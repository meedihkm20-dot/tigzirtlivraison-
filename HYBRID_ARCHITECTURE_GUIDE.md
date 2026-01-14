# 🏗️ Architecture Hybrid - Guide Complet

## Vue d'Ensemble

```
┌─────────────────────────────────────────┐
│         Flutter Apps (Mobile)           │
│  • dz_delivery (multi-rôle)            │
│  • customer_app, restaurant_app, etc.   │
└─────────────────┬───────────────────────┘
                  │
        ┌─────────┴─────────┐
        │                   │
        ▼                   ▼
┌───────────────────┐   ┌──────────────────┐
│ Vercel            │   │ Supabase         │
│ (Backend NestJS)  │   │                  │
├───────────────────┤   ├──────────────────┤
│ • API REST        │   │ • Realtime       │
│ • Business Logic  │   │ • Auth (backup)  │
│ • Validations     │   │ • Storage        │
│ • Payments        │   │ • Edge Functions │
│ • Notifications   │   │                  │
└─────────┬─────────┘   └────────┬─────────┘
          │                      │
          └──────────┬───────────┘
                     ▼
            ┌────────────────┐
            │ Supabase DB    │
            │ (PostgreSQL)   │
            └────────────────┘
```

## Responsabilités

### Supabase (Garde)
- ✅ **Database**: PostgreSQL avec toutes tes tables
- ✅ **Realtime**: Tracking des livreurs en temps réel
- ✅ **Auth**: Authentification (optionnel, peut migrer vers Vercel)
- ✅ **Storage**: Images des restaurants, profils, etc.
- ✅ **RLS**: Sécurité au niveau des lignes

### Vercel (Nouveau)
- ✅ **API REST**: Tous les endpoints NestJS
- ✅ **Business Logic**: Calculs, validations, workflows
- ✅ **Intégrations**: Paiements, SMS, emails
- ✅ **Caching**: Redis/Upstash pour performances
- ✅ **CORS**: Gestion des requêtes cross-origin

## Flux de Données

### Exemple 1: Créer une Commande

```
Flutter App
    │
    ├─→ POST /api/orders (Vercel)
    │       │
    │       ├─→ Valide les données
    │       ├─→ Calcule le prix
    │       ├─→ Vérifie le restaurant
    │       │
    │       └─→ INSERT dans Supabase DB
    │               │
    │               └─→ Trigger SQL notifie Realtime
    │                       │
    └───────────────────────┴─→ Flutter reçoit update via Supabase Realtime
```

### Exemple 2: Tracking Livreur

```
Flutter App (Livreur)
    │
    ├─→ POST /api/location (Vercel)
    │       │
    │       └─→ UPDATE dans Supabase DB
    │               │
    │               └─→ Realtime broadcast
    │
Flutter App (Client)
    │
    └─→ Subscribe Supabase Realtime
            │
            └─→ Reçoit position en temps réel
```

## Avantages de cette Architecture

### 1. Meilleur des Deux Mondes
- ✅ Contrôle total sur la logique (Vercel)
- ✅ Realtime qui fonctionne (Supabase)
- ✅ Pas de vendor lock-in complet

### 2. Performance
- ✅ Vercel: Edge network mondial
- ✅ Supabase: Connexions poolées
- ✅ Cache Redis pour requêtes fréquentes

### 3. Coûts
- ✅ Vercel Hobby: Gratuit
- ✅ Supabase Free: 500 MB DB
- ✅ Total: $0/mois pour commencer

### 4. Scalabilité
- ✅ Vercel scale automatiquement
- ✅ Supabase gère les connexions
- ✅ Pas de serveur à gérer

## Migration Progressive

### Semaine 1: Setup Initial
1. ✅ Configurer Vercel
2. ✅ Déployer backend NestJS
3. ✅ Connecter à Supabase DB
4. ✅ Tester les endpoints

### Semaine 2: Migration des Endpoints
1. ✅ Migrer `/auth` vers Vercel
2. ✅ Migrer `/orders` vers Vercel
3. ✅ Migrer `/restaurants` vers Vercel
4. ✅ Garder Realtime sur Supabase

### Semaine 3: Optimisations
1. ✅ Ajouter cache Redis
2. ✅ Ajouter retry logic
3. ✅ Ajouter monitoring
4. ✅ Tests de charge

### Semaine 4: Production
1. ✅ Migration complète Flutter apps
2. ✅ Tests end-to-end
3. ✅ Monitoring en production
4. ✅ Documentation

## Configuration Technique

### Backend NestJS → Vercel

