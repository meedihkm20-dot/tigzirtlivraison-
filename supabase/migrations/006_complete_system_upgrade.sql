-- DZ Delivery - Complete System Upgrade
-- Migration 006: Livreur Gamification, Menu Enhancement, Notifications, Dynamic Pricing

-- ============================================
-- 1. SYSTÈME LIVREUR GAMIFIÉ (Commission ~12.5%)
-- ============================================

-- Niveaux livreur
CREATE TYPE livreur_tier AS ENUM ('bronze', 'silver', 'gold', 'diamond');

ALTER TABLE public.livreurs ADD COLUMN IF NOT EXISTS tier livreur_tier DEFAULT 'bronze';
ALTER TABLE public.livreurs ADD COLUMN IF NOT EXISTS tier_progress INTEGER DEFAULT 0; -- Points vers prochain niveau
ALTER TABLE public.livreurs ADD COLUMN IF NOT EXISTS weekly_deliveries INTEGER DEFAULT 0;
ALTER TABLE public.livreurs ADD COLUMN IF NOT EXISTS monthly_deliveries INTEGER DEFAULT 0;
ALTER TABLE public.livreurs ADD COLUMN IF NOT EXISTS cancellation_rate DECIMAL(5,2) DEFAULT 0;
ALTER TABLE public.livreurs ADD COLUMN IF NOT EXISTS streak_days INTEGER DEFAULT 0; -- Jours consécutifs actifs
ALTER TABLE public.livreurs ADD COLUMN IF NOT EXISTS last_active_date DATE;
ALTER TABLE public.livreurs ADD COLUMN IF NOT EXISTS bonus_earned DECIMAL(10,2) DEFAULT 0;
ALTER TABLE public.livreurs ADD COLUMN IF NOT EXISTS fcm_token TEXT; -- Firebase token

-- Table des bonus livreur
CREATE TABLE IF NOT EXISTS public.livreur_bonuses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    livreur_id UUID REFERENCES public.livreurs(id) ON DELETE CASCADE,
    bonus_type VARCHAR(50) NOT NULL, -- 'daily_target', 'weekly_target', 'streak', 'weather', 'rush_hour', 'five_star'
    amount DECIMAL(10,2) NOT NULL,
    description TEXT,
    order_id UUID REFERENCES public.orders(id),
    earned_at TIMESTAMPTZ DEFAULT NOW()
);

-- Configuration des tiers (admin peut modifier)
CREATE TABLE IF NOT EXISTS public.tier_config (
    tier livreur_tier PRIMARY KEY,
    commission_rate DECIMAL(5,2) NOT NULL, -- Pourcentage
    min_deliveries INTEGER NOT NULL,
    min_rating DECIMAL(3,2) NOT NULL,
    max_cancellation_rate DECIMAL(5,2) NOT NULL,
    priority_level INTEGER NOT NULL, -- 1-4, plus haut = priorité
    weekend_bonus DECIMAL(5,2) DEFAULT 0, -- % bonus weekend
    description TEXT
);

INSERT INTO public.tier_config VALUES
    ('bronze', 10.0, 0, 0, 100, 1, 0, 'Nouveau livreur'),
    ('silver', 12.0, 50, 3.8, 15, 2, 3, 'Livreur régulier'),
    ('gold', 14.0, 150, 4.2, 10, 3, 5, 'Livreur expert'),
    ('diamond', 16.0, 400, 4.6, 5, 4, 8, 'Livreur élite')
ON CONFLICT (tier) DO NOTHING;

-- Objectifs journaliers/hebdo
CREATE TABLE IF NOT EXISTS public.livreur_targets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    target_type VARCHAR(20) NOT NULL, -- 'daily', 'weekly', 'monthly'
    deliveries_required INTEGER NOT NULL,
    bonus_amount DECIMAL(10,2) NOT NULL,
    is_active BOOLEAN DEFAULT true
);

INSERT INTO public.livreur_targets VALUES
    (uuid_generate_v4(), 'daily', 8, 300, true),
    (uuid_generate_v4(), 'daily', 12, 600, true),
    (uuid_generate_v4(), 'weekly', 40, 2000, true),
    (uuid_generate_v4(), 'weekly', 60, 4000, true),
    (uuid_generate_v4(), 'monthly', 180, 12000, true)
ON CONFLICT DO NOTHING;

-- ============================================
-- 2. MENU AMÉLIORÉ (Photos, Détails, Stats)
-- ============================================

