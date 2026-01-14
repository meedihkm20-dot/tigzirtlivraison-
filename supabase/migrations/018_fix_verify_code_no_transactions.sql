-- ============================================
-- FIX: verify_confirmation_code SANS transactions
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
    RAISE EXCEPTION 'Commande introuvable';
  END IF;
  
  -- Vérifier le code
  IF v_order.confirmation_code != p_code THEN
    RETURN FALSE;
  END IF;
  
  -- Vérifier que la commande est bien en statut picked_up
  IF v_order.status != 'picked_up' THEN
    RAISE EXCEPTION 'La commande n''est pas en cours de livraison';
  END IF;
  
  -- Mettre à jour le statut de la commande
  UPDATE orders SET 
    status = 'delivered',
    delivered_at = NOW()
  WHERE id = p_order_id;
  
  -- Mettre à jour les stats du livreur
  v_livreur_id := v_order.livreur_id;
  v_commission := COALESCE(v_order.livreur_commission, 0);
  
  IF v_livreur_id IS NOT NULL THEN
    UPDATE livreurs SET
      total_deliveries = total_deliveries + 1,
      total_earnings = total_earnings + v_commission,
      is_available = true
    WHERE id = v_livreur_id;
  END IF;
  
  -- Mettre à jour les stats du restaurant
  UPDATE restaurants SET
    total_reviews = total_reviews + 1
  WHERE id = v_order.restaurant_id;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Tester la fonction
SELECT '✅ Fonction verify_confirmation_code corrigée (sans transactions)' as message;
