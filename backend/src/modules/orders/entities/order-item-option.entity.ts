import { Entity, PrimaryGeneratedColumn, Column, ManyToOne } from 'typeorm';
import { OrderItem } from './order-item.entity';

@Entity('order_item_options')
export class OrderItemOption {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  orderItemId: string;

  @Column({ length: 100 })
  optionName: string;

  @Column({ nullable: true, length: 100 })
  choiceName?: string;

  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0 })
  price: number;

  // Relations
  @ManyToOne(() => OrderItem, orderItem => orderItem.options)
  orderItem: OrderItem;
}
