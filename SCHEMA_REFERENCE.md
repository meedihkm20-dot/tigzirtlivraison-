# 🗄️ SCHÉMA DE RÉFÉRENCE - SINGLE SOURCE OF TRUTH

## ⚠️ RÈGLE ABSOLUE

**Le schéma SQL Supabase est la SOURCE DE VÉRITÉ UNIQUE.**

```
┌─────────────────────────────────────────────────────────────┐
│                    FLUX DE DONNÉES                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   ┌─────────────┐                                           │
│   │   SQL       │  ← SOURCE DE VÉRITÉ                       │
│   │  Supabase   │                                           │
│   └──────┬──────┘                                           │
│          │                                                  │
│          ▼                                                  │
│   ┌─────────────┐     ┌─────────────┐                       │
│   │  Backend    │     │  Flutter    │                       │
│   │  NestJS     │     │  (lecture)  │                       │
│   │ (écriture)  │     │             │                       │
│   └──────┬──────┘     └──────┬──────┘                       │
│          │                   │                              │
│          ▼                   ▼                              │
│   ┌─────────────────────────────────────┐                   │
│   │         BASE DE DONNÉES             │                   │
│   │           Supabase                  │                   │
│   └─────────────────────────────────────┘                   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 📁 Fichiers de Référence

| Couche | Fichier | Rôle |
|--------|---------|------|
| **SQL** | `supabase/SOURCE_DE_VERITE.sql` | **SOURCE DE VÉRITÉ UNIQUE** |
| **SQL** | `supabase/migrations/000_complete_schema.sql` | Migration complète |
| **SQL** | `supabase/migrations/102_unified_schema_fix.sql` | Corrections sync |
| **Backend** | `backend/src/types/database.types.ts` | Types TypeScript |
| **Flutter** | `apps/dz_delivery/lib/core/models/database_models.dart` | Modèles Dart |

---

## 📊 LISTE COMPLÈTE DES TABLES (24 tables)

### Tables Principales (8)
| Table | Backend | Flutter | Description |
|-------|---------|---------|-------------|
| `profiles` | ✅ | ✅ | Utilisateurs (tous rôles) |
| `restaurants` | ✅ | ✅ | Restaurants |
| `menu_categories` | ✅ | ✅ | Catégories de menu |
| `menu_items` | ✅ | ✅ | Plats |
| `livreurs` | ✅ | ✅ | Livreurs |
| `orders` | ✅ | ✅ | Commandes |
| `order_items` | ✅ | ✅ | Items de commande |
| `reviews` | ✅ | ✅ | Avis |

### Tables Support (5)
| Table | Backend | Flutter | Description |
|-------|---------|---------|-------------|
| `transactions` | ✅ | ✅ | Transactions financières |
| `notifications` | ✅ | ✅ | Notifications |
| `commission_settings` | ✅ | ❌ | Paramètres commissions |
| `delivery_pricing` | ✅ | ✅ | Tarification livraison |
| `delivery_zones` | ✅ | ❌ | Zones de livraison |

### Tables Flutter-Only (6)
| Table | Backend | Flutter | Description |
|-------|---------|---------|-------------|
| `order_messages` | ✅ | ✅ | Chat commande |
| `livreur_locations` | ✅ | ✅ | Tracking GPS |
| `saved_addresses` | ✅ | ✅ | Adresses sauvegardées |
| `favorites` | ✅ | ✅ | Restaurants favoris |
| `favorite_items` | ✅ | ✅ | Plats favoris |
| `promotions` | ✅ | ✅ | Promotions |

### Tables Gamification (5)
| Table | Backend | Flutter | Description |
|-------|---------|---------|-------------|
| `livreur_badges` | ✅ | ✅ | Badges livreur |
| `livreur_bonuses` | ✅ | ✅ | Bonus livreur |
| `tier_config` | ✅ | ❌ | Configuration tiers |
| `livreur_targets` | ❌ | ❌ | Objectifs livreur |
| `referrals` | ✅ | ❌ | Parrainages |

---

## 🚨 COLONNES CRITIQUES - NE PAS RENOMMER

### Table `orders`

| ✅ Nom SQL Correct | ❌ Noms Incorrects | Où corriger |
|-------------------|-------------------|-------------|
| `livreur_id` | `driver_id` | Backend |
| `total` | `total_amount` | Backend |
| `delivery_latitude` | `delivery_lat` | Backend DTO |
| `delivery_longitude` | `delivery_lng` | Backend DTO |
| `prepared_at` | `preparing_at` | Backend |
| `delivery_instructions` | `notes` | Backend |

### Enum `order_status`

```sql
-- VALEURS AUTORISÉES (8 valeurs)
'pending', 'confirmed', 'preparing', 'ready', 
'picked_up', 'delivering', 'delivered', 'cancelled'

