import { Controller, Get, Post, Put, Body, Param, UseGuards, Request } from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('notifications')
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Get()
  @UseGuards(JwtAuthGuard)
  findAll(@Request() req) {
    const { id, role } = req.user;
    if (role === 'user') {
      return this.notificationsService.findByUser(id);
    } else if (role === 'restaurant') {
      return this.notificationsService.findByRestaurant(id);
    } else if (role === 'livreur') {
      return this.notificationsService.findByLivreur(id);
    }
    return [];
  }

  @Get('unread-count')
  @UseGuards(JwtAuthGuard)
  getUnreadCount(@Request() req) {
    const { id, role } = req.user;
    return this.notificationsService.getUnreadCount(role, id);
  }

  @Put(':id/read')
  @UseGuards(JwtAuthGuard)
  markAsRead(@Param('id') id: string) {
    return this.notificationsService.markAsRead(id);
  }

  @Put('read-all')
  @UseGuards(JwtAuthGuard)
  markAllAsRead(@Request() req) {
    const { id, role } = req.user;
    return this.notificationsService.markAllAsRead(role, id);
  }

  @Post('device-token')
  @UseGuards(JwtAuthGuard)
  registerDeviceToken(
    @Request() req,
    @Body() body: { token: string; deviceType?: string },
  ) {
    const { id, role } = req.user;
    const data: any = { token: body.token, deviceType: body.deviceType };
    
    if (role === 'user') data.userId = id;
    else if (role === 'restaurant') data.restaurantId = id;
    else if (role === 'livreur') data.livreurId = id;

    return this.notificationsService.registerDeviceToken(data);
  }
}
