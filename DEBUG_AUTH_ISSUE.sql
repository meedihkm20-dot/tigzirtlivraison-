-- ============================================
-- DEBUG: Pourquoi l'app tourne en boucle?
-- ============================================
-- Exécuter ce script dans Supabase SQL Editor

-- 1. Voir TOUS les utilisateurs
SELECT 
    'UTILISATEURS' as section,
    u.email,
    u.id,
    u.encrypted_password IS NOT NULL as has_password,
    u.email_confirmed_at IS NOT NULL as email_confirmed,
    u.last_sign_in_at,
    p.role,
    p.full_name,
    CASE 
        WHEN p.id IS NULL THEN '❌ PAS DE PROFIL'
        WHEN p.role IS NULL THEN '❌ ROLE NULL'
        ELSE '✅ OK'
    END as status
FROM auth.users u
LEFT JOIN public.profiles p ON p.id = u.id
ORDER BY u.created_at DESC;

-- 2. Vérifier les restaurants
SELECT 
    'RESTAURANTS' as section,
    u.email,
    r.name as restaurant_name,
    r.is_verified,
    CASE 
        WHEN r.id IS NULL THEN '❌ PAS DE RESTAURANT'
        WHEN NOT r.is_verified THEN '⚠️ NON VÉRIFIÉ'
        ELSE '✅ VÉRIFIÉ'
    END as status
FROM auth.users u
LEFT JOIN public.profiles p ON p.id = u.id
LEFT JOIN public.restaurants r ON r.owner_id = u.id
WHERE p.role = 'restaurant' OR u.email LIKE '%restaurant%';

-- 3. Vérifier les livreurs
SELECT 
    'LIVREURS' as section,
    u.email,
    l.vehicle_type,
    l.is_verified,
    CASE 
        WHEN l.id IS NULL THEN '❌ PAS DE LIVREUR'
        WHEN NOT l.is_verified THEN '⚠️ NON VÉRIFIÉ'
        ELSE '✅ VÉRIFIÉ'
    END as status
FROM auth.users u
LEFT JOIN public.profiles p ON p.id = u.id
LEFT JOIN public.livreurs l ON l.user_id = u.id
WHERE p.role = 'livreur' OR u.email LIKE '%livreur%';

-- 4. Compter les problèmes
SELECT 
    'RÉSUMÉ DES PROBLÈMES' as section,
    COUNT(*) FILTER (WHERE p.id IS NULL) as users_sans_profil,
    COUNT(*) FILTER (WHERE p.role IS NULL) as users_sans_role,
    COUNT(*) FILTER (WHERE p.role = 'restaurant' AND r.id IS NULL) as restaurants_manquants,
    COUNT(*) FILTER (WHERE p.role = 'livreur' AND l.id IS NULL) as livreurs_manquants
FROM auth.users u
LEFT JOIN public.profiles p ON p.id = u.id
LEFT JOIN public.restaurants r ON r.owner_id = u.id AND p.role = 'restaurant'
LEFT JOIN public.livreurs l ON l.user_id = u.id AND p.role = 'livreur';