-- ❌ VALEURS INTERDITES
'driver_assigned', 'accepted', 'in_progress'
```

---

## 📋 Workflow de Modification

```
1. MODIFIER LE SQL
   └── supabase/migrations/XXX_nom_migration.sql

2. METTRE À JOUR LES TYPES BACKEND
   └── backend/src/types/database.types.ts

3. METTRE À JOUR LES MODÈLES FLUTTER
   └── apps/dz_delivery/lib/core/models/database_models.dart

4. TESTER
   └── Vérifier que tout compile et fonctionne
```

---

## 🔒 Règles d'Architecture

### Backend (NestJS)
- ✅ Valide les données
- ✅ Applique les règles métier
- ✅ Gère les écritures (INSERT/UPDATE/DELETE)
- ❌ Ne définit PAS de modèles différents du SQL
- ❌ N'invente PAS de noms de colonnes

### Frontend (Flutter)
- ✅ Lit directement depuis Supabase (SELECT, realtime)
- ✅ Utilise les modèles alignés sur le SQL
- ❌ N'écrit JAMAIS directement dans la base
- ❌ Pas de logique métier critique

---

## 📊 Tables Principales

### profiles
```sql
id UUID PRIMARY KEY REFERENCES auth.users(id)
role user_role ('customer', 'restaurant', 'livreur', 'admin')
phone VARCHAR(20)
full_name VARCHAR(100)
avatar_url TEXT
address TEXT
latitude DECIMAL(10, 8)
longitude DECIMAL(11, 8)
is_active BOOLEAN DEFAULT true
fcm_token TEXT
loyalty_points INTEGER DEFAULT 0
total_orders INTEGER DEFAULT 0
total_spent DECIMAL(12,2) DEFAULT 0
referral_code VARCHAR(10)
referred_by UUID
referral_earnings DECIMAL(10,2) DEFAULT 0
phone_verified BOOLEAN DEFAULT false
email_verified BOOLEAN DEFAULT false
created_at TIMESTAMPTZ
updated_at TIMESTAMPTZ
```

### restaurants
```sql
id UUID PRIMARY KEY
owner_id UUID REFERENCES profiles(id)
name VARCHAR(100) NOT NULL
description TEXT
logo_url TEXT
cover_url TEXT
phone VARCHAR(20)
address TEXT NOT NULL
latitude DECIMAL(10, 8) NOT NULL
longitude DECIMAL(11, 8) NOT NULL
cuisine_type VARCHAR(50)
opening_time TIME DEFAULT '08:00'
closing_time TIME DEFAULT '23:00'
min_order_amount DECIMAL(10, 2) DEFAULT 0
delivery_fee DECIMAL(10, 2) DEFAULT 0
avg_prep_time INTEGER DEFAULT 30
rating DECIMAL(2, 1) DEFAULT 0
total_reviews INTEGER DEFAULT 0
is_open BOOLEAN DEFAULT true
is_verified BOOLEAN DEFAULT false
cover_images TEXT[]
tags TEXT[]
accepts_preorders BOOLEAN DEFAULT false
fcm_token TEXT
created_at TIMESTAMPTZ
updated_at TIMESTAMPTZ
```

### livreurs
```sql
id UUID PRIMARY KEY
user_id UUID UNIQUE REFERENCES profiles(id)
vehicle_type vehicle_type ('moto', 'velo', 'voiture') DEFAULT 'moto'
vehicle_number VARCHAR(20)
license_number VARCHAR(50)
current_latitude DECIMAL(10, 8)
current_longitude DECIMAL(11, 8)
is_available BOOLEAN DEFAULT false
is_online BOOLEAN DEFAULT false
is_verified BOOLEAN DEFAULT false
rating DECIMAL(2, 1) DEFAULT 5.0
total_deliveries INTEGER DEFAULT 0
total_earnings DECIMAL(12, 2) DEFAULT 0
total_distance_km DECIMAL(10, 2) DEFAULT 0
avg_delivery_time INTEGER
acceptance_rate DECIMAL(5, 2) DEFAULT 100
tier livreur_tier ('bronze', 'silver', 'gold', 'diamond') DEFAULT 'bronze'
tier_progress INTEGER DEFAULT 0
weekly_deliveries INTEGER DEFAULT 0
monthly_deliveries INTEGER DEFAULT 0
cancellation_rate DECIMAL(5,2) DEFAULT 0
streak_days INTEGER DEFAULT 0
last_active_date DATE
bonus_earned DECIMAL(10,2) DEFAULT 0
fcm_token TEXT
created_at TIMESTAMPTZ
updated_at TIMESTAMPTZ
```

### orders ⚠️ TABLE CRITIQUE
```sql
id UUID PRIMARY KEY
order_number VARCHAR(20) UNIQUE NOT NULL
customer_id UUID REFERENCES profiles(id)
restaurant_id UUID REFERENCES restaurants(id)
livreur_id UUID REFERENCES livreurs(id)  -- ⚠️ PAS "driver_id"
status order_status DEFAULT 'pending'

