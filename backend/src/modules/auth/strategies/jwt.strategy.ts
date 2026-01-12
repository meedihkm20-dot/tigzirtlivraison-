import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { Restaurant } from '../../restaurants/entities/restaurant.entity';
import { Livreur } from '../../livreurs/entities/livreur.entity';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    configService: ConfigService,
    @InjectRepository(User)
    private usersRepository: Repository<User>,
    @InjectRepository(Restaurant)
    private restaurantsRepository: Repository<Restaurant>,
    @InjectRepository(Livreur)
    private livreursRepository: Repository<Livreur>,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: configService.get<string>('jwt.secret'),
    });
  }

  async validate(payload: any) {
    // Verify user still exists and is active
    let user: any;

    switch (payload.role) {
      case 'user':
        user = await this.usersRepository.findOne({ 
          where: { id: payload.sub },
          select: ['id', 'phone', 'fullName', 'email', 'isActive', 'isVerified'],
        });
        break;
      case 'restaurant':
        user = await this.restaurantsRepository.findOne({ 
          where: { id: payload.sub },
          select: ['id', 'phone', 'name', 'email', 'isActive', 'isVerified'],
        });
        break;
      case 'livreur':
        user = await this.livreursRepository.findOne({ 
          where: { id: payload.sub },
          select: ['id', 'phone', 'fullName', 'email', 'isActive', 'isVerified'],
        });
        break;
      default:
        throw new UnauthorizedException('Invalid token');
    }

    if (!user) {
      throw new UnauthorizedException('User not found');
    }

    if (!user.isActive) {
      throw new UnauthorizedException('Account is deactivated');
    }

    return { 
      id: payload.sub, 
      phone: payload.phone, 
      role: payload.role,
      isVerified: user.isVerified,
    };
  }
}
