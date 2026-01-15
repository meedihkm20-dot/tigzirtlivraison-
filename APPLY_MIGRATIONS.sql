-- ============================================
-- MIGRATIONS À EXÉCUTER SUR SUPABASE SQL EDITOR
-- Copier-coller ce fichier dans: https://supabase.com/dashboard/project/pauqmhqriyjdqctvfvtt/sql
-- ============================================

-- ============================================
-- MIGRATION 025: RACE CONDITION LIVREUR
-- ============================================

-- Ajouter colonne pour compter les tentatives
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS code_attempts INTEGER DEFAULT 0;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS code_blocked_until TIMESTAMPTZ;

-- Fonction atomique pour accepter une commande (anti race condition)
CREATE OR REPLACE FUNCTION accept_order_atomic(
    p_order_id UUID,
    p_livreur_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_order RECORD;
    v_livreur RECORD;
    v_result JSONB;
BEGIN
    -- 1. Vérifier que le livreur existe et est disponible
    SELECT * INTO v_livreur 
    FROM livreurs 
    WHERE id = p_livreur_id 
    AND is_verified = true 
    AND is_online = true 
    AND is_available = true
    FOR UPDATE;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'LIVREUR_NOT_AVAILABLE',
            'message', 'Vous n''êtes pas disponible pour accepter des commandes'
        );
    END IF;
    
    -- 2. Verrouiller et vérifier la commande (FOR UPDATE = lock exclusif)
    SELECT * INTO v_order 
    FROM orders 
    WHERE id = p_order_id 
    FOR UPDATE;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'ORDER_NOT_FOUND',
            'message', 'Commande introuvable'
        );
    END IF;
    
    -- 3. Vérifier que la commande est disponible
    IF v_order.status != 'ready' THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'ORDER_NOT_READY',
            'message', 'Cette commande n''est plus disponible (statut: ' || v_order.status || ')'
        );
    END IF;
    
    -- 4. Vérifier qu'aucun livreur n'est déjà assigné
    IF v_order.livreur_id IS NOT NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'ORDER_ALREADY_TAKEN',
            'message', 'Cette commande a déjà été acceptée par un autre livreur'
        );
    END IF;
    
    -- 5. ASSIGNER LE LIVREUR (point de non-retour)
    UPDATE orders SET
        livreur_id = p_livreur_id,
        status = 'picked_up',
        picked_up_at = NOW(),
        livreur_accepted_at = NOW()
    WHERE id = p_order_id;
    
    -- 6. Marquer le livreur comme occupé
    UPDATE livreurs SET
        is_available = false,
        updated_at = NOW()
    WHERE id = p_livreur_id;
    
    -- 7. Retourner le succès avec les infos
    RETURN jsonb_build_object(
        'success', true,
        'order_id', p_order_id,
        'order_number', v_order.order_number,
        'message', 'Commande acceptée avec succès!'
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'SYSTEM_ERROR',
            'message', 'Erreur système: ' || SQLERRM
        );
END;
$$;

GRANT EXECUTE ON FUNCTION accept_order_atomic TO authenticated;

-- ============================================
-- MIGRATION 026: SÉCURITÉ CODE CONFIRMATION
-- ============================================

