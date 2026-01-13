-- ============================================
-- FONCTIONS RPC MANQUANTES
-- ============================================

-- Supprimer les fonctions existantes pour éviter les conflits de type
DROP FUNCTION IF EXISTS get_top_restaurants(INT);
DROP FUNCTION IF EXISTS get_top_menu_items(UUID, INT);
DROP FUNCTION IF EXISTS get_restaurant_stats(UUID);
DROP FUNCTION IF EXISTS verify_confirmation_code(UUID, TEXT);
DROP FUNCTION IF EXISTS apply_promotion(UUID, TEXT);
DROP FUNCTION IF EXISTS apply_referral_code(TEXT);
DROP FUNCTION IF EXISTS add_tip(UUID, NUMERIC);

-- Fonction pour obtenir les top restaurants
CREATE OR REPLACE FUNCTION get_top_restaurants(p_limit INT DEFAULT 10)
RETURNS TABLE (
  id UUID,
  name TEXT,
  logo_url TEXT,
  cover_url TEXT,
  rating NUMERIC,
  total_reviews INT,
  cuisine_type TEXT,
  avg_prep_time INT,
  delivery_fee NUMERIC,
  is_open BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    r.id,
    r.name,
    r.logo_url,
    r.cover_url,
    r.rating,
    r.total_reviews,
    r.cuisine_type,
    r.avg_prep_time,
    r.delivery_fee,
    r.is_open
  FROM restaurants r
  WHERE r.is_verified = true
  ORDER BY r.rating DESC, r.total_reviews DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour obtenir les top plats
CREATE OR REPLACE FUNCTION get_top_menu_items(p_restaurant_id UUID DEFAULT NULL, p_limit INT DEFAULT 20)
RETURNS TABLE (
  id UUID,
  name TEXT,
  description TEXT,
  price NUMERIC,
  image_url TEXT,
  avg_rating NUMERIC,
  order_count INT,
  restaurant_id UUID,
  restaurant_name TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    mi.id,
    mi.name,
    mi.description,
    mi.price,
    mi.image_url,
    mi.avg_rating,
    mi.order_count,
    mi.restaurant_id,
    r.name as restaurant_name
  FROM menu_items mi
  JOIN restaurants r ON r.id = mi.restaurant_id
  WHERE mi.is_available = true
    AND r.is_verified = true
    AND (p_restaurant_id IS NULL OR mi.restaurant_id = p_restaurant_id)
  ORDER BY mi.order_count DESC, mi.avg_rating DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour obtenir les stats du restaurant
CREATE OR REPLACE FUNCTION get_restaurant_stats(restaurant_uuid UUID)
RETURNS TABLE (
  total_orders BIGINT,
  total_revenue NUMERIC,
  orders_today BIGINT,
  revenue_today NUMERIC,
  pending_orders BIGINT,
  avg_rating NUMERIC
) AS $$
DECLARE
  today_start TIMESTAMP := DATE_TRUNC('day', NOW());
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*)::BIGINT as total_orders,
    COALESCE(SUM(o.total), 0)::NUMERIC as total_revenue,
    COUNT(*) FILTER (WHERE o.created_at >= today_start)::BIGINT as orders_today,
    COALESCE(SUM(o.total) FILTER (WHERE o.created_at >= today_start), 0)::NUMERIC as revenue_today,
    COUNT(*) FILTER (WHERE o.status IN ('pending', 'confirmed', 'preparing'))::BIGINT as pending_orders,
    COALESCE(AVG(rv.restaurant_rating), 0)::NUMERIC as avg_rating
  FROM orders o
  LEFT JOIN reviews rv ON rv.order_id = o.id
  WHERE o.restaurant_id = restaurant_uuid;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour vérifier le code de confirmation
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
  END IF;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour appliquer un code promo
CREATE OR REPLACE FUNCTION apply_promotion(p_order_id UUID, p_promo_code TEXT)
RETURNS TABLE (success BOOLEAN, discount NUMERIC, message TEXT) AS $$
DECLARE
  v_promo RECORD;
  v_order RECORD;
  v_discount NUMERIC;
BEGIN
  -- Récupérer la promo
  SELECT * INTO v_promo FROM promotions 
  WHERE code = p_promo_code 
    AND is_active = true 
    AND (ends_at IS NULL OR ends_at > NOW())
    AND (usage_limit IS NULL OR usage_count < usage_limit);
  
  IF v_promo IS NULL THEN
    RETURN QUERY SELECT FALSE, 0::NUMERIC, 'Code promo invalide ou expiré'::TEXT;
    RETURN;
  END IF;
  
  -- Récupérer la commande
  SELECT * INTO v_order FROM orders WHERE id = p_order_id;
  
  IF v_order IS NULL THEN
    RETURN QUERY SELECT FALSE, 0::NUMERIC, 'Commande non trouvée'::TEXT;
    RETURN;
  END IF;
  
  -- Vérifier le montant minimum
  IF v_order.subtotal < v_promo.min_order_amount THEN
    RETURN QUERY SELECT FALSE, 0::NUMERIC, ('Montant minimum: ' || v_promo.min_order_amount || ' DA')::TEXT;
    RETURN;
  END IF;
  
  -- Calculer la réduction
  IF v_promo.discount_type = 'percentage' THEN
    v_discount := v_order.subtotal * v_promo.discount_value / 100;
    IF v_promo.max_discount IS NOT NULL AND v_discount > v_promo.max_discount THEN
      v_discount := v_promo.max_discount;
    END IF;
  ELSE
    v_discount := v_promo.discount_value;
  END IF;
  
  -- Appliquer la réduction
  UPDATE orders SET
    discount = v_discount,
    promotion_id = v_promo.id,
    total = subtotal + delivery_fee - v_discount
  WHERE id = p_order_id;
  
  -- Incrémenter le compteur d'utilisation
  UPDATE promotions SET usage_count = usage_count + 1 WHERE id = v_promo.id;
  
  RETURN QUERY SELECT TRUE, v_discount, ('Réduction de ' || v_discount || ' DA appliquée!')::TEXT;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour appliquer un code de parrainage
CREATE OR REPLACE FUNCTION apply_referral_code(p_code TEXT)
RETURNS TABLE (success BOOLEAN, message TEXT) AS $$
DECLARE
  v_referrer_id UUID;
  v_current_user_id UUID;
BEGIN
  v_current_user_id := auth.uid();
  
  IF v_current_user_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Non connecté'::TEXT;
    RETURN;
  END IF;
  
  -- Vérifier si l'utilisateur a déjà utilisé un code
  IF EXISTS (SELECT 1 FROM referrals WHERE referred_id = v_current_user_id) THEN
    RETURN QUERY SELECT FALSE, 'Vous avez déjà utilisé un code de parrainage'::TEXT;
    RETURN;
  END IF;
  
  -- Trouver le parrain
  SELECT id INTO v_referrer_id FROM profiles WHERE referral_code = p_code;
  
  IF v_referrer_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Code de parrainage invalide'::TEXT;
    RETURN;
  END IF;
  
  IF v_referrer_id = v_current_user_id THEN
    RETURN QUERY SELECT FALSE, 'Vous ne pouvez pas utiliser votre propre code'::TEXT;
    RETURN;
  END IF;
  
  -- Créer le parrainage
  INSERT INTO referrals (referrer_id, referred_id, status)
  VALUES (v_referrer_id, v_current_user_id, 'pending');
  
  -- Donner les points de bienvenue au filleul
  UPDATE profiles SET loyalty_points = loyalty_points + 300 WHERE id = v_current_user_id;
  
  RETURN QUERY SELECT TRUE, 'Code appliqué! Vous avez reçu 300 points de bienvenue 🎁'::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour ajouter un pourboire
CREATE OR REPLACE FUNCTION add_tip(p_order_id UUID, p_amount NUMERIC)
RETURNS BOOLEAN AS $$
DECLARE
  v_order RECORD;
BEGIN
  SELECT * INTO v_order FROM orders WHERE id = p_order_id;
  
  IF v_order IS NULL OR v_order.status != 'delivered' THEN
    RETURN FALSE;
  END IF;
  
  -- Ajouter le pourboire
  UPDATE orders SET tip = p_amount WHERE id = p_order_id;
  
  -- Ajouter aux gains du livreur
  IF v_order.livreur_id IS NOT NULL THEN
    UPDATE livreurs SET 
      total_earnings = total_earnings + p_amount,
      bonus_earned = bonus_earned + p_amount
    WHERE id = v_order.livreur_id;
  END IF;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Créer les tables manquantes si elles n'existent pas

-- Table des recherches
CREATE TABLE IF NOT EXISTS search_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  query TEXT NOT NULL,
  searched_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des adresses sauvegardées
CREATE TABLE IF NOT EXISTS saved_addresses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  label TEXT NOT NULL,
  address TEXT NOT NULL,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  instructions TEXT,
  is_default BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des parrainages
CREATE TABLE IF NOT EXISTS referrals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  referrer_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  referred_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'rewarded')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  rewarded_at TIMESTAMP WITH TIME ZONE,
  UNIQUE(referred_id)
);

