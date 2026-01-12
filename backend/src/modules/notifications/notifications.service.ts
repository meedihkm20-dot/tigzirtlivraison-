import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Notification } from './entities/notification.entity';
import { DeviceToken } from './entities/device-token.entity';
import { FirebaseService } from './firebase.service';

@Injectable()
export class NotificationsService {
  constructor(
    @InjectRepository(Notification)
    private notificationsRepository: Repository<Notification>,
    @InjectRepository(DeviceToken)
    private deviceTokensRepository: Repository<DeviceToken>,
    private firebaseService: FirebaseService,
  ) {}

  async create(data: {
    userId?: string;
    restaurantId?: string;
    livreurId?: string;
    title: string;
    message: string;
    type: string;
    data?: Record<string, any>;
  }): Promise<Notification> {
    const notification = this.notificationsRepository.create(data);
    const saved = await this.notificationsRepository.save(notification);

    // Send push notification
    await this.sendPushNotification(data);

    return saved;
  }

  async findByUser(userId: string): Promise<Notification[]> {
    return this.notificationsRepository.find({
      where: { userId },
      order: { createdAt: 'DESC' },
      take: 50,
    });
  }

  async findByRestaurant(restaurantId: string): Promise<Notification[]> {
    return this.notificationsRepository.find({
      where: { restaurantId },
      order: { createdAt: 'DESC' },
      take: 50,
    });
  }

  async findByLivreur(livreurId: string): Promise<Notification[]> {
    return this.notificationsRepository.find({
      where: { livreurId },
      order: { createdAt: 'DESC' },
      take: 50,
    });
  }

  async markAsRead(id: string): Promise<void> {
    await this.notificationsRepository.update(id, { isRead: true });
  }

  async markAllAsRead(entityType: string, entityId: string): Promise<void> {
    const whereClause: any = { isRead: false };
    if (entityType === 'user') whereClause.userId = entityId;
    if (entityType === 'restaurant') whereClause.restaurantId = entityId;
    if (entityType === 'livreur') whereClause.livreurId = entityId;

    await this.notificationsRepository.update(whereClause, { isRead: true });
  }

  async getUnreadCount(entityType: string, entityId: string): Promise<number> {
    const whereClause: any = { isRead: false };
    if (entityType === 'user') whereClause.userId = entityId;
    if (entityType === 'restaurant') whereClause.restaurantId = entityId;
    if (entityType === 'livreur') whereClause.livreurId = entityId;

    return this.notificationsRepository.count({ where: whereClause });
  }

  // Device tokens
  async registerDeviceToken(data: {
    userId?: string;
    restaurantId?: string;
    livreurId?: string;
    token: string;
    deviceType?: string;
  }): Promise<DeviceToken> {
    // Check if token already exists
    const existing = await this.deviceTokensRepository.findOne({
      where: { token: data.token },
    });

    if (existing) {
      await this.deviceTokensRepository.update(existing.id, data);
      return this.deviceTokensRepository.findOne({ where: { id: existing.id } });
    }

    const deviceToken = this.deviceTokensRepository.create(data);
    return this.deviceTokensRepository.save(deviceToken);
  }

  async removeDeviceToken(token: string): Promise<void> {
    await this.deviceTokensRepository.delete({ token });
  }

  private async sendPushNotification(data: {
    userId?: string;
    restaurantId?: string;
    livreurId?: string;
    title: string;
    message: string;
    data?: Record<string, any>;
  }): Promise<void> {
    const whereClause: any = {};
    if (data.userId) whereClause.userId = data.userId;
    if (data.restaurantId) whereClause.restaurantId = data.restaurantId;
    if (data.livreurId) whereClause.livreurId = data.livreurId;

    const tokens = await this.deviceTokensRepository.find({ where: whereClause });

    for (const deviceToken of tokens) {
      try {
        await this.firebaseService.sendNotification(
          deviceToken.token,
          data.title,
          data.message,
          data.data,
        );
      } catch (error) {
        console.error(`Failed to send notification to ${deviceToken.token}:`, error);
        // Remove invalid token
        if (error.code === 'messaging/invalid-registration-token') {
          await this.removeDeviceToken(deviceToken.token);
        }
      }
    }
  }

  // Notification helpers
  async notifyNewOrder(restaurantId: string, orderId: string, orderNumber: string): Promise<void> {
    await this.create({
      restaurantId,
      title: 'Nouvelle commande',
      message: `Vous avez reçu une nouvelle commande #${orderNumber}`,
      type: 'new_order',
      data: { orderId, orderNumber },
    });
  }

  async notifyOrderStatusChange(
    userId: string,
    orderId: string,
    orderNumber: string,
    status: string,
  ): Promise<void> {
    const statusMessages: Record<string, string> = {
      accepted: 'Votre commande a été acceptée',
      preparing: 'Votre commande est en préparation',
      ready: 'Votre commande est prête',
      picked_up: 'Le livreur a récupéré votre commande',
      delivering: 'Votre commande est en cours de livraison',
      delivered: 'Votre commande a été livrée',
      cancelled: 'Votre commande a été annulée',
    };

    await this.create({
      userId,
      title: `Commande #${orderNumber}`,
      message: statusMessages[status] || `Statut: ${status}`,
      type: 'order_status',
      data: { orderId, orderNumber, status },
    });
  }

  async notifyLivreurNewDelivery(livreurId: string, orderId: string, orderNumber: string): Promise<void> {
    await this.create({
      livreurId,
      title: 'Nouvelle livraison disponible',
      message: `Une nouvelle livraison #${orderNumber} est disponible près de vous`,
      type: 'new_delivery',
      data: { orderId, orderNumber },
    });
  }
}
