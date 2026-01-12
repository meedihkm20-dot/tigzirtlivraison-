import { Controller, Get, Post, Put, Body, Param, Query, UseGuards, Request, ForbiddenException } from '@nestjs/common';
import { OrdersService } from './orders.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { OrderStatus } from './entities/order.entity';

@Controller('orders')
@UseGuards(JwtAuthGuard, RolesGuard)
export class OrdersController {
  constructor(private readonly ordersService: OrdersService) {}

  @Post()
  @Roles('user')
  create(
    @CurrentUser('id') userId: string,
    @Body() data: {
      restaurantId: string;
      deliveryAddressId: string;
      items: Array<{
        menuItemId: string;
        itemName: string;
        itemPrice: number;
        quantity: number;
        specialInstructions?: string;
        options?: Array<{ optionName: string; choiceName?: string; price: number }>;
      }>;
      deliveryFee: number;
      customerNotes?: string;
    },
  ) {
    return this.ordersService.create({
      ...data,
      userId,
    });
  }

  @Get()
  findAll(
    @CurrentUser() user: { id: string; role: string },
    @Query('status') status?: OrderStatus,
  ) {
    const filters: any = { status };

    // Users can only see their own orders
    if (user.role === 'user') {
      filters.userId = user.id;
    } else if (user.role === 'restaurant') {
      filters.restaurantId = user.id;
    } else if (user.role === 'livreur') {
      filters.livreurId = user.id;
    }

    return this.ordersService.findAll(filters);
  }

  @Get('pending')
  @Roles('restaurant')
  getPendingOrders(@CurrentUser('id') restaurantId: string) {
    return this.ordersService.getPendingOrdersForRestaurant(restaurantId);
  }

  @Get('active')
  @Roles('livreur')
  getActiveOrders(@CurrentUser('id') livreurId: string) {
    return this.ordersService.getActiveOrdersForLivreur(livreurId);
  }

  @Get(':id')
  async findOne(
    @Param('id') id: string,
    @CurrentUser() user: { id: string; role: string },
  ) {
    const order = await this.ordersService.findOne(id);
    
    // Verify user has access to this order
    if (user.role === 'user' && order.userId !== user.id) {
      throw new ForbiddenException('Access denied');
    }
    if (user.role === 'restaurant' && order.restaurantId !== user.id) {
      throw new ForbiddenException('Access denied');
    }
    if (user.role === 'livreur' && order.livreurId !== user.id) {
      throw new ForbiddenException('Access denied');
    }

    return order;
  }

  @Get('number/:orderNumber')
  async findByOrderNumber(
    @Param('orderNumber') orderNumber: string,
    @CurrentUser() user: { id: string; role: string },
  ) {
    const order = await this.ordersService.findByOrderNumber(orderNumber);
    
    // Verify user has access
    if (user.role === 'user' && order.userId !== user.id) {
      throw new ForbiddenException('Access denied');
    }

    return order;
  }

  @Put(':id/status')
  async updateStatus(
    @CurrentUser() user: { id: string; role: string },
    @Param('id') id: string,
    @Body() body: { status: OrderStatus; notes?: string },
  ) {
    const order = await this.ordersService.findOne(id);
    
    // Verify permissions based on status change
    this.validateStatusChangePermission(order, body.status, user);

    return this.ordersService.updateStatus(id, body.status, user.role, body.notes);
  }

  @Put(':id/accept')
  @Roles('livreur', 'restaurant')
  async acceptOrder(
    @CurrentUser() user: { id: string; role: string },
    @Param('id') id: string,
  ) {
    const order = await this.ordersService.findOne(id);

    if (user.role === 'livreur') {
      // Livreur accepts delivery
      await this.ordersService.assignLivreur(id, user.id);
      return this.ordersService.updateStatus(id, OrderStatus.ACCEPTED, 'livreur');
    }

    // Restaurant accepts order
    if (order.restaurantId !== user.id) {
      throw new ForbiddenException('Access denied');
    }
    return this.ordersService.updateStatus(id, OrderStatus.ACCEPTED, 'restaurant');
  }

