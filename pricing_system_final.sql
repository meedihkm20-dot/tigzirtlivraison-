-- ============================================================
-- SYSTÈME DE PRICING DYNAMIQUE - DZ DELIVERY
-- ============================================================
-- 📋 INSTRUCTIONS D'EXÉCUTION:
-- 1. Ouvrir Supabase Dashboard > SQL Editor
-- 2. Copier-coller ce script complet
-- 3. Cliquer sur "Run" pour exécuter
-- 4. Vérifier que toutes les tables sont créées
-- ============================================================

-- ============================================
-- ÉTAPE 1: CRÉER LES TYPES ENUM
-- ============================================
DO $$ 
BEGIN
    -- Type pour les conditions météo
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'weather_condition') THEN
        CREATE TYPE weather_condition AS ENUM (
            'clear', 'cloudy', 'light_rain', 'heavy_rain', 'storm', 'fog', 'wind', 'extreme'
        );
    END IF;
    
    -- Type pour les règles de pricing
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'pricing_rule_type') THEN
        CREATE TYPE pricing_rule_type AS ENUM (
            'base', 'distance', 'time', 'weather', 'demand', 'zone'
        );
    END IF;
END $$;

-- ============================================
-- ÉTAPE 2: CRÉER LES TABLES
-- ============================================

-- Table 1: Configuration du pricing
CREATE TABLE IF NOT EXISTS public.pricing_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL UNIQUE,
    value DECIMAL(10, 4) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table 2: Règles de calcul dynamique
CREATE TABLE IF NOT EXISTS public.pricing_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_type pricing_rule_type NOT NULL,
    name VARCHAR(100) NOT NULL,
    condition_key VARCHAR(50),
    condition_operator VARCHAR(10),
    condition_value JSONB,
    multiplier DECIMAL(3, 2) DEFAULT 1.00,
    bonus_amount DECIMAL(10, 2) DEFAULT 0,
    priority INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table 3: Historique des calculs
CREATE TABLE IF NOT EXISTS public.pricing_calculations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID,
    livreur_id UUID,
    
    -- Prix calculés
    base_price DECIMAL(10, 2) NOT NULL,
    final_price DECIMAL(10, 2) NOT NULL,
    
    -- Facteurs appliqués
    distance_km DECIMAL(8, 3),
    zone_multiplier DECIMAL(3, 2) DEFAULT 1.00,
    time_multiplier DECIMAL(3, 2) DEFAULT 1.00,
    weather_multiplier DECIMAL(3, 2) DEFAULT 1.00,
    demand_multiplier DECIMAL(3, 2) DEFAULT 1.00,
    
    -- Bonus
    night_bonus DECIMAL(10, 2) DEFAULT 0,
    weather_bonus DECIMAL(10, 2) DEFAULT 0,
    equipment_bonus DECIMAL(10, 2) DEFAULT 0,
    
    -- Contexte
    weather_condition weather_condition,
    available_drivers INTEGER,
    pending_orders INTEGER,
    calculation_time TIMESTAMPTZ DEFAULT NOW(),
    calculation_breakdown JSONB,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table 4: Données météo temps réel
CREATE TABLE IF NOT EXISTS public.weather_data (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    location_name VARCHAR(100) NOT NULL,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    condition weather_condition NOT NULL,
    temperature DECIMAL(4, 1),
    humidity INTEGER,
    wind_speed DECIMAL(5, 2),
    visibility DECIMAL(5, 2),
    raw_data JSONB,
    recorded_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '1 hour'
);

-- Table 5: Analytics de la demande
CREATE TABLE IF NOT EXISTS public.demand_analytics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    zone_name VARCHAR(100),
    pending_orders INTEGER DEFAULT 0,
    available_drivers INTEGER DEFAULT 0,
    demand_ratio DECIMAL(5, 2),
    hour_of_day INTEGER CHECK (hour_of_day >= 0 AND hour_of_day <= 23),
    day_of_week INTEGER CHECK (day_of_week >= 1 AND day_of_week <= 7),
    recorded_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- ÉTAPE 3: INSÉRER LES DONNÉES INITIALES
-- ============================================

-- Configuration de base
INSERT INTO public.pricing_config (name, value, description) VALUES
('base_fee', 150.00, 'Frais de base par livraison (DA)'),
('price_per_km', 50.00, 'Prix par kilomètre (DA)'),
('min_price', 100.00, 'Prix minimum garanti (DA)'),
('max_price', 1500.00, 'Prix maximum autorisé (DA)'),
('night_start_hour', 20, 'Heure début majoration nocturne'),
('night_end_hour', 6, 'Heure fin majoration nocturne'),
('demand_threshold_high', 2.0, 'Seuil forte demande'),
('demand_threshold_very_high', 3.0, 'Seuil très forte demande')
ON CONFLICT (name) DO NOTHING;

-- Règles de pricing par défaut
INSERT INTO public.pricing_rules (rule_type, name, condition_key, condition_operator, condition_value, multiplier, priority) VALUES
-- Règles nocturnes
('time', 'Soirée (20h-22h)', 'hour', 'between', '[20, 21]', 1.20, 10),
('time', 'Nuit tardive (22h-00h)', 'hour', 'between', '[22, 23]', 1.50, 10),
('time', 'Nuit profonde (00h-03h)', 'hour', 'between', '[0, 2]', 1.80, 10),
('time', 'Petit matin (03h-06h)', 'hour', 'between', '[3, 5]', 1.40, 10),