ALTER TABLE public.menu_items ADD COLUMN IF NOT EXISTS image_width INTEGER DEFAULT 500;
ALTER TABLE public.menu_items ADD COLUMN IF NOT EXISTS image_height INTEGER DEFAULT 500;
ALTER TABLE public.menu_items ADD COLUMN IF NOT EXISTS ingredients TEXT[];
ALTER TABLE public.menu_items ADD COLUMN IF NOT EXISTS nutrition_info JSONB; -- {calories, protein, carbs, fat}
ALTER TABLE public.menu_items ADD COLUMN IF NOT EXISTS is_daily_special BOOLEAN DEFAULT false;
ALTER TABLE public.menu_items ADD COLUMN IF NOT EXISTS daily_special_price DECIMAL(10,2);
ALTER TABLE public.menu_items ADD COLUMN IF NOT EXISTS avg_rating DECIMAL(3,2) DEFAULT 0;
ALTER TABLE public.menu_items ADD COLUMN IF NOT EXISTS total_reviews INTEGER DEFAULT 0;
ALTER TABLE public.menu_items ADD COLUMN IF NOT EXISTS last_ordered_at TIMESTAMPTZ;
ALTER TABLE public.menu_items ADD COLUMN IF NOT EXISTS tags TEXT[]; -- ['best-seller', 'new', 'healthy']

-- Avis sur les plats (pas juste le restaurant)
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
-- 3. NOTIFICATIONS FIREBASE
-- ============================================

CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    title VARCHAR(100) NOT NULL,
    body TEXT NOT NULL,
    data JSONB, -- Données additionnelles (order_id, type, etc.)
    notification_type VARCHAR(50) NOT NULL, -- 'order_status', 'new_order', 'promotion', 'system'
    is_read BOOLEAN DEFAULT false,
    sent_at TIMESTAMPTZ DEFAULT NOW(),
    read_at TIMESTAMPTZ
);

-- FCM tokens pour tous les utilisateurs
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS fcm_token TEXT;
ALTER TABLE public.restaurants ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- ============================================
-- 4. CALCUL PRIX LIVRAISON DYNAMIQUE
-- ============================================

CREATE TABLE IF NOT EXISTS public.delivery_pricing (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(50) NOT NULL,
    base_fee DECIMAL(10,2) NOT NULL DEFAULT 100, -- Frais de base
    per_km_fee DECIMAL(10,2) NOT NULL DEFAULT 30, -- Par km
    min_fee DECIMAL(10,2) NOT NULL DEFAULT 100,
    max_fee DECIMAL(10,2) NOT NULL DEFAULT 500,
    surge_multiplier DECIMAL(3,2) DEFAULT 1.0, -- Multiplicateur rush
    is_active BOOLEAN DEFAULT true
);

INSERT INTO public.delivery_pricing (name, base_fee, per_km_fee, min_fee, max_fee) VALUES
    ('standard', 100, 30, 100, 500)
ON CONFLICT DO NOTHING;

-- Zones avec tarifs spéciaux
CREATE TABLE IF NOT EXISTS public.delivery_zones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    polygon JSONB NOT NULL, -- Coordonnées du polygone
    fee_adjustment DECIMAL(10,2) DEFAULT 0, -- +/- sur le prix
    is_active BOOLEAN DEFAULT true
);

-- ============================================
-- 5. FONCTIONNALITÉS CLIENT INÉDITES
-- ============================================

-- Historique de recherche
CREATE TABLE IF NOT EXISTS public.search_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    query VARCHAR(200) NOT NULL,
    searched_at TIMESTAMPTZ DEFAULT NOW()
);

-- Adresses sauvegardées
CREATE TABLE IF NOT EXISTS public.saved_addresses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    label VARCHAR(50) NOT NULL, -- 'Maison', 'Travail', etc.
    address TEXT NOT NULL,
    latitude DECIMAL(10, 7) NOT NULL,
    longitude DECIMAL(10, 7) NOT NULL,
    instructions TEXT,
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Commandes récurrentes (re-commander facilement)
CREATE TABLE IF NOT EXISTS public.reorder_suggestions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    restaurant_id UUID REFERENCES public.restaurants(id) ON DELETE CASCADE,
    items JSONB NOT NULL, -- Liste des items
    last_ordered_at TIMESTAMPTZ,
    order_count INTEGER DEFAULT 1
);

