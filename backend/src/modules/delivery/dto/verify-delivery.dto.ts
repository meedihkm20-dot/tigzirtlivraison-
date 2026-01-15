import { IsString, IsUUID, Length } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class VerifyDeliveryDto {
  @ApiProperty()
  @IsUUID()
  order_id: string;

  @ApiProperty({ description: 'Code de vérification à 4-6 caractères' })
  @IsString()
  @Length(4, 6)
  verification_code: string;
}
