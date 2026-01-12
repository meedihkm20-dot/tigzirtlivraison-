import { IsString, IsOptional, IsNumber, IsDecimal, IsEnum } from 'class-validator';
import { Type } from 'class-transformer';

export class UpdateUserDto {
  @IsString()
  @IsOptional()
  fullName?: string;

  @IsString()
  @IsOptional()
  email?: string;

  @IsString()
  @IsOptional()
  defaultAddressId?: string;
}

export class CreateAddressDto {
  @IsString()
  @IsOptional()
  label?: string;

  @IsString()
  addressLine: string;

  @IsString()
  city: string;

  @IsString()
  wilaya: string;

  @IsNumber()
  @IsOptional()
  @Type(() => Number)
  latitude?: number;

  @IsNumber()
  @IsOptional()
  @Type(() => Number)
  longitude?: number;

  @IsString()
  @IsOptional()
  isDefault?: string;
}
