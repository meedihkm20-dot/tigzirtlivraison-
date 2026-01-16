-- ============================================
-- FIX: Un email = Plusieurs restaurants
-- ============================================

-- PROBLÈME ACTUEL:
-- restaurant@test.com gère 3 restaurants:
-- - Pizza Tigzirt
-- - Couscous Mama  
-- - Tacos Express

-- ============================================
-- SOLUTION 1: GARDER UN SEUL RESTAURANT (Recommandé pour test)
-- ============================================

-- 1. Voir tous les restaurants de cet owner
SELECT 
    id,
    name,
    owner_id,
    is_verified,
    is_open,
    created_at
FROM restaurants
WHERE owner_id IN (SELECT id FROM auth.users WHERE email = 'restaurant@test.com')
ORDER BY created_at;

-- 2. Choisir quel restaurant garder (le plus ancien par exemple)
-- Copier l'ID du restaurant à GARDER

-- 3. Supprimer les autres restaurants
-- ⚠️ ATTENTION: Remplacer 'RESTAURANT_ID_A_GARDER' par l'ID réel

/*
DELETE FROM restaurants
WHERE owner_id IN (SELECT id FROM auth.users WHERE email = 'restaurant@test.com')
AND id != 'RESTAURANT_ID_A_GARDER';
*/

-- Exemple: Garder "Pizza Tigzirt" et supprimer les autres
/*
DELETE FROM restaurants
WHERE owner_id IN (SELECT id FROM auth.users WHERE email = 'restaurant@test.com')
AND name != 'Pizza Tigzirt';
*/

-- ============================================
-- SOLUTION 2: CRÉER DES COMPTES SÉPARÉS
-- ============================================

-- Créer 2 nouveaux comptes pour les 2 autres restaurants

-- A. Restaurant 2: Couscous Mama
/*
-- 1. Générer UUID
SELECT gen_random_uuid();

-- 2. Créer l'utilisateur
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
    'UUID_RESTAURANT_2',
    'restaurant2@test.com',
    crypt('test123456', gen_salt('bf')),
    NOW(),
    NOW(),
    NOW(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Mama Couscous","phone":"0555000002","role":"restaurant"}',
    false,
    'authenticated'
);

-- 3. Créer le profil
INSERT INTO profiles (id, role, full_name, phone, is_active)
VALUES (
    'UUID_RESTAURANT_2',
    'restaurant',
    'Mama Couscous',
    '0555000002',
    true
);

-- 4. Transférer le restaurant
UPDATE restaurants
SET owner_id = 'UUID_RESTAURANT_2'
WHERE name = 'Couscous Mama';
*/

-- B. Restaurant 3: Tacos Express
/*
-- Répéter les mêmes étapes avec:
-- - email: restaurant3@test.com
-- - full_name: Tacos Express Owner
-- - phone: 0555000003
*/

-- ============================================
-- SOLUTION 3: ARCHITECTURE MULTI-RESTAURANTS
-- ============================================

-- Si tu veux vraiment qu'un owner gère plusieurs restaurants,
-- il faut modifier l'app pour:

-- 1. Ajouter une table de sélection de restaurant
CREATE TABLE IF NOT EXISTS user_selected_restaurant (
    user_id UUID PRIMARY KEY REFERENCES profiles(id),
    restaurant_id UUID REFERENCES restaurants(id),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Modifier l'app pour afficher un sélecteur au login
-- 3. Stocker le restaurant sélectionné

-- ⚠️ Cette solution nécessite des modifications de code importantes

-- ============================================
-- VÉRIFICATION APRÈS FIX
-- ============================================

-- Vérifier qu'il ne reste qu'un seul restaurant par owner
SELECT 
    u.email,
    COUNT(r.id) as nb_restaurants,
    STRING_AGG(r.name, ', ') as restaurants
FROM auth.users u
JOIN profiles p ON p.id = u.id
LEFT JOIN restaurants r ON r.owner_id = u.id
WHERE p.role = 'restaurant'
GROUP BY u.email
HAVING COUNT(r.id) > 1;

-- Résultat attendu: 0 lignes (aucun owner avec plusieurs restaurants)

-- ============================================
-- RECOMMANDATION FINALE
-- ============================================

-- Pour l'instant (phase de test):
-- ✅ SOLUTION 1: Garder un seul restaurant par email
-- ✅ Supprimer "Couscous Mama" et "Tacos Express"
-- ✅ Garder "Pizza Tigzirt" pour restaurant@test.com

-- Pour la production:
-- ✅ Créer un email unique par restaurant
-- ✅ Ou implémenter l'architecture multi-restaurants (plus complexe)