-- Fonction sécurisée de vérification du code
CREATE OR REPLACE FUNCTION verify_confirmation_code_secure(
    p_order_id UUID,
    p_code VARCHAR(4),
    p_livreur_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_order RECORD;
    v_max_attempts CONSTANT INTEGER := 3;
    v_block_duration CONSTANT INTERVAL := '15 minutes';
BEGIN
    -- 1. Récupérer la commande avec verrouillage
    SELECT * INTO v_order 
    FROM orders 
    WHERE id = p_order_id 
    FOR UPDATE;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'ORDER_NOT_FOUND',
            'message', 'Commande introuvable'
        );
    END IF;
    
    -- 2. Vérifier que le livreur est bien assigné
    IF v_order.livreur_id != p_livreur_id THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'NOT_ASSIGNED',
            'message', 'Vous n''êtes pas assigné à cette commande'
        );
    END IF;
    
    -- 3. Vérifier le statut
    IF v_order.status NOT IN ('picked_up', 'delivering') THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'INVALID_STATUS',
            'message', 'Statut invalide pour vérification'
        );
    END IF;
    
    -- 4. Vérifier si le code est bloqué
    IF v_order.code_blocked_until IS NOT NULL AND v_order.code_blocked_until > NOW() THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'CODE_BLOCKED',
            'message', 'Trop de tentatives. Réessayez dans ' || 
                       EXTRACT(MINUTES FROM (v_order.code_blocked_until - NOW()))::INTEGER || ' minutes',
            'blocked_until', v_order.code_blocked_until
        );
    END IF;
    
    -- 5. Vérifier le code
    IF UPPER(v_order.confirmation_code) != UPPER(p_code) THEN
        -- Incrémenter le compteur de tentatives
        UPDATE orders SET 
            code_attempts = COALESCE(code_attempts, 0) + 1,
            code_blocked_until = CASE 
                WHEN COALESCE(code_attempts, 0) + 1 >= v_max_attempts 
                THEN NOW() + v_block_duration 
                ELSE NULL 
            END
        WHERE id = p_order_id;
        
        IF COALESCE(v_order.code_attempts, 0) + 1 >= v_max_attempts THEN
            RETURN jsonb_build_object(
                'success', false,
                'error', 'CODE_BLOCKED',
                'message', 'Trop de tentatives! Code bloqué pendant 15 minutes. Contactez le support.',
                'attempts', COALESCE(v_order.code_attempts, 0) + 1
            );
        END IF;
        
        RETURN jsonb_build_object(
            'success', false,
            'error', 'WRONG_CODE',
            'message', 'Code incorrect. ' || (v_max_attempts - COALESCE(v_order.code_attempts, 0) - 1)::TEXT || ' tentative(s) restante(s)',
            'attempts_remaining', v_max_attempts - COALESCE(v_order.code_attempts, 0) - 1
        );
    END IF;
    
    -- 6. CODE CORRECT - Finaliser la livraison
    UPDATE orders SET
        status = 'delivered',
        delivered_at = NOW(),
        code_verified_at = NOW(),
        code_attempts = 0,
        code_blocked_until = NULL
    WHERE id = p_order_id;
    
    -- Libérer le livreur
    UPDATE livreurs SET
        is_available = true,
        total_deliveries = total_deliveries + 1
    WHERE id = p_livreur_id;
    
    RETURN jsonb_build_object(
        'success', true,
        'message', 'Livraison confirmée avec succès!',
        'order_id', p_order_id,
        'delivered_at', NOW()
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'SYSTEM_ERROR',
            'message', 'Erreur système: ' || SQLERRM
        );
END;
$$;

-- Fonction admin pour débloquer un code
CREATE OR REPLACE FUNCTION admin_unblock_code(p_order_id UUID, p_admin_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Vérifier que c'est un admin
    IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = p_admin_id AND role = 'admin') THEN
        RETURN FALSE;
    END IF;
    
    UPDATE orders SET
        code_attempts = 0,
        code_blocked_until = NULL
    WHERE id = p_order_id;
    
    RETURN TRUE;
END;
$$;

GRANT EXECUTE ON FUNCTION verify_confirmation_code_secure TO authenticated;
GRANT EXECUTE ON FUNCTION admin_unblock_code TO authenticated;

-- ============================================
-- MIGRATION 027: PERFORMANCE RAMADAN
-- ============================================

-- Index composites pour les requêtes les plus fréquentes

-- 1. Commandes en attente par restaurant
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

-- 4. Livreurs disponibles
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

-- Fonction pour limiter le nombre de commandes simultanées par restaurant
CREATE OR REPLACE FUNCTION check_restaurant_capacity()
RETURNS TRIGGER AS $$
DECLARE
    v_pending_count INTEGER;
    v_max_capacity INTEGER := 20;
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

GRANT SELECT ON v_realtime_stats TO authenticated;

-- ============================================
-- FIN DES MIGRATIONS
-- ============================================
SELECT 'Migrations 025, 026, 027 appliquées avec succès!' AS status;
