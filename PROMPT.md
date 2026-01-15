# 🎯 PROMPT AGENT IA - BACKEND KOYEB + ONESIGNAL (100% GRATUIT)

---

## ⚠️ CONTEXTE CRITIQUE

**Situation actuelle :**
```
📱 Apps Flutter (dz_delivery + admin_app)
        │
        ▼
🗄️ Supabase (BDD, Auth, Realtime, Storage)
```

**Situation cible :**
```
📱 Apps Flutter (dz_delivery + admin_app)
        │
        ├──→ 🖥️ Backend NestJS (Koyeb) ← NOUVEAU
        │         │
        │         ├──→ 🔔 OneSignal (Push notifications)
        │         │
        │         ▼
        └──→ 🗄️ Supabase (BDD, Auth, Realtime, Storage)
```

---

## 💰 STACK 100% GRATUITE - AUCUNE CARTE BANCAIRE

| Service | Coût | Carte requise |
|---------|------|---------------|
| Koyeb | Gratuit (1 service) | ❌ Non |
| Supabase | Gratuit (free tier) | ❌ Non |
| **OneSignal** | **Gratuit (illimité mobile)** | **❌ Non** |

**⚠️ NE PAS UTILISER Firebase** - Requiert carte bancaire (plan Blaze)

---

## 📂 STRUCTURE PROJET

```
LIVRAISON TIGZIRT/
├── apps/
│   ├── admin_app/
│   └── dz_delivery/
├── backend/                      ← CRÉER
│   ├── src/
│   │   ├── main.ts
│   │   ├── app.module.ts
│   │   │
│   │   ├── config/
│   │   │   └── env.validation.ts
│   │   │
│   │   ├── common/
│   │   │   ├── guards/
│   │   │   │   └── supabase-auth.guard.ts
│   │   │   └── decorators/
│   │   │       └── current-user.decorator.ts
│   │   │
│   │   ├── modules/
│   │   │   ├── health/
│   │   │   ├── orders/
│   │   │   ├── delivery/
│   │   │   ├── notifications/    ← OneSignal
│   │   │   └── webhooks/
│   │   │
│   │   └── supabase/
│   │       ├── supabase.module.ts
│   │       └── supabase.service.ts
│   │
│   ├── .env.example
│   ├── Dockerfile
│   ├── package.json
│   └── tsconfig.json
│
└── supabase/
```

---

## 🛑 RÈGLES ABSOLUES

1. **NE PAS** utiliser Firebase (requiert carte bancaire)
2. **UTILISER** OneSignal pour les notifications push
3. **NE PAS** casser le fonctionnement Supabase existant
4. **GARDER** l'authentification via Supabase Auth
5. **100% GRATUIT** - Aucun service payant

---

## 🚀 PHASE 1 : CRÉATION BACKEND NESTJS

### 1.1 Fichiers à créer

#### 📄 `backend/package.json`
```json
{
  "name": "tigzirt-liv-backend",
  "version": "1.0.0",
  "description": "Backend API pour Tigzirt Livraison",
  "scripts": {
    "build": "nest build",
    "start": "nest start",
    "start:dev": "nest start --watch",
    "start:prod": "node dist/main",
    "lint": "eslint \"{src,apps,libs,test}/**/*.ts\" --fix"
  },
  "dependencies": {
    "@nestjs/common": "^10.3.0",
    "@nestjs/core": "^10.3.0",
    "@nestjs/platform-express": "^10.3.0",
    "@nestjs/config": "^3.1.1",
    "@nestjs/swagger": "^7.2.0",
    "@supabase/supabase-js": "^2.39.0",
    "class-validator": "^0.14.0",
    "class-transformer": "^0.5.1",
    "rxjs": "^7.8.1"
  },
  "devDependencies": {
    "@nestjs/cli": "^10.3.0",
    "@types/express": "^4.17.21",
    "@types/node": "^20.10.0",
    "typescript": "^5.3.0"
  }
}
```

