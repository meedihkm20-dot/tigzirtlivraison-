import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Order, OrderStatus } from './entities/order.entity';
import { OrderItem } from './entities/order-item.entity';
import { OrderItemOption } from './entities/order-item-option.entity';
import { OrderStatusHistory } from './entities/order-status-history.entity';

@Injectable()
export class OrdersService {
  constructor(
    @InjectRepository(Order)
    private ordersRepository: Repository<Order>,
    @InjectRepository(OrderItem)
    private orderItemsRepository: Repository<OrderItem>,
    @InjectRepository(OrderItemOption)
    private orderItemOptionsRepository: Repository<OrderItemOption>,
    @InjectRepository(OrderStatusHistory)
    private statusHistoryRepository: Repository<OrderStatusHistory>,
  ) {}

  // Generate order number: DZ-YYYYMMDD-XXX
  private generateOrderNumber(): string {
    const date = new Date();
    const dateStr = date.toISOString().slice(0, 10).replace(/-/g, '');
    const random = Math.floor(Math.random() * 1000).toString().padStart(3, '0');
    return `DZ-${dateStr}-${random}`;
  }

  // Generate 4-digit confirmation code
  private generateConfirmationCode(): string {
    return Math.floor(1000 + Math.random() * 9000).toString();
  }

  async create(data: {
    userId: string;
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
    commissionRate?: number;
  }): Promise<Order> {
    // Calculate totals
    let subtotal = 0;
    for (const item of data.items) {
      let itemTotal = item.itemPrice * item.quantity;
      if (item.options) {
        for (const opt of item.options) {
          itemTotal += opt.price * item.quantity;
        }
      }
      subtotal += itemTotal;
    }

    const totalAmount = subtotal + data.deliveryFee;
    const commissionRate = data.commissionRate || 10;
    const platformCommission = (subtotal * commissionRate) / 100;

    // Create order
    const order = this.ordersRepository.create({
      orderNumber: this.generateOrderNumber(),
      userId: data.userId,
      restaurantId: data.restaurantId,
      deliveryAddressId: data.deliveryAddressId,
      subtotal,
      deliveryFee: data.deliveryFee,
      totalAmount,
      platformCommission,
      commissionRate,
      confirmationCode: this.generateConfirmationCode(),
      customerNotes: data.customerNotes,
      status: OrderStatus.PENDING,
    });

    const savedOrder = await this.ordersRepository.save(order);

    // Create order items
    for (const item of data.items) {
      let itemTotal = item.itemPrice * item.quantity;
      if (item.options) {
        for (const opt of item.options) {
          itemTotal += opt.price * item.quantity;
        }
      }

      const orderItem = this.orderItemsRepository.create({
        orderId: savedOrder.id,
        menuItemId: item.menuItemId,
        itemName: item.itemName,
        itemPrice: item.itemPrice,
        quantity: item.quantity,
        totalPrice: itemTotal,
        specialInstructions: item.specialInstructions,
      });

      const savedItem = await this.orderItemsRepository.save(orderItem);

      // Create item options
      if (item.options) {
        for (const opt of item.options) {
          const orderItemOption = this.orderItemOptionsRepository.create({
            orderItemId: savedItem.id,
            optionName: opt.optionName,
            choiceName: opt.choiceName,
            price: opt.price,
          });
          await this.orderItemOptionsRepository.save(orderItemOption);
        }
      }
    }

    // Add status history
    await this.addStatusHistory(savedOrder.id, OrderStatus.PENDING, 'system');

    return this.findOne(savedOrder.id);
  }

  async findAll(filters?: {
    userId?: string;
    restaurantId?: string;
    livreurId?: string;
    status?: OrderStatus;
  }): Promise<Order[]> {
    const query = this.ordersRepository.createQueryBuilder('order')
      .leftJoinAndSelect('order.orderItems', 'items')
      .orderBy('order.createdAt', 'DESC');

    if (filters?.userId) {
      query.andWhere('order.userId = :userId', { userId: filters.userId });
    }
    if (filters?.restaurantId) {
      query.andWhere('order.restaurantId = :restaurantId', { restaurantId: filters.restaurantId });
    }
    if (filters?.livreurId) {
      query.andWhere('order.livreurId = :livreurId', { livreurId: filters.livreurId });
    }
    if (filters?.status) {
      query.andWhere('order.status = :status', { status: filters.status });
    }

    return query.getMany();
  }

