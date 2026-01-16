-- ============================================================
-- MIGRATION FINALE COMPLÈTE: Backend + Flutter → Supabase
-- ============================================================
-- Date: 2026-01-16
-- Objectif: Synchronisation TOTALE de toutes les colonnes/tables/fonctions
-- Méthode: IF NOT EXISTS pour éviter les erreurs
-- ============================================================

-- ============================================
-- PARTIE 1: COLONNES MANQUANTES - ORDERS
-- ============================================

ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS total_amount DECIMAL(10,2);
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivery_lat DECIMAL(10,8);
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivery_lng DECIMAL(11,8);
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS notes TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS driver_id UUID REFERENCES public.profiles(id);
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS preparing_at TIMESTAMPTZ;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS cancelled_by TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS code_verified_at TIMESTAMPTZ;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS verification_code TEXT;

-- Synchroniser les données existantes
UPDATE public.orders SET total_amount = total WHERE total_amount IS NULL AND total IS NOT NULL;
UPDATE public.orders SET delivery_lat = delivery_latitude WHERE delivery_lat IS NULL AND delivery_latitude IS NOT NULL;
UPDATE public.orders SET delivery_lng = delivery_longitude WHERE delivery_lng IS NULL AND delivery_longitude IS NOT NULL;

-- ============================================
-- PARTIE 2: COLONNES MANQUANTES - ORDER_ITEMS
-- ============================================

ALTER TABLE public.order_items ADD COLUMN IF NOT EXISTS unit_price DECIMAL(10,2);
ALTER TABLE public.order_items ADD COLUMN IF NOT EXISTS total_price DECIMAL(10,2);

UPDATE public.order_items 
SET unit_price = price, total_price = price * quantity 
WHERE unit_price IS NULL OR total_price IS NULL;

-- ============================================
-- PARTIE 3: COLONNES MANQUANTES - PROFILES
-- ============================================

ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_available BOOLEAN DEFAULT false;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS referral_earnings DECIMAL(10,2) DEFAULT 0;

UPDATE public.profiles SET is_active = true WHERE is_active IS NULL;
UPDATE public.profiles SET is_available = false WHERE is_available IS NULL AND role = 'livreur';

-- ============================================
-- PARTIE 4: COLONNES MANQUANTES - MENU_ITEMS
-- ============================================

ALTER TABLE public.menu_items ADD COLUMN IF NOT EXISTS is_daily_special BOOLEAN DEFAULT false;
ALTER TABLE public.menu_items ADD COLUMN IF NOT EXISTS daily_special_price DECIMAL(10,2);
ALTER TABLE public.menu_items ADD COLUMN IF NOT EXISTS is_vegetarian BOOLEAN DEFAULT false;
ALTER TABLE public.menu_items ADD COLUMN IF NOT EXISTS is_spicy BOOLEAN DEFAULT false;
ALTER TABLE public.menu_items ADD COLUMN IF NOT EXISTS ingredients TEXT[];
ALTER TABLE public.menu_items ADD COLUMN IF NOT EXISTS nutrition_info JSONB;
ALTER TABLE public.menu_items ADD COLUMN IF NOT EXISTS tags TEXT[];
ALTER TABLE public.menu_items ADD COLUMN IF NOT EXISTS total_reviews INTEGER DEFAULT 0;
ALTER TABLE public.menu_items ADD COLUMN IF NOT EXISTS last_ordered_at TIMESTAMPTZ;

-- ============================================
-- PARTIE 5: COLONNES MANQUANTES - LIVREURS
-- ============================================

