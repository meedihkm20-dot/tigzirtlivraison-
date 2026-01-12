import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe } from '@nestjs/common';
import { ThrottlerGuard } from '@nestjs/throttler';
import { ConfigService } from '@nestjs/config';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  
  const configService = app.get(ConfigService);
  
  // Pipes globaux
  app.useGlobalPipes(new ValidationPipe({
    whitelist: true,
    forbidNonWhitelisted: true,
    transform: true,
  }));
  
  // Guards globaux
  app.useGlobalGuards(app.get(ThrottlerGuard));
  
  // CORS
  app.enableCors({
    origin: [
      'http://localhost:3000', // Admin dashboard
      'http://localhost:3001', // Customer app
      'http://localhost:3002', // Restaurant app
      'http://localhost:3003', // Livreur app
    ],
    credentials: true,
  });
  
  // Préfixe API
  app.setGlobalPrefix('api');
  
  const port = configService.get<number>('PORT') || 3000;
  await app.listen(port);
  
  console.log(`🚀 DZ Delivery Backend running on port ${port}`);
}

bootstrap();
