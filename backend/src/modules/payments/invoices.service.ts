import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between } from 'typeorm';
import { Invoice, InvoiceStatus } from './entities/invoice.entity';

@Injectable()
export class InvoicesService {
  constructor(
    @InjectRepository(Invoice)
    private invoicesRepository: Repository<Invoice>,
  ) {}

  private generateInvoiceNumber(): string {
    const year = new Date().getFullYear();
    const random = Math.floor(Math.random() * 10000).toString().padStart(4, '0');
    return `FACT-${year}-${random}`;
  }

  async createInvoice(data: {
    restaurantId: string;
    periodStart: Date;
    periodEnd: Date;
    totalOrders: number;
    totalSales: number;
    commissionRate: number;
    commissionAmount: number;
  }): Promise<Invoice> {
    const dueDate = new Date();
    dueDate.setDate(dueDate.getDate() + 15); // 15 days to pay

    const invoice = this.invoicesRepository.create({
      ...data,
      invoiceNumber: this.generateInvoiceNumber(),
      dueDate,
    });
    return this.invoicesRepository.save(invoice);
  }

  async findByRestaurant(restaurantId: string): Promise<Invoice[]> {
    return this.invoicesRepository.find({
      where: { restaurantId },
      order: { createdAt: 'DESC' },
    });
  }

  async findOne(id: string): Promise<Invoice> {
    return this.invoicesRepository.findOne({ where: { id } });
  }

  async markAsPaid(id: string): Promise<Invoice> {
    await this.invoicesRepository.update(id, {
      status: InvoiceStatus.PAID,
      paidAt: new Date(),
    });
    return this.findOne(id);
  }

  async getPendingInvoices(): Promise<Invoice[]> {
    return this.invoicesRepository.find({
      where: { status: InvoiceStatus.PENDING },
      order: { dueDate: 'ASC' },
    });
  }

  async getOverdueInvoices(): Promise<Invoice[]> {
    const today = new Date();
    return this.invoicesRepository
      .createQueryBuilder('invoice')
      .where('invoice.status = :status', { status: InvoiceStatus.PENDING })
      .andWhere('invoice.dueDate < :today', { today })
      .getMany();
  }

  async markOverdueInvoices(): Promise<void> {
    const today = new Date();
    await this.invoicesRepository
      .createQueryBuilder()
      .update(Invoice)
      .set({ status: InvoiceStatus.OVERDUE })
      .where('status = :status', { status: InvoiceStatus.PENDING })
      .andWhere('dueDate < :today', { today })
      .execute();
  }
}
