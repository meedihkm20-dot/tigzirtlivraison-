-- ============================================================
-- DZ DELIVERY - DONNÉES DE TEST
-- ============================================================
-- Exécuter après SCHEMA_FINAL.sql
-- Crée des utilisateurs, restaurants, menus pour tester l'app
-- ============================================================

-- ============================================
-- 1. CRÉER LES UTILISATEURS DE TEST
-- ============================================
-- Note: Les utilisateurs doivent être créés via Supabase Auth
-- Voici les comptes à créer manuellement dans Authentication > Users:
--
-- CLIENT:
--   Email: client@test.com
--   Password: test123456
--   Metadata: {"full_name": "Ahmed Client", "phone": "0555123456", "role": "customer"}
--
-- RESTAURANT:
--   Email: restaurant@test.com
--   Password: test123456
--   Metadata: {"full_name": "Karim Restaurant", "phone": "0555234567", "role": "restaurant"}
--
-- LIVREUR:
--   Email: livreur@test.com
--   Password: test123456
--   Metadata: {"full_name": "Yacine Livreur", "phone": "0555345678", "role": "livreur"}
--
-- ADMIN:
--   Email: admin@test.com (ou mehdihakkoum@gmail.com)
--   Password: test123456 (ou epau2012)
--   Metadata: {"full_name": "Admin DZ", "phone": "0555000000", "role": "admin"}

-- ============================================
-- 2. RESTAURANT DE TEST
-- ============================================
-- Note: Remplacer 'RESTAURANT_USER_ID' par l'UUID réel après création du compte

-- D'abord, récupérer l'ID du restaurant owner (à exécuter après création des users)
-- SELECT id FROM auth.users WHERE email = 'restaurant@test.com';

