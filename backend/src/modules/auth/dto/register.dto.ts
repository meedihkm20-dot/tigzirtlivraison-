import { IsString, IsEnum, MinLength, MaxLength, IsOptional, IsEmail, IsNotEmpty, Matches } from 'class-validator';
import { Transform } from 'class-transformer';

export class RegisterDto {
  @IsString()
  @IsNotEmpty()
  @MinLength(10)
  @MaxLength(15)
  @Transform(({ value }) => value?.replace(/\s/g, ''))
  @Matches(/^(\+213|0)(5|6|7)[0-9]{8}$/, {
    message: 'Phone must be a valid Algerian number (+213XXXXXXXXX or 0XXXXXXXXX)',
  })
  phone: string;

  @IsString()
  @IsNotEmpty()
  @MinLength(8)
  @MaxLength(100)
  @Matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d@$!%*?&]{8,}$/, {
    message: 'Password must contain at least 8 characters, one uppercase, one lowercase, and one number',
  })
  password: string;

  @IsEnum(['user', 'restaurant', 'livreur'])
  role: 'user' | 'restaurant' | 'livreur';

  @IsString()
  @IsNotEmpty()
  @MinLength(2)
  @MaxLength(100)
  @Transform(({ value }) => value?.trim())
  fullName: string;

  @IsEmail()
  @IsOptional()
  @MaxLength(255)
  @Transform(({ value }) => value?.toLowerCase().trim())
  email?: string;
}
