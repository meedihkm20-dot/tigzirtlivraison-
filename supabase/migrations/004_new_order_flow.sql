-- DZ Delivery - New Order Flow
-- Migration: Code confirmation + Commissions + Livreur-first flow

-- ============================================
-- 1. AJOUTER COLONNES POUR LE NOUVEAU FLUX
-- ============================================

-- Code de confirmation (4 chiffres)
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS confirmation_code VARCHAR(4);

-- Commissions
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS livreur_commission DECIMAL(10, 2) DEFAULT 0;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS admin_commission DECIMAL(10, 2) DEFAULT 0;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS restaurant_amount DECIMAL(10, 2) DEFAULT 0;

-- Timestamps supplémentaires
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS livreur_accepted_at TIMESTAMPTZ;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS code_verified_at TIMESTAMPTZ;

-- ============================================
-- 2. TABLE DES PARAMÈTRES DE COMMISSION
-- ============================================

CREATE TABLE IF NOT EXISTS public.commission_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    livreur_commission_percent DECIMAL(5, 2) DEFAULT 15.00, -- 15% pour le livreur
    admin_commission_percent DECIMAL(5, 2) DEFAULT 5.00,    -- 5% pour l'admin (toi)
    min_delivery_fee DECIMAL(10, 2) DEFAULT 100.00,         -- Frais minimum 100 DA
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insérer les paramètres par défaut
INSERT INTO public.commission_settings (livreur_commission_percent, admin_commission_percent, min_delivery_fee)
VALUES (15.00, 5.00, 100.00)
ON CONFLICT DO NOTHING;

-- ============================================
-- 3. TABLE DES TRANSACTIONS FINANCIÈRES
-- ============================================

CREATE TABLE IF NOT EXISTS public.transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
    type VARCHAR(20) NOT NULL, -- 'livreur_earning', 'admin_commission', 'restaurant_payment'
    amount DECIMAL(10, 2) NOT NULL,
    recipient_id UUID, -- user_id du bénéficiaire
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'completed', 'cancelled'
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 4. FONCTION: GÉNÉRER CODE CONFIRMATION
-- ============================================

CREATE OR REPLACE FUNCTION generate_confirmation_code()
RETURNS TRIGGER AS $$
BEGIN
    -- Générer un code à 4 chiffres aléatoire
    NEW.confirmation_code = LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour générer le code à la création de commande
DROP TRIGGER IF EXISTS generate_confirmation_code_trigger ON public.orders;
CREATE TRIGGER generate_confirmation_code_trigger
    BEFORE INSERT ON public.orders
    FOR EACH ROW EXECUTE FUNCTION generate_confirmation_code();

-- ============================================
-- 5. FONCTION: CALCULER LES COMMISSIONS
-- ============================================

CREATE OR REPLACE FUNCTION calculate_commissions()
RETURNS TRIGGER AS $$
DECLARE
    settings RECORD;
    total_amount DECIMAL;
    livreur_comm DECIMAL;
    admin_comm DECIMAL;
    restaurant_amt DECIMAL;
BEGIN
    -- Récupérer les paramètres de commission
    SELECT * INTO settings FROM public.commission_settings LIMIT 1;
    
    total_amount := NEW.total;
    
    -- Calculer les commissions
    -- Commission livreur = frais de livraison (minimum garanti)
    livreur_comm := GREATEST(NEW.delivery_fee, settings.min_delivery_fee);
    
    -- Commission admin = % du total de la commande
    admin_comm := (total_amount * settings.admin_commission_percent / 100);
    
    -- Montant restaurant = total - commission admin
    restaurant_amt := total_amount - admin_comm - NEW.delivery_fee;
    
    NEW.livreur_commission := livreur_comm;
    NEW.admin_commission := admin_comm;
    NEW.restaurant_amount := restaurant_amt;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour calculer les commissions à la création
DROP TRIGGER IF EXISTS calculate_commissions_trigger ON public.orders;
CREATE TRIGGER calculate_commissions_trigger
    BEFORE INSERT ON public.orders
    FOR EACH ROW EXECUTE FUNCTION calculate_commissions();

