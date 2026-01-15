-- ============================================
-- OPTIMISATIONS PERFORMANCE RAMADAN
-- ============================================

-- Index composites pour les requêtes les plus fréquentes

-- 1. Commandes en attente par restaurant (requête la plus fréquente)
CREATE INDEX IF NOT EXISTS idx_orders_restaurant_pending 
ON orders(restaurant_id, status, created_at DESC) 
WHERE status IN ('pending', 'confirmed', 'preparing');

-- 2. Commandes disponibles pour livreurs
CREATE INDEX IF NOT EXISTS idx_orders_available_for_delivery 
ON orders(status, livreur_id, created_at DESC) 
WHERE status = 'ready' AND livreur_id IS NULL;

-- 3. Commandes actives d'un livreur
CREATE INDEX IF NOT EXISTS idx_orders_livreur_active 
ON orders(livreur_id, status) 
WHERE status IN ('picked_up', 'delivering');

-- 4. Livreurs disponibles (requête fréquente)
CREATE INDEX IF NOT EXISTS idx_livreurs_available_online 
ON livreurs(is_online, is_available, is_verified, current_latitude, current_longitude) 
WHERE is_online = true AND is_available = true AND is_verified = true;

-- 5. Notifications non lues
CREATE INDEX IF NOT EXISTS idx_notifications_unread_user 
ON notifications(user_id, created_at DESC) 
WHERE is_read = false;

-- 6. Restaurants ouverts et vérifiés
CREATE INDEX IF NOT EXISTS idx_restaurants_open_verified 
ON restaurants(is_open, is_verified, rating DESC) 
WHERE is_open = true AND is_verified = true;

-- ============================================
-- LIMITES ET GARDE-FOUS
-- ============================================

-- Fonction pour limiter le nombre de commandes simultanées par restaurant
CREATE OR REPLACE FUNCTION check_restaurant_capacity()
RETURNS TRIGGER AS $$
DECLARE
    v_pending_count INTEGER;
    v_max_capacity INTEGER := 20; -- Max 20 commandes en cours
BEGIN
    SELECT COUNT(*) INTO v_pending_count
    FROM orders
    WHERE restaurant_id = NEW.restaurant_id
    AND status IN ('pending', 'confirmed', 'preparing');
    
    IF v_pending_count >= v_max_capacity THEN
        RAISE EXCEPTION 'Restaurant surchargé. Réessayez dans quelques minutes.';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS check_restaurant_capacity_trigger ON orders;
CREATE TRIGGER check_restaurant_capacity_trigger
    BEFORE INSERT ON orders
    FOR EACH ROW
    EXECUTE FUNCTION check_restaurant_capacity();

-- ============================================
-- NETTOYAGE AUTOMATIQUE
-- ============================================

-- Fonction pour nettoyer les anciennes données (à exécuter via cron)
CREATE OR REPLACE FUNCTION cleanup_old_data()
RETURNS void AS $$
BEGIN
    -- Supprimer les notifications lues de plus de 30 jours
    DELETE FROM notifications 
    WHERE is_read = true 
    AND created_at < NOW() - INTERVAL '30 days';
    
    -- Supprimer les positions GPS de plus de 7 jours
    DELETE FROM livreur_locations 
    WHERE recorded_at < NOW() - INTERVAL '7 days';
    
    -- Supprimer l'historique de recherche de plus de 30 jours
    DELETE FROM search_history 
    WHERE searched_at < NOW() - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- STATISTIQUES POUR MONITORING
-- ============================================

-- Vue pour le monitoring en temps réel
CREATE OR REPLACE VIEW v_realtime_stats AS
SELECT
    (SELECT COUNT(*) FROM orders WHERE status = 'pending') as pending_orders,
    (SELECT COUNT(*) FROM orders WHERE status IN ('confirmed', 'preparing')) as preparing_orders,
    (SELECT COUNT(*) FROM orders WHERE status IN ('picked_up', 'delivering')) as delivering_orders,
    (SELECT COUNT(*) FROM livreurs WHERE is_online = true AND is_available = true) as available_livreurs,
    (SELECT COUNT(*) FROM livreurs WHERE is_online = true AND is_available = false) as busy_livreurs,
    (SELECT COUNT(*) FROM restaurants WHERE is_open = true AND is_verified = true) as open_restaurants,
    (SELECT COUNT(*) FROM orders WHERE created_at > NOW() - INTERVAL '1 hour') as orders_last_hour;

-- Accorder l'accès à la vue
GRANT SELECT ON v_realtime_stats TO authenticated;
