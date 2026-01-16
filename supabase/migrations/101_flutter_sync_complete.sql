-- ============================================================
-- MIGRATION: Synchronisation Flutter → Supabase
-- ============================================================
-- Date: 2026-01-16
-- Objectif: Ajouter toutes les tables/colonnes manquantes utilisées par Flutter
-- ============================================================

-- ============================================
-- PARTIE 1: TABLE SEARCH_HISTORY
-- ============================================

CREATE TABLE IF NOT EXISTS public.search_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    query TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_search_history_customer ON public.search_history(customer_id, created_at DESC);

-- RLS
ALTER TABLE public.search_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY IF NOT EXISTS "Search history: gestion par propriétaire" 
    ON public.search_history FOR ALL USING (auth.uid() = customer_id);

-- ============================================
-- PARTIE 2: FONCTIONS RPC MANQUANTES
-- ============================================

-- Fonction: get_top_menu_items (avec filtre restaurant optionnel)
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

-- ============================================
-- VÉRIFICATION
-- ============================================

SELECT 
    'Migration Flutter sync terminée' as status,
    EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'search_history') as search_history_exists,
    EXISTS(SELECT 1 FROM pg_proc WHERE proname = 'get_top_menu_items') as get_top_menu_items_exists;
