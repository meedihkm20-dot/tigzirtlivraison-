import { IsString, IsOptional, IsEnum } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export enum CancellationReason {
  CUSTOMER_REQUEST = 'customer_request',
  RESTAURANT_UNAVAILABLE = 'restaurant_unavailable',
  ITEM_UNAVAILABLE = 'item_unavailable',
  DRIVER_UNAVAILABLE = 'driver_unavailable',
  RESTAURANT_CLOSED = 'restaurant_closed',
  OTHER = 'other',
}

export class CancelOrderDto {
  @ApiProperty({ enum: CancellationReason })
  @IsEnum(CancellationReason)
  reason: CancellationReason;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  details?: string;
}
