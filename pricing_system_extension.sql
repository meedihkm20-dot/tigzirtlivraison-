-- ============================================================
-- EXTENSION SYSTÈME DE PRICING DYNAMIQUE
-- ============================================================
-- Date: 2025-01-17
-- Compatible avec: supabase/SOURCE_DE_VERITE.sql
-- 
-- ⚠️ EXTENSION UNIQUEMENT - Pas de modification du schéma existant
-- ============================================================

-- ============================================
-- NOUVEAUX TYPES ENUM
-- ============================================
DO $$ BEGIN
    CREATE TYPE weather_condition AS ENUM ('clear', 'cloudy', 'light_rain', 'heavy_rain', 'storm', 'fog', 'wind', 'extreme');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE pricing_rule_type AS ENUM ('base', 'distance', 'time', 'weather', 'demand', 'zone');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ============================================
-- TABLE: pricing_config
-- Configuration globale du système de pricing
-- ============================================
CREATE TABLE IF NOT EXISTS public.pricing_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL UNIQUE,
    value DECIMAL(10, 4) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- TABLE: delivery_zones
-- Zones géographiques avec multiplicateurs
-- ============================================
CREATE TABLE IF NOT EXISTS public.delivery_zones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    multiplier DECIMAL(3, 2) DEFAULT 1.00,
    polygon GEOMETRY(POLYGON, 4326), -- Zone géographique
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- TABLE: pricing_rules
-- Règles de calcul dynamique
-- ============================================
CREATE TABLE IF NOT EXISTS public.pricing_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_type pricing_rule_type NOT NULL,
    name VARCHAR(100) NOT NULL,
    condition_key VARCHAR(50), -- Ex: 'hour', 'weather', 'distance_km'
    condition_operator VARCHAR(10), -- Ex: '>=', '<=', '=', 'between'
    condition_value JSONB, -- Valeurs flexibles
    multiplier DECIMAL(3, 2) DEFAULT 1.00,
    bonus_amount DECIMAL(10, 2) DEFAULT 0,
    priority INTEGER DEFAULT 0, -- Ordre d'application
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- TABLE: pricing_calculations
-- Historique des calculs de prix
-- ============================================
CREATE TABLE IF NOT EXISTS public.pricing_calculations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
    livreur_id UUID REFERENCES public.livreurs(id),
    
    -- Prix calculé
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
    
    -- Détail du calcul (JSON)
    calculation_breakdown JSONB,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- TABLE: weather_data
-- Données météorologiques temps réel
-- ============================================
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
    
    -- Données brutes API météo
    raw_data JSONB,
    
    recorded_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '1 hour'
);

-- ============================================
-- TABLE: demand_analytics
-- Analytics de la demande temps réel
-- ============================================
CREATE TABLE IF NOT EXISTS public.demand_analytics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    zone_id UUID REFERENCES public.delivery_zones(id),
    
    -- Métriques demande
    pending_orders INTEGER DEFAULT 0,
    available_drivers INTEGER DEFAULT 0,
    demand_ratio DECIMAL(5, 2), -- orders/drivers
    
    -- Période
    hour_of_day INTEGER CHECK (hour_of_day >= 0 AND hour_of_day <= 23),
    day_of_week INTEGER CHECK (day_of_week >= 1 AND day_of_week <= 7),
    
    recorded_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- DONNÉES INITIALES
-- ============================================

-- Configuration de base
INSERT INTO public.pricing_config (name, value, description) VALUES
('base_fee', 150.00, 'Frais de base par livraison (DA)'),
('price_per_km', 50.00, 'Prix par kilomètre (DA)'),
('min_price', 100.00, 'Prix minimum garanti (DA)'),
('max_price', 1500.00, 'Prix maximum autorisé (DA)'),
('night_start_hour', 20, 'Heure début majoration nocturne'),
('night_end_hour', 6, 'Heure fin majoration nocturne'),
('demand_threshold_high', 2.0, 'Seuil forte demande (ratio commandes/livreurs)'),
('demand_threshold_very_high', 3.0, 'Seuil très forte demande')
ON CONFLICT (name) DO NOTHING;

