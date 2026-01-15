import { Injectable, BadRequestException, Logger } from '@nestjs/common';
import { SupabaseService } from '../../supabase/supabase.service';
import { NotificationsService } from '../notifications/notifications.service';
import { DeliveryService } from '../delivery/delivery.service';
import { CreateOrderDto } from './dto/create-order.dto';
import { OrderItem, CreateOrderResponse } from './dto/order-item.dto';

@Injectable()
export class OrdersService {
  private readonly logger = new Logger(OrdersService.name);

  constructor(
    private supabaseService: SupabaseService,
    private notificationsService: NotificationsService,
    private deliveryService: DeliveryService,
  ) {}

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
    const { data: order, error: orderError } = await supabase
      .from('orders')
      .insert({
        user_id: userId,
        restaurant_id: dto.restaurant_id,
        order_number: orderNumber,
        status: 'pending',
        subtotal,
        delivery_fee: deliveryFee,
        total_amount: totalAmount,
        delivery_address: dto.delivery_address,
        delivery_lat: dto.delivery_lat,
        delivery_lng: dto.delivery_lng,
        notes: dto.notes,
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

    // 7. Notifier le restaurant (OneSignal)
    await this.notificationsService.notifyNewOrder(order.id);

    this.logger.log(`Order created: ${order.order_number}`);
    return { order, items: orderItems };
  }

  /**
   * Restaurant accepte la commande
   */
  async acceptOrder(orderId: string, restaurantOwnerId: string) {
    const order = await this.supabaseService.getOrderById(orderId);
    const restaurant = await this.supabaseService.getRestaurantById(
      order.restaurant_id,
    );

    if (restaurant.owner_id !== restaurantOwnerId) {
      throw new BadRequestException('Non autorisé');
    }

    await this.supabaseService.updateOrderStatus(orderId, 'accepted');
    await this.notificationsService.notifyOrderAccepted(orderId);

    this.logger.log(`Order accepted: ${orderId}`);
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
  async markDelivered(orderId: string, driverId: string) {
    const order = await this.supabaseService.getOrderById(orderId);

    if (order.driver_id !== driverId) {
      throw new BadRequestException('Non autorisé');
    }

    await this.supabaseService.updateOrderStatus(orderId, 'delivered');
    await this.notificationsService.notifyOrderDelivered(orderId);

    this.logger.log(`Order delivered: ${orderId}`);
    return { success: true };
  }
}