-- Créer le restaurant (remplacer l'UUID)
INSERT INTO public.restaurants (
    id,
    owner_id,
    name,
    description,
    logo_url,
    cover_url,
    phone,
    address,
    latitude,
    longitude,
    cuisine_type,
    tags,
    opening_time,
    closing_time,
    min_order_amount,
    delivery_fee,
    avg_prep_time,
    rating,
    is_open,
    is_verified
) VALUES (
    'a1111111-1111-1111-1111-111111111111',
    (SELECT id FROM public.profiles WHERE role = 'restaurant' LIMIT 1),
    'Pizza Tigzirt',
    'Les meilleures pizzas de Tigzirt! Pâte fraîche, ingrédients locaux.',
    'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=200',
    'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=800',
    '0555234567',
    'Rue principale, Tigzirt',
    36.8892,
    4.1225,
    'Pizza',
    ARRAY['Pizza', 'Italien', 'Fast-food'],
    '10:00',
    '23:00',
    500,
    150,
    25,
    4.5,
    true,
    true
) ON CONFLICT (id) DO NOTHING;

-- Restaurant 2
INSERT INTO public.restaurants (
    id,
    owner_id,
    name,
    description,
    phone,
    address,
    latitude,
    longitude,
    cuisine_type,
    tags,
    min_order_amount,
    delivery_fee,
    avg_prep_time,
    rating,
    is_open,
    is_verified
) VALUES (
    'a2222222-2222-2222-2222-222222222222',
    (SELECT id FROM public.profiles WHERE role = 'restaurant' LIMIT 1),
    'Couscous Mama',
    'Couscous traditionnel kabyle fait maison',
    '0555345678',
    'Centre ville, Tigzirt',
    36.8900,
    4.1230,
    'Traditionnel',
    ARRAY['Couscous', 'Kabyle', 'Traditionnel'],
    800,
    100,
    45,
    4.8,
    true,
    true
) ON CONFLICT (id) DO NOTHING;

-- ============================================
-- 3. CATÉGORIES DE MENU
-- ============================================
INSERT INTO public.menu_categories (id, restaurant_id, name, description, sort_order) VALUES
    ('c1111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111', 'Pizzas', 'Nos pizzas maison', 1),
    ('c2222222-2222-2222-2222-222222222222', 'a1111111-1111-1111-1111-111111111111', 'Boissons', 'Boissons fraîches', 2),
    ('c3333333-3333-3333-3333-333333333333', 'a1111111-1111-1111-1111-111111111111', 'Desserts', 'Douceurs sucrées', 3),
    ('c4444444-4444-4444-4444-444444444444', 'a2222222-2222-2222-2222-222222222222', 'Couscous', 'Nos couscous', 1),
    ('c5555555-5555-5555-5555-555555555555', 'a2222222-2222-2222-2222-222222222222', 'Entrées', 'Pour commencer', 2)
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- 4. PLATS DU MENU
-- ============================================

-- Pizzas
INSERT INTO public.menu_items (id, restaurant_id, category_id, name, description, price, image_url, is_available, is_popular, prep_time) VALUES
    ('m1111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111', 'c1111111-1111-1111-1111-111111111111', 
     'Pizza Margherita', 'Tomate, mozzarella, basilic frais', 800, 
     'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=400', true, true, 20),
    
    ('m2222222-2222-2222-2222-222222222222', 'a1111111-1111-1111-1111-111111111111', 'c1111111-1111-1111-1111-111111111111', 
     'Pizza 4 Fromages', 'Mozzarella, gorgonzola, parmesan, chèvre', 1000, 
     'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400', true, true, 25),
    
    ('m3333333-3333-3333-3333-333333333333', 'a1111111-1111-1111-1111-111111111111', 'c1111111-1111-1111-1111-111111111111', 
     'Pizza Viande Hachée', 'Viande hachée, oignons, poivrons, fromage', 900, 
     'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400', true, false, 25),
    
    ('m4444444-4444-4444-4444-444444444444', 'a1111111-1111-1111-1111-111111111111', 'c1111111-1111-1111-1111-111111111111', 
     'Pizza Poulet', 'Poulet grillé, champignons, sauce blanche', 950, 
     'https://images.unsplash.com/photo-1594007654729-407eedc4be65?w=400', true, false, 25)
ON CONFLICT (id) DO NOTHING;

-- Boissons
INSERT INTO public.menu_items (id, restaurant_id, category_id, name, description, price, is_available, prep_time) VALUES
    ('m5555555-5555-5555-5555-555555555555', 'a1111111-1111-1111-1111-111111111111', 'c2222222-2222-2222-2222-222222222222', 
     'Coca-Cola 33cl', 'Canette fraîche', 100, true, 1),
    ('m6666666-6666-6666-6666-666666666666', 'a1111111-1111-1111-1111-111111111111', 'c2222222-2222-2222-2222-222222222222', 
     'Eau minérale 1.5L', 'Eau Ifri', 80, true, 1),
    ('m7777777-7777-7777-7777-777777777777', 'a1111111-1111-1111-1111-111111111111', 'c2222222-2222-2222-2222-222222222222', 
     'Jus d''orange 1L', 'Jus frais', 150, true, 1)
ON CONFLICT (id) DO NOTHING;

-- Desserts
INSERT INTO public.menu_items (id, restaurant_id, category_id, name, description, price, is_available, prep_time) VALUES
    ('m8888888-8888-8888-8888-888888888888', 'a1111111-1111-1111-1111-111111111111', 'c3333333-3333-3333-3333-333333333333', 
     'Tiramisu', 'Tiramisu maison au café', 300, true, 5),
    ('m9999999-9999-9999-9999-999999999999', 'a1111111-1111-1111-1111-111111111111', 'c3333333-3333-3333-3333-333333333333', 
     'Glace 2 boules', 'Vanille, chocolat ou fraise', 200, true, 2)
ON CONFLICT (id) DO NOTHING;

-- Couscous (Restaurant 2)
INSERT INTO public.menu_items (id, restaurant_id, category_id, name, description, price, image_url, is_available, is_popular, prep_time) VALUES
    ('ma111111-1111-1111-1111-111111111111', 'a2222222-2222-2222-2222-222222222222', 'c4444444-4444-4444-4444-444444444444', 
     'Couscous Poulet', 'Couscous traditionnel avec poulet et légumes', 1200, 
     'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=400', true, true, 40),
    
    ('ma222222-2222-2222-2222-222222222222', 'a2222222-2222-2222-2222-222222222222', 'c4444444-4444-4444-4444-444444444444', 
     'Couscous Agneau', 'Couscous avec viande d''agneau tendre', 1500, 
     'https://images.unsplash.com/photo-1511690743698-d9d85f2fbf38?w=400', true, true, 45),
    
    ('ma333333-3333-3333-3333-333333333333', 'a2222222-2222-2222-2222-222222222222', 'c4444444-4444-4444-4444-444444444444', 
     'Couscous Légumes', 'Couscous végétarien aux 7 légumes', 900, 
     NULL, true, false, 35)
ON CONFLICT (id) DO NOTHING;

-- Entrées (Restaurant 2)
INSERT INTO public.menu_items (id, restaurant_id, category_id, name, description, price, is_available, prep_time) VALUES
    ('ma444444-4444-4444-4444-444444444444', 'a2222222-2222-2222-2222-222222222222', 'c5555555-5555-5555-5555-555555555555', 
     'Chorba', 'Soupe traditionnelle aux légumes', 300, true, 10),
    ('ma555555-5555-5555-5555-555555555555', 'a2222222-2222-2222-2222-222222222222', 'c5555555-5555-5555-5555-555555555555', 
     'Salade Mechouia', 'Salade de poivrons grillés', 250, true, 5)
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- 5. LIVREUR DE TEST
-- ============================================
-- Note: Le profil est créé automatiquement via trigger
-- Il faut juste créer l'entrée dans la table livreurs

INSERT INTO public.livreurs (
    id,
    user_id,
    vehicle_type,
    vehicle_number,
    current_latitude,
    current_longitude,
    is_available,
    is_online,
    is_verified,
    rating,
    total_deliveries,
    total_earnings,
    tier
) 
SELECT 
    'l1111111-1111-1111-1111-111111111111',
    id,
    'moto',
    '12345-123-16',
    36.8895,
    4.1220,
    true,
    true,
    true,
    4.8,
    25,
    12500,
    'silver'
FROM public.profiles 
WHERE role = 'livreur' 
LIMIT 1
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- 6. PROMOTIONS DE TEST
-- ============================================
INSERT INTO public.promotions (id, restaurant_id, name, description, discount_type, discount_value, min_order_amount, max_discount, code, is_active, ends_at) VALUES
    ('p1111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111', 
     'Bienvenue', 'Réduction de bienvenue', 'percentage', 10, 500, 200, 'BIENVENUE10', true, NOW() + INTERVAL '30 days'),
    ('p2222222-2222-2222-2222-222222222222', NULL, 
     'Livraison Gratuite', 'Livraison offerte', 'fixed', 150, 1000, NULL, 'LIVGRATUITE', true, NOW() + INTERVAL '7 days')
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- 7. VÉRIFICATION
-- ============================================
SELECT 'Données de test créées!' AS status;

SELECT 'Restaurants:' AS type, COUNT(*) AS count FROM public.restaurants
UNION ALL
SELECT 'Catégories:', COUNT(*) FROM public.menu_categories
UNION ALL
SELECT 'Plats:', COUNT(*) FROM public.menu_items
UNION ALL
SELECT 'Livreurs:', COUNT(*) FROM public.livreurs
UNION ALL
SELECT 'Promotions:', COUNT(*) FROM public.promotions;

-- ============================================
-- COMPTES DE TEST À CRÉER DANS SUPABASE AUTH
-- ============================================
/*
Aller dans Supabase Dashboard > Authentication > Users > Add User

1. CLIENT:
   Email: client@test.com
   Password: test123456
   User Metadata (JSON): 
   {
     "full_name": "Ahmed Client",
     "phone": "0555123456",
     "role": "customer"
   }

2. RESTAURANT:
   Email: restaurant@test.com
   Password: test123456
   User Metadata (JSON):
   {
     "full_name": "Karim Restaurant",
     "phone": "0555234567",
     "role": "restaurant"
   }

3. LIVREUR:
   Email: livreur@test.com
   Password: test123456
   User Metadata (JSON):
   {
     "full_name": "Yacine Livreur",
     "phone": "0555345678",
     "role": "livreur"
   }

4. ADMIN (si pas déjà créé):
   Email: admin@test.com
   Password: test123456
   User Metadata (JSON):
   {
     "full_name": "Admin DZ",
     "phone": "0555000000",
     "role": "admin"
   }

Après création des users, ré-exécuter ce script pour lier les données.
*/
