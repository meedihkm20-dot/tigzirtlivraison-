-- VÉRIFICATION RAPIDE DES UTILISATEURS ET RÔLES

SELECT 
    u.email,
    p.role,
    p.full_name,
    u.last_sign_in_at as derniere_connexion,
    CASE 
        WHEN p.role = 'restaurant' THEN 
            CASE WHEN EXISTS(SELECT 1 FROM restaurants WHERE owner_id = u.id) 
                THEN '✅ Restaurant OK' 
                ELSE '❌ Restaurant manquant' 
            END
        WHEN p.role = 'livreur' THEN 
            CASE WHEN EXISTS(SELECT 1 FROM livreurs WHERE user_id = u.id) 
                THEN '✅ Livreur OK' 
                ELSE '❌ Livreur manquant' 
            END
        ELSE '✅ OK'
    END as status_entite
FROM auth.users u
LEFT JOIN public.profiles p ON p.id = u.id
ORDER BY u.created_at DESC;
