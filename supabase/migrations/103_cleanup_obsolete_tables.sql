-- ============================================================
-- MIGRATION 103: Nettoyage des tables obsolètes
-- ============================================================
-- Basé sur SCHEMA_REFERENCE.md - Source de Vérité Unique
-- 
-- TABLES À GARDER (30 tables):
-- profiles, restaurants, menu_categories, menu_items, livreurs,
-- orders, order_items, reviews, transactions, notifications,
-- livreur_locations, order_messages, saved_addresses, favorites,
-- favorite_items, promotions, commission_settings, delivery_pricing,
-- delivery_zones, livreur_badges, livreur_bonuses, tier_config,
-- livreur_targets, referrals, fcm_tokens, menu_item_variants,
-- menu_item_extras, menu_item_reviews, search_history, reorder_suggestions
-- ============================================================

-- ════════════════════════════════════════════════════════════════════════════
-- PHASE 1: AUDIT - Identifier les tables à supprimer
-- ════════════════════════════════════════════════════════════════════════════

-- Exécuter cette requête d'abord pour voir les tables à supprimer:
/*
WITH tables_a_garder AS (
  SELECT unnest(ARRAY[
    'profiles', 'restaurants', 'menu_categories', 'menu_items',
    'livreurs', 'orders', 'order_items', 'reviews', 'transactions',
    'notifications', 'livreur_locations', 'order_messages',
    'saved_addresses', 'favorites', 'favorite_items', 'promotions',
    'commission_settings', 'delivery_pricing', 'delivery_zones',
    'livreur_badges', 'livreur_bonuses', 'tier_config',
    'livreur_targets', 'referrals', 'fcm_tokens',
    'menu_item_variants', 'menu_item_extras', 'menu_item_reviews',
    'search_history', 'reorder_suggestions'
  ]) as name
)
SELECT 
  t.table_name,
  CASE 
    WHEN k.name IS NOT NULL THEN '✅ GARDER'
    ELSE '🗑️ SUPPRIMER'
  END as action,
  (SELECT n_live_tup FROM pg_stat_user_tables WHERE relname = t.table_name) as rows
FROM information_schema.tables t
LEFT JOIN tables_a_garder k ON t.table_name = k.name
WHERE t.table_schema = 'public' AND t.table_type = 'BASE TABLE'
ORDER BY action DESC, t.table_name;
*/

-- ════════════════════════════════════════════════════════════════════════════
-- PHASE 2: SUPPRESSION DES TABLES OBSOLÈTES
-- ════════════════════════════════════════════════════════════════════════════

BEGIN;

-- ────────────────────────────────────────────────────────────────────────────
-- 1. Tables de panier (non utilisées - state Flutter)
-- ────────────────────────────────────────────────────────────────────────────
DROP TABLE IF EXISTS cart_items CASCADE;
DROP TABLE IF EXISTS carts CASCADE;

-- ────────────────────────────────────────────────────────────────────────────
-- 2. Anciennes tables de configuration
-- ────────────────────────────────────────────────────────────────────────────
DROP TABLE IF EXISTS app_settings CASCADE;
DROP TABLE IF EXISTS settings CASCADE;

-- ────────────────────────────────────────────────────────────────────────────
-- 3. Tables renommées (anciennes versions)
-- ────────────────────────────────────────────────────────────────────────────
DROP TABLE IF EXISTS drivers CASCADE;
DROP TABLE IF EXISTS driver_locations CASCADE;
DROP TABLE IF EXISTS addresses CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS items CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS order_history CASCADE;
DROP TABLE IF EXISTS order_status_history CASCADE;
DROP TABLE IF EXISTS zones CASCADE;
DROP TABLE IF EXISTS pricing CASCADE;
DROP TABLE IF EXISTS coupons CASCADE;
DROP TABLE IF EXISTS discounts CASCADE;

-- ────────────────────────────────────────────────────────────────────────────
-- 4. Tables de test/debug
-- ────────────────────────────────────────────────────────────────────────────
DROP TABLE IF EXISTS test_table CASCADE;
DROP TABLE IF EXISTS debug_logs CASCADE;
DROP TABLE IF EXISTS temp_data CASCADE;
DROP TABLE IF EXISTS _test CASCADE;
DROP TABLE IF EXISTS test_users CASCADE;
DROP TABLE IF EXISTS test_orders CASCADE;

-- ────────────────────────────────────────────────────────────────────────────
-- 5. Vues obsolètes
-- ────────────────────────────────────────────────────────────────────────────
DROP VIEW IF EXISTS v_order_details CASCADE;
DROP VIEW IF EXISTS v_restaurant_stats CASCADE;
DROP VIEW IF EXISTS v_livreur_stats CASCADE;
DROP VIEW IF EXISTS v_admin_dashboard CASCADE;

-- ────────────────────────────────────────────────────────────────────────────
-- 6. Fonctions Edge Functions migrées vers Backend
-- ────────────────────────────────────────────────────────────────────────────
-- Note: Ces fonctions sont maintenant gérées par le backend NestJS

DROP FUNCTION IF EXISTS cancel_order(UUID, TEXT) CASCADE;
DROP FUNCTION IF EXISTS change_order_status(UUID, TEXT) CASCADE;
DROP FUNCTION IF EXISTS verify_delivery(UUID, TEXT) CASCADE;
DROP FUNCTION IF EXISTS assign_driver(UUID, UUID) CASCADE;

-- ────────────────────────────────────────────────────────────────────────────
-- 7. Types enum obsolètes
-- ────────────────────────────────────────────────────────────────────────────
DROP TYPE IF EXISTS old_order_status CASCADE;
DROP TYPE IF EXISTS driver_status CASCADE;

COMMIT;

-- ════════════════════════════════════════════════════════════════════════════
-- PHASE 3: VÉRIFICATION POST-NETTOYAGE
-- ════════════════════════════════════════════════════════════════════════════

-- Vérifier que seules les 30 tables de la source de vérité restent
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
    ELSE '⚠️ INATTENDU'
  END as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_type = 'BASE TABLE'
ORDER BY status, table_name;

-- ════════════════════════════════════════════════════════════════════════════
-- FIN DE LA MIGRATION 103
-- ════════════════════════════════════════════════════════════════════════════
DO $$
BEGIN
    RAISE NOTICE 'Migration 103 terminée - Tables obsolètes supprimées';
END $$;
