-- ============================================
-- VÉRIFICATION DES LOGS D'AUTHENTIFICATION
-- ============================================

-- 1. TOUS LES UTILISATEURS AVEC LEURS RÔLES
SELECT 
    '📊 UTILISATEURS ET RÔLES' as section,
    '' as separator;

SELECT 
    u.id,
    u.email,
    p.role,
    p.full_name,
    u.email_confirmed_at,
    u.last_sign_in_at,
    u.created_at,
    CASE 
        WHEN u.email_confirmed_at IS NULL THEN '❌ Email non confirmé'
        WHEN u.last_sign_in_at IS NULL THEN '⚠️ Jamais connecté'
        ELSE '✅ Actif'
    END as status
FROM auth.users u
LEFT JOIN public.profiles p ON p.id = u.id
ORDER BY u.created_at DESC;

-- 2. COMPTAGE PAR RÔLE
SELECT 
    '📈 COMPTAGE PAR RÔLE' as section,
    '' as separator;

SELECT 
    COALESCE(p.role::text, 'sans_role') as role,
    COUNT(*) as nombre,
    COUNT(CASE WHEN u.last_sign_in_at IS NOT NULL THEN 1 END) as connectes,
    COUNT(CASE WHEN u.email_confirmed_at IS NULL THEN 1 END) as non_confirmes
FROM auth.users u
LEFT JOIN public.profiles p ON p.id = u.id
GROUP BY p.role
ORDER BY nombre DESC;

-- 3. DERNIÈRES CONNEXIONS
SELECT 
    '🔐 DERNIÈRES CONNEXIONS' as section,
    '' as separator;

SELECT 
    u.email,
    p.role,
    u.last_sign_in_at,
    u.email_confirmed_at,
    EXTRACT(EPOCH FROM (NOW() - u.last_sign_in_at))/3600 as heures_depuis_derniere_connexion
FROM auth.users u
LEFT JOIN public.profiles p ON p.id = u.id
WHERE u.last_sign_in_at IS NOT NULL
ORDER BY u.last_sign_in_at DESC
LIMIT 20;

-- 4. UTILISATEURS JAMAIS CONNECTÉS
SELECT 
    '⚠️ UTILISATEURS JAMAIS CONNECTÉS' as section,
    '' as separator;

SELECT 
    u.email,
    p.role,
    u.created_at,
    EXTRACT(EPOCH FROM (NOW() - u.created_at))/86400 as jours_depuis_creation
FROM auth.users u
LEFT JOIN public.profiles p ON p.id = u.id
WHERE u.last_sign_in_at IS NULL
ORDER BY u.created_at DESC;

-- 5. COMPTES TEST SPÉCIFIQUES
SELECT 
    '🧪 COMPTES TEST' as section,
    '' as separator;

SELECT 
    u.email,
    p.role,
    p.full_name,
    u.email_confirmed_at IS NOT NULL as email_confirme,
    u.last_sign_in_at as derniere_connexion,
    CASE 
        WHEN p.role = 'restaurant' THEN 
            EXISTS(SELECT 1 FROM public.restaurants WHERE owner_id = u.id)
        WHEN p.role = 'livreur' THEN 
            EXISTS(SELECT 1 FROM public.livreurs WHERE user_id = u.id)
        ELSE true
    END as entite_existe
FROM auth.users u
LEFT JOIN public.profiles p ON p.id = u.id
WHERE u.email IN ('admin@test.com', 'client@test.com', 'restaurant@test.com', 'livreur@test.com')
ORDER BY u.email;

-- 6. VÉRIFIER LES PROFILS MANQUANTS
SELECT 
    '❌ PROFILS MANQUANTS' as section,
    '' as separator;

SELECT 
    u.id,
    u.email,
    u.created_at,
    '⚠️ Profil manquant dans public.profiles' as probleme
FROM auth.users u
LEFT JOIN public.profiles p ON p.id = u.id
WHERE p.id IS NULL;

-- 7. VÉRIFIER LES INCOHÉRENCES DE RÔLES
SELECT 
    '⚠️ INCOHÉRENCES DE RÔLES' as section,
    '' as separator;

-- Restaurants sans restaurant
SELECT 
    u.email,
    p.role,
    '❌ Rôle restaurant mais pas de restaurant créé' as probleme
FROM auth.users u
JOIN public.profiles p ON p.id = u.id
LEFT JOIN public.restaurants r ON r.owner_id = u.id
WHERE p.role = 'restaurant' AND r.id IS NULL

UNION ALL

-- Livreurs sans livreur
SELECT 
    u.email,
    p.role,
    '❌ Rôle livreur mais pas de livreur créé' as probleme
FROM auth.users u
JOIN public.profiles p ON p.id = u.id
LEFT JOIN public.livreurs l ON l.user_id = u.id
WHERE p.role = 'livreur' AND l.id IS NULL;

-- 8. STATISTIQUES GLOBALES
SELECT 
    '📊 STATISTIQUES GLOBALES' as section,
    '' as separator;

SELECT 
    COUNT(*) as total_utilisateurs,
    COUNT(CASE WHEN email_confirmed_at IS NOT NULL THEN 1 END) as emails_confirmes,
    COUNT(CASE WHEN last_sign_in_at IS NOT NULL THEN 1 END) as deja_connectes,
    COUNT(CASE WHEN last_sign_in_at IS NULL THEN 1 END) as jamais_connectes,
    COUNT(CASE WHEN last_sign_in_at > NOW() - INTERVAL '24 hours' THEN 1 END) as connectes_24h,
    COUNT(CASE WHEN last_sign_in_at > NOW() - INTERVAL '7 days' THEN 1 END) as connectes_7j
FROM auth.users;

-- 9. RÉSUMÉ FINAL
SELECT 
    '✅ RÉSUMÉ FINAL' as section,
    '' as separator;

SELECT 
    'Total utilisateurs' as metrique,
    COUNT(*)::text as valeur
FROM auth.users

UNION ALL

SELECT 
    'Avec profil',
    COUNT(*)::text
FROM public.profiles

UNION ALL

SELECT 
    'Admins',
    COUNT(*)::text
FROM public.profiles WHERE role = 'admin'

UNION ALL

SELECT 
    'Clients',
    COUNT(*)::text
FROM public.profiles WHERE role = 'customer'

UNION ALL

SELECT 
    'Restaurants',
    COUNT(*)::text
FROM public.profiles WHERE role = 'restaurant'

UNION ALL

SELECT 
    'Livreurs',
    COUNT(*)::text
FROM public.profiles WHERE role = 'livreur';
