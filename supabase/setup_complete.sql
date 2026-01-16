-- ============================================================
-- SETUP COMPLET - DZ DELIVERY
-- ============================================================
-- Ce script contient toutes les corrections et données de test
-- Exécuter après SCHEMA_FINAL.sql
-- ============================================================

-- ============================================
-- 1. FONCTIONS MANQUANTES
-- ============================================

-- Top restaurants
CREATE OR REPLACE FUNCTION get_top_restaurants(p_limit INTEGER DEFAULT 10)
RETURNS TABLE (
    id UUID, name VARCHAR, description TEXT, logo_url TEXT, cover_url TEXT,
    cuisine_type VARCHAR, rating DECIMAL, delivery_fee DECIMAL, 
    avg_prep_time INTEGER, is_open BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT r.id, r.name, r.description, r.logo_url, r.cover_url,
        r.cuisine_type, r.rating, r.delivery_fee, r.avg_prep_time, r.is_open
    FROM public.restaurants r
    WHERE r.is_verified = true
    ORDER BY r.rating DESC, r.total_reviews DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- Plats du jour
CREATE OR REPLACE FUNCTION get_daily_specials()
RETURNS TABLE (
    id UUID, name VARCHAR, description TEXT, price DECIMAL, image_url TEXT,
    restaurant_id UUID, restaurant_name VARCHAR, daily_special_price DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT mi.id, mi.name, mi.description, mi.price, mi.image_url,
        mi.restaurant_id, r.name as restaurant_name,
        (mi.price * 0.8)::DECIMAL as daily_special_price
    FROM public.menu_items mi
    JOIN public.restaurants r ON r.id = mi.restaurant_id
    WHERE mi.is_available = true AND mi.is_popular = true AND r.is_verified = true
    ORDER BY mi.order_count DESC
    LIMIT 5;
END;
$$ LANGUAGE plpgsql;

-- Top menu items
CREATE OR REPLACE FUNCTION get_top_menu_items(limit_count INTEGER DEFAULT 10)
RETURNS TABLE (
    id UUID, name VARCHAR, description TEXT, price DECIMAL, image_url TEXT,
    restaurant_id UUID, restaurant_name VARCHAR, avg_rating DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT mi.id, mi.name, mi.description, mi.price, mi.image_url,
        mi.restaurant_id, r.name as restaurant_name, mi.avg_rating
    FROM public.menu_items mi
    JOIN public.restaurants r ON r.id = mi.restaurant_id
    WHERE mi.is_available = true AND r.is_verified = true
    ORDER BY mi.order_count DESC, mi.avg_rating DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- Panier avec détails
CREATE OR REPLACE FUNCTION get_cart_items(p_customer_id UUID)
RETURNS TABLE (
    id UUID, menu_item_id UUID, quantity INTEGER, special_instructions TEXT,
    item_name VARCHAR, item_description TEXT, item_price DECIMAL, item_image_url TEXT,
    restaurant_id UUID, restaurant_name VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT ci.id, ci.menu_item_id, ci.quantity, ci.special_instructions,
        mi.name, mi.description, mi.price, mi.image_url,
        r.id as restaurant_id, r.name as restaurant_name
    FROM public.cart_items ci
    JOIN public.menu_items mi ON mi.id = ci.menu_item_id
    JOIN public.restaurants r ON r.id = mi.restaurant_id
    WHERE ci.customer_id = p_customer_id
    ORDER BY ci.created_at;
END;
$$ LANGUAGE plpgsql;

-- Loyalty points
CREATE OR REPLACE FUNCTION get_customer_loyalty()
RETURNS TABLE (points INTEGER, total_orders INTEGER, total_spent DECIMAL) AS $$
BEGIN
    RETURN QUERY
    SELECT COALESCE(p.loyalty_points, 0), COALESCE(p.total_orders, 0), COALESCE(p.total_spent, 0)
    FROM public.profiles p WHERE p.id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recherches récentes (placeholder)
CREATE OR REPLACE FUNCTION get_recent_searches(p_limit INTEGER DEFAULT 5)
RETURNS TABLE (query TEXT) AS $$
BEGIN
    RETURN QUERY SELECT ''::TEXT WHERE FALSE LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- Sauvegarder recherche (placeholder)
CREATE OR REPLACE FUNCTION save_search_query(p_query TEXT)
RETURNS VOID AS $$ BEGIN RETURN; END; $$ LANGUAGE plpgsql;

-- ============================================
-- 2. TABLE PANIER
-- ============================================

CREATE TABLE IF NOT EXISTS public.cart_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    menu_item_id UUID NOT NULL REFERENCES public.menu_items(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL DEFAULT 1,
    special_instructions TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(customer_id, menu_item_id)
);

CREATE INDEX IF NOT EXISTS idx_cart_items_customer ON public.cart_items(customer_id);

ALTER TABLE public.cart_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Cart: gestion par propriétaire" ON public.cart_items;
CREATE POLICY "Cart: gestion par propriétaire" 
    ON public.cart_items FOR ALL USING (auth.uid() = customer_id);

DROP TRIGGER IF EXISTS update_cart_items_updated_at ON public.cart_items;
CREATE TRIGGER update_cart_items_updated_at 
    BEFORE UPDATE ON public.cart_items 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================
-- 3. DONNÉES DE TEST
-- ============================================

-- Restaurant 1: Pizza Tigzirt
INSERT INTO public.restaurants (
    id, owner_id, name, description, phone, address, latitude, longitude,
    cuisine_type, tags, min_order_amount, delivery_fee, avg_prep_time, 
    rating, is_open, is_verified
) VALUES (
    'a1111111-1111-1111-1111-111111111111',
    (SELECT id FROM public.profiles WHERE role = 'restaurant' LIMIT 1),
    'Pizza Tigzirt', 'Les meilleures pizzas de Tigzirt!',
    '0555234567', 'Rue principale, Tigzirt', 36.8892, 4.1225,
    'Pizza', ARRAY['Pizza', 'Italien'], 500, 150, 25, 4.5, true, true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 2: Couscous Mama
INSERT INTO public.restaurants (
    id, owner_id, name, description, phone, address, latitude, longitude,
    cuisine_type, tags, min_order_amount, delivery_fee, avg_prep_time,
    rating, is_open, is_verified
) VALUES (
    'a2222222-2222-2222-2222-222222222222',
    (SELECT id FROM public.profiles WHERE role = 'restaurant' LIMIT 1),
    'Couscous Mama', 'Couscous traditionnel kabyle fait maison',
    '0555345678', 'Centre ville, Tigzirt', 36.8900, 4.1230,
    'Traditionnel', ARRAY['Couscous', 'Kabyle'], 800, 100, 45, 4.8, true, true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 3: Tacos Express
INSERT INTO public.restaurants (
    id, owner_id, name, description, phone, address, latitude, longitude,
    cuisine_type, tags, min_order_amount, delivery_fee, avg_prep_time,
    rating, is_open, is_verified
) VALUES (
    'a3333333-3333-3333-3333-333333333333',
    (SELECT id FROM public.profiles WHERE role = 'restaurant' LIMIT 1),
    'Tacos Express', 'Tacos et sandwichs rapides',
    '0555456789', 'Bord de mer, Tigzirt', 36.8880, 4.1210,
    'Fast-food', ARRAY['Tacos', 'Sandwich'], 400, 120, 15, 4.2, true, true
) ON CONFLICT (id) DO NOTHING;

-- Catégories
INSERT INTO public.menu_categories (id, restaurant_id, name, sort_order) VALUES
    ('c1111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111', 'Pizzas', 1),
    ('c2222222-2222-2222-2222-222222222222', 'a2222222-2222-2222-2222-222222222222', 'Couscous', 1),
    ('c3333333-3333-3333-3333-333333333333', 'a2222222-2222-2222-2222-222222222222', 'Entrées', 2),
    ('c4444444-4444-4444-4444-444444444444', 'a3333333-3333-3333-3333-333333333333', 'Tacos', 1)
ON CONFLICT (id) DO NOTHING;

-- Plats Pizza Tigzirt
INSERT INTO public.menu_items (id, restaurant_id, category_id, name, description, price, is_available, is_popular, prep_time) VALUES
    ('11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111', 'c1111111-1111-1111-1111-111111111111', 'Pizza Margherita', 'Tomate, mozzarella, basilic', 800, true, true, 20),
    ('22222222-2222-2222-2222-222222222222', 'a1111111-1111-1111-1111-111111111111', 'c1111111-1111-1111-1111-111111111111', 'Pizza 4 Fromages', 'Mozzarella, gorgonzola, parmesan, chèvre', 1000, true, true, 25),
    ('33333333-3333-3333-3333-333333333333', 'a1111111-1111-1111-1111-111111111111', 'c1111111-1111-1111-1111-111111111111', 'Pizza Viande', 'Viande hachée, oignons, fromage', 900, true, false, 25)
ON CONFLICT (id) DO NOTHING;

-- Plats Couscous Mama
INSERT INTO public.menu_items (id, restaurant_id, category_id, name, description, price, is_available, is_popular, prep_time) VALUES
    ('44444444-4444-4444-4444-444444444444', 'a2222222-2222-2222-2222-222222222222', 'c2222222-2222-2222-2222-222222222222', 'Couscous Poulet', 'Couscous traditionnel avec poulet et légumes', 1200, true, true, 40),
    ('55555555-5555-5555-5555-555555555555', 'a2222222-2222-2222-2222-222222222222', 'c2222222-2222-2222-2222-222222222222', 'Couscous Agneau', 'Couscous avec viande d''agneau tendre', 1500, true, true, 45),
    ('66666666-6666-6666-6666-666666666666', 'a2222222-2222-2222-2222-222222222222', 'c3333333-3333-3333-3333-333333333333', 'Chorba', 'Soupe traditionnelle aux légumes', 300, true, false, 10)
ON CONFLICT (id) DO NOTHING;

-- Plats Tacos Express
INSERT INTO public.menu_items (id, restaurant_id, category_id, name, description, price, is_available, is_popular, prep_time) VALUES
    ('77777777-7777-7777-7777-777777777777', 'a3333333-3333-3333-3333-333333333333', 'c4444444-4444-4444-4444-444444444444', 'Tacos Poulet', 'Tacos avec poulet grillé', 600, true, true, 12),
    ('88888888-8888-8888-8888-888888888888', 'a3333333-3333-3333-3333-333333333333', 'c4444444-4444-4444-4444-444444444444', 'Tacos Viande', 'Tacos avec viande hachée', 650, true, true, 12),
    ('99999999-9999-9999-9999-999999999999', 'a3333333-3333-3333-3333-333333333333', 'c4444444-4444-4444-4444-444444444444', 'Tacos Mixte', 'Tacos poulet + viande', 700, true, false, 15)
ON CONFLICT (id) DO NOTHING;

-- Livreur
INSERT INTO public.livreurs (id, user_id, vehicle_type, vehicle_number, current_latitude, current_longitude, is_available, is_online, is_verified, rating, tier)
SELECT 'b1111111-1111-1111-1111-111111111111', id, 'moto', '12345-123-16', 36.8895, 4.1220, true, true, true, 4.8, 'silver'
FROM public.profiles WHERE role = 'livreur' LIMIT 1
ON CONFLICT (id) DO UPDATE SET user_id = EXCLUDED.user_id;

-- ============================================
-- VÉRIFICATION
-- ============================================
SELECT 'Setup complet terminé!' as status;
SELECT 'Restaurants' as type, COUNT(*)::text as count FROM public.restaurants
UNION ALL SELECT 'Menu items', COUNT(*)::text FROM public.menu_items
UNION ALL SELECT 'Livreurs', COUNT(*)::text FROM public.livreurs
UNION ALL SELECT 'Profiles', COUNT(*)::text FROM public.profiles;