#### 📄 `backend/.env.example`
```env
# Server
PORT=3000
NODE_ENV=production

# Supabase
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_SERVICE_KEY=eyJxxxxx

# OneSignal (GRATUIT - pas de carte bancaire requise)
ONESIGNAL_APP_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
ONESIGNAL_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

#### 📄 `backend/src/main.ts`
```typescript
import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  
  // CORS pour Flutter
  app.enableCors({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  });
  
  // Validation globale
  app.useGlobalPipes(new ValidationPipe({
    whitelist: true,
    forbidNonWhitelisted: true,
    transform: true,
  }));
  
  // Swagger
  const config = new DocumentBuilder()
    .setTitle('Tigzirt Livraison API')
    .setDescription('API Backend pour DZ Delivery')
    .setVersion('1.0')
    .addBearerAuth()
    .build();
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document);
  
  const port = process.env.PORT || 3000;
  await app.listen(port);
  console.log(`🚀 Backend running on port ${port}`);
}
bootstrap();
```

#### 📄 `backend/src/app.module.ts`
```typescript
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { SupabaseModule } from './supabase/supabase.module';
import { HealthModule } from './modules/health/health.module';
import { OrdersModule } from './modules/orders/orders.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { DeliveryModule } from './modules/delivery/delivery.module';
import { WebhooksModule } from './modules/webhooks/webhooks.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),
    SupabaseModule,
    HealthModule,
    OrdersModule,
    NotificationsModule,
    DeliveryModule,
    WebhooksModule,
  ],
})
export class AppModule {}
```

#### 📄 `backend/src/supabase/supabase.service.ts`
```typescript
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createClient, SupabaseClient } from '@supabase/supabase-js';

@Injectable()
export class SupabaseService {
  private supabase: SupabaseClient;

  constructor(private configService: ConfigService) {
    this.supabase = createClient(
      this.configService.get<string>('SUPABASE_URL'),
      this.configService.get<string>('SUPABASE_SERVICE_KEY'),
    );
  }

  getClient(): SupabaseClient {
    return this.supabase;
  }

  async getOrderById(orderId: string) {
    const { data, error } = await this.supabase
      .from('orders')
      .select('*, order_items(*), restaurant:restaurants(*)')
      .eq('id', orderId)
      .single();
    
    if (error) throw error;
    return data;
  }

  async updateOrderStatus(orderId: string, status: string) {
    const { data, error } = await this.supabase
      .from('orders')
      .update({ status, updated_at: new Date().toISOString() })
      .eq('id', orderId)
      .select()
      .single();
    
    if (error) throw error;
    return data;
  }

  async getRestaurantById(restaurantId: string) {
    const { data, error } = await this.supabase
      .from('restaurants')
      .select('*')
      .eq('id', restaurantId)
      .single();
    
    if (error) throw error;
    return data;
  }

  async getUserById(userId: string) {
    const { data, error } = await this.supabase
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .single();
    
    if (error) throw error;
    return data;
  }
}
```

#### 📄 `backend/src/supabase/supabase.module.ts`
```typescript
import { Module, Global } from '@nestjs/common';
import { SupabaseService } from './supabase.service';

@Global()
@Module({
  providers: [SupabaseService],
  exports: [SupabaseService],
})
export class SupabaseModule {}
```

#### 📄 `backend/src/common/guards/supabase-auth.guard.ts`
```typescript
import {
  Injectable,
  CanActivate,
  ExecutionContext,
  UnauthorizedException,
} from '@nestjs/common';
import { SupabaseService } from '../../supabase/supabase.service';

@Injectable()
export class SupabaseAuthGuard implements CanActivate {
  constructor(private supabaseService: SupabaseService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const authHeader = request.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new UnauthorizedException('Token manquant');
    }

    const token = authHeader.split(' ')[1];

    try {
      const { data: { user }, error } = await this.supabaseService
        .getClient()
        .auth.getUser(token);

      if (error || !user) {
        throw new UnauthorizedException('Token invalide');
      }

      request.user = user;
      return true;
    } catch (error) {
      throw new UnauthorizedException('Token invalide');
    }
  }
}
```

#### 📄 `backend/src/common/decorators/current-user.decorator.ts`
```typescript
import { createParamDecorator, ExecutionContext } from '@nestjs/common';

export const CurrentUser = createParamDecorator(
  (data: unknown, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest();
    return request.user;
  },
);
```

#### 📄 `backend/src/modules/health/health.controller.ts`
```typescript
import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';

@ApiTags('Health')
@Controller('health')
export class HealthController {
  @Get()
  @ApiOperation({ summary: 'Health check endpoint' })
  check() {
    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
      service: 'tigzirt-liv-backend',
    };
  }
}
```

#### 📄 `backend/src/modules/health/health.module.ts`
```typescript
import { Module } from '@nestjs/common';
import { HealthController } from './health.controller';

