import { IsString, IsEnum, MinLength, MaxLength, IsNotEmpty } from 'class-validator';
import { Transform } from 'class-transformer';

export class LoginDto {
  @IsString()
  @IsNotEmpty()
  @MinLength(10)
  @MaxLength(15)
  @Transform(({ value }) => value?.replace(/\s/g, ''))
  phone: string;

  @IsString()
  @IsNotEmpty()
  @MinLength(6)
  @MaxLength(100)
  password: string;

  @IsEnum(['user', 'restaurant', 'livreur'])
  role: 'user' | 'restaurant' | 'livreur';
}
