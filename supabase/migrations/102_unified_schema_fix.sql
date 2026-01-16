-- ============================================================
-- MIGRATION 102: Synchronisation Schéma Unifié
-- ============================================================
-- Cette migration ajoute les colonnes manquantes pour aligner
-- le schéma SQL avec le Backend et Flutter
-- ============================================================

-- ============================================
-- 1. AJOUTER cancelled_by à orders
-- Utilisé par le backend pour tracer qui annule
-- ============================================
ALTER TABLE public.orders 
ADD COLUMN IF NOT EXISTS cancelled_by VARCHAR(20);

COMMENT ON COLUMN public.orders.cancelled_by IS 'Qui a annulé: customer, restaurant, livreur, admin, system';

-- ============================================
-- 2. AJOUTER onesignal_player_id à profiles
-- Pour les notifications OneSignal
-- ============================================
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS onesignal_player_id TEXT;

COMMENT ON COLUMN public.profiles.onesignal_player_id IS 'OneSignal Player ID pour notifications push';

-- ============================================
-- 3. AJOUTER onesignal_player_id à livreurs
-- Pour les notifications OneSignal spécifiques livreur
-- ============================================
ALTER TABLE public.livreurs 
ADD COLUMN IF NOT EXISTS onesignal_player_id TEXT;

-- ============================================
-- 4. AJOUTER onesignal_player_id à restaurants
-- Pour les notifications OneSignal spécifiques restaurant
-- ============================================
ALTER TABLE public.restaurants 
ADD COLUMN IF NOT EXISTS onesignal_player_id TEXT;

-- ============================================
-- 5. AJOUTER is_available à profiles
-- Pour le statut de disponibilité (utilisé par delivery.service)
-- ============================================
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS is_available BOOLEAN DEFAULT false;

-- ============================================
-- 6. INDEX pour les nouvelles colonnes
-- ============================================
CREATE INDEX IF NOT EXISTS idx_orders_cancelled_by ON public.orders(cancelled_by) WHERE cancelled_by IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_profiles_onesignal ON public.profiles(onesignal_player_id) WHERE onesignal_player_id IS NOT NULL;

-- ============================================
-- 7. FONCTION: Vérifier la cohérence du schéma
-- ============================================
CREATE OR REPLACE FUNCTION check_schema_consistency()
RETURNS TABLE (
    table_name TEXT,
    column_name TEXT,
    data_type TEXT,
    is_nullable TEXT
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.table_name::TEXT,
        c.column_name::TEXT,
        c.data_type::TEXT,
        c.is_nullable::TEXT
    FROM information_schema.columns c
    WHERE c.table_schema = 'public'
    AND c.table_name IN (
        'profiles', 'restaurants', 'menu_categories', 'menu_items',
        'livreurs', 'orders', 'order_items', 'reviews', 'transactions',
        'notifications', 'order_messages', 'livreur_locations'
    )
    ORDER BY c.table_name, c.ordinal_position;
END;
$$;

-- ============================================
-- 8. VUE: Résumé des tables pour debug
-- ============================================
CREATE OR REPLACE VIEW public.schema_summary AS
SELECT 
    t.table_name,
    COUNT(c.column_name) as column_count,
    string_agg(c.column_name, ', ' ORDER BY c.ordinal_position) as columns
FROM information_schema.tables t
JOIN information_schema.columns c ON t.table_name = c.table_name AND t.table_schema = c.table_schema
WHERE t.table_schema = 'public'
AND t.table_type = 'BASE TABLE'
GROUP BY t.table_name
ORDER BY t.table_name;

-- ============================================
-- 9. Mise à jour du timestamp
-- ============================================
DO $$
BEGIN
    RAISE NOTICE 'Migration 102 appliquée avec succès - Schéma unifié';
END $$;