-- Points fidélité client
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS loyalty_points INTEGER DEFAULT 0;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS total_orders INTEGER DEFAULT 0;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS total_spent DECIMAL(12,2) DEFAULT 0;

-- ============================================
-- 6. INDEXES PERFORMANCE
-- ============================================

CREATE INDEX IF NOT EXISTS idx_notifications_user ON public.notifications(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON public.notifications(notification_type);
CREATE INDEX IF NOT EXISTS idx_menu_items_daily ON public.menu_items(restaurant_id, is_daily_special) WHERE is_daily_special = true;
CREATE INDEX IF NOT EXISTS idx_menu_items_rating ON public.menu_items(restaurant_id, avg_rating DESC);
CREATE INDEX IF NOT EXISTS idx_livreur_tier ON public.livreurs(tier, is_available);
CREATE INDEX IF NOT EXISTS idx_saved_addresses ON public.saved_addresses(customer_id);
CREATE INDEX IF NOT EXISTS idx_livreur_bonuses ON public.livreur_bonuses(livreur_id, earned_at);

-- ============================================
-- 7. RLS POLICIES
-- ============================================

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.livreur_bonuses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.search_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saved_addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menu_item_reviews ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users see own notifications" ON public.notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users manage own addresses" ON public.saved_addresses FOR ALL USING (auth.uid() = customer_id);
CREATE POLICY "Users manage own search history" ON public.search_history FOR ALL USING (auth.uid() = customer_id);
CREATE POLICY "Anyone can read menu reviews" ON public.menu_item_reviews FOR SELECT USING (true);
CREATE POLICY "Customers write menu reviews" ON public.menu_item_reviews FOR INSERT WITH CHECK (auth.uid() = customer_id);
CREATE POLICY "Livreurs see own bonuses" ON public.livreur_bonuses FOR SELECT 
    USING (EXISTS (SELECT 1 FROM public.livreurs WHERE id = livreur_bonuses.livreur_id AND user_id = auth.uid()));



-- ============================================
-- 8. FONCTIONS SYSTÈME LIVREUR
-- ============================================

-- Calculer la commission selon le tier
CREATE OR REPLACE FUNCTION calculate_livreur_commission(
    p_livreur_id UUID,
    p_delivery_fee DECIMAL
)
RETURNS DECIMAL
LANGUAGE plpgsql AS $$
DECLARE
    v_tier livreur_tier;
    v_commission_rate DECIMAL;
    v_is_weekend BOOLEAN;
    v_weekend_bonus DECIMAL;
    v_base_commission DECIMAL;
BEGIN
    -- Récupérer le tier du livreur
    SELECT tier INTO v_tier FROM public.livreurs WHERE id = p_livreur_id;
    
    -- Récupérer le taux de commission
    SELECT commission_rate, weekend_bonus INTO v_commission_rate, v_weekend_bonus 
    FROM public.tier_config WHERE tier = v_tier;
    
    -- Vérifier si c'est le weekend
    v_is_weekend := EXTRACT(DOW FROM NOW()) IN (0, 6);
    
    -- Calculer la commission
    v_base_commission := p_delivery_fee * (v_commission_rate / 100);
    
    IF v_is_weekend THEN
        v_base_commission := v_base_commission * (1 + v_weekend_bonus / 100);
    END IF;
    
    RETURN ROUND(v_base_commission, 2);
END;
$$;

-- Mettre à jour le tier du livreur
CREATE OR REPLACE FUNCTION update_livreur_tier()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
DECLARE
    v_new_tier livreur_tier;
    v_deliveries INTEGER;
    v_rating DECIMAL;
    v_cancel_rate DECIMAL;
BEGIN
    -- Récupérer les stats
    v_deliveries := NEW.total_deliveries;
    v_rating := COALESCE(NEW.rating, 5.0);
    v_cancel_rate := COALESCE(NEW.cancellation_rate, 0);
    
    -- Déterminer le nouveau tier
    IF v_deliveries >= 400 AND v_rating >= 4.6 AND v_cancel_rate <= 5 THEN
        v_new_tier := 'diamond';
    ELSIF v_deliveries >= 150 AND v_rating >= 4.2 AND v_cancel_rate <= 10 THEN
        v_new_tier := 'gold';
    ELSIF v_deliveries >= 50 AND v_rating >= 3.8 AND v_cancel_rate <= 15 THEN
        v_new_tier := 'silver';
    ELSE
        v_new_tier := 'bronze';
    END IF;
    
    -- Mettre à jour si changement
    IF NEW.tier IS DISTINCT FROM v_new_tier THEN
        NEW.tier := v_new_tier;
        
        -- Notifier le livreur du changement de tier
        INSERT INTO public.notifications (user_id, title, body, notification_type, data)
        SELECT user_id, 
            CASE v_new_tier 
                WHEN 'diamond' THEN '💎 Félicitations! Niveau Diamant!'
                WHEN 'gold' THEN '🥇 Bravo! Niveau Or atteint!'
                WHEN 'silver' THEN '🥈 Niveau Argent débloqué!'
                ELSE '🥉 Bienvenue niveau Bronze'
            END,
            'Votre nouveau taux de commission: ' || 
            (SELECT commission_rate FROM public.tier_config WHERE tier = v_new_tier) || '%',
            'tier_change',
            jsonb_build_object('new_tier', v_new_tier::text)
        FROM public.livreurs WHERE id = NEW.id;
    END IF;
    
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS update_livreur_tier_trigger ON public.livreurs;
CREATE TRIGGER update_livreur_tier_trigger
    BEFORE UPDATE ON public.livreurs
    FOR EACH ROW EXECUTE FUNCTION update_livreur_tier();

-- Vérifier et attribuer les bonus
CREATE OR REPLACE FUNCTION check_livreur_daily_bonus(p_livreur_id UUID)
RETURNS VOID
LANGUAGE plpgsql AS $$
DECLARE
    v_today_deliveries INTEGER;
    v_target RECORD;
    v_already_earned BOOLEAN;
BEGIN
    -- Compter les livraisons du jour
    SELECT COUNT(*) INTO v_today_deliveries
    FROM public.orders
    WHERE livreur_id = p_livreur_id 
    AND status = 'delivered'
    AND DATE(delivered_at) = CURRENT_DATE;
    
    -- Vérifier chaque objectif journalier
    FOR v_target IN SELECT * FROM public.livreur_targets WHERE target_type = 'daily' AND is_active = true LOOP
        -- Vérifier si déjà gagné aujourd'hui
        SELECT EXISTS (
            SELECT 1 FROM public.livreur_bonuses 
            WHERE livreur_id = p_livreur_id 
            AND bonus_type = 'daily_target'
            AND amount = v_target.bonus_amount
            AND DATE(earned_at) = CURRENT_DATE
        ) INTO v_already_earned;
        
        IF NOT v_already_earned AND v_today_deliveries >= v_target.deliveries_required THEN
            INSERT INTO public.livreur_bonuses (livreur_id, bonus_type, amount, description)
            VALUES (p_livreur_id, 'daily_target', v_target.bonus_amount, 
                    v_target.deliveries_required || ' livraisons aujourd''hui!');
            
            UPDATE public.livreurs SET bonus_earned = bonus_earned + v_target.bonus_amount
            WHERE id = p_livreur_id;
        END IF;
    END LOOP;
END;
$$;

-- ============================================
-- 9. CALCUL PRIX LIVRAISON DYNAMIQUE
-- ============================================

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
)
LANGUAGE plpgsql AS $$
DECLARE
    v_distance DECIMAL;
    v_pricing RECORD;
    v_base DECIMAL;
    v_per_km DECIMAL;
    v_total DECIMAL;
    v_time INTEGER;
