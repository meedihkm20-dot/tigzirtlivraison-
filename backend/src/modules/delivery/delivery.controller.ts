import { Controller, Post, Body, Get, Query } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { DeliveryService } from './delivery.service';

@ApiTags('Delivery')
@Controller('api/delivery')
export class DeliveryController {
  constructor(private deliveryService: DeliveryService) {}

  @Get('calculate-price')
  @ApiOperation({ summary: 'Calculer le prix de livraison' })
  calculatePrice(
    @Query('distance') distance: number,
    @Query('zone') zone: string,
  ) {
    const price = this.deliveryService.calculateDeliveryPrice(
      Number(distance),
      zone,
    );
    return { price, currency: 'DA' };
  }

  @Get('estimate-time')
  @ApiOperation({ summary: 'Estimer le temps de livraison' })
  estimateTime(
    @Query('distance') distance: number,
    @Query('preparation_time') preparationTime: number,
  ) {
    const minutes = this.deliveryService.calculateEstimatedTime(
      Number(distance),
      Number(preparationTime),
    );
    return { estimated_minutes: minutes };
  }

  @Post('assign-driver')
  @ApiOperation({ summary: 'Assigner un livreur' })
  async assignDriver(@Body() body: { order_id: string }) {
    const driver = await this.deliveryService.assignDriver(body.order_id);
    return { success: !!driver, driver };
  }
}
