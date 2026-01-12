import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Payment } from './entities/payment.entity';
import { AccountingTransaction } from './entities/accounting-transaction.entity';
import { Invoice } from './entities/invoice.entity';
import { PaymentsService } from './payments.service';
import { PaymentsController } from './payments.controller';
import { InvoicesService } from './invoices.service';

@Module({
  imports: [TypeOrmModule.forFeature([Payment, AccountingTransaction, Invoice])],
  controllers: [PaymentsController],
  providers: [PaymentsService, InvoicesService],
  exports: [PaymentsService, InvoicesService],
})
export class PaymentsModule {}
