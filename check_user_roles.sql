-- ============================================
-- VÉRIFICATION DES RÔLES UTILISATEURS
-- ============================================
-- Ce script vérifie les rôles de tous les utilisateurs

-- 1. TOUS LES UTILISATEURS AVEC LEURS RÔLES
SELECT 
    p.id,
    u.email,
    p.full_name,
    p.role,
    p.phone,
    p.created_at,
    CASE 
        WHEN p.role = 'admin' THEN '👑 Admin'
        WHEN p.role = 'customer' THEN '👤 Client'
        WHEN p.role = 'restaurant' THEN '🍽️ Restaurant'
        WHEN p.role = 'livreur' THEN '🚴 Livreur'
        ELSE '❓ Inconnu'
    END as role_icon
FROM public.profiles p
JOIN auth.users u ON u.id = p.id
ORDER BY 
    CASE p.role
        WHEN 'admin' THEN 1
        WHEN 'restaurant' THEN 2
        WHEN 'livreur' THEN 3
        WHEN 'customer' THEN 4
        ELSE 5
    END,
    p.created_at;

-- 2. COMPTAGE PAR RÔLE
SELECT 
    role,
    COUNT(*) as nombre,
    CASE 
        WHEN role = 'admin' THEN '👑'
        WHEN role = 'customer' THEN '👤'
        WHEN role = 'restaurant' THEN '🍽️'
        WHEN role = 'livreur' THEN '🚴'
        ELSE '❓'
    END as icon
FROM public.profiles
GROUP BY role
ORDER BY 
    CASE role
        WHEN 'admin' THEN 1
        WHEN 'restaurant' THEN 2
        WHEN 'livreur' THEN 3
        WHEN 'customer' THEN 4
        ELSE 5
    END;

-- 3. VÉRIFIER LES RESTAURANTS LIÉS AUX UTILISATEURS
SELECT 
    u.email,
    p.full_name,
    p.role,
    r.name as restaurant_name,
    r.is_verified as restaurant_verified,
    r.is_open as restaurant_open
FROM public.profiles p
JOIN auth.users u ON u.id = p.id
LEFT JOIN public.restaurants r ON r.owner_id = p.id
WHERE p.role = 'restaurant'
ORDER BY r.created_at;

-- 4. VÉRIFIER LES LIVREURS LIÉS AUX UTILISATEURS
SELECT 
    u.email,
    p.full_name,
    p.role,
    l.vehicle_type,
    l.is_verified as livreur_verified,
    l.is_available,
    l.is_online,
    l.tier,
    l.total_deliveries,
    l.rating
FROM public.profiles p
JOIN auth.users u ON u.id = p.id
LEFT JOIN public.livreurs l ON l.user_id = p.id
WHERE p.role = 'livreur'
ORDER BY l.created_at;

-- 5. VÉRIFIER LES INCOHÉRENCES
-- Restaurants sans profil restaurant
SELECT 
    r.id,
    r.name,
    u.email,
    p.role as profile_role,
    '⚠️ Restaurant owner n''a pas le rôle restaurant' as probleme
FROM public.restaurants r
JOIN auth.users u ON u.id = r.owner_id
JOIN public.profiles p ON p.id = r.owner_id
WHERE p.role != 'restaurant';

-- Livreurs sans profil livreur
SELECT 
    l.id,
    u.email,
    p.role as profile_role,
    '⚠️ Livreur n''a pas le rôle livreur' as probleme
FROM public.livreurs l
JOIN auth.users u ON u.id = l.user_id
JOIN public.profiles p ON p.id = l.user_id
WHERE p.role != 'livreur';

-- Profils restaurant sans restaurant
SELECT 
    p.id,
    u.email,
    p.full_name,
    p.role,
    '⚠️ Profil restaurant mais pas de restaurant créé' as probleme
FROM public.profiles p
JOIN auth.users u ON u.id = p.id
LEFT JOIN public.restaurants r ON r.owner_id = p.id
WHERE p.role = 'restaurant' AND r.id IS NULL;

-- Profils livreur sans livreur
SELECT 
    p.id,
    u.email,
    p.full_name,
    p.role,
    '⚠️ Profil livreur mais pas de livreur créé' as probleme
FROM public.profiles p
JOIN auth.users u ON u.id = p.id
LEFT JOIN public.livreurs l ON l.user_id = p.id
WHERE p.role = 'livreur' AND l.id IS NULL;

-- 6. RÉSUMÉ FINAL
SELECT 
    '📊 RÉSUMÉ DES RÔLES' as titre,
    (SELECT COUNT(*) FROM profiles WHERE role = 'admin') as admins,
    (SELECT COUNT(*) FROM profiles WHERE role = 'customer') as clients,
    (SELECT COUNT(*) FROM profiles WHERE role = 'restaurant') as restaurants,
    (SELECT COUNT(*) FROM profiles WHERE role = 'livreur') as livreurs,
    (SELECT COUNT(*) FROM profiles) as total;
