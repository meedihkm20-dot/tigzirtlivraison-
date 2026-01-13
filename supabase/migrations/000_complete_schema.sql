-- ============================================================
-- DZ DELIVERY - MIGRATION UNIFIÉE COMPLÈTE
-- ============================================================
-- Cette migration peut être exécutée plusieurs fois sans erreur
-- Elle intègre toutes les migrations (001 à 007) en une seule
-- Exécute ce fichier dans Supabase SQL Editor
-- ============================================================

-- ============================================
-- EXTENSIONS
-- ============================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- ============================================
-- TYPES ENUM (avec vérification)
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
-- TABLE: PROFILES
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
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Colonnes additionnelles profiles
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS fcm_token TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS loyalty_points INTEGER DEFAULT 0;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS total_orders INTEGER DEFAULT 0;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS total_spent DECIMAL(12,2) DEFAULT 0;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS referral_code VARCHAR(10);
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS referred_by UUID REFERENCES public.profiles(id);
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS referral_earnings DECIMAL(10,2) DEFAULT 0;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS phone_verified BOOLEAN DEFAULT false;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS email_verified BOOLEAN DEFAULT false;

-- ============================================
-- TABLE: RESTAURANTS
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
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.restaurants ADD COLUMN IF NOT EXISTS cover_images TEXT[];
ALTER TABLE public.restaurants ADD COLUMN IF NOT EXISTS tags TEXT[];
ALTER TABLE public.restaurants ADD COLUMN IF NOT EXISTS accepts_preorders BOOLEAN DEFAULT false;
ALTER TABLE public.restaurants ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- ============================================
-- TABLE: MENU_CATEGORIES
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
-- TABLE: MENU_ITEMS
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
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Colonnes additionnelles menu_items
ALTER TABLE public.menu_items ADD COLUMN IF NOT EXISTS calories INTEGER;
ALTER TABLE public.menu_items ADD COLUMN IF NOT EXISTS is_vegetarian BOOLEAN DEFAULT false;
ALTER TABLE public.menu_items ADD COLUMN IF NOT EXISTS is_spicy BOOLEAN DEFAULT false;
ALTER TABLE public.menu_items ADD COLUMN IF NOT EXISTS allergens TEXT[];
ALTER TABLE public.menu_items ADD COLUMN IF NOT EXISTS order_count INTEGER DEFAULT 0;
ALTER TABLE public.menu_items ADD COLUMN IF NOT EXISTS image_width INTEGER DEFAULT 500;
ALTER TABLE public.menu_items ADD COLUMN IF NOT EXISTS image_height INTEGER DEFAULT 500;
ALTER TABLE public.menu_items ADD COLUMN IF NOT EXISTS ingredients TEXT[];
ALTER TABLE public.menu_items ADD COLUMN IF NOT EXISTS nutrition_info JSONB;
ALTER TABLE public.menu_items ADD COLUMN IF NOT EXISTS is_daily_special BOOLEAN DEFAULT false;
ALTER TABLE public.menu_items ADD COLUMN IF NOT EXISTS daily_special_price DECIMAL(10,2);
ALTER TABLE public.menu_items ADD COLUMN IF NOT EXISTS avg_rating DECIMAL(3,2) DEFAULT 0;
ALTER TABLE public.menu_items ADD COLUMN IF NOT EXISTS total_reviews INTEGER DEFAULT 0;
ALTER TABLE public.menu_items ADD COLUMN IF NOT EXISTS last_ordered_at TIMESTAMPTZ;
ALTER TABLE public.menu_items ADD COLUMN IF NOT EXISTS tags TEXT[];

-- ============================================
-- TABLE: LIVREURS
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
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Colonnes additionnelles livreurs
ALTER TABLE public.livreurs ADD COLUMN IF NOT EXISTS total_distance_km DECIMAL(10, 2) DEFAULT 0;
ALTER TABLE public.livreurs ADD COLUMN IF NOT EXISTS avg_delivery_time INTEGER;
ALTER TABLE public.livreurs ADD COLUMN IF NOT EXISTS acceptance_rate DECIMAL(5, 2) DEFAULT 100;
ALTER TABLE public.livreurs ADD COLUMN IF NOT EXISTS tier livreur_tier DEFAULT 'bronze';
ALTER TABLE public.livreurs ADD COLUMN IF NOT EXISTS tier_progress INTEGER DEFAULT 0;
ALTER TABLE public.livreurs ADD COLUMN IF NOT EXISTS weekly_deliveries INTEGER DEFAULT 0;
ALTER TABLE public.livreurs ADD COLUMN IF NOT EXISTS monthly_deliveries INTEGER DEFAULT 0;
ALTER TABLE public.livreurs ADD COLUMN IF NOT EXISTS cancellation_rate DECIMAL(5,2) DEFAULT 0;
ALTER TABLE public.livreurs ADD COLUMN IF NOT EXISTS streak_days INTEGER DEFAULT 0;
ALTER TABLE public.livreurs ADD COLUMN IF NOT EXISTS last_active_date DATE;
ALTER TABLE public.livreurs ADD COLUMN IF NOT EXISTS bonus_earned DECIMAL(10,2) DEFAULT 0;
ALTER TABLE public.livreurs ADD COLUMN IF NOT EXISTS fcm_token TEXT;


-- ============================================
-- TABLE: ORDERS
-- ============================================
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_number VARCHAR(20) UNIQUE NOT NULL,
    customer_id UUID REFERENCES public.profiles(id),
    restaurant_id UUID REFERENCES public.restaurants(id),
    livreur_id UUID REFERENCES public.livreurs(id),
    status order_status DEFAULT 'pending',
    delivery_address TEXT NOT NULL,
    delivery_latitude DECIMAL(10, 8) NOT NULL,
    delivery_longitude DECIMAL(11, 8) NOT NULL,
    delivery_instructions TEXT,
    subtotal DECIMAL(10, 2) NOT NULL,
    delivery_fee DECIMAL(10, 2) DEFAULT 0,
    service_fee DECIMAL(10, 2) DEFAULT 0,
    discount DECIMAL(10, 2) DEFAULT 0,
    total DECIMAL(10, 2) NOT NULL,
    payment_method payment_method DEFAULT 'cash',
    payment_status payment_status DEFAULT 'pending',
    estimated_delivery_time TIMESTAMPTZ,
    confirmed_at TIMESTAMPTZ,
    prepared_at TIMESTAMPTZ,
    picked_up_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    cancellation_reason TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Colonnes additionnelles orders
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS confirmation_code VARCHAR(4);
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS livreur_commission DECIMAL(10, 2) DEFAULT 0;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS admin_commission DECIMAL(10, 2) DEFAULT 0;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS restaurant_amount DECIMAL(10, 2) DEFAULT 0;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS livreur_accepted_at TIMESTAMPTZ;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS code_verified_at TIMESTAMPTZ;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS promotion_id UUID;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS promo_code VARCHAR(20);
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS promo_discount DECIMAL(10, 2) DEFAULT 0;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS current_eta_minutes INTEGER;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS distance_remaining_km DECIMAL(10,2);
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS tip_amount DECIMAL(10,2) DEFAULT 0;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS tip_paid_at TIMESTAMPTZ;

-- ============================================
-- TABLE: ORDER_ITEMS
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
-- TABLE: REVIEWS
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
-- TABLE: LIVREUR_LOCATIONS
-- ============================================
CREATE TABLE IF NOT EXISTS public.livreur_locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    livreur_id UUID REFERENCES public.livreurs(id) ON DELETE CASCADE,
    order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    recorded_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.livreur_locations ADD COLUMN IF NOT EXISTS speed DECIMAL(5,2);
