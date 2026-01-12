import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, ManyToOne, OneToMany, JoinColumn } from 'typeorm';
import { OrderItem } from './order-item.entity';
import { OrderStatusHistory } from './order-status-history.entity';

export enum OrderStatus {
  PENDING = 'pending',
  ACCEPTED = 'accepted',
  PREPARING = 'preparing',
  READY = 'ready',
  PICKED_UP = 'picked_up',
  DELIVERING = 'delivering',
  DELIVERED = 'delivered',
  CANCELLED = 'cancelled'
}

@Entity('orders')
export class Order {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true, length: 20 })
  orderNumber: string;

  @Column({ nullable: true })
  userId?: string;

  @Column()
  restaurantId: string;

  @Column({ nullable: true })
  livreurId?: string;

  @Column({ nullable: true })
  deliveryAddressId?: string;

  @Column({ type: 'varchar', length: 20, default: 'pending' })
  status: OrderStatus;

  @Column({ type: 'decimal', precision: 10, scale: 2 })
  subtotal: number;

  @Column({ type: 'decimal', precision: 10, scale: 2 })
  deliveryFee: number;

  @Column({ type: 'decimal', precision: 10, scale: 2 })
  totalAmount: number;

  @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
  platformCommission?: number;

  @Column({ type: 'decimal', precision: 4, scale: 2, nullable: true })
  commissionRate?: number;

  @Column({ type: 'decimal', precision: 5, scale: 2, nullable: true })
  deliveryDistanceKm?: number;

  @Column({ nullable: true })
  estimatedDeliveryTime?: number;

  @Column({ length: 4, nullable: true })
  confirmationCode?: string;

  @Column({ nullable: true })
  customerNotes?: string;

  @Column({ nullable: true })
  restaurantNotes?: string;

  @CreateDateColumn()
  createdAt: Date;

  @Column({ nullable: true })
  acceptedAt?: Date;

  @Column({ nullable: true })
  preparingAt?: Date;

  @Column({ nullable: true })
  readyAt?: Date;

  @Column({ nullable: true })
  pickedUpAt?: Date;

  @Column({ nullable: true })
  deliveredAt?: Date;

  @Column({ nullable: true })
  cancelledAt?: Date;

  @Column({ length: 20, nullable: true })
  cancelledBy?: string;

  @Column({ nullable: true })
  cancellationReason?: string;

  // Relations - using string references to avoid circular imports
  @OneToMany(() => OrderItem, orderItem => orderItem.order, { cascade: true })
  orderItems: OrderItem[];

  @OneToMany(() => OrderStatusHistory, statusHistory => statusHistory.order, { cascade: true })
  statusHistory: OrderStatusHistory[];
}
