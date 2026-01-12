import { IsString, IsEmail, IsOptional, IsBoolean, MinLength } from 'class-validator';

export class CreateUserDto {
  @IsString()
  @MinLength(10)
  phone: string;

  @IsString()
  @MinLength(2)
  fullName: string;

  @IsEmail()
  @IsOptional()
  email?: string;

  @IsString()
  @MinLength(6)
  password: string;
}

export class UpdateUserDto {
  @IsString()
  @IsOptional()
  fullName?: string;

  @IsEmail()
  @IsOptional()
  email?: string;

  @IsBoolean()
  @IsOptional()
  isActive?: boolean;

  @IsBoolean()
  @IsOptional()
  isVerified?: boolean;
}
