import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

export enum TransactionType {
  ORDER_REVENUE = 'order_revenue',
  DELIVERY_FEE = 'delivery_fee',
  PLATFORM_COMMISSION = 'platform_commission',
  RESTAURANT_PAYOUT = 'restaurant_payout',
  LIVREUR_PAYOUT = 'livreur_payout',
}

@Entity('accounting_transactions')
export class AccountingTransaction {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ nullable: true })
  orderId?: string;

  @Column({ nullable: true })
  restaurantId?: string;

  @Column({ nullable: true })
  livreurId?: string;

  @Column({ type: 'enum', enum: TransactionType })
  type: TransactionType;

  @Column({ type: 'decimal', precision: 12, scale: 2 })
  amount: number;

  @Column({ type: 'decimal', precision: 12, scale: 2, nullable: true })
  balanceBefore?: number;

  @Column({ type: 'decimal', precision: 12, scale: 2, nullable: true })
  balanceAfter?: number;

  @Column({ nullable: true })
  description?: string;

  @CreateDateColumn()
  createdAt: Date;
}
