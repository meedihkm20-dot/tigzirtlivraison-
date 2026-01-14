-- ============================================
-- MIGRATION 022: PREMIUM FEATURES
-- Restaurant Dashboard, Analytics, Stocks, etc.
-- ============================================

-- 1. RESTAURANT ANALYTICS
-- ============================================

-- Table pour stocker les stats journalières (cache)
CREATE TABLE IF NOT EXISTS restaurant_daily_stats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    restaurant_id UUID REFERENCES restaurants(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    orders_count INTEGER DEFAULT 0,
    revenue DECIMAL(10,2) DEFAULT 0,
    avg_order_value DECIMAL(10,2) DEFAULT 0,
    avg_prep_time INTEGER DEFAULT 0,
    cancelled_count INTEGER DEFAULT 0,
    avg_rating DECIMAL(3,2) DEFAULT 0,
    reviews_count INTEGER DEFAULT 0,
    peak_hour INTEGER, -- 0-23
    top_item_id UUID REFERENCES menu_items(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(restaurant_id, date)
);

-- Index pour requêtes rapides
CREATE INDEX idx_restaurant_daily_stats_date ON restaurant_daily_stats(restaurant_id, date DESC);

-- 2. GESTION DES STOCKS
-- ============================================

-- Ajouter colonnes stock aux menu_items
ALTER TABLE menu_items ADD COLUMN IF NOT EXISTS stock_quantity INTEGER;
ALTER TABLE menu_items ADD COLUMN IF NOT EXISTS low_stock_threshold INTEGER DEFAULT 10;
ALTER TABLE menu_items ADD COLUMN IF NOT EXISTS track_stock BOOLEAN DEFAULT false;
ALTER TABLE menu_items ADD COLUMN IF NOT EXISTS auto_disable_on_stockout BOOLEAN DEFAULT true;

-- Table historique des stocks
CREATE TABLE IF NOT EXISTS stock_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    menu_item_id UUID REFERENCES menu_items(id) ON DELETE CASCADE,
    previous_quantity INTEGER,
    new_quantity INTEGER,
    change_reason VARCHAR(50), -- 'order', 'manual', 'restock', 'adjustment'
    order_id UUID REFERENCES orders(id),
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_stock_history_item ON stock_history(menu_item_id, created_at DESC);

-- 3. BADGES & CERTIFICATIONS RESTAURANT
-- ============================================

CREATE TABLE IF NOT EXISTS restaurant_badges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    restaurant_id UUID REFERENCES restaurants(id) ON DELETE CASCADE,
    badge_type VARCHAR(50) NOT NULL, -- 'verified', 'top_rated', 'fast_delivery', 'hygiene_a', 'eco_friendly', 'popular'
    earned_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    metadata JSONB DEFAULT '{}',
    UNIQUE(restaurant_id, badge_type)
);

-- 4. GALERIE PHOTOS RESTAURANT
-- ============================================

