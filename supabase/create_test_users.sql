-- ============================================
-- CRÉATION DES COMPTES DE TEST AVEC RÔLES CORRECTS
-- ============================================
-- Ce script crée tous les comptes de test avec les bons rôles

-- ============================================
-- ÉTAPE 1: VÉRIFIER LES UTILISATEURS EXISTANTS
-- ============================================

SELECT 
    '📊 UTILISATEURS EXISTANTS' as info,
    u.email,
    p.role,
    p.full_name,
    u.created_at
FROM auth.users u
LEFT JOIN public.profiles p ON p.id = u.id
WHERE u.email IN ('admin@test.com', 'client@test.com', 'restaurant@test.com', 'livreur@test.com')
ORDER BY u.email;

-- ============================================
-- ÉTAPE 2: CORRIGER LES RÔLES SI NÉCESSAIRE
-- ============================================

-- Fonction pour corriger le rôle d'un utilisateur
CREATE OR REPLACE FUNCTION fix_user_role(user_email TEXT, correct_role user_role)
RETURNS BOOLEAN AS $
DECLARE
  user_id UUID;
  current_role user_role;
BEGIN
  -- Récupérer l'ID et le rôle actuel
  SELECT u.id, p.role INTO user_id, current_role
  FROM auth.users u
  LEFT JOIN public.profiles p ON p.id = u.id
  WHERE u.email = user_email;
  
  IF user_id IS NULL THEN
    RAISE NOTICE '❌ Utilisateur % non trouvé', user_email;
    RETURN FALSE;
  END IF;
  
  IF current_role IS NULL THEN
    RAISE NOTICE '⚠️ Profil manquant pour %, création...', user_email;
    -- Créer le profil avec le bon rôle
    INSERT INTO public.profiles (id, role, full_name, phone)
    VALUES (
      user_id, 
      correct_role,
      CASE correct_role
        WHEN 'admin' THEN 'Admin Test'
        WHEN 'customer' THEN 'Client Test'
        WHEN 'restaurant' THEN 'Restaurant Test'
        WHEN 'livreur' THEN 'Livreur Test'
      END,
      '+213 555 000 000'
    );
    RAISE NOTICE '✅ Profil créé pour % avec rôle %', user_email, correct_role;
    RETURN TRUE;
  END IF;
  
  IF current_role != correct_role THEN
    RAISE NOTICE '⚠️ Rôle incorrect pour %: % au lieu de %', user_email, current_role, correct_role;
    -- Corriger le rôle
    UPDATE public.profiles 
    SET role = correct_role
    WHERE id = user_id;
    RAISE NOTICE '✅ Rôle corrigé pour %: %', user_email, correct_role;
    RETURN TRUE;
  END IF;
  
  RAISE NOTICE '✅ Rôle correct pour %: %', user_email, correct_role;
  RETURN TRUE;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- ÉTAPE 3: CORRIGER TOUS LES RÔLES
-- ============================================

SELECT fix_user_role('admin@test.com', 'admin');
SELECT fix_user_role('client@test.com', 'customer');
SELECT fix_user_role('restaurant@test.com', 'restaurant');
SELECT fix_user_role('livreur@test.com', 'livreur');

-- ============================================
-- ÉTAPE 4: CRÉER LES ENTITÉS LIÉES SI NÉCESSAIRE
-- ============================================

-- Créer le restaurant pour restaurant@test.com si manquant
DO $
DECLARE
  restaurant_user_id UUID;
  restaurant_exists BOOLEAN;
