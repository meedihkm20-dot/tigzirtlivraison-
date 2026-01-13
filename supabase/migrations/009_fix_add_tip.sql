-- ============================================
-- CORRECTION: Fonction add_tip
-- ============================================
-- La colonne s'appelle tip_amount, pas tip

DROP FUNCTION IF EXISTS add_tip(UUID, NUMERIC);

CREATE OR REPLACE FUNCTION add_tip(p_order_id UUID, p_amount NUMERIC)
RETURNS BOOLEAN AS $$
DECLARE
  v_order RECORD;
BEGIN
  SELECT * INTO v_order FROM orders WHERE id = p_order_id;
  
  IF v_order IS NULL OR v_order.status != 'delivered' THEN
    RETURN FALSE;
  END IF;
  
  -- Ajouter le pourboire (colonne tip_amount)
  UPDATE orders SET tip_amount = p_amount, tip_paid_at = NOW() WHERE id = p_order_id;
  
  -- Ajouter aux gains du livreur
  IF v_order.livreur_id IS NOT NULL THEN
    UPDATE livreurs SET 
      total_earnings = total_earnings + p_amount,
      bonus_earned = bonus_earned + p_amount
    WHERE id = v_order.livreur_id;
    
    -- Créer une transaction pour le pourboire
    INSERT INTO transactions (order_id, type, amount, recipient_id, status, description)
    SELECT p_order_id, 'tip', p_amount, l.user_id, 'completed', 'Pourboire commande #' || v_order.order_number
    FROM livreurs l WHERE l.id = v_order.livreur_id;
  END IF;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- Vérification des colonnes manquantes
-- ============================================

-- S'assurer que tip_amount existe
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS tip_amount DECIMAL(10,2) DEFAULT 0;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS tip_paid_at TIMESTAMPTZ;

-- S'assurer que referral_code existe dans referrals
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'referrals' AND column_name = 'referral_code') THEN
    ALTER TABLE public.referrals ADD COLUMN referral_code VARCHAR(20);
  END IF;
END $$;

SELECT 'Migration 009 exécutée avec succès!' AS status;
