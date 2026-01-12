import { IsString, IsEnum, MinLength, IsOptional, IsEmail } from 'class-validator';

export class RegisterDto {
  @IsString()
  @MinLength(10)
  phone: string;

  @IsString()
  @MinLength(6)
  password: string;

  @IsEnum(['user', 'restaurant', 'livreur'])
  role: 'user' | 'restaurant' | 'livreur';

  @IsString()
  @MinLength(2)
  fullName: string;

  @IsEmail()
  @IsOptional()
  email?: string;
}
