-- ============================================================
-- MIGRATION: Synchronisation Backend → Supabase
-- ============================================================
-- Date: 2026-01-16
-- Objectif: Ajouter toutes les colonnes manquantes utilisées par le backend
-- Méthode: IF NOT EXISTS pour éviter les erreurs si déjà présentes
-- ============================================================

-- ============================================
-- PARTIE 1: COLONNES MANQUANTES - ORDERS
-- ============================================

-- Colonnes utilisées par le backend mais absentes du schéma
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS total_amount DECIMAL(10,2);
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivery_lat DECIMAL(10,8);
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivery_lng DECIMAL(11,8);
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS notes TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS driver_id UUID REFERENCES public.profiles(id);
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS preparing_at TIMESTAMPTZ;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS cancelled_by TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS code_verified_at TIMESTAMPTZ;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS verification_code TEXT;

-- Renommer delivery_latitude/longitude si elles existent (backend utilise delivery_lat/lng)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'delivery_latitude') THEN
        -- Copier les données si delivery_lat n'existe pas encore
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'delivery_lat') THEN
            ALTER TABLE public.orders ADD COLUMN delivery_lat DECIMAL(10,8);
            UPDATE public.orders SET delivery_lat = delivery_latitude WHERE delivery_lat IS NULL;
        END IF;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'delivery_longitude') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'delivery_lng') THEN
            ALTER TABLE public.orders ADD COLUMN delivery_lng DECIMAL(11,8);
            UPDATE public.orders SET delivery_lng = delivery_longitude WHERE delivery_lng IS NULL;
        END IF;
    END IF;
END $$;

-- Synchroniser total avec total_amount si total_amount est NULL
UPDATE public.orders SET total_amount = total WHERE total_amount IS NULL AND total IS NOT NULL;

-- ============================================
-- PARTIE 2: COLONNES MANQUANTES - ORDER_ITEMS
-- ============================================

ALTER TABLE public.order_items ADD COLUMN IF NOT EXISTS unit_price DECIMAL(10,2);
ALTER TABLE public.order_items ADD COLUMN IF NOT EXISTS total_price DECIMAL(10,2);

-- Calculer unit_price et total_price si manquants
UPDATE public.order_items 
SET unit_price = price, total_price = price * quantity 
WHERE unit_price IS NULL OR total_price IS NULL;

-- ============================================
-- PARTIE 3: COLONNES MANQUANTES - PROFILES
-- ============================================

ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_available BOOLEAN DEFAULT false;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;

-- ============================================
-- PARTIE 4: INDEX POUR PERFORMANCE
-- ============================================

-- Index pour driver_id (nouveau champ)
CREATE INDEX IF NOT EXISTS idx_orders_driver ON public.orders(driver_id) WHERE driver_id IS NOT NULL;

-- Index pour les recherches par statut + livreur
CREATE INDEX IF NOT EXISTS idx_orders_status_livreur ON public.orders(status, livreur_id) WHERE livreur_id IS NOT NULL;

-- Index pour les commandes en attente d'assignation
CREATE INDEX IF NOT EXISTS idx_orders_pending_no_driver ON public.orders(status, created_at) 
WHERE status = 'pending' AND driver_id IS NULL AND livreur_id IS NULL;

-- ============================================
-- PARTIE 5: FONCTION RPC MANQUANTE
-- ============================================

-- Fonction pour incrémenter les stats du livreur (appelée par le backend)
CREATE OR REPLACE FUNCTION increment_livreur_stats(
    p_livreur_id UUID,
    p_commission DECIMAL
)
RETURNS VOID AS $$
BEGIN
    UPDATE public.livreurs
    SET 
        total_deliveries = total_deliveries + 1,
        total_earnings = total_earnings + p_commission,
        weekly_deliveries = weekly_deliveries + 1,
        monthly_deliveries = monthly_deliveries + 1
    WHERE id = p_livreur_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- PARTIE 6: CONTRAINTES ET VALIDATIONS
-- ============================================

-- S'assurer que driver_id pointe vers un profil de type livreur
-- (Contrainte optionnelle, peut être ajoutée plus tard si nécessaire)

-- ============================================
-- PARTIE 7: DONNÉES PAR DÉFAUT
-- ============================================

-- Mettre à jour les profils existants
UPDATE public.profiles SET is_active = true WHERE is_active IS NULL;
UPDATE public.profiles SET is_available = false WHERE is_available IS NULL AND role = 'livreur';

-- ============================================
-- VÉRIFICATION FINALE
-- ============================================

DO $$
DECLARE
    missing_columns TEXT[];
    col RECORD;
BEGIN
    -- Vérifier les colonnes critiques
    FOR col IN 
        SELECT 
            'orders' as table_name, 
            unnest(ARRAY['total_amount', 'delivery_lat', 'delivery_lng', 'driver_id', 'cancelled_by']) as column_name
        UNION ALL
        SELECT 'order_items', unnest(ARRAY['unit_price', 'total_price'])
        UNION ALL
        SELECT 'profiles', unnest(ARRAY['is_available', 'is_active'])
    LOOP
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = col.table_name 
            AND column_name = col.column_name
        ) THEN
            missing_columns := array_append(missing_columns, col.table_name || '.' || col.column_name);
        END IF;
    END LOOP;
    
    IF array_length(missing_columns, 1) > 0 THEN
        RAISE WARNING 'Colonnes manquantes détectées: %', array_to_string(missing_columns, ', ');
    ELSE
        RAISE NOTICE '✅ Toutes les colonnes backend sont présentes';
    END IF;
END $$;

-- ============================================
-- RÉSUMÉ
-- ============================================

SELECT 
    'Migration backend sync terminée' as status,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'orders') as orders_columns,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'order_items') as order_items_columns,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'profiles') as profiles_columns;

-- ============================================
-- NOTES IMPORTANTES
-- ============================================
/*
COLONNES AJOUTÉES:

orders:
  - total_amount (alias de total pour compatibilité backend)
  - delivery_lat, delivery_lng (backend utilise ces noms courts)
  - notes (instructions de livraison)
  - driver_id (référence au livreur, utilisé en parallèle de livreur_id)
  - preparing_at (timestamp quand le restaurant commence la préparation)
  - cancelled_by (qui a annulé: 'customer', 'restaurant')
  - code_verified_at (quand le code a été vérifié)
  - verification_code (alias de confirmation_code)

order_items:
  - unit_price (prix unitaire de l'article)
  - total_price (prix total = unit_price * quantity)

profiles:
  - is_available (disponibilité pour les livreurs)
  - is_active (compte actif ou suspendu)

FONCTIONS AJOUTÉES:
  - increment_livreur_stats() (mise à jour stats après livraison)

INDEX AJOUTÉS:
  - idx_orders_driver (recherche par driver_id)
  - idx_orders_status_livreur (recherche par statut + livreur)
  - idx_orders_pending_no_driver (commandes en attente d'assignation)
*/