@Module({
  controllers: [HealthController],
})
export class HealthModule {}
```

---

## 🔔 PHASE 2 : MODULE NOTIFICATIONS (ONESIGNAL)

### ⚠️ IMPORTANT : OneSignal, PAS Firebase !

#### 📄 `backend/src/modules/notifications/notifications.service.ts`
```typescript
import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { SupabaseService } from '../../supabase/supabase.service';

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);
  private readonly appId: string;
  private readonly apiKey: string;

  constructor(
    private configService: ConfigService,
    private supabaseService: SupabaseService,
  ) {
    this.appId = this.configService.get<string>('ONESIGNAL_APP_ID');
    this.apiKey = this.configService.get<string>('ONESIGNAL_API_KEY');

    if (!this.appId || !this.apiKey) {
      this.logger.warn('OneSignal credentials not configured');
    } else {
      this.logger.log('OneSignal initialized');
    }
  }

  /**
   * Envoyer notification push via OneSignal (GRATUIT)
   */
  async sendPushToUser(
    userId: string,
    title: string,
    message: string,
    data?: Record<string, string>,
  ) {
    if (!this.appId || !this.apiKey) {
      this.logger.warn('OneSignal not configured, skipping notification');
      return null;
    }

    try {
      const response = await fetch('https://onesignal.com/api/v1/notifications', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Basic ${this.apiKey}`,
        },
        body: JSON.stringify({
          app_id: this.appId,
          include_external_user_ids: [userId],
          headings: { en: title, fr: title },
          contents: { en: message, fr: message },
          data: data || {},
          // Android
          android_channel_id: 'orders',
          android_accent_color: 'FF6B35',
          // iOS
          ios_sound: 'default',
          ios_badgeType: 'Increase',
          ios_badgeCount: 1,
        }),
      });

      const result = await response.json();
      
      if (result.errors) {
        this.logger.error(`OneSignal error: ${JSON.stringify(result.errors)}`);
        return null;
      }

      this.logger.log(`Notification sent to user ${userId}: ${result.id}`);
      return result;
    } catch (error) {
      this.logger.error(`Failed to send notification: ${error.message}`);
      return null;
    }
  }

  /**
   * Envoyer notification à plusieurs utilisateurs
   */
  async sendPushToUsers(
    userIds: string[],
    title: string,
    message: string,
    data?: Record<string, string>,
  ) {
    if (!this.appId || !this.apiKey) {
      return null;
    }

    try {
      const response = await fetch('https://onesignal.com/api/v1/notifications', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Basic ${this.apiKey}`,
        },
        body: JSON.stringify({
          app_id: this.appId,
          include_external_user_ids: userIds,
          headings: { en: title, fr: title },
          contents: { en: message, fr: message },
          data: data || {},
        }),
      });

      return response.json();
    } catch (error) {
      this.logger.error(`Failed to send notifications: ${error.message}`);
      return null;
    }
  }

  /**
   * Nouvelle commande → Notifier le restaurant
   */
  async notifyNewOrder(orderId: string) {
    try {
      const order = await this.supabaseService.getOrderById(orderId);
      const restaurant = await this.supabaseService.getRestaurantById(order.restaurant_id);

      return this.sendPushToUser(
        restaurant.owner_id,
        '🔔 Nouvelle commande !',
        `Commande #${order.order_number} - ${order.total_amount} DA`,
        { 
          type: 'new_order', 
          order_id: orderId,
          order_number: order.order_number,
        },
      );
    } catch (error) {
      this.logger.error(`notifyNewOrder error: ${error.message}`);
      return null;
    }
  }

  /**
   * Commande acceptée → Notifier le client
   */
  async notifyOrderAccepted(orderId: string) {
    try {
      const order = await this.supabaseService.getOrderById(orderId);

      return this.sendPushToUser(
        order.user_id,
        '✅ Commande acceptée !',
        `Votre commande #${order.order_number} est en préparation`,
        { 
          type: 'order_accepted', 
          order_id: orderId,
        },
      );
    } catch (error) {
      this.logger.error(`notifyOrderAccepted error: ${error.message}`);
      return null;
    }
  }

  /**
   * Commande prête → Notifier le client
   */
  async notifyOrderReady(orderId: string) {
    try {
      const order = await this.supabaseService.getOrderById(orderId);

      return this.sendPushToUser(
        order.user_id,
        '🍽️ Commande prête !',
        `Votre commande #${order.order_number} est prête`,
        { 
          type: 'order_ready', 
          order_id: orderId,
        },
      );
    } catch (error) {
      this.logger.error(`notifyOrderReady error: ${error.message}`);
      return null;
    }
  }

  /**
   * Livreur assigné → Notifier le client
   */
  async notifyDriverAssigned(orderId: string, driverId: string) {
    try {
      const order = await this.supabaseService.getOrderById(orderId);
      const driver = await this.supabaseService.getUserById(driverId);

      return this.sendPushToUser(
        order.user_id,
        '🚚 Livreur en route !',
        `${driver.full_name || 'Un livreur'} arrive avec votre commande`,
        { 
          type: 'driver_assigned', 
          order_id: orderId,
          driver_id: driverId,
        },
      );
    } catch (error) {
      this.logger.error(`notifyDriverAssigned error: ${error.message}`);
      return null;
    }
  }

  /**
   * Nouvelle livraison → Notifier le livreur
   */
  async notifyDriverNewDelivery(driverId: string, orderId: string) {
    try {
      const order = await this.supabaseService.getOrderById(orderId);

      return this.sendPushToUser(
        driverId,
        '📦 Nouvelle livraison !',
        `Commande #${order.order_number} à récupérer`,
        { 
          type: 'new_delivery', 
          order_id: orderId,
        },
      );
    } catch (error) {
      this.logger.error(`notifyDriverNewDelivery error: ${error.message}`);
      return null;
    }
  }

  /**
   * Commande livrée → Notifier le client
   */
  async notifyOrderDelivered(orderId: string) {
    try {
      const order = await this.supabaseService.getOrderById(orderId);

      return this.sendPushToUser(
        order.user_id,
        '✅ Commande livrée !',
        `Votre commande #${order.order_number} a été livrée. Bon appétit !`,
        { 
          type: 'order_delivered', 
          order_id: orderId,
        },
      );
    } catch (error) {
      this.logger.error(`notifyOrderDelivered error: ${error.message}`);
      return null;
    }
  }

  /**
   * Commande annulée → Notifier le client
   */
  async notifyOrderCancelled(orderId: string, reason?: string) {
    try {
      const order = await this.supabaseService.getOrderById(orderId);

      return this.sendPushToUser(
        order.user_id,
        '❌ Commande annulée',
        reason || `Votre commande #${order.order_number} a été annulée`,
        { 
          type: 'order_cancelled', 
          order_id: orderId,
        },
      );
    } catch (error) {
      this.logger.error(`notifyOrderCancelled error: ${error.message}`);
      return null;
    }
  }
}
```

#### 📄 `backend/src/modules/notifications/notifications.controller.ts`
```typescript
import { Controller, Post, Body } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { NotificationsService } from './notifications.service';

