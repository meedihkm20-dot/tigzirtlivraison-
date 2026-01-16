-- ============================================================
-- MIGRATION COMPLÈTE: Synchronisation Backend NestJS ↔ SQL
-- Date: 2026-01-16
-- Description: Corrige TOUS les mismatches entre backend et base de données
-- RÈGLE: Le backend est la source de vérité
-- ============================================================

-- ⚠️ BACKUP RECOMMANDÉ AVANT EXÉCUTION

BEGIN;

-- ════════════════════════════════════════════════════════════
-- TABLE: orders
-- Backend: backend/src/modules/orders/orders.service.ts
-- ════════════════════════════════════════════════════════════

-- 1. Ajouter colonnes manquantes pour compatibilité backend
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS user_id UUID;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivery_lat DECIMAL(10,8);
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivery_lng DECIMAL(11,8);
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS total_amount DECIMAL(10,2);

-- 2. Rendre 'total' nullable (backend utilise total_amount)
ALTER TABLE public.orders ALTER COLUMN total DROP NOT NULL;

-- 3. Rendre delivery_latitude et delivery_longitude nullable (backend utilise delivery_lat/lng)
ALTER TABLE public.orders ALTER COLUMN delivery_latitude DROP NOT NULL;
ALTER TABLE public.orders ALTER COLUMN delivery_longitude DROP NOT NULL;

-- 4. Créer triggers pour synchroniser automatiquement les colonnes
CREATE OR REPLACE FUNCTION sync_orders_columns()
RETURNS TRIGGER AS $$
BEGIN
  -- Sync user_id <-> customer_id
  IF NEW.user_id IS NOT NULL AND NEW.customer_id IS NULL THEN
    NEW.customer_id := NEW.user_id;
  END IF;
  IF NEW.customer_id IS NOT NULL AND NEW.user_id IS NULL THEN
    NEW.user_id := NEW.customer_id;
  END IF;
  
  -- Sync delivery_lat/lng <-> delivery_latitude/longitude
  IF NEW.delivery_lat IS NOT NULL AND NEW.delivery_latitude IS NULL THEN
    NEW.delivery_latitude := NEW.delivery_lat;
  END IF;
  IF NEW.delivery_lng IS NOT NULL AND NEW.delivery_longitude IS NULL THEN
    NEW.delivery_longitude := NEW.delivery_lng;
  END IF;
  IF NEW.delivery_latitude IS NOT NULL AND NEW.delivery_lat IS NULL THEN
    NEW.delivery_lat := NEW.delivery_latitude;
  END IF;
  IF NEW.delivery_longitude IS NOT NULL AND NEW.delivery_lng IS NULL THEN
    NEW.delivery_lng := NEW.delivery_longitude;
  END IF;
  
  -- Sync total_amount <-> total
  IF NEW.total_amount IS NOT NULL AND NEW.total IS NULL THEN
    NEW.total := NEW.total_amount;
  END IF;
  IF NEW.total IS NOT NULL AND NEW.total_amount IS NULL THEN
    NEW.total_amount := NEW.total;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_sync_orders_columns ON public.orders;
CREATE TRIGGER trigger_sync_orders_columns
  BEFORE INSERT OR UPDATE ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION sync_orders_columns();

-- 5. Migrer les données existantes
UPDATE public.orders 
SET 
  user_id = customer_id,
  delivery_lat = delivery_latitude,
  delivery_lng = delivery_longitude,
  total_amount = total
WHERE user_id IS NULL OR delivery_lat IS NULL OR total_amount IS NULL;

-- 6. Ajouter commentaires pour documentation
COMMENT ON COLUMN public.orders.user_id IS 'Alias de customer_id pour compatibilité backend';
COMMENT ON COLUMN public.orders.delivery_lat IS 'Alias de delivery_latitude pour compatibilité backend';
COMMENT ON COLUMN public.orders.delivery_lng IS 'Alias de delivery_longitude pour compatibilité backend';
COMMENT ON COLUMN public.orders.total_amount IS 'Alias de total pour compatibilité backend';

-- ════════════════════════════════════════════════════════════
-- TABLE: saved_addresses
-- Backend: apps/dz_delivery/lib/core/services/supabase_service.dart
-- ════════════════════════════════════════════════════════════