-- Adresse de livraison
delivery_address TEXT NOT NULL
delivery_latitude DECIMAL(10, 8) NOT NULL  -- ⚠️ PAS "delivery_lat"
delivery_longitude DECIMAL(11, 8) NOT NULL  -- ⚠️ PAS "delivery_lng"
delivery_instructions TEXT

-- Montants
subtotal DECIMAL(10, 2) NOT NULL
delivery_fee DECIMAL(10, 2) DEFAULT 0
service_fee DECIMAL(10, 2) DEFAULT 0
discount DECIMAL(10, 2) DEFAULT 0
total DECIMAL(10, 2) NOT NULL  -- ⚠️ PAS "total_amount"

-- Paiement
payment_method payment_method DEFAULT 'cash'
payment_status payment_status DEFAULT 'pending'

-- Timestamps
estimated_delivery_time TIMESTAMPTZ
confirmed_at TIMESTAMPTZ
prepared_at TIMESTAMPTZ  -- ⚠️ PAS "preparing_at"
picked_up_at TIMESTAMPTZ
delivered_at TIMESTAMPTZ
cancelled_at TIMESTAMPTZ
cancellation_reason TEXT

-- Colonnes additionnelles
confirmation_code VARCHAR(4)
livreur_commission DECIMAL(10, 2) DEFAULT 0
admin_commission DECIMAL(10, 2) DEFAULT 0
restaurant_amount DECIMAL(10, 2) DEFAULT 0
livreur_accepted_at TIMESTAMPTZ
code_verified_at TIMESTAMPTZ
promotion_id UUID
promo_code VARCHAR(20)
promo_discount DECIMAL(10, 2) DEFAULT 0
current_eta_minutes INTEGER
distance_remaining_km DECIMAL(10,2)
tip_amount DECIMAL(10,2) DEFAULT 0
tip_paid_at TIMESTAMPTZ

