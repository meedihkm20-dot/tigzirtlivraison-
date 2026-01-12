import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, ManyToOne } from 'typeorm';
import { Order } from './order.entity';

@Entity('order_status_history')
export class OrderStatusHistory {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  orderId: string;

  @Column({ type: 'enum', enumName: 'order_status' })
  status: string;

  @Column({ length: 20, nullable: true })
  changedBy?: string;

  @Column({ nullable: true })
  notes?: string;

  @CreateDateColumn()
  createdAt: Date;

  // Relations
  @ManyToOne(() => Order, order => order.statusHistory)
  order: Order;
}
