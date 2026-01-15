-- ============================================================
-- DZ DELIVERY - SCHÉMA FINAL COMPLET
-- ============================================================
-- 
-- ARCHITECTURE:
-- ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
-- │  Flutter App    │────▶│  NestJS Backend │────▶│    Supabase     │
-- │  (Mobile)       │     │  (Koyeb)        │     │  (Database)     │
-- └─────────────────┘     └─────────────────┘     └─────────────────┘
--                                │
--                                ▼
--                         ┌─────────────────┐
--                         │   OneSignal     │
--                         │  (Notifications)│
--                         └─────────────────┘
--
-- RESPONSABILITÉS:
-- ═══════════════════════════════════════════════════════════════
-- SUPABASE:
--   ✅ Auth (login, register, logout)
--   ✅ Database (stockage des données)
--   ✅ Realtime (écoute des changements)
--   ✅ Storage (images)
--   ✅ RLS (sécurité lecture)
--   ✅ Triggers (updated_at, order_number, commissions)
--   ✅ Fonctions utilitaires (get_nearby_restaurants, etc.)
--
-- BACKEND (NestJS):
--   ✅ Création de commande (validation, calcul prix)
--   ✅ Changement de statut (transitions validées)
--   ✅ Annulation de commande (règles métier)
--   ✅ Vérification code livraison
--   ✅ Notifications OneSignal
--   ✅ Logique métier complexe
-- ═══════════════════════════════════════════════════════════════
--
-- Date: 16 janvier 2026
-- Version: 3.0 (Production Ready)
-- ============================================================

-- ============================================
-- PARTIE 1: NETTOYAGE COMPLET
-- ============================================

-- Désactiver temporairement les contraintes
SET session_replication_role = 'replica';

-- Supprimer toutes les tables existantes
DROP TABLE IF EXISTS public.reorder_suggestions CASCADE;
DROP TABLE IF EXISTS public.referrals CASCADE;
DROP TABLE IF EXISTS public.order_messages CASCADE;
DROP TABLE IF EXISTS public.search_history CASCADE;
DROP TABLE IF EXISTS public.saved_addresses CASCADE;
DROP TABLE IF EXISTS public.menu_item_reviews CASCADE;
DROP TABLE IF EXISTS public.livreur_bonuses CASCADE;
DROP TABLE IF EXISTS public.livreur_badges CASCADE;
DROP TABLE IF EXISTS public.livreur_targets CASCADE;
DROP TABLE IF EXISTS public.tier_config CASCADE;
DROP TABLE IF EXISTS public.delivery_zones CASCADE;
DROP TABLE IF EXISTS public.delivery_pricing CASCADE;
DROP TABLE IF EXISTS public.menu_item_extras CASCADE;
DROP TABLE IF EXISTS public.menu_item_variants CASCADE;
DROP TABLE IF EXISTS public.favorite_items CASCADE;
DROP TABLE IF EXISTS public.favorites CASCADE;
DROP TABLE IF EXISTS public.promotions CASCADE;
DROP TABLE IF EXISTS public.transactions CASCADE;
DROP TABLE IF EXISTS public.fcm_tokens CASCADE;
DROP TABLE IF EXISTS public.notifications CASCADE;
DROP TABLE IF EXISTS public.livreur_locations CASCADE;
DROP TABLE IF EXISTS public.reviews CASCADE;
DROP TABLE IF EXISTS public.order_items CASCADE;
DROP TABLE IF EXISTS public.orders CASCADE;
DROP TABLE IF EXISTS public.livreurs CASCADE;
DROP TABLE IF EXISTS public.menu_items CASCADE;
DROP TABLE IF EXISTS public.menu_categories CASCADE;
DROP TABLE IF EXISTS public.restaurants CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;
DROP TABLE IF EXISTS public.commission_settings CASCADE;

-- Supprimer les types enum
DROP TYPE IF EXISTS livreur_tier CASCADE;
DROP TYPE IF EXISTS vehicle_type CASCADE;
DROP TYPE IF EXISTS payment_status CASCADE;
DROP TYPE IF EXISTS payment_method CASCADE;
DROP TYPE IF EXISTS order_status CASCADE;
DROP TYPE IF EXISTS user_role CASCADE;

