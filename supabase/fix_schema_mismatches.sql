-- ============================================================
-- CORRECTIONS SCHÉMA - Alignement Code/Base de données
-- ============================================================
-- Ce script corrige toutes les incohérences entre le code Flutter
-- et la base de données Supabase
-- ============================================================

-- 1. Renommer created_at en sent_at dans notifications
ALTER TABLE public.notifications RENAME COLUMN created_at TO sent_at;

-- 2. Ajouter colonne 'type' dans saved_addresses
ALTER TABLE public.saved_addresses ADD COLUMN IF NOT EXISTS type VARCHAR(20);

UPDATE public.saved_addresses 
SET type = CASE 
    WHEN label ILIKE '%maison%' OR label ILIKE '%home%' OR label ILIKE '%🏠%' THEN 'home'
    WHEN label ILIKE '%travail%' OR label ILIKE '%work%' OR label ILIKE '%bureau%' OR label ILIKE '%🏢%' THEN 'work'
    ELSE 'other'
END
WHERE type IS NULL;

ALTER TABLE public.saved_addresses ALTER COLUMN type SET DEFAULT 'other';

-- 3. Créer table user_preferences
CREATE TABLE IF NOT EXISTS public.user_preferences (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    theme VARCHAR(20) DEFAULT 'system',
    language VARCHAR(10) DEFAULT 'fr',
    notifications_enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Preferences: gestion par propriétaire" ON public.user_preferences;
CREATE POLICY "Preferences: gestion par propriétaire" 
    ON public.user_preferences FOR ALL USING (auth.uid() = user_id);

-- 4. Corriger fonction get_cart_items (retourner 'price' au lieu de 'item_price')
DROP FUNCTION IF EXISTS get_cart_items(uuid);

CREATE OR REPLACE FUNCTION get_cart_items(p_customer_id UUID)
RETURNS TABLE (
    id UUID,
    menu_item_id UUID,
    quantity INTEGER,
    special_instructions TEXT,
    item_name VARCHAR,
    item_description TEXT,
    price DECIMAL,
    item_image_url TEXT,
    restaurant_id UUID,
    restaurant_name VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ci.id, ci.menu_item_id, ci.quantity, ci.special_instructions,
        mi.name as item_name, mi.description as item_description, 
        mi.price,
        mi.image_url as item_image_url,
        r.id as restaurant_id, r.name as restaurant_name
    FROM public.cart_items ci
    JOIN public.menu_items mi ON mi.id = ci.menu_item_id
    JOIN public.restaurants r ON r.id = mi.restaurant_id
    WHERE ci.customer_id = p_customer_id
    ORDER BY ci.created_at;
END;
$$ LANGUAGE plpgsql;

-- Vérification
SELECT 'Toutes les corrections appliquées!' as status;

-- ============================================
-- 5. ADD lat/lng COLUMNS TO saved_addresses
-- ============================================
-- Code expects 'lat' and 'lng' but database has 'latitude' and 'longitude'
-- RULE: Code is the reference, so we add the fields code expects
ALTER TABLE public.saved_addresses ADD COLUMN IF NOT EXISTS lat DECIMAL(10,8);
ALTER TABLE public.saved_addresses ADD COLUMN IF NOT EXISTS lng DECIMAL(11,8);

-- Copy existing data from latitude/longitude to lat/lng
UPDATE public.saved_addresses 
SET lat = latitude, lng = longitude 
WHERE lat IS NULL OR lng IS NULL;

COMMENT ON COLUMN public.saved_addresses.lat IS 'Latitude (short name for code compatibility)';
COMMENT ON COLUMN public.saved_addresses.lng IS 'Longitude (short name for code compatibility)';

-- Final verification
SELECT 'Schema mismatches fixed - lat/lng added!' AS status;

-- ============================================
-- 6. ADD delivery_lat/delivery_lng TO orders
-- ============================================
-- Code expects 'delivery_lat' and 'delivery_lng' but database has 'delivery_latitude' and 'delivery_longitude'
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivery_lat DECIMAL(10,8);
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivery_lng DECIMAL(11,8);

-- Copy existing data from delivery_latitude/delivery_longitude to delivery_lat/delivery_lng
UPDATE public.orders 
SET delivery_lat = delivery_latitude, delivery_lng = delivery_longitude 
WHERE delivery_lat IS NULL OR delivery_lng IS NULL;

COMMENT ON COLUMN public.orders.delivery_lat IS 'Delivery latitude (short name for code compatibility)';
COMMENT ON COLUMN public.orders.delivery_lng IS 'Delivery longitude (short name for code compatibility)';

-- Final verification
SELECT 'All schema fixes applied - orders table updated!' AS status;
