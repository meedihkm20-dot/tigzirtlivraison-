-- ============================================
-- CORRECTION FORCÉE DES COMPTES TEST
-- ============================================

-- Mettre à jour ou créer les profils (sans supprimer pour éviter les contraintes FK)
INSERT INTO public.profiles (id, role, full_name, phone, phone_verified)
SELECT 
    u.id,
    CASE 
        WHEN u.email = 'admin@test.com' THEN 'admin'::user_role
        WHEN u.email = 'client@test.com' THEN 'customer'::user_role
        WHEN u.email = 'restaurant@test.com' THEN 'restaurant'::user_role
        WHEN u.email = 'livreur@test.com' THEN 'livreur'::user_role
    END,
    CASE 
        WHEN u.email = 'admin@test.com' THEN 'Admin Test'
        WHEN u.email = 'client@test.com' THEN 'Client Test'
        WHEN u.email = 'restaurant@test.com' THEN 'Restaurant Test'
        WHEN u.email = 'livreur@test.com' THEN 'Livreur Test'
    END,
    '+213 555 000 000',
    true
FROM auth.users u
WHERE u.email IN ('admin@test.com', 'client@test.com', 'restaurant@test.com', 'livreur@test.com')
ON CONFLICT (id) DO UPDATE SET
    role = EXCLUDED.role,
    full_name = EXCLUDED.full_name,
    phone = EXCLUDED.phone,
    phone_verified = EXCLUDED.phone_verified;

-- S'assurer que le restaurant existe
DO $$
DECLARE
    v_owner_id UUID;
BEGIN
    SELECT id INTO v_owner_id FROM auth.users WHERE email = 'restaurant@test.com';
    
    IF v_owner_id IS NOT NULL THEN
        -- Vérifier si le restaurant existe déjà
        IF NOT EXISTS (SELECT 1 FROM public.restaurants WHERE owner_id = v_owner_id) THEN
            -- Créer le restaurant
            INSERT INTO public.restaurants (
                owner_id, name, description, phone, address, 
                latitude, longitude, cuisine_type, opening_time, closing_time,
                min_order_amount, delivery_fee, avg_prep_time, is_open, is_verified
            ) VALUES (
                v_owner_id,
                'Restaurant Test',
                'Restaurant de test pour développement',
                '+213 555 100 100',
                'Centre Ville, Tigzirt',
                36.8869,
                4.1260,
                'Algérienne',
                '10:00'::time,
                '23:00'::time,
                500,
                150,
                25,
                true,
                true
            );
        ELSE
            -- Mettre à jour le restaurant existant
            UPDATE public.restaurants 
            SET is_verified = true, is_open = true
            WHERE owner_id = v_owner_id;
        END IF;
    END IF;
END $$;

-- S'assurer que le livreur existe
DO $$
DECLARE
    v_user_id UUID;
BEGIN
    SELECT id INTO v_user_id FROM auth.users WHERE email = 'livreur@test.com';
    
    IF v_user_id IS NOT NULL THEN
        -- Vérifier si le livreur existe déjà
        IF NOT EXISTS (SELECT 1 FROM public.livreurs WHERE user_id = v_user_id) THEN
            -- Créer le livreur
            INSERT INTO public.livreurs (
                user_id, vehicle_type, vehicle_registration, license_number,
                latitude, longitude, is_available, is_online, is_verified,
                tier, rating, total_deliveries, total_earnings
            ) VALUES (
                v_user_id,
                'moto',
                'ABC-123-16',
                'LIC-TEST-001',
                36.8869,
                4.1260,
                true,
                false,
                true,
                'bronze',
                5.0,
                0,
                0
            );
        ELSE
            -- Mettre à jour le livreur existant
            UPDATE public.livreurs 
            SET is_verified = true, is_available = true
            WHERE user_id = v_user_id;
        END IF;
    END IF;
END $$;

-- Vérification finale
SELECT 
    u.email,
    p.role,
    p.full_name,
    CASE 
        WHEN p.role = 'restaurant' THEN EXISTS(SELECT 1 FROM restaurants WHERE owner_id = u.id)
        WHEN p.role = 'livreur' THEN EXISTS(SELECT 1 FROM livreurs WHERE user_id = u.id)
        ELSE true
    END as entity_exists
FROM auth.users u
JOIN public.profiles p ON p.id = u.id
WHERE u.email IN ('admin@test.com', 'client@test.com', 'restaurant@test.com', 'livreur@test.com')
ORDER BY u.email;
