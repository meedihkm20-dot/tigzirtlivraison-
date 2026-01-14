-- ============================================
-- VÉRIFICATION ET CORRECTION DES UTILISATEURS
-- ============================================

-- Afficher tous les utilisateurs avec leurs rôles
DO $
DECLARE
    user_record RECORD;
    total_users INT := 0;
    users_with_profiles INT := 0;
    users_without_profiles INT := 0;
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'VÉRIFICATION DES UTILISATEURS';
    RAISE NOTICE '========================================';
    RAISE NOTICE '';
    
    -- Compter les utilisateurs
    SELECT COUNT(*) INTO total_users FROM auth.users;
    SELECT COUNT(*) INTO users_with_profiles FROM auth.users u JOIN public.profiles p ON p.id = u.id;
    users_without_profiles := total_users - users_with_profiles;
    
    RAISE NOTICE 'Total utilisateurs: %', total_users;
    RAISE NOTICE 'Avec profil: %', users_with_profiles;
    RAISE NOTICE 'Sans profil: %', users_without_profiles;
    RAISE NOTICE '';
    RAISE NOTICE '----------------------------------------';
    RAISE NOTICE 'LISTE DES UTILISATEURS:';
    RAISE NOTICE '----------------------------------------';
    
    FOR user_record IN 
        SELECT 
            u.email,
            p.role,
            p.full_name,
            u.last_sign_in_at,
            CASE 
                WHEN p.role = 'restaurant' THEN 
                    EXISTS(SELECT 1 FROM restaurants WHERE owner_id = u.id)
                WHEN p.role = 'livreur' THEN 
                    EXISTS(SELECT 1 FROM livreurs WHERE user_id = u.id)
                ELSE true
            END as entity_exists
        FROM auth.users u
        LEFT JOIN public.profiles p ON p.id = u.id
        ORDER BY u.created_at DESC
    LOOP
        IF user_record.role IS NULL THEN
            RAISE NOTICE '❌ % - PAS DE PROFIL', user_record.email;
        ELSIF user_record.role = 'restaurant' AND NOT user_record.entity_exists THEN
            RAISE NOTICE '⚠️  % - Role: % - RESTAURANT MANQUANT', user_record.email, user_record.role;
        ELSIF user_record.role = 'livreur' AND NOT user_record.entity_exists THEN
            RAISE NOTICE '⚠️  % - Role: % - LIVREUR MANQUANT', user_record.email, user_record.role;
        ELSE
            RAISE NOTICE '✅ % - Role: % - OK', user_record.email, COALESCE(user_record.role::text, 'NULL');
        END IF;
    END LOOP;
    
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
END $;

-- Exécuter le script de correction automatique
DO $
DECLARE
    user_record RECORD;
    restaurant_user_id UUID;
    livreur_user_id UUID;
BEGIN
    RAISE NOTICE 'CORRECTION AUTOMATIQUE...';
    RAISE NOTICE '';
    
    -- Corriger les profils manquants pour les comptes test
    FOR user_record IN 
        SELECT u.id, u.email
        FROM auth.users u
        LEFT JOIN public.profiles p ON p.id = u.id
        WHERE p.id IS NULL
        AND u.email IN ('admin@test.com', 'client@test.com', 'restaurant@test.com', 'livreur@test.com')
    LOOP
        INSERT INTO public.profiles (id, role, full_name, phone)
        VALUES (
            user_record.id,
            CASE 
                WHEN user_record.email = 'admin@test.com' THEN 'admin'
                WHEN user_record.email = 'client@test.com' THEN 'customer'
                WHEN user_record.email = 'restaurant@test.com' THEN 'restaurant'
                WHEN user_record.email = 'livreur@test.com' THEN 'livreur'
            END::user_role,
            CASE 
                WHEN user_record.email = 'admin@test.com' THEN 'Admin Test'
                WHEN user_record.email = 'client@test.com' THEN 'Client Test'
                WHEN user_record.email = 'restaurant@test.com' THEN 'Restaurant Test'
                WHEN user_record.email = 'livreur@test.com' THEN 'Livreur Test'
            END,
            '+213 555 000 000'
        );
        RAISE NOTICE '✅ Profil créé pour: %', user_record.email;
    END LOOP;
    
    -- Créer le restaurant pour restaurant@test.com si manquant
    SELECT id INTO restaurant_user_id FROM auth.users WHERE email = 'restaurant@test.com';
    IF restaurant_user_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.restaurants WHERE owner_id = restaurant_user_id) THEN
        INSERT INTO public.restaurants (
            owner_id, name, description, phone, address, 
            latitude, longitude, cuisine_type, opening_time, closing_time,
            min_order_amount, delivery_fee, avg_prep_time, is_open, is_verified
        ) VALUES (
            restaurant_user_id, 'Restaurant Test', 'Restaurant de test',
            '+213 555 100 100', 'Centre Ville, Tigzirt',
            36.8869, 4.1260, 'Algérienne', '10:00'::time, '23:00'::time,
            500, 150, 25, true, true
        );
        RAISE NOTICE '✅ Restaurant créé pour restaurant@test.com';
    END IF;
    
    -- Créer le livreur pour livreur@test.com si manquant
    SELECT id INTO livreur_user_id FROM auth.users WHERE email = 'livreur@test.com';
    IF livreur_user_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.livreurs WHERE user_id = livreur_user_id) THEN
        INSERT INTO public.livreurs (
            user_id, vehicle_type, vehicle_registration, license_number,
            latitude, longitude, is_available, is_online, is_verified,
            tier, rating, total_deliveries, total_earnings
        ) VALUES (
            livreur_user_id, 'moto', 'ABC-123-16', 'LIC-TEST-001',
            36.8869, 4.1260, true, false, true,
            'bronze', 5.0, 0, 0
        );
        RAISE NOTICE '✅ Livreur créé pour livreur@test.com';
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'CORRECTION TERMINÉE';
    RAISE NOTICE '========================================';
END $;
