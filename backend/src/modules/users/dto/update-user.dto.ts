import { IsString, IsOptional, IsNumber, IsBoolean, MaxLength, IsEmail } from 'class-validator';
import { Transform, Type } from 'class-transformer';

export class UpdateUserDto {
  @IsString()
  @IsOptional()
  @MaxLength(100)
  @Transform(({ value }) => value?.trim())
  fullName?: string;

  @IsEmail()
  @IsOptional()
  @MaxLength(255)
  @Transform(({ value }) => value?.toLowerCase().trim())
  email?: string;

  @IsString()
  @IsOptional()
  defaultAddressId?: string;
}

export class CreateAddressDto {
  @IsString()
  @IsOptional()
  @MaxLength(50)
  label?: string;

  @IsString()
  @MaxLength(255)
  addressLine: string;

  @IsString()
  @MaxLength(100)
  city: string;

  @IsString()
  @MaxLength(100)
  wilaya: string;

  @IsNumber()
  @IsOptional()
  @Type(() => Number)
  latitude?: number;

  @IsNumber()
  @IsOptional()
  @Type(() => Number)
  longitude?: number;

  @IsBoolean()
  @IsOptional()
  @Type(() => Boolean)
  isDefault?: boolean;
}