-- Règles météo
('weather', 'Pluie légère', 'weather', '=', '"light_rain"', 1.30, 20),
('weather', 'Pluie forte', 'weather', '=', '"heavy_rain"', 1.60, 20),
('weather', 'Orage', 'weather', '=', '"storm"', 2.00, 20),
('weather', 'Brouillard', 'weather', '=', '"fog"', 1.40, 20),
('weather', 'Vent fort', 'weather', '=', '"wind"', 1.20, 20),

-- Règles demande
('demand', 'Forte demande', 'demand_ratio', '>=', '2.0', 1.50, 30),
('demand', 'Très forte demande', 'demand_ratio', '>=', '3.0', 1.80, 30)
ON CONFLICT DO NOTHING;

-- ============================================
-- ÉTAPE 4: CRÉER LES INDEX POUR PERFORMANCE
-- ============================================
CREATE INDEX IF NOT EXISTS idx_pricing_calculations_order_id ON public.pricing_calculations(order_id);
CREATE INDEX IF NOT EXISTS idx_pricing_calculations_livreur_id ON public.pricing_calculations(livreur_id);
CREATE INDEX IF NOT EXISTS idx_pricing_calculations_time ON public.pricing_calculations(calculation_time);
CREATE INDEX IF NOT EXISTS idx_weather_data_location ON public.weather_data(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_weather_data_time ON public.weather_data(recorded_at);
CREATE INDEX IF NOT EXISTS idx_demand_analytics_time ON public.demand_analytics(recorded_at);

-- ============================================
-- ÉTAPE 5: CONFIGURER LA SÉCURITÉ RLS
-- ============================================

-- Table pricing_config
ALTER TABLE public.pricing_config ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pricing_config_select" ON public.pricing_config;
CREATE POLICY "pricing_config_select" ON public.pricing_config FOR SELECT USING (true);

-- Table pricing_rules
ALTER TABLE public.pricing_rules ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pricing_rules_select" ON public.pricing_rules;
CREATE POLICY "pricing_rules_select" ON public.pricing_rules FOR SELECT USING (true);

-- Table pricing_calculations
ALTER TABLE public.pricing_calculations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pricing_calculations_select" ON public.pricing_calculations;
DROP POLICY IF EXISTS "pricing_calculations_insert" ON public.pricing_calculations;
CREATE POLICY "pricing_calculations_select" ON public.pricing_calculations FOR SELECT USING (true);
CREATE POLICY "pricing_calculations_insert" ON public.pricing_calculations FOR INSERT WITH CHECK (true);

-- Table weather_data
ALTER TABLE public.weather_data ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "weather_data_select" ON public.weather_data;
CREATE POLICY "weather_data_select" ON public.weather_data FOR SELECT USING (true);

-- Table demand_analytics
ALTER TABLE public.demand_analytics ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "demand_analytics_select" ON public.demand_analytics;
CREATE POLICY "demand_analytics_select" ON public.demand_analytics FOR SELECT USING (true);

-- ============================================
-- ÉTAPE 6: FONCTIONS UTILITAIRES
-- ============================================

-- Fonction pour nettoyer les anciennes données météo
CREATE OR REPLACE FUNCTION cleanup_old_weather_data()
RETURNS void AS $$
BEGIN
    DELETE FROM public.weather_data WHERE expires_at < NOW();
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- ÉTAPE 7: TRIGGERS
-- ============================================

-- Trigger pour nettoyer automatiquement les données météo expirées
CREATE OR REPLACE FUNCTION trigger_cleanup_weather()
RETURNS trigger AS $$
BEGIN
    PERFORM cleanup_old_weather_data();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS weather_cleanup_trigger ON public.weather_data;
CREATE TRIGGER weather_cleanup_trigger
    AFTER INSERT ON public.weather_data
    FOR EACH ROW EXECUTE FUNCTION trigger_cleanup_weather();

-- ============================================
-- ÉTAPE 8: COMMENTAIRES ET DOCUMENTATION
-- ============================================
COMMENT ON TABLE public.pricing_config IS 'Configuration globale du système de pricing dynamique';
COMMENT ON TABLE public.pricing_rules IS 'Règles de calcul automatique des prix selon conditions';
COMMENT ON TABLE public.pricing_calculations IS 'Historique des calculs de prix pour analytics';
COMMENT ON TABLE public.weather_data IS 'Données météorologiques temps réel pour ajustements prix';
COMMENT ON TABLE public.demand_analytics IS 'Analytics de la demande par zone et période';

-- ============================================
-- ✅ SCRIPT TERMINÉ AVEC SUCCÈS
-- ============================================
-- Les tables suivantes ont été créées:
-- - pricing_config (8 entrées de configuration)
-- - pricing_rules (12 règles par défaut)
-- - pricing_calculations (historique)
-- - weather_data (données météo)
-- - demand_analytics (analytics demande)
--
-- 🚀 Le système de pricing dynamique est maintenant prêt !
-- ============================================