import { Controller, Post, Body } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { NotificationsService } from './notifications.service';
import {
  NotifyOrderDto,
  NotifyDriverAssignedDto,
  NotifyNewDeliveryDto,
  NotifyOrderCancelledDto,
  TestNotificationDto,
  OneSignalResponse,
} from './dto/notification.dto';

@ApiTags('Notifications')
@Controller('api/notifications')
export class NotificationsController {
  constructor(private notificationsService: NotificationsService) {}

  @Post('new-order')
  @ApiOperation({ summary: 'Notifier restaurant - nouvelle commande' })
  async newOrder(@Body() body: NotifyOrderDto): Promise<OneSignalResponse | null> {
    return this.notificationsService.notifyNewOrder(body.order_id);
  }

  @Post('order-confirmed')
  @ApiOperation({ summary: 'Notifier client - commande confirmée' })
  async orderConfirmed(@Body() body: NotifyOrderDto): Promise<OneSignalResponse | null> {
    return this.notificationsService.notifyOrderConfirmed(body.order_id);
  }

  // Alias pour compatibilité (deprecated)
  @Post('order-accepted')
  @ApiOperation({ summary: 'Notifier client - commande confirmée (alias deprecated)' })
  async orderAccepted(@Body() body: NotifyOrderDto): Promise<OneSignalResponse | null> {
    return this.notificationsService.notifyOrderConfirmed(body.order_id);
  }

  @Post('order-ready')
  @ApiOperation({ summary: 'Notifier client - commande prête' })
  async orderReady(@Body() body: NotifyOrderDto): Promise<OneSignalResponse | null> {
    return this.notificationsService.notifyOrderReady(body.order_id);
  }

  @Post('driver-assigned')
  @ApiOperation({ summary: 'Notifier client - livreur assigné' })
  async driverAssigned(@Body() body: NotifyDriverAssignedDto): Promise<OneSignalResponse | null> {
    return this.notificationsService.notifyDriverAssigned(
      body.order_id,
      body.livreur_id, // ⚠️ SQL: "livreur_id"
    );
  }

  @Post('new-delivery')
  @ApiOperation({ summary: 'Notifier livreur - nouvelle livraison' })
  async newDelivery(@Body() body: NotifyNewDeliveryDto): Promise<OneSignalResponse | null> {
    return this.notificationsService.notifyDriverNewDelivery(
      body.livreur_id, // ⚠️ SQL: "livreur_id"
      body.order_id,
    );
  }

  @Post('order-delivered')
  @ApiOperation({ summary: 'Notifier client - commande livrée' })
  async orderDelivered(@Body() body: NotifyOrderDto): Promise<OneSignalResponse | null> {
    return this.notificationsService.notifyOrderDelivered(body.order_id);
  }

  @Post('order-cancelled')
  @ApiOperation({ summary: 'Notifier client - commande annulée' })
  async orderCancelled(@Body() body: NotifyOrderCancelledDto): Promise<OneSignalResponse | null> {
    return this.notificationsService.notifyOrderCancelled(
      body.order_id,
      body.reason,
    );
  }

  @Post('test')
  @ApiOperation({ summary: 'Test notification' })
  async test(@Body() body: TestNotificationDto): Promise<OneSignalResponse | null> {
    return this.notificationsService.sendPushToUser(
      body.user_id,
      body.title,
      body.message,
    );
  }
}
