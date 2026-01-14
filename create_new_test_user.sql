-- ============================================
-- CRÉER UN NOUVEAU COMPTE TEST QUI MARCHE
-- ============================================

-- 1. Créer l'utilisateur dans auth.users
-- Note: Remplace 'MON_MOT_DE_PASSE' par ton mot de passe
-- Le hash ci-dessous est pour 'test12345'

INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at
) VALUES (
    '00000000-0000-0000-0000-000000000000',
    gen_random_uuid(),
    'authenticated',
    'authenticated',
    'test@dzdelivery.com',
    crypt('test12345', gen_salt('bf')),
    NOW(),
    NOW(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Test User","phone":"+213 555 999 999","role":"customer"}',
    NOW(),
    NOW()
)
RETURNING id, email;

-- 2. Créer le profil automatiquement
-- (Le trigger devrait le faire, mais on force au cas où)
INSERT INTO public.profiles (id, role, full_name, phone, phone_verified)
SELECT 
    id,
    'customer'::user_role,
    'Test User',
    '+213 555 999 999',
    true
FROM auth.users
WHERE email = 'test@dzdelivery.com'
ON CONFLICT (id) DO NOTHING;

-- 3. Vérifier
SELECT 
    u.email,
    u.email_confirmed_at IS NOT NULL as email_confirmed,
    p.role,
    p.full_name,
    '✅ Compte créé! Utilise: test@dzdelivery.com / test12345' as message
FROM auth.users u
JOIN public.profiles p ON p.id = u.id
WHERE u.email = 'test@dzdelivery.com';