-- Table des bonus livreur
CREATE TABLE IF NOT EXISTS livreur_bonuses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  livreur_id UUID REFERENCES livreurs(id) ON DELETE CASCADE,
  bonus_type TEXT NOT NULL,
  amount NUMERIC NOT NULL,
  description TEXT,
  earned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des objectifs livreur
CREATE TABLE IF NOT EXISTS livreur_targets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  target_type TEXT NOT NULL CHECK (target_type IN ('daily', 'weekly', 'monthly')),
  deliveries_required INT NOT NULL,
  bonus_amount NUMERIC NOT NULL,
  is_active BOOLEAN DEFAULT TRUE
);

-- Table de configuration des tiers (ne pas créer si existe déjà)
-- CREATE TABLE IF NOT EXISTS tier_config (
--   id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
--   tier TEXT UNIQUE NOT NULL CHECK (tier IN ('bronze', 'silver', 'gold', 'diamond')),
--   min_deliveries INT NOT NULL,
--   min_rating NUMERIC NOT NULL,
--   max_cancellation_rate NUMERIC NOT NULL,
--   commission_rate NUMERIC NOT NULL
-- );

-- Mettre à jour les configurations de tier existantes
UPDATE tier_config SET 
  min_deliveries = 0,
  min_rating = 0,
  max_cancellation_rate = 100,
  commission_rate = 10
