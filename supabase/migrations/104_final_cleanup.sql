-- ============================================================
-- MIGRATION 104: Nettoyage final des tables obsolètes
-- ============================================================
-- Tables identifiées comme INATTENDUES après audit:
-- - customer_badges (obsolète)
-- - user_preferences (obsolète)
-- - spatial_ref_sys (PostGIS - NE PAS TOUCHER)
-- ============================================================

BEGIN;

-- ════════════════════════════════════════════════════════════════════════════
-- SUPPRESSION DES TABLES OBSOLÈTES
-- ════════════════════════════════════════════════════════════════════════════

-- Table customer_badges - remplacée par livreur_badges (gamification livreur uniquement)
DROP TABLE IF EXISTS customer_badges CASCADE;

-- Table user_preferences - non utilisée
DROP TABLE IF EXISTS user_preferences CASCADE;

-- ⚠️ NE PAS SUPPRIMER spatial_ref_sys - c'est une table système PostGIS

COMMIT;

-- ════════════════════════════════════════════════════════════════════════════
-- CRÉATION DES TABLES MANQUANTES (si elles n'existent pas)
-- ════════════════════════════════════════════════════════════════════════════

-- delivery_zones
CREATE TABLE IF NOT EXISTS public.delivery_zones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    polygon JSONB NOT NULL,
    fee_adjustment DECIMAL(10,2) DEFAULT 0,
    is_active BOOLEAN DEFAULT true
);

-- fcm_tokens
CREATE TABLE IF NOT EXISTS public.fcm_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    token TEXT NOT NULL,
    device_type VARCHAR(20),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, token)
);

-- favorite_items
CREATE TABLE IF NOT EXISTS public.favorite_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    menu_item_id UUID REFERENCES public.menu_items(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(customer_id, menu_item_id)
);

-- livreur_badges
CREATE TABLE IF NOT EXISTS public.livreur_badges (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    livreur_id UUID REFERENCES public.livreurs(id) ON DELETE CASCADE,
    badge_type VARCHAR(50) NOT NULL,
    earned_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(livreur_id, badge_type)
);

-- menu_item_variants
CREATE TABLE IF NOT EXISTS public.menu_item_variants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    menu_item_id UUID REFERENCES public.menu_items(id) ON DELETE CASCADE,
    name VARCHAR(50) NOT NULL,
    price_adjustment DECIMAL(10, 2) DEFAULT 0,
    is_default BOOLEAN DEFAULT false,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- menu_item_extras
CREATE TABLE IF NOT EXISTS public.menu_item_extras (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    menu_item_id UUID REFERENCES public.menu_items(id) ON DELETE CASCADE,
    name VARCHAR(50) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    is_available BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ════════════════════════════════════════════════════════════════════════════
-- VÉRIFICATION FINALE
-- ════════════════════════════════════════════════════════════════════════════

SELECT 
  table_name,
  CASE 
    WHEN table_name IN (
      'profiles', 'restaurants', 'menu_categories', 'menu_items',
      'livreurs', 'orders', 'order_items', 'reviews', 'transactions',
      'notifications', 'livreur_locations', 'order_messages',
      'saved_addresses', 'favorites', 'favorite_items', 'promotions',
      'commission_settings', 'delivery_pricing', 'delivery_zones',
      'livreur_badges', 'livreur_bonuses', 'tier_config',
      'livreur_targets', 'referrals', 'fcm_tokens',
      'menu_item_variants', 'menu_item_extras', 'menu_item_reviews',
      'search_history', 'reorder_suggestions'
    ) THEN '✅ OK'
    WHEN table_name = 'spatial_ref_sys' THEN '🔧 PostGIS (système)'
    ELSE '⚠️ INATTENDU'
  END as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_type = 'BASE TABLE'
ORDER BY status, table_name;

-- ════════════════════════════════════════════════════════════════════════════
DO $$
BEGIN
    RAISE NOTICE 'Migration 104 terminée - Nettoyage final effectué';
END $$;
