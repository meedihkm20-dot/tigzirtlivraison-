-- ============================================
-- OPTIMISATION: Suppression des Index Inutilisés
-- ============================================
-- Ces index ne sont jamais utilisés et ralentissent les INSERT/UPDATE

-- Index avec 0 scans (jamais utilisés)
DROP INDEX IF EXISTS public.idx_restaurants_location;
DROP INDEX IF EXISTS public.idx_orders_status;
DROP INDEX IF EXISTS public.idx_profiles_referral_code;
DROP INDEX IF EXISTS public.idx_menu_items_available;
DROP INDEX IF EXISTS public.idx_profiles_phone;
DROP INDEX IF EXISTS public.idx_livreurs_available;
DROP INDEX IF EXISTS public.idx_profiles_role;
DROP INDEX IF EXISTS public.idx_orders_confirmation_code;
DROP INDEX IF EXISTS public.idx_livreur_tier;
DROP INDEX IF EXISTS public.idx_restaurants_cuisine;
DROP INDEX IF EXISTS public.idx_restaurants_is_open;
DROP INDEX IF EXISTS public.idx_menu_items_popular;
DROP INDEX IF EXISTS public.idx_menu_items_rating;
DROP INDEX IF EXISTS public.idx_livreurs_location;

-- Index redondants (doublons avec contraintes uniques)
-- Note: idx_orders_order_number déjà supprimé ci-dessus
-- Note: livreurs_user_id_key ne peut pas être supprimé car utilisé par la contrainte unique

-- ============================================
-- RECRÉER les Index Vraiment Nécessaires
-- ============================================

-- Index pour les recherches de livreurs disponibles (composite)
CREATE INDEX IF NOT EXISTS idx_livreurs_available_online 
ON public.livreurs (is_available, is_online, is_verified) 
WHERE is_available = true AND is_online = true AND is_verified = true;

-- Index pour les commandes par statut (partial index)
CREATE INDEX IF NOT EXISTS idx_orders_active_status 
ON public.orders (status, created_at DESC) 
WHERE status IN ('pending', 'confirmed', 'preparing', 'ready', 'picked_up', 'delivering');

-- Index pour les menu items disponibles (partial index)
CREATE INDEX IF NOT EXISTS idx_menu_items_available_restaurant 
ON public.menu_items (restaurant_id, is_available, order_count DESC) 
WHERE is_available = true;

-- Index composite pour recherche géographique des restaurants
CREATE INDEX IF NOT EXISTS idx_restaurants_location_coords
ON public.restaurants (latitude, longitude, is_verified, is_open)
WHERE is_verified = true;

SELECT 'Migration 012: Index optimisés avec succès!' AS status;