-- Supprimer toutes les fonctions
DROP FUNCTION IF EXISTS update_updated_at() CASCADE;
DROP FUNCTION IF EXISTS handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS generate_order_number() CASCADE;
DROP FUNCTION IF EXISTS generate_confirmation_code() CASCADE;
DROP FUNCTION IF EXISTS calculate_commissions() CASCADE;
DROP FUNCTION IF EXISTS update_restaurant_rating() CASCADE;
DROP FUNCTION IF EXISTS update_livreur_rating() CASCADE;
DROP FUNCTION IF EXISTS create_delivery_transactions() CASCADE;
DROP FUNCTION IF EXISTS after_delivery_complete() CASCADE;
DROP FUNCTION IF EXISTS update_livreur_tier() CASCADE;
DROP FUNCTION IF EXISTS generate_referral_code() CASCADE;
DROP FUNCTION IF EXISTS get_nearby_restaurants(DECIMAL, DECIMAL, DECIMAL) CASCADE;
DROP FUNCTION IF EXISTS get_available_livreurs(DECIMAL, DECIMAL, DECIMAL) CASCADE;
DROP FUNCTION IF EXISTS get_restaurant_stats(UUID) CASCADE;
DROP FUNCTION IF EXISTS get_admin_stats() CASCADE;
DROP FUNCTION IF EXISTS calculate_delivery_fee(DECIMAL, DECIMAL, DECIMAL, DECIMAL) CASCADE;
DROP FUNCTION IF EXISTS verify_confirmation_code(UUID, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS apply_promotion(UUID, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS submit_review(UUID, INTEGER, INTEGER, TEXT) CASCADE;
DROP FUNCTION IF EXISTS calculate_livreur_commission(UUID, DECIMAL) CASCADE;
DROP FUNCTION IF EXISTS check_livreur_daily_bonus(UUID) CASCADE;
DROP FUNCTION IF EXISTS check_livreur_badges(UUID) CASCADE;
DROP FUNCTION IF EXISTS add_tip(UUID, DECIMAL) CASCADE;
DROP FUNCTION IF EXISTS apply_referral_code(VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS reward_referrer_on_first_order() CASCADE;
DROP FUNCTION IF EXISTS update_reorder_suggestions() CASCADE;
DROP FUNCTION IF EXISTS get_top_restaurants(INTEGER) CASCADE;
DROP FUNCTION IF EXISTS get_top_menu_items(UUID, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS increment_menu_item_orders() CASCADE;
DROP FUNCTION IF EXISTS reset_weekly_stats() CASCADE;
DROP FUNCTION IF EXISTS reset_monthly_stats() CASCADE;

-- Réactiver les contraintes
SET session_replication_role = 'origin';

-- ============================================
-- PARTIE 2: EXTENSIONS
-- ============================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- PARTIE 3: TYPES ENUM
-- ============================================
CREATE TYPE user_role AS ENUM ('customer', 'restaurant', 'livreur', 'admin');
CREATE TYPE order_status AS ENUM ('pending', 'confirmed', 'preparing', 'ready', 'picked_up', 'delivering', 'delivered', 'cancelled');
CREATE TYPE payment_method AS ENUM ('cash', 'card', 'edahabia', 'cib');
CREATE TYPE payment_status AS ENUM ('pending', 'paid', 'failed', 'refunded');
CREATE TYPE vehicle_type AS ENUM ('moto', 'velo', 'voiture');
CREATE TYPE livreur_tier AS ENUM ('bronze', 'silver', 'gold', 'diamond');

-- ============================================
-- PARTIE 4: TABLES PRINCIPALES
-- ============================================

-- ─────────────────────────────────────────────
-- PROFILES (Utilisateurs)
-- Créé automatiquement à l'inscription via trigger
-- ─────────────────────────────────────────────
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    role user_role NOT NULL DEFAULT 'customer',
    full_name VARCHAR(100),
    phone VARCHAR(20),
    avatar_url TEXT,
    address TEXT,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    is_active BOOLEAN DEFAULT true,
    -- OneSignal pour notifications push
    onesignal_player_id TEXT,
    -- Fidélité
    loyalty_points INTEGER DEFAULT 0,
    total_orders INTEGER DEFAULT 0,
    total_spent DECIMAL(12,2) DEFAULT 0,
    -- Parrainage
    referral_code VARCHAR(10),
    referred_by UUID REFERENCES public.profiles(id),
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.profiles IS 'Profils utilisateurs - créés automatiquement à l''inscription';
COMMENT ON COLUMN public.profiles.onesignal_player_id IS 'ID OneSignal pour les notifications push';

-- ─────────────────────────────────────────────
-- RESTAURANTS
-- ─────────────────────────────────────────────
CREATE TABLE public.restaurants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    logo_url TEXT,
    cover_url TEXT,
    phone VARCHAR(20),
    address TEXT NOT NULL,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    cuisine_type VARCHAR(50),
    tags TEXT[],
    opening_time TIME DEFAULT '08:00',
    closing_time TIME DEFAULT '23:00',
    min_order_amount DECIMAL(10, 2) DEFAULT 0,
    delivery_fee DECIMAL(10, 2) DEFAULT 0,
    avg_prep_time INTEGER DEFAULT 30,
    rating DECIMAL(2, 1) DEFAULT 0,
    total_reviews INTEGER DEFAULT 0,
    is_open BOOLEAN DEFAULT true,
    is_verified BOOLEAN DEFAULT false,
    -- OneSignal
    onesignal_player_id TEXT,
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.restaurants IS 'Restaurants partenaires';

-- ─────────────────────────────────────────────
-- MENU_CATEGORIES
-- ─────────────────────────────────────────────
CREATE TABLE public.menu_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    restaurant_id UUID NOT NULL REFERENCES public.restaurants(id) ON DELETE CASCADE,
    name VARCHAR(50) NOT NULL,
    description TEXT,
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─────────────────────────────────────────────
-- MENU_ITEMS
-- ─────────────────────────────────────────────
CREATE TABLE public.menu_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    restaurant_id UUID NOT NULL REFERENCES public.restaurants(id) ON DELETE CASCADE,
    category_id UUID REFERENCES public.menu_categories(id) ON DELETE SET NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    image_url TEXT,
    is_available BOOLEAN DEFAULT true,
    is_popular BOOLEAN DEFAULT false,
    prep_time INTEGER DEFAULT 15,
    order_count INTEGER DEFAULT 0,
    avg_rating DECIMAL(3,2) DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─────────────────────────────────────────────
-- LIVREURS
-- ─────────────────────────────────────────────
CREATE TABLE public.livreurs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    vehicle_type vehicle_type DEFAULT 'moto',
    vehicle_number VARCHAR(20),
    -- Position temps réel
    current_latitude DECIMAL(10, 8),
    current_longitude DECIMAL(11, 8),
    -- Statut
    is_available BOOLEAN DEFAULT false,
    is_online BOOLEAN DEFAULT false,
    is_verified BOOLEAN DEFAULT false,
    -- Stats
    rating DECIMAL(2, 1) DEFAULT 5.0,
    total_deliveries INTEGER DEFAULT 0,
    total_earnings DECIMAL(12, 2) DEFAULT 0,
    -- Gamification
    tier livreur_tier DEFAULT 'bronze',
    weekly_deliveries INTEGER DEFAULT 0,
    monthly_deliveries INTEGER DEFAULT 0,
    -- OneSignal
    onesignal_player_id TEXT,
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.livreurs IS 'Livreurs - position mise à jour en temps réel';

-- ─────────────────────────────────────────────
-- ORDERS (Commandes)
-- ⚠️ INSERT/UPDATE via Backend uniquement
-- ─────────────────────────────────────────────
CREATE TABLE public.orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_number VARCHAR(20) UNIQUE NOT NULL,
    -- Relations
    customer_id UUID NOT NULL REFERENCES public.profiles(id),
    restaurant_id UUID NOT NULL REFERENCES public.restaurants(id),
    livreur_id UUID REFERENCES public.livreurs(id),
    -- Statut (modifié par le backend)
    status order_status DEFAULT 'pending',
    -- Livraison
    delivery_address TEXT NOT NULL,
    delivery_latitude DECIMAL(10, 8) NOT NULL,
    delivery_longitude DECIMAL(11, 8) NOT NULL,
    delivery_instructions TEXT,
    -- Montants
    subtotal DECIMAL(10, 2) NOT NULL,
    delivery_fee DECIMAL(10, 2) DEFAULT 0,
    service_fee DECIMAL(10, 2) DEFAULT 0,
    discount DECIMAL(10, 2) DEFAULT 0,
    total DECIMAL(10, 2) NOT NULL,
    tip_amount DECIMAL(10,2) DEFAULT 0,
    -- Paiement
    payment_method payment_method DEFAULT 'cash',
    payment_status payment_status DEFAULT 'pending',
    -- Code de confirmation (4 chiffres)
    confirmation_code VARCHAR(4),
    -- Commissions (calculées par trigger)
    livreur_commission DECIMAL(10, 2) DEFAULT 0,
    admin_commission DECIMAL(10, 2) DEFAULT 0,
    restaurant_amount DECIMAL(10, 2) DEFAULT 0,
    -- Timestamps de progression
    estimated_delivery_time TIMESTAMPTZ,
    confirmed_at TIMESTAMPTZ,
    prepared_at TIMESTAMPTZ,
    livreur_accepted_at TIMESTAMPTZ,
    picked_up_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    cancellation_reason TEXT,
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.orders IS 'Commandes - INSERT/UPDATE via Backend NestJS uniquement';
COMMENT ON COLUMN public.orders.confirmation_code IS 'Code 4 chiffres pour confirmer la livraison';

-- ─────────────────────────────────────────────
-- ORDER_ITEMS (Articles de commande)
-- ─────────────────────────────────────────────
CREATE TABLE public.order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    menu_item_id UUID REFERENCES public.menu_items(id),
    name VARCHAR(100) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    special_instructions TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─────────────────────────────────────────────
-- REVIEWS (Avis)
-- ─────────────────────────────────────────────
CREATE TABLE public.reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID UNIQUE NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES public.profiles(id),
    restaurant_id UUID REFERENCES public.restaurants(id),
    livreur_id UUID REFERENCES public.livreurs(id),
    restaurant_rating INTEGER CHECK (restaurant_rating >= 1 AND restaurant_rating <= 5),
    livreur_rating INTEGER CHECK (livreur_rating >= 1 AND livreur_rating <= 5),
    comment TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─────────────────────────────────────────────
-- LIVREUR_LOCATIONS (Tracking temps réel)
-- ─────────────────────────────────────────────
CREATE TABLE public.livreur_locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    livreur_id UUID NOT NULL REFERENCES public.livreurs(id) ON DELETE CASCADE,
    order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    recorded_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.livreur_locations IS 'Historique positions livreur - utilisé pour le tracking client';

-- ─────────────────────────────────────────────
-- NOTIFICATIONS
-- ─────────────────────────────────────────────
CREATE TABLE public.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title VARCHAR(100) NOT NULL,
    body TEXT,
    data JSONB,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.notifications IS 'Notifications in-app (OneSignal gère les push)';

-- ─────────────────────────────────────────────
-- TRANSACTIONS (Comptabilité)
-- ─────────────────────────────────────────────
CREATE TABLE public.transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
    type VARCHAR(30) NOT NULL, -- 'livreur_earning', 'admin_commission', 'restaurant_payment', 'tip'
    amount DECIMAL(10, 2) NOT NULL,
    recipient_id UUID,
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'completed', 'failed'
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─────────────────────────────────────────────
-- PROMOTIONS
-- ─────────────────────────────────────────────
CREATE TABLE public.promotions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    restaurant_id UUID REFERENCES public.restaurants(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    discount_type VARCHAR(20) NOT NULL CHECK (discount_type IN ('percentage', 'fixed')),
    discount_value DECIMAL(10, 2) NOT NULL,
    min_order_amount DECIMAL(10, 2) DEFAULT 0,
    max_discount DECIMAL(10, 2),
    code VARCHAR(20) UNIQUE,
    is_active BOOLEAN DEFAULT true,
    starts_at TIMESTAMPTZ DEFAULT NOW(),
    ends_at TIMESTAMPTZ,
    usage_limit INTEGER,
    usage_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─────────────────────────────────────────────
-- FAVORITES
-- ─────────────────────────────────────────────
CREATE TABLE public.favorites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    restaurant_id UUID NOT NULL REFERENCES public.restaurants(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(customer_id, restaurant_id)
);

-- ─────────────────────────────────────────────
-- SAVED_ADDRESSES
-- ─────────────────────────────────────────────
CREATE TABLE public.saved_addresses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    label VARCHAR(50) NOT NULL, -- 'Maison', 'Bureau', etc.
    address TEXT NOT NULL,
    latitude DECIMAL(10, 7) NOT NULL,
    longitude DECIMAL(10, 7) NOT NULL,
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─────────────────────────────────────────────
-- ORDER_MESSAGES (Chat commande)
-- ─────────────────────────────────────────────
CREATE TABLE public.order_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    sender_type VARCHAR(20) NOT NULL CHECK (sender_type IN ('customer', 'livreur', 'restaurant', 'system')),
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- PARTIE 5: TABLES DE CONFIGURATION
-- ============================================

-- ─────────────────────────────────────────────
-- COMMISSION_SETTINGS
-- ─────────────────────────────────────────────
CREATE TABLE public.commission_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    livreur_commission_percent DECIMAL(5, 2) DEFAULT 15.00,
    admin_commission_percent DECIMAL(5, 2) DEFAULT 5.00,
    min_delivery_fee DECIMAL(10, 2) DEFAULT 100.00,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─────────────────────────────────────────────
-- TIER_CONFIG (Niveaux livreurs)
-- ─────────────────────────────────────────────
CREATE TABLE public.tier_config (
    tier livreur_tier PRIMARY KEY,
    commission_rate DECIMAL(5,2) NOT NULL,
    min_deliveries INTEGER NOT NULL,
    min_rating DECIMAL(3,2) NOT NULL,
    priority_level INTEGER NOT NULL,
    description TEXT
);

-- ─────────────────────────────────────────────
-- DELIVERY_PRICING
-- ─────────────────────────────────────────────
CREATE TABLE public.delivery_pricing (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(50) NOT NULL,
    base_fee DECIMAL(10,2) NOT NULL DEFAULT 100,
    per_km_fee DECIMAL(10,2) NOT NULL DEFAULT 30,
    min_fee DECIMAL(10,2) NOT NULL DEFAULT 100,
    max_fee DECIMAL(10,2) NOT NULL DEFAULT 500,
    is_active BOOLEAN DEFAULT true
);


-- ============================================
-- PARTIE 6: INDEXES (Performance)
-- ============================================

-- Profiles
CREATE INDEX idx_profiles_role ON public.profiles(role);
CREATE INDEX idx_profiles_phone ON public.profiles(phone);

-- Restaurants
CREATE INDEX idx_restaurants_owner ON public.restaurants(owner_id);
CREATE INDEX idx_restaurants_location ON public.restaurants(latitude, longitude);
CREATE INDEX idx_restaurants_cuisine ON public.restaurants(cuisine_type);
CREATE INDEX idx_restaurants_open ON public.restaurants(is_open, is_verified) WHERE is_open = true AND is_verified = true;

-- Menu
CREATE INDEX idx_menu_categories_restaurant ON public.menu_categories(restaurant_id);
CREATE INDEX idx_menu_items_restaurant ON public.menu_items(restaurant_id);
CREATE INDEX idx_menu_items_category ON public.menu_items(category_id);
CREATE INDEX idx_menu_items_available ON public.menu_items(restaurant_id, is_available) WHERE is_available = true;

-- Livreurs
CREATE INDEX idx_livreurs_user ON public.livreurs(user_id);
CREATE INDEX idx_livreurs_location ON public.livreurs(current_latitude, current_longitude);
CREATE INDEX idx_livreurs_available ON public.livreurs(is_available, is_online, is_verified) WHERE is_available = true AND is_online = true;

-- Orders (très important pour les performances)
CREATE INDEX idx_orders_customer ON public.orders(customer_id, created_at DESC);
CREATE INDEX idx_orders_restaurant ON public.orders(restaurant_id, created_at DESC);
CREATE INDEX idx_orders_livreur ON public.orders(livreur_id, created_at DESC);
CREATE INDEX idx_orders_status ON public.orders(status);
CREATE INDEX idx_orders_pending ON public.orders(status, created_at) WHERE status = 'pending';
CREATE INDEX idx_orders_active ON public.orders(status) WHERE status IN ('pending', 'confirmed', 'preparing', 'ready', 'picked_up', 'delivering');
CREATE INDEX idx_orders_ready_no_livreur ON public.orders(status, restaurant_id) WHERE status = 'ready' AND livreur_id IS NULL;

-- Order Items
CREATE INDEX idx_order_items_order ON public.order_items(order_id);

-- Livreur Locations
CREATE INDEX idx_livreur_locations_order ON public.livreur_locations(order_id, recorded_at DESC);
CREATE INDEX idx_livreur_locations_livreur ON public.livreur_locations(livreur_id, recorded_at DESC);

-- Notifications
CREATE INDEX idx_notifications_user ON public.notifications(user_id, is_read, created_at DESC);
CREATE INDEX idx_notifications_unread ON public.notifications(user_id) WHERE is_read = false;

-- Transactions
CREATE INDEX idx_transactions_order ON public.transactions(order_id);
CREATE INDEX idx_transactions_recipient ON public.transactions(recipient_id, created_at DESC);

-- Favorites
CREATE INDEX idx_favorites_customer ON public.favorites(customer_id);

-- Order Messages
CREATE INDEX idx_order_messages_order ON public.order_messages(order_id, created_at);

-- ============================================
-- PARTIE 7: ROW LEVEL SECURITY (RLS)
-- ============================================

-- Activer RLS sur toutes les tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.restaurants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menu_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menu_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.livreurs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.livreur_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.promotions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saved_addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_messages ENABLE ROW LEVEL SECURITY;

-- ============================================
-- PARTIE 8: POLICIES (Sécurité)
-- ============================================

-- ─────────────────────────────────────────────
-- PROFILES
-- ─────────────────────────────────────────────
CREATE POLICY "Profiles: lecture publique" 
    ON public.profiles FOR SELECT USING (true);

CREATE POLICY "Profiles: modification par propriétaire" 
    ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- ─────────────────────────────────────────────
-- RESTAURANTS
-- ─────────────────────────────────────────────
CREATE POLICY "Restaurants: lecture publique" 
    ON public.restaurants FOR SELECT USING (true);

CREATE POLICY "Restaurants: modification par propriétaire" 
    ON public.restaurants FOR UPDATE USING (auth.uid() = owner_id);

CREATE POLICY "Restaurants: création par propriétaire" 
    ON public.restaurants FOR INSERT WITH CHECK (auth.uid() = owner_id);

-- ─────────────────────────────────────────────
-- MENU
-- ─────────────────────────────────────────────
CREATE POLICY "Menu categories: lecture publique" 
    ON public.menu_categories FOR SELECT USING (true);

CREATE POLICY "Menu categories: gestion par restaurant" 
    ON public.menu_categories FOR ALL 
    USING (EXISTS (SELECT 1 FROM public.restaurants WHERE id = menu_categories.restaurant_id AND owner_id = auth.uid()));

CREATE POLICY "Menu items: lecture publique" 
    ON public.menu_items FOR SELECT USING (true);

CREATE POLICY "Menu items: gestion par restaurant" 
    ON public.menu_items FOR ALL 
    USING (EXISTS (SELECT 1 FROM public.restaurants WHERE id = menu_items.restaurant_id AND owner_id = auth.uid()));

-- ─────────────────────────────────────────────
-- LIVREURS
-- ─────────────────────────────────────────────
CREATE POLICY "Livreurs: lecture publique" 
    ON public.livreurs FOR SELECT USING (true);

CREATE POLICY "Livreurs: modification par propriétaire" 
    ON public.livreurs FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Livreurs: création par propriétaire" 
    ON public.livreurs FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ─────────────────────────────────────────────
-- ORDERS (Lecture seule côté client - modifications via Backend)
-- ─────────────────────────────────────────────
CREATE POLICY "Orders: lecture par client" 
    ON public.orders FOR SELECT 
    USING (auth.uid() = customer_id);

CREATE POLICY "Orders: lecture par restaurant" 
    ON public.orders FOR SELECT 
    USING (EXISTS (SELECT 1 FROM public.restaurants WHERE id = orders.restaurant_id AND owner_id = auth.uid()));

CREATE POLICY "Orders: lecture par livreur assigné" 
    ON public.orders FOR SELECT 
    USING (EXISTS (SELECT 1 FROM public.livreurs WHERE id = orders.livreur_id AND user_id = auth.uid()));

CREATE POLICY "Orders: lecture commandes disponibles (livreurs)" 
    ON public.orders FOR SELECT 
    USING (status = 'ready' AND livreur_id IS NULL AND EXISTS (SELECT 1 FROM public.livreurs WHERE user_id = auth.uid() AND is_verified = true));

-- Note: INSERT et UPDATE des orders passent par le Backend avec service_role key

-- ─────────────────────────────────────────────
-- ORDER_ITEMS
-- ─────────────────────────────────────────────
CREATE POLICY "Order items: lecture par parties concernées" 
    ON public.order_items FOR SELECT 
    USING (EXISTS (
        SELECT 1 FROM public.orders o 
        WHERE o.id = order_items.order_id 
        AND (
            o.customer_id = auth.uid() 
            OR EXISTS (SELECT 1 FROM public.restaurants WHERE id = o.restaurant_id AND owner_id = auth.uid())
            OR EXISTS (SELECT 1 FROM public.livreurs WHERE id = o.livreur_id AND user_id = auth.uid())
        )
    ));

-- ─────────────────────────────────────────────
-- REVIEWS
-- ─────────────────────────────────────────────
CREATE POLICY "Reviews: lecture publique" 
    ON public.reviews FOR SELECT USING (true);

CREATE POLICY "Reviews: création par client" 
    ON public.reviews FOR INSERT WITH CHECK (auth.uid() = customer_id);

-- ─────────────────────────────────────────────
-- LIVREUR_LOCATIONS
-- ─────────────────────────────────────────────
CREATE POLICY "Locations: lecture par parties concernées" 
    ON public.livreur_locations FOR SELECT 
    USING (
        EXISTS (SELECT 1 FROM public.livreurs WHERE id = livreur_locations.livreur_id AND user_id = auth.uid())
        OR EXISTS (
            SELECT 1 FROM public.orders o 
            WHERE o.id = livreur_locations.order_id 
            AND (o.customer_id = auth.uid() OR EXISTS (SELECT 1 FROM public.restaurants WHERE id = o.restaurant_id AND owner_id = auth.uid()))
        )
    );

CREATE POLICY "Locations: insertion par livreur" 
    ON public.livreur_locations FOR INSERT 
    WITH CHECK (EXISTS (SELECT 1 FROM public.livreurs WHERE id = livreur_locations.livreur_id AND user_id = auth.uid()));

-- ─────────────────────────────────────────────
-- NOTIFICATIONS
-- ─────────────────────────────────────────────
CREATE POLICY "Notifications: lecture par propriétaire" 
    ON public.notifications FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Notifications: modification par propriétaire" 
    ON public.notifications FOR UPDATE USING (auth.uid() = user_id);

-- ─────────────────────────────────────────────
-- TRANSACTIONS
-- ─────────────────────────────────────────────
CREATE POLICY "Transactions: lecture par admin" 
    ON public.transactions FOR SELECT 
    USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "Transactions: lecture par destinataire" 
    ON public.transactions FOR SELECT USING (recipient_id = auth.uid());

-- ─────────────────────────────────────────────
-- PROMOTIONS
-- ─────────────────────────────────────────────
CREATE POLICY "Promotions: lecture publique" 
    ON public.promotions FOR SELECT USING (true);

CREATE POLICY "Promotions: gestion par restaurant" 
    ON public.promotions FOR ALL 
    USING (EXISTS (SELECT 1 FROM public.restaurants WHERE id = promotions.restaurant_id AND owner_id = auth.uid()));

-- ─────────────────────────────────────────────
-- FAVORITES
-- ─────────────────────────────────────────────
CREATE POLICY "Favorites: gestion par propriétaire" 
    ON public.favorites FOR ALL USING (auth.uid() = customer_id);

-- ─────────────────────────────────────────────
-- SAVED_ADDRESSES
-- ─────────────────────────────────────────────
CREATE POLICY "Addresses: gestion par propriétaire" 
    ON public.saved_addresses FOR ALL USING (auth.uid() = customer_id);

-- ─────────────────────────────────────────────
-- ORDER_MESSAGES
-- ─────────────────────────────────────────────
CREATE POLICY "Messages: lecture par parties concernées" 
    ON public.order_messages FOR SELECT 
    USING (EXISTS (
        SELECT 1 FROM public.orders o 
        WHERE o.id = order_messages.order_id 
        AND (o.customer_id = auth.uid() OR EXISTS (SELECT 1 FROM public.livreurs WHERE id = o.livreur_id AND user_id = auth.uid()))
    ));

CREATE POLICY "Messages: envoi par expéditeur" 
    ON public.order_messages FOR INSERT WITH CHECK (auth.uid() = sender_id);


-- ============================================
-- PARTIE 9: FONCTIONS
-- ============================================

-- ─────────────────────────────────────────────
-- Fonction: updated_at automatique
-- ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ─────────────────────────────────────────────
-- Fonction: Créer profil à l'inscription
-- ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, phone, role)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
        COALESCE(NEW.raw_user_meta_data->>'phone', ''),
        COALESCE((NEW.raw_user_meta_data->>'role')::user_role, 'customer')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─────────────────────────────────────────────
-- Fonction: Générer numéro de commande
-- Format: DZ + YYMMDD + 4 chiffres (ex: DZ2601160001)
-- ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS TRIGGER AS $$
DECLARE
    today_count INTEGER;
BEGIN
    SELECT COUNT(*) + 1 INTO today_count
    FROM public.orders
    WHERE DATE(created_at) = CURRENT_DATE;
    
    NEW.order_number = 'DZ' || TO_CHAR(CURRENT_DATE, 'YYMMDD') || LPAD(today_count::TEXT, 4, '0');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ─────────────────────────────────────────────
-- Fonction: Générer code de confirmation (4 chiffres)
-- ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION generate_confirmation_code()
RETURNS TRIGGER AS $$
BEGIN
    NEW.confirmation_code = LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ─────────────────────────────────────────────
-- Fonction: Calculer les commissions
-- ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION calculate_commissions()
RETURNS TRIGGER AS $$
DECLARE
    settings RECORD;
BEGIN
    SELECT * INTO settings FROM public.commission_settings LIMIT 1;
    
    -- Commission livreur = frais de livraison (minimum garanti)
    NEW.livreur_commission := GREATEST(NEW.delivery_fee, COALESCE(settings.min_delivery_fee, 100));
    
    -- Commission admin = % du total
    NEW.admin_commission := ROUND(NEW.total * COALESCE(settings.admin_commission_percent, 5) / 100, 2);
    
    -- Montant restaurant = total - commission admin - frais livraison
    NEW.restaurant_amount := NEW.total - NEW.admin_commission - NEW.delivery_fee;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ─────────────────────────────────────────────
-- Fonction: Mettre à jour rating restaurant
-- ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION update_restaurant_rating()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.restaurants
    SET 
        rating = (SELECT COALESCE(AVG(restaurant_rating), 0) FROM public.reviews WHERE restaurant_id = NEW.restaurant_id AND restaurant_rating IS NOT NULL),
        total_reviews = (SELECT COUNT(*) FROM public.reviews WHERE restaurant_id = NEW.restaurant_id AND restaurant_rating IS NOT NULL)
    WHERE id = NEW.restaurant_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ─────────────────────────────────────────────
-- Fonction: Mettre à jour rating livreur
-- ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION update_livreur_rating()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.livreur_id IS NOT NULL THEN
        UPDATE public.livreurs
        SET rating = (SELECT COALESCE(AVG(livreur_rating), 5.0) FROM public.reviews WHERE livreur_id = NEW.livreur_id AND livreur_rating IS NOT NULL)
        WHERE id = NEW.livreur_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ─────────────────────────────────────────────
-- Fonction: Créer transactions après livraison
-- ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION create_delivery_transactions()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'delivered' AND OLD.status != 'delivered' THEN
        -- Transaction livreur
        INSERT INTO public.transactions (order_id, type, amount, recipient_id, status, description)
        SELECT NEW.id, 'livreur_earning', NEW.livreur_commission, l.user_id, 'completed', 'Commission livraison #' || NEW.order_number
        FROM public.livreurs l WHERE l.id = NEW.livreur_id;
        
        -- Transaction admin
        INSERT INTO public.transactions (order_id, type, amount, recipient_id, status, description)
        VALUES (NEW.id, 'admin_commission', NEW.admin_commission, NULL, 'completed', 'Commission admin #' || NEW.order_number);
        
        -- Transaction restaurant
        INSERT INTO public.transactions (order_id, type, amount, recipient_id, status, description)
        SELECT NEW.id, 'restaurant_payment', NEW.restaurant_amount, r.owner_id, 'pending', 'Paiement restaurant #' || NEW.order_number
        FROM public.restaurants r WHERE r.id = NEW.restaurant_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ─────────────────────────────────────────────
-- Fonction: Mise à jour stats après livraison
-- ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION after_delivery_complete()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'delivered' AND OLD.status != 'delivered' THEN
        -- Update livreur stats
        UPDATE public.livreurs SET
            total_deliveries = total_deliveries + 1,
            total_earnings = total_earnings + NEW.livreur_commission,
            weekly_deliveries = weekly_deliveries + 1,
            monthly_deliveries = monthly_deliveries + 1
        WHERE id = NEW.livreur_id;
        
        -- Update customer stats
        UPDATE public.profiles SET
            total_orders = total_orders + 1,
            total_spent = total_spent + NEW.total,
            loyalty_points = loyalty_points + FLOOR(NEW.total / 100)::INTEGER
        WHERE id = NEW.customer_id;
        
        -- Update menu items order count
        UPDATE public.menu_items mi SET
            order_count = order_count + oi.quantity
        FROM public.order_items oi
        WHERE oi.order_id = NEW.id AND mi.id = oi.menu_item_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ─────────────────────────────────────────────
-- Fonction: Mise à jour tier livreur
-- ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION update_livreur_tier()
RETURNS TRIGGER AS $$
DECLARE
    v_new_tier livreur_tier;
BEGIN
    IF NEW.total_deliveries >= 400 AND COALESCE(NEW.rating, 5.0) >= 4.6 THEN
        v_new_tier := 'diamond';
    ELSIF NEW.total_deliveries >= 150 AND COALESCE(NEW.rating, 5.0) >= 4.2 THEN
        v_new_tier := 'gold';
    ELSIF NEW.total_deliveries >= 50 AND COALESCE(NEW.rating, 5.0) >= 3.8 THEN
        v_new_tier := 'silver';
    ELSE
        v_new_tier := 'bronze';
    END IF;
    
    IF NEW.tier IS DISTINCT FROM v_new_tier THEN
        NEW.tier := v_new_tier;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ─────────────────────────────────────────────
-- Fonction: Générer code parrainage
-- ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION generate_referral_code()
RETURNS TRIGGER AS $$
BEGIN
    NEW.referral_code := UPPER(SUBSTRING(MD5(NEW.id::text || NOW()::text) FROM 1 FOR 8));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- PARTIE 10: FONCTIONS API (Lecture)
-- ============================================

-- ─────────────────────────────────────────────
-- Fonction: Restaurants à proximité
-- ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION get_nearby_restaurants(
    user_lat DECIMAL, 
    user_lng DECIMAL, 
    radius_km DECIMAL DEFAULT 10
)
RETURNS TABLE (
    id UUID, 
    name VARCHAR, 
    description TEXT, 
    logo_url TEXT, 
    cuisine_type VARCHAR,
    rating DECIMAL, 
    delivery_fee DECIMAL, 
    avg_prep_time INTEGER, 
    distance_km DECIMAL, 
    is_open BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        r.id, r.name, r.description, r.logo_url, r.cuisine_type, 
        r.rating, r.delivery_fee, r.avg_prep_time,
        ROUND((6371 * acos(
            cos(radians(user_lat)) * cos(radians(r.latitude)) * 
            cos(radians(r.longitude) - radians(user_lng)) + 
            sin(radians(user_lat)) * sin(radians(r.latitude))
        ))::DECIMAL, 2) AS distance_km,
        r.is_open
    FROM public.restaurants r
    WHERE r.is_verified = true
    AND (6371 * acos(
        cos(radians(user_lat)) * cos(radians(r.latitude)) * 
        cos(radians(r.longitude) - radians(user_lng)) + 
        sin(radians(user_lat)) * sin(radians(r.latitude))
    )) <= radius_km
    ORDER BY distance_km;
END;
$$ LANGUAGE plpgsql;

-- ─────────────────────────────────────────────
-- Fonction: Livreurs disponibles
-- ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION get_available_livreurs(
    restaurant_lat DECIMAL, 
    restaurant_lng DECIMAL, 
    radius_km DECIMAL DEFAULT 5
)
RETURNS TABLE (
    id UUID, 
    user_id UUID, 
    full_name VARCHAR, 
    phone VARCHAR, 
    vehicle_type vehicle_type, 
    rating DECIMAL, 
    distance_km DECIMAL,
    tier livreur_tier
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        l.id, l.user_id, p.full_name, p.phone, l.vehicle_type, l.rating,
        ROUND((6371 * acos(
            cos(radians(restaurant_lat)) * cos(radians(l.current_latitude)) * 
            cos(radians(l.current_longitude) - radians(restaurant_lng)) + 
            sin(radians(restaurant_lat)) * sin(radians(l.current_latitude))
        ))::DECIMAL, 2) AS distance_km,
        l.tier
    FROM public.livreurs l
    JOIN public.profiles p ON p.id = l.user_id
    WHERE l.is_available = true 
    AND l.is_online = true 
    AND l.is_verified = true 
    AND l.current_latitude IS NOT NULL
    AND (6371 * acos(
        cos(radians(restaurant_lat)) * cos(radians(l.current_latitude)) * 
        cos(radians(l.current_longitude) - radians(restaurant_lng)) + 
        sin(radians(restaurant_lat)) * sin(radians(l.current_latitude))
    )) <= radius_km
    ORDER BY l.tier DESC, distance_km;
END;
$$ LANGUAGE plpgsql;

-- ─────────────────────────────────────────────
-- Fonction: Stats restaurant
-- ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION get_restaurant_stats(restaurant_uuid UUID)
RETURNS TABLE (
    total_orders BIGINT, 
    total_revenue DECIMAL, 
    orders_today BIGINT, 
    revenue_today DECIMAL, 
    avg_order_value DECIMAL, 
    pending_orders BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::BIGINT,
        COALESCE(SUM(total), 0),
        COUNT(*) FILTER (WHERE DATE(created_at) = CURRENT_DATE)::BIGINT,
        COALESCE(SUM(total) FILTER (WHERE DATE(created_at) = CURRENT_DATE), 0),
        COALESCE(AVG(total), 0),
        COUNT(*) FILTER (WHERE status IN ('pending', 'confirmed', 'preparing'))::BIGINT
    FROM public.orders 
    WHERE orders.restaurant_id = restaurant_uuid AND status != 'cancelled';
END;
$$ LANGUAGE plpgsql;

-- ─────────────────────────────────────────────
-- Fonction: Stats admin
-- ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION get_admin_stats()
RETURNS TABLE (
    total_orders BIGINT, 
    total_revenue DECIMAL, 
    total_admin_commission DECIMAL, 
    today_orders BIGINT, 
    today_commission DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::BIGINT,
        COALESCE(SUM(total), 0),
        COALESCE(SUM(admin_commission), 0),
        COUNT(*) FILTER (WHERE DATE(created_at) = CURRENT_DATE)::BIGINT,
        COALESCE(SUM(admin_commission) FILTER (WHERE DATE(created_at) = CURRENT_DATE), 0)
    FROM public.orders 
    WHERE status = 'delivered';
END;
$$ LANGUAGE plpgsql;

-- ─────────────────────────────────────────────
-- Fonction: Calculer frais de livraison
-- ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION calculate_delivery_fee(
    p_restaurant_lat DECIMAL, 
    p_restaurant_lng DECIMAL, 
    p_customer_lat DECIMAL, 
    p_customer_lng DECIMAL
)
RETURNS TABLE (
    distance_km DECIMAL, 
    base_fee DECIMAL, 
    distance_fee DECIMAL, 
    total_fee DECIMAL, 
    estimated_time INTEGER
) AS $$
DECLARE
    v_distance DECIMAL;
    v_pricing RECORD;
    v_total DECIMAL;
BEGIN
    -- Calcul distance (formule Haversine)
    v_distance := 6371 * ACOS(
        COS(RADIANS(p_restaurant_lat)) * COS(RADIANS(p_customer_lat)) * 
        COS(RADIANS(p_customer_lng) - RADIANS(p_restaurant_lng)) + 
        SIN(RADIANS(p_restaurant_lat)) * SIN(RADIANS(p_customer_lat))
    );
    
    SELECT * INTO v_pricing FROM public.delivery_pricing WHERE is_active = true LIMIT 1;
    
    v_total := COALESCE(v_pricing.base_fee, 100) + (v_distance * COALESCE(v_pricing.per_km_fee, 30));
    v_total := GREATEST(COALESCE(v_pricing.min_fee, 100), LEAST(v_total, COALESCE(v_pricing.max_fee, 500)));
    
    RETURN QUERY SELECT 
        ROUND(v_distance, 2), 
        COALESCE(v_pricing.base_fee, 100), 
        ROUND(v_distance * COALESCE(v_pricing.per_km_fee, 30), 2), 
        ROUND(v_total, 0), 
        (CEIL(v_distance * 3) + 10)::INTEGER;
END;
$$ LANGUAGE plpgsql;


-- ============================================
-- PARTIE 11: TRIGGERS
-- ============================================

-- Updated_at automatique
CREATE TRIGGER update_profiles_updated_at 
    BEFORE UPDATE ON public.profiles 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_restaurants_updated_at 
    BEFORE UPDATE ON public.restaurants 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_menu_items_updated_at 
    BEFORE UPDATE ON public.menu_items 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_livreurs_updated_at 
    BEFORE UPDATE ON public.livreurs 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_orders_updated_at 
    BEFORE UPDATE ON public.orders 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Création profil à l'inscription
CREATE TRIGGER on_auth_user_created 
    AFTER INSERT ON auth.users 
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Génération numéro de commande
CREATE TRIGGER generate_order_number_trigger 
    BEFORE INSERT ON public.orders 
    FOR EACH ROW EXECUTE FUNCTION generate_order_number();

-- Génération code de confirmation
CREATE TRIGGER generate_confirmation_code_trigger 
    BEFORE INSERT ON public.orders 
    FOR EACH ROW EXECUTE FUNCTION generate_confirmation_code();

-- Calcul des commissions
CREATE TRIGGER calculate_commissions_trigger 
    BEFORE INSERT ON public.orders 
    FOR EACH ROW EXECUTE FUNCTION calculate_commissions();

-- Mise à jour rating restaurant
CREATE TRIGGER update_restaurant_rating_trigger 
    AFTER INSERT OR UPDATE ON public.reviews 
    FOR EACH ROW EXECUTE FUNCTION update_restaurant_rating();

-- Mise à jour rating livreur
CREATE TRIGGER update_livreur_rating_trigger 
    AFTER INSERT OR UPDATE ON public.reviews 
    FOR EACH ROW EXECUTE FUNCTION update_livreur_rating();

-- Création transactions après livraison
CREATE TRIGGER create_delivery_transactions_trigger 
    AFTER UPDATE ON public.orders 
    FOR EACH ROW EXECUTE FUNCTION create_delivery_transactions();

-- Mise à jour stats après livraison
CREATE TRIGGER after_delivery_complete_trigger 
    AFTER UPDATE ON public.orders 
    FOR EACH ROW EXECUTE FUNCTION after_delivery_complete();

-- Mise à jour tier livreur
CREATE TRIGGER update_livreur_tier_trigger 
    BEFORE UPDATE ON public.livreurs 
    FOR EACH ROW EXECUTE FUNCTION update_livreur_tier();

-- Génération code parrainage
CREATE TRIGGER generate_referral_code_trigger 
    BEFORE INSERT ON public.profiles 
    FOR EACH ROW EXECUTE FUNCTION generate_referral_code();

-- ============================================
-- PARTIE 12: DONNÉES DE CONFIGURATION
-- ============================================

-- Commission settings
INSERT INTO public.commission_settings (livreur_commission_percent, admin_commission_percent, min_delivery_fee)
VALUES (15.00, 5.00, 100.00);

-- Tier config
INSERT INTO public.tier_config (tier, commission_rate, min_deliveries, min_rating, priority_level, description) VALUES
    ('bronze', 10.0, 0, 0, 1, 'Nouveau livreur'),
    ('silver', 12.0, 50, 3.8, 2, 'Livreur régulier'),
    ('gold', 14.0, 150, 4.2, 3, 'Livreur expert'),
    ('diamond', 16.0, 400, 4.6, 4, 'Livreur élite');

-- Delivery pricing
INSERT INTO public.delivery_pricing (name, base_fee, per_km_fee, min_fee, max_fee, is_active)
VALUES ('standard', 100, 30, 100, 500, true);

-- ============================================
-- PARTIE 13: REALTIME (Supabase)
-- ============================================

-- Activer Realtime sur les tables importantes
-- (À faire dans le Dashboard Supabase > Database > Replication)
-- Tables à activer:
-- - orders (pour le suivi des commandes)
-- - livreur_locations (pour le tracking)
-- - notifications (pour les notifs in-app)
-- - order_messages (pour le chat)

-- ============================================
-- PARTIE 14: STORAGE BUCKETS
-- ============================================

-- À créer manuellement dans Supabase Dashboard > Storage:
-- 1. menu-images (public) - Images des plats
-- 2. restaurant-images (public) - Logos et covers restaurants
-- 3. profile-images (public) - Avatars utilisateurs

-- ============================================
-- FIN DU SCHÉMA
-- ============================================

-- Vérification
SELECT 'Schéma créé avec succès!' AS status;
SELECT 
    (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public') AS tables_count,
    (SELECT COUNT(*) FROM pg_indexes WHERE schemaname = 'public') AS indexes_count,
    (SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public') AS policies_count;

-- ============================================
-- RÉSUMÉ DE L'ARCHITECTURE
-- ============================================
/*
┌─────────────────────────────────────────────────────────────────────────────┐
│                           DZ DELIVERY - ARCHITECTURE                         │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  FLUTTER APP                                                                 │
│  ├── Auth (Supabase Auth)                                                   │
│  ├── Lectures (Supabase Direct - RLS protégé)                               │
│  │   ├── Restaurants, Menu, Profils                                         │
│  │   ├── Commandes (lecture seule)                                          │
│  │   └── Notifications, Favoris, Adresses                                   │
│  ├── Realtime (Supabase Realtime)                                           │
│  │   ├── Suivi commandes                                                    │
│  │   ├── Position livreur                                                   │
│  │   └── Chat commande                                                      │
│  └── Opérations critiques (Backend API)                                     │
│      ├── Créer commande                                                     │
│      ├── Changer statut                                                     │
│      ├── Annuler commande                                                   │
│      └── Vérifier code livraison                                            │
│                                                                              │
│  BACKEND NESTJS (Koyeb)                                                      │
│  ├── Validation des données                                                 │
│  ├── Logique métier                                                         │
│  ├── Calcul des prix                                                        │
│  ├── Transitions de statut                                                  │
│  ├── Notifications OneSignal                                                │
│  └── Écriture Supabase (service_role)                                       │
│                                                                              │
│  SUPABASE                                                                    │
│  ├── Auth (inscription, connexion)                                          │
│  ├── Database (PostgreSQL)                                                  │
│  │   ├── Tables avec RLS                                                    │
│  │   ├── Triggers automatiques                                              │
│  │   └── Fonctions utilitaires                                              │
│  ├── Realtime (WebSocket)                                                   │
│  └── Storage (images)                                                       │
│                                                                              │
│  ONESIGNAL                                                                   │
│  └── Push notifications (appelé par Backend)                                │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘

FLUX DE COMMANDE:
1. Client crée commande → Backend valide → Supabase INSERT
2. Restaurant confirme → Backend change statut → Supabase UPDATE → Realtime notifie
3. Livreur accepte → Backend change statut → OneSignal notifie client
4. Livreur livre → Backend vérifie code → Supabase UPDATE → Transactions créées

SÉCURITÉ:
- RLS protège toutes les lectures
- Backend utilise service_role pour les écritures
- Validation côté serveur pour toutes les opérations critiques
*/