-- Zones de livraison par défaut
INSERT INTO public.delivery_zones (name, description, multiplier) VALUES
('centre_ville', 'Centre-ville de Tigzirt', 1.00),
('cite_universitaire', 'Cité Universitaire', 1.10),
('nouvelle_ville', 'Nouvelle Ville', 1.20),
('peripherie', 'Périphérie urbaine', 1.40),
('villages', 'Villages environnants', 1.60),
('montagne', 'Zones montagneuses', 1.80)
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
-- INDEX POUR PERFORMANCE
-- ============================================
CREATE INDEX IF NOT EXISTS idx_pricing_calculations_order_id ON public.pricing_calculations(order_id);
CREATE INDEX IF NOT EXISTS idx_pricing_calculations_livreur_id ON public.pricing_calculations(livreur_id);
CREATE INDEX IF NOT EXISTS idx_pricing_calculations_time ON public.pricing_calculations(calculation_time);
CREATE INDEX IF NOT EXISTS idx_weather_data_location ON public.weather_data(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_weather_data_time ON public.weather_data(recorded_at);
CREATE INDEX IF NOT EXISTS idx_demand_analytics_zone ON public.demand_analytics(zone_id);
CREATE INDEX IF NOT EXISTS idx_demand_analytics_time ON public.demand_analytics(recorded_at);

-- ============================================
-- RLS POLICIES (Sécurité)
-- ============================================

-- pricing_config: Lecture pour tous, écriture admin seulement
ALTER TABLE public.pricing_config ENABLE ROW LEVEL SECURITY;
CREATE POLICY "pricing_config_read" ON public.pricing_config FOR SELECT USING (true);
CREATE POLICY "pricing_config_admin_write" ON public.pricing_config FOR ALL 
    USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));

-- delivery_zones: Lecture pour tous, écriture admin seulement  
ALTER TABLE public.delivery_zones ENABLE ROW LEVEL SECURITY;
CREATE POLICY "delivery_zones_read" ON public.delivery_zones FOR SELECT USING (true);
CREATE POLICY "delivery_zones_admin_write" ON public.delivery_zones FOR ALL
    USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));

-- pricing_rules: Lecture pour tous, écriture admin seulement
ALTER TABLE public.pricing_rules ENABLE ROW LEVEL SECURITY;
CREATE POLICY "pricing_rules_read" ON public.pricing_rules FOR SELECT USING (true);
CREATE POLICY "pricing_rules_admin_write" ON public.pricing_rules FOR ALL
    USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));

-- pricing_calculations: Lecture selon rôle
ALTER TABLE public.pricing_calculations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "pricing_calculations_livreur_read" ON public.pricing_calculations FOR SELECT
    USING (livreur_id IN (SELECT id FROM public.livreurs WHERE profile_id = auth.uid()));
CREATE POLICY "pricing_calculations_admin_read" ON public.pricing_calculations FOR SELECT
    USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));
CREATE POLICY "pricing_calculations_system_write" ON public.pricing_calculations FOR INSERT
    USING (true); -- Système peut insérer

-- weather_data: Lecture pour tous, écriture système seulement
ALTER TABLE public.weather_data ENABLE ROW LEVEL SECURITY;
CREATE POLICY "weather_data_read" ON public.weather_data FOR SELECT USING (true);

-- demand_analytics: Lecture pour tous, écriture système seulement
ALTER TABLE public.demand_analytics ENABLE ROW LEVEL SECURITY;
CREATE POLICY "demand_analytics_read" ON public.demand_analytics FOR SELECT USING (true);

-- ============================================
-- FONCTIONS UTILITAIRES
-- ============================================

-- Fonction pour nettoyer les anciennes données météo
CREATE OR REPLACE FUNCTION cleanup_old_weather_data()
RETURNS void AS $$
BEGIN
    DELETE FROM public.weather_data WHERE expires_at < NOW();
END;
$$ LANGUAGE plpgsql;

-- Fonction pour calculer la zone d'une coordonnée
CREATE OR REPLACE FUNCTION get_delivery_zone(lat DECIMAL, lng DECIMAL)
RETURNS UUID AS $$
DECLARE
    zone_id UUID;
BEGIN
    SELECT id INTO zone_id
    FROM public.delivery_zones
    WHERE is_active = true
    AND (polygon IS NULL OR ST_Contains(polygon, ST_Point(lng, lat)))
    ORDER BY multiplier ASC -- Zone la moins chère en cas de conflit
    LIMIT 1;
    
    -- Zone par défaut si aucune trouvée
    IF zone_id IS NULL THEN
        SELECT id INTO zone_id FROM public.delivery_zones WHERE name = 'centre_ville';
    END IF;
    
    RETURN zone_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TRIGGERS
-- ============================================

-- Trigger pour nettoyer automatiquement les données météo expirées
CREATE OR REPLACE FUNCTION trigger_cleanup_weather()
RETURNS trigger AS $$
BEGIN
    -- Nettoyer les données expirées à chaque insertion
    PERFORM cleanup_old_weather_data();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER weather_cleanup_trigger
    AFTER INSERT ON public.weather_data
    FOR EACH ROW EXECUTE FUNCTION trigger_cleanup_weather();

-- ============================================
-- COMMENTAIRES
-- ============================================
COMMENT ON TABLE public.pricing_config IS 'Configuration globale du système de pricing dynamique';
COMMENT ON TABLE public.delivery_zones IS 'Zones géographiques avec multiplicateurs de prix';
COMMENT ON TABLE public.pricing_rules IS 'Règles de calcul automatique des prix';
COMMENT ON TABLE public.pricing_calculations IS 'Historique des calculs de prix pour analytics';
COMMENT ON TABLE public.weather_data IS 'Données météorologiques temps réel';
COMMENT ON TABLE public.demand_analytics IS 'Analytics de la demande par zone et période';