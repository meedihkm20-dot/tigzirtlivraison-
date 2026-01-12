import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToMany } from 'typeorm';
import { Order } from './order.entity';
import { MenuItem } from '../restaurants/entities/menu-item.entity';
import { OrderItemOption } from './order-item-option.entity';

@Entity('order_items')
export class OrderItem {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  orderId: string;

  @Column({ nullable: true })
  menuItemId?: string;

  @Column({ length: 150 })
  itemName: string;

  @Column({ type: 'decimal', precision: 10, scale: 2 })
  itemPrice: number;

  @Column({ default: 1 })
  quantity: number;

  @Column({ type: 'decimal', precision: 10, scale: 2 })
  totalPrice: number;

  @Column({ nullable: true })
  specialInstructions?: string;

  // Relations
  @ManyToOne(() => Order, order => order.orderItems)
  order: Order;

  @ManyToOne(() => MenuItem, menuItem => menuItem.orderItems)
  menuItem?: MenuItem;

  @OneToMany(() => OrderItemOption, orderItemOption => orderItemOption.orderItem)
  options: OrderItemOption[];
}
