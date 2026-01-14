-- Migration: Système Admin Avancé
-- Date: 2026-01-15
-- Description: Rôles admin, audit logs, paramètres globaux, incidents

-- ============================================
-- 1. RÔLES ADMIN GRANULAIRES
-- ============================================

-- Type ENUM pour les rôles admin
DO $$ BEGIN
    CREATE TYPE admin_role AS ENUM (
        'super_admin',    -- Tout accès
        'ops_admin',      -- Opérations (commandes, livreurs)
        'support_admin',  -- Support client
        'finance_admin',  -- Lecture finance uniquement
        'readonly_admin'  -- Audit/lecture seule
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Table des admins avec rôles granulaires
CREATE TABLE IF NOT EXISTS public.admin_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
    admin_role admin_role NOT NULL DEFAULT 'readonly_admin',
    permissions JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    last_login_at TIMESTAMPTZ,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index
CREATE INDEX IF NOT EXISTS idx_admin_users_role ON public.admin_users(admin_role);
CREATE INDEX IF NOT EXISTS idx_admin_users_active ON public.admin_users(is_active);

-- ============================================
-- 2. AUDIT LOGS ADMIN (CRITIQUE)
-- ============================================

CREATE TABLE IF NOT EXISTS public.admin_audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id UUID REFERENCES auth.users(id),
    admin_role TEXT,
    action TEXT NOT NULL,
    entity_type TEXT NOT NULL,  -- 'restaurant', 'livreur', 'order', 'user', 'settings'
    entity_id UUID,
    old_value JSONB,
    new_value JSONB,
    reason TEXT,
    ip_address TEXT,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index pour recherche rapide
CREATE INDEX IF NOT EXISTS idx_admin_audit_action ON public.admin_audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_admin_audit_entity ON public.admin_audit_logs(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_admin_audit_admin ON public.admin_audit_logs(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_audit_created ON public.admin_audit_logs(created_at DESC);

-- ============================================
-- 3. PARAMÈTRES GLOBAUX PLATEFORME
-- ============================================

CREATE TABLE IF NOT EXISTS public.platform_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key TEXT UNIQUE NOT NULL,
    value JSONB NOT NULL,
    description TEXT,
    category TEXT DEFAULT 'general',
    is_sensitive BOOLEAN DEFAULT false,
    updated_by UUID REFERENCES auth.users(id),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insérer les paramètres par défaut
INSERT INTO public.platform_settings (key, value, description, category) VALUES
    ('admin_commission_percent', '5', 'Commission admin en %', 'finance'),
    ('min_delivery_fee', '100', 'Frais de livraison minimum (DA)', 'finance'),
    ('max_delivery_radius_km', '15', 'Rayon de livraison max (km)', 'delivery'),
    ('order_timeout_minutes', '30', 'Timeout commande sans livreur (min)', 'orders'),
    ('maintenance_mode', 'false', 'Mode maintenance activé', 'system'),
    ('new_registrations_enabled', 'true', 'Nouvelles inscriptions autorisées', 'system'),
    ('livreur_registrations_enabled', 'true', 'Inscriptions livreurs autorisées', 'system'),
    ('restaurant_registrations_enabled', 'true', 'Inscriptions restaurants autorisées', 'system'),
    ('min_order_amount', '200', 'Montant minimum commande (DA)', 'orders'),
    ('max_orders_per_hour', '5', 'Max commandes par client par heure', 'orders')
ON CONFLICT (key) DO NOTHING;

-- ============================================
-- 4. SYSTÈME D'INCIDENTS
-- ============================================

-- Type ENUM pour les statuts d'incident
DO $$ BEGIN
    CREATE TYPE incident_status AS ENUM ('open', 'in_progress', 'resolved', 'closed');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE incident_priority AS ENUM ('low', 'medium', 'high', 'critical');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS public.incidents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    incident_type TEXT NOT NULL,  -- 'order_issue', 'payment', 'livreur_complaint', 'restaurant_complaint', 'system'
    priority incident_priority DEFAULT 'medium',
    status incident_status DEFAULT 'open',
    
    -- Entités liées
    order_id UUID REFERENCES public.orders(id),
    customer_id UUID REFERENCES auth.users(id),
    restaurant_id UUID REFERENCES public.restaurants(id),
    livreur_id UUID REFERENCES public.livreurs(id),
    
    -- Assignation
    assigned_to UUID REFERENCES auth.users(id),
    
    -- Résolution
    resolution TEXT,
    resolved_at TIMESTAMPTZ,
    resolved_by UUID REFERENCES auth.users(id),
    
    -- Métadonnées
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index
CREATE INDEX IF NOT EXISTS idx_incidents_status ON public.incidents(status);
CREATE INDEX IF NOT EXISTS idx_incidents_priority ON public.incidents(priority);
CREATE INDEX IF NOT EXISTS idx_incidents_type ON public.incidents(incident_type);
CREATE INDEX IF NOT EXISTS idx_incidents_order ON public.incidents(order_id);
CREATE INDEX IF NOT EXISTS idx_incidents_created ON public.incidents(created_at DESC);

-- ============================================
-- 5. SUSPENSIONS UTILISATEURS
-- ============================================

CREATE TABLE IF NOT EXISTS public.user_suspensions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    user_type TEXT NOT NULL,  -- 'customer', 'restaurant', 'livreur'
    reason TEXT NOT NULL,
    suspended_by UUID REFERENCES auth.users(id),
    suspended_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ,  -- NULL = permanent
    is_active BOOLEAN DEFAULT true,
    lifted_by UUID REFERENCES auth.users(id),
    lifted_at TIMESTAMPTZ,
    lift_reason TEXT
);

-- Index
CREATE INDEX IF NOT EXISTS idx_suspensions_user ON public.user_suspensions(user_id);
CREATE INDEX IF NOT EXISTS idx_suspensions_active ON public.user_suspensions(is_active);
CREATE INDEX IF NOT EXISTS idx_suspensions_expires ON public.user_suspensions(expires_at);

-- ============================================
-- 6. STATISTIQUES TEMPS RÉEL (VUE)
-- ============================================

CREATE OR REPLACE VIEW public.realtime_dashboard_stats AS
SELECT
    -- Commandes
    (SELECT COUNT(*) FROM orders WHERE status = 'pending') as pending_orders,
    (SELECT COUNT(*) FROM orders WHERE status IN ('confirmed', 'preparing')) as preparing_orders,
    (SELECT COUNT(*) FROM orders WHERE status = 'ready') as ready_orders,
    (SELECT COUNT(*) FROM orders WHERE status IN ('picked_up', 'delivering')) as delivering_orders,
    (SELECT COUNT(*) FROM orders WHERE DATE(created_at) = CURRENT_DATE) as today_orders,
    (SELECT COALESCE(SUM(total), 0) FROM orders WHERE DATE(created_at) = CURRENT_DATE AND status = 'delivered') as today_revenue,
    
    -- Restaurants
    (SELECT COUNT(*) FROM restaurants WHERE is_verified = true AND is_open = true) as online_restaurants,
    (SELECT COUNT(*) FROM restaurants WHERE is_verified = false) as pending_restaurants,
    
    -- Livreurs
    (SELECT COUNT(*) FROM livreurs WHERE is_verified = true AND is_online = true) as online_livreurs,
    (SELECT COUNT(*) FROM livreurs WHERE is_verified = false) as pending_livreurs,
    (SELECT COUNT(*) FROM livreurs WHERE is_verified = true AND is_online = true AND is_available = true) as available_livreurs,
    
    -- Incidents
    (SELECT COUNT(*) FROM incidents WHERE status = 'open') as open_incidents,
    (SELECT COUNT(*) FROM incidents WHERE status = 'open' AND priority = 'critical') as critical_incidents;

-- ============================================
-- 7. FONCTION POUR LOGGER LES ACTIONS ADMIN
-- ============================================

CREATE OR REPLACE FUNCTION log_admin_action(
    p_action TEXT,
    p_entity_type TEXT,
    p_entity_id UUID DEFAULT NULL,
    p_old_value JSONB DEFAULT NULL,
    p_new_value JSONB DEFAULT NULL,
    p_reason TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_admin_role TEXT;
    v_log_id UUID;
BEGIN
    -- Récupérer le rôle admin
    SELECT admin_role::TEXT INTO v_admin_role
    FROM public.admin_users
    WHERE user_id = auth.uid();

    INSERT INTO public.admin_audit_logs (
        admin_id, admin_role, action, entity_type, entity_id, 
        old_value, new_value, reason
    ) VALUES (
        auth.uid(), v_admin_role, p_action, p_entity_type, p_entity_id,
        p_old_value, p_new_value, p_reason
    ) RETURNING id INTO v_log_id;

    RETURN v_log_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 8. FONCTION STATS ADMIN AMÉLIORÉE
-- ============================================

CREATE OR REPLACE FUNCTION get_admin_dashboard_stats()
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        -- Commandes temps réel
        'pending_orders', (SELECT COUNT(*) FROM orders WHERE status = 'pending'),
        'preparing_orders', (SELECT COUNT(*) FROM orders WHERE status IN ('confirmed', 'preparing')),
        'ready_orders', (SELECT COUNT(*) FROM orders WHERE status = 'ready'),
        'delivering_orders', (SELECT COUNT(*) FROM orders WHERE status IN ('picked_up', 'delivering')),
        'today_orders', (SELECT COUNT(*) FROM orders WHERE DATE(created_at) = CURRENT_DATE),
        'today_delivered', (SELECT COUNT(*) FROM orders WHERE DATE(created_at) = CURRENT_DATE AND status = 'delivered'),
        'today_revenue', (SELECT COALESCE(SUM(total), 0) FROM orders WHERE DATE(created_at) = CURRENT_DATE AND status = 'delivered'),
        'today_commission', (SELECT COALESCE(SUM(admin_commission), 0) FROM orders WHERE DATE(created_at) = CURRENT_DATE AND status = 'delivered'),
        
        -- Restaurants
        'total_restaurants', (SELECT COUNT(*) FROM restaurants),
        'verified_restaurants', (SELECT COUNT(*) FROM restaurants WHERE is_verified = true),
        'online_restaurants', (SELECT COUNT(*) FROM restaurants WHERE is_verified = true AND is_open = true),
        'pending_restaurants', (SELECT COUNT(*) FROM restaurants WHERE is_verified = false),
        
        -- Livreurs
        'total_livreurs', (SELECT COUNT(*) FROM livreurs),
        'verified_livreurs', (SELECT COUNT(*) FROM livreurs WHERE is_verified = true),
        'online_livreurs', (SELECT COUNT(*) FROM livreurs WHERE is_verified = true AND is_online = true),
        'available_livreurs', (SELECT COUNT(*) FROM livreurs WHERE is_verified = true AND is_online = true AND is_available = true),
        'pending_livreurs', (SELECT COUNT(*) FROM livreurs WHERE is_verified = false),
        
        -- Incidents
        'open_incidents', (SELECT COUNT(*) FROM incidents WHERE status = 'open'),
        'critical_incidents', (SELECT COUNT(*) FROM incidents WHERE status = 'open' AND priority = 'critical'),
        
        -- Ce mois
        'month_orders', (SELECT COUNT(*) FROM orders WHERE DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE) AND status = 'delivered'),
        'month_revenue', (SELECT COALESCE(SUM(total), 0) FROM orders WHERE DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE) AND status = 'delivered'),
        'month_commission', (SELECT COALESCE(SUM(admin_commission), 0) FROM orders WHERE DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE) AND status = 'delivered')
    ) INTO result;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 9. RLS POUR TABLES ADMIN
