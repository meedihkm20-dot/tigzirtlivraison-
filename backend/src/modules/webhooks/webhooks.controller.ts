import { Controller, Post, Body, Headers, Logger } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { NotificationsService } from '../notifications/notifications.service';

@ApiTags('Webhooks')
@Controller('api/webhooks')
export class WebhooksController {
  private readonly logger = new Logger(WebhooksController.name);

  constructor(private notificationsService: NotificationsService) {}

  @Post('supabase')
  @ApiOperation({ summary: 'Webhook Supabase pour les changements de commandes' })
  async supabaseWebhook(
    @Body() body: any,
    @Headers('x-supabase-webhook-secret') secret: string,
  ) {
    this.logger.log(`Webhook received: ${JSON.stringify(body)}`);

    // Vérifier le secret (optionnel mais recommandé)
    // if (secret !== process.env.SUPABASE_WEBHOOK_SECRET) {
    //   throw new UnauthorizedException('Invalid webhook secret');
    // }

    const { type, table, record, old_record } = body;

    if (table === 'orders') {
      const orderId = record?.id;
      const newStatus = record?.status;
      const oldStatus = old_record?.status;

      if (newStatus !== oldStatus && orderId) {
        switch (newStatus) {
          // ⚠️ SQL: 'confirmed' (pas 'accepted')
          case 'confirmed':
            await this.notificationsService.notifyOrderConfirmed(orderId);
            break;
          case 'ready':
            await this.notificationsService.notifyOrderReady(orderId);
            break;
          case 'delivered':
            await this.notificationsService.notifyOrderDelivered(orderId);
            break;
          case 'cancelled':
            await this.notificationsService.notifyOrderCancelled(orderId);
            break;
        }
      }
    }

    return { received: true };
  }
}