-- ============================================
-- 6. FONCTION: CRÉER TRANSACTIONS À LA LIVRAISON
-- ============================================

CREATE OR REPLACE FUNCTION create_delivery_transactions()
RETURNS TRIGGER AS $$
BEGIN
    -- Seulement quand le statut passe à 'delivered'
    IF NEW.status = 'delivered' AND OLD.status != 'delivered' THEN
        -- Transaction pour le livreur
        INSERT INTO public.transactions (order_id, type, amount, recipient_id, status)
        SELECT NEW.id, 'livreur_earning', NEW.livreur_commission, l.user_id, 'completed'
        FROM public.livreurs l WHERE l.id = NEW.livreur_id;
        
        -- Transaction pour l'admin
        INSERT INTO public.transactions (order_id, type, amount, recipient_id, status)
        VALUES (NEW.id, 'admin_commission', NEW.admin_commission, NULL, 'completed');
        
        -- Transaction pour le restaurant
        INSERT INTO public.transactions (order_id, type, amount, recipient_id, status)
        SELECT NEW.id, 'restaurant_payment', NEW.restaurant_amount, r.owner_id, 'pending'
        FROM public.restaurants r WHERE r.id = NEW.restaurant_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS create_delivery_transactions_trigger ON public.orders;
CREATE TRIGGER create_delivery_transactions_trigger
    AFTER UPDATE ON public.orders
    FOR EACH ROW EXECUTE FUNCTION create_delivery_transactions();

-- ============================================
-- 7. FONCTION: VÉRIFIER CODE CONFIRMATION
-- ============================================

CREATE OR REPLACE FUNCTION verify_confirmation_code(
    p_order_id UUID,
    p_code VARCHAR(4)
)
RETURNS BOOLEAN AS $$
DECLARE
    stored_code VARCHAR(4);
BEGIN
    SELECT confirmation_code INTO stored_code
    FROM public.orders
    WHERE id = p_order_id;
    
    IF stored_code = p_code THEN
        UPDATE public.orders
        SET code_verified_at = NOW(),
            status = 'delivered',
            delivered_at = NOW()
        WHERE id = p_order_id;
        RETURN TRUE;
    END IF;
    
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 8. FONCTION: STATS ADMIN (COMMISSIONS)
-- ============================================

CREATE OR REPLACE FUNCTION get_admin_stats()
RETURNS TABLE (
    total_orders BIGINT,
    total_revenue DECIMAL,
    total_admin_commission DECIMAL,
    today_orders BIGINT,
    today_commission DECIMAL,
    pending_restaurant_payments DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::BIGINT,
        COALESCE(SUM(total), 0),
        COALESCE(SUM(admin_commission), 0),
        COUNT(*) FILTER (WHERE DATE(created_at) = CURRENT_DATE)::BIGINT,
        COALESCE(SUM(admin_commission) FILTER (WHERE DATE(created_at) = CURRENT_DATE), 0),
        COALESCE((SELECT SUM(amount) FROM public.transactions WHERE type = 'restaurant_payment' AND status = 'pending'), 0)
    FROM public.orders
    WHERE status = 'delivered';
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 9. INDEX POUR PERFORMANCE
-- ============================================

CREATE INDEX IF NOT EXISTS idx_orders_confirmation_code ON public.orders(confirmation_code);
CREATE INDEX IF NOT EXISTS idx_transactions_order_id ON public.transactions(order_id);
CREATE INDEX IF NOT EXISTS idx_transactions_recipient ON public.transactions(recipient_id);
CREATE INDEX IF NOT EXISTS idx_transactions_type ON public.transactions(type);

-- ============================================
-- 10. RLS POUR TRANSACTIONS
-- ============================================

ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

-- Admin peut tout voir
CREATE POLICY "Admin full access transactions" ON public.transactions
    FOR ALL USING (
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Livreurs voient leurs transactions
CREATE POLICY "Livreurs view own transactions" ON public.transactions
    FOR SELECT USING (recipient_id = auth.uid());

-- Restaurants voient leurs transactions
CREATE POLICY "Restaurants view own transactions" ON public.transactions
    FOR SELECT USING (recipient_id = auth.uid());