ALTER TABLE public.livreur_locations ADD COLUMN IF NOT EXISTS heading DECIMAL(5,2);

-- ============================================
-- TABLE: NOTIFICATIONS
-- ============================================
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    title VARCHAR(100) NOT NULL,
    body TEXT,
    data JSONB,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS notification_type VARCHAR(50) DEFAULT 'system';
ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS sent_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS read_at TIMESTAMPTZ;

-- ============================================
-- TABLE: FCM_TOKENS
-- ============================================
CREATE TABLE IF NOT EXISTS public.fcm_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    token TEXT NOT NULL,
    device_type VARCHAR(20),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, token)
);

-- ============================================
-- TABLE: COMMISSION_SETTINGS
-- ============================================
CREATE TABLE IF NOT EXISTS public.commission_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    livreur_commission_percent DECIMAL(5, 2) DEFAULT 15.00,
    admin_commission_percent DECIMAL(5, 2) DEFAULT 5.00,
    min_delivery_fee DECIMAL(10, 2) DEFAULT 100.00,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO public.commission_settings (livreur_commission_percent, admin_commission_percent, min_delivery_fee)
SELECT 15.00, 5.00, 100.00
WHERE NOT EXISTS (SELECT 1 FROM public.commission_settings);

-- ============================================
-- TABLE: TRANSACTIONS
-- ============================================
CREATE TABLE IF NOT EXISTS public.transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
    type VARCHAR(20) NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    recipient_id UUID,
    status VARCHAR(20) DEFAULT 'pending',
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- TABLE: PROMOTIONS
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
-- TABLE: FAVORITES
-- ============================================
CREATE TABLE IF NOT EXISTS public.favorites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    restaurant_id UUID REFERENCES public.restaurants(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(customer_id, restaurant_id)
);

CREATE TABLE IF NOT EXISTS public.favorite_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    menu_item_id UUID REFERENCES public.menu_items(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(customer_id, menu_item_id)
);

-- ============================================
-- TABLE: MENU_ITEM_VARIANTS & EXTRAS
-- ============================================
CREATE TABLE IF NOT EXISTS public.menu_item_variants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    menu_item_id UUID REFERENCES public.menu_items(id) ON DELETE CASCADE,
    name VARCHAR(50) NOT NULL,
    price_adjustment DECIMAL(10, 2) DEFAULT 0,
    is_default BOOLEAN DEFAULT false,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.menu_item_extras (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    menu_item_id UUID REFERENCES public.menu_items(id) ON DELETE CASCADE,
    name VARCHAR(50) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    is_available BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- TABLE: LIVREUR_BADGES
-- ============================================
CREATE TABLE IF NOT EXISTS public.livreur_badges (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    livreur_id UUID REFERENCES public.livreurs(id) ON DELETE CASCADE,
    badge_type VARCHAR(50) NOT NULL,
    earned_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(livreur_id, badge_type)
);

-- ============================================
-- TABLE: LIVREUR_BONUSES
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
-- TABLE: TIER_CONFIG
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

INSERT INTO public.tier_config VALUES
    ('bronze', 10.0, 0, 0, 100, 1, 0, 'Nouveau livreur'),
    ('silver', 12.0, 50, 3.8, 15, 2, 3, 'Livreur régulier'),
    ('gold', 14.0, 150, 4.2, 10, 3, 5, 'Livreur expert'),
    ('diamond', 16.0, 400, 4.6, 5, 4, 8, 'Livreur élite')
ON CONFLICT (tier) DO NOTHING;

-- ============================================
-- TABLE: LIVREUR_TARGETS
-- ============================================
CREATE TABLE IF NOT EXISTS public.livreur_targets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    target_type VARCHAR(20) NOT NULL,
    deliveries_required INTEGER NOT NULL,
    bonus_amount DECIMAL(10,2) NOT NULL,
    is_active BOOLEAN DEFAULT true
);

INSERT INTO public.livreur_targets (id, target_type, deliveries_required, bonus_amount, is_active)
SELECT uuid_generate_v4(), 'daily', 8, 300, true WHERE NOT EXISTS (SELECT 1 FROM public.livreur_targets WHERE target_type = 'daily' AND deliveries_required = 8);
INSERT INTO public.livreur_targets (id, target_type, deliveries_required, bonus_amount, is_active)
SELECT uuid_generate_v4(), 'daily', 12, 600, true WHERE NOT EXISTS (SELECT 1 FROM public.livreur_targets WHERE target_type = 'daily' AND deliveries_required = 12);
INSERT INTO public.livreur_targets (id, target_type, deliveries_required, bonus_amount, is_active)
SELECT uuid_generate_v4(), 'weekly', 40, 2000, true WHERE NOT EXISTS (SELECT 1 FROM public.livreur_targets WHERE target_type = 'weekly' AND deliveries_required = 40);
INSERT INTO public.livreur_targets (id, target_type, deliveries_required, bonus_amount, is_active)
SELECT uuid_generate_v4(), 'weekly', 60, 4000, true WHERE NOT EXISTS (SELECT 1 FROM public.livreur_targets WHERE target_type = 'weekly' AND deliveries_required = 60);
INSERT INTO public.livreur_targets (id, target_type, deliveries_required, bonus_amount, is_active)
SELECT uuid_generate_v4(), 'monthly', 180, 12000, true WHERE NOT EXISTS (SELECT 1 FROM public.livreur_targets WHERE target_type = 'monthly' AND deliveries_required = 180);


-- ============================================
-- TABLE: MENU_ITEM_REVIEWS
-- ============================================
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

-- ============================================
-- TABLE: DELIVERY_PRICING
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

INSERT INTO public.delivery_pricing (name, base_fee, per_km_fee, min_fee, max_fee)
SELECT 'standard', 100, 30, 100, 500
WHERE NOT EXISTS (SELECT 1 FROM public.delivery_pricing WHERE name = 'standard');

-- ============================================
-- TABLE: DELIVERY_ZONES
-- ============================================
CREATE TABLE IF NOT EXISTS public.delivery_zones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    polygon JSONB NOT NULL,
    fee_adjustment DECIMAL(10,2) DEFAULT 0,
    is_active BOOLEAN DEFAULT true
);

-- ============================================
-- TABLE: SEARCH_HISTORY
-- ============================================
CREATE TABLE IF NOT EXISTS public.search_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    query VARCHAR(200) NOT NULL,
    searched_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- TABLE: SAVED_ADDRESSES
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
-- TABLE: REORDER_SUGGESTIONS
-- ============================================
CREATE TABLE IF NOT EXISTS public.reorder_suggestions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    restaurant_id UUID REFERENCES public.restaurants(id) ON DELETE CASCADE,
    items JSONB NOT NULL,
    last_ordered_at TIMESTAMPTZ,
    order_count INTEGER DEFAULT 1
);