CREATE TABLE IF NOT EXISTS restaurant_gallery (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    restaurant_id UUID REFERENCES restaurants(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    image_type VARCHAR(30) DEFAULT 'general', -- 'cover', 'interior', 'food', 'team', 'general'
    caption TEXT,
    sort_order INTEGER DEFAULT 0,
    is_featured BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_restaurant_gallery ON restaurant_gallery(restaurant_id, sort_order);

-- 5. HORAIRES DÉTAILLÉS
-- ============================================

CREATE TABLE IF NOT EXISTS restaurant_hours (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    restaurant_id UUID REFERENCES restaurants(id) ON DELETE CASCADE,
    day_of_week INTEGER NOT NULL, -- 0=Dimanche, 1=Lundi, etc.
    open_time TIME,
    close_time TIME,
    is_closed BOOLEAN DEFAULT false,
    UNIQUE(restaurant_id, day_of_week)
);

-- 6. ÉQUIPE RESTAURANT
-- ============================================

CREATE TABLE IF NOT EXISTS restaurant_staff (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    restaurant_id UUID REFERENCES restaurants(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id),
    role VARCHAR(30) NOT NULL, -- 'owner', 'manager', 'chef', 'staff'
    permissions JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. RAPPORTS AUTOMATIQUES
-- ============================================

CREATE TABLE IF NOT EXISTS restaurant_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    restaurant_id UUID REFERENCES restaurants(id) ON DELETE CASCADE,
    report_type VARCHAR(30) NOT NULL, -- 'daily', 'weekly', 'monthly'
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    data JSONB NOT NULL,
    generated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_restaurant_reports ON restaurant_reports(restaurant_id, report_type, period_start DESC);

-- 8. PRÉFÉRENCES UTILISATEUR (Mode sombre, etc.)
-- ============================================

CREATE TABLE IF NOT EXISTS user_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
    dark_mode BOOLEAN DEFAULT false,
    notifications_enabled BOOLEAN DEFAULT true,
    sound_enabled BOOLEAN DEFAULT true,
    haptic_enabled BOOLEAN DEFAULT true,
    language VARCHAR(5) DEFAULT 'fr',
    currency VARCHAR(3) DEFAULT 'DZD',
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. ANALYTICS EVENTS
-- ============================================

CREATE TABLE IF NOT EXISTS analytics_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id),
    event_type VARCHAR(50) NOT NULL,
    event_data JSONB DEFAULT '{}',
    screen_name VARCHAR(100),
    session_id VARCHAR(100),
    device_info JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_analytics_events_user ON analytics_events(user_id, created_at DESC);
CREATE INDEX idx_analytics_events_type ON analytics_events(event_type, created_at DESC);

-- 10. SUGGESTIONS IA
-- ============================================

CREATE TABLE IF NOT EXISTS ai_suggestions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    restaurant_id UUID REFERENCES restaurants(id) ON DELETE CASCADE,
    suggestion_type VARCHAR(50) NOT NULL, -- 'promo', 'stock', 'menu', 'pricing', 'hours'
    title TEXT NOT NULL,
    description TEXT,
    action_data JSONB DEFAULT '{}',
    priority INTEGER DEFAULT 0, -- 0=low, 1=medium, 2=high
    is_read BOOLEAN DEFAULT false,
    is_dismissed BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ
);

CREATE INDEX idx_ai_suggestions ON ai_suggestions(restaurant_id, is_dismissed, created_at DESC);

-- 11. FONCTIONS ANALYTICS
-- ============================================

-- Fonction pour calculer les stats journalières
CREATE OR REPLACE FUNCTION calculate_daily_stats(p_restaurant_id UUID, p_date DATE)
RETURNS void AS $$
DECLARE
    v_orders_count INTEGER;
    v_revenue DECIMAL(10,2);
    v_avg_order DECIMAL(10,2);
    v_avg_prep INTEGER;
    v_cancelled INTEGER;
    v_avg_rating DECIMAL(3,2);
    v_reviews INTEGER;
    v_peak_hour INTEGER;
    v_top_item UUID;
BEGIN
    -- Compter les commandes
    SELECT 
        COUNT(*),
        COALESCE(SUM(total), 0),
        COALESCE(AVG(total), 0),
        COALESCE(AVG(EXTRACT(EPOCH FROM (prepared_at - confirmed_at))/60), 0)::INTEGER
    INTO v_orders_count, v_revenue, v_avg_order, v_avg_prep
    FROM orders
    WHERE restaurant_id = p_restaurant_id
      AND DATE(created_at) = p_date
      AND status = 'delivered';
    
    -- Commandes annulées
    SELECT COUNT(*) INTO v_cancelled
    FROM orders
    WHERE restaurant_id = p_restaurant_id
      AND DATE(created_at) = p_date
      AND status = 'cancelled';
    
    -- Note moyenne du jour
    SELECT COALESCE(AVG(rating), 0), COUNT(*)
    INTO v_avg_rating, v_reviews
    FROM reviews
    WHERE restaurant_id = p_restaurant_id
      AND DATE(created_at) = p_date;
    
    -- Heure de pointe
    SELECT EXTRACT(HOUR FROM created_at)::INTEGER INTO v_peak_hour
    FROM orders
    WHERE restaurant_id = p_restaurant_id
      AND DATE(created_at) = p_date
    GROUP BY EXTRACT(HOUR FROM created_at)
    ORDER BY COUNT(*) DESC
    LIMIT 1;
    
    -- Plat le plus commandé
    SELECT oi.menu_item_id INTO v_top_item
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.id
    WHERE o.restaurant_id = p_restaurant_id
      AND DATE(o.created_at) = p_date
    GROUP BY oi.menu_item_id
    ORDER BY SUM(oi.quantity) DESC
    LIMIT 1;
    
    -- Insérer ou mettre à jour
    INSERT INTO restaurant_daily_stats (
        restaurant_id, date, orders_count, revenue, avg_order_value,
        avg_prep_time, cancelled_count, avg_rating, reviews_count,
        peak_hour, top_item_id
    ) VALUES (
        p_restaurant_id, p_date, v_orders_count, v_revenue, v_avg_order,
        v_avg_prep, v_cancelled, v_avg_rating, v_reviews,
        v_peak_hour, v_top_item
    )
    ON CONFLICT (restaurant_id, date) DO UPDATE SET
        orders_count = EXCLUDED.orders_count,
        revenue = EXCLUDED.revenue,
        avg_order_value = EXCLUDED.avg_order_value,
        avg_prep_time = EXCLUDED.avg_prep_time,
        cancelled_count = EXCLUDED.cancelled_count,
        avg_rating = EXCLUDED.avg_rating,
        reviews_count = EXCLUDED.reviews_count,
        peak_hour = EXCLUDED.peak_hour,
        top_item_id = EXCLUDED.top_item_id;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour obtenir les stats de la semaine
CREATE OR REPLACE FUNCTION get_restaurant_weekly_stats(p_restaurant_id UUID)
RETURNS TABLE (
    date DATE,
    orders_count INTEGER,
    revenue DECIMAL(10,2),
    avg_rating DECIMAL(3,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        rds.date,
        rds.orders_count,
        rds.revenue,
        rds.avg_rating
    FROM restaurant_daily_stats rds
    WHERE rds.restaurant_id = p_restaurant_id
      AND rds.date >= CURRENT_DATE - INTERVAL '7 days'
    ORDER BY rds.date ASC;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour obtenir les plats populaires
CREATE OR REPLACE FUNCTION get_popular_items(p_restaurant_id UUID, p_limit INTEGER DEFAULT 5)
RETURNS TABLE (
    item_id UUID,
    item_name VARCHAR,
    item_price DECIMAL,
    item_image TEXT,
    total_orders BIGINT,
    avg_rating DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        mi.id,
        mi.name,
        mi.price,
        mi.image_url,
        COALESCE(SUM(oi.quantity), 0) as total_orders,
        COALESCE(mi.avg_rating, 0) as avg_rating
    FROM menu_items mi
    LEFT JOIN order_items oi ON mi.id = oi.menu_item_id
    LEFT JOIN orders o ON oi.order_id = o.id AND o.status = 'delivered'
    WHERE mi.restaurant_id = p_restaurant_id
      AND mi.is_available = true
    GROUP BY mi.id
    ORDER BY total_orders DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour vérifier les stocks bas
CREATE OR REPLACE FUNCTION check_low_stock(p_restaurant_id UUID)
RETURNS TABLE (
    item_id UUID,
    item_name VARCHAR,
    current_stock INTEGER,
    threshold INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        mi.id,
        mi.name,
        mi.stock_quantity,
        mi.low_stock_threshold
    FROM menu_items mi
    WHERE mi.restaurant_id = p_restaurant_id
      AND mi.track_stock = true
      AND mi.stock_quantity IS NOT NULL
      AND mi.stock_quantity <= mi.low_stock_threshold;
END;
$$ LANGUAGE plpgsql;

-- 12. TRIGGERS
-- ============================================

-- Trigger pour décrémenter le stock après commande
CREATE OR REPLACE FUNCTION decrement_stock_on_order()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'confirmed' AND OLD.status = 'pending' THEN
        -- Décrémenter le stock pour chaque item
        UPDATE menu_items mi
        SET stock_quantity = stock_quantity - oi.quantity
        FROM order_items oi
        WHERE oi.order_id = NEW.id
          AND mi.id = oi.menu_item_id
          AND mi.track_stock = true
          AND mi.stock_quantity IS NOT NULL;
        
        -- Désactiver les items en rupture
        UPDATE menu_items
        SET is_available = false
        WHERE restaurant_id = NEW.restaurant_id
          AND track_stock = true
          AND auto_disable_on_stockout = true
          AND stock_quantity <= 0;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_decrement_stock ON orders;
CREATE TRIGGER trigger_decrement_stock
    AFTER UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION decrement_stock_on_order();

-- Trigger pour calculer les stats à minuit
-- (À exécuter via pg_cron ou Edge Function)

-- 13. VUES UTILES
-- ============================================

-- Vue pour le dashboard restaurant
CREATE OR REPLACE VIEW v_restaurant_dashboard AS
SELECT 
    r.id as restaurant_id,
    r.name,
    r.is_open,
    r.rating,
    r.total_reviews,
    -- Stats aujourd'hui
    COALESCE(today.orders_count, 0) as orders_today,
    COALESCE(today.revenue, 0) as revenue_today,
    -- Stats semaine
    COALESCE(week.orders_count, 0) as orders_week,
    COALESCE(week.revenue, 0) as revenue_week,
    -- Commandes en cours
    (SELECT COUNT(*) FROM orders o WHERE o.restaurant_id = r.id AND o.status IN ('pending', 'confirmed', 'preparing')) as pending_orders,
    -- Livreurs actifs
    (SELECT COUNT(DISTINCT l.id) FROM livreurs l 
     JOIN orders o ON o.livreur_id = l.id 
     WHERE o.restaurant_id = r.id AND o.status IN ('confirmed', 'preparing', 'ready', 'picked_up')
     AND l.is_online = true) as active_livreurs
FROM restaurants r
LEFT JOIN restaurant_daily_stats today ON r.id = today.restaurant_id AND today.date = CURRENT_DATE
LEFT JOIN (
    SELECT restaurant_id, SUM(orders_count) as orders_count, SUM(revenue) as revenue
    FROM restaurant_daily_stats
    WHERE date >= CURRENT_DATE - INTERVAL '7 days'
    GROUP BY restaurant_id
) week ON r.id = week.restaurant_id;

-- 14. DONNÉES INITIALES
-- ============================================

-- Insérer les badges par défaut pour les restaurants vérifiés
INSERT INTO restaurant_badges (restaurant_id, badge_type)
SELECT id, 'verified'
FROM restaurants
WHERE is_verified = true
ON CONFLICT DO NOTHING;

-- Créer les préférences par défaut pour les utilisateurs existants
INSERT INTO user_preferences (user_id)
SELECT id FROM auth.users
ON CONFLICT DO NOTHING;

-- Créer les horaires par défaut (7j/7, 8h-23h)
INSERT INTO restaurant_hours (restaurant_id, day_of_week, open_time, close_time)
SELECT r.id, d.day, '08:00'::TIME, '23:00'::TIME
FROM restaurants r
CROSS JOIN generate_series(0, 6) as d(day)
ON CONFLICT DO NOTHING;