**Connexion à Supabase DB:**
```typescript
// backend/src/config/database.config.ts
import { TypeOrmModuleOptions } from '@nestjs/typeorm';

export const databaseConfig: TypeOrmModuleOptions = {
  type: 'postgres',
  url: process.env.SUPABASE_DB_URL,
  // Format: postgresql://postgres:[PASSWORD]@db.[PROJECT_REF].supabase.co:5432/postgres
  ssl: { rejectUnauthorized: false },
  entities: ['dist/**/*.entity{.ts,.js}'],
  synchronize: false, // IMPORTANT: false en production
  logging: process.env.NODE_ENV === 'development',
};
```

**Realtime via Supabase Client:**
```typescript
// backend/src/services/realtime.service.ts
import { createClient } from '@supabase/supabase-js';

export class RealtimeService {
  private supabase = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_SERVICE_KEY, // Service key pour backend
  );

  async broadcastOrderUpdate(orderId: string, data: any) {
    await this.supabase
      .channel(`order_${orderId}`)
      .send({
        type: 'broadcast',
        event: 'order_update',
        payload: data,
      });
  }
}
```

### Flutter Apps → Vercel + Supabase

**Service API (Vercel):**
```dart
// lib/core/services/api_service.dart
class ApiService {
  static const String baseUrl = 'https://ton-api.vercel.app';
  
  static Future<Order> createOrder(OrderData data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/orders'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await SupabaseService.getToken()}',
      },
      body: jsonEncode(data.toJson()),
    );
    
    if (response.statusCode == 201) {
      return Order.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create order');
  }
}
```

**Realtime (Supabase):**
```dart
// lib/core/services/realtime_service.dart
class RealtimeService {
  static RealtimeChannel subscribeToOrder(String orderId, Function(Map) onUpdate) {
    return SupabaseService.client
      .channel('order_$orderId')
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'orders',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: orderId,
        ),
        callback: (payload) => onUpdate(payload.newRecord),
      )
      .subscribe();
  }
}
```

## Variables d'Environnement

### Vercel (Backend)
```env
# Supabase Database
SUPABASE_DB_URL=postgresql://postgres:[PASSWORD]@db.[PROJECT_REF].supabase.co:5432/postgres

# Supabase API (pour Realtime)
SUPABASE_URL=https://[PROJECT_REF].supabase.co
SUPABASE_SERVICE_KEY=eyJhbGc...

# JWT
JWT_SECRET=ton-secret-jwt
JWT_EXPIRES_IN=7d

# Redis (optionnel)
REDIS_URL=redis://...

# Autres
NODE_ENV=production
PORT=3000
```

### Flutter Apps
```dart
// lib/core/config/app_config.dart
class AppConfig {
  // Vercel API
  static const String apiBaseUrl = 'https://ton-api.vercel.app';
  
  // Supabase (pour Realtime et Storage)
  static const String supabaseUrl = 'https://pauqmhqriyjdqctvfvtt.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGc...';
}
```

## Sécurité

### 1. Authentication
- ✅ JWT tokens générés par Vercel
- ✅ Validés par middleware NestJS
- ✅ Refresh tokens stockés en DB

### 2. Authorization
- ✅ Guards NestJS pour les rôles
- ✅ RLS Supabase comme backup
- ✅ Validation des permissions

### 3. Rate Limiting
```typescript
// backend/src/main.ts
import rateLimit from 'express-rate-limit';

app.use(
  rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100, // 100 requêtes max
  }),
);
```

## Monitoring

### Vercel
- ✅ Logs automatiques
- ✅ Analytics intégrés
- ✅ Error tracking

### Supabase
- ✅ Database metrics
- ✅ Realtime connections
- ✅ Storage usage

### Sentry (Recommandé)
```typescript
// backend/src/main.ts
import * as Sentry from '@sentry/node';

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  environment: process.env.NODE_ENV,
});
```

## Coûts Estimés

### Gratuit (0-1000 utilisateurs)
- Vercel Hobby: $0
- Supabase Free: $0
- Total: **$0/mois**

### Croissance (1000-10000 utilisateurs)
- Vercel Pro: $20/mois
- Supabase Pro: $25/mois
- Upstash Redis: $10/mois
- Total: **$55/mois**

### Scale (10000+ utilisateurs)
- Vercel Enterprise: $150/mois
- Supabase Team: $599/mois
- Total: **$749/mois**

## Prochaines Étapes

1. ✅ Créer compte Vercel
2. ✅ Configurer `vercel.json`
3. ✅ Déployer backend
4. ✅ Tester les endpoints
5. ✅ Migrer Flutter apps progressivement

Voir `VERCEL_DEPLOYMENT_GUIDE.md` pour les instructions détaillées.
