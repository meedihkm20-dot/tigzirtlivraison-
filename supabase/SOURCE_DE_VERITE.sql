-- ============================================================
-- DZ DELIVERY - SOURCE DE VÉRITÉ UNIQUE
-- ============================================================
-- Date: 2025-01-16
-- Version: 1.0.0
-- 
-- CE FICHIER EST LA RÉFÉRENCE ABSOLUE POUR:
-- - Backend NestJS (backend/src/types/database.types.ts)
-- - Flutter App (apps/dz_delivery/lib/core/models/database_models.dart)
-- - Admin App (apps/admin_app)
--
-- RÈGLE: Toute modification du schéma DOIT commencer ici
-- ============================================================

-- ============================================
-- EXTENSIONS
-- ============================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- ============================================
-- TYPES ENUM
-- ============================================
DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('customer', 'restaurant', 'livreur', 'admin');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE order_status AS ENUM ('pending', 'confirmed', 'preparing', 'ready', 'picked_up', 'delivering', 'delivered', 'cancelled');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE payment_method AS ENUM ('cash', 'card', 'edahabia', 'cib');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE payment_status AS ENUM ('pending', 'paid', 'failed', 'refunded');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE vehicle_type AS ENUM ('moto', 'velo', 'voiture');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE livreur_tier AS ENUM ('bronze', 'silver', 'gold', 'diamond');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ============================================
-- TABLE 1: profiles
-- Utilisateurs de l'application (tous rôles)
-- ============================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    role user_role NOT NULL DEFAULT 'customer',
    phone VARCHAR(20),
    full_name VARCHAR(100),
    avatar_url TEXT,
    address TEXT,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    is_active BOOLEAN DEFAULT true,
    is_available BOOLEAN DEFAULT false,
    fcm_token TEXT,
    onesignal_player_id TEXT,
    loyalty_points INTEGER DEFAULT 0,
    total_orders INTEGER DEFAULT 0,
    total_spent DECIMAL(12,2) DEFAULT 0,
    referral_code VARCHAR(10),
    referred_by UUID REFERENCES public.profiles(id),
    referral_earnings DECIMAL(10,2) DEFAULT 0,
    phone_verified BOOLEAN DEFAULT false,
    email_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- TABLE 2: restaurants
-- Restaurants partenaires
-- ============================================
CREATE TABLE IF NOT EXISTS public.restaurants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    logo_url TEXT,
    cover_url TEXT,
    phone VARCHAR(20),
    address TEXT NOT NULL,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    cuisine_type VARCHAR(50),
    opening_time TIME DEFAULT '08:00',
    closing_time TIME DEFAULT '23:00',
    min_order_amount DECIMAL(10, 2) DEFAULT 0,
    delivery_fee DECIMAL(10, 2) DEFAULT 0,
    avg_prep_time INTEGER DEFAULT 30,
    rating DECIMAL(2, 1) DEFAULT 0,
    total_reviews INTEGER DEFAULT 0,
    is_open BOOLEAN DEFAULT true,
    is_verified BOOLEAN DEFAULT false,
    cover_images TEXT[],
    tags TEXT[],
    accepts_preorders BOOLEAN DEFAULT false,
    fcm_token TEXT,
    onesignal_player_id TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- TABLE 3: menu_categories
