-- ============================================
-- DEBUG: Vérifier le compte restaurant@test.com
-- ============================================

-- 1. Vérifier si l'utilisateur existe dans auth.users
SELECT 
    id,
    email,
    email_confirmed_at,
    created_at,
    last_sign_in_at
FROM auth.users
WHERE email = 'restaurant@test.com';

-- 2. Vérifier le profil
SELECT 
    id,
    role,
    full_name,
    phone,
    is_active
FROM profiles
WHERE id IN (SELECT id FROM auth.users WHERE email = 'restaurant@test.com');

-- 3. Vérifier le restaurant associé
SELECT 
    id,
    owner_id,
    name,
    is_verified,
    is_open,
    created_at
FROM restaurants
WHERE owner_id IN (SELECT id FROM auth.users WHERE email = 'restaurant@test.com');

-- ============================================
-- SOLUTION 1: Si l'utilisateur n'existe pas, le créer
-- ============================================

-- Créer l'utilisateur (à exécuter dans Supabase Dashboard > SQL Editor)
-- Note: Remplacer 'USER_ID_HERE' par un UUID généré

/*
-- Générer un UUID
SELECT gen_random_uuid();

-- Insérer dans auth.users (ADMIN ONLY - via Dashboard)
INSERT INTO auth.users (
    id,
    email,
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at,
    raw_app_meta_data,
    raw_user_meta_data,
    is_super_admin,
    role
) VALUES (
    'USER_ID_HERE', -- Remplacer par UUID généré
    'restaurant@test.com',
    crypt('test123456', gen_salt('bf')), -- Hash du mot de passe
    NOW(),
    NOW(),
    NOW(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Restaurant Test","phone":"0555000001","role":"restaurant"}',
    false,
    'authenticated'
);

-- Créer le profil
INSERT INTO profiles (id, role, full_name, phone, is_active)
VALUES (
    'USER_ID_HERE', -- Même UUID
    'restaurant',
    'Restaurant Test',
    '0555000001',
    true
);

-- Créer le restaurant
INSERT INTO restaurants (
    owner_id,
    name,
    address,
    phone,
    latitude,
    longitude,
    is_verified,
    is_open
) VALUES (
    'USER_ID_HERE', -- Même UUID
    'Restaurant Test',
    'Tigzirt Centre',
    '0555000001',
    36.8869,
    4.1260,
    true, -- ✅ VÉRIFIÉ pour pouvoir se connecter
    true  -- ✅ OUVERT
);
*/

-- ============================================
-- SOLUTION 2: Si l'utilisateur existe mais n'est pas vérifié
-- ============================================

-- Vérifier et activer le restaurant
UPDATE restaurants
SET 
    is_verified = true,
    is_open = true
WHERE owner_id IN (SELECT id FROM auth.users WHERE email = 'restaurant@test.com');

-- Activer le profil
UPDATE profiles
SET is_active = true
WHERE id IN (SELECT id FROM auth.users WHERE email = 'restaurant@test.com');

-- ============================================
-- SOLUTION 3: Réinitialiser le mot de passe (si oublié)
-- ============================================

-- Via Supabase Dashboard > Authentication > Users
-- Cliquer sur l'utilisateur > Reset Password
-- Ou utiliser l'API de reset password

-- ============================================
-- VÉRIFICATION FINALE
-- ============================================

SELECT 
    u.email,
    p.role,
    p.full_name,
    p.is_active,
    r.name as restaurant_name,
    r.is_verified,
    r.is_open
FROM auth.users u
LEFT JOIN profiles p ON p.id = u.id
LEFT JOIN restaurants r ON r.owner_id = u.id
WHERE u.email = 'restaurant@test.com';