WHERE tier = 'bronze';

UPDATE tier_config SET 
  min_deliveries = 50,
  min_rating = 4.0,
  max_cancellation_rate = 15,
  commission_rate = 12
WHERE tier = 'silver';

UPDATE tier_config SET 
  min_deliveries = 200,
  min_rating = 4.5,
  max_cancellation_rate = 10,
  commission_rate = 15
WHERE tier = 'gold';

UPDATE tier_config SET 
  min_deliveries = 500,
  min_rating = 4.8,
  max_cancellation_rate = 5,
  commission_rate = 20
WHERE tier = 'diamond';

-- Insérer les objectifs par défaut
INSERT INTO livreur_targets (target_type, deliveries_required, bonus_amount)
VALUES 
  ('daily', 5, 200),
  ('daily', 10, 500),
  ('weekly', 30, 1500),
  ('weekly', 50, 3000),
  ('monthly', 100, 5000)
ON CONFLICT DO NOTHING;

-- Ajouter les colonnes manquantes aux tables existantes
DO $$ 
BEGIN
  -- Ajouter referral_code à profiles si manquant
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'referral_code') THEN
    ALTER TABLE profiles ADD COLUMN referral_code TEXT UNIQUE;
  END IF;
  
  -- Ajouter referral_earnings à profiles si manquant
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'referral_earnings') THEN
    ALTER TABLE profiles ADD COLUMN referral_earnings NUMERIC DEFAULT 0;
  END IF;
  
  -- Ajouter loyalty_points à profiles si manquant
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'loyalty_points') THEN
    ALTER TABLE profiles ADD COLUMN loyalty_points INT DEFAULT 0;
  END IF;
  
  -- Ajouter total_orders à profiles si manquant
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'total_orders') THEN
    ALTER TABLE profiles ADD COLUMN total_orders INT DEFAULT 0;
  END IF;
  
  -- Ajouter total_spent à profiles si manquant
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'total_spent') THEN
    ALTER TABLE profiles ADD COLUMN total_spent NUMERIC DEFAULT 0;
  END IF;
  
  -- Ajouter confirmation_code à orders si manquant
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'confirmation_code') THEN
    ALTER TABLE orders ADD COLUMN confirmation_code TEXT;
  END IF;
  
  -- Ajouter livreur_commission à orders si manquant
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'livreur_commission') THEN
    ALTER TABLE orders ADD COLUMN livreur_commission NUMERIC DEFAULT 0;
  END IF;
  
  -- Ajouter tip à orders si manquant
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'tip') THEN
    ALTER TABLE orders ADD COLUMN tip NUMERIC DEFAULT 0;
  END IF;
  
  -- Ajouter discount à orders si manquant
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'discount') THEN
    ALTER TABLE orders ADD COLUMN discount NUMERIC DEFAULT 0;
  END IF;
  
  -- Ajouter promotion_id à orders si manquant
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'promotion_id') THEN
    ALTER TABLE orders ADD COLUMN promotion_id UUID REFERENCES promotions(id);
  END IF;
  
  -- Ajouter is_daily_special à menu_items si manquant
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'menu_items' AND column_name = 'is_daily_special') THEN
    ALTER TABLE menu_items ADD COLUMN is_daily_special BOOLEAN DEFAULT FALSE;
  END IF;
  
  -- Ajouter daily_special_price à menu_items si manquant
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'menu_items' AND column_name = 'daily_special_price') THEN
    ALTER TABLE menu_items ADD COLUMN daily_special_price NUMERIC;
  END IF;
  
  -- Ajouter order_count à menu_items si manquant
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'menu_items' AND column_name = 'order_count') THEN
    ALTER TABLE menu_items ADD COLUMN order_count INT DEFAULT 0;
  END IF;
  
  -- Ajouter avg_rating à menu_items si manquant
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'menu_items' AND column_name = 'avg_rating') THEN
    ALTER TABLE menu_items ADD COLUMN avg_rating NUMERIC DEFAULT 0;
  END IF;
  
  -- Ajouter total_reviews à menu_items si manquant
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'menu_items' AND column_name = 'total_reviews') THEN
    ALTER TABLE menu_items ADD COLUMN total_reviews INT DEFAULT 0;
  END IF;