  async findOne(id: string): Promise<Order> {
    const order = await this.ordersRepository.findOne({
      where: { id },
      relations: ['orderItems', 'orderItems.options', 'statusHistory'],
    });
    if (!order) {
      throw new NotFoundException(`Order #${id} not found`);
    }
    return order;
  }

  async findByOrderNumber(orderNumber: string): Promise<Order> {
    const order = await this.ordersRepository.findOne({
      where: { orderNumber },
      relations: ['orderItems', 'orderItems.options'],
    });
    if (!order) {
      throw new NotFoundException(`Order ${orderNumber} not found`);
    }
    return order;
  }

  async updateStatus(
    id: string,
    status: OrderStatus,
    changedBy: string,
    notes?: string,
  ): Promise<Order> {
    const order = await this.findOne(id);

    // Validate status transition
    const validTransitions: Record<OrderStatus, OrderStatus[]> = {
      [OrderStatus.PENDING]: [OrderStatus.ACCEPTED, OrderStatus.CANCELLED],
      [OrderStatus.ACCEPTED]: [OrderStatus.PREPARING, OrderStatus.CANCELLED],
      [OrderStatus.PREPARING]: [OrderStatus.READY, OrderStatus.CANCELLED],
      [OrderStatus.READY]: [OrderStatus.PICKED_UP, OrderStatus.CANCELLED],
      [OrderStatus.PICKED_UP]: [OrderStatus.DELIVERING],
      [OrderStatus.DELIVERING]: [OrderStatus.DELIVERED],
      [OrderStatus.DELIVERED]: [],
      [OrderStatus.CANCELLED]: [],
    };

    if (!validTransitions[order.status].includes(status)) {
      throw new BadRequestException(
        `Cannot transition from ${order.status} to ${status}`,
      );
    }

    // Update timestamps based on status
    const updateData: Partial<Order> = { status };
    const now = new Date();

    switch (status) {
      case OrderStatus.ACCEPTED:
        updateData.acceptedAt = now;
        break;
      case OrderStatus.PREPARING:
        updateData.preparingAt = now;
        break;
      case OrderStatus.READY:
        updateData.readyAt = now;
        break;
      case OrderStatus.PICKED_UP:
        updateData.pickedUpAt = now;
        break;
      case OrderStatus.DELIVERED:
        updateData.deliveredAt = now;
        break;
      case OrderStatus.CANCELLED:
        updateData.cancelledAt = now;
        updateData.cancelledBy = changedBy;
        updateData.cancellationReason = notes;
        break;
    }

    await this.ordersRepository.update(id, updateData);
    await this.addStatusHistory(id, status, changedBy, notes);

    return this.findOne(id);
  }

  async assignLivreur(orderId: string, livreurId: string): Promise<Order> {
    await this.ordersRepository.update(orderId, { livreurId });
    return this.findOne(orderId);
  }

  async addStatusHistory(
    orderId: string,
    status: OrderStatus,
    changedBy: string,
    notes?: string,
  ): Promise<void> {
    const history = this.statusHistoryRepository.create({
      orderId,
      status,
      changedBy,
      notes,
    });
    await this.statusHistoryRepository.save(history);
  }

  // Get pending orders for a restaurant
  async getPendingOrdersForRestaurant(restaurantId: string): Promise<Order[]> {
    return this.ordersRepository.find({
      where: { restaurantId, status: OrderStatus.PENDING },
      relations: ['orderItems'],
      order: { createdAt: 'ASC' },
    });
  }

  // Get active orders for a livreur
  async getActiveOrdersForLivreur(livreurId: string): Promise<Order[]> {
    return this.ordersRepository
      .createQueryBuilder('order')
      .where('order.livreurId = :livreurId', { livreurId })
      .andWhere('order.status IN (:...statuses)', {
        statuses: [
          OrderStatus.ACCEPTED,
          OrderStatus.PREPARING,
          OrderStatus.READY,
          OrderStatus.PICKED_UP,
          OrderStatus.DELIVERING,
        ],
      })
      .leftJoinAndSelect('order.orderItems', 'items')
      .orderBy('order.createdAt', 'ASC')
      .getMany();
  }
}
