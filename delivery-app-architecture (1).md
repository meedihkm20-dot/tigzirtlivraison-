# Architecture Application Livraison - DZ Delivery

## 1. Schéma de Base de Données (PostgreSQL)

### Vue d'ensemble des entités

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│    USERS     │     │  RESTAURANTS │     │   LIVREURS   │
│   (clients)  │     │              │     │              │
└──────┬───────┘     └──────┬───────┘     └──────┬───────┘
       │                    │                    │
       │              ┌─────┴─────┐              │
       │              │   MENUS   │              │
       │              │  (plats)  │              │
       │              └─────┬─────┘              │
       │                    │                    │
       └────────────┬───────┴───────────────────┘
                    │
              ┌─────┴─────┐
              │ COMMANDES │
              └─────┬─────┘
                    │
              ┌─────┴─────┐
              │ PAIEMENTS │
              └───────────┘
```

---

### Tables détaillées

#### 1. users (Clients)

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone VARCHAR(15) UNIQUE NOT NULL,  -- +213XXXXXXXXX
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    
    -- Adresses (peut en avoir plusieurs)
    default_address_id UUID,
    
    -- Statut
    is_active BOOLEAN DEFAULT true,
    is_verified BOOLEAN DEFAULT false,
    
    -- Métadonnées
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Adresses des clients
CREATE TABLE user_addresses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    label VARCHAR(50),  -- "Maison", "Travail", etc.
    address_line VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    wilaya VARCHAR(100) NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### 2. restaurants

```sql
CREATE TABLE restaurants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Infos de base
    name VARCHAR(150) NOT NULL,
    slug VARCHAR(150) UNIQUE NOT NULL,  -- pour URL: dz-delivery.com/restau/le-sultan
    description TEXT,
    phone VARCHAR(15) NOT NULL,
    email VARCHAR(255),
    password_hash VARCHAR(255) NOT NULL,
    
    -- Localisation
    address VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    wilaya VARCHAR(100) NOT NULL,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    delivery_radius_km DECIMAL(4, 2) DEFAULT 5.00,  -- Rayon de livraison
    
    -- Médias
    logo_url VARCHAR(500),
    cover_image_url VARCHAR(500),
    
    -- Business
    commission_rate DECIMAL(4, 2) DEFAULT 10.00,  -- Ta commission %
    min_order_amount DECIMAL(10, 2) DEFAULT 500,  -- Commande minimum (DA)
    avg_preparation_time INT DEFAULT 30,  -- Minutes
    
    -- Horaires (JSON pour flexibilité)
    opening_hours JSONB DEFAULT '{
        "monday": {"open": "08:00", "close": "23:00"},
        "tuesday": {"open": "08:00", "close": "23:00"},
        "wednesday": {"open": "08:00", "close": "23:00"},
        "thursday": {"open": "08:00", "close": "23:00"},
        "friday": {"open": "08:00", "close": "23:00"},
        "saturday": {"open": "08:00", "close": "23:00"},
        "sunday": {"open": "08:00", "close": "23:00"}
    }',
    
    -- Statut
    is_active BOOLEAN DEFAULT true,
    is_verified BOOLEAN DEFAULT false,
    is_open BOOLEAN DEFAULT true,  -- Peut fermer manuellement
    
    -- Stats
    rating DECIMAL(2, 1) DEFAULT 0,
    total_orders INT DEFAULT 0,
    
    -- Métadonnées
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Catégories de restaurants
CREATE TABLE restaurant_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,  -- "Pizza", "Tacos", "Traditionnel"
    icon VARCHAR(50),
    display_order INT DEFAULT 0
);

CREATE TABLE restaurant_category_mapping (
    restaurant_id UUID REFERENCES restaurants(id) ON DELETE CASCADE,
    category_id UUID REFERENCES restaurant_categories(id) ON DELETE CASCADE,
    PRIMARY KEY (restaurant_id, category_id)
);
```

#### 3. menus (Plats)

```sql
-- Catégories du menu (Entrées, Plats, Desserts, Boissons)
CREATE TABLE menu_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    restaurant_id UUID REFERENCES restaurants(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    display_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT true
);

-- Plats
CREATE TABLE menu_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    restaurant_id UUID REFERENCES restaurants(id) ON DELETE CASCADE,
    category_id UUID REFERENCES menu_categories(id) ON DELETE SET NULL,
    
    name VARCHAR(150) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,  -- Prix en DA
    
    image_url VARCHAR(500),
    
    -- Options
    is_available BOOLEAN DEFAULT true,
    is_featured BOOLEAN DEFAULT false,  -- Mis en avant
    preparation_time INT,  -- Minutes (optionnel)
    
    -- Stats
    total_orders INT DEFAULT 0,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Options/Suppléments (ex: sauce, fromage extra)
CREATE TABLE menu_item_options (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    menu_item_id UUID REFERENCES menu_items(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,  -- "Supplément fromage"
    price DECIMAL(10, 2) DEFAULT 0,  -- Prix additionnel
    is_required BOOLEAN DEFAULT false,
    max_selections INT DEFAULT 1
);

CREATE TABLE menu_item_option_choices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    option_id UUID REFERENCES menu_item_options(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,  -- "Cheddar", "Mozzarella"
    price DECIMAL(10, 2) DEFAULT 0
);
```

#### 4. livreurs

```sql
CREATE TABLE livreurs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Infos personnelles
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(15) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    
    -- Documents
    id_card_number VARCHAR(50),
    id_card_image_url VARCHAR(500),
    driver_license_url VARCHAR(500),
    
    -- Véhicule
    vehicle_type VARCHAR(20) NOT NULL,  -- 'moto', 'velo', 'voiture'
    vehicle_plate VARCHAR(20),
    
    -- Zone de travail
    city VARCHAR(100) NOT NULL,
    wilaya VARCHAR(100) NOT NULL,
    
    -- Position temps réel
    current_latitude DECIMAL(10, 8),
    current_longitude DECIMAL(11, 8),
    last_location_update TIMESTAMP,
    
    -- Statut
    is_active BOOLEAN DEFAULT true,
    is_verified BOOLEAN DEFAULT false,  -- Admin a validé les docs
    is_online BOOLEAN DEFAULT false,    -- Disponible pour livraisons
    is_busy BOOLEAN DEFAULT false,      -- En cours de livraison
    
    -- Finance
    wallet_balance DECIMAL(10, 2) DEFAULT 0,  -- Si tu veux un système de wallet
    
    -- Stats
    rating DECIMAL(2, 1) DEFAULT 5.0,
    total_deliveries INT DEFAULT 0,
    total_earnings DECIMAL(12, 2) DEFAULT 0,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Zones de livraison préférées du livreur
CREATE TABLE livreur_zones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    livreur_id UUID REFERENCES livreurs(id) ON DELETE CASCADE,
    city VARCHAR(100) NOT NULL,
    wilaya VARCHAR(100) NOT NULL,
    is_active BOOLEAN DEFAULT true
);
```

#### 5. commandes (LE CŒUR DU SYSTÈME)

```sql
-- Statuts possibles d'une commande
CREATE TYPE order_status AS ENUM (
    'pending',           -- En attente d'acceptation livreur
    'accepted',          -- Livreur a accepté
    'preparing',         -- Restaurant prépare
    'ready',             -- Prêt à récupérer
    'picked_up',         -- Livreur a récupéré
    'delivering',        -- En cours de livraison
    'delivered',         -- Livrée
    'cancelled'          -- Annulée
);

CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_number VARCHAR(20) UNIQUE NOT NULL,  -- Format: DZ-20250112-001
    
    -- Relations
    user_id UUID REFERENCES users(id),
    restaurant_id UUID REFERENCES restaurants(id),
    livreur_id UUID REFERENCES livreurs(id),
    delivery_address_id UUID REFERENCES user_addresses(id),
    
    -- Statut
    status order_status DEFAULT 'pending',
    
    -- Montants
    subtotal DECIMAL(10, 2) NOT NULL,      -- Total plats
    delivery_fee DECIMAL(10, 2) NOT NULL,  -- Frais livraison
    total_amount DECIMAL(10, 2) NOT NULL,  -- subtotal + delivery_fee
    
    -- Commission
    platform_commission DECIMAL(10, 2),     -- Ta commission (calculée)
    commission_rate DECIMAL(4, 2),          -- % appliqué
    
    -- Livraison
    delivery_distance_km DECIMAL(5, 2),
    estimated_delivery_time INT,  -- Minutes
    
    -- Sécurité
    confirmation_code VARCHAR(4),  -- Code à donner au livreur
    
    -- Notes
    customer_notes TEXT,  -- "Sans oignons", "Sonnez 2 fois"
    restaurant_notes TEXT,
    
    -- Timestamps détaillés
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    accepted_at TIMESTAMP,        -- Livreur accepte
    preparing_at TIMESTAMP,       -- Restau commence
    ready_at TIMESTAMP,           -- Restau termine
    picked_up_at TIMESTAMP,       -- Livreur récupère
    delivered_at TIMESTAMP,       -- Livraison effectuée
    cancelled_at TIMESTAMP,
    cancelled_by VARCHAR(20),     -- 'user', 'restaurant', 'livreur', 'admin'
    cancellation_reason TEXT
);

-- Détails de la commande (plats commandés)
CREATE TABLE order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    menu_item_id UUID REFERENCES menu_items(id),
    
    -- Snapshot au moment de la commande (si le prix change après)
    item_name VARCHAR(150) NOT NULL,
    item_price DECIMAL(10, 2) NOT NULL,
    
    quantity INT NOT NULL DEFAULT 1,
    total_price DECIMAL(10, 2) NOT NULL,  -- item_price * quantity + options
    
    special_instructions TEXT  -- "Bien cuit", "Sans sauce"
);

-- Options sélectionnées pour chaque item
CREATE TABLE order_item_options (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_item_id UUID REFERENCES order_items(id) ON DELETE CASCADE,
    option_name VARCHAR(100) NOT NULL,
    choice_name VARCHAR(100),
    price DECIMAL(10, 2) DEFAULT 0
);

-- Historique des changements de statut
CREATE TABLE order_status_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    status order_status NOT NULL,
    changed_by VARCHAR(20),  -- 'system', 'user', 'restaurant', 'livreur', 'admin'
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### 6. notifications

```sql
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Destinataire (un seul sera rempli)
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    restaurant_id UUID REFERENCES restaurants(id) ON DELETE CASCADE,
    livreur_id UUID REFERENCES livreurs(id) ON DELETE CASCADE,
    
    -- Contenu
    title VARCHAR(150) NOT NULL,
    body TEXT NOT NULL,
    data JSONB,  -- Données additionnelles (order_id, etc.)
    
    -- Type
    type VARCHAR(50) NOT NULL,  -- 'new_order', 'order_ready', 'order_delivered'
    
    -- Statut
    is_read BOOLEAN DEFAULT false,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tokens FCM pour les push notifications
CREATE TABLE device_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    restaurant_id UUID REFERENCES restaurants(id) ON DELETE CASCADE,
    livreur_id UUID REFERENCES livreurs(id) ON DELETE CASCADE,
    
    token VARCHAR(500) NOT NULL,
    device_type VARCHAR(20),  -- 'android', 'ios', 'web'
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### 7. évaluations

```sql
CREATE TABLE reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES orders(id) UNIQUE,  -- Une review par commande
    user_id UUID REFERENCES users(id),
    
    -- Notes
    restaurant_rating INT CHECK (restaurant_rating BETWEEN 1 AND 5),
    livreur_rating INT CHECK (livreur_rating BETWEEN 1 AND 5),
    
    -- Commentaires
    restaurant_comment TEXT,
    livreur_comment TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### 8. comptabilité / paiements

```sql
-- Transactions financières
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES orders(id),
    
    -- Type
    type VARCHAR(50) NOT NULL,  -- 'order_payment', 'commission', 'payout'
    
    -- Montant
    amount DECIMAL(10, 2) NOT NULL,
    
    -- Parties concernées
    from_entity_type VARCHAR(20),  -- 'user', 'restaurant', 'platform'
    from_entity_id UUID,
    to_entity_type VARCHAR(20),
    to_entity_id UUID,
    
    -- Statut
    status VARCHAR(20) DEFAULT 'completed',  -- 'pending', 'completed', 'failed'
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Factures hebdomadaires aux restaurants
CREATE TABLE invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_number VARCHAR(30) UNIQUE NOT NULL,  -- FACT-2025-001
    restaurant_id UUID REFERENCES restaurants(id),
    
    -- Période
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    
    -- Montants
    total_orders INT NOT NULL,
    total_sales DECIMAL(12, 2) NOT NULL,
    commission_rate DECIMAL(4, 2) NOT NULL,
    commission_amount DECIMAL(12, 2) NOT NULL,  -- Ce que le restau te doit
    
    -- Statut
    status VARCHAR(20) DEFAULT 'pending',  -- 'pending', 'paid', 'overdue'
    paid_at TIMESTAMP,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    due_date DATE NOT NULL
);
```

