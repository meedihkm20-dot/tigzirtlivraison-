import { Injectable, BadRequestException, ForbiddenException, Logger } from '@nestjs/common';
import { SupabaseService } from '../../supabase/supabase.service';
import { NotificationsService } from '../notifications/notifications.service';
import { DeliveryService } from '../delivery/delivery.service';
import { CreateOrderDto } from './dto/create-order.dto';
import { OrderItem, CreateOrderResponse } from './dto/order-item.dto';
import { ChangeStatusDto, OrderStatus } from './dto/change-status.dto';
import { CancelOrderDto, CancellationReason } from './dto/cancel-order.dto';

// Transitions autorisées (RÈGLE MÉTIER STRICTE)
const VALID_TRANSITIONS: Record<string, string[]> = {
  'pending': ['confirmed', 'cancelled'],
  'confirmed': ['preparing', 'cancelled'],
  'preparing': ['ready', 'cancelled'],
  'ready': ['picked_up'],
  'picked_up': ['delivering', 'delivered'],
  'delivering': ['delivered'],
};

// Rôles autorisés pour chaque transition
const ROLE_PERMISSIONS: Record<string, string[]> = {
  'pending->confirmed': ['livreur'],
  'pending->cancelled': ['customer', 'restaurant'],
  'confirmed->preparing': ['restaurant'],
  'confirmed->cancelled': ['customer', 'restaurant'],
  'preparing->ready': ['restaurant'],
  'preparing->cancelled': ['restaurant'],
  'ready->picked_up': ['livreur'],
  'picked_up->delivering': ['livreur'],
  'picked_up->delivered': ['livreur'],
  'delivering->delivered': ['livreur'],
};

// Statuts où l'annulation est INTERDITE
const NON_CANCELLABLE_STATUSES = ['picked_up', 'delivering', 'delivered'];

// Qui peut annuler à quel moment
const CANCELLATION_RULES: Record<string, string[]> = {
  'pending': ['customer', 'restaurant'],
  'confirmed': ['customer', 'restaurant'],
  'preparing': ['restaurant'],
  'ready': [],
};

@Injectable()
export class OrdersService {
  private readonly logger = new Logger(OrdersService.name);

  constructor(
    private supabaseService: SupabaseService,
    private notificationsService: NotificationsService,
    private deliveryService: DeliveryService,
  ) { }

  /**
   * Créer une commande (validation côté serveur)
   */
  async createOrder(userId: string, dto: CreateOrderDto): Promise<CreateOrderResponse> {
    const supabase = this.supabaseService.getClient();

    // 1. Vérifier le restaurant
    const { data: restaurant, error: restError } = await supabase
      .from('restaurants')
      .select('*, menu_items(*)')
      .eq('id', dto.restaurant_id)
      .single();

    if (restError || !restaurant) {
      throw new BadRequestException('Restaurant introuvable');
    }

    if (!restaurant.is_open) {
      throw new BadRequestException('Restaurant fermé');
    }

    // 2. Calculer le total (côté serveur = sécurisé)
    let subtotal = 0;
    const orderItems: OrderItem[] = [];

    for (const item of dto.items) {
      const menuItem = (restaurant.menu_items as any[])?.find(
        (mi: any) => mi.id === item.menu_item_id,
      );

      if (!menuItem) {
        throw new BadRequestException(`Plat introuvable: ${item.menu_item_id}`);
      }

      if (!menuItem.is_available) {
        throw new BadRequestException(`${menuItem.name} n'est plus disponible`);
      }

      subtotal += menuItem.price * item.quantity;
      orderItems.push({
        menu_item_id: item.menu_item_id,
        quantity: item.quantity,
        unit_price: menuItem.price,
        total_price: menuItem.price * item.quantity,
        name: menuItem.name,
      });
    }

    // 3. Calculer les frais de livraison
    const estimatedDistance = 5;
    const deliveryFee = this.deliveryService.calculateDeliveryPrice(
      estimatedDistance,
      'tigzirt',
    );

    const totalAmount = subtotal + deliveryFee;

    // 4. Générer numéro de commande
    const orderNumber = `DZ${Date.now().toString(36).toUpperCase()}`;

    // 5. Créer la commande
    // ⚠️ NOMS DE COLONNES = SCHÉMA SQL (source de vérité)
    const { data: order, error: orderError } = await supabase
      .from('orders')
      .insert({
        customer_id: userId,
        restaurant_id: dto.restaurant_id,
        order_number: orderNumber,
        status: 'pending',
        subtotal,
        delivery_fee: deliveryFee,
        total: totalAmount, // ⚠️ SQL: "total" (pas "total_amount")
        delivery_address: dto.delivery_address,
        delivery_latitude: dto.delivery_lat, // ⚠️ SQL: "delivery_latitude"
        delivery_longitude: dto.delivery_lng, // ⚠️ SQL: "delivery_longitude"
        delivery_instructions: dto.notes,
      })
      .select()
      .single();

    if (orderError) {
      this.logger.error(`Order creation error: ${orderError.message}`);
      throw new BadRequestException('Erreur création commande');
    }

    // 6. Créer les items
    const itemsToInsert = orderItems.map((item) => ({
      ...item,
      order_id: order.id,
    }));

    const { error: itemsError } = await supabase
      .from('order_items')
      .insert(itemsToInsert);

    if (itemsError) {
      this.logger.error(`Order items error: ${itemsError.message}`);
    }

    // 7. Notifier tous les livreurs disponibles (nouvelle commande à livrer)
    await this.notificationsService.notifyAvailableLivreurs(order.id);

    this.logger.log(`Order created: ${order.order_number}`);
    return { order, items: orderItems };
  }

