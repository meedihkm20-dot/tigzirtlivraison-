import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import helmet from 'helmet';
import { GlobalExceptionFilter } from './common/filters/http-exception.filter';
import { SanitizeInterceptor } from './common/interceptors/sanitize.interceptor';
import { LoggingInterceptor } from './common/interceptors/logging.interceptor';

async function bootstrap() {
  const logger = new Logger('Bootstrap');
  const app = await NestFactory.create(AppModule, {
    logger: ['error', 'warn', 'log'],
  });
  
  const configService = app.get(ConfigService);
  
  // Security headers with Helmet
  app.use(helmet({
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        styleSrc: ["'self'", "'unsafe-inline'"],
        imgSrc: ["'self'", 'data:', 'https:'],
        scriptSrc: ["'self'"],
      },
    },
    crossOriginEmbedderPolicy: false,
  }));

  // Global validation pipe with security options
  app.useGlobalPipes(new ValidationPipe({
    whitelist: true,              // Strip unknown properties
    forbidNonWhitelisted: true,   // Throw error on unknown properties
    transform: true,              // Transform payloads to DTO instances
    transformOptions: {
      enableImplicitConversion: false, // Prevent type coercion attacks
    },
    disableErrorMessages: process.env.NODE_ENV === 'production',
  }));

  // Global exception filter
  app.useGlobalFilters(new GlobalExceptionFilter());

  // Global interceptors
  app.useGlobalInterceptors(
    new LoggingInterceptor(),
    new SanitizeInterceptor(),
  );
  
  // CORS configuration
  const allowedOrigins = [
    configService.get<string>('FRONTEND_URL') || 'http://localhost:3001',
    'http://localhost:3000',
    'http://localhost:3001',
    'http://localhost:3002',
    'http://localhost:3003',
  ];

  app.enableCors({
    origin: (origin, callback) => {
      // Allow requests with no origin (mobile apps, Postman)
      if (!origin) return callback(null, true);
      
      if (allowedOrigins.includes(origin)) {
        callback(null, true);
      } else {
        callback(new Error('Not allowed by CORS'));
      }
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
    exposedHeaders: ['X-Total-Count'],
    maxAge: 86400, // 24 hours
  });
  
  // API prefix
  app.setGlobalPrefix('api');

  // Graceful shutdown
  app.enableShutdownHooks();
  
  const port = configService.get<number>('PORT') || 3000;
  await app.listen(port);
  
  logger.log(`🚀 DZ Delivery Backend running on port ${port}`);
  logger.log(`📝 Environment: ${process.env.NODE_ENV || 'development'}`);
}

bootstrap();