-- Contrainte unique pour reorder_suggestions
DO $$ BEGIN
    ALTER TABLE public.reorder_suggestions 
    ADD CONSTRAINT reorder_suggestions_customer_restaurant_key 
    UNIQUE (customer_id, restaurant_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ============================================
-- TABLE: ORDER_MESSAGES (Chat)
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
-- TABLE: REFERRALS
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
-- INDEXES
-- ============================================
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_phone ON public.profiles(phone);
CREATE INDEX IF NOT EXISTS idx_profiles_referral_code ON public.profiles(referral_code);

CREATE INDEX IF NOT EXISTS idx_restaurants_owner ON public.restaurants(owner_id);
CREATE INDEX IF NOT EXISTS idx_restaurants_location ON public.restaurants(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_restaurants_cuisine ON public.restaurants(cuisine_type);
CREATE INDEX IF NOT EXISTS idx_restaurants_is_open ON public.restaurants(is_open);

CREATE INDEX IF NOT EXISTS idx_menu_items_restaurant ON public.menu_items(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_menu_items_category ON public.menu_items(category_id);
CREATE INDEX IF NOT EXISTS idx_menu_items_available ON public.menu_items(is_available);
CREATE INDEX IF NOT EXISTS idx_menu_items_popular ON public.menu_items(restaurant_id, order_count DESC);
CREATE INDEX IF NOT EXISTS idx_menu_items_daily ON public.menu_items(restaurant_id, is_daily_special) WHERE is_daily_special = true;
CREATE INDEX IF NOT EXISTS idx_menu_items_rating ON public.menu_items(restaurant_id, avg_rating DESC);

CREATE INDEX IF NOT EXISTS idx_livreurs_user ON public.livreurs(user_id);
CREATE INDEX IF NOT EXISTS idx_livreurs_location ON public.livreurs(current_latitude, current_longitude);
CREATE INDEX IF NOT EXISTS idx_livreurs_available ON public.livreurs(is_available, is_online);
CREATE INDEX IF NOT EXISTS idx_livreur_tier ON public.livreurs(tier, is_available);

CREATE INDEX IF NOT EXISTS idx_orders_customer ON public.orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_restaurant ON public.orders(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_orders_livreur ON public.orders(livreur_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created ON public.orders(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_orders_confirmation_code ON public.orders(confirmation_code);

CREATE INDEX IF NOT EXISTS idx_livreur_locations_livreur ON public.livreur_locations(livreur_id);
CREATE INDEX IF NOT EXISTS idx_livreur_locations_order ON public.livreur_locations(order_id);
CREATE INDEX IF NOT EXISTS idx_livreur_locations_time ON public.livreur_locations(recorded_at DESC);

CREATE INDEX IF NOT EXISTS idx_notifications_user ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON public.notifications(user_id, is_read) WHERE is_read = false;
CREATE INDEX IF NOT EXISTS idx_notifications_type ON public.notifications(notification_type);

CREATE INDEX IF NOT EXISTS idx_transactions_order_id ON public.transactions(order_id);
CREATE INDEX IF NOT EXISTS idx_transactions_recipient ON public.transactions(recipient_id);
CREATE INDEX IF NOT EXISTS idx_transactions_type ON public.transactions(type);

CREATE INDEX IF NOT EXISTS idx_promotions_restaurant ON public.promotions(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_promotions_active ON public.promotions(is_active, starts_at, ends_at);
CREATE INDEX IF NOT EXISTS idx_promotions_code ON public.promotions(code) WHERE code IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_favorites_customer ON public.favorites(customer_id);
CREATE INDEX IF NOT EXISTS idx_favorite_items_customer ON public.favorite_items(customer_id);

CREATE INDEX IF NOT EXISTS idx_saved_addresses ON public.saved_addresses(customer_id);
CREATE INDEX IF NOT EXISTS idx_livreur_bonuses ON public.livreur_bonuses(livreur_id, earned_at);

CREATE INDEX IF NOT EXISTS idx_order_messages_order ON public.order_messages(order_id, created_at);
CREATE INDEX IF NOT EXISTS idx_referrals_referrer ON public.referrals(referrer_id);
CREATE INDEX IF NOT EXISTS idx_referrals_code ON public.referrals(referral_code);


-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

-- Enable RLS on all tables
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
ALTER TABLE public.fcm_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.promotions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favorite_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menu_item_variants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menu_item_extras ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.livreur_badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.livreur_bonuses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.search_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saved_addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menu_item_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referrals ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to recreate them
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname, tablename FROM pg_policies WHERE schemaname = 'public') LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', r.policyname, r.tablename);
    END LOOP;
END $$;

-- PROFILES POLICIES
CREATE POLICY "Public profiles are viewable by everyone" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Users can update their own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- RESTAURANTS POLICIES
CREATE POLICY "Restaurants are viewable by everyone" ON public.restaurants FOR SELECT USING (true);
CREATE POLICY "Restaurant owners can update their restaurant" ON public.restaurants FOR UPDATE USING (auth.uid() = owner_id);
CREATE POLICY "Restaurant owners can insert their restaurant" ON public.restaurants FOR INSERT WITH CHECK (auth.uid() = owner_id);

-- MENU POLICIES
CREATE POLICY "Menu categories are viewable by everyone" ON public.menu_categories FOR SELECT USING (true);
CREATE POLICY "Menu items are viewable by everyone" ON public.menu_items FOR SELECT USING (true);
CREATE POLICY "Restaurant owners can manage menu categories" ON public.menu_categories FOR ALL
    USING (EXISTS (SELECT 1 FROM public.restaurants WHERE id = menu_categories.restaurant_id AND owner_id = auth.uid()));
CREATE POLICY "Restaurant owners can manage menu items" ON public.menu_items FOR ALL
    USING (EXISTS (SELECT 1 FROM public.restaurants WHERE id = menu_items.restaurant_id AND owner_id = auth.uid()));

-- LIVREURS POLICIES
CREATE POLICY "Livreurs are viewable by everyone" ON public.livreurs FOR SELECT USING (true);
CREATE POLICY "Livreurs can update their own data" ON public.livreurs FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Livreurs can insert their own data" ON public.livreurs FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ORDERS POLICIES
CREATE POLICY "Customers can view their orders" ON public.orders FOR SELECT USING (auth.uid() = customer_id);
CREATE POLICY "Restaurants can view their orders" ON public.orders FOR SELECT
    USING (EXISTS (SELECT 1 FROM public.restaurants WHERE id = orders.restaurant_id AND owner_id = auth.uid()));
CREATE POLICY "Livreurs can view assigned orders" ON public.orders FOR SELECT
    USING (EXISTS (SELECT 1 FROM public.livreurs WHERE id = orders.livreur_id AND user_id = auth.uid()));
CREATE POLICY "Livreurs can view available orders" ON public.orders FOR SELECT
    USING (status = 'pending' AND livreur_id IS NULL);
CREATE POLICY "Customers can create orders" ON public.orders FOR INSERT WITH CHECK (auth.uid() = customer_id);
CREATE POLICY "Involved parties can update orders" ON public.orders FOR UPDATE
    USING (auth.uid() = customer_id
        OR EXISTS (SELECT 1 FROM public.restaurants WHERE id = orders.restaurant_id AND owner_id = auth.uid())
        OR EXISTS (SELECT 1 FROM public.livreurs WHERE id = orders.livreur_id AND user_id = auth.uid()));

-- ORDER ITEMS POLICIES
CREATE POLICY "Order items follow order access" ON public.order_items FOR SELECT
    USING (EXISTS (SELECT 1 FROM public.orders WHERE id = order_items.order_id
        AND (customer_id = auth.uid() OR EXISTS (SELECT 1 FROM public.restaurants WHERE id = orders.restaurant_id AND owner_id = auth.uid()))));
CREATE POLICY "Customers can insert order items" ON public.order_items FOR INSERT
    WITH CHECK (EXISTS (SELECT 1 FROM public.orders WHERE id = order_items.order_id AND customer_id = auth.uid()));

-- REVIEWS POLICIES
CREATE POLICY "Reviews are viewable by everyone" ON public.reviews FOR SELECT USING (true);
CREATE POLICY "Customers can create reviews for their orders" ON public.reviews FOR INSERT WITH CHECK (auth.uid() = customer_id);

-- LIVREUR LOCATIONS POLICIES
CREATE POLICY "Livreur locations viewable by involved parties" ON public.livreur_locations FOR SELECT
    USING (EXISTS (SELECT 1 FROM public.orders WHERE id = livreur_locations.order_id
        AND (customer_id = auth.uid() OR EXISTS (SELECT 1 FROM public.restaurants WHERE id = orders.restaurant_id AND owner_id = auth.uid())))
        OR EXISTS (SELECT 1 FROM public.livreurs WHERE id = livreur_locations.livreur_id AND user_id = auth.uid()));
CREATE POLICY "Livreurs can insert their locations" ON public.livreur_locations FOR INSERT
    WITH CHECK (EXISTS (SELECT 1 FROM public.livreurs WHERE id = livreur_locations.livreur_id AND user_id = auth.uid()));

-- NOTIFICATIONS POLICIES
CREATE POLICY "Users can view their notifications" ON public.notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update their notifications" ON public.notifications FOR UPDATE USING (auth.uid() = user_id);

-- FCM TOKENS POLICIES
CREATE POLICY "Users can manage their FCM tokens" ON public.fcm_tokens FOR ALL USING (auth.uid() = user_id);

-- TRANSACTIONS POLICIES
CREATE POLICY "Admin full access transactions" ON public.transactions FOR ALL
    USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));
CREATE POLICY "Livreurs view own transactions" ON public.transactions FOR SELECT USING (recipient_id = auth.uid());
CREATE POLICY "Restaurants view own transactions" ON public.transactions FOR SELECT USING (recipient_id = auth.uid());

-- PROMOTIONS POLICIES
CREATE POLICY "Promotions viewable by everyone" ON public.promotions FOR SELECT USING (true);
CREATE POLICY "Restaurant owners manage promotions" ON public.promotions FOR ALL
    USING (EXISTS (SELECT 1 FROM public.restaurants WHERE id = promotions.restaurant_id AND owner_id = auth.uid()));

-- FAVORITES POLICIES
CREATE POLICY "Users manage their favorites" ON public.favorites FOR ALL USING (auth.uid() = customer_id);
CREATE POLICY "Users manage their favorite items" ON public.favorite_items FOR ALL USING (auth.uid() = customer_id);

-- VARIANTS/EXTRAS POLICIES
CREATE POLICY "Variants viewable by everyone" ON public.menu_item_variants FOR SELECT USING (true);
CREATE POLICY "Extras viewable by everyone" ON public.menu_item_extras FOR SELECT USING (true);
CREATE POLICY "Restaurant owners manage variants" ON public.menu_item_variants FOR ALL
    USING (EXISTS (SELECT 1 FROM public.menu_items mi JOIN public.restaurants r ON mi.restaurant_id = r.id 
                   WHERE mi.id = menu_item_variants.menu_item_id AND r.owner_id = auth.uid()));
CREATE POLICY "Restaurant owners manage extras" ON public.menu_item_extras FOR ALL
    USING (EXISTS (SELECT 1 FROM public.menu_items mi JOIN public.restaurants r ON mi.restaurant_id = r.id 
                   WHERE mi.id = menu_item_extras.menu_item_id AND r.owner_id = auth.uid()));

-- BADGES POLICIES
CREATE POLICY "Badges viewable by everyone" ON public.livreur_badges FOR SELECT USING (true);

-- BONUSES POLICIES
CREATE POLICY "Livreurs see own bonuses" ON public.livreur_bonuses FOR SELECT 
    USING (EXISTS (SELECT 1 FROM public.livreurs WHERE id = livreur_bonuses.livreur_id AND user_id = auth.uid()));

-- SEARCH HISTORY POLICIES
CREATE POLICY "Users manage own search history" ON public.search_history FOR ALL USING (auth.uid() = customer_id);

-- SAVED ADDRESSES POLICIES
CREATE POLICY "Users manage own addresses" ON public.saved_addresses FOR ALL USING (auth.uid() = customer_id);

-- MENU ITEM REVIEWS POLICIES
CREATE POLICY "Anyone can read menu reviews" ON public.menu_item_reviews FOR SELECT USING (true);
CREATE POLICY "Customers write menu reviews" ON public.menu_item_reviews FOR INSERT WITH CHECK (auth.uid() = customer_id);

-- ORDER MESSAGES POLICIES
CREATE POLICY "Order participants can view messages" ON public.order_messages FOR SELECT
    USING (EXISTS (SELECT 1 FROM public.orders o WHERE o.id = order_messages.order_id
        AND (o.customer_id = auth.uid() OR o.livreur_id IN (SELECT id FROM public.livreurs WHERE user_id = auth.uid()))));
CREATE POLICY "Order participants can send messages" ON public.order_messages FOR INSERT WITH CHECK (auth.uid() = sender_id);

-- REFERRALS POLICIES
CREATE POLICY "Users can see their referrals" ON public.referrals FOR SELECT
    USING (auth.uid() = referrer_id OR auth.uid() = referred_id);


-- ============================================
-- FUNCTIONS
-- ============================================

-- Updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, phone, role, phone_verified)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
        COALESCE(NEW.raw_user_meta_data->>'phone', ''),
        COALESCE((NEW.raw_user_meta_data->>'role')::user_role, 'customer'),
        COALESCE((NEW.raw_user_meta_data->>'phone_verified')::boolean, false)
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Generate order number
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

-- Generate confirmation code
CREATE OR REPLACE FUNCTION generate_confirmation_code()
RETURNS TRIGGER AS $$
BEGIN
    NEW.confirmation_code = LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Calculate commissions
CREATE OR REPLACE FUNCTION calculate_commissions()
RETURNS TRIGGER AS $$
DECLARE
    settings RECORD;
    total_amount DECIMAL;
    livreur_comm DECIMAL;
    admin_comm DECIMAL;
    restaurant_amt DECIMAL;
BEGIN
    SELECT * INTO settings FROM public.commission_settings LIMIT 1;
    total_amount := NEW.total;
    livreur_comm := GREATEST(NEW.delivery_fee, COALESCE(settings.min_delivery_fee, 100));
    admin_comm := (total_amount * COALESCE(settings.admin_commission_percent, 5) / 100);
    restaurant_amt := total_amount - admin_comm - NEW.delivery_fee;
    
    NEW.livreur_commission := livreur_comm;
    NEW.admin_commission := admin_comm;
    NEW.restaurant_amount := restaurant_amt;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Update restaurant rating
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

-- Update livreur rating
CREATE OR REPLACE FUNCTION update_livreur_rating()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.livreurs
    SET rating = (SELECT COALESCE(AVG(livreur_rating), 5.0) FROM public.reviews WHERE livreur_id = NEW.livreur_id AND livreur_rating IS NOT NULL)
    WHERE id = NEW.livreur_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Verify confirmation code
CREATE OR REPLACE FUNCTION verify_confirmation_code(p_order_id UUID, p_code VARCHAR(4))
RETURNS BOOLEAN AS $$
DECLARE
    stored_code VARCHAR(4);
BEGIN
    SELECT confirmation_code INTO stored_code FROM public.orders WHERE id = p_order_id;
    
    IF stored_code = p_code THEN
        UPDATE public.orders
        SET code_verified_at = NOW(), status = 'delivered', delivered_at = NOW()
        WHERE id = p_order_id;
        RETURN TRUE;
    END IF;
    
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

-- Create delivery transactions
CREATE OR REPLACE FUNCTION create_delivery_transactions()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'delivered' AND OLD.status != 'delivered' THEN
        -- Transaction pour le livreur
        INSERT INTO public.transactions (order_id, type, amount, recipient_id, status, description)
        SELECT NEW.id, 'livreur_earning', NEW.livreur_commission, l.user_id, 'completed', 'Commission livraison #' || NEW.order_number
        FROM public.livreurs l WHERE l.id = NEW.livreur_id;
        
        -- Transaction pour l'admin
        INSERT INTO public.transactions (order_id, type, amount, recipient_id, status, description)
        VALUES (NEW.id, 'admin_commission', NEW.admin_commission, NULL, 'completed', 'Commission admin #' || NEW.order_number);
        
        -- Transaction pour le restaurant
        INSERT INTO public.transactions (order_id, type, amount, recipient_id, status, description)
        SELECT NEW.id, 'restaurant_payment', NEW.restaurant_amount, r.owner_id, 'pending', 'Paiement restaurant #' || NEW.order_number
        FROM public.restaurants r WHERE r.id = NEW.restaurant_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Get nearby restaurants
CREATE OR REPLACE FUNCTION get_nearby_restaurants(user_lat DECIMAL, user_lng DECIMAL, radius_km DECIMAL DEFAULT 10)
RETURNS TABLE (
    id UUID, name VARCHAR, description TEXT, logo_url TEXT, cuisine_type VARCHAR,
    rating DECIMAL, delivery_fee DECIMAL, avg_prep_time INTEGER, distance_km DECIMAL, is_open BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT r.id, r.name, r.description, r.logo_url, r.cuisine_type, r.rating, r.delivery_fee, r.avg_prep_time,
        (6371 * acos(cos(radians(user_lat)) * cos(radians(r.latitude)) * cos(radians(r.longitude) - radians(user_lng)) + sin(radians(user_lat)) * sin(radians(r.latitude))))::DECIMAL AS distance_km,
        r.is_open
    FROM public.restaurants r
    WHERE r.is_verified = true
    AND (6371 * acos(cos(radians(user_lat)) * cos(radians(r.latitude)) * cos(radians(r.longitude) - radians(user_lng)) + sin(radians(user_lat)) * sin(radians(r.latitude)))) <= radius_km
    ORDER BY distance_km;
END;
$$ LANGUAGE plpgsql;

-- Get available livreurs
CREATE OR REPLACE FUNCTION get_available_livreurs(restaurant_lat DECIMAL, restaurant_lng DECIMAL, radius_km DECIMAL DEFAULT 5)
RETURNS TABLE (id UUID, user_id UUID, full_name VARCHAR, phone VARCHAR, vehicle_type vehicle_type, rating DECIMAL, distance_km DECIMAL) AS $$
BEGIN
    RETURN QUERY
    SELECT l.id, l.user_id, p.full_name, p.phone, l.vehicle_type, l.rating,
        (6371 * acos(cos(radians(restaurant_lat)) * cos(radians(l.current_latitude)) * cos(radians(l.current_longitude) - radians(restaurant_lng)) + sin(radians(restaurant_lat)) * sin(radians(l.current_latitude))))::DECIMAL AS distance_km
    FROM public.livreurs l
    JOIN public.profiles p ON p.id = l.user_id
    WHERE l.is_available = true AND l.is_online = true AND l.is_verified = true AND l.current_latitude IS NOT NULL
    AND (6371 * acos(cos(radians(restaurant_lat)) * cos(radians(l.current_latitude)) * cos(radians(l.current_longitude) - radians(restaurant_lng)) + sin(radians(restaurant_lat)) * sin(radians(l.current_latitude)))) <= radius_km
    ORDER BY distance_km;
END;
$$ LANGUAGE plpgsql;

-- Get restaurant stats
CREATE OR REPLACE FUNCTION get_restaurant_stats(restaurant_uuid UUID)
RETURNS TABLE (total_orders BIGINT, total_revenue DECIMAL, orders_today BIGINT, revenue_today DECIMAL, avg_order_value DECIMAL, pending_orders BIGINT) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::BIGINT, COALESCE(SUM(total), 0),
        COUNT(*) FILTER (WHERE DATE(created_at) = CURRENT_DATE)::BIGINT,
        COALESCE(SUM(total) FILTER (WHERE DATE(created_at) = CURRENT_DATE), 0),
        COALESCE(AVG(total), 0),
        COUNT(*) FILTER (WHERE status IN ('pending', 'confirmed', 'preparing'))::BIGINT
    FROM public.orders WHERE orders.restaurant_id = restaurant_uuid AND status != 'cancelled';
END;
$$ LANGUAGE plpgsql;

-- Get admin stats
CREATE OR REPLACE FUNCTION get_admin_stats()
RETURNS TABLE (total_orders BIGINT, total_revenue DECIMAL, total_admin_commission DECIMAL, today_orders BIGINT, today_commission DECIMAL, pending_restaurant_payments DECIMAL) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::BIGINT, COALESCE(SUM(total), 0), COALESCE(SUM(admin_commission), 0),
        COUNT(*) FILTER (WHERE DATE(created_at) = CURRENT_DATE)::BIGINT,
        COALESCE(SUM(admin_commission) FILTER (WHERE DATE(created_at) = CURRENT_DATE), 0),
        COALESCE((SELECT SUM(amount) FROM public.transactions WHERE type = 'restaurant_payment' AND status = 'pending'), 0)
    FROM public.orders WHERE status = 'delivered';
END;
$$ LANGUAGE plpgsql;


-- Apply promotion
CREATE OR REPLACE FUNCTION apply_promotion(p_order_id UUID, p_promo_code VARCHAR)
RETURNS TABLE (success BOOLEAN, discount DECIMAL, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_promo RECORD;
    v_order RECORD;
    v_discount DECIMAL;
BEGIN
    SELECT * INTO v_order FROM public.orders WHERE id = p_order_id;
    IF NOT FOUND THEN
        RETURN QUERY SELECT false, 0::DECIMAL, 'Commande non trouvée'::TEXT;
        RETURN;
    END IF;

    SELECT * INTO v_promo FROM public.promotions 
    WHERE code = p_promo_code AND is_active = true
    AND (starts_at IS NULL OR starts_at <= NOW())
    AND (ends_at IS NULL OR ends_at >= NOW())
    AND (usage_limit IS NULL OR usage_count < usage_limit)
    AND (restaurant_id IS NULL OR restaurant_id = v_order.restaurant_id);

    IF NOT FOUND THEN
        RETURN QUERY SELECT false, 0::DECIMAL, 'Code promo invalide ou expiré'::TEXT;
        RETURN;
    END IF;

    IF v_order.subtotal < v_promo.min_order_amount THEN
        RETURN QUERY SELECT false, 0::DECIMAL, ('Minimum de commande: ' || v_promo.min_order_amount || ' DA')::TEXT;
        RETURN;
    END IF;

    IF v_promo.discount_type = 'percentage' THEN
        v_discount := v_order.subtotal * v_promo.discount_value / 100;
        IF v_promo.max_discount IS NOT NULL AND v_discount > v_promo.max_discount THEN
            v_discount := v_promo.max_discount;
        END IF;
    ELSE
        v_discount := v_promo.discount_value;
    END IF;

    UPDATE public.orders SET 
        promotion_id = v_promo.id, promo_code = p_promo_code, promo_discount = v_discount,
        discount = v_discount, total = subtotal + delivery_fee + service_fee - v_discount
    WHERE id = p_order_id;

    UPDATE public.promotions SET usage_count = usage_count + 1 WHERE id = v_promo.id;

    RETURN QUERY SELECT true, v_discount, ('Réduction de ' || v_discount || ' DA appliquée!')::TEXT;
END;
$$;

-- Submit review
CREATE OR REPLACE FUNCTION submit_review(p_order_id UUID, p_restaurant_rating INTEGER, p_livreur_rating INTEGER, p_comment TEXT DEFAULT NULL)
RETURNS BOOLEAN
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_order RECORD;
BEGIN
    SELECT * INTO v_order FROM public.orders WHERE id = p_order_id AND status = 'delivered';
    IF NOT FOUND THEN RETURN false; END IF;
    IF v_order.customer_id != auth.uid() THEN RETURN false; END IF;

    INSERT INTO public.reviews (order_id, customer_id, restaurant_id, livreur_id, restaurant_rating, livreur_rating, comment)
    VALUES (p_order_id, auth.uid(), v_order.restaurant_id, v_order.livreur_id, p_restaurant_rating, p_livreur_rating, p_comment)
    ON CONFLICT (order_id) DO UPDATE SET
        restaurant_rating = p_restaurant_rating, livreur_rating = p_livreur_rating, comment = p_comment;

    RETURN true;
END;
$$;

-- Calculate livreur commission based on tier
CREATE OR REPLACE FUNCTION calculate_livreur_commission(p_livreur_id UUID, p_delivery_fee DECIMAL)
RETURNS DECIMAL
LANGUAGE plpgsql AS $$
DECLARE
    v_tier livreur_tier;
    v_commission_rate DECIMAL;
    v_is_weekend BOOLEAN;
    v_weekend_bonus DECIMAL;
    v_base_commission DECIMAL;
BEGIN
    SELECT tier INTO v_tier FROM public.livreurs WHERE id = p_livreur_id;
    SELECT commission_rate, weekend_bonus INTO v_commission_rate, v_weekend_bonus FROM public.tier_config WHERE tier = v_tier;
    v_is_weekend := EXTRACT(DOW FROM NOW()) IN (0, 6);
    v_base_commission := p_delivery_fee * (COALESCE(v_commission_rate, 10) / 100);
    IF v_is_weekend THEN
        v_base_commission := v_base_commission * (1 + COALESCE(v_weekend_bonus, 0) / 100);
    END IF;
    RETURN ROUND(v_base_commission, 2);
END;
$$;

-- Update livreur tier
CREATE OR REPLACE FUNCTION update_livreur_tier()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
DECLARE
    v_new_tier livreur_tier;
    v_deliveries INTEGER;
    v_rating DECIMAL;
    v_cancel_rate DECIMAL;
BEGIN
    v_deliveries := NEW.total_deliveries;
    v_rating := COALESCE(NEW.rating, 5.0);
    v_cancel_rate := COALESCE(NEW.cancellation_rate, 0);
    
    IF v_deliveries >= 400 AND v_rating >= 4.6 AND v_cancel_rate <= 5 THEN
        v_new_tier := 'diamond';
    ELSIF v_deliveries >= 150 AND v_rating >= 4.2 AND v_cancel_rate <= 10 THEN
        v_new_tier := 'gold';
    ELSIF v_deliveries >= 50 AND v_rating >= 3.8 AND v_cancel_rate <= 15 THEN
        v_new_tier := 'silver';
    ELSE
        v_new_tier := 'bronze';
    END IF;
    
    IF NEW.tier IS DISTINCT FROM v_new_tier THEN
        NEW.tier := v_new_tier;
        INSERT INTO public.notifications (user_id, title, body, notification_type, data)
        SELECT user_id, 
            CASE v_new_tier 
                WHEN 'diamond' THEN '💎 Félicitations! Niveau Diamant!'
                WHEN 'gold' THEN '🥇 Bravo! Niveau Or atteint!'
                WHEN 'silver' THEN '🥈 Niveau Argent débloqué!'
                ELSE '🥉 Bienvenue niveau Bronze'
            END,
            'Votre nouveau taux de commission: ' || (SELECT commission_rate FROM public.tier_config WHERE tier = v_new_tier) || '%',
            'tier_change',
            jsonb_build_object('new_tier', v_new_tier::text)
        FROM public.livreurs WHERE id = NEW.id;
    END IF;
    
    RETURN NEW;
END;
$$;

-- Check livreur daily bonus
CREATE OR REPLACE FUNCTION check_livreur_daily_bonus(p_livreur_id UUID)
RETURNS VOID
LANGUAGE plpgsql AS $$
DECLARE
    v_today_deliveries INTEGER;
    v_target RECORD;
    v_already_earned BOOLEAN;
BEGIN
    SELECT COUNT(*) INTO v_today_deliveries FROM public.orders
    WHERE livreur_id = p_livreur_id AND status = 'delivered' AND DATE(delivered_at) = CURRENT_DATE;
    
    FOR v_target IN SELECT * FROM public.livreur_targets WHERE target_type = 'daily' AND is_active = true LOOP
        SELECT EXISTS (SELECT 1 FROM public.livreur_bonuses 
            WHERE livreur_id = p_livreur_id AND bonus_type = 'daily_target'
            AND amount = v_target.bonus_amount AND DATE(earned_at) = CURRENT_DATE) INTO v_already_earned;
        
        IF NOT v_already_earned AND v_today_deliveries >= v_target.deliveries_required THEN
            INSERT INTO public.livreur_bonuses (livreur_id, bonus_type, amount, description)
            VALUES (p_livreur_id, 'daily_target', v_target.bonus_amount, v_target.deliveries_required || ' livraisons aujourd''hui!');
            
            UPDATE public.livreurs SET bonus_earned = bonus_earned + v_target.bonus_amount WHERE id = p_livreur_id;
        END IF;
    END LOOP;
END;
$$;

-- Calculate delivery fee
CREATE OR REPLACE FUNCTION calculate_delivery_fee(p_restaurant_lat DECIMAL, p_restaurant_lng DECIMAL, p_customer_lat DECIMAL, p_customer_lng DECIMAL)
RETURNS TABLE (distance_km DECIMAL, base_fee DECIMAL, distance_fee DECIMAL, total_fee DECIMAL, estimated_time INTEGER)
LANGUAGE plpgsql AS $$
DECLARE
    v_distance DECIMAL;
    v_pricing RECORD;
    v_base DECIMAL;
    v_per_km DECIMAL;
    v_total DECIMAL;
    v_time INTEGER;
BEGIN
    v_distance := 6371 * ACOS(COS(RADIANS(p_restaurant_lat)) * COS(RADIANS(p_customer_lat)) * COS(RADIANS(p_customer_lng) - RADIANS(p_restaurant_lng)) + SIN(RADIANS(p_restaurant_lat)) * SIN(RADIANS(p_customer_lat)));
    SELECT * INTO v_pricing FROM public.delivery_pricing WHERE is_active = true LIMIT 1;
    v_base := COALESCE(v_pricing.base_fee, 100);
    v_per_km := COALESCE(v_pricing.per_km_fee, 30);
    v_total := v_base + (v_distance * v_per_km);
    v_total := GREATEST(COALESCE(v_pricing.min_fee, 100), LEAST(v_total, COALESCE(v_pricing.max_fee, 500)));
    v_time := CEIL(v_distance * 3) + 10;
    
    RETURN QUERY SELECT ROUND(v_distance, 2), v_base, ROUND(v_distance * v_per_km, 2), ROUND(v_total, 0), v_time;
END;
$$;

-- Get top restaurants
CREATE OR REPLACE FUNCTION get_top_restaurants(p_limit INTEGER DEFAULT 10)
RETURNS TABLE (id UUID, name VARCHAR, logo_url TEXT, cover_url TEXT, cuisine_type VARCHAR, rating DECIMAL, total_reviews INTEGER, total_orders INTEGER, avg_delivery_time INTEGER)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT r.id, r.name, r.logo_url, r.cover_url, r.cuisine_type, COALESCE(r.rating, 0)::DECIMAL, COALESCE(r.total_reviews, 0),
        COALESCE((SELECT COUNT(*) FROM public.orders WHERE restaurant_id = r.id AND status = 'delivered'), 0)::INTEGER,
        COALESCE(r.avg_prep_time, 30)
    FROM public.restaurants r
    WHERE r.is_verified = true AND r.is_open = true
    ORDER BY r.rating DESC NULLS LAST, r.total_reviews DESC
    LIMIT p_limit;
END;
$$;

-- Get top menu items
CREATE OR REPLACE FUNCTION get_top_menu_items(p_restaurant_id UUID DEFAULT NULL, p_limit INTEGER DEFAULT 20)
RETURNS TABLE (id UUID, name VARCHAR, description TEXT, price DECIMAL, image_url TEXT, restaurant_id UUID, restaurant_name VARCHAR, avg_rating DECIMAL, order_count INTEGER, is_daily_special BOOLEAN)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT mi.id, mi.name, mi.description, mi.price, mi.image_url, mi.restaurant_id, r.name,
        COALESCE(mi.avg_rating, 0)::DECIMAL, COALESCE(mi.order_count, 0), COALESCE(mi.is_daily_special, false)
    FROM public.menu_items mi
    JOIN public.restaurants r ON mi.restaurant_id = r.id
    WHERE mi.is_available = true AND r.is_verified = true
    AND (p_restaurant_id IS NULL OR mi.restaurant_id = p_restaurant_id)
    ORDER BY mi.order_count DESC, mi.avg_rating DESC
    LIMIT p_limit;
END;
$$;

-- After delivery complete
CREATE OR REPLACE FUNCTION after_delivery_complete()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
DECLARE
    v_commission DECIMAL;
BEGIN
    IF NEW.status = 'delivered' AND OLD.status != 'delivered' THEN
        v_commission := calculate_livreur_commission(NEW.livreur_id, NEW.delivery_fee);
        NEW.livreur_commission := v_commission;
        
        UPDATE public.livreurs SET
            total_deliveries = total_deliveries + 1,
            total_earnings = total_earnings + v_commission,
            weekly_deliveries = weekly_deliveries + 1,
            monthly_deliveries = monthly_deliveries + 1,
            last_active_date = CURRENT_DATE,
            streak_days = CASE 
                WHEN last_active_date = CURRENT_DATE - 1 THEN streak_days + 1
                WHEN last_active_date = CURRENT_DATE THEN streak_days
                ELSE 1
            END
        WHERE id = NEW.livreur_id;
        
        PERFORM check_livreur_daily_bonus(NEW.livreur_id);
        
        UPDATE public.profiles SET
            total_orders = total_orders + 1,
            total_spent = total_spent + NEW.total,
            loyalty_points = loyalty_points + FLOOR(NEW.total / 100)
        WHERE id = NEW.customer_id;
        
        UPDATE public.menu_items mi SET
            order_count = order_count + oi.quantity,
            last_ordered_at = NOW()
        FROM public.order_items oi
        WHERE oi.order_id = NEW.id AND mi.id = oi.menu_item_id;
    END IF;
    
    RETURN NEW;
END;
$$;

-- Check livreur badges
CREATE OR REPLACE FUNCTION check_livreur_badges(p_livreur_id UUID)
RETURNS VOID
LANGUAGE plpgsql AS $$
DECLARE
    v_livreur RECORD;
BEGIN
    SELECT * INTO v_livreur FROM public.livreurs WHERE id = p_livreur_id;
    
    IF v_livreur.total_deliveries = 1 THEN
        INSERT INTO public.livreur_badges (livreur_id, badge_type) VALUES (p_livreur_id, 'first_delivery') ON CONFLICT DO NOTHING;
    END IF;
    IF v_livreur.total_deliveries >= 50 THEN
        INSERT INTO public.livreur_badges (livreur_id, badge_type) VALUES (p_livreur_id, '50_deliveries') ON CONFLICT DO NOTHING;
    END IF;
    IF v_livreur.total_deliveries >= 100 THEN
        INSERT INTO public.livreur_badges (livreur_id, badge_type) VALUES (p_livreur_id, '100_deliveries') ON CONFLICT DO NOTHING;
    END IF;
    IF v_livreur.rating >= 4.8 AND v_livreur.total_deliveries >= 10 THEN
        INSERT INTO public.livreur_badges (livreur_id, badge_type) VALUES (p_livreur_id, '5_stars') ON CONFLICT DO NOTHING;
    END IF;
END;
$$;

-- Increment menu item orders
CREATE OR REPLACE FUNCTION increment_menu_item_orders()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE public.menu_items SET order_count = order_count + NEW.quantity WHERE id = NEW.menu_item_id;
    RETURN NEW;
END;
$$;

-- Add tip
CREATE OR REPLACE FUNCTION add_tip(p_order_id UUID, p_amount DECIMAL)
RETURNS BOOLEAN
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_order RECORD;
BEGIN
    SELECT * INTO v_order FROM public.orders WHERE id = p_order_id AND status = 'delivered';
    IF NOT FOUND THEN RETURN false; END IF;
    IF v_order.customer_id != auth.uid() THEN RETURN false; END IF;
    
    UPDATE public.orders SET tip_amount = p_amount, tip_paid_at = NOW() WHERE id = p_order_id;
    UPDATE public.livreurs SET total_earnings = total_earnings + p_amount WHERE id = v_order.livreur_id;
    
    INSERT INTO public.transactions (order_id, type, amount, recipient_id, description)
    VALUES (p_order_id, 'tip', p_amount, (SELECT user_id FROM public.livreurs WHERE id = v_order.livreur_id), 'Pourboire commande #' || v_order.order_number);
    
    RETURN true;
END;
$$;

-- Generate referral code
CREATE OR REPLACE FUNCTION generate_referral_code()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
    NEW.referral_code := UPPER(SUBSTRING(MD5(NEW.id::text || NOW()::text) FROM 1 FOR 8));
    RETURN NEW;
END;
$$;

-- Apply referral code
CREATE OR REPLACE FUNCTION apply_referral_code(p_code VARCHAR)
RETURNS TABLE (success BOOLEAN, message TEXT, bonus DECIMAL)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_referrer RECORD;
    v_current_user RECORD;
BEGIN
    SELECT * INTO v_current_user FROM public.profiles WHERE id = auth.uid();
    IF v_current_user.referred_by IS NOT NULL THEN
        RETURN QUERY SELECT false, 'Vous avez déjà utilisé un code de parrainage'::TEXT, 0::DECIMAL;
        RETURN;
    END IF;
    
    SELECT * INTO v_referrer FROM public.profiles WHERE referral_code = UPPER(p_code);
    IF NOT FOUND THEN
        RETURN QUERY SELECT false, 'Code de parrainage invalide'::TEXT, 0::DECIMAL;
        RETURN;
    END IF;
    
    IF v_referrer.id = auth.uid() THEN
        RETURN QUERY SELECT false, 'Vous ne pouvez pas utiliser votre propre code'::TEXT, 0::DECIMAL;
        RETURN;
    END IF;
    
    UPDATE public.profiles SET referred_by = v_referrer.id WHERE id = auth.uid();
    INSERT INTO public.referrals (referrer_id, referred_id, referral_code) VALUES (v_referrer.id, auth.uid(), p_code);
    UPDATE public.profiles SET loyalty_points = loyalty_points + 300 WHERE id = auth.uid();
    
    RETURN QUERY SELECT true, 'Code appliqué! +300 points de bienvenue'::TEXT, 300::DECIMAL;
END;
$$;

-- Reward referrer on first order
CREATE OR REPLACE FUNCTION reward_referrer_on_first_order()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
DECLARE
    v_referral RECORD;
BEGIN
    IF NEW.status = 'delivered' AND OLD.status != 'delivered' THEN
        IF (SELECT COUNT(*) FROM public.orders WHERE customer_id = NEW.customer_id AND status = 'delivered') = 1 THEN
            SELECT * INTO v_referral FROM public.referrals WHERE referred_id = NEW.customer_id AND status = 'pending';
            
            IF FOUND THEN
                UPDATE public.profiles SET loyalty_points = loyalty_points + 500, referral_earnings = referral_earnings + 500 WHERE id = v_referral.referrer_id;
                UPDATE public.referrals SET status = 'rewarded', completed_at = NOW() WHERE id = v_referral.id;
                
                INSERT INTO public.notifications (user_id, title, body, notification_type, data)
                VALUES (v_referral.referrer_id, '🎉 Bonus parrainage!', 'Votre filleul a passé sa première commande. +500 points!', 'referral', jsonb_build_object('referred_id', NEW.customer_id, 'bonus', 500));
            END IF;
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

-- Update reorder suggestions
CREATE OR REPLACE FUNCTION update_reorder_suggestions()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.status = 'delivered' AND OLD.status != 'delivered' THEN
        INSERT INTO public.reorder_suggestions (customer_id, restaurant_id, items, last_ordered_at, order_count)
        SELECT NEW.customer_id, NEW.restaurant_id,
            (SELECT jsonb_agg(jsonb_build_object('menu_item_id', oi.menu_item_id, 'name', oi.name, 'price', oi.price, 'quantity', oi.quantity)) FROM public.order_items oi WHERE oi.order_id = NEW.id),
            NOW(), 1
        ON CONFLICT (customer_id, restaurant_id) DO UPDATE SET
            items = EXCLUDED.items, last_ordered_at = NOW(), order_count = reorder_suggestions.order_count + 1;
    END IF;
    RETURN NEW;
END;
$$;

-- Reset weekly stats
CREATE OR REPLACE FUNCTION reset_weekly_stats()
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE public.livreurs SET weekly_deliveries = 0;
END;
$$;

-- Reset monthly stats
CREATE OR REPLACE FUNCTION reset_monthly_stats()
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE public.livreurs SET monthly_deliveries = 0;
END;
$$;


-- ============================================
-- TRIGGERS
-- ============================================

-- Drop existing triggers first
DROP TRIGGER IF EXISTS update_profiles_updated_at ON public.profiles;
DROP TRIGGER IF EXISTS update_restaurants_updated_at ON public.restaurants;
DROP TRIGGER IF EXISTS update_menu_items_updated_at ON public.menu_items;
DROP TRIGGER IF EXISTS update_livreurs_updated_at ON public.livreurs;
DROP TRIGGER IF EXISTS update_orders_updated_at ON public.orders;
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS generate_order_number_trigger ON public.orders;
DROP TRIGGER IF EXISTS generate_confirmation_code_trigger ON public.orders;
DROP TRIGGER IF EXISTS calculate_commissions_trigger ON public.orders;
DROP TRIGGER IF EXISTS update_restaurant_rating_trigger ON public.reviews;
DROP TRIGGER IF EXISTS update_livreur_rating_trigger ON public.reviews;
DROP TRIGGER IF EXISTS create_delivery_transactions_trigger ON public.orders;
DROP TRIGGER IF EXISTS update_livreur_stats_trigger ON public.orders;
DROP TRIGGER IF EXISTS update_livreur_stats_enhanced_trigger ON public.orders;
DROP TRIGGER IF EXISTS after_delivery_complete_trigger ON public.orders;
DROP TRIGGER IF EXISTS update_livreur_tier_trigger ON public.livreurs;
DROP TRIGGER IF EXISTS increment_menu_item_orders_trigger ON public.order_items;
DROP TRIGGER IF EXISTS generate_referral_code_trigger ON public.profiles;
DROP TRIGGER IF EXISTS reward_referrer_trigger ON public.orders;
DROP TRIGGER IF EXISTS update_reorder_suggestions_trigger ON public.orders;

-- Create triggers
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

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

CREATE TRIGGER generate_order_number_trigger
    BEFORE INSERT ON public.orders
    FOR EACH ROW EXECUTE FUNCTION generate_order_number();

CREATE TRIGGER generate_confirmation_code_trigger
    BEFORE INSERT ON public.orders
    FOR EACH ROW EXECUTE FUNCTION generate_confirmation_code();

CREATE TRIGGER calculate_commissions_trigger
    BEFORE INSERT ON public.orders
    FOR EACH ROW EXECUTE FUNCTION calculate_commissions();

CREATE TRIGGER update_restaurant_rating_trigger
    AFTER INSERT OR UPDATE ON public.reviews
    FOR EACH ROW EXECUTE FUNCTION update_restaurant_rating();

CREATE TRIGGER update_livreur_rating_trigger
    AFTER INSERT OR UPDATE ON public.reviews
    FOR EACH ROW EXECUTE FUNCTION update_livreur_rating();

CREATE TRIGGER create_delivery_transactions_trigger
    AFTER UPDATE ON public.orders
    FOR EACH ROW EXECUTE FUNCTION create_delivery_transactions();

CREATE TRIGGER after_delivery_complete_trigger
    BEFORE UPDATE ON public.orders
    FOR EACH ROW EXECUTE FUNCTION after_delivery_complete();

CREATE TRIGGER update_livreur_tier_trigger
    BEFORE UPDATE ON public.livreurs
    FOR EACH ROW EXECUTE FUNCTION update_livreur_tier();

CREATE TRIGGER increment_menu_item_orders_trigger
    AFTER INSERT ON public.order_items
    FOR EACH ROW EXECUTE FUNCTION increment_menu_item_orders();

CREATE TRIGGER generate_referral_code_trigger
    BEFORE INSERT ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION generate_referral_code();

CREATE TRIGGER reward_referrer_trigger
    AFTER UPDATE ON public.orders
    FOR EACH ROW EXECUTE FUNCTION reward_referrer_on_first_order();

CREATE TRIGGER update_reorder_suggestions_trigger
    AFTER UPDATE ON public.orders
    FOR EACH ROW EXECUTE FUNCTION update_reorder_suggestions();

-- ============================================
-- STORAGE BUCKETS (à créer manuellement dans Supabase Dashboard)
-- ============================================
-- 1. menu-images (public)
-- 2. restaurant-images (public)
-- 3. profile-images (public)

-- ============================================
-- FIN DE LA MIGRATION UNIFIÉE
-- ============================================
-- Cette migration est idempotente et peut être exécutée plusieurs fois
-- Toutes les tables, colonnes, indexes, policies, functions et triggers sont créés
-- Les données de configuration (tiers, targets, pricing) sont insérées si absentes

SELECT 'Migration complète exécutée avec succès!' AS status;
