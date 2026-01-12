import { Injectable, UnauthorizedException, BadRequestException, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import { User } from '../users/entities/user.entity';
import { Restaurant } from '../restaurants/entities/restaurant.entity';
import { Livreur } from '../livreurs/entities/livreur.entity';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';

export type UserRole = 'user' | 'restaurant' | 'livreur';

// Track failed login attempts
const loginAttempts = new Map<string, { count: number; lastAttempt: Date }>();
const MAX_LOGIN_ATTEMPTS = 5;
const LOCKOUT_DURATION_MS = 15 * 60 * 1000; // 15 minutes

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    @InjectRepository(User)
    private usersRepository: Repository<User>,
    @InjectRepository(Restaurant)
    private restaurantsRepository: Repository<Restaurant>,
    @InjectRepository(Livreur)
    private livreursRepository: Repository<Livreur>,
    private jwtService: JwtService,
    private configService: ConfigService,
  ) {}

  private checkRateLimit(identifier: string): void {
    const attempts = loginAttempts.get(identifier);
    
    if (attempts) {
      const timeSinceLastAttempt = Date.now() - attempts.lastAttempt.getTime();
      
      // Reset if lockout period has passed
      if (timeSinceLastAttempt > LOCKOUT_DURATION_MS) {
        loginAttempts.delete(identifier);
        return;
      }
      
      if (attempts.count >= MAX_LOGIN_ATTEMPTS) {
        const remainingTime = Math.ceil((LOCKOUT_DURATION_MS - timeSinceLastAttempt) / 60000);
        throw new BadRequestException(
          `Too many login attempts. Please try again in ${remainingTime} minutes.`,
        );
      }
    }
  }

  private recordFailedAttempt(identifier: string): void {
    const attempts = loginAttempts.get(identifier) || { count: 0, lastAttempt: new Date() };
    attempts.count += 1;
    attempts.lastAttempt = new Date();
    loginAttempts.set(identifier, attempts);
  }

  private clearFailedAttempts(identifier: string): void {
    loginAttempts.delete(identifier);
  }

  async validateUser(phone: string, password: string, role: UserRole): Promise<any> {
    let user: User | Restaurant | Livreur | null = null;

    switch (role) {
      case 'user':
        user = await this.usersRepository.findOne({ where: { phone } });
        break;
      case 'restaurant':
        user = await this.restaurantsRepository.findOne({ where: { phone } });
        break;
      case 'livreur':
        user = await this.livreursRepository.findOne({ where: { phone } });
        break;
    }

    if (user && await bcrypt.compare(password, user.passwordHash)) {
      // Check if account is active
      if (!user.isActive) {
        throw new UnauthorizedException('Account is deactivated');
      }
      
      const { passwordHash, ...result } = user;
      return { ...result, role };
    }
    return null;
  }

  async login(loginDto: LoginDto) {
    const { phone, password, role } = loginDto;
    const identifier = `${phone}:${role}`;

    // Check rate limiting
    this.checkRateLimit(identifier);

    const user = await this.validateUser(phone, password, role);

    if (!user) {
      this.recordFailedAttempt(identifier);
      this.logger.warn(`Failed login attempt for ${phone} as ${role}`);
      throw new UnauthorizedException('Invalid credentials');
    }

    // Clear failed attempts on successful login
    this.clearFailedAttempts(identifier);

    const payload = { 
      phone: user.phone, 
      sub: user.id, 
      role,
      iat: Math.floor(Date.now() / 1000),
    };
    
    this.logger.log(`Successful login for ${phone} as ${role}`);

    return {
      access_token: this.jwtService.sign(payload),
      refresh_token: this.jwtService.sign(payload, { 
        expiresIn: this.configService.get<string>('jwt.refreshExpiresIn'),
        secret: this.configService.get<string>('jwt.refreshSecret'),
      }),
      user,
    };
  }

  async register(registerDto: RegisterDto) {
    const { phone, password, role, ...userData } = registerDto;
    
    // Check if user already exists in any table
    const existingUser = await this.usersRepository.findOne({ where: { phone } });
    const existingRestaurant = await this.restaurantsRepository.findOne({ where: { phone } });
    const existingLivreur = await this.livreursRepository.findOne({ where: { phone } });

    if (existingUser || existingRestaurant || existingLivreur) {
      throw new BadRequestException('Phone number already registered');
    }

    // Hash password with higher cost factor
    const hashedPassword = await bcrypt.hash(password, 12);
    
    let newUser;
    switch (role) {
      case 'user':
        newUser = this.usersRepository.create({
          phone,
          passwordHash: hashedPassword,
          ...userData,
        });
        newUser = await this.usersRepository.save(newUser);
        break;
      case 'restaurant':
        // Restaurants need additional validation
        throw new BadRequestException('Restaurant registration requires admin approval');
      case 'livreur':
        // Livreurs need additional validation
        throw new BadRequestException('Livreur registration requires admin approval');
    }

    const { passwordHash, ...result } = newUser;
    const payload = { 
      phone: result.phone, 
      sub: result.id, 
      role,
      iat: Math.floor(Date.now() / 1000),
    };
    
    this.logger.log(`New user registered: ${phone} as ${role}`);

    return {
      access_token: this.jwtService.sign(payload),
      refresh_token: this.jwtService.sign(payload, { 
        expiresIn: this.configService.get<string>('jwt.refreshExpiresIn'),
        secret: this.configService.get<string>('jwt.refreshSecret'),
      }),
      user: result,
    };
  }

  async refreshToken(refreshToken: string) {
    try {
      const payload = this.jwtService.verify(refreshToken, {
        secret: this.configService.get<string>('jwt.refreshSecret'),
      });

      // Verify user still exists and is active
      const user = await this.validateUserExists(payload.sub, payload.role);
      if (!user || !user.isActive) {
        throw new UnauthorizedException('User not found or inactive');
      }

      const newPayload = { 
        phone: payload.phone, 
        sub: payload.sub, 
        role: payload.role,
        iat: Math.floor(Date.now() / 1000),
      };
      
      return {
        access_token: this.jwtService.sign(newPayload),
      };
    } catch (e) {
      this.logger.warn(`Invalid refresh token attempt`);
      throw new UnauthorizedException('Invalid refresh token');
    }
  }

  private async validateUserExists(id: string, role: string): Promise<any> {
    switch (role) {
      case 'user':
        return this.usersRepository.findOne({ where: { id } });
      case 'restaurant':
        return this.restaurantsRepository.findOne({ where: { id } });
      case 'livreur':
        return this.livreursRepository.findOne({ where: { id } });
      default:
        return null;
    }
  }

  async changePassword(userId: string, role: string, oldPassword: string, newPassword: string) {
    let user: any;
    let repository: Repository<any>;

    switch (role) {
      case 'user':
        repository = this.usersRepository;
        user = await this.usersRepository.findOne({ where: { id: userId } });
        break;
      case 'restaurant':
        repository = this.restaurantsRepository;
        user = await this.restaurantsRepository.findOne({ where: { id: userId } });
        break;
      case 'livreur':
        repository = this.livreursRepository;
        user = await this.livreursRepository.findOne({ where: { id: userId } });
        break;
    }

    if (!user) {
      throw new UnauthorizedException('User not found');
    }

    const isOldPasswordValid = await bcrypt.compare(oldPassword, user.passwordHash);
    if (!isOldPasswordValid) {
      throw new UnauthorizedException('Current password is incorrect');
    }

    const hashedNewPassword = await bcrypt.hash(newPassword, 12);
    await repository.update(userId, { passwordHash: hashedNewPassword });

    this.logger.log(`Password changed for user ${userId}`);
    return { message: 'Password changed successfully' };
  }
}