-- Catégories de menu par restaurant
-- ============================================
CREATE TABLE IF NOT EXISTS public.menu_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    restaurant_id UUID REFERENCES public.restaurants(id) ON DELETE CASCADE,
    name VARCHAR(50) NOT NULL,
    description TEXT,
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- TABLE 4: menu_items
-- Plats du menu
-- ============================================
CREATE TABLE IF NOT EXISTS public.menu_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    restaurant_id UUID REFERENCES public.restaurants(id) ON DELETE CASCADE,
    category_id UUID REFERENCES public.menu_categories(id) ON DELETE SET NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    image_url TEXT,
    is_available BOOLEAN DEFAULT true,
    is_popular BOOLEAN DEFAULT false,
    prep_time INTEGER DEFAULT 15,
    calories INTEGER,
    is_vegetarian BOOLEAN DEFAULT false,
    is_spicy BOOLEAN DEFAULT false,
    allergens TEXT[],
    order_count INTEGER DEFAULT 0,
    image_width INTEGER DEFAULT 500,
    image_height INTEGER DEFAULT 500,
    ingredients TEXT[],
    nutrition_info JSONB,
    is_daily_special BOOLEAN DEFAULT false,
    daily_special_price DECIMAL(10,2),
    avg_rating DECIMAL(3,2) DEFAULT 0,
    total_reviews INTEGER DEFAULT 0,
    last_ordered_at TIMESTAMPTZ,
    tags TEXT[],
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- TABLE 5: livreurs
-- Livreurs partenaires
-- ============================================
CREATE TABLE IF NOT EXISTS public.livreurs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
    vehicle_type vehicle_type DEFAULT 'moto',
    vehicle_number VARCHAR(20),
    license_number VARCHAR(50),
    current_latitude DECIMAL(10, 8),
    current_longitude DECIMAL(11, 8),
    is_available BOOLEAN DEFAULT false,
    is_online BOOLEAN DEFAULT false,
    is_verified BOOLEAN DEFAULT false,
    rating DECIMAL(2, 1) DEFAULT 5.0,
    total_deliveries INTEGER DEFAULT 0,
    total_earnings DECIMAL(12, 2) DEFAULT 0,
    total_distance_km DECIMAL(10, 2) DEFAULT 0,
    avg_delivery_time INTEGER,
    acceptance_rate DECIMAL(5, 2) DEFAULT 100,
    tier livreur_tier DEFAULT 'bronze',
    tier_progress INTEGER DEFAULT 0,
    weekly_deliveries INTEGER DEFAULT 0,
    monthly_deliveries INTEGER DEFAULT 0,
    cancellation_rate DECIMAL(5,2) DEFAULT 0,
    streak_days INTEGER DEFAULT 0,
    last_active_date DATE,
    bonus_earned DECIMAL(10,2) DEFAULT 0,
    fcm_token TEXT,
    onesignal_player_id TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- TABLE 6: orders ⚠️ TABLE CRITIQUE
-- Commandes - COLONNES À NE PAS RENOMMER
-- ============================================
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_number VARCHAR(20) UNIQUE NOT NULL,
    customer_id UUID REFERENCES public.profiles(id),
    restaurant_id UUID REFERENCES public.restaurants(id),
    livreur_id UUID REFERENCES public.livreurs(id),  -- ⚠️ PAS "driver_id"
    status order_status DEFAULT 'pending',
    
    -- Adresse de livraison
    delivery_address TEXT NOT NULL,
    delivery_latitude DECIMAL(10, 8) NOT NULL,   -- ⚠️ PAS "delivery_lat"
    delivery_longitude DECIMAL(11, 8) NOT NULL,  -- ⚠️ PAS "delivery_lng"
    delivery_instructions TEXT,
    
    -- Montants
    subtotal DECIMAL(10, 2) NOT NULL,
    delivery_fee DECIMAL(10, 2) DEFAULT 0,
    service_fee DECIMAL(10, 2) DEFAULT 0,
    discount DECIMAL(10, 2) DEFAULT 0,
    total DECIMAL(10, 2) NOT NULL,  -- ⚠️ PAS "total_amount"
    
    -- Paiement
    payment_method payment_method DEFAULT 'cash',
    payment_status payment_status DEFAULT 'pending',
    
    -- Timestamps de suivi
    estimated_delivery_time TIMESTAMPTZ,
    confirmed_at TIMESTAMPTZ,
    prepared_at TIMESTAMPTZ,  -- ⚠️ PAS "preparing_at"
    picked_up_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    cancellation_reason TEXT,
    cancelled_by VARCHAR(20),  -- 'customer', 'restaurant', 'livreur', 'admin', 'system'
    
    -- Code de confirmation
    confirmation_code VARCHAR(4),
    code_verified_at TIMESTAMPTZ,
    
    -- Commissions
    livreur_commission DECIMAL(10, 2) DEFAULT 0,
    admin_commission DECIMAL(10, 2) DEFAULT 0,
    restaurant_amount DECIMAL(10, 2) DEFAULT 0,
    livreur_accepted_at TIMESTAMPTZ,
    
    -- Promotions
    promotion_id UUID,
    promo_code VARCHAR(20),
    promo_discount DECIMAL(10, 2) DEFAULT 0,
    
    -- Tracking
    current_eta_minutes INTEGER,
    distance_remaining_km DECIMAL(10,2),
    
    -- Pourboire
    tip_amount DECIMAL(10,2) DEFAULT 0,
    tip_paid_at TIMESTAMPTZ,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- TABLE 7: order_items
-- Items de commande
-- ============================================
CREATE TABLE IF NOT EXISTS public.order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
    menu_item_id UUID REFERENCES public.menu_items(id),
    name VARCHAR(100) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    special_instructions TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- TABLE 8: reviews
