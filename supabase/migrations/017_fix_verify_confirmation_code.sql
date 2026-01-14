-- ============================================
-- FIX: Fonction verify_confirmation_code
-- ============================================

DROP FUNCTION IF EXISTS verify_confirmation_code(UUID, TEXT);
DROP FUNCTION IF EXISTS verify_confirmation_code(UUID, VARCHAR);

CREATE OR REPLACE FUNCTION verify_confirmation_code(p_order_id UUID, p_code TEXT)
RETURNS BOOLEAN AS $$
DECLARE
  v_order RECORD;
  v_livreur_id UUID;
  v_commission NUMERIC;
BEGIN
  -- Récupérer la commande
  SELECT * INTO v_order FROM orders WHERE id = p_order_id;
  
  IF v_order IS NULL THEN
    RETURN FALSE;
  END IF;
  
  -- Vérifier le code
  IF v_order.confirmation_code != p_code THEN
    RETURN FALSE;
  END IF;
  
  -- Mettre à jour le statut
  UPDATE orders SET 
    status = 'delivered',
    delivered_at = NOW()
  WHERE id = p_order_id;
  
  -- Mettre à jour les stats du livreur
  v_livreur_id := v_order.livreur_id;
  v_commission := v_order.livreur_commission;
  
  IF v_livreur_id IS NOT NULL THEN
    UPDATE livreurs SET
      total_deliveries = total_deliveries + 1,
      total_earnings = total_earnings + COALESCE(v_commission, 0),
      is_available = true
    WHERE id = v_livreur_id;
    
    -- Créer la transaction pour le livreur
    INSERT INTO transactions (
      recipient_id,
      order_id,
      type,
      amount,
      status
    ) VALUES (
      (SELECT user_id FROM livreurs WHERE id = v_livreur_id),
      p_order_id,
      'livreur_earning',
      v_commission,
      'completed'
    );
  END IF;
  
  -- Créer la transaction pour le restaurant
  INSERT INTO transactions (
    recipient_id,
    order_id,
    type,
    amount,
    status
  ) VALUES (
    (SELECT owner_id FROM restaurants WHERE id = v_order.restaurant_id),
    p_order_id,
    'restaurant_earning',
    v_order.subtotal,
    'completed'
  );
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Tester la fonction
SELECT '✅ Fonction verify_confirmation_code corrigée' as message;