#### 9. admin

```sql
CREATE TABLE admins (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    role VARCHAR(20) DEFAULT 'admin',  -- 'super_admin', 'admin', 'support'
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Logs des actions admin
CREATE TABLE admin_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id UUID REFERENCES admins(id),
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50),
    entity_id UUID,
    details JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

### Index pour la Performance (CRITIQUE)

```sql
-- ═══════════════════════════════════════════════════════════════
-- INDEX ESSENTIELS POUR LA RAPIDITÉ DES REQUÊTES
-- ═══════════════════════════════════════════════════════════════

-- Users
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_user_addresses_user ON user_addresses(user_id);

-- Restaurants
CREATE INDEX idx_restaurants_city ON restaurants(city);
CREATE INDEX idx_restaurants_wilaya ON restaurants(wilaya);
CREATE INDEX idx_restaurants_active_open ON restaurants(is_active, is_open);
CREATE INDEX idx_restaurants_location ON restaurants USING gist (
    ll_to_earth(latitude, longitude)
);  -- Pour recherche par proximité

-- Menu
CREATE INDEX idx_menu_items_restaurant ON menu_items(restaurant_id);
CREATE INDEX idx_menu_items_available ON menu_items(restaurant_id, is_available);
CREATE INDEX idx_menu_categories_restaurant ON menu_categories(restaurant_id);

-- Livreurs
CREATE INDEX idx_livreurs_city_online ON livreurs(city, is_online, is_busy);
CREATE INDEX idx_livreurs_location ON livreurs USING gist (
    ll_to_earth(current_latitude, current_longitude)
);

