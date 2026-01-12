import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Payment, PaymentMethod, PaymentStatus } from './entities/payment.entity';
import { AccountingTransaction, TransactionType } from './entities/accounting-transaction.entity';

@Injectable()
export class PaymentsService {
  constructor(
    @InjectRepository(Payment)
    private paymentsRepository: Repository<Payment>,
    @InjectRepository(AccountingTransaction)
    private transactionsRepository: Repository<AccountingTransaction>,
  ) {}

  async createPayment(data: {
    orderId: string;
    amount: number;
    method: PaymentMethod;
  }): Promise<Payment> {
    const payment = this.paymentsRepository.create({
      ...data,
      status: PaymentStatus.PENDING,
    });
    return this.paymentsRepository.save(payment);
  }

  async completePayment(paymentId: string, transactionId?: string): Promise<Payment> {
    await this.paymentsRepository.update(paymentId, {
      status: PaymentStatus.COMPLETED,
      transactionId,
      completedAt: new Date(),
    });
    return this.paymentsRepository.findOne({ where: { id: paymentId } });
  }

  async failPayment(paymentId: string, response?: Record<string, any>): Promise<Payment> {
    await this.paymentsRepository.update(paymentId, {
      status: PaymentStatus.FAILED,
      paymentGatewayResponse: response,
    });
    return this.paymentsRepository.findOne({ where: { id: paymentId } });
  }

  async getPaymentByOrder(orderId: string): Promise<Payment> {
    return this.paymentsRepository.findOne({ where: { orderId } });
  }

  // Accounting transactions
  async recordTransaction(data: {
    orderId?: string;
    restaurantId?: string;
    livreurId?: string;
    type: TransactionType;
    amount: number;
    description?: string;
  }): Promise<AccountingTransaction> {
    const transaction = this.transactionsRepository.create(data);
    return this.transactionsRepository.save(transaction);
  }

  async recordOrderTransactions(order: {
    id: string;
    restaurantId: string;
    livreurId?: string;
    subtotal: number;
    deliveryFee: number;
    platformCommission: number;
  }): Promise<void> {
    // Record order revenue
    await this.recordTransaction({
      orderId: order.id,
      restaurantId: order.restaurantId,
      type: TransactionType.ORDER_REVENUE,
      amount: order.subtotal,
      description: 'Revenu commande',
    });

    // Record platform commission
    await this.recordTransaction({
      orderId: order.id,
      restaurantId: order.restaurantId,
      type: TransactionType.PLATFORM_COMMISSION,
      amount: -order.platformCommission,
      description: 'Commission plateforme',
    });

    // Record delivery fee for livreur
    if (order.livreurId) {
      await this.recordTransaction({
        orderId: order.id,
        livreurId: order.livreurId,
        type: TransactionType.DELIVERY_FEE,
        amount: order.deliveryFee,
        description: 'Frais de livraison',
      });
    }
  }

  async getTransactionsByRestaurant(
    restaurantId: string,
    startDate?: Date,
    endDate?: Date,
  ): Promise<AccountingTransaction[]> {
    const query = this.transactionsRepository.createQueryBuilder('t')
      .where('t.restaurantId = :restaurantId', { restaurantId });

    if (startDate) {
      query.andWhere('t.createdAt >= :startDate', { startDate });
    }
    if (endDate) {
      query.andWhere('t.createdAt <= :endDate', { endDate });
    }

    return query.orderBy('t.createdAt', 'DESC').getMany();
  }

  async getTransactionsByLivreur(
    livreurId: string,
    startDate?: Date,
    endDate?: Date,
  ): Promise<AccountingTransaction[]> {
    const query = this.transactionsRepository.createQueryBuilder('t')
      .where('t.livreurId = :livreurId', { livreurId });

    if (startDate) {
      query.andWhere('t.createdAt >= :startDate', { startDate });
    }
    if (endDate) {
      query.andWhere('t.createdAt <= :endDate', { endDate });
    }

    return query.orderBy('t.createdAt', 'DESC').getMany();
  }
}
