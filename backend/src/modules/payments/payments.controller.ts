import { Controller, Get, Post, Put, Body, Param, Query, UseGuards, Request } from '@nestjs/common';
import { PaymentsService } from './payments.service';
import { InvoicesService } from './invoices.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('payments')
export class PaymentsController {
  constructor(
    private readonly paymentsService: PaymentsService,
    private readonly invoicesService: InvoicesService,
  ) {}

  @Get('transactions')
  @UseGuards(JwtAuthGuard)
  getTransactions(
    @Request() req,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
  ) {
    const { id, role } = req.user;
    const start = startDate ? new Date(startDate) : undefined;
    const end = endDate ? new Date(endDate) : undefined;

    if (role === 'restaurant') {
      return this.paymentsService.getTransactionsByRestaurant(id, start, end);
    } else if (role === 'livreur') {
      return this.paymentsService.getTransactionsByLivreur(id, start, end);
    }
    return [];
  }

  @Get('invoices')
  @UseGuards(JwtAuthGuard)
  getInvoices(@Request() req) {
    if (req.user.role === 'restaurant') {
      return this.invoicesService.findByRestaurant(req.user.id);
    }
    return [];
  }

  @Get('invoices/:id')
  @UseGuards(JwtAuthGuard)
  getInvoice(@Param('id') id: string) {
    return this.invoicesService.findOne(id);
  }

  @Put('invoices/:id/pay')
  @UseGuards(JwtAuthGuard)
  markInvoiceAsPaid(@Param('id') id: string) {
    return this.invoicesService.markAsPaid(id);
  }
}