BEGIN
    -- Calculer la distance (formule Haversine simplifiée)
    v_distance := 6371 * ACOS(
        COS(RADIANS(p_restaurant_lat)) * COS(RADIANS(p_customer_lat)) *
        COS(RADIANS(p_customer_lng) - RADIANS(p_restaurant_lng)) +
        SIN(RADIANS(p_restaurant_lat)) * SIN(RADIANS(p_customer_lat))
    );
    
    -- Récupérer la config de prix
    SELECT * INTO v_pricing FROM public.delivery_pricing WHERE is_active = true LIMIT 1;
    
    v_base := COALESCE(v_pricing.base_fee, 100);
    v_per_km := COALESCE(v_pricing.per_km_fee, 30);
    
    -- Calculer le total
    v_total := v_base + (v_distance * v_per_km);
    
    -- Appliquer min/max
    v_total := GREATEST(COALESCE(v_pricing.min_fee, 100), LEAST(v_total, COALESCE(v_pricing.max_fee, 500)));
    
    -- Estimer le temps (3 min/km + 10 min préparation)
    v_time := CEIL(v_distance * 3) + 10;
    
    RETURN QUERY SELECT 
        ROUND(v_distance, 2),
        v_base,
        ROUND(v_distance * v_per_km, 2),
        ROUND(v_total, 0),
        v_time;
