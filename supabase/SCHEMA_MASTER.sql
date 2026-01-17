-- ============================================================
-- SCHÉMA MASTER - SOURCE DE VÉRITÉ UNIQUE
-- ============================================================
-- Ce schéma est la référence ABSOLUE pour:
-- - Backend NestJS
-- - Flutter App
-- - Supabase Database
-- 
-- RÈGLE: Toute modification doit être faite ICI d'abord
-- ============================================================

-- ============================================
-- EXTENSIONS
-- ============================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis" SCHEMA public;

-- ============================================
-- TYPES ENUM
-- ============================================
DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('customer', 'restaurant', 'livreur', 'admin');
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE order_status AS ENUM ('pending', 'confirmed', 'preparing', 'ready', 'picked_up', 'delivering', 'delivered', 'cancelled');
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE payment_method AS ENUM ('cash', 'card', 'edahabia', 'cib');
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE payment_status AS ENUM ('pending', 'paid', 'failed', 'refunded');
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE vehicle_type AS ENUM ('moto', 'velo', 'voiture');
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE livreur_tier AS ENUM ('bronze', 'silver', 'gold', 'diamond');
EXCEPTION WHEN duplicate_object THEN null;
END $$;

-- ============================================
-- TABLE: profiles
-- Utilisée par: Backend + Flutter
-- ============================================
CREATE TABLE IF NOT EXISTS public.profiles (
    -- Colonnes communes (Backend + Flutter)
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    role user_role NOT NULL DEFAULT 'customer',
    full_name VARCHAR(100),
    phone VARCHAR(20),
    avatar_url TEXT,
    address TEXT,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    
    -- Colonnes Backend
    is_active BOOLEAN DEFAULT true,
    is_available BOOLEAN DEFAULT false,
    
    -- Colonnes Flutter
    onesignal_player_id TEXT,
    loyalty_points INTEGER DEFAULT 0,
    total_orders INTEGER DEFAULT 0,
    total_spent DECIMAL(12,2) DEFAULT 0,
    referral_code VARCHAR(10),
    referred_by UUID REFERENCES public.profiles(id),
    referral_earnings DECIMAL(10,2) DEFAULT 0,
    
    -- Timestamps
    created_at 