ALTER TABLE public.livreurs ADD COLUMN IF NOT EXISTS avg_delivery_time INTEGER DEFAULT 0;
ALTER TABLE public.livreurs ADD COLUMN IF NOT EXISTS total_distance_km DECIMAL(10,2) DEFAULT 0;
ALTER TABLE public.livreurs ADD COLUMN IF NOT EXISTS acceptance_rate DECIMAL(5,2) DEFAULT 100;
ALTER TABLE public.livreurs ADD COLUMN IF NOT EXISTS cancellation_rate DECIMAL(5,2) DEFAULT 0;
ALTER TABLE public.livreurs ADD COLUMN IF NOT EXISTS streak_days INTEGER DEFAULT 0;
ALTER TABLE public.livreurs ADD COLUMN IF NOT EXISTS bonus_earned DECIMAL(10,2) DEFAULT 0;

-- ============================================
-- PARTIE 6: COLONNES MANQUANTES - SAVED_ADDRESSES
-- ============================================

ALTER TABLE public.saved_addresses ADD COLUMN IF NOT EXISTS instructions TEXT;

-- ============================================
-- PARTIE 7: COLONNES MANQUANTES - TIER_CONFIG
-- ============================================

ALTER TABLE public.tier_config ADD COLUMN IF NOT EXISTS max_cancellation_rate DECIMAL(5,2) DEFAULT 10;

-- ============================================
-- PARTIE 8: TABLES MANQUANTES
-- ============================================

-- Table: search_history
CREATE TABLE IF NOT EXISTS public.search_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    query TEXT NOT NULL,
    searched_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_search_history_customer ON public.search_history(customer_id, searched_at DESC);

ALTER TABLE public.search_history ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Search history: gestion par propriétaire" ON public.search_history;
CREATE POLICY "Search history: gestion par propriétaire" 
    ON public.search_history FOR ALL USING (auth.uid() = customer_id);

-- Table: menu_item_reviews
CREATE TABLE IF NOT EXISTS public.menu_item_reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    menu_item_id UUID NOT NULL REFERENCES public.menu_items(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(order_id, menu_item_id)
);

CREATE INDEX IF NOT EXISTS idx_menu_item_reviews_item ON public.menu_item_reviews(menu_item_id);
CREATE INDEX IF NOT EXISTS idx_menu_item_reviews_customer ON public.menu_item_reviews(customer_id);

ALTER TABLE public.menu_item_reviews ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Menu item reviews: lecture publique" ON public.menu_item_reviews;
CREATE POLICY "Menu item reviews: lecture publique" 
    ON public.menu_item_reviews FOR SELECT USING (true);
DROP POLICY IF EXISTS "Menu item reviews: création par client" ON public.menu_item_reviews;
CREATE POLICY "Menu item reviews: création par client" 
    ON public.menu_item_reviews FOR INSERT WITH CHECK (auth.uid() = customer_id);

-- Table: livreur_bonuses
CREATE TABLE IF NOT EXISTS public.livreur_bonuses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    livreur_id UUID NOT NULL REFERENCES public.livreurs(id) ON DELETE CASCADE,
    bonus_type VARCHAR(50) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    description TEXT,
    earned_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_livreur_bonuses_livreur ON public.livreur_bonuses(livreur_id, earned_at DESC);

ALTER TABLE public.livreur_bonuses ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Livreur bonuses: lecture par propriétaire" ON public.livreur_bonuses;
CREATE POLICY "Livreur bonuses: lecture par propriétaire" 
    ON public.livreur_bonuses FOR SELECT 
    USING (EXISTS (SELECT 1 FROM public.livreurs WHERE id = livreur_bonuses.livreur_id AND user_id = auth.uid()));

-- Table: livreur_targets
CREATE TABLE IF NOT EXISTS public.livreur_targets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    deliveries_required INTEGER NOT NULL,
    bonus_amount DECIMAL(10,2) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.livreur_targets ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Livreur targets: lecture publique" ON public.livreur_targets;
CREATE POLICY "Livreur targets: lecture publique" 
    ON public.livreur_targets FOR SELECT USING (is_active = true);

-- Table: referrals
CREATE TABLE IF NOT EXISTS public.referrals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    referrer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    referred_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'rewarded'
    reward_amount DECIMAL(10,2) DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    rewarded_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_referrals_referrer ON public.referrals(referrer_id);
