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

      return this.sendPushToUser(
        restaurant.owner_id,
        '🔔 Nouvelle commande !',
        `Commande #${order.order_number} - ${order.total_amount} DA`,
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
   * Commande acceptée → Notifier le client
   */
  async notifyOrderAccepted(orderId: string): Promise<OneSignalResponse | null> {
    try {
      const order = await this.supabaseService.getOrderById(orderId);

      return this.sendPushToUser(
        order.user_id,
        '✅ Commande acceptée !',
        `Votre commande #${order.order_number} est en préparation`,
        { type: 'order_accepted', order_id: orderId },
      );
    } catch (error) {
      this.logger.error(`notifyOrderAccepted error: ${(error as Error).message}`);
      return null;
    }
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
  async notifyDriverAssigned(orderId: string, driverId: string): Promise<OneSignalResponse | null> {
    try {
      const order = await this.supabaseService.getOrderById(orderId);
      const driver = await this.supabaseService.getUserById(driverId);

      return this.sendPushToUser(
        order.user_id,
        '🚚 Livreur en route !',
        `${driver.full_name || 'Un livreur'} arrive avec votre commande`,
        {
          type: 'driver_assigned',
          order_id: orderId,
          driver_id: driverId,
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
  async notifyDriverNewDelivery(driverId: string, orderId: string): Promise<OneSignalResponse | null> {
    try {
      const order = await this.supabaseService.getOrderById(orderId);

      return this.sendPushToUser(
        driverId,
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
}