  /**
   * Restaurant confirme la commande
   * ⚠️ SQL: status 'confirmed' (pas 'accepted')
   */
  async acceptOrder(orderId: string, restaurantOwnerId: string) {
    const order = await this.supabaseService.getOrderById(orderId);
    const restaurant = await this.supabaseService.getRestaurantById(
      order.restaurant_id,
    );

    if (restaurant.owner_id !== restaurantOwnerId) {
      throw new BadRequestException('Non autorisé');
    }

    // ⚠️ SQL: 'confirmed' (pas 'accepted')
    await this.supabaseService.updateOrderStatus(orderId, 'confirmed');
    await this.notificationsService.notifyOrderConfirmed(orderId);

    this.logger.log(`Order confirmed: ${orderId}`);
    return { success: true };
  }

  /**
   * Commande prête → Assigner livreur
   */
  async markReady(orderId: string, restaurantOwnerId: string) {
    const order = await this.supabaseService.getOrderById(orderId);
    const restaurant = await this.supabaseService.getRestaurantById(
      order.restaurant_id,
    );

    if (restaurant.owner_id !== restaurantOwnerId) {
      throw new BadRequestException('Non autorisé');
    }

    await this.supabaseService.updateOrderStatus(orderId, 'ready');
    await this.notificationsService.notifyOrderReady(orderId);

    // Assigner un livreur
    const driver = await this.deliveryService.assignDriver(orderId);

    if (driver) {
      await this.notificationsService.notifyDriverNewDelivery(driver.id, orderId);
      await this.notificationsService.notifyDriverAssigned(orderId, driver.id);
    }

    this.logger.log(`Order ready: ${orderId}, driver: ${driver?.id || 'none'}`);
    return { success: true, driver };
  }

  /**
   * Livreur confirme livraison
   */
  async markDelivered(orderId: string, livreurUserId: string) {
    const order = await this.supabaseService.getOrderById(orderId);
    const supabase = this.supabaseService.getClient();

    // Récupérer le livreur depuis user_id
    const { data: livreur } = await supabase
      .from('livreurs')
      .select('id')
      .eq('user_id', livreurUserId)
      .single();

    // ⚠️ SQL: "livreur_id" (pas "driver_id")
    if (order.livreur_id !== livreur?.id) {
      throw new BadRequestException('Non autorisé');
    }

    await this.supabaseService.updateOrderStatus(orderId, 'delivered');
    await this.notificationsService.notifyOrderDelivered(orderId);

    this.logger.log(`Order delivered: ${orderId}`);
    return { success: true };
  }

