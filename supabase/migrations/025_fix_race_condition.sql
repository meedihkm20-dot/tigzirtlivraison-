-- ============================================
-- CORRECTION CRITIQUE: Race Condition Livreur
-- ============================================
-- Cette fonction garantit qu'UN SEUL livreur peut accepter une commande
-- Utilise FOR UPDATE pour verrouiller la ligne pendant la transaction

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
