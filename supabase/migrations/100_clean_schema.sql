-- ============================================================
-- DZ DELIVERY - SCHÉMA PROPRE ET OPTIMISÉ
-- ============================================================
-- Date: 16 janvier 2026
-- Version: 2.0 (Post-migration Backend)
-- 
-- Ce schéma est optimisé pour fonctionner avec le Backend NestJS
-- Les opérations critiques passent par le backend, Supabase gère:
-- - Auth, Realtime, Storage, Lectures (SELECT)
-- ============================================================

-- ============================================
-- EXTENSIONS
-- ============================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- ============================================
-- TYPES ENUM
-- ============================================
DO $$ BEGIN CREATE TYPE user_role AS ENUM ('customer', 'restaurant', 'livreur', 'admin'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE order_status AS ENUM ('pending', 'confirmed', 'preparing', 'ready', 'picked_up', 'delivering', 'delivered', 'cancelled'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE payment_method AS ENUM ('cash', 'card', 'edahabia', 'cib'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE payment_status AS ENUM ('pending', 'paid', 'failed', 'refunded'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE vehicle_type AS ENUM ('moto', 'velo', 'voiture'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE livreur_tier AS ENUM ('bronze', 'silver', 'gold', 'diamond'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ============================================
-- TABLES PRINCIPALES
-- ============================================

-- PROFILES (utilisateurs)
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

-- RESTAURANTS
CREATE TABLE IF NOT EXISTS public.restaurants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    logo_url TEXT,
    cover_url TEXT,
    cover_images TEXT[],
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
    accepts_preorders BOOLEAN DEFAULT false,
    fcm_token TEXT,
    onesignal_player_id TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- MENU_CATEGORIES
CREATE TABLE IF NOT EXISTS public.menu_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    restaurant_id UUID REFERENCES public.restaurants(id) ON DELETE CASCADE,
    name VARCHAR(50) NOT NULL,
    description TEXT,
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- MENU_ITEMS
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
    is_vegetarian BOOLEAN DEFAULT false,
    is_spicy BOOLEAN DEFAULT false,
    is_daily_special BOOLEAN DEFAULT false,
    daily_special_price DECIMAL(10,2),
    prep_time INTEGER DEFAULT 15,
    calories INTEGER,
    allergens TEXT[],
    ingredients TEXT[],
    tags TEXT[],
    order_count INTEGER DEFAULT 0,
    avg_rating DECIMAL(3,2) DEFAULT 0,
    total_reviews INTEGER DEFAULT 0,
    last_ordered_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- LIVREURS
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
    cancellation_rate DECIMAL(5,2) DEFAULT 0,
    tier livreur_tier DEFAULT 'bronze',
    tier_progress INTEGER DEFAULT 0,
    weekly_deliveries INTEGER DEFAULT 0,
    monthly_deliveries INTEGER DEFAULT 0,
    streak_days INTEGER DEFAULT 0,
    last_active_date DATE,
    bonus_earned DECIMAL(10,2) DEFAULT 0,
    fcm_token TEXT,
    onesignal_player_id TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ORDERS
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
    confirmation_code VARCHAR(4),
    livreur_commission DECIMAL(10, 2) DEFAULT 0,
    admin_commission DECIMAL(10, 2) DEFAULT 0,
    restaurant_amount DECIMAL(10, 2) DEFAULT 0,
    tip_amount DECIMAL(10,2) DEFAULT 0,
    tip_paid_at TIMESTAMPTZ,
    promo_code VARCHAR(20),
    promo_discount DECIMAL(10, 2) DEFAULT 0,
    promotion_id UUID,
    current_eta_minutes INTEGER,
    distance_remaining_km DECIMAL(10,2),
    estimated_delivery_time TIMESTAMPTZ,
    confirmed_at TIMESTAMPTZ,
    prepared_at TIMESTAMPTZ,
    livreur_accepted_at TIMESTAMPTZ,
    picked_up_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    code_verified_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    cancellation_reason TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ORDER_ITEMS
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

-- REVIEWS
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

-- LIVREUR_LOCATIONS (tracking temps réel)
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

-- NOTIFICATIONS
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    title VARCHAR(100) NOT NULL,
    body TEXT,
    data JSONB,
    notification_type VARCHAR(50) DEFAULT 'system',
    is_read BOOLEAN DEFAULT false,
    sent_at TIMESTAMPTZ DEFAULT NOW(),
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- TRANSACTIONS
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

-- PROMOTIONS
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

-- FAVORITES
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

-- SAVED_ADDRESSES
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

-- ORDER_MESSAGES (Chat)
CREATE TABLE IF NOT EXISTS public.order_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    sender_type VARCHAR(20) NOT NULL CHECK (sender_type IN ('customer', 'livreur', 'restaurant', 'system')),
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- REFERRALS
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
-- TABLES DE CONFIGURATION
-- ============================================

-- COMMISSION_SETTINGS
CREATE TABLE IF NOT EXISTS public.commission_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    livreur_commission_percent DECIMAL(5, 2) DEFAULT 15.00,
    admin_commission_percent DECIMAL(5, 2) DEFAULT 5.00,
    min_delivery_fee DECIMAL(10, 2) DEFAULT 100.00,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- TIER_CONFIG
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

-- LIVREUR_TARGETS
CREATE TABLE IF NOT EXISTS public.livreur_targets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    target_type VARCHAR(20) NOT NULL,
    deliveries_required INTEGER NOT NULL,
    bonus_amount DECIMAL(10,2) NOT NULL,
    is_active BOOLEAN DEFAULT true
);

-- DELIVERY_PRICING
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

-- LIVREUR_BADGES
CREATE TABLE IF NOT EXISTS public.livreur_badges (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    livreur_id UUID REFERENCES public.livreurs(id) ON DELETE CASCADE,
    badge_type VARCHAR(50) NOT NULL,
    earned_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(livreur_id, badge_type)
);

-- LIVREUR_BONUSES
CREATE TABLE IF NOT EXISTS public.livreur_bonuses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    livreur_id UUID REFERENCES public.livreurs(id) ON DELETE CASCADE,
    bonus_type VARCHAR(50) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    description TEXT,
    order_id UUID REFERENCES public.orders(id),
    earned_at TIMESTAMPTZ DEFAULT NOW()
);

-- REORDER_SUGGESTIONS
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
-- INDEXES OPTIMISÉS
-- ============================================
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_phone ON public.profiles(phone);
CREATE INDEX IF NOT EXISTS idx_profiles_referral_code ON public.profiles(referral_code);

CREATE INDEX IF NOT EXISTS idx_restaurants_owner ON public.restaurants(owner_id);
CREATE INDEX IF NOT EXISTS idx_restaurants_location ON public.restaurants(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_restaurants_cuisine ON public.restaurants(cuisine_type);
CREATE INDEX IF NOT EXISTS idx_restaurants_is_open ON public.restaurants(is_open) WHERE is_open = true;
CREATE INDEX IF NOT EXISTS idx_restaurants_verified_open ON public.restaurants(is_verified, is_open) WHERE is_verified = true;

CREATE INDEX IF NOT EXISTS idx_menu_items_restaurant ON public.menu_items(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_menu_items_category ON public.menu_items(category_id);
CREATE INDEX IF NOT EXISTS idx_menu_items_available ON public.menu_items(is_available) WHERE is_available = true;
CREATE INDEX IF NOT EXISTS idx_menu_items_popular ON public.menu_items(restaurant_id, order_count DESC);

CREATE INDEX IF NOT EXISTS idx_livreurs_user ON public.livreurs(user_id);
CREATE INDEX IF NOT EXISTS idx_livreurs_location ON public.livreurs(current_latitude, current_longitude);
CREATE INDEX IF NOT EXISTS idx_livreurs_available ON public.livreurs(is_available, is_online) WHERE is_available = true AND is_online = true;
CREATE INDEX IF NOT EXISTS idx_livreurs_tier ON public.livreurs(tier);

CREATE INDEX IF NOT EXISTS idx_orders_customer ON public.orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_restaurant ON public.orders(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_orders_livreur ON public.orders(livreur_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created ON public.orders(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_orders_pending ON public.orders(status, created_at) WHERE status = 'pending';
CREATE INDEX IF NOT EXISTS idx_orders_active ON public.orders(status) WHERE status IN ('pending', 'confirmed', 'preparing', 'ready', 'picked_up', 'delivering');

CREATE INDEX IF NOT EXISTS idx_order_items_order ON public.order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_livreur_locations_order ON public.livreur_locations(order_id, recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread ON public.notifications(user_id, is_read) WHERE is_read = false;
CREATE INDEX IF NOT EXISTS idx_transactions_order ON public.transactions(order_id);
CREATE INDEX IF NOT EXISTS idx_transactions_recipient ON public.transactions(recipient_id);
CREATE INDEX IF NOT EXISTS idx_promotions_active ON public.promotions(is_active, starts_at, ends_at) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_favorites_customer ON public.favorites(customer_id);
CREATE INDEX IF NOT EXISTS idx_order_messages_order ON public.order_messages(order_id, created_at);

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================
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
ALTER TABLE public.favorite_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saved_addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referrals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.livreur_badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.livreur_bonuses ENABLE ROW LEVEL SECURITY;

-- ============================================
-- POLICIES
-- ============================================

-- PROFILES
DROP POLICY IF EXISTS "profiles_select" ON public.profiles;
DROP POLICY IF EXISTS "profiles_update" ON public.profiles;
CREATE POLICY "profiles_select" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "profiles_update" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- RESTAURANTS
DROP POLICY IF EXISTS "restaurants_select" ON public.restaurants;
DROP POLICY IF EXISTS "restaurants_update" ON public.restaurants;
DROP POLICY IF EXISTS "restaurants_insert" ON public.restaurants;
CREATE POLICY "restaurants_select" ON public.restaurants FOR SELECT USING (true);
CREATE POLICY "restaurants_update" ON public.restaurants FOR UPDATE USING (auth.uid() = owner_id);
CREATE POLICY "restaurants_insert" ON public.restaurants FOR INSERT WITH CHECK (auth.uid() = owner_id);

-- MENU
DROP POLICY IF EXISTS "menu_categories_select" ON public.menu_categories;
DROP POLICY IF EXISTS "menu_items_select" ON public.menu_items;
DROP POLICY IF EXISTS "menu_categories_manage" ON public.menu_categories;
DROP POLICY IF EXISTS "menu_items_manage" ON public.menu_items;
CREATE POLICY "menu_categories_select" ON public.menu_categories FOR SELECT USING (true);
CREATE POLICY "menu_items_select" ON public.menu_items FOR SELECT USING (true);
CREATE POLICY "menu_categories_manage" ON public.menu_categories FOR ALL
    USING (EXISTS (SELECT 1 FROM public.restaurants WHERE id = menu_categories.restaurant_id AND owner_id = auth.uid()));
CREATE POLICY "menu_items_manage" ON public.menu_items FOR ALL
    USING (EXISTS (SELECT 1 FROM public.restaurants WHERE id = menu_items.restaurant_id AND owner_id = auth.uid()));

-- LIVREURS
DROP POLICY IF EXISTS "livreurs_select" ON public.livreurs;
DROP POLICY IF EXISTS "livreurs_update" ON public.livreurs;
DROP POLICY IF EXISTS "livreurs_insert" ON public.livreurs;
CREATE POLICY "livreurs_select" ON public.livreurs FOR SELECT USING (true);
CREATE POLICY "livreurs_update" ON public.livreurs FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "livreurs_insert" ON public.livreurs FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ORDERS (lecture seule côté client, modifications via backend)
DROP POLICY IF EXISTS "orders_customer_select" ON public.orders;
DROP POLICY IF EXISTS "orders_restaurant_select" ON public.orders;
DROP POLICY IF EXISTS "orders_livreur_select" ON public.orders;
DROP POLICY IF EXISTS "orders_available_select" ON public.orders;
DROP POLICY IF EXISTS "orders_insert" ON public.orders;
DROP POLICY IF EXISTS "orders_update" ON public.orders;
CREATE POLICY "orders_customer_select" ON public.orders FOR SELECT USING (auth.uid() = customer_id);
CREATE POLICY "orders_restaurant_select" ON public.orders FOR SELECT
    USING (EXISTS (SELECT 1 FROM public.restaurants WHERE id = orders.restaurant_id AND owner_id = auth.uid()));
CREATE POLICY "orders_livreur_select" ON public.orders FOR SELECT
    USING (EXISTS (SELECT 1 FROM public.livreurs WHERE id = orders.livreur_id AND user_id = auth.uid()));
CREATE POLICY "orders_available_select" ON public.orders FOR SELECT
    USING (status = 'ready' AND livreur_id IS NULL);
-- Note: INSERT et UPDATE des orders passent par le backend avec service_role

-- ORDER_ITEMS
DROP POLICY IF EXISTS "order_items_select" ON public.order_items;
CREATE POLICY "order_items_select" ON public.order_items FOR SELECT
    USING (EXISTS (SELECT 1 FROM public.orders WHERE id = order_items.order_id
        AND (customer_id = auth.uid() 
            OR EXISTS (SELECT 1 FROM public.restaurants WHERE id = orders.restaurant_id AND owner_id = auth.uid())
            OR EXISTS (SELECT 1 FROM public.livreurs WHERE id = orders.livreur_id AND user_id = auth.uid()))));

-- REVIEWS
DROP POLICY IF EXISTS "reviews_select" ON public.reviews;
DROP POLICY IF EXISTS "reviews_insert" ON public.reviews;
CREATE POLICY "reviews_select" ON public.reviews FOR SELECT USING (true);
CREATE POLICY "reviews_insert" ON public.reviews FOR INSERT WITH CHECK (auth.uid() = customer_id);

-- LIVREUR_LOCATIONS
DROP POLICY IF EXISTS "livreur_locations_select" ON public.livreur_locations;
DROP POLICY IF EXISTS "livreur_locations_insert" ON public.livreur_locations;
CREATE POLICY "livreur_locations_select" ON public.livreur_locations FOR SELECT
    USING (EXISTS (SELECT 1 FROM public.orders WHERE id = livreur_locations.order_id
        AND (customer_id = auth.uid() OR EXISTS (SELECT 1 FROM public.restaurants WHERE id = orders.restaurant_id AND owner_id = auth.uid())))
        OR EXISTS (SELECT 1 FROM public.livreurs WHERE id = livreur_locations.livreur_id AND user_id = auth.uid()));
CREATE POLICY "livreur_locations_insert" ON public.livreur_locations FOR INSERT
    WITH CHECK (EXISTS (SELECT 1 FROM public.livreurs WHERE id = livreur_locations.livreur_id AND user_id = auth.uid()));

-- NOTIFICATIONS
DROP POLICY IF EXISTS "notifications_select" ON public.notifications;
DROP POLICY IF EXISTS "notifications_update" ON public.notifications;
CREATE POLICY "notifications_select" ON public.notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "notifications_update" ON public.notifications FOR UPDATE USING (auth.uid() = user_id);

-- TRANSACTIONS
DROP POLICY IF EXISTS "transactions_admin" ON public.transactions;
DROP POLICY IF EXISTS "transactions_recipient" ON public.transactions;
CREATE POLICY "transactions_admin" ON public.transactions FOR ALL
    USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));
CREATE POLICY "transactions_recipient" ON public.transactions FOR SELECT USING (recipient_id = auth.uid());

-- PROMOTIONS
DROP POLICY IF EXISTS "promotions_select" ON public.promotions;
DROP POLICY IF EXISTS "promotions_manage" ON public.promotions;
CREATE POLICY "promotions_select" ON public.promotions FOR SELECT USING (true);
CREATE POLICY "promotions_manage" ON public.promotions FOR ALL
    USING (EXISTS (SELECT 1 FROM public.restaurants WHERE id = promotions.restaurant_id AND owner_id = auth.uid()));

-- FAVORITES
DROP POLICY IF EXISTS "favorites_manage" ON public.favorites;
DROP POLICY IF EXISTS "favorite_items_manage" ON public.favorite_items;
CREATE POLICY "favorites_manage" ON public.favorites FOR ALL USING (auth.uid() = customer_id);
CREATE POLICY "favorite_items_manage" ON public.favorite_items FOR ALL USING (auth.uid() = customer_id);

-- SAVED_ADDRESSES
DROP POLICY IF EXISTS "saved_addresses_manage" ON public.saved_addresses;
CREATE POLICY "saved_addresses_manage" ON public.saved_addresses FOR ALL USING (auth.uid() = customer_id);

-- ORDER_MESSAGES
DROP POLICY IF EXISTS "order_messages_select" ON public.order_messages;
DROP POLICY IF EXISTS "order_messages_insert" ON public.order_messages;
CREATE POLICY "order_messages_select" ON public.order_messages FOR SELECT
    USING (EXISTS (SELECT 1 FROM public.orders o WHERE o.id = order_messages.order_id
        AND (o.customer_id = auth.uid() OR o.livreur_id IN (SELECT id FROM public.livreurs WHERE user_id = auth.uid()))));
CREATE POLICY "order_messages_insert" ON public.order_messages FOR INSERT WITH CHECK (auth.uid() = sender_id);

-- REFERRALS
DROP POLICY IF EXISTS "referrals_select" ON public.referrals;
CREATE POLICY "referrals_select" ON public.referrals FOR SELECT
    USING (auth.uid() = referrer_id OR auth.uid() = referred_id);

-- BADGES & BONUSES
DROP POLICY IF EXISTS "livreur_badges_select" ON public.livreur_badges;
DROP POLICY IF EXISTS "livreur_bonuses_select" ON public.livreur_bonuses;
CREATE POLICY "livreur_badges_select" ON public.livreur_badges FOR SELECT USING (true);
CREATE POLICY "livreur_bonuses_select" ON public.livreur_bonuses FOR SELECT 
    USING (EXISTS (SELECT 1 FROM public.livreurs WHERE id = livreur_bonuses.livreur_id AND user_id = auth.uid()));


-- ============================================
-- FONCTIONS UTILITAIRES
-- ============================================

-- Updated_at trigger
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
BEGIN
    SELECT * INTO settings FROM public.commission_settings LIMIT 1;
    
    NEW.livreur_commission := GREATEST(NEW.delivery_fee, COALESCE(settings.min_delivery_fee, 100));
    NEW.admin_commission := (NEW.total * COALESCE(settings.admin_commission_percent, 5) / 100);
    NEW.restaurant_amount := NEW.total - NEW.admin_commission - NEW.delivery_fee;
    
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

-- Create delivery transactions (appelé après livraison)
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

-- After delivery complete (mise à jour stats)
CREATE OR REPLACE FUNCTION after_delivery_complete()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'delivered' AND OLD.status != 'delivered' THEN
        -- Update livreur stats
        UPDATE public.livreurs SET
            total_deliveries = total_deliveries + 1,
            total_earnings = total_earnings + NEW.livreur_commission,
            weekly_deliveries = weekly_deliveries + 1,
            monthly_deliveries = monthly_deliveries + 1,
            last_active_date = CURRENT_DATE,
            streak_days = CASE 
                WHEN last_active_date = CURRENT_DATE - 1 THEN streak_days + 1
                WHEN last_active_date = CURRENT_DATE THEN streak_days
                ELSE 1
            END
        WHERE id = NEW.livreur_id;
        
        -- Update customer stats
        UPDATE public.profiles SET
            total_orders = total_orders + 1,
            total_spent = total_spent + NEW.total,
            loyalty_points = loyalty_points + FLOOR(NEW.total / 100)
        WHERE id = NEW.customer_id;
        
        -- Update menu items order count
        UPDATE public.menu_items mi SET
            order_count = order_count + oi.quantity,
            last_ordered_at = NOW()
        FROM public.order_items oi
        WHERE oi.order_id = NEW.id AND mi.id = oi.menu_item_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Update livreur tier
CREATE OR REPLACE FUNCTION update_livreur_tier()
RETURNS TRIGGER AS $$
DECLARE
    v_new_tier livreur_tier;
BEGIN
    IF NEW.total_deliveries >= 400 AND COALESCE(NEW.rating, 5.0) >= 4.6 AND COALESCE(NEW.cancellation_rate, 0) <= 5 THEN
        v_new_tier := 'diamond';
    ELSIF NEW.total_deliveries >= 150 AND COALESCE(NEW.rating, 5.0) >= 4.2 AND COALESCE(NEW.cancellation_rate, 0) <= 10 THEN
        v_new_tier := 'gold';
    ELSIF NEW.total_deliveries >= 50 AND COALESCE(NEW.rating, 5.0) >= 3.8 AND COALESCE(NEW.cancellation_rate, 0) <= 15 THEN
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

-- Generate referral code
CREATE OR REPLACE FUNCTION generate_referral_code()
RETURNS TRIGGER AS $$
BEGIN
    NEW.referral_code := UPPER(SUBSTRING(MD5(NEW.id::text || NOW()::text) FROM 1 FOR 8));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- FONCTIONS API (utilisées par le backend)
-- ============================================

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
RETURNS TABLE (id UUID, user_id UUID, full_name VARCHAR, phone VARCHAR, vehicle_type vehicle_type, rating DECIMAL, distance_km DECIMAL, tier livreur_tier) AS $$
BEGIN
    RETURN QUERY
    SELECT l.id, l.user_id, p.full_name, p.phone, l.vehicle_type, l.rating,
        (6371 * acos(cos(radians(restaurant_lat)) * cos(radians(l.current_latitude)) * cos(radians(l.current_longitude) - radians(restaurant_lng)) + sin(radians(restaurant_lat)) * sin(radians(l.current_latitude))))::DECIMAL AS distance_km,
        l.tier
    FROM public.livreurs l
    JOIN public.profiles p ON p.id = l.user_id
    WHERE l.is_available = true AND l.is_online = true AND l.is_verified = true AND l.current_latitude IS NOT NULL
    AND (6371 * acos(cos(radians(restaurant_lat)) * cos(radians(l.current_latitude)) * cos(radians(l.current_longitude) - radians(restaurant_lng)) + sin(radians(restaurant_lat)) * sin(radians(l.current_latitude)))) <= radius_km
    ORDER BY l.tier DESC, distance_km;
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

-- Calculate delivery fee
CREATE OR REPLACE FUNCTION calculate_delivery_fee(p_restaurant_lat DECIMAL, p_restaurant_lng DECIMAL, p_customer_lat DECIMAL, p_customer_lng DECIMAL)
RETURNS TABLE (distance_km DECIMAL, base_fee DECIMAL, distance_fee DECIMAL, total_fee DECIMAL, estimated_time INTEGER) AS $$
DECLARE
    v_distance DECIMAL;
    v_pricing RECORD;
    v_total DECIMAL;
BEGIN
    v_distance := 6371 * ACOS(COS(RADIANS(p_restaurant_lat)) * COS(RADIANS(p_customer_lat)) * COS(RADIANS(p_customer_lng) - RADIANS(p_restaurant_lng)) + SIN(RADIANS(p_restaurant_lat)) * SIN(RADIANS(p_customer_lat)));
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
-- TRIGGERS
-- ============================================
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
DROP TRIGGER IF EXISTS after_delivery_complete_trigger ON public.orders;
DROP TRIGGER IF EXISTS update_livreur_tier_trigger ON public.livreurs;
DROP TRIGGER IF EXISTS generate_referral_code_trigger ON public.profiles;

CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_restaurants_updated_at BEFORE UPDATE ON public.restaurants FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_menu_items_updated_at BEFORE UPDATE ON public.menu_items FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_livreurs_updated_at BEFORE UPDATE ON public.livreurs FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON public.orders FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION handle_new_user();
CREATE TRIGGER generate_order_number_trigger BEFORE INSERT ON public.orders FOR EACH ROW EXECUTE FUNCTION generate_order_number();
CREATE TRIGGER generate_confirmation_code_trigger BEFORE INSERT ON public.orders FOR EACH ROW EXECUTE FUNCTION generate_confirmation_code();
CREATE TRIGGER calculate_commissions_trigger BEFORE INSERT ON public.orders FOR EACH ROW EXECUTE FUNCTION calculate_commissions();
CREATE TRIGGER update_restaurant_rating_trigger AFTER INSERT OR UPDATE ON public.reviews FOR EACH ROW EXECUTE FUNCTION update_restaurant_rating();
CREATE TRIGGER update_livreur_rating_trigger AFTER INSERT OR UPDATE ON public.reviews FOR EACH ROW EXECUTE FUNCTION update_livreur_rating();
CREATE TRIGGER create_delivery_transactions_trigger AFTER UPDATE ON public.orders FOR EACH ROW EXECUTE FUNCTION create_delivery_transactions();
CREATE TRIGGER after_delivery_complete_trigger BEFORE UPDATE ON public.orders FOR EACH ROW EXECUTE FUNCTION after_delivery_complete();
CREATE TRIGGER update_livreur_tier_trigger BEFORE UPDATE ON public.livreurs FOR EACH ROW EXECUTE FUNCTION update_livreur_tier();
CREATE TRIGGER generate_referral_code_trigger BEFORE INSERT ON public.profiles FOR EACH ROW EXECUTE FUNCTION generate_referral_code();

-- ============================================
-- DONNÉES DE CONFIGURATION
-- ============================================
INSERT INTO public.commission_settings (livreur_commission_percent, admin_commission_percent, min_delivery_fee)
SELECT 15.00, 5.00, 100.00 WHERE NOT EXISTS (SELECT 1 FROM public.commission_settings);

INSERT INTO public.tier_config VALUES
    ('bronze', 10.0, 0, 0, 100, 1, 0, 'Nouveau livreur'),
    ('silver', 12.0, 50, 3.8, 15, 2, 3, 'Livreur régulier'),
    ('gold', 14.0, 150, 4.2, 10, 3, 5, 'Livreur expert'),
    ('diamond', 16.0, 400, 4.6, 5, 4, 8, 'Livreur élite')
ON CONFLICT (tier) DO NOTHING;

INSERT INTO public.delivery_pricing (name, base_fee, per_km_fee, min_fee, max_fee)
SELECT 'standard', 100, 30, 100, 500 WHERE NOT EXISTS (SELECT 1 FROM public.delivery_pricing WHERE name = 'standard');

INSERT INTO public.livreur_targets (target_type, deliveries_required, bonus_amount, is_active) VALUES
    ('daily', 8, 300, true),
    ('daily', 12, 600, true),
    ('weekly', 40, 2000, true),
    ('weekly', 60, 4000, true),
    ('monthly', 180, 12000, true)
ON CONFLICT DO NOTHING;

-- ============================================
-- FIN DU SCHÉMA PROPRE
-- ============================================
SELECT 'Schéma propre créé avec succès!' AS status;
