import { Module } from '@nestjs/common';
import { OrdersController } from './orders.controller';
import { OrdersService } from './orders.service';
import { NotificationsModule } from '../notifications/notifications.module';
import { DeliveryModule } from '../delivery/delivery.module';

@Module({
  imports: [NotificationsModule, DeliveryModule],
  controllers: [OrdersController],
  providers: [OrdersService],
})
export class OrdersModule {}