-- Avis clients
-- ============================================
CREATE TABLE IF NOT EXISTS public.reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID UNIQUE REFERENCES public.orders(id) ON DELETE CASCADE,
    customer_id UUID REFERENCES public.profiles(id),
    restaurant_id UUID REFERENCES public.restaurants(id),
    livreur_id UUID REFERENCES public.livreurs(id),
    restaurant_rating INTEGER CHECK (restaurant_rating >= 1 AND restaurant_rating <= 5),
    livreur_rating INTEGER CHECK (livreur_rating >= 1 AND livreur_rating <= 5),
    comment TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- TABLE 9: transactions
-- Transactions financières
-- ============================================
CREATE TABLE IF NOT EXISTS public.transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
    type VARCHAR(20) NOT NULL,  -- 'livreur_earning', 'admin_commission', 'restaurant_payment', 'tip'
    amount DECIMAL(10, 2) NOT NULL,
    recipient_id UUID,
    status VARCHAR(20) DEFAULT 'pending',  -- 'pending', 'completed', 'cancelled'
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- TABLE 10: notifications
-- Notifications push
-- ============================================
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    title VARCHAR(100) NOT NULL,
    body TEXT,
    data JSONB,
    is_read BOOLEAN DEFAULT false,
    notification_type VARCHAR(50) DEFAULT 'system',
    sent_at TIMESTAMPTZ DEFAULT NOW(),
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- TABLE 11: livreur_locations
-- Tracking GPS des livreurs
-- ============================================
CREATE TABLE IF NOT EXISTS public.livreur_locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    livreur_id UUID REFERENCES public.livreurs(id) ON DELETE CASCADE,
    order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    speed DECIMAL(5,2),
    heading DECIMAL(5,2),
    recorded_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- TABLE 12: order_messages
-- Chat de commande
-- ============================================
CREATE TABLE IF NOT EXISTS public.order_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    sender_type VARCHAR(20) NOT NULL CHECK (sender_type IN ('customer', 'livreur', 'restaurant', 'system')),
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- TABLE 13: saved_addresses
-- Adresses sauvegardées
-- ============================================
CREATE TABLE IF NOT EXISTS public.saved_addresses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    label VARCHAR(50) NOT NULL,
    address TEXT NOT NULL,
    latitude DECIMAL(10, 7) NOT NULL,
    longitude DECIMAL(10, 7) NOT NULL,
    instructions TEXT,
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- TABLE 14: favorites
-- Restaurants favoris
-- ============================================
CREATE TABLE IF NOT EXISTS public.favorites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    restaurant_id UUID REFERENCES public.restaurants(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(customer_id, restaurant_id)
);

-- ============================================
-- TABLE 15: favorite_items
-- Plats favoris
-- ============================================
CREATE TABLE IF NOT EXISTS public.favorite_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    menu_item_id UUID REFERENCES public.menu_items(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(customer_id, menu_item_id)
);

-- ============================================
-- TABLE 16: promotions
-- Codes promo et réductions
-- ============================================
CREATE TABLE IF NOT EXISTS public.promotions (
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

-- ============================================
-- TABLE 17: commission_settings
-- Paramètres de commission
-- ============================================
CREATE TABLE IF NOT EXISTS public.commission_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    livreur_commission_percent DECIMAL(5, 2) DEFAULT 15.00,
    admin_commission_percent DECIMAL(5, 2) DEFAULT 5.00,
    min_delivery_fee DECIMAL(10, 2) DEFAULT 100.00,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- TABLE 18: delivery_pricing
-- Tarification livraison
-- ============================================
CREATE TABLE IF NOT EXISTS public.delivery_pricing (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(50) NOT NULL,
    base_fee DECIMAL(10,2) NOT NULL DEFAULT 100,
    per_km_fee DECIMAL(10,2) NOT NULL DEFAULT 30,
    min_fee DECIMAL(10,2) NOT NULL DEFAULT 100,
    max_fee DECIMAL(10,2) NOT NULL DEFAULT 500,
    surge_multiplier DECIMAL(3,2) DEFAULT 1.0,
    is_active BOOLEAN DEFAULT true
);

-- ============================================
-- TABLE 19: delivery_zones
-- Zones de livraison
-- ============================================
CREATE TABLE IF NOT EXISTS public.delivery_zones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    polygon JSONB NOT NULL,
    fee_adjustment DECIMAL(10,2) DEFAULT 0,
    is_active BOOLEAN DEFAULT true
);