-- Commandes (TRÈS IMPORTANT)
CREATE INDEX idx_orders_user ON orders(user_id);
CREATE INDEX idx_orders_restaurant ON orders(restaurant_id);
CREATE INDEX idx_orders_livreur ON orders(livreur_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_created ON orders(created_at DESC);
CREATE INDEX idx_orders_restaurant_status ON orders(restaurant_id, status);
CREATE INDEX idx_orders_delivered_date ON orders(delivered_at) 
    WHERE status = 'delivered';  -- Index partiel pour factures

-- Order Items
CREATE INDEX idx_order_items_order ON order_items(order_id);

-- Notifications
CREATE INDEX idx_notifications_user_unread ON notifications(user_id, is_read) 
    WHERE is_read = false;
CREATE INDEX idx_notifications_restaurant ON notifications(restaurant_id, is_read);
CREATE INDEX idx_notifications_livreur ON notifications(livreur_id, is_read);

-- Factures
CREATE INDEX idx_invoices_restaurant ON invoices(restaurant_id);
CREATE INDEX idx_invoices_status ON invoices(status);
```

---

## 2. Architecture Technique

### Stack recommandée

```
┌─────────────────────────────────────────────────────────────┐
│                        CLIENTS                              │
├─────────────┬─────────────┬─────────────┬─────────────────┤
│ App Client  │ App Livreur │ App Restau  │  Admin Panel    │
│  (Flutter)  │  (Flutter)  │  (Flutter)  │   (Next.js)     │
└──────┬──────┴──────┬──────┴──────┬──────┴────────┬────────┘
       │             │             │               │
       └─────────────┴──────┬──────┴───────────────┘
                            │
                    ┌───────┴───────┐
                    │   API Gateway  │
                    │   (NestJS)     │
                    └───────┬───────┘
                            │
       ┌────────────────────┼────────────────────┐
       │                    │                    │
┌──────┴──────┐     ┌───────┴───────┐    ┌──────┴──────┐
│  PostgreSQL │     │     Redis     │    │   Firebase  │
│  (Supabase) │     │   (Cache +    │    │    (FCM)    │
│             │     │   Real-time)  │    │             │
└─────────────┘     └───────────────┘    └─────────────┘
```

### Structure du projet NestJS

```
src/
├── main.ts
├── app.module.ts
│
├── common/
│   ├── decorators/
│   ├── filters/
│   ├── guards/
│   ├── interceptors/
│   │   └── cache.interceptor.ts      # Cache Redis
│   └── pipes/
│
├── config/
│   ├── database.config.ts
│   ├── firebase.config.ts
│   ├── redis.config.ts               # Configuration Redis
│   └── jwt.config.ts
│
├── modules/
│   ├── auth/
│   │   ├── auth.module.ts
│   │   ├── auth.controller.ts
│   │   ├── auth.service.ts
│   │   ├── strategies/
│   │   │   └── jwt.strategy.ts
│   │   └── dto/
│   │       ├── login.dto.ts
│   │       └── register.dto.ts
│   │
│   ├── users/
│   │   ├── users.module.ts
│   │   ├── users.controller.ts
│   │   ├── users.service.ts
│   │   └── entities/
│   │       └── user.entity.ts
│   │
│   ├── restaurants/
│   │   ├── restaurants.module.ts
│   │   ├── restaurants.controller.ts
│   │   ├── restaurants.service.ts
│   │   ├── entities/
│   │   │   ├── restaurant.entity.ts
│   │   │   ├── menu-category.entity.ts
│   │   │   └── menu-item.entity.ts
│   │   └── dto/
│   │
│   ├── livreurs/
│   │   ├── livreurs.module.ts
│   │   ├── livreurs.controller.ts
│   │   ├── livreurs.service.ts
│   │   └── entities/
│   │       └── livreur.entity.ts
│   │
│   ├── orders/
│   │   ├── orders.module.ts
│   │   ├── orders.controller.ts
│   │   ├── orders.service.ts
│   │   ├── orders.gateway.ts        # WebSocket pour temps réel
│   │   └── entities/
│   │       ├── order.entity.ts
│   │       └── order-item.entity.ts
│   │
│   ├── notifications/
│   │   ├── notifications.module.ts
│   │   ├── notifications.service.ts
│   │   └── firebase.service.ts
│   │
│   ├── payments/
│   │   ├── payments.module.ts
│   │   ├── payments.service.ts
│   │   └── invoices.service.ts
│   │
│   ├── cache/                        # Module Cache
│   │   ├── cache.module.ts
│   │   └── cache.service.ts
│   │
│   ├── admin/
│   │   ├── admin.module.ts
│   │   ├── admin.controller.ts
│   │   └── dashboard.service.ts
│   │
│   └── uploads/
│       ├── uploads.module.ts
│       └── s3.service.ts
│
└── shared/
    ├── utils/
    │   ├── distance.util.ts      # Calcul distances GPS
    │   └── order-number.util.ts  # Génération numéros commande
    └── constants/
```

### Structure Flutter (3 apps) - OPTIMISÉE PERFORMANCE

```
apps/
├── customer_app/          # App Client
│   └── lib/
│       ├── main.dart
│       ├── core/
│       │   ├── api/
│       │   │   ├── api_client.dart
│       │   │   └── interceptors/
│       │   │       ├── cache_interceptor.dart
│       │   │       └── retry_interceptor.dart
│       │   ├── cache/
│       │   │   ├── local_database.dart      # Hive/Drift
│       │   │   └── cache_manager.dart
│       │   ├── models/
│       │   └── services/
│       │       └── connectivity_service.dart
│       ├── features/
│       │   ├── auth/
│       │   ├── home/
│       │   ├── restaurants/
│       │   │   ├── data/
│       │   │   │   └── restaurant_repository.dart  # Offline-first
│       │   │   ├── presentation/
│       │   │   │   ├── restaurant_list_screen.dart
│       │   │   │   └── widgets/
│       │   │   │       ├── restaurant_card.dart    # const + cached image
│       │   │   │       └── restaurant_shimmer.dart # Loading skeleton
│       │   │   └── providers/
│       │   ├── cart/
│       │   │   └── providers/
│       │   │       └── cart_provider.dart  # Optimistic updates
│       │   ├── orders/
│       │   └── profile/
│       └── shared/
│           └── widgets/
│               ├── cached_image.dart
│               ├── shimmer_loading.dart
│               └── optimistic_button.dart
│
├── livreur_app/           # App Livreur
│   └── lib/
│       ├── main.dart
│       ├── core/
│       │   ├── location/
│       │   │   └── location_service.dart    # GPS optimisé
│       │   └── websocket/
│       │       └── socket_service.dart      # Connexion persistante
│       ├── features/
│       │   ├── auth/
│       │   ├── home/           # Carte + commandes dispo
│       │   ├── deliveries/     # Livraisons en cours
│       │   ├── earnings/       # Gains
│       │   └── profile/
│       └── shared/
│
├── restaurant_app/        # App Restaurant
│   └── lib/
│       ├── main.dart
│       ├── core/
│       ├── features/
│       │   ├── auth/
│       │   ├── orders/         # Gestion commandes
│       │   ├── menu/           # Gestion menu
│       │   ├── stats/          # Statistiques
│       │   └── settings/
│       └── shared/
│
└── shared/                # Code partagé entre les 3 apps
    ├── models/
    ├── api/
    ├── constants/
    └── widgets/
        ├── buttons/
        │   └── haptic_button.dart
        └── loading/
            └── shimmer_widget.dart
```

---

## 3. PERFORMANCE & FLUIDITÉ (60 FPS)

### 3.1 Packages Flutter Requis

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  
  # ══════════════════════════════════════════════
  # STATE MANAGEMENT (Rebuild ciblé)
  # ══════════════════════════════════════════════
  flutter_riverpod: ^2.4.0
  
  # ══════════════════════════════════════════════
  # CACHE & OFFLINE
  # ══════════════════════════════════════════════
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  cached_network_image: ^3.3.0
  flutter_cache_manager: ^3.3.1
  
  # ══════════════════════════════════════════════
  # NETWORK
  # ══════════════════════════════════════════════
  dio: ^5.4.0
  dio_smart_retry: ^6.0.0
  connectivity_plus: ^5.0.2
  
  # ══════════════════════════════════════════════
  # UI & ANIMATIONS
  # ══════════════════════════════════════════════
  shimmer: ^3.0.0
  flutter_animate: ^4.3.0
  
  # ══════════════════════════════════════════════
  # REAL-TIME
  # ══════════════════════════════════════════════
  socket_io_client: ^2.0.3+1
  
  # ══════════════════════════════════════════════
  # MAPS & LOCATION
  # ══════════════════════════════════════════════
  google_maps_flutter: ^2.5.0
  geolocator: ^10.1.0
  
  # ══════════════════════════════════════════════
  # NOTIFICATIONS
  # ══════════════════════════════════════════════
  firebase_messaging: ^14.7.0
  flutter_local_notifications: ^16.1.0

dev_dependencies:
  hive_generator: ^2.0.1
  build_runner: ^2.4.6
```

---

### 3.2 Architecture Offline-First

```dart
// lib/core/cache/local_database.dart
import 'package:hive_flutter/hive_flutter.dart';

class LocalDatabase {
  static const String restaurantsBox = 'restaurants';
  static const String menuBox = 'menus';
  static const String ordersBox = 'orders';
  static const String userBox = 'user';

  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Ouvrir les boxes
    await Hive.openBox(restaurantsBox);
    await Hive.openBox(menuBox);
    await Hive.openBox(ordersBox);
    await Hive.openBox(userBox);
  }

  // ══════════════════════════════════════════════
  // RESTAURANTS
  // ══════════════════════════════════════════════
  
  static Future<void> saveRestaurants(String city, List<Map> restaurants) async {
    final box = Hive.box(restaurantsBox);
    await box.put('list_$city', restaurants);
    await box.put('timestamp_$city', DateTime.now().toIso8601String());
  }

  static List<Map>? getRestaurants(String city) {
    final box = Hive.box(restaurantsBox);
    return box.get('list_$city')?.cast<Map>();
  }

  static bool isRestaurantsCacheValid(String city, {int maxAgeMinutes = 5}) {
    final box = Hive.box(restaurantsBox);
    final timestamp = box.get('timestamp_$city');
    if (timestamp == null) return false;
    
    final cached = DateTime.parse(timestamp);
    return DateTime.now().difference(cached).inMinutes < maxAgeMinutes;
  }

  // ══════════════════════════════════════════════
  // MENU
  // ══════════════════════════════════════════════
  
  static Future<void> saveMenu(String restaurantId, Map menu) async {
    final box = Hive.box(menuBox);
    await box.put(restaurantId, menu);
    await box.put('ts_$restaurantId', DateTime.now().toIso8601String());
  }

  static Map? getMenu(String restaurantId) {
    final box = Hive.box(menuBox);
    return box.get(restaurantId);
  }
}
```

---

### 3.3 Repository Pattern (Cache + API)

```dart
// lib/features/restaurants/data/restaurant_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RestaurantRepository {
  final ApiClient api;
  
  RestaurantRepository(this.api);

  /// Stratégie: Cache d'abord, puis mise à jour en background
  Stream<List<Restaurant>> getRestaurants(String city) async* {
    // 1. Émettre le cache IMMÉDIATEMENT (UI instantanée)
    final cached = LocalDatabase.getRestaurants(city);
    if (cached != null && cached.isNotEmpty) {
      yield cached.map((e) => Restaurant.fromJson(e)).toList();
    }

    // 2. Si cache valide, pas besoin de fetch
    if (LocalDatabase.isRestaurantsCacheValid(city)) {
      return;
    }

    // 3. Fetch en background
    try {
      final response = await api.get('/restaurants', queryParams: {
        'city': city,
        'is_open': true,
        'limit': 50,
      });
      
      final restaurants = (response['data'] as List)
          .map((e) => Restaurant.fromJson(e))
          .toList();
      
      // 4. Sauvegarder en cache
      await LocalDatabase.saveRestaurants(
        city, 
        restaurants.map((e) => e.toJson()).toList(),
      );
      
      // 5. Émettre les données fraîches
      yield restaurants;
      
    } catch (e) {
      // Pas de réseau ? On a déjà émis le cache
      if (cached == null || cached.isEmpty) {
        throw Exception('Pas de connexion et pas de cache');
      }
    }
  }

  /// Pour un seul restaurant avec son menu
  Future<RestaurantDetail> getRestaurantDetail(String id) async {
    // Cache local
    final cachedMenu = LocalDatabase.getMenu(id);
    if (cachedMenu != null) {
      return RestaurantDetail.fromJson(cachedMenu);
    }

    // Sinon fetch
    final response = await api.get('/restaurants/$id/full');
    await LocalDatabase.saveMenu(id, response);
    return RestaurantDetail.fromJson(response);
  }
}

// Provider
final restaurantRepositoryProvider = Provider((ref) {
  return RestaurantRepository(ref.read(apiClientProvider));
});

final restaurantsProvider = StreamProvider.family<List<Restaurant>, String>(
  (ref, city) => ref.read(restaurantRepositoryProvider).getRestaurants(city),
);
```

---

### 3.4 Widgets Optimisés

#### Image avec Cache

```dart
// lib/shared/widgets/cached_image.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class AppCachedImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const AppCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder();
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: width,
        height: height,
        fit: fit,
        // ══════════════════════════════════════════════
        // SHIMMER PENDANT LE CHARGEMENT
        // ══════════════════════════════════════════════
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: width,
            height: height,
            color: Colors.white,
          ),
        ),
        // ══════════════════════════════════════════════
        // PLACEHOLDER SI ERREUR
        // ══════════════════════════════════════════════
        errorWidget: (context, url, error) => _buildPlaceholder(),
        // ══════════════════════════════════════════════
        // FADE IN ANIMATION
        // ══════════════════════════════════════════════
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Icon(Icons.restaurant, color: Colors.grey),
    );
  }
}
```

#### Shimmer Loading (Skeleton)

```dart
// lib/shared/widgets/shimmer_loading.dart
import 'package:shimmer/shimmer.dart';

class RestaurantCardShimmer extends StatelessWidget {
  const RestaurantCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Image placeholder
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Container(
                    height: 20,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Subtitle
                  Container(
                    height: 14,
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Rating
                  Container(
                    height: 14,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RestaurantListShimmer extends StatelessWidget {
  const RestaurantListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 6,  // Nombre de skeletons à afficher
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) => const RestaurantCardShimmer(),
    );
  }
}
```

#### Bouton avec Haptic + Optimistic Update

```dart
// lib/shared/widgets/buttons/haptic_button.dart
import 'package:flutter/services.dart';

class HapticButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;

  const HapticButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      child: ElevatedButton(
        onPressed: isLoading ? null : () {
          // Feedback haptique IMMÉDIAT
          HapticFeedback.lightImpact();
          onPressed?.call();
        },
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : child,
      ),
    );
  }
}
```

#### Bouton Ajouter au Panier (Optimistic)

```dart
// lib/features/cart/presentation/widgets/add_to_cart_button.dart
class AddToCartButton extends ConsumerWidget {
  final MenuItem item;

  const AddToCartButton({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(addToCartLoadingProvider(item.id));
    final cartCount = ref.watch(cartItemCountProvider(item.id));

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: cartCount > 0
          ? _QuantitySelector(item: item, count: cartCount)
          : HapticButton(
              isLoading: isLoading,
              onPressed: () => _addToCart(ref, context),
              child: const Text('Ajouter'),
            ),
    );
  }

  Future<void> _addToCart(WidgetRef ref, BuildContext context) async {
    // 1. Haptic feedback (déjà dans HapticButton)
    
    // 2. OPTIMISTIC UPDATE - UI change IMMÉDIATEMENT
    ref.read(cartProvider.notifier).addOptimistic(item);
    
    // 3. Sync avec serveur en background
    try {
      await ref.read(cartProvider.notifier).syncWithServer();
    } catch (e) {
      // 4. ROLLBACK si erreur
      ref.read(cartProvider.notifier).rollback(item);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur, veuillez réessayer'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _QuantitySelector extends ConsumerWidget {
  final MenuItem item;
  final int count;

  const _QuantitySelector({required this.item, required this.count});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            onPressed: () {
              HapticFeedback.selectionClick();
              ref.read(cartProvider.notifier).decrementOptimistic(item);
            },
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: child,
            ),
            child: Text(
              '$count',
              key: ValueKey(count),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: () {
              HapticFeedback.selectionClick();
              ref.read(cartProvider.notifier).addOptimistic(item);
            },
          ),
        ],
      ),
    );
  }
}
```

---

### 3.5 Cart Provider avec Optimistic Updates

```dart
// lib/features/cart/providers/cart_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CartState {
  final Map<String, CartItem> items;
  final bool isSyncing;
  final Map<String, CartItem> pendingChanges;  // Pour rollback

  const CartState({
    this.items = const {},
    this.isSyncing = false,
    this.pendingChanges = const {},
  });

  double get total => items.values.fold(
    0, 
    (sum, item) => sum + (item.price * item.quantity),
  );

  int get itemCount => items.values.fold(
    0, 
    (sum, item) => sum + item.quantity,
  );

  CartState copyWith({
    Map<String, CartItem>? items,
    bool? isSyncing,
    Map<String, CartItem>? pendingChanges,
  }) {
    return CartState(
      items: items ?? this.items,
      isSyncing: isSyncing ?? this.isSyncing,
      pendingChanges: pendingChanges ?? this.pendingChanges,
    );
  }
}

class CartNotifier extends StateNotifier<CartState> {
  final ApiClient api;
  
  CartNotifier(this.api) : super(const CartState());

  // ══════════════════════════════════════════════
  // OPTIMISTIC ADD - UI change immédiatement
  // ══════════════════════════════════════════════
  void addOptimistic(MenuItem item) {
    final currentItem = state.items[item.id];
    final newQuantity = (currentItem?.quantity ?? 0) + 1;
    
    // Sauvegarder l'état actuel pour rollback
    final previousItems = Map<String, CartItem>.from(state.items);
    
    state = state.copyWith(
      items: {
        ...state.items,
        item.id: CartItem(
          id: item.id,
          name: item.name,
          price: item.price,
          quantity: newQuantity,
          imageUrl: item.imageUrl,
        ),
      },
      pendingChanges: previousItems,
    );
  }

  void decrementOptimistic(MenuItem item) {
    final currentItem = state.items[item.id];
    if (currentItem == null) return;

    final previousItems = Map<String, CartItem>.from(state.items);
    
    if (currentItem.quantity <= 1) {
      // Supprimer l'item
      final newItems = Map<String, CartItem>.from(state.items);
      newItems.remove(item.id);
      state = state.copyWith(items: newItems, pendingChanges: previousItems);
    } else {
      state = state.copyWith(
        items: {
          ...state.items,
          item.id: currentItem.copyWith(quantity: currentItem.quantity - 1),
        },
        pendingChanges: previousItems,
      );
    }
  }

  // ══════════════════════════════════════════════
  // ROLLBACK si erreur serveur
  // ══════════════════════════════════════════════
  void rollback(MenuItem item) {
    if (state.pendingChanges.isNotEmpty) {
      state = state.copyWith(
        items: state.pendingChanges,
        pendingChanges: {},
      );
    }
  }

  // ══════════════════════════════════════════════
  // SYNC avec serveur (en background)
  // ══════════════════════════════════════════════
  Future<void> syncWithServer() async {
    state = state.copyWith(isSyncing: true);
    
    try {
      await api.post('/cart/sync', body: {
        'items': state.items.values.map((e) => e.toJson()).toList(),
      });
      
      // Clear pending changes après succès
      state = state.copyWith(pendingChanges: {}, isSyncing: false);
    } catch (e) {
      state = state.copyWith(isSyncing: false);
      rethrow;
    }
  }
}

// Providers
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier(ref.read(apiClientProvider));
});

final cartItemCountProvider = Provider.family<int, String>((ref, itemId) {
  return ref.watch(cartProvider).items[itemId]?.quantity ?? 0;
});

final addToCartLoadingProvider = StateProvider.family<bool, String>(
  (ref, itemId) => false,
);
```

---

### 3.6 Liste avec Performance Maximale

```dart
// lib/features/restaurants/presentation/restaurant_list_screen.dart
class RestaurantListScreen extends ConsumerWidget {
  const RestaurantListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final city = ref.watch(selectedCityProvider);
    final restaurantsAsync = ref.watch(restaurantsProvider(city));

    return Scaffold(
      body: restaurantsAsync.when(
        // ══════════════════════════════════════════════
        // LOADING - Afficher Shimmer (pas spinner)
        // ══════════════════════════════════════════════
        loading: () => const RestaurantListShimmer(),
        
        // ══════════════════════════════════════════════
        // ERROR - Avec bouton retry
        // ══════════════════════════════════════════════
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Pas de connexion'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(restaurantsProvider(city)),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        
        // ══════════════════════════════════════════════
        // DATA - Liste optimisée
        // ══════════════════════════════════════════════
        data: (restaurants) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(restaurantsProvider(city));
          },
          child: ListView.builder(
            // ⚡ PERFORMANCE: Lazy loading automatique
            itemCount: restaurants.length,
            
            // ⚡ PERFORMANCE: Cache les items hors écran
            cacheExtent: 500,
            
            // ⚡ PERFORMANCE: Taille fixe si possible
            itemExtent: 120,  // Si toutes les cards ont la même hauteur
            
            itemBuilder: (context, index) {
              final restaurant = restaurants[index];
              
              return RestaurantCard(
                key: ValueKey(restaurant.id),  // ⚡ Aide le diffing
                restaurant: restaurant,
              );
            },
          ),
        ),
      ),
    );
  }
}
```

#### Restaurant Card Optimisé

```dart
// lib/features/restaurants/presentation/widgets/restaurant_card.dart
class RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;

  const RestaurantCard({
    super.key,
    required this.restaurant,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        context.push('/restaurant/${restaurant.id}');
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // ══════════════════════════════════════════════
            // IMAGE HERO POUR TRANSITION FLUIDE
            // ══════════════════════════════════════════════
            Hero(
              tag: 'restaurant-${restaurant.id}',
              child: AppCachedImage(
                imageUrl: restaurant.logoUrl,
                width: 100,
                height: 100,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            
            const SizedBox(width: 12),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    restaurant.categories.join(' • '),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // ══════════════════════════════════════════════
                  // INFOS: Rating, Time, Distance
                  // ══════════════════════════════════════════════
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        restaurant.rating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.access_time, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('${restaurant.avgPrepTime} min'),
                    ],
                  ),
                ],
              ),
            ),
            
            // Indicateur ouvert/fermé
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: restaurant.isOpen ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                restaurant.isOpen ? 'Ouvert' : 'Fermé',
                style: TextStyle(
                  fontSize: 11,
                  color: restaurant.isOpen ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

### 3.7 Backend NestJS - Optimisations

#### Cache Redis

```typescript
// src/modules/cache/cache.service.ts
import { Injectable, Inject, CACHE_MANAGER } from '@nestjs/common';
import { Cache } from 'cache-manager';

@Injectable()
export class CacheService {
  constructor(@Inject(CACHE_MANAGER) private cacheManager: Cache) {}

  // ══════════════════════════════════════════════
  // RESTAURANTS PAR VILLE (Cache 5 minutes)
  // ══════════════════════════════════════════════
  async getRestaurantsByCity(city: string): Promise<any[]> {
    const cacheKey = `restaurants:${city}`;
    
    // Vérifier cache
    const cached = await this.cacheManager.get<any[]>(cacheKey);
    if (cached) return cached;
    
    return null;
  }

  async setRestaurantsByCity(city: string, data: any[]): Promise<void> {
    const cacheKey = `restaurants:${city}`;
    await this.cacheManager.set(cacheKey, data, 300); // 5 minutes
  }

  // ══════════════════════════════════════════════
  // MENU RESTAURANT (Cache 10 minutes)
  // ══════════════════════════════════════════════
  async getMenu(restaurantId: string): Promise<any> {
    const cacheKey = `menu:${restaurantId}`;
    return this.cacheManager.get(cacheKey);
  }

  async setMenu(restaurantId: string, data: any): Promise<void> {
    const cacheKey = `menu:${restaurantId}`;
    await this.cacheManager.set(cacheKey, data, 600); // 10 minutes
  }

  // ══════════════════════════════════════════════
  // INVALIDATION
  // ══════════════════════════════════════════════
  async invalidateRestaurants(city: string): Promise<void> {
    await this.cacheManager.del(`restaurants:${city}`);
  }

  async invalidateMenu(restaurantId: string): Promise<void> {
    await this.cacheManager.del(`menu:${restaurantId}`);
  }
}
```

#### Controller Optimisé

```typescript
// src/modules/restaurants/restaurants.controller.ts
import { Controller, Get, Param, Query, UseInterceptors } from '@nestjs/common';
import { CacheInterceptor, CacheTTL } from '@nestjs/cache-manager';

@Controller('restaurants')
export class RestaurantsController {
  constructor(
    private restaurantsService: RestaurantsService,
    private cacheService: CacheService,
  ) {}

  @Get()
  async findAll(
    @Query('city') city: string,
    @Query('page') page = 1,
    @Query('limit') limit = 20,
  ) {
    // Vérifier cache d'abord
    const cached = await this.cacheService.getRestaurantsByCity(city);
    if (cached) return cached;

    // Sinon, requête DB avec pagination
    const restaurants = await this.restaurantsService.findPaginated({
      city,
      page,
      limit,
      isActive: true,
    });

    // Mettre en cache
    await this.cacheService.setRestaurantsByCity(city, restaurants);

    return restaurants;
  }

  @Get(':id/menu')
  @UseInterceptors(CacheInterceptor)
  @CacheTTL(600)  // 10 minutes
  async getMenu(@Param('id') id: string) {
    return this.restaurantsService.getMenuWithItems(id);
  }
}
```

#### Service avec Requêtes Optimisées

```typescript
// src/modules/restaurants/restaurants.service.ts
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

@Injectable()
export class RestaurantsService {
  constructor(
    @InjectRepository(Restaurant)
    private restaurantsRepo: Repository<Restaurant>,
  ) {}

  async findPaginated(options: {
    city: string;
    page: number;
    limit: number;
    isActive: boolean;
  }) {
    const { city, page, limit, isActive } = options;

    // ══════════════════════════════════════════════
    // REQUÊTE OPTIMISÉE avec sélection des colonnes
    // ══════════════════════════════════════════════
    return this.restaurantsRepo
      .createQueryBuilder('r')
      .select([
        'r.id',
        'r.name',
        'r.slug',
        'r.logo_url',
        'r.rating',
        'r.avg_preparation_time',
        'r.is_open',
        'r.delivery_radius_km',
      ])
      .leftJoin('r.categories', 'c')
      .addSelect(['c.name'])
      .where('r.city = :city', { city })
      .andWhere('r.is_active = :isActive', { isActive })
      .orderBy('r.rating', 'DESC')
      .skip((page - 1) * limit)
      .take(limit)
      .getMany();
  }

  async getMenuWithItems(restaurantId: string) {
    // ══════════════════════════════════════════════
    // UNE SEULE REQUÊTE avec toutes les relations
    // ══════════════════════════════════════════════
    return this.restaurantsRepo.findOne({
      where: { id: restaurantId },
      relations: [
        'menuCategories',
        'menuCategories.items',
        'menuCategories.items.options',
      ],
      select: {
        id: true,
        name: true,
        menuCategories: {
          id: true,
          name: true,
          displayOrder: true,
          items: {
            id: true,
            name: true,
            description: true,
            price: true,
            imageUrl: true,
            isAvailable: true,
          },
        },
      },
    });
  }
}
```

---

### 3.8 Checklist Performance

| Composant | Optimisation | Impact |
|-----------|--------------|--------|
| **Flutter - Widgets** | `const` partout | ⚡⚡⚡ |
| **Flutter - Lists** | `ListView.builder` | ⚡⚡⚡ |
| **Flutter - Images** | `CachedNetworkImage` | ⚡⚡⚡ |
| **Flutter - State** | Riverpod (rebuild ciblé) | ⚡⚡⚡ |
| **Flutter - UX** | Shimmer au lieu de spinner | ⚡⚡ |
| **Flutter - UX** | Haptic feedback | ⚡ |
| **Flutter - UX** | Optimistic updates | ⚡⚡⚡ |
| **Flutter - UX** | Hero animations | ⚡⚡ |
| **Flutter - Offline** | Hive cache local | ⚡⚡⚡ |
| **Backend - API** | Pagination | ⚡⚡⚡ |
| **Backend - API** | Redis cache | ⚡⚡⚡ |
| **Backend - DB** | Index SQL | ⚡⚡⚡ |
| **Backend - DB** | Relations eager loading | ⚡⚡⚡ |
| **Backend - DB** | Select colonnes spécifiques | ⚡⚡ |

---

## 4. Flux API Principaux

### Création de commande

```
POST /api/orders

Request:
{
  "restaurant_id": "uuid",
  "delivery_address_id": "uuid",
  "items": [
    {
      "menu_item_id": "uuid",
      "quantity": 2,
      "options": [
        { "option_id": "uuid", "choice_id": "uuid" }
      ],
      "special_instructions": "Bien cuit"
    }
  ],
  "customer_notes": "Sonnez 2 fois"
}

Response:
{
  "id": "uuid",
  "order_number": "DZ-20250112-001",
  "status": "pending",
  "subtotal": 1500,
  "delivery_fee": 200,
  "total_amount": 1700,
  "confirmation_code": "4829",
  "estimated_delivery_time": 45
}
```

### Broadcast aux livreurs (WebSocket)

```javascript
// Backend émet aux livreurs dans le rayon
socket.to(`zone:${restaurant.city}`).emit('new_order', {
  order_id: order.id,
  restaurant: {
    name: restaurant.name,
    address: restaurant.address,
    latitude: restaurant.latitude,
    longitude: restaurant.longitude
  },
  delivery: {
    address: deliveryAddress.address_line,
    distance_km: calculatedDistance,
  },
  delivery_fee: 200,
  expires_in: 60  // Secondes pour accepter
});
```

### Livreur accepte

```
POST /api/orders/:id/accept

Response:
{
  "success": true,
  "order": { ... },
  "customer_phone": "+213XXXXXXXX",
  "restaurant_phone": "+213XXXXXXXX"
}
```

---

## 5. Dashboard Admin (Next.js)

### Pages principales

```
/admin
├── /dashboard          # Vue d'ensemble
├── /orders             # Toutes les commandes
├── /restaurants        # Gestion restaurants
│   ├── /new           # Ajouter restaurant
│   └── /:id           # Détails restaurant
├── /livreurs          # Gestion livreurs
│   └── /pending       # En attente de validation
├── /users             # Clients
├── /invoices          # Factures
│   └── /generate      # Générer factures hebdo
├── /stats             # Statistiques
└── /settings          # Paramètres plateforme
```

### KPIs Dashboard

```
┌─────────────────────────────────────────────────────────────┐
│                    TABLEAU DE BORD                          │
├─────────────┬─────────────┬─────────────┬─────────────────┤
│ Commandes   │ CA du jour  │ Commission  │ Livreurs actifs │
│ aujourd'hui │             │ du jour     │                 │
│    127      │  189,500 DA │  18,950 DA  │      23         │
└─────────────┴─────────────┴─────────────┴─────────────────┘

┌──────────────────────┐  ┌──────────────────────────────────┐
│ Commandes en cours   │  │ Graphique CA (7 derniers jours)  │
│ ▪ En attente: 5      │  │ ████████████████████████████     │
│ ▪ En prépa: 12       │  │                                  │
│ ▪ En livraison: 8    │  │                                  │
└──────────────────────┘  └──────────────────────────────────┘
```

---

## 6. Calculs Importants

### Frais de livraison dynamiques

```typescript
function calculateDeliveryFee(distanceKm: number): number {
  const BASE_FEE = 100;  // DA
  const PER_KM_RATE = 30; // DA par km
  const MIN_FEE = 150;
  const MAX_FEE = 500;

  let fee = BASE_FEE + (distanceKm * PER_KM_RATE);
  
  return Math.min(Math.max(fee, MIN_FEE), MAX_FEE);
}
```

### Distance entre deux points GPS

```typescript
function calculateDistance(
  lat1: number, lon1: number,
  lat2: number, lon2: number
): number {
  const R = 6371; // Rayon Terre en km
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  
  const a = 
    Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * 
    Math.sin(dLon/2) * Math.sin(dLon/2);
  
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  
  return R * c;
}
```

### Génération facture hebdomadaire

```typescript
async function generateWeeklyInvoice(restaurantId: string) {
  const startDate = getLastMonday();
  const endDate = getLastSunday();
  
  const orders = await this.ordersRepo.find({
    where: {
      restaurant_id: restaurantId,
      status: 'delivered',
      delivered_at: Between(startDate, endDate)
    }
  });
  
  const totalSales = orders.reduce((sum, o) => sum + o.subtotal, 0);
  const commissionRate = restaurant.commission_rate;
  const commissionAmount = totalSales * (commissionRate / 100);
  
  return {
    invoice_number: generateInvoiceNumber(),
    restaurant_id: restaurantId,
    period_start: startDate,
    period_end: endDate,
    total_orders: orders.length,
    total_sales: totalSales,
    commission_rate: commissionRate,
    commission_amount: commissionAmount,
    due_date: addDays(new Date(), 7)
  };
}
```

---

## 7. Sécurité

### Points critiques

1. **Authentification JWT** avec refresh tokens
2. **Rate limiting** sur les endpoints sensibles
3. **Validation** de toutes les entrées (class-validator)
4. **Vérification** que le livreur est dans le rayon avant acceptation
5. **Code de confirmation** à 4 chiffres pour valider la livraison
6. **Logs** de toutes les actions critiques

### Exemple middleware de vérification

```typescript
@Injectable()
export class OrderOwnershipGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const user = request.user;
    const orderId = request.params.id;
    
    // Vérifier que l'utilisateur a le droit d'accéder à cette commande
    return this.ordersService.belongsTo(orderId, user.id, user.role);
  }
}
```

---

## 8. Prochaines Étapes

1. [ ] Créer le projet NestJS avec la structure
2. [ ] Configurer Supabase/PostgreSQL avec les index
3. [ ] Configurer Redis pour le cache
4. [ ] Implémenter les entités TypeORM
5. [ ] Créer les modules Auth, Users, Restaurants
6. [ ] Implémenter le flux de commande
7. [ ] Ajouter WebSockets pour le temps réel
8. [ ] Créer les 3 apps Flutter avec architecture offline-first
9. [ ] Implémenter Shimmer + Optimistic updates
10. [ ] Dashboard admin Next.js
11. [ ] Tests de performance
12. [ ] Déploiement