@ApiTags('Notifications')
@Controller('api/notifications')
export class NotificationsController {
  constructor(private notificationsService: NotificationsService) {}

  @Post('new-order')
  @ApiOperation({ summary: 'Notifier restaurant - nouvelle commande' })
  async newOrder(@Body() body: { order_id: string }) {
    return this.notificationsService.notifyNewOrder(body.order_id);
  }

  @Post('order-accepted')
  @ApiOperation({ summary: 'Notifier client - commande acceptée' })
  async orderAccepted(@Body() body: { order_id: string }) {
    return this.notificationsService.notifyOrderAccepted(body.order_id);
  }

  @Post('order-ready')
  @ApiOperation({ summary: 'Notifier client - commande prête' })
  async orderReady(@Body() body: { order_id: string }) {
    return this.notificationsService.notifyOrderReady(body.order_id);
  }

  @Post('driver-assigned')
  @ApiOperation({ summary: 'Notifier client - livreur assigné' })
  async driverAssigned(@Body() body: { order_id: string; driver_id: string }) {
    return this.notificationsService.notifyDriverAssigned(
      body.order_id,
      body.driver_id,
    );
  }

  @Post('new-delivery')
  @ApiOperation({ summary: 'Notifier livreur - nouvelle livraison' })
  async newDelivery(@Body() body: { driver_id: string; order_id: string }) {
    return this.notificationsService.notifyDriverNewDelivery(
      body.driver_id,
      body.order_id,
    );
  }

  @Post('order-delivered')
  @ApiOperation({ summary: 'Notifier client - commande livrée' })
  async orderDelivered(@Body() body: { order_id: string }) {
    return this.notificationsService.notifyOrderDelivered(body.order_id);
  }

  @Post('order-cancelled')
  @ApiOperation({ summary: 'Notifier client - commande annulée' })
  async orderCancelled(@Body() body: { order_id: string; reason?: string }) {
    return this.notificationsService.notifyOrderCancelled(
      body.order_id,
      body.reason,
    );
  }

  @Post('test')
  @ApiOperation({ summary: 'Test notification' })
  async test(@Body() body: { user_id: string; title: string; message: string }) {
    return this.notificationsService.sendPushToUser(
      body.user_id,
      body.title,
      body.message,
    );
  }
}
```

#### 📄 `backend/src/modules/notifications/notifications.module.ts`
```typescript
import { Module } from '@nestjs/common';
import { NotificationsController } from './notifications.controller';
import { NotificationsService } from './notifications.service';

@Module({
  controllers: [NotificationsController],
  providers: [NotificationsService],
  exports: [NotificationsService],
})
export class NotificationsModule {}
```

---

## 🚚 PHASE 3 : MODULE DELIVERY

#### 📄 `backend/src/modules/delivery/delivery.service.ts`
```typescript
import { Injectable } from '@nestjs/common';
import { SupabaseService } from '../../supabase/supabase.service';

@Injectable()
export class DeliveryService {
  constructor(private supabaseService: SupabaseService) {}