  /**
   * Changer le statut d'une commande (migration Edge Function)
   * Source unique de vérité pour les transitions de statut
   */
  async changeOrderStatus(orderId: string, userId: string, dto: ChangeStatusDto) {
    const supabase = this.supabaseService.getClient();
    const newStatus = dto.status;

    // Récupérer la commande avec restaurant
    const { data: order, error: orderError } = await supabase
      .from('orders')
      .select('*, restaurant:restaurants(owner_id)')
      .eq('id', orderId)
      .single();

    if (orderError || !order) {
      throw new BadRequestException('Commande non trouvée');
    }

    const currentStatus = order.status;

    // Vérifier si la transition est valide
    if (!VALID_TRANSITIONS[currentStatus]?.includes(newStatus)) {
      throw new BadRequestException(`Transition invalide: ${currentStatus} → ${newStatus}`);
    }

    // Récupérer le rôle de l'utilisateur
    const { data: profile } = await supabase
      .from('profiles')
      .select('role')
      .eq('id', userId)
      .single();

    const userRole = profile?.role;

    // Vérifier les permissions de rôle
    const transitionKey = `${currentStatus}->${newStatus}`;
    const allowedRoles = ROLE_PERMISSIONS[transitionKey];

    if (!allowedRoles?.includes(userRole)) {
      throw new ForbiddenException(`Rôle ${userRole} non autorisé pour cette transition`);
    }

    // Vérifications supplémentaires selon le rôle
    if (userRole === 'customer' && order.customer_id !== userId) {
      throw new ForbiddenException('Vous ne pouvez modifier que vos propres commandes');
    }

    if (userRole === 'restaurant' && order.restaurant?.owner_id !== userId) {
      throw new ForbiddenException('Vous ne pouvez modifier que les commandes de votre restaurant');
    }

    if (userRole === 'livreur') {
      const { data: livreur } = await supabase
        .from('livreurs')
        .select('id, is_verified')
        .eq('user_id', userId)
        .single();

      if (!livreur?.is_verified) {
        throw new ForbiddenException('Livreur non vérifié');
      }

      // Pour accepter une commande pending
      if (currentStatus === 'pending' && newStatus === 'confirmed') {
        if (order.livreur_id !== null) {
          throw new BadRequestException('Commande déjà acceptée par un autre livreur');
        }
      } else if (order.livreur_id !== livreur.id) {
        throw new ForbiddenException('Vous ne pouvez modifier que vos commandes assignées');
      }
    }

    // Préparer les mises à jour
    const updates: Record<string, any> = { status: newStatus };
    const now = new Date().toISOString();

    // Ajouter les timestamps selon le statut
    switch (newStatus) {
      case 'confirmed':
        updates.confirmed_at = now;
        if (userRole === 'livreur') {
          const { data: livreur } = await supabase
            .from('livreurs')
            .select('id')
            .eq('user_id', userId)
            .single();
          updates.livreur_id = livreur?.id;
          updates.livreur_accepted_at = now;

          // Marquer le livreur comme non disponible
          await supabase
            .from('livreurs')
            .update({ is_available: false })
            .eq('user_id', userId);
        }
        break;
      case 'preparing':
        // Note: SQL n'a pas de colonne "preparing_at", on utilise "prepared_at" pour "ready"
        break;
      case 'ready':
        updates.prepared_at = now;
        break;
      case 'picked_up':
        updates.picked_up_at = now;
        break;
      case 'delivered':
        updates.delivered_at = now;
        // Libérer le livreur
        if (order.livreur_id) {
          await supabase
            .from('livreurs')
            .update({ is_available: true })
            .eq('id', order.livreur_id);
        }
        break;
    }

    // Appliquer la mise à jour
    const { error: updateError } = await supabase
      .from('orders')
      .update(updates)
      .eq('id', orderId);

    if (updateError) {
      throw new BadRequestException(`Erreur mise à jour: ${updateError.message}`);
    }

    // Envoyer notifications (passer l'order pour éviter re-fetch)
    await this.sendStatusNotification(orderId, newStatus, order);

    this.logger.log(`Order ${orderId}: ${currentStatus} → ${newStatus}`);
    return {
      success: true,
      message: `Statut changé: ${currentStatus} → ${newStatus}`,
      order_id: orderId,
      new_status: newStatus,
    };
  }