-- Ajouter colonnes lat/lng (déjà fait mais on s'assure)
ALTER TABLE public.saved_addresses ADD COLUMN IF NOT EXISTS lat DECIMAL(10,8);
ALTER TABLE public.saved_addresses ADD COLUMN IF NOT EXISTS lng DECIMAL(11,8);

-- Trigger pour synchroniser
CREATE OR REPLACE FUNCTION sync_saved_addresses_coords()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.lat IS NOT NULL AND NEW.latitude IS NULL THEN
    NEW.latitude := NEW.lat;
  END IF;
  IF NEW.lng IS NOT NULL AND NEW.longitude IS NULL THEN
    NEW.longitude := NEW.lng;
  END IF;
  IF NEW.latitude IS NOT NULL AND NEW.lat IS NULL THEN
    NEW.lat := NEW.latitude;
  END IF;
  IF NEW.longitude IS NOT NULL AND NEW.lng IS NULL THEN
    NEW.lng := NEW.longitude;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_sync_saved_addresses_coords ON public.saved_addresses;
CREATE TRIGGER trigger_sync_saved_addresses_coords
  BEFORE INSERT OR UPDATE ON public.saved_addresses
  FOR EACH ROW
  EXECUTE FUNCTION sync_saved_addresses_coords();

-- Migrer données existantes
UPDATE public.saved_addresses 
SET lat = latitude, lng = longitude 
WHERE lat IS NULL OR lng IS NULL;

-- ════════════════════════════════════════════════════════════
-- INDEXES POUR PERFORMANCE
-- ════════════════════════════════════════════════════════════

CREATE INDEX IF NOT EXISTS idx_orders_user_id ON public.orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON public.orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_restaurant_id ON public.orders(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_orders_livreur_id ON public.orders(livreur_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON public.orders(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON public.order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_menu_item_id ON public.order_items(menu_item_id);

CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_livreurs_user_id ON public.livreurs(user_id);
CREATE INDEX IF NOT EXISTS idx_livreurs_is_available ON public.livreurs(is_available) WHERE is_verified = true;

-- ════════════════════════════════════════════════════════════
-- VÉRIFICATIONS POST-MIGRATION
-- ════════════════════════════════════════════════════════════

DO $$
DECLARE
  v_orders_user_id_exists BOOLEAN;
  v_orders_delivery_lat_exists BOOLEAN;
  v_orders_total_amount_exists BOOLEAN;
  v_addresses_lat_exists BOOLEAN;
BEGIN
  -- Vérifier que les colonnes existent
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'orders' AND column_name = 'user_id'
  ) INTO v_orders_user_id_exists;
  
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'orders' AND column_name = 'delivery_lat'
  ) INTO v_orders_delivery_lat_exists;
  
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'orders' AND column_name = 'total_amount'
  ) INTO v_orders_total_amount_exists;
  
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'saved_addresses' AND column_name = 'lat'
  ) INTO v_addresses_lat_exists;
  
  -- Afficher les résultats
  RAISE NOTICE '✅ orders.user_id exists: %', v_orders_user_id_exists;
  RAISE NOTICE '✅ orders.delivery_lat exists: %', v_orders_delivery_lat_exists;
  RAISE NOTICE '✅ orders.total_amount exists: %', v_orders_total_amount_exists;
  RAISE NOTICE '✅ saved_addresses.lat exists: %', v_addresses_lat_exists;
  
  IF NOT (v_orders_user_id_exists AND v_orders_delivery_lat_exists AND v_orders_total_amount_exists AND v_addresses_lat_exists) THEN
    RAISE EXCEPTION 'Migration incomplète - certaines colonnes manquent';
  END IF;
END $$;

COMMIT;

-- ════════════════════════════════════════════════════════════
-- RÉSUMÉ DE LA MIGRATION
-- ════════════════════════════════════════════════════════════

SELECT '
╔════════════════════════════════════════════════════════════╗
║  ✅ MIGRATION COMPLÈTE RÉUSSIE                             ║
╠════════════════════════════════════════════════════════════╣
║  Tables modifiées:                                         ║
║    • orders (user_id, delivery_lat/lng, total_amount)     ║
║    • saved_addresses (lat/lng)                             ║
║                                                            ║
║  Triggers créés:                                           ║
║    • sync_orders_columns                                   ║
║    • sync_saved_addresses_coords                           ║
║                                                            ║
║  Indexes créés: 11                                         ║
║                                                            ║
║  ⚡ Le backend peut maintenant créer des commandes!        ║
╚════════════════════════════════════════════════════════════╝
' AS "Migration Status";