-- ============================================
-- TABLE 20: livreur_badges
-- Badges livreur (gamification)
-- ============================================
CREATE TABLE IF NOT EXISTS public.livreur_badges (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    livreur_id UUID REFERENCES public.livreurs(id) ON DELETE CASCADE,
    badge_type VARCHAR(50) NOT NULL,
    earned_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(livreur_id, badge_type)
);

-- ============================================
-- TABLE 21: livreur_bonuses
-- Bonus livreur
-- ============================================
CREATE TABLE IF NOT EXISTS public.livreur_bonuses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    livreur_id UUID REFERENCES public.livreurs(id) ON DELETE CASCADE,
    bonus_type VARCHAR(50) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    description TEXT,
    order_id UUID REFERENCES public.orders(id),
    earned_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- TABLE 22: tier_config
-- Configuration des tiers livreur
-- ============================================
CREATE TABLE IF NOT EXISTS public.tier_config (
    tier livreur_tier PRIMARY KEY,
    commission_rate DECIMAL(5,2) NOT NULL,
    min_deliveries INTEGER NOT NULL,
    min_rating DECIMAL(3,2) NOT NULL,
    max_cancellation_rate DECIMAL(5,2) NOT NULL,
    priority_level INTEGER NOT NULL,
    weekend_bonus DECIMAL(5,2) DEFAULT 0,
    description TEXT
);

-- ============================================
-- TABLE 23: livreur_targets
-- Objectifs livreur
-- ============================================
CREATE TABLE IF NOT EXISTS public.livreur_targets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    target_type VARCHAR(20) NOT NULL,
    deliveries_required INTEGER NOT NULL,
    bonus_amount DECIMAL(10,2) NOT NULL,
    is_active BOOLEAN DEFAULT true
);

-- ============================================
-- TABLE 24: referrals
-- Parrainages
-- ============================================
CREATE TABLE IF NOT EXISTS public.referrals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    referrer_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    referred_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    referral_code VARCHAR(20) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'rewarded')),
    referrer_reward DECIMAL(10,2) DEFAULT 500,
    referred_reward DECIMAL(10,2) DEFAULT 300,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    UNIQUE(referred_id)
);

-- ============================================
-- TABLES SECONDAIRES
-- ============================================

-- FCM Tokens
CREATE TABLE IF NOT EXISTS public.fcm_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    token TEXT NOT NULL,
    device_type VARCHAR(20),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, token)
);

-- Menu Item Variants
CREATE TABLE IF NOT EXISTS public.menu_item_variants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    menu_item_id UUID REFERENCES public.menu_items(id) ON DELETE CASCADE,
    name VARCHAR(50) NOT NULL,
    price_adjustment DECIMAL(10, 2) DEFAULT 0,
    is_default BOOLEAN DEFAULT false,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Menu Item Extras
CREATE TABLE IF NOT EXISTS public.menu_item_extras (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    menu_item_id UUID REFERENCES public.menu_items(id) ON DELETE CASCADE,
    name VARCHAR(50) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    is_available BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Menu Item Reviews
CREATE TABLE IF NOT EXISTS public.menu_item_reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    menu_item_id UUID REFERENCES public.menu_items(id) ON DELETE CASCADE,
    customer_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    order_id UUID REFERENCES public.orders(id),
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(order_id, menu_item_id)
);

-- Search History
CREATE TABLE IF NOT EXISTS public.search_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    query VARCHAR(200) NOT NULL,
    searched_at TIMESTAMPTZ DEFAULT NOW()
);

-- Reorder Suggestions
CREATE TABLE IF NOT EXISTS public.reorder_suggestions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    restaurant_id UUID REFERENCES public.restaurants(id) ON DELETE CASCADE,
    items JSONB NOT NULL,
    last_ordered_at TIMESTAMPTZ,
    order_count INTEGER DEFAULT 1,
    UNIQUE(customer_id, restaurant_id)
);

-- ============================================
-- COLONNES CRITIQUES - MAPPING
-- ============================================
-- 
-- ⚠️ NE JAMAIS UTILISER CES NOMS INCORRECTS:
-- 
-- | ❌ INCORRECT      | ✅ CORRECT           |
-- |-------------------|----------------------|
-- | driver_id         | livreur_id           |
-- | delivery_lat      | delivery_latitude    |
-- | delivery_lng      | delivery_longitude   |
-- | total_amount      | total                |
-- | preparing_at      | prepared_at          |
-- | driver_assigned   | confirmed            |
-- 
-- ============================================

-- ============================================
-- FIN DE LA SOURCE DE VÉRITÉ
-- ============================================
SELECT 'Source de vérité créée avec succès - 24 tables principales' AS status;
