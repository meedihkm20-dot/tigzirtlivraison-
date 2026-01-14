-- ============================================
-- VÉRIFICATION DES UTILISATEURS ET AUTH
-- ============================================

-- Voir tous les utilisateurs avec détails
SELECT 
    u.id,
    u.email,
    u.encrypted_password IS NOT NULL as has_password,
    u.email_confirmed_at IS NOT NULL as email_confirmed,
    u.last_sign_in_at,
    u.created_at,
    p.role,
    p.full_name,
    CASE 
        WHEN u.last_sign_in_at IS NULL THEN 'JAMAIS CONNECTÉ'
        WHEN u.last_sign_in_at > NOW() - INTERVAL '1 hour' THEN 'ACTIF'
        WHEN u.last_sign_in_at > NOW() - INTERVAL '24 hours' THEN 'RÉCENT'
        ELSE 'INACTIF'
    END as status
FROM auth.users u
LEFT JOIN public.profiles p ON p.id = u.id
ORDER BY u.created_at DESC;
