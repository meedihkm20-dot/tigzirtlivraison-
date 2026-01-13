-- DZ Delivery - Chat & Extra Features
-- Migration 007: Chat, Reorder suggestions, Enhanced tracking

-- ============================================
-- 0. CORRECTIONS PRÉALABLES
-- ============================================

-- Ajouter la colonne description à transactions si elle n'existe pas
ALTER TABLE public.transactions ADD COLUMN IF NOT EXISTS description TEXT;

-- ============================================
-- 1. CHAT ENTRE CLIENT ET LIVREUR
-- ============================================

CREATE TABLE IF NOT EXISTS public.order_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    sender_type VARCHAR(20) NOT NULL CHECK (sender_type IN ('customer', 'livreur', 'restaurant', 'system')),
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_order_messages_order ON public.order_messages(order_id, created_at);

ALTER TABLE public.order_messages ENABLE ROW LEVEL SECURITY;

-- Participants de la commande peuvent voir/envoyer des messages
CREATE POLICY "Order participants can view messages" ON public.order_messages FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.orders o
            WHERE o.id = order_messages.order_id
            AND (o.customer_id = auth.uid() OR o.livreur_id IN (SELECT id FROM public.livreurs WHERE user_id = auth.uid()))
        )
    );

CREATE POLICY "Order participants can send messages" ON public.order_messages FOR INSERT
    WITH CHECK (auth.uid() = sender_id);

-- ============================================
-- 2. SUGGESTIONS DE RECOMMANDE
-- ============================================

-- Mettre à jour les suggestions après chaque commande livrée
CREATE OR REPLACE FUNCTION update_reorder_suggestions()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.status = 'delivered' AND OLD.status != 'delivered' THEN
        -- Insérer ou mettre à jour la suggestion
        INSERT INTO public.reorder_suggestions (customer_id, restaurant_id, items, last_ordered_at, order_count)
        SELECT 
            NEW.customer_id,
            NEW.restaurant_id,
            (SELECT jsonb_agg(jsonb_build_object(
                'menu_item_id', oi.menu_item_id,
                'name', oi.name,
                'price', oi.price,
                'quantity', oi.quantity
            )) FROM public.order_items oi WHERE oi.order_id = NEW.id),
            NOW(),
            1
        ON CONFLICT (customer_id, restaurant_id) DO UPDATE SET
            items = EXCLUDED.items,
            last_ordered_at = NOW(),
            order_count = reorder_suggestions.order_count + 1;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS update_reorder_suggestions_trigger ON public.orders;
CREATE TRIGGER update_reorder_suggestions_trigger
    AFTER UPDATE ON public.orders
    FOR EACH ROW EXECUTE FUNCTION update_reorder_suggestions();

-- Ajouter contrainte unique si pas existante
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'reorder_suggestions_customer_restaurant_key'
    ) THEN
        ALTER TABLE public.reorder_suggestions 
        ADD CONSTRAINT reorder_suggestions_customer_restaurant_key 
        UNIQUE (customer_id, restaurant_id);
    END IF;
END $$;

-- ============================================
-- 3. TRACKING AMÉLIORÉ
-- ============================================

-- Historique des positions livreur (pour replay du trajet)
ALTER TABLE public.livreur_locations ADD COLUMN IF NOT EXISTS speed DECIMAL(5,2); -- km/h
ALTER TABLE public.livreur_locations ADD COLUMN IF NOT EXISTS heading DECIMAL(5,2); -- direction en degrés

-- ETA dynamique
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS current_eta_minutes INTEGER;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS distance_remaining_km DECIMAL(10,2);

-- ============================================
-- 4. SYSTÈME DE POURBOIRE
-- ============================================

ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS tip_amount DECIMAL(10,2) DEFAULT 0;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS tip_paid_at TIMESTAMPTZ;

-- Fonction pour ajouter un pourboire
CREATE OR REPLACE FUNCTION add_tip(
    p_order_id UUID,
    p_amount DECIMAL
)
RETURNS BOOLEAN
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_order RECORD;
BEGIN
    SELECT * INTO v_order FROM public.orders WHERE id = p_order_id AND status = 'delivered';
    IF NOT FOUND THEN RETURN false; END IF;
    
    -- Vérifier que c'est le client
    IF v_order.customer_id != auth.uid() THEN RETURN false; END IF;
    
    -- Ajouter le pourboire
    UPDATE public.orders SET 
        tip_amount = p_amount,
        tip_paid_at = NOW()
    WHERE id = p_order_id;
    
    -- Ajouter aux gains du livreur
    UPDATE public.livreurs SET
        total_earnings = total_earnings + p_amount
    WHERE id = v_order.livreur_id;
    
    -- Créer une transaction
    INSERT INTO public.transactions (
        order_id, type, amount, recipient_id, description
    ) VALUES (
        p_order_id, 'tip', p_amount, 
        (SELECT user_id FROM public.livreurs WHERE id = v_order.livreur_id),
        'Pourboire commande #' || v_order.order_number
    );
    
    RETURN true;
END;
$$;

-- ============================================
-- 5. SYSTÈME DE PARRAINAGE
-- ============================================

