import { Injectable, UnauthorizedException } from '@nestjs/common';
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

@Injectable()
export class AuthService {
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
      const { passwordHash, ...result } = user;
      return { ...result, role };
    }
    return null;
  }

  async login(loginDto: LoginDto) {
    const { phone, password, role } = loginDto;
    const user = await this.validateUser(phone, password, role);

    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const payload = { phone: user.phone, sub: user.id, role };
    
    return {
      access_token: this.jwtService.sign(payload, { expiresIn: '1h' }),
      refresh_token: this.jwtService.sign(payload, { 
        expiresIn: this.configService.get<string>('jwt.refreshExpiresIn') || '7d',
        secret: this.configService.get<string>('jwt.refreshSecret') || this.configService.get<string>('jwt.secret'),
      }),
      user,
    };
  }

  async register(registerDto: RegisterDto) {
    const { phone, password, role, ...userData } = registerDto;
    
    // Check if user already exists
    let existingUser = null;
    switch (role) {
      case 'user':
        existingUser = await this.usersRepository.findOne({ where: { phone } });
        break;
      case 'restaurant':
        existingUser = await this.restaurantsRepository.findOne({ where: { phone } });
        break;
      case 'livreur':
        existingUser = await this.livreursRepository.findOne({ where: { phone } });
        break;
    }

    if (existingUser) {
      throw new UnauthorizedException('User already exists');
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    
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
        newUser = this.restaurantsRepository.create({
          phone,
          passwordHash: hashedPassword,
          ...userData,
        });
        newUser = await this.restaurantsRepository.save(newUser);
        break;
      case 'livreur':
        newUser = this.livreursRepository.create({
          phone,
          passwordHash: hashedPassword,
          ...userData,
        });
        newUser = await this.livreursRepository.save(newUser);
        break;
    }

    const { passwordHash, ...result } = newUser;
    const payload = { phone: result.phone, sub: result.id, role };
    
    return {
      access_token: this.jwtService.sign(payload, { expiresIn: '1h' }),
      refresh_token: this.jwtService.sign(payload, { 
        expiresIn: this.configService.get<string>('jwt.refreshExpiresIn') || '7d',
        secret: this.configService.get<string>('jwt.refreshSecret') || this.configService.get<string>('jwt.secret'),
      }),
      user: result,
    };
  }

  async refreshToken(refreshToken: string) {
    try {
      const payload = this.jwtService.verify(refreshToken, {
        secret: this.configService.get<string>('jwt.refreshSecret'),
      });

      const newPayload = { phone: payload.phone, sub: payload.sub, role: payload.role };
      
      return {
        access_token: this.jwtService.sign(newPayload),
      };
    } catch (e) {
      throw new UnauthorizedException('Invalid refresh token');
    }
  }
}