  /**
   * Calculer le prix de livraison (côté serveur = anti-triche)
   */
  calculateDeliveryPrice(distanceKm: number, zone: string): number {
    const baseFee = 100; // 100 DA minimum
    const perKmRate = 30; // 30 DA par km
    
    const zoneMultipliers: Record<string, number> = {
      'tigzirt': 1.0,
      'azazga': 1.2,
      'tizi-ouzou': 1.5,
      'autres': 2.0,
    };

    const multiplier = zoneMultipliers[zone] || zoneMultipliers['autres'];
    const price = (baseFee + (distanceKm * perKmRate)) * multiplier;

    return Math.ceil(price / 10) * 10; // Arrondir à 10 DA
  }

  /**
   * Estimer le temps de livraison
   */
  calculateEstimatedTime(distanceKm: number, preparationTime: number): number {
    const avgSpeedKmH = 25;
    const deliveryTimeMin = (distanceKm / avgSpeedKmH) * 60;
    const bufferMin = 5;

    return Math.ceil(preparationTime + deliveryTimeMin + bufferMin);
  }

  /**
   * Trouver et assigner un livreur disponible
   */
  async assignDriver(orderId: string) {
    const supabase = this.supabaseService.getClient();
    const order = await this.supabaseService.getOrderById(orderId);

    // Trouver les livreurs disponibles
    const { data: drivers, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('role', 'livreur')
      .eq('is_available', true)
      .eq('is_active', true);

    if (error || !drivers?.length) {
      return null;
    }

    // Prendre le premier disponible (TODO: proximité)
    const driver = drivers[0];

    // Assigner
    await supabase
      .from('orders')
      .update({ 
        driver_id: driver.id,
        status: 'driver_assigned',
        updated_at: new Date().toISOString(),
      })
      .eq('id', orderId);

    return driver;
  }
}
```

#### 📄 `backend/src/modules/delivery/delivery.controller.ts`
```typescript
import { Controller, Post, Body, Get, Query } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { DeliveryService } from './delivery.service';

@ApiTags('Delivery')
@Controller('api/delivery')
export class DeliveryController {
  constructor(private deliveryService: DeliveryService) {}

  @Get('calculate-price')
  @ApiOperation({ summary: 'Calculer le prix de livraison' })
  calculatePrice(
    @Query('distance') distance: number,
    @Query('zone') zone: string,
  ) {
    const price = this.deliveryService.calculateDeliveryPrice(
      Number(distance),
      zone,
    );
    return { price, currency: 'DA' };
  }

  @Get('estimate-time')
  @ApiOperation({ summary: 'Estimer le temps de livraison' })
  estimateTime(
    @Query('distance') distance: number,
    @Query('preparation_time') preparationTime: number,
  ) {
    const minutes = this.deliveryService.calculateEstimatedTime(
      Number(distance),
      Number(preparationTime),
    );
    return { estimated_minutes: minutes };
  }

  @Post('assign-driver')
  @ApiOperation({ summary: 'Assigner un livreur' })
  async assignDriver(@Body() body: { order_id: string }) {
    const driver = await this.deliveryService.assignDriver(body.order_id);
    return { success: !!driver, driver };
  }
}
```

#### 📄 `backend/src/modules/delivery/delivery.module.ts`
```typescript
import { Module } from '@nestjs/common';
import { DeliveryController } from './delivery.controller';
import { DeliveryService } from './delivery.service';

@Module({
  controllers: [DeliveryController],
  providers: [DeliveryService],
  exports: [DeliveryService],
})
export class DeliveryModule {}
```

---

## 📦 PHASE 4 : MODULE ORDERS

#### 📄 `backend/src/modules/orders/dto/create-order.dto.ts`
```typescript
import { IsString, IsArray, IsNumber, IsOptional, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty } from '@nestjs/swagger';

class OrderItemDto {
  @ApiProperty()
  @IsString()
  menu_item_id: string;

  @ApiProperty()
  @IsNumber()
  quantity: number;
}

export class CreateOrderDto {
  @ApiProperty()
  @IsString()
  restaurant_id: string;