created_at TIMESTAMPTZ
updated_at TIMESTAMPTZ
```

### order_items
```sql
id UUID PRIMARY KEY
order_id UUID REFERENCES orders(id) ON DELETE CASCADE
menu_item_id UUID REFERENCES menu_items(id)
name VARCHAR(100) NOT NULL
price DECIMAL(10, 2) NOT NULL
quantity INTEGER NOT NULL DEFAULT 1
special_instructions TEXT
created_at TIMESTAMPTZ
```

### menu_items
```sql
id UUID PRIMARY KEY
restaurant_id UUID REFERENCES restaurants(id) ON DELETE CASCADE
category_id UUID REFERENCES menu_categories(id)
name VARCHAR(100) NOT NULL
description TEXT
price DECIMAL(10, 2) NOT NULL
image_url TEXT
is_available BOOLEAN DEFAULT true
is_popular BOOLEAN DEFAULT false
prep_time INTEGER DEFAULT 15
calories INTEGER
is_vegetarian BOOLEAN DEFAULT false
is_spicy BOOLEAN DEFAULT false
allergens TEXT[]
order_count INTEGER DEFAULT 0
image_width INTEGER DEFAULT 500
image_height INTEGER DEFAULT 500
ingredients TEXT[]
nutrition_info JSONB
is_daily_special BOOLEAN DEFAULT false
daily_special_price DECIMAL(10,2)
avg_rating DECIMAL(3,2) DEFAULT 0
total_reviews INTEGER DEFAULT 0
last_ordered_at TIMESTAMPTZ
tags TEXT[]
created_at TIMESTAMPTZ
updated_at TIMESTAMPTZ
```

### transactions
```sql
id UUID PRIMARY KEY
order_id UUID REFERENCES orders(id) ON DELETE CASCADE
type VARCHAR(20) NOT NULL  -- 'livreur_earning', 'admin_commission', 'restaurant_payment'
amount DECIMAL(10, 2) NOT NULL
recipient_id UUID
status VARCHAR(20) DEFAULT 'pending'  -- 'pending', 'completed', 'cancelled'
description TEXT
created_at TIMESTAMPTZ
```

### commission_settings
```sql
id UUID PRIMARY KEY
livreur_commission_percent DECIMAL(5, 2) DEFAULT 15.00
admin_commission_percent DECIMAL(5, 2) DEFAULT 5.00
min_delivery_fee DECIMAL(10, 2) DEFAULT 100.00
updated_at TIMESTAMPTZ
```

---

## ✅ Checklist Avant Commit

- [ ] Les noms de colonnes correspondent au SQL
- [ ] Les enums utilisent les valeurs SQL exactes
- [ ] Pas de `driver_id` (utiliser `livreur_id`)
- [ ] Pas de `total_amount` (utiliser `total`)
- [ ] Pas de `delivery_lat/lng` (utiliser `delivery_latitude/longitude`)
- [ ] Pas de `preparing_at` (utiliser `prepared_at`)
- [ ] Pas de status inventés (`driver_assigned`, etc.)

---

## 🔄 Corrections Appliquées

### Backend (2025-01-16)
1. ✅ `orders.service.ts`: `total_amount` → `total`
2. ✅ `orders.service.ts`: `delivery_lat/lng` → `delivery_latitude/longitude`
3. ✅ `orders.service.ts`: `preparing_at` → supprimé (pas de colonne SQL)
4. ✅ `orders.service.ts`: `driver_id` → `livreur_id`
5. ✅ `delivery.service.ts`: `driver_id` → `livreur_id`
6. ✅ `delivery.service.ts`: `driver_assigned` → `confirmed`

### Fichiers créés
1. ✅ `backend/src/types/database.types.ts` - Types TypeScript alignés SQL
2. ✅ `apps/dz_delivery/lib/core/models/database_models.dart` - Modèles Dart alignés SQL
