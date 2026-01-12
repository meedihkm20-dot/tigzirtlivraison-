import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

export enum InvoiceStatus {
  PENDING = 'pending',
  PAID = 'paid',
  OVERDUE = 'overdue',
}

@Entity('invoices')
export class Invoice {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true, length: 30 })
  invoiceNumber: string;

  @Column()
  restaurantId: string;

  @Column({ type: 'date' })
  periodStart: Date;

  @Column({ type: 'date' })
  periodEnd: Date;

  @Column()
  totalOrders: number;

  @Column({ type: 'decimal', precision: 12, scale: 2 })
  totalSales: number;

  @Column({ type: 'decimal', precision: 4, scale: 2 })
  commissionRate: number;

  @Column({ type: 'decimal', precision: 12, scale: 2 })
  commissionAmount: number;

  @Column({ type: 'enum', enum: InvoiceStatus, default: InvoiceStatus.PENDING })
  status: InvoiceStatus;

  @Column({ nullable: true })
  paidAt?: Date;

  @CreateDateColumn()
  createdAt: Date;

  @Column({ type: 'date' })
  dueDate: Date;
}
