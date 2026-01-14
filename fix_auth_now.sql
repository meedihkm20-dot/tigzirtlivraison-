-- ============================================
-- FIX IMMÉDIAT: Vérifier et corriger l'auth
-- ============================================

-- 1. Voir TOUS les utilisateurs et leurs profils
SELECT 
    '=== UTILISATEURS ===' as section,
    u.email,
    u.id,
    u.encrypted_password IS NOT NULL as has_password,
    u.email_confirmed_at IS NOT NULL as email_confirmed,
    u.confirmed_at IS NOT NULL as confirmed,
    p.role,
    p.full_name,
    CASE 
        WHEN p.id IS NULL THEN '❌ PAS DE PROFIL'
        WHEN p.role IS NULL THEN '❌ ROLE NULL'
        ELSE '✅ OK'
    END as status
FROM auth.users u
LEFT JOIN public.profiles p ON p.id = u.id
WHERE u.email LIKE '%test.com'
ORDER BY u.email;

-- 2. Vérifier les politiques RLS sur profiles
SELECT 
    '=== POLITIQUES RLS PROFILES ===' as section,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'profiles';

-- 3. Tester si on peut lire les profils
SELECT 
    '=== TEST LECTURE PROFILS ===' as section,
    id,
    role,
    full_name
FROM public.profiles
WHERE id IN (
    SELECT id FROM auth.users WHERE email LIKE '%test.com'
);

-- 4. Vérifier le trigger handle_new_user
SELECT 
    '=== TRIGGER HANDLE_NEW_USER ===' as section,
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created';

-- 5. FORCER la création des profils manquants
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

-- 6. Vérifier après correction
SELECT 
    '=== APRÈS CORRECTION ===' as section,
    u.email,
    p.role,
    p.full_name,
    CASE 
        WHEN p.id IS NULL THEN '❌ TOUJOURS PAS DE PROFIL'
        WHEN p.role IS NULL THEN '❌ TOUJOURS PAS DE ROLE'
        ELSE '✅ CORRIGÉ'
    END as status
FROM auth.users u
LEFT JOIN public.profiles p ON p.id = u.id
WHERE u.email LIKE '%test.com'
ORDER BY u.email;

-- 7. Désactiver temporairement RLS pour tester
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;

-- 8. Message final
SELECT '✅ Exécute ce script dans Supabase SQL Editor, puis teste la connexion' as message;