  @ApiProperty({ type: [OrderItemDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => OrderItemDto)
  items: OrderItemDto[];

  @ApiProperty()
  @IsString()
  delivery_address: string;

  @ApiProperty()
  @IsNumber()
  delivery_lat: number;

  @ApiProperty()
  @IsNumber()
  delivery_lng: number;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  notes?: string;
}
```

#### 📄 `backend/src/modules/orders/orders.service.ts`
```typescript
import { Injectable, BadRequestException } from '@nestjs/common';
import { SupabaseService } from '../../supabase/supabase.service';
import { NotificationsService } from '../notifications/notifications.service';
import { DeliveryService } from '../delivery/delivery.service';
import { CreateOrderDto } from './dto/create-order.dto';

@Injectable()
export class OrdersService {
  constructor(
    private supabaseService: SupabaseService,
    private notificationsService: NotificationsService,
    private deliveryService: DeliveryService,
  ) {}

  /**
   * Créer une commande (validation côté serveur)
   */
  async createOrder(userId: string, dto: CreateOrderDto) {
    const supabase = this.supabaseService.getClient();

    // 1. Vérifier le restaurant
    const { data: restaurant, error: restError } = await supabase
      .from('restaurants')
      .select('*, menu_items(*)')
      .eq('id', dto.restaurant_id)
      .single();

    if (restError || !restaurant) {
      throw new BadRequestException('Restaurant introuvable');
    }

    if (!restaurant.is_open) {
      throw new BadRequestException('Restaurant fermé');
    }

    // 2. Calculer le total (côté serveur = sécurisé)
    let subtotal = 0;
    const orderItems = [];

    for (const item of dto.items) {
      const menuItem = restaurant.menu_items.find(
        (mi: any) => mi.id === item.menu_item_id
      );

      if (!menuItem) {
        throw new BadRequestException(`Plat introuvable: ${item.menu_item_id}`);
      }

      if (!menuItem.is_available) {
        throw new BadRequestException(`${menuItem.name} n'est plus disponible`);
      }

      subtotal += menuItem.price * item.quantity;
      orderItems.push({
        menu_item_id: item.menu_item_id,
        quantity: item.quantity,
        unit_price: menuItem.price,
        total_price: menuItem.price * item.quantity,
        name: menuItem.name,
      });
    }

    // 3. Calculer les frais de livraison
    const estimatedDistance = 5; // TODO: Calculer vraie distance
    const deliveryFee = this.deliveryService.calculateDeliveryPrice(
      estimatedDistance,
      'tigzirt'
    );

    const totalAmount = subtotal + deliveryFee;

    // 4. Générer numéro de commande
    const orderNumber = `DZ${Date.now().toString(36).toUpperCase()}`;

    // 5. Créer la commande
    const { data: order, error: orderError } = await supabase
      .from('orders')
      .insert({
        user_id: userId,
        restaurant_id: dto.restaurant_id,
        order_number: orderNumber,
        status: 'pending',
        subtotal,
        delivery_fee: deliveryFee,
        total_amount: totalAmount,
        delivery_address: dto.delivery_address,
        delivery_lat: dto.delivery_lat,
        delivery_lng: dto.delivery_lng,
        notes: dto.notes,
      })
      .select()
      .single();

    if (orderError) {
      throw new BadRequestException('Erreur création commande');
    }

    // 6. Créer les items
    const itemsToInsert = orderItems.map(item => ({
      ...item,
      order_id: order.id,
    }));
    await supabase.from('order_items').insert(itemsToInsert);

    // 7. Notifier le restaurant (OneSignal)
    await this.notificationsService.notifyNewOrder(order.id);

    return { order, items: orderItems };
  }

  /**
   * Restaurant accepte la commande
   */
  async acceptOrder(orderId: string, restaurantOwnerId: string) {
    const order = await this.supabaseService.getOrderById(orderId);
    const restaurant = await this.supabaseService.getRestaurantById(order.restaurant_id);

    if (restaurant.owner_id !== restaurantOwnerId) {
      throw new BadRequestException('Non autorisé');
    }

    await this.supabaseService.updateOrderStatus(orderId, 'accepted');
    await this.notificationsService.notifyOrderAccepted(orderId);

    return { success: true };
  }

  /**
   * Commande prête → Assigner livreur
   */
  async markReady(orderId: string, restaurantOwnerId: string) {
    const order = await this.supabaseService.getOrderById(orderId);
    const restaurant = await this.supabaseService.getRestaurantById(order.restaurant_id);

    if (restaurant.owner_id !== restaurantOwnerId) {
      throw new BadRequestException('Non autorisé');
    }

    await this.supabaseService.updateOrderStatus(orderId, 'ready');
    await this.notificationsService.notifyOrderReady(orderId);

    // Assigner un livreur
    const driver = await this.deliveryService.assignDriver(orderId);

    if (driver) {
      await this.notificationsService.notifyDriverNewDelivery(driver.id, orderId);
      await this.notificationsService.notifyDriverAssigned(orderId, driver.id);
    }

    return { success: true, driver };
  }

  /**
   * Livreur confirme livraison
   */
  async markDelivered(orderId: string, driverId: string) {
    const order = await this.supabaseService.getOrderById(orderId);

    if (order.driver_id !== driverId) {
      throw new BadRequestException('Non autorisé');
    }

    await this.supabaseService.updateOrderStatus(orderId, 'delivered');
    await this.notificationsService.notifyOrderDelivered(orderId);

    return { success: true };
  }
}
```

#### 📄 `backend/src/modules/orders/orders.controller.ts`
```typescript
import { Controller, Post, Body, Param, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { OrdersService } from './orders.service';
import { SupabaseAuthGuard } from '../../common/guards/supabase-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { CreateOrderDto } from './dto/create-order.dto';

@ApiTags('Orders')
@Controller('api/orders')
export class OrdersController {
  constructor(private ordersService: OrdersService) {}

  @Post('create')
  @UseGuards(SupabaseAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Créer une commande' })
  async create(@CurrentUser() user: any, @Body() dto: CreateOrderDto) {
    return this.ordersService.createOrder(user.id, dto);
  }

  @Post(':id/accept')
  @UseGuards(SupabaseAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Accepter une commande (restaurant)' })
  async accept(@Param('id') id: string, @CurrentUser() user: any) {
    return this.ordersService.acceptOrder(id, user.id);
  }

  @Post(':id/ready')
  @UseGuards(SupabaseAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Marquer prête (restaurant)' })
  async ready(@Param('id') id: string, @CurrentUser() user: any) {
    return this.ordersService.markReady(id, user.id);
  }

  @Post(':id/delivered')
  @UseGuards(SupabaseAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Confirmer livraison (livreur)' })
  async delivered(@Param('id') id: string, @CurrentUser() user: any) {
    return this.ordersService.markDelivered(id, user.id);
  }
}
```

#### 📄 `backend/src/modules/orders/orders.module.ts`
```typescript
import { Module } from '@nestjs/common';
import { OrdersController } from './orders.controller';
import { OrdersService } from './orders.service';
import { NotificationsModule } from '../notifications/notifications.module';
import { DeliveryModule } from '../delivery/delivery.module';

@Module({
  imports: [NotificationsModule, DeliveryModule],
  controllers: [OrdersController],
  providers: [OrdersService],
})
export class OrdersModule {}
```

---

## 🐳 PHASE 5 : DOCKERFILE

#### 📄 `backend/Dockerfile`
```dockerfile
FROM node:20-alpine

WORKDIR /app

COPY package*.json ./

RUN npm ci --only=production

COPY . .

RUN npm run build

EXPOSE 3000

CMD ["npm", "run", "start:prod"]
```

#### 📄 `backend/tsconfig.json`
```json
{
  "compilerOptions": {
    "module": "commonjs",
    "declaration": true,
    "removeComments": true,
    "emitDecoratorMetadata": true,
    "experimentalDecorators": true,
    "allowSyntheticDefaultImports": true,
    "target": "ES2021",
    "sourceMap": true,
    "outDir": "./dist",
    "baseUrl": "./",
    "incremental": true,
    "skipLibCheck": true,
    "strictNullChecks": true,
    "noImplicitAny": false,
    "strictBindCallApply": false,
    "forceConsistentCasingInFileNames": false,
    "noFallthroughCasesInSwitch": false
  }
}
```

#### 📄 `backend/nest-cli.json`
```json
{
  "$schema": "https://json.schemastore.org/nest-cli",
  "collection": "@nestjs/schematics",
  "sourceRoot": "src",
  "compilerOptions": {
    "deleteOutDir": true
  }
}
```

#### 📄 `backend/.gitignore`
```
node_modules/
dist/
.env
*.log
```

---

## 📱 PHASE 6 : INTÉGRATION FLUTTER + ONESIGNAL

### 6.1 Ajouter dépendances Flutter

```yaml
# apps/dz_delivery/pubspec.yaml (et admin_app)
dependencies:
  onesignal_flutter: ^5.1.0
  http: ^1.1.0
```

### 6.2 Initialiser OneSignal

```dart
// apps/dz_delivery/lib/main.dart

import 'package:onesignal_flutter/onesignal_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Supabase init (existant)
  await Supabase.initialize(...);
  
  // OneSignal init (NOUVEAU)
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose); // Désactiver en prod
  OneSignal.initialize("TON_ONESIGNAL_APP_ID");
  OneSignal.Notifications.requestPermission(true);
  
  runApp(MyApp());
}
```

### 6.3 Lier utilisateur Supabase à OneSignal

```dart
// apps/shared/lib/services/auth_service.dart (ou équivalent)

Future<void> onLoginSuccess(User user) async {
  // Lier l'utilisateur Supabase à OneSignal
  // Permet d'envoyer des notifications ciblées par user ID
  OneSignal.login(user.id);
  
  // Récupérer le profil pour savoir le rôle
  final profile = await getProfile(user.id);
  
  // Ajouter des tags pour filtrer
  OneSignal.User.addTags({
    'role': profile.role, // 'client', 'restaurant', 'livreur'
    'user_id': user.id,
  });
}

Future<void> onLogout() async {
  OneSignal.logout();
}
```

### 6.4 Service API Backend

```dart
// apps/shared/lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiService {
  // ⚠️ REMPLACER par ton URL Koyeb après déploiement
  static const String baseUrl = 'https://tigzirt-backend.koyeb.app';
  
  final SupabaseClient _supabase;
  
  ApiService(this._supabase);

  Future<Map<String, String>> get _headers async {
    final session = _supabase.auth.currentSession;
    return {
      'Content-Type': 'application/json',
      if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
    };
  }

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _headers,
      body: json.encode(body),
    );
    
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('API Error: ${response.body}');
    }
    
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> get(String endpoint, {Map<String, String>? params}) async {
    final uri = Uri.parse('$baseUrl$endpoint').replace(queryParameters: params);
    final response = await http.get(uri, headers: await _headers);
    
    if (response.statusCode != 200) {
      throw Exception('API Error: ${response.body}');
    }
    
    return json.decode(response.body);
  }

  // ═══════════════════════════════════════════════
  // ENDPOINTS
  // ═══════════════════════════════════════════════

  Future<int> calculateDeliveryPrice(double distance, String zone) async {
    final result = await get('/api/delivery/calculate-price', params: {
      'distance': distance.toString(),
      'zone': zone,
    });
    return result['price'];
  }

  Future<Map<String, dynamic>> createOrder({
    required String restaurantId,
    required List<Map<String, dynamic>> items,
    required String deliveryAddress,
    required double deliveryLat,
    required double deliveryLng,
    String? notes,
  }) async {
    return post('/api/orders/create', {
      'restaurant_id': restaurantId,
      'items': items,
      'delivery_address': deliveryAddress,
      'delivery_lat': deliveryLat,
      'delivery_lng': deliveryLng,
      if (notes != null) 'notes': notes,
    });
  }

  Future<void> acceptOrder(String orderId) async {
    await post('/api/orders/$orderId/accept', {});
  }

  Future<Map<String, dynamic>> markOrderReady(String orderId) async {
    return post('/api/orders/$orderId/ready', {});
  }

  Future<void> markOrderDelivered(String orderId) async {
    await post('/api/orders/$orderId/delivered', {});
  }
}
```

---

## 🚀 PHASE 7 : DÉPLOIEMENT KOYEB

### 7.1 Push vers GitHub

```bash
cd backend
git init
git add .
git commit -m "Backend NestJS + OneSignal"
git remote add origin https://github.com/USERNAME/tigzirt-backend.git
git push -u origin main
```

### 7.2 Configurer Koyeb

```
1. https://www.koyeb.com/ → Sign up (gratuit)
2. "Create App" → "GitHub"
3. Sélectionner le repo

┌─────────────────────────────────────────┐
│  Build settings                         │
│  ─────────────                          │
│  Builder: Dockerfile                    │
│                                         │
│  Run settings                           │
│  ────────────                           │
│  Port: 3000                             │
│                                         │
│  Environment variables                  │
│  ─────────────────────                  │
│  PORT=3000                              │
│  NODE_ENV=production                    │
│  SUPABASE_URL=https://xxx.supabase.co   │
│  SUPABASE_SERVICE_KEY=eyJxxx            │
│  ONESIGNAL_APP_ID=xxx-xxx-xxx           │
│  ONESIGNAL_API_KEY=xxx                  │
└─────────────────────────────────────────┘

4. "Deploy"
5. Attendre 2-3 minutes
6. URL: https://tigzirt-backend-xxx.koyeb.app
```

### 7.3 Tester

```bash
# Health check
curl https://tigzirt-backend-xxx.koyeb.app/health

# Swagger docs
# https://tigzirt-backend-xxx.koyeb.app/api/docs
```

---

## ✅ CHECKLIST FINALE

### Backend :
- [ ] Tous les modules créés
- [ ] OneSignal configuré (PAS Firebase)
- [ ] Dockerfile présent
- [ ] .env.example complet

### Koyeb :
- [ ] Repo GitHub connecté
- [ ] Variables d'environnement définies
- [ ] Déploiement réussi
- [ ] Health check OK

### Flutter :
- [ ] onesignal_flutter ajouté
- [ ] OneSignal.initialize() dans main()
- [ ] OneSignal.login() après connexion
- [ ] ApiService créé

### OneSignal :
- [ ] Compte créé sur onesignal.com
- [ ] App créée
- [ ] APP_ID et API_KEY récupérés
- [ ] Android configuré
- [ ] iOS configuré (si nécessaire)

---

## 📊 RÉCAPITULATIF COÛTS

| Service | Coût | Carte requise |
|---------|------|---------------|
| Koyeb | **GRATUIT** | ❌ Non |
| Supabase | **GRATUIT** | ❌ Non |
| OneSignal | **GRATUIT** | ❌ Non |
| **TOTAL** | **0 DA** | ❌ Non |

---

**FIN DU PROMPT - Backend Koyeb + OneSignal (100% GRATUIT)**