BEGIN
  -- Récupérer l'ID du restaurant owner
  SELECT id INTO restaurant_user_id 
  FROM auth.users 
  WHERE email = 'restaurant@test.com';
  
  IF restaurant_user_id IS NOT NULL THEN
    -- Vérifier si le restaurant existe
    SELECT EXISTS(SELECT 1 FROM public.restaurants WHERE owner_id = restaurant_user_id) 
    INTO restaurant_exists;
    
    IF NOT restaurant_exists THEN
      RAISE NOTICE '⚠️ Restaurant manquant pour restaurant@test.com, création...';
      
      INSERT INTO public.restaurants (
        owner_id, 
        name, 
        description, 
        phone, 
        address, 
        latitude, 
        longitude, 
        cuisine_type,
        opening_time,
        closing_time,
        min_order_amount,
        delivery_fee,
        avg_prep_time,
        is_open,
        is_verified
      ) VALUES (
        restaurant_user_id,
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
      
      RAISE NOTICE '✅ Restaurant créé pour restaurant@test.com';
    ELSE
      RAISE NOTICE '✅ Restaurant existe déjà pour restaurant@test.com';
    END IF;
  END IF;
END $;

-- Créer le livreur pour livreur@test.com si manquant
DO $
DECLARE
  livreur_user_id UUID;
  livreur_exists BOOLEAN;
BEGIN
  -- Récupérer l'ID du livreur
  SELECT id INTO livreur_user_id 
  FROM auth.users 
  WHERE email = 'livreur@test.com';
  
  IF livreur_user_id IS NOT NULL THEN
    -- Vérifier si le livreur existe
    SELECT EXISTS(SELECT 1 FROM public.livreurs WHERE user_id = livreur_user_id) 
    INTO livreur_exists;
    
    IF NOT livreur_exists THEN
      RAISE NOTICE '⚠️ Livreur manquant pour livreur@test.com, création...';
      
      INSERT INTO public.livreurs (
        user_id,
        vehicle_type,
        vehicle_registration,
        license_number,
        latitude,
        longitude,
        is_available,
        is_online,
        is_verified,
        tier,
        rating,
        total_deliveries,
        total_earnings
      ) VALUES (
        livreur_user_id,
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
      
      RAISE NOTICE '✅ Livreur créé pour livreur@test.com';
    ELSE
      RAISE NOTICE '✅ Livreur existe déjà pour livreur@test.com';
    END IF;
  END IF;
END $;

-- ============================================
-- ÉTAPE 5: VÉRIFICATION FINALE
-- ============================================

SELECT 
    '📊 VÉRIFICATION FINALE' as titre,
    '' as separator;

-- Tous les utilisateurs avec leurs rôles
SELECT 
    u.email,
    p.role,
    p.full_name,
    CASE 
        WHEN p.role = 'admin' THEN '👑 Admin'
        WHEN p.role = 'customer' THEN '👤 Client'
        WHEN p.role = 'restaurant' THEN '🍽️ Restaurant'
        WHEN p.role = 'livreur' THEN '🚴 Livreur'
        ELSE '❓ Inconnu'
    END as role_icon,
    CASE 
        WHEN p.role = 'restaurant' THEN 
            CASE WHEN EXISTS(SELECT 1 FROM restaurants WHERE owner_id = u.id) 
                THEN '✅ Restaurant créé' 
                ELSE '❌ Restaurant manquant' 
            END
        WHEN p.role = 'livreur' THEN 
            CASE WHEN EXISTS(SELECT 1 FROM livreurs WHERE user_id = u.id) 
                THEN '✅ Livreur créé' 
                ELSE '❌ Livreur manquant' 
            END
        ELSE '✅ OK'
    END as entity_status
FROM auth.users u
LEFT JOIN public.profiles p ON p.id = u.id
WHERE u.email IN ('admin@test.com', 'client@test.com', 'restaurant@test.com', 'livreur@test.com')
ORDER BY 
    CASE p.role
        WHEN 'admin' THEN 1
        WHEN 'restaurant' THEN 2
        WHEN 'livreur' THEN 3
        WHEN 'customer' THEN 4
        ELSE 5
    END;

-- Comptage par rôle
SELECT 
    '📈 COMPTAGE PAR RÔLE' as titre,
    role,
    COUNT(*) as nombre
FROM public.profiles
WHERE id IN (SELECT id FROM auth.users WHERE email IN ('admin@test.com', 'client@test.com', 'restaurant@test.com', 'livreur@test.com'))
GROUP BY role
ORDER BY 
    CASE role
        WHEN 'admin' THEN 1
        WHEN 'restaurant' THEN 2
        WHEN 'livreur' THEN 3
        WHEN 'customer' THEN 4
        ELSE 5
    END;

-- Supprimer la fonction temporaire
DROP FUNCTION IF EXISTS fix_user_role(TEXT, user_role);

SELECT '✅ Vérification et correction des rôles terminée!' AS status;
