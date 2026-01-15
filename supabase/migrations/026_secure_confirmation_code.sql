-- ============================================
-- SÉCURITÉ: Limite de tentatives code confirmation
-- ============================================

-- Ajouter colonne pour compter les tentatives
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS code_attempts INTEGER DEFAULT 0;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS code_blocked_until TIMESTAMPTZ;

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
            code_attempts = code_attempts + 1,
            code_blocked_until = CASE 
                WHEN code_attempts + 1 >= v_max_attempts 
                THEN NOW() + v_block_duration 
                ELSE NULL 
            END
        WHERE id = p_order_id;
        
        -- Log de sécurité
        INSERT INTO admin_audit_logs (action, entity_type, entity_id, old_value, new_value, reason)
        VALUES (
            'failed_code_attempt',
            'order',
            p_order_id,
            jsonb_build_object('livreur_id', p_livreur_id),
            jsonb_build_object('attempt', v_order.code_attempts + 1, 'code_entered', p_code),
            'Tentative de code échouée'
        );
        
        IF v_order.code_attempts + 1 >= v_max_attempts THEN
            RETURN jsonb_build_object(
                'success', false,
                'error', 'CODE_BLOCKED',
                'message', 'Trop de tentatives! Code bloqué pendant 15 minutes. Contactez le support.',
                'attempts', v_order.code_attempts + 1
            );
        END IF;
        
        RETURN jsonb_build_object(
            'success', false,
            'error', 'WRONG_CODE',
            'message', 'Code incorrect. ' || (v_max_attempts - v_order.code_attempts - 1)::TEXT || ' tentative(s) restante(s)',
            'attempts_remaining', v_max_attempts - v_order.code_attempts - 1
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
    
    -- Log
    INSERT INTO admin_audit_logs (admin_id, action, entity_type, entity_id, reason)
    VALUES (p_admin_id, 'unblock_code', 'order', p_order_id, 'Déblocage manuel du code');
    
    RETURN TRUE;
END;
$$;

GRANT EXECUTE ON FUNCTION verify_confirmation_code_secure TO authenticated;
GRANT EXECUTE ON FUNCTION admin_unblock_code TO authenticated;