CREATE TABLE IF NOT EXISTS public.referrals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    referrer_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    referred_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    referral_code VARCHAR(20) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'rewarded')),
    referrer_reward DECIMAL(10,2) DEFAULT 500, -- 500 DA pour le parrain
    referred_reward DECIMAL(10,2) DEFAULT 300, -- 300 DA pour le filleul
    created_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    UNIQUE(referred_id)
);

-- Code de parrainage unique par utilisateur
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS referral_code VARCHAR(10);
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS referred_by UUID REFERENCES public.profiles(id);
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS referral_earnings DECIMAL(10,2) DEFAULT 0;

-- Générer un code de parrainage
CREATE OR REPLACE FUNCTION generate_referral_code()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
    NEW.referral_code := UPPER(SUBSTRING(MD5(NEW.id::text || NOW()::text) FROM 1 FOR 8));
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS generate_referral_code_trigger ON public.profiles;
CREATE TRIGGER generate_referral_code_trigger
    BEFORE INSERT ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION generate_referral_code();

-- Appliquer un code de parrainage
CREATE OR REPLACE FUNCTION apply_referral_code(p_code VARCHAR)
RETURNS TABLE (success BOOLEAN, message TEXT, bonus DECIMAL)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_referrer RECORD;
    v_current_user RECORD;
BEGIN
    -- Vérifier que l'utilisateur n'a pas déjà été parrainé
    SELECT * INTO v_current_user FROM public.profiles WHERE id = auth.uid();
    IF v_current_user.referred_by IS NOT NULL THEN
        RETURN QUERY SELECT false, 'Vous avez déjà utilisé un code de parrainage'::TEXT, 0::DECIMAL;
        RETURN;
    END IF;
    
    -- Trouver le parrain
    SELECT * INTO v_referrer FROM public.profiles WHERE referral_code = UPPER(p_code);
    IF NOT FOUND THEN
        RETURN QUERY SELECT false, 'Code de parrainage invalide'::TEXT, 0::DECIMAL;
        RETURN;
    END IF;
    
    -- Ne pas se parrainer soi-même
    IF v_referrer.id = auth.uid() THEN
        RETURN QUERY SELECT false, 'Vous ne pouvez pas utiliser votre propre code'::TEXT, 0::DECIMAL;
        RETURN;
    END IF;
    
    -- Appliquer le parrainage
    UPDATE public.profiles SET referred_by = v_referrer.id WHERE id = auth.uid();
    
    -- Créer l'entrée de parrainage
    INSERT INTO public.referrals (referrer_id, referred_id, referral_code)
    VALUES (v_referrer.id, auth.uid(), p_code);
    
    -- Donner le bonus au filleul immédiatement
    UPDATE public.profiles SET loyalty_points = loyalty_points + 300 WHERE id = auth.uid();
    
    RETURN QUERY SELECT true, 'Code appliqué! +300 points de bienvenue'::TEXT, 300::DECIMAL;
END;
$$;

-- Récompenser le parrain après la première commande du filleul
CREATE OR REPLACE FUNCTION reward_referrer_on_first_order()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
DECLARE
    v_referral RECORD;
    v_customer RECORD;
BEGIN
    IF NEW.status = 'delivered' AND OLD.status != 'delivered' THEN
        -- Vérifier si c'est la première commande du client
        IF (SELECT COUNT(*) FROM public.orders WHERE customer_id = NEW.customer_id AND status = 'delivered') = 1 THEN
            -- Récupérer le parrainage
            SELECT * INTO v_referral FROM public.referrals 
            WHERE referred_id = NEW.customer_id AND status = 'pending';
            
            IF FOUND THEN
                -- Récompenser le parrain
                UPDATE public.profiles SET 
                    loyalty_points = loyalty_points + 500,
                    referral_earnings = referral_earnings + 500
                WHERE id = v_referral.referrer_id;
                
                -- Marquer comme complété
                UPDATE public.referrals SET 
                    status = 'rewarded',
                    completed_at = NOW()
                WHERE id = v_referral.id;
                
                -- Notifier le parrain
                INSERT INTO public.notifications (user_id, title, body, notification_type, data)
                VALUES (
                    v_referral.referrer_id,
                    '🎉 Bonus parrainage!',
                    'Votre filleul a passé sa première commande. +500 points!',
                    'referral',
                    jsonb_build_object('referred_id', NEW.customer_id, 'bonus', 500)
                );
            END IF;
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS reward_referrer_trigger ON public.orders;
CREATE TRIGGER reward_referrer_trigger
    AFTER UPDATE ON public.orders
    FOR EACH ROW EXECUTE FUNCTION reward_referrer_on_first_order();

-- ============================================
-- 6. INDEXES PERFORMANCE
-- ============================================

CREATE INDEX IF NOT EXISTS idx_referrals_referrer ON public.referrals(referrer_id);
CREATE INDEX IF NOT EXISTS idx_referrals_code ON public.referrals(referral_code);
CREATE INDEX IF NOT EXISTS idx_profiles_referral_code ON public.profiles(referral_code);

-- ============================================
-- 7. RLS POLICIES
-- ============================================

ALTER TABLE public.referrals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can see their referrals" ON public.referrals FOR SELECT
    USING (auth.uid() = referrer_id OR auth.uid() = referred_id);
