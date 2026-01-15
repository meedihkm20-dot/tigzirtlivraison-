import { Controller, Post, Body, Param, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { OrdersService } from './orders.service';
import { SupabaseAuthGuard } from '../../common/guards/supabase-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { CreateOrderDto } from './dto/create-order.dto';
import { CreateOrderResponse } from './dto/order-item.dto';
import { ChangeStatusDto } from './dto/change-status.dto';
import { CancelOrderDto } from './dto/cancel-order.dto';

@ApiTags('Orders')
@Controller('api/orders')
export class OrdersController {
  constructor(private ordersService: OrdersService) {}

  @Post('create')
  @UseGuards(SupabaseAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Créer une commande' })
  async create(
    @CurrentUser() user: any,
    @Body() dto: CreateOrderDto,
  ): Promise<CreateOrderResponse> {
    return this.ordersService.createOrder(user.id, dto);
  }

  @Post(':id/accept')
  @UseGuards(SupabaseAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Accepter une commande (restaurant)' })
  async accept(@Param('id') id: string, @CurrentUser() user: any) {
    return this.ordersService.acceptOrder(id, user.id);
  }

  @Post(':id/ready')
  @UseGuards(SupabaseAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Marquer prête (restaurant)' })
  async ready(@Param('id') id: string, @CurrentUser() user: any) {
    return this.ordersService.markReady(id, user.id);
  }

  @Post(':id/delivered')
  @UseGuards(SupabaseAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Confirmer livraison (livreur)' })
  async delivered(@Param('id') id: string, @CurrentUser() user: any) {
    return this.ordersService.markDelivered(id, user.id);
  }

  @Post(':id/status')
  @UseGuards(SupabaseAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Changer le statut (transitions validées)' })
  async changeStatus(
    @Param('id') id: string,
    @CurrentUser() user: any,
    @Body() dto: ChangeStatusDto,
  ) {
    return this.ordersService.changeOrderStatus(id, user.id, dto);
  }

  @Post(':id/cancel')
  @UseGuards(SupabaseAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Annuler une commande' })
  async cancel(
    @Param('id') id: string,
    @CurrentUser() user: any,
    @Body() dto: CancelOrderDto,
  ) {
    return this.ordersService.cancelOrder(id, user.id, dto);
  }
}
