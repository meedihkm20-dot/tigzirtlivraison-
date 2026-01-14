-- Migration: Support pour Edge Functions
-- Date: 2026-01-15
-- Description: Améliore RLS et ajoute fonctions de support pour Edge Functions

-- ============================================
-- AMÉLIORATION RLS COMMANDES LIVREUR
-- ============================================

-- Supprimer l'ancienne politique si elle existe (pour la recréer proprement)
DROP POLICY IF EXISTS "livreur_view_orders" ON public.orders;
DROP POLICY IF EXISTS "Livreurs can view available orders" ON public.orders;
DROP POLICY IF EXISTS "Livreurs can view assigned orders" ON public.orders;

-- Politique unifiée pour les livreurs (lecture)
CREATE POLICY "livreur_view_orders" ON public.orders
FOR SELECT USING (
    -- Livreur peut voir ses commandes assignées
    (
        livreur_id IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM public.livreurs
            WHERE id = orders.livreur_id
            AND user_id = auth.uid()
        )
    )
    OR
    -- Livreur vérifié peut voir les commandes disponibles
    (
        status = 'pending'
        AND livreur_id IS NULL
        AND EXISTS (
            SELECT 1 FROM public.livreurs
            WHERE user_id = auth.uid()
            AND is_verified = true
        )
    )
);

-- ============================================
-- COLONNE POUR TRACKING ANNULATION
-- ============================================

-- Ajouter colonne cancelled_by si elle n'existe pas
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'orders' AND column_name = 'cancelled_by'
    ) THEN
        ALTER TABLE public.orders ADD COLUMN cancelled_by TEXT;
    END IF;
END $$;

-- Ajouter colonne code_verified_at si elle n'existe pas
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'orders' AND column_name = 'code_verified_at'
    ) THEN
        ALTER TABLE public.orders ADD COLUMN code_verified_at TIMESTAMPTZ;
    END IF;
END $$;

-- ============================================
-- FONCTION POUR INCRÉMENTER STATS LIVREUR
-- ============================================

CREATE OR REPLACE FUNCTION increment_livreur_stats(
    p_livreur_id UUID,
    p_commission DECIMAL DEFAULT 0
)
RETURNS VOID AS $$
BEGIN
    UPDATE public.livreurs
    SET 
        total_deliveries = COALESCE(total_deliveries, 0) + 1,
        total_earnings = COALESCE(total_earnings, 0) + p_commission
    WHERE id = p_livreur_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- TABLE AUDIT EVENTS (OPTIONNEL MAIS RECOMMANDÉ)
-- ============================================

CREATE TABLE IF NOT EXISTS public.audit_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type TEXT NOT NULL,
    table_name TEXT,
    record_id UUID,
    user_id UUID REFERENCES auth.users(id),
    user_role TEXT,
    old_data JSONB,
    new_data JSONB,
    ip_address TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index pour recherche rapide
CREATE INDEX IF NOT EXISTS idx_audit_events_type ON public.audit_events(event_type);
CREATE INDEX IF NOT EXISTS idx_audit_events_user ON public.audit_events(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_events_created ON public.audit_events(created_at DESC);

-- RLS sur audit_events (admin only)
ALTER TABLE public.audit_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admin can view audit events" ON public.audit_events
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid()
        AND role = 'admin'
    )
);

-- ============================================
-- FONCTION POUR LOGGER LES ÉVÉNEMENTS
-- ============================================

CREATE OR REPLACE FUNCTION log_audit_event(
    p_event_type TEXT,
    p_table_name TEXT,
    p_record_id UUID,
    p_old_data JSONB DEFAULT NULL,
    p_new_data JSONB DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_user_role TEXT;
    v_event_id UUID;
BEGIN
    -- Récupérer le rôle de l'utilisateur
    SELECT role INTO v_user_role
    FROM public.profiles
    WHERE id = auth.uid();

    INSERT INTO public.audit_events (
        event_type, table_name, record_id, user_id, user_role, old_data, new_data
    ) VALUES (
        p_event_type, p_table_name, p_record_id, auth.uid(), v_user_role, p_old_data, p_new_data
    ) RETURNING id INTO v_event_id;

    RETURN v_event_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- TRIGGER POUR AUDIT AUTOMATIQUE DES COMMANDES
-- ============================================

CREATE OR REPLACE FUNCTION audit_order_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        -- Logger uniquement les changements de statut
        IF OLD.status IS DISTINCT FROM NEW.status THEN
            PERFORM log_audit_event(
                'order_status_change',
                'orders',
                NEW.id,
                jsonb_build_object('status', OLD.status),
                jsonb_build_object('status', NEW.status)
            );
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Créer le trigger si pas existant
DROP TRIGGER IF EXISTS trigger_audit_orders ON public.orders;
CREATE TRIGGER trigger_audit_orders
    AFTER UPDATE ON public.orders
    FOR EACH ROW
    EXECUTE FUNCTION audit_order_changes();

COMMENT ON TABLE public.audit_events IS 'Table d''audit pour tracer les actions sensibles';