END;
$$;

-- ============================================
-- 10. TOP RESTAURANTS & MENUS
-- ============================================

CREATE OR REPLACE FUNCTION get_top_restaurants(p_limit INTEGER DEFAULT 10)
RETURNS TABLE (
    id UUID,
    name VARCHAR,
    logo_url TEXT,
    cover_url TEXT,
    cuisine_type VARCHAR,
    rating DECIMAL,
    total_reviews INTEGER,
    total_orders INTEGER,
    avg_delivery_time INTEGER
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT 
        r.id, r.name, r.logo_url, r.cover_url, r.cuisine_type,
        COALESCE(r.rating, 0)::DECIMAL,
        COALESCE(r.total_reviews, 0),
        COALESCE((SELECT COUNT(*) FROM public.orders WHERE restaurant_id = r.id AND status = 'delivered'), 0)::INTEGER,
        COALESCE(r.avg_prep_time, 30)
    FROM public.restaurants r
    WHERE r.is_verified = true AND r.is_open = true
    ORDER BY r.rating DESC NULLS LAST, r.total_reviews DESC
    LIMIT p_limit;
END;
$$;

CREATE OR REPLACE FUNCTION get_top_menu_items(p_restaurant_id UUID DEFAULT NULL, p_limit INTEGER DEFAULT 20)
RETURNS TABLE (
    id UUID,
    name VARCHAR,
    description TEXT,
    price DECIMAL,
    image_url TEXT,
    restaurant_id UUID,
    restaurant_name VARCHAR,
    avg_rating DECIMAL,
    order_count INTEGER,
    is_daily_special BOOLEAN
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT 
        mi.id, mi.name, mi.description, mi.price, mi.image_url,
        mi.restaurant_id, r.name,
        COALESCE(mi.avg_rating, 0)::DECIMAL,
        COALESCE(mi.order_count, 0),
        COALESCE(mi.is_daily_special, false)
    FROM public.menu_items mi
    JOIN public.restaurants r ON mi.restaurant_id = r.id
    WHERE mi.is_available = true
    AND r.is_verified = true
    AND (p_restaurant_id IS NULL OR mi.restaurant_id = p_restaurant_id)
    ORDER BY mi.order_count DESC, mi.avg_rating DESC
    LIMIT p_limit;
END;
$$;

-- ============================================
-- 11. MISE À JOUR STATS APRÈS LIVRAISON
-- ============================================

CREATE OR REPLACE FUNCTION after_delivery_complete()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
DECLARE
    v_commission DECIMAL;
BEGIN
    IF NEW.status = 'delivered' AND OLD.status != 'delivered' THEN
        -- Calculer la commission du livreur
        v_commission := calculate_livreur_commission(NEW.livreur_id, NEW.delivery_fee);
        
        -- Mettre à jour la commande avec la commission
        NEW.livreur_commission := v_commission;
        
        -- Mettre à jour les stats du livreur
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
        
        -- Vérifier les bonus
        PERFORM check_livreur_daily_bonus(NEW.livreur_id);
        
        -- Mettre à jour les stats client
        UPDATE public.profiles SET
            total_orders = total_orders + 1,
            total_spent = total_spent + NEW.total,
            loyalty_points = loyalty_points + FLOOR(NEW.total / 100) -- 1 point par 100 DA
        WHERE id = NEW.customer_id;
        
        -- Mettre à jour le compteur des plats commandés
        UPDATE public.menu_items mi SET
            order_count = order_count + oi.quantity,
            last_ordered_at = NOW()
        FROM public.order_items oi
        WHERE oi.order_id = NEW.id AND mi.id = oi.menu_item_id;
    END IF;
    
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS after_delivery_complete_trigger ON public.orders;
CREATE TRIGGER after_delivery_complete_trigger
    BEFORE UPDATE ON public.orders
    FOR EACH ROW EXECUTE FUNCTION after_delivery_complete();

-- Reset hebdomadaire des stats livreur (à exécuter via cron)
CREATE OR REPLACE FUNCTION reset_weekly_stats()
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE public.livreurs SET weekly_deliveries = 0;
END;
$$;

-- Reset mensuel
CREATE OR REPLACE FUNCTION reset_monthly_stats()
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE public.livreurs SET monthly_deliveries = 0;
END;
$$;
