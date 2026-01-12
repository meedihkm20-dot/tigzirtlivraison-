import { IsString, IsEnum, MinLength, IsOptional } from 'class-validator';

export class LoginDto {
  @IsString()
  @MinLength(10)
  phone: string;

  @IsString()
  @MinLength(6)
  password: string;

  @IsEnum(['user', 'restaurant', 'livreur'])
  role: 'user' | 'restaurant' | 'livreur';
}

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

  @IsString()
  @IsOptional()
  email?: string;
}