  @Put(':id/preparing')
  @Roles('restaurant')
  async startPreparing(
    @CurrentUser('id') restaurantId: string,
    @Param('id') id: string,
  ) {
    const order = await this.ordersService.findOne(id);
    if (order.restaurantId !== restaurantId) {
      throw new ForbiddenException('Access denied');
    }
    return this.ordersService.updateStatus(id, OrderStatus.PREPARING, 'restaurant');
  }

  @Put(':id/ready')
  @Roles('restaurant')
  async markReady(
    @CurrentUser('id') restaurantId: string,
    @Param('id') id: string,
  ) {
    const order = await this.ordersService.findOne(id);
    if (order.restaurantId !== restaurantId) {
      throw new ForbiddenException('Access denied');
    }
    return this.ordersService.updateStatus(id, OrderStatus.READY, 'restaurant');
  }

  @Put(':id/picked-up')
  @Roles('livreur')
  async markPickedUp(
    @CurrentUser('id') livreurId: string,
    @Param('id') id: string,
  ) {
    const order = await this.ordersService.findOne(id);
    if (order.livreurId !== livreurId) {
      throw new ForbiddenException('Access denied');
    }
    return this.ordersService.updateStatus(id, OrderStatus.PICKED_UP, 'livreur');
  }

  @Put(':id/delivering')
  @Roles('livreur')
  async startDelivering(
    @CurrentUser('id') livreurId: string,
    @Param('id') id: string,
  ) {
    const order = await this.ordersService.findOne(id);
    if (order.livreurId !== livreurId) {
      throw new ForbiddenException('Access denied');
    }
    return this.ordersService.updateStatus(id, OrderStatus.DELIVERING, 'livreur');
  }

  @Put(':id/delivered')
  @Roles('livreur')
  async markDelivered(
    @CurrentUser('id') livreurId: string,
    @Param('id') id: string,
    @Body('confirmationCode') confirmationCode?: string,
  ) {
    const order = await this.ordersService.findOne(id);
    if (order.livreurId !== livreurId) {
      throw new ForbiddenException('Access denied');
    }
    
    // Verify confirmation code
    if (order.confirmationCode && order.confirmationCode !== confirmationCode) {
      throw new ForbiddenException('Invalid confirmation code');
    }

    return this.ordersService.updateStatus(id, OrderStatus.DELIVERED, 'livreur');
  }

  @Put(':id/cancel')
  async cancelOrder(
    @CurrentUser() user: { id: string; role: string },
    @Param('id') id: string,
    @Body('reason') reason?: string,
  ) {
    const order = await this.ordersService.findOne(id);
    
    // Verify user can cancel this order
    if (user.role === 'user' && order.userId !== user.id) {
      throw new ForbiddenException('Access denied');
    }
    if (user.role === 'restaurant' && order.restaurantId !== user.id) {
      throw new ForbiddenException('Access denied');
    }
    if (user.role === 'livreur' && order.livreurId !== user.id) {
      throw new ForbiddenException('Access denied');
    }

    // Users can only cancel pending orders
    if (user.role === 'user' && order.status !== OrderStatus.PENDING) {
      throw new ForbiddenException('Cannot cancel order after it has been accepted');
    }

    return this.ordersService.updateStatus(id, OrderStatus.CANCELLED, user.role, reason);
  }

  private validateStatusChangePermission(
    order: any,
    newStatus: OrderStatus,
    user: { id: string; role: string },
  ): void {
    const restaurantStatuses = [OrderStatus.PREPARING, OrderStatus.READY];
    const livreurStatuses = [OrderStatus.PICKED_UP, OrderStatus.DELIVERING, OrderStatus.DELIVERED];

    if (restaurantStatuses.includes(newStatus) && user.role !== 'restaurant') {
      throw new ForbiddenException('Only restaurants can set this status');
    }

    if (livreurStatuses.includes(newStatus) && user.role !== 'livreur') {
      throw new ForbiddenException('Only livreurs can set this status');
    }

    if (user.role === 'restaurant' && order.restaurantId !== user.id) {
      throw new ForbiddenException('Access denied');
    }

    if (user.role === 'livreur' && order.livreurId !== user.id) {
      throw new ForbiddenException('Access denied');
    }
  }
}
