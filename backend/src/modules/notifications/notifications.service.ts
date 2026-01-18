import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { SupabaseService } from '../../supabase/supabase.service';
import { OneSignalResponse } from './dto/notification.dto';

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);
  private readonly appId: string;
  private readonly apiKey: string;

  constructor(
    private configService: ConfigService,
    private supabaseService: SupabaseService,
  ) {
    this.appId = this.configService.get<string>('ONESIGNAL_APP_ID') || '';
    this.apiKey = this.configService.get<string>('ONESIGNAL_API_KEY') || '';

    if (!this.appId || !this.apiKey) {
      this.logger.warn('⚠️ OneSignal credentials not configured');
    } else {
      this.logger.log('✅ OneSignal initialized');
    }
  }

  /**
   * Envoyer notification push via OneSignal (GRATUIT)
   */
  async sendPushToUser(
    userId: string,
    title: string,
    message: string,
    data?: Record<string, string>,
  ): Promise<OneSignalResponse | null> {
    if (!this.appId || !this.apiKey) {
      this.logger.warn('OneSignal not configured, skipping notification');
      return null;
    }

    try {
      const response = await fetch('https://onesignal.com/api/v1/notifications', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Basic ${this.apiKey}`,
        },
        body: JSON.stringify({
          app_id: this.appId,
          include_external_user_ids: [userId],
          headings: { en: title, fr: title },
          contents: { en: message, fr: message },
          data: data || {},
          android_channel_id: 'orders',
          android_accent_color: 'FF6B35',
          ios_sound: 'default',
          ios_badgeType: 'Increase',
          ios_badgeCount: 1,
        }),
      });

      const result: OneSignalResponse = await response.json();

      if (result.errors) {
        this.logger.error(`OneSignal error: ${JSON.stringify(result.errors)}`);
        return null;
      }

      this.logger.log(`📱 Notification sent to ${userId}: ${result.id}`);
      return result;
    } catch (error) {
      this.logger.error(`Failed to send notification: ${(error as Error).message}`);
      return null;
    }
  }

  /**
   * Nouvelle commande → Notifier le restaurant
   */
  async notifyNewOrder(orderId: string): Promise<OneSignalResponse | null> {
    try {
      const order = await this.supabaseService.getOrderById(orderId);
      const restaurant = await this.supabaseService.getRestaurantById(order.restaurant_id);

      // ⚠️ SQL: "total" (pas "total_amount")
      return this.sendPushToUser(
        restaurant.owner_id,
        '🔔 Nouvelle commande !',
        `Commande #${order.order_number} - ${order.total} DA`,
        {
          type: 'new_order',
          order_id: orderId,
          order_number: order.order_number,
        },
      );
    } catch (error) {
      this.logger.error(`notifyNewOrder error: ${(error as Error).message}`);
      return null;
    }
  }

  /**
   * Commande confirmée → Notifier le client
   * ⚠️ SQL: status 'confirmed' (pas 'accepted')
   */
  async notifyOrderConfirmed(orderId: string): Promise<OneSignalResponse | null> {
    try {
      const order = await this.supabaseService.getOrderById(orderId);

      return this.sendPushToUser(
        order.user_id,
        '✅ Commande confirmée !',
        `Votre commande #${order.order_number} est en préparation`,
        { type: 'order_confirmed', order_id: orderId },
      );
    } catch (error) {
      this.logger.error(`notifyOrderConfirmed error: ${(error as Error).message}`);
      return null;
    }
  }

  // Alias pour compatibilité (deprecated - utiliser notifyOrderConfirmed)
  async notifyOrderAccepted(orderId: string): Promise<OneSignalResponse | null> {
    return this.notifyOrderConfirmed(orderId);
  }

  /**
   * Commande prête → Notifier le client
   */
  async notifyOrderReady(orderId: string): Promise<OneSignalResponse | null> {
    try {
      const order = await this.supabaseService.getOrderById(orderId);

      return this.sendPushToUser(
        order.user_id,
        '🍽️ Commande prête !',
        `Votre commande #${order.order_number} est prête`,
        { type: 'order_ready', order_id: orderId },
      );
    } catch (error) {
      this.logger.error(`notifyOrderReady error: ${(error as Error).message}`);
      return null;
    }
  }

  /**
   * Livreur assigné → Notifier le client
   */
  async notifyDriverAssigned(orderId: string, livreurId: string): Promise<OneSignalResponse | null> {
    try {
      const order = await this.supabaseService.getOrderById(orderId);
      const livreur = await this.supabaseService.getUserById(livreurId);

      return this.sendPushToUser(
        order.user_id,
        '🚚 Livreur en route !',
        `${livreur.full_name || 'Un livreur'} arrive avec votre commande`,
        {
          type: 'driver_assigned',
          order_id: orderId,
          livreur_id: livreurId, // ⚠️ SQL: "livreur_id"
        },
      );
    } catch (error) {
      this.logger.error(`notifyDriverAssigned error: ${(error as Error).message}`);
      return null;
    }
  }

  /**
   * Nouvelle livraison → Notifier le livreur
   */
  async notifyDriverNewDelivery(livreurId: string, orderId: string): Promise<OneSignalResponse | null> {
    try {
      const order = await this.supabaseService.getOrderById(orderId);

      return this.sendPushToUser(
        livreurId,
        '📦 Nouvelle livraison !',
        `Commande #${order.order_number} à récupérer`,
        { type: 'new_delivery', order_id: orderId },
      );
    } catch (error) {
      this.logger.error(`notifyDriverNewDelivery error: ${(error as Error).message}`);
      return null;
    }
  }

  /**
   * Commande livrée → Notifier le client
   */
  async notifyOrderDelivered(orderId: string): Promise<OneSignalResponse | null> {
    try {
      const order = await this.supabaseService.getOrderById(orderId);

      return this.sendPushToUser(
        order.user_id,
        '✅ Commande livrée !',
        `Votre commande #${order.order_number} a été livrée. Bon appétit !`,
        { type: 'order_delivered', order_id: orderId },
      );
    } catch (error) {
      this.logger.error(`notifyOrderDelivered error: ${(error as Error).message}`);
      return null;
    }
  }

  /**
   * Commande annulée → Notifier le client
   */
  async notifyOrderCancelled(orderId: string, reason?: string): Promise<OneSignalResponse | null> {
    try {
      const order = await this.supabaseService.getOrderById(orderId);

      return this.sendPushToUser(
        order.user_id,
        '❌ Commande annulée',
        reason || `Votre commande #${order.order_number} a été annulée`,
        { type: 'order_cancelled', order_id: orderId },
      );
    } catch (error) {
      this.logger.error(`notifyOrderCancelled error: ${(error as Error).message}`);
      return null;
    }
  }

  // ========================================
  // NOUVELLES MÉTHODES POUR FLUX COMPLET
  // ========================================

  /**
   * Nouvelle commande créée → Notifier TOUS les livreurs disponibles
   * Pour qu'ils puissent accepter la livraison
   */
  async notifyAvailableLivreurs(orderId: string): Promise<void> {
    try {
      const order = await this.supabaseService.getOrderById(orderId);
      const supabase = this.supabaseService.getClient();

      // Récupérer tous les livreurs disponibles et vérifiés
      const { data: livreurs, error } = await supabase
        .from('livreurs')
        .select('user_id')
        .eq('is_available', true)
        .eq('is_verified', true);

      if (error || !livreurs?.length) {
        this.logger.warn('No available livreurs to notify');
        return;
      }

      // Envoyer notification à chaque livreur disponible
      const notifications = livreurs.map((l) =>
        this.sendPushToUser(
          l.user_id,
          '📦 Nouvelle livraison disponible !',
          `Commande #${order.order_number} - ${order.total} DA`,
          {
            type: 'new_delivery_available',
            order_id: orderId,
            order_number: order.order_number,
          },
        ),
      );

      await Promise.allSettled(notifications);
      this.logger.log(`📱 Notified ${livreurs.length} livreurs for order ${orderId}`);
    } catch (error) {
      this.logger.error(`notifyAvailableLivreurs error: ${(error as Error).message}`);
    }
  }

  /**
   * Commande prête → Notifier le livreur assigné
   * Pour qu'il vienne la récupérer
   */
  async notifyLivreurOrderReady(orderId: string, livreurId: string): Promise<OneSignalResponse | null> {
    try {
      const order = await this.supabaseService.getOrderById(orderId);
      const supabase = this.supabaseService.getClient();

      // Récupérer le user_id du livreur
      const { data: livreur } = await supabase
        .from('livreurs')
        .select('user_id')
        .eq('id', livreurId)
        .single();

      if (!livreur?.user_id) {
        this.logger.warn(`Livreur ${livreurId} not found`);
        return null;
      }

      return this.sendPushToUser(
        livreur.user_id,
        '🍽️ Commande prête à récupérer !',
        `Commande #${order.order_number} est prête au restaurant`,
        {
          type: 'order_ready_pickup',
          order_id: orderId,
          order_number: order.order_number,
        },
      );
    } catch (error) {
      this.logger.error(`notifyLivreurOrderReady error: ${(error as Error).message}`);
      return null;
    }
  }

  /**
   * Commande récupérée → Notifier le client
   * Pour qu'il sache que sa commande est en route
   */
  async notifyOrderPickedUp(orderId: string): Promise<OneSignalResponse | null> {
    try {
      const order = await this.supabaseService.getOrderById(orderId);

      return this.sendPushToUser(
        order.user_id,
        '🚚 Votre commande est en route !',
        `Commande #${order.order_number} arrive bientôt`,
        {
          type: 'order_picked_up',
          order_id: orderId,
          order_number: order.order_number,
        },
      );
    } catch (error) {
      this.logger.error(`notifyOrderPickedUp error: ${(error as Error).message}`);
      return null;
    }
  }

  /**
   * Commande livrée → Notifier le restaurant
   * Pour confirmer que la commande a été bien reçue par le client
   */
  async notifyRestaurantOrderDelivered(orderId: string): Promise<OneSignalResponse | null> {
    try {
      const order = await this.supabaseService.getOrderById(orderId);
      const restaurant = await this.supabaseService.getRestaurantById(order.restaurant_id);

      return this.sendPushToUser(
        restaurant.owner_id,
        '✅ Commande livrée !',
        `Commande #${order.order_number} a été livrée au client`,
        {
          type: 'order_delivered_confirm',
          order_id: orderId,
          order_number: order.order_number,
        },
      );
    } catch (error) {
      this.logger.error(`notifyRestaurantOrderDelivered error: ${(error as Error).message}`);
      return null;
    }
  }

  /**
   * Livreur accepte commande → Notifier le restaurant
   * Pour qu'il commence la préparation
   */
  async notifyRestaurantLivreurAccepted(orderId: string): Promise<OneSignalResponse | null> {
    try {
      const order = await this.supabaseService.getOrderById(orderId);
      const restaurant = await this.supabaseService.getRestaurantById(order.restaurant_id);

      return this.sendPushToUser(
        restaurant.owner_id,
        '🔔 Nouvelle commande !',
        `Commande #${order.order_number} - Un livreur est assigné, commencez la préparation`,
        {
          type: 'new_order',
          order_id: orderId,
          order_number: order.order_number,
        },
      );
    } catch (error) {
      this.logger.error(`notifyRestaurantLivreurAccepted error: ${(error as Error).message}`);
      return null;
    }
  }
}

