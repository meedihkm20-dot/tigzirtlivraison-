-- DZ Delivery - Enhanced Features Migration
-- Migration: Promos, Kitchen Display, Ratings, Favorites, Menu Photos

-- ============================================
-- PROMOTIONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.promotions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    restaurant_id UUID REFERENCES public.restaurants(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    discount_type VARCHAR(20) NOT NULL CHECK (discount_type IN ('percentage', 'fixed')),
    discount_value DECIMAL(10, 2) NOT NULL,
    min_order_amount DECIMAL(10, 2) DEFAULT 0,
    max_discount DECIMAL(10, 2), -- Pour les % (plafond)
    code VARCHAR(20) UNIQUE, -- Code promo optionnel
    is_active BOOLEAN DEFAULT true,
    starts_at TIMESTAMPTZ DEFAULT NOW(),
    ends_at TIMESTAMPTZ,
    usage_limit INTEGER, -- Nombre max d'utilisations
    usage_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- CUSTOMER FAVORITES
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
-- MENU ITEM VARIANTS (Tailles, Options)
-- ============================================
CREATE TABLE IF NOT EXISTS public.menu_item_variants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    menu_item_id UUID REFERENCES public.menu_items(id) ON DELETE CASCADE,
    name VARCHAR(50) NOT NULL, -- Ex: "Petit", "Moyen", "Grand"
    price_adjustment DECIMAL(10, 2) DEFAULT 0, -- +50 DA pour grand
    is_default BOOLEAN DEFAULT false,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.menu_item_extras (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    menu_item_id UUID REFERENCES public.menu_items(id) ON DELETE CASCADE,
    name VARCHAR(50) NOT NULL, -- Ex: "Fromage supplémentaire"
    price DECIMAL(10, 2) NOT NULL,
    is_available BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- LIVREUR BADGES & STATS
-- ============================================
CREATE TABLE IF NOT EXISTS public.livreur_badges (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    livreur_id UUID REFERENCES public.livreurs(id) ON DELETE CASCADE,
    badge_type VARCHAR(50) NOT NULL, -- 'first_delivery', '100_deliveries', '5_stars', 'speed_demon'
    earned_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(livreur_id, badge_type)
);

-- ============================================
-- ADD COLUMNS TO EXISTING TABLES
-- ============================================

-- Menu items: ajout champs pour photos et popularité
ALTER TABLE public.menu_items ADD COLUMN IF NOT EXISTS calories INTEGER;
ALTER TABLE public.menu_items ADD COLUMN IF NOT EXISTS is_vegetarian BOOLEAN DEFAULT false;
ALTER TABLE public.menu_items ADD COLUMN IF NOT EXISTS is_spicy BOOLEAN DEFAULT false;
ALTER TABLE public.menu_items ADD COLUMN IF NOT EXISTS allergens TEXT[];
ALTER TABLE public.menu_items ADD COLUMN IF NOT EXISTS order_count INTEGER DEFAULT 0;

-- Orders: ajout promo appliquée
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS promotion_id UUID REFERENCES public.promotions(id);
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS promo_code VARCHAR(20);
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS promo_discount DECIMAL(10, 2) DEFAULT 0;

-- Restaurants: ajout champs
ALTER TABLE public.restaurants ADD COLUMN IF NOT EXISTS cover_images TEXT[]; -- Plusieurs images
ALTER TABLE public.restaurants ADD COLUMN IF NOT EXISTS tags TEXT[]; -- Tags cuisine
ALTER TABLE public.restaurants ADD COLUMN IF NOT EXISTS accepts_preorders BOOLEAN DEFAULT false;

-- Livreurs: stats additionnelles
ALTER TABLE public.livreurs ADD COLUMN IF NOT EXISTS total_distance_km DECIMAL(10, 2) DEFAULT 0;
ALTER TABLE public.livreurs ADD COLUMN IF NOT EXISTS avg_delivery_time INTEGER; -- minutes
ALTER TABLE public.livreurs ADD COLUMN IF NOT EXISTS acceptance_rate DECIMAL(5, 2) DEFAULT 100;

-- ============================================
-- INDEXES
-- ============================================
CREATE INDEX IF NOT EXISTS idx_promotions_restaurant ON public.promotions(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_promotions_active ON public.promotions(is_active, starts_at, ends_at);
CREATE INDEX IF NOT EXISTS idx_promotions_code ON public.promotions(code) WHERE code IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_favorites_customer ON public.favorites(customer_id);
CREATE INDEX IF NOT EXISTS idx_favorite_items_customer ON public.favorite_items(customer_id);
CREATE INDEX IF NOT EXISTS idx_menu_items_popular ON public.menu_items(restaurant_id, order_count DESC);

-- ============================================
-- RLS POLICIES
-- ============================================
ALTER TABLE public.promotions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favorite_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menu_item_variants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menu_item_extras ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.livreur_badges ENABLE ROW LEVEL SECURITY;

-- Promotions: visibles par tous, gérées par le resto
CREATE POLICY "Promotions viewable by everyone" ON public.promotions FOR SELECT USING (true);
CREATE POLICY "Restaurant owners manage promotions" ON public.promotions FOR ALL
    USING (EXISTS (SELECT 1 FROM public.restaurants WHERE id = promotions.restaurant_id AND owner_id = auth.uid()));

-- Favorites: gérés par le client
CREATE POLICY "Users manage their favorites" ON public.favorites FOR ALL USING (auth.uid() = customer_id);
CREATE POLICY "Users manage their favorite items" ON public.favorite_items FOR ALL USING (auth.uid() = customer_id);

-- Variants/Extras: visibles par tous
CREATE POLICY "Variants viewable by everyone" ON public.menu_item_variants FOR SELECT USING (true);
CREATE POLICY "Extras viewable by everyone" ON public.menu_item_extras FOR SELECT USING (true);
CREATE POLICY "Restaurant owners manage variants" ON public.menu_item_variants FOR ALL
    USING (EXISTS (SELECT 1 FROM public.menu_items mi JOIN public.restaurants r ON mi.restaurant_id = r.id 
                   WHERE mi.id = menu_item_variants.menu_item_id AND r.owner_id = auth.uid()));
CREATE POLICY "Restaurant owners manage extras" ON public.menu_item_extras FOR ALL
    USING (EXISTS (SELECT 1 FROM public.menu_items mi JOIN public.restaurants r ON mi.restaurant_id = r.id 
                   WHERE mi.id = menu_item_extras.menu_item_id AND r.owner_id = auth.uid()));

-- Badges: visibles par tous
CREATE POLICY "Badges viewable by everyone" ON public.livreur_badges FOR SELECT USING (true);

-- ============================================
-- FUNCTIONS
-- ============================================

-- Appliquer une promotion
CREATE OR REPLACE FUNCTION apply_promotion(
    p_order_id UUID,
    p_promo_code VARCHAR
)
RETURNS TABLE (success BOOLEAN, discount DECIMAL, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_promo RECORD;
    v_order RECORD;
    v_discount DECIMAL;
BEGIN
    -- Récupérer la commande
    SELECT * INTO v_order FROM public.orders WHERE id = p_order_id;
    IF NOT FOUND THEN
        RETURN QUERY SELECT false, 0::DECIMAL, 'Commande non trouvée'::TEXT;
        RETURN;
    END IF;

    -- Récupérer la promo
    SELECT * INTO v_promo FROM public.promotions 
    WHERE code = p_promo_code 
    AND is_active = true
    AND (starts_at IS NULL OR starts_at <= NOW())
    AND (ends_at IS NULL OR ends_at >= NOW())
    AND (usage_limit IS NULL OR usage_count < usage_limit)
    AND (restaurant_id IS NULL OR restaurant_id = v_order.restaurant_id);

    IF NOT FOUND THEN
        RETURN QUERY SELECT false, 0::DECIMAL, 'Code promo invalide ou expiré'::TEXT;
        RETURN;
    END IF;

    -- Vérifier montant minimum
    IF v_order.subtotal < v_promo.min_order_amount THEN
        RETURN QUERY SELECT false, 0::DECIMAL, ('Minimum de commande: ' || v_promo.min_order_amount || ' DA')::TEXT;
        RETURN;
    END IF;

    -- Calculer la réduction
    IF v_promo.discount_type = 'percentage' THEN
        v_discount := v_order.subtotal * v_promo.discount_value / 100;
        IF v_promo.max_discount IS NOT NULL AND v_discount > v_promo.max_discount THEN
            v_discount := v_promo.max_discount;
        END IF;
    ELSE
        v_discount := v_promo.discount_value;
    END IF;

    -- Appliquer
    UPDATE public.orders SET 
        promotion_id = v_promo.id,
        promo_code = p_promo_code,
        promo_discount = v_discount,
        discount = v_discount,
        total = subtotal + delivery_fee + service_fee - v_discount
    WHERE id = p_order_id;

    -- Incrémenter usage
    UPDATE public.promotions SET usage_count = usage_count + 1 WHERE id = v_promo.id;

    RETURN QUERY SELECT true, v_discount, ('Réduction de ' || v_discount || ' DA appliquée!')::TEXT;
END;
$$;

-- Ajouter un avis (restaurant + livreur)
CREATE OR REPLACE FUNCTION submit_review(
    p_order_id UUID,
    p_restaurant_rating INTEGER,
    p_livreur_rating INTEGER,
    p_comment TEXT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_order RECORD;
BEGIN
    SELECT * INTO v_order FROM public.orders WHERE id = p_order_id AND status = 'delivered';
    IF NOT FOUND THEN RETURN false; END IF;

    -- Vérifier que c'est bien le client
    IF v_order.customer_id != auth.uid() THEN RETURN false; END IF;

    -- Insérer ou mettre à jour l'avis
    INSERT INTO public.reviews (order_id, customer_id, restaurant_id, livreur_id, restaurant_rating, livreur_rating, comment)
    VALUES (p_order_id, auth.uid(), v_order.restaurant_id, v_order.livreur_id, p_restaurant_rating, p_livreur_rating, p_comment)
    ON CONFLICT (order_id) DO UPDATE SET
        restaurant_rating = p_restaurant_rating,
        livreur_rating = p_livreur_rating,
        comment = p_comment;

    RETURN true;
END;
$$;

-- Mettre à jour les stats livreur après livraison
CREATE OR REPLACE FUNCTION update_livreur_stats_enhanced()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.status = 'delivered' AND OLD.status != 'delivered' THEN
        -- Mettre à jour les stats
        UPDATE public.livreurs SET
            total_deliveries = total_deliveries + 1,
            total_earnings = total_earnings + COALESCE(NEW.livreur_commission, 0),
            avg_delivery_time = (
                SELECT AVG(EXTRACT(EPOCH FROM (delivered_at - picked_up_at)) / 60)::INTEGER
                FROM public.orders WHERE livreur_id = NEW.livreur_id AND status = 'delivered'
            )
        WHERE id = NEW.livreur_id;

        -- Vérifier badges
        PERFORM check_livreur_badges(NEW.livreur_id);
    END IF;
    RETURN NEW;
END;
$$;

-- Vérifier et attribuer badges
CREATE OR REPLACE FUNCTION check_livreur_badges(p_livreur_id UUID)
RETURNS VOID
LANGUAGE plpgsql AS $$
DECLARE
    v_livreur RECORD;
BEGIN
    SELECT * INTO v_livreur FROM public.livreurs WHERE id = p_livreur_id;
    
    -- Badge première livraison
    IF v_livreur.total_deliveries = 1 THEN
        INSERT INTO public.livreur_badges (livreur_id, badge_type) 
        VALUES (p_livreur_id, 'first_delivery') ON CONFLICT DO NOTHING;
    END IF;
    
    -- Badge 50 livraisons
    IF v_livreur.total_deliveries >= 50 THEN
        INSERT INTO public.livreur_badges (livreur_id, badge_type) 
        VALUES (p_livreur_id, '50_deliveries') ON CONFLICT DO NOTHING;
    END IF;
    
    -- Badge 100 livraisons
    IF v_livreur.total_deliveries >= 100 THEN
        INSERT INTO public.livreur_badges (livreur_id, badge_type) 
        VALUES (p_livreur_id, '100_deliveries') ON CONFLICT DO NOTHING;
    END IF;
    
    -- Badge 5 étoiles (moyenne >= 4.8)
    IF v_livreur.rating >= 4.8 AND v_livreur.total_deliveries >= 10 THEN
        INSERT INTO public.livreur_badges (livreur_id, badge_type) 
        VALUES (p_livreur_id, '5_stars') ON CONFLICT DO NOTHING;
    END IF;
END;
$$;

-- Incrémenter compteur commandes plat
CREATE OR REPLACE FUNCTION increment_menu_item_orders()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE public.menu_items SET order_count = order_count + NEW.quantity
    WHERE id = NEW.menu_item_id;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS increment_menu_item_orders_trigger ON public.order_items;
CREATE TRIGGER increment_menu_item_orders_trigger
    AFTER INSERT ON public.order_items
    FOR EACH ROW EXECUTE FUNCTION increment_menu_item_orders();

-- Remplacer le trigger livreur stats
DROP TRIGGER IF EXISTS update_livreur_stats_trigger ON public.orders;
CREATE TRIGGER update_livreur_stats_enhanced_trigger
    AFTER UPDATE ON public.orders
    FOR EACH ROW EXECUTE FUNCTION update_livreur_stats_enhanced();
