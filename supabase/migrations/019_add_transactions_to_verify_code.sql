-- ============================================
-- AMÉLIORATION: Ajouter les transactions
-- ============================================

DROP FUNCTION IF EXISTS verify_confirmation_code(UUID, TEXT);

CREATE OR REPLACE FUNCTION verify_confirmation_code(p_order_id UUID, p_code TEXT)
RETURNS BOOLEAN AS $$
DECLARE
  v_order RECORD;
  v_livreur_id UUID;
  v_livreur_user_id UUID;
  v_restaurant_owner_id UUID;
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
  
  -- Récupérer les IDs nécessaires
  v_livreur_id := v_order.livreur_id;
  v_commission := COALESCE(v_order.livreur_commission, 0);
  
  IF v_livreur_id IS NOT NULL THEN
    -- Récupérer le user_id du livreur
    SELECT user_id INTO v_livreur_user_id 
    FROM livreurs 
    WHERE id = v_livreur_id;
    
    -- Mettre à jour les stats du livreur
    UPDATE livreurs SET
      total_deliveries = total_deliveries + 1,
      total_earnings = total_earnings + v_commission,
      is_available = true
    WHERE id = v_livreur_id;
    
    -- Créer la transaction pour le livreur
    IF v_livreur_user_id IS NOT NULL THEN
      INSERT INTO transactions (
        recipient_id,
        order_id,
        type,
        amount,
        status
      ) VALUES (
        v_livreur_user_id,
        p_order_id,
        'livreur_earning',
        v_commission,
        'completed'
      );
    END IF;
  END IF;
  
  -- Récupérer l'owner_id du restaurant
  SELECT owner_id INTO v_restaurant_owner_id
  FROM restaurants
  WHERE id = v_order.restaurant_id;
  
  -- Créer la transaction pour le restaurant
  IF v_restaurant_owner_id IS NOT NULL THEN
    INSERT INTO transactions (
      recipient_id,
      order_id,
      type,
      amount,
      status
    ) VALUES (
      v_restaurant_owner_id,
      p_order_id,
      'restaurant_earning',
      v_order.subtotal,
      'completed'
    );
  END IF;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Tester la fonction
SELECT '✅ Fonction verify_confirmation_code avec transactions' as message;