  /**
   * Annuler une commande (migration Edge Function)
   * Bloque les annulations après pickup
   */
  async cancelOrder(orderId: string, userId: string, dto: CancelOrderDto) {
    const supabase = this.supabaseService.getClient();

    // Récupérer la commande
    const { data: order, error: orderError } = await supabase
      .from('orders')
      .select('*, restaurant:restaurants(owner_id)')
      .eq('id', orderId)
      .single();

    if (orderError || !order) {
      throw new BadRequestException('Commande non trouvée');
    }

    const currentStatus = order.status;

    // RÈGLE CRITIQUE: Bloquer après pickup
    if (NON_CANCELLABLE_STATUSES.includes(currentStatus)) {
      throw new BadRequestException(
        `Impossible d'annuler: commande déjà en livraison (statut: ${currentStatus})`,
      );
    }

    if (currentStatus === 'cancelled') {
      throw new BadRequestException('Commande déjà annulée');
    }

    // Récupérer le rôle
    const { data: profile } = await supabase
      .from('profiles')
      .select('role')
      .eq('id', userId)
      .single();

    const userRole = profile?.role;

    // Vérifier les permissions d'annulation
    const allowedRoles = CANCELLATION_RULES[currentStatus] || [];
    if (!allowedRoles.includes(userRole)) {
      throw new ForbiddenException(
        `Rôle ${userRole} non autorisé pour annuler au statut ${currentStatus}`,
      );
    }

    // Vérifier que l'utilisateur est bien impliqué dans la commande
    let isAuthorized = false;
    let cancelledBy = '';

    if (userRole === 'customer' && order.customer_id === userId) {
      isAuthorized = true;
      cancelledBy = 'customer';
    } else if (userRole === 'restaurant' && order.restaurant?.owner_id === userId) {
      isAuthorized = true;
      cancelledBy = 'restaurant';
    }

    if (!isAuthorized) {
      throw new ForbiddenException("Vous n'êtes pas autorisé à annuler cette commande");
    }

    // Effectuer l'annulation
    const { error: updateError } = await supabase
      .from('orders')
      .update({
        status: 'cancelled',
        cancelled_at: new Date().toISOString(),
        cancellation_reason: dto.details || `Annulé par ${cancelledBy}: ${dto.reason}`,
        cancelled_by: cancelledBy,
      })
      .eq('id', orderId);

    if (updateError) {
      throw new BadRequestException(`Erreur annulation: ${updateError.message}`);
    }

    // Si un livreur était assigné, le libérer
    if (order.livreur_id) {
      await supabase
        .from('livreurs')
        .update({ is_available: true })
        .eq('id', order.livreur_id);
    }

    // Notifier les parties concernées
    await this.notificationsService.notifyOrderCancelled(orderId, cancelledBy);

    this.logger.log(`Order cancelled: ${orderId} by ${cancelledBy}`);
    return {
      success: true,
      message: 'Commande annulée avec succès',
      order_id: orderId,
      cancelled_by: cancelledBy,
      previous_status: currentStatus,
    };
  }

  /**
   * Envoyer notification selon le nouveau statut
   * FLUX COMPLET:
   * - pending (créé) → Tous les livreurs
   * - confirmed (livreur accepte) → Client + Restaurant
   * - preparing (restaurant prépare) → (optionnel)
   * - ready (restaurant prêt) → Livreur + Client
   * - picked_up (livreur récupère) → Client
   * - delivered (livreur livre) → Client + Restaurant
   */
  private async sendStatusNotification(orderId: string, status: string, order?: any) {
    try {
      // Récupérer la commande si pas fournie
      if (!order) {
        order = await this.supabaseService.getOrderById(orderId);
      }

      switch (status) {
        case 'confirmed':
          // Livreur accepte → Client sait qu'un livreur est assigné
          await this.notificationsService.notifyOrderConfirmed(orderId);
          // Restaurant sait qu'il peut commencer à préparer
          await this.notificationsService.notifyRestaurantLivreurAccepted(orderId);
          break;

        case 'preparing':
          // Optionnel: le client peut être notifié que la préparation commence
          // await this.notificationsService.notifyOrderPreparing(orderId);
          break;

        case 'ready':
          // Client sait que sa commande est prête
          await this.notificationsService.notifyOrderReady(orderId);
          // Livreur sait qu'il doit venir la chercher
          if (order.livreur_id) {
            await this.notificationsService.notifyLivreurOrderReady(orderId, order.livreur_id);
          }
          break;

        case 'picked_up':
          // Client sait que sa commande est en route
          await this.notificationsService.notifyOrderPickedUp(orderId);
          break;

        case 'delivered':
          // Client sait que c'est livré
          await this.notificationsService.notifyOrderDelivered(orderId);
          // Restaurant sait que c'est livré
          await this.notificationsService.notifyRestaurantOrderDelivered(orderId);
          break;
      }
    } catch (error) {
      this.logger.warn(`Notification error for ${orderId}: ${(error as Error).message}`);
    }
  }
}