-- ============================================

ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.platform_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_suspensions ENABLE ROW LEVEL SECURITY;

-- Seuls les admins peuvent voir/modifier
CREATE POLICY "Admins can view admin_users" ON public.admin_users
FOR SELECT USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

CREATE POLICY "Super admins can manage admin_users" ON public.admin_users
FOR ALL USING (
    EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND admin_role = 'super_admin')
);

CREATE POLICY "Admins can view audit logs" ON public.admin_audit_logs
FOR SELECT USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

CREATE POLICY "Admins can insert audit logs" ON public.admin_audit_logs
FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

CREATE POLICY "Admins can view settings" ON public.platform_settings
FOR SELECT USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

CREATE POLICY "Super admins can modify settings" ON public.platform_settings
FOR UPDATE USING (
    EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND admin_role IN ('super_admin', 'ops_admin'))
);

CREATE POLICY "Admins can manage incidents" ON public.incidents
FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

CREATE POLICY "Admins can manage suspensions" ON public.user_suspensions
FOR ALL USING (
    EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND admin_role IN ('super_admin', 'ops_admin', 'support_admin'))
);

-- ============================================
-- 10. CRÉER L'ADMIN PAR DÉFAUT
-- ============================================

-- Insérer l'admin existant comme super_admin
INSERT INTO public.admin_users (user_id, admin_role, permissions)
SELECT id, 'super_admin', '{"all": true}'::jsonb
FROM auth.users
WHERE email = 'admin@test.com'
ON CONFLICT (user_id) DO NOTHING;

COMMENT ON TABLE public.admin_users IS 'Utilisateurs admin avec rôles granulaires';
COMMENT ON TABLE public.admin_audit_logs IS 'Logs d''audit de toutes les actions admin';
COMMENT ON TABLE public.platform_settings IS 'Paramètres globaux de la plateforme';
COMMENT ON TABLE public.incidents IS 'Gestion des incidents et tickets support';
COMMENT ON TABLE public.user_suspensions IS 'Historique des suspensions utilisateurs';