CREATE INDEX IF NOT EXISTS idx_referrals_referred ON public.referrals(referred_id);

ALTER TABLE public.referrals ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Referrals: lecture par parties concernées" ON public.referrals;
CREATE POLICY "Referrals: lecture par parties concernées" 
    ON public.referrals FOR SELECT 
    USING (auth.uid() = referrer_id OR auth.uid() = referred_id);

-- Table: reorder_suggestions
CREATE TABLE IF NOT EXISTS public.reorder_suggestions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    restaurant_id UUID NOT NULL REFERENCES public.restaurants(id) ON DELETE CASCADE,
    last_ordered_at TIMESTAMPTZ NOT NULL,
    order_count INTEGER DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(customer_id, restaurant_id)
);

CREATE INDEX IF NOT EXISTS idx_reorder_suggestions_customer ON public.reorder_suggestions(customer_id, last_ordered_at DESC);

ALTER TABLE public.reorder_suggestions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Reorder suggestions: gestion par propriétaire" ON public.reorder_suggestions;
CREATE POLICY "Reorder suggestions: gestion par propriétaire" 
    ON public.reorder_suggestions FOR ALL USING (auth.uid() = customer_id);

-- Table: customer_badges
CREATE TABLE IF NOT EXISTS public.customer_badges (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    badge_id UUID NOT NULL,
    earned_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_customer_badges_customer ON public.customer_badges(customer_id);

ALTER TABLE public.customer_badges ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Customer badges: lecture par propriétaire" ON public.customer_badges;
CREATE POLICY "Customer badges: lecture par propriétaire" 
    ON public.customer_badges FOR SELECT USING (auth.uid() = customer_id);

-- ============================================
-- PARTIE 9: FONCTIONS RPC MANQUANTES
-- ============================================

-- Fonction: increment_livreur_stats
DROP FUNCTION IF EXISTS increment_livreur_stats(UUID, NUMERIC);
CREATE OR REPLACE FUNCTION increment_livreur_stats(
    p_livreur_id UUID,
    p_commission DECIMAL
)
RETURNS VOID AS $$
BEGIN
    UPDATE public.livreurs
    SET 
        total_deliveries = total_deliveries + 1,
        total_earnings = total_earnings + p_commission,
        weekly_deliveries = weekly_deliveries + 1,
        monthly_deliveries = monthly_deliveries + 1
    WHERE id = p_livreur_id;
END;
$$ LANGUAGE plpgsql;

-- Fonction: get_top_menu_items
DROP FUNCTION IF EXISTS get_top_menu_items(UUID, INTEGER);
CREATE OR REPLACE FUNCTION get_top_menu_items(
    p_restaurant_id UUID DEFAULT NULL,
    p_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
    id UUID,
    name VARCHAR,
    description TEXT,
    price DECIMAL,
    image_url TEXT,
    restaurant_id UUID,
    restaurant_name VARCHAR,
    avg_rating DECIMAL,
    order_count INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        mi.id, mi.name, mi.description, mi.price, mi.image_url,
        mi.restaurant_id, r.name as restaurant_name, 
        mi.avg_rating, mi.order_count
    FROM public.menu_items mi
    JOIN public.restaurants r ON r.id = mi.restaurant_id
    WHERE mi.is_available = true 
    AND r.is_verified = true
    AND (p_restaurant_id IS NULL OR mi.restaurant_id = p_restaurant_id)
    ORDER BY mi.order_count DESC, mi.avg_rating DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- Fonction: get_cart_items
DROP FUNCTION IF EXISTS get_cart_items(UUID);
CREATE OR REPLACE FUNCTION get_cart_items(p_customer_id UUID)
RETURNS TABLE (
    id UUID,
    menu_item_id UUID,
    quantity INTEGER,
    name VARCHAR,
    price DECIMAL,
    image_url TEXT,
    restaurant_id UUID,
    restaurant_name VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ci.id, ci.menu_item_id, ci.quantity,
        mi.name, mi.price, mi.image_url,
        mi.restaurant_id, r.name as restaurant_name
    FROM public.cart_items ci
    JOIN public.menu_items mi ON mi.id = ci.menu_item_id
    JOIN public.restaurants r ON r.id = mi.restaurant_id
    WHERE ci.customer_id = p_customer_id;
END;
$$ LANGUAGE plpgsql;

-- Fonction: submit_review
DROP FUNCTION IF EXISTS submit_review(UUID, INTEGER, INTEGER, TEXT);
CREATE OR REPLACE FUNCTION submit_review(
    p_order_id UUID,
    p_restaurant_rating INTEGER,
    p_livreur_rating INTEGER,
    p_comment TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    v_order RECORD;
BEGIN
    SELECT * INTO v_order FROM public.orders WHERE id = p_order_id;
    
    IF v_order IS NULL THEN
        RETURN false;
    END IF;
    
    INSERT INTO public.reviews (
        order_id, customer_id, restaurant_id, livreur_id,
        restaurant_rating, livreur_rating, comment
    ) VALUES (
        p_order_id, v_order.customer_id, v_order.restaurant_id, v_order.livreur_id,
        p_restaurant_rating, p_livreur_rating, p_comment
    ) ON CONFLICT (order_id) DO UPDATE SET
        restaurant_rating = p_restaurant_rating,
        livreur_rating = p_livreur_rating,
        comment = p_comment;
    
    RETURN true;
END;
$$ LANGUAGE plpgsql;

-- Fonction: add_tip
DROP FUNCTION IF EXISTS add_tip(UUID, DECIMAL);
CREATE OR REPLACE FUNCTION add_tip(
    p_order_id UUID,
    p_amount DECIMAL
)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE public.orders
    SET tip_amount = tip_amount + p_amount
    WHERE id = p_order_id;
    
    INSERT INTO public.transactions (order_id, type, amount, description)
    VALUES (p_order_id, 'tip', p_amount, 'Pourboire');
    
    RETURN true;
END;
$$ LANGUAGE plpgsql;

-- Fonction: apply_referral_code
DROP FUNCTION IF EXISTS apply_referral_code(VARCHAR);
CREATE OR REPLACE FUNCTION apply_referral_code(p_code VARCHAR)
RETURNS TABLE (success BOOLEAN, message TEXT) AS $$
DECLARE
    v_referrer_id UUID;
    v_current_user_id UUID;
BEGIN
    v_current_user_id := auth.uid();
    
    SELECT id INTO v_referrer_id FROM public.profiles WHERE referral_code = p_code;
    
    IF v_referrer_id IS NULL THEN
        RETURN QUERY SELECT false, 'Code invalide';
        RETURN;
    END IF;
    
    IF v_referrer_id = v_current_user_id THEN
        RETURN QUERY SELECT false, 'Vous ne pouvez pas utiliser votre propre code';
        RETURN;
    END IF;
    
    UPDATE public.profiles SET referred_by = v_referrer_id WHERE id = v_current_user_id;
    
    INSERT INTO public.referrals (referrer_id, referred_id)
    VALUES (v_referrer_id, v_current_user_id);
    
    RETURN QUERY SELECT true, 'Code appliqué avec succès';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- PARTIE 10: INDEX POUR PERFORMANCE
-- ============================================

CREATE INDEX IF NOT EXISTS idx_orders_driver ON public.orders(driver_id) WHERE driver_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_orders_status_livreur ON public.orders(status, livreur_id) WHERE livreur_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_orders_pending_no_driver ON public.orders(status, created_at) 
WHERE status = 'pending' AND driver_id IS NULL AND livreur_id IS NULL;

-- ============================================
-- VÉRIFICATION FINALE
-- ============================================

SELECT 
    'Migration FINALE terminée' as status,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'orders') as orders_columns,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'order_items') as order_items_columns,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'profiles') as profiles_columns,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'menu_items') as menu_items_columns,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'livreurs') as livreurs_columns,
    (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public') as total_tables;