END $$;

-- Générer un code de parrainage pour les utilisateurs existants
UPDATE profiles 
SET referral_code = UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 6))
WHERE referral_code IS NULL;

-- Trigger pour générer le code de parrainage à l'inscription
CREATE OR REPLACE FUNCTION generate_referral_code()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.referral_code IS NULL THEN
    NEW.referral_code := UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 6));
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_generate_referral_code ON profiles;
CREATE TRIGGER trigger_generate_referral_code
  BEFORE INSERT ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION generate_referral_code();

-- Trigger pour générer le code de confirmation à la création de commande
CREATE OR REPLACE FUNCTION generate_confirmation_code()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.confirmation_code IS NULL THEN
    NEW.confirmation_code := LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0');
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_generate_confirmation_code ON orders;
CREATE TRIGGER trigger_generate_confirmation_code
  BEFORE INSERT ON orders
  FOR EACH ROW
  EXECUTE FUNCTION generate_confirmation_code();

-- Trigger pour calculer la commission du livreur
CREATE OR REPLACE FUNCTION calculate_livreur_commission()
RETURNS TRIGGER AS $$
DECLARE
  v_tier TEXT;
  v_rate NUMERIC;
BEGIN
  IF NEW.livreur_id IS NOT NULL AND NEW.livreur_commission IS NULL THEN
    -- Récupérer le tier du livreur
    SELECT tier INTO v_tier FROM livreurs WHERE id = NEW.livreur_id;
    
    -- Récupérer le taux de commission
    SELECT commission_rate INTO v_rate FROM tier_config WHERE tier = COALESCE(v_tier, 'bronze');
    
    -- Calculer la commission (pourcentage du delivery_fee)
    NEW.livreur_commission := NEW.delivery_fee * COALESCE(v_rate, 10) / 100;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_calculate_commission ON orders;
CREATE TRIGGER trigger_calculate_commission
  BEFORE INSERT OR UPDATE ON orders
  FOR EACH ROW
  EXECUTE FUNCTION calculate_livreur_commission();
