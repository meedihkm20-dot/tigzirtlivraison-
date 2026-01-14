-- ============================================
-- SEED: Données de Test pour DZ Delivery
-- ============================================
-- Ce script crée des données de test réalistes pour l'application

-- ============================================
-- 1. RESTAURANTS (5 restaurants à Tigzirt)
-- ============================================

-- Restaurant 1: Pizza Palace
INSERT INTO public.restaurants (id, owner_id, name, description, phone, address, latitude, longitude, cuisine_type, opening_time, closing_time, min_order_amount, delivery_fee, avg_prep_time, rating, is_open, is_verified)
SELECT 
    '11111111-1111-1111-1111-111111111111'::uuid,
    (SELECT id FROM profiles WHERE role = 'restaurant' LIMIT 1),
    'Pizza Palace Tigzirt',
    'Les meilleures pizzas artisanales de Tigzirt. Pâte fraîche, ingrédients locaux.',
    '+213 555 123 456',
    'Centre Ville, Tigzirt',
    36.8869,
    4.1260,
    'Pizza',
    '11:00'::time,
    '23:00'::time,
    500,
    150,
    25,
    4.5,
    true,
    true
WHERE NOT EXISTS (SELECT 1 FROM public.restaurants WHERE id = '11111111-1111-1111-1111-111111111111');

-- Restaurant 2: Tacos Express
INSERT INTO public.restaurants (id, owner_id, name, description, phone, address, latitude, longitude, cuisine_type, opening_time, closing_time, min_order_amount, delivery_fee, avg_prep_time, rating, is_open, is_verified)
SELECT 
    '22222222-2222-2222-2222-222222222222'::uuid,
    (SELECT id FROM profiles WHERE role = 'restaurant' LIMIT 1),
    'Tacos Express',
    'Tacos, burgers et sandwichs. Livraison rapide!',
    '+213 555 234 567',
    'Route Nationale, Tigzirt',
    36.8879,
    4.1270,
    'Fast Food',
    '10:00'::time,
    '01:00'::time,
    300,
    100,
    15,
    4.2,
    true,
    true
WHERE NOT EXISTS (SELECT 1 FROM public.restaurants WHERE id = '22222222-2222-2222-2222-222222222222');

-- Restaurant 3: Le Couscous Royal
INSERT INTO public.restaurants (id, owner_id, name, description, phone, address, latitude, longitude, cuisine_type, opening_time, closing_time, min_order_amount, delivery_fee, avg_prep_time, rating, is_open, is_verified)
SELECT 
    '33333333-3333-3333-3333-333333333333'::uuid,
    (SELECT id FROM profiles WHERE role = 'restaurant' LIMIT 1),
    'Le Couscous Royal',
    'Cuisine traditionnelle algérienne. Couscous, tajines, grillades.',
    '+213 555 345 678',
    'Quartier Plage, Tigzirt',
    36.8859,
    4.1250,
    'Algérienne',
    '12:00'::time,
    '22:00'::time,
    800,
    200,
    35,
    4.8,
    true,
    true
WHERE NOT EXISTS (SELECT 1 FROM public.restaurants WHERE id = '33333333-3333-3333-3333-333333333333');

-- Restaurant 4: Sushi Bar
INSERT INTO public.restaurants (id, owner_id, name, description, phone, address, latitude, longitude, cuisine_type, opening_time, closing_time, min_order_amount, delivery_fee, avg_prep_time, rating, is_open, is_verified)
SELECT 
    '44444444-4444-4444-4444-444444444444'::uuid,
    (SELECT id FROM profiles WHERE role = 'restaurant' LIMIT 1),
    'Sushi Bar Tigzirt',
    'Sushi frais, makis, california rolls. Poisson du jour.',
    '+213 555 456 789',
    'Port de Tigzirt',
    36.8889,
    4.1280,
    'Japonaise',
    '18:00'::time,
    '23:30'::time,
    1000,
    250,
    30,
    4.6,
    true,
    true
WHERE NOT EXISTS (SELECT 1 FROM public.restaurants WHERE id = '44444444-4444-4444-4444-444444444444');

-- Restaurant 5: Café Gourmand
INSERT INTO public.restaurants (id, owner_id, name, description, phone, address, latitude, longitude, cuisine_type, opening_time, closing_time, min_order_amount, delivery_fee, avg_prep_time, rating, is_open, is_verified)
SELECT 
    '55555555-5555-5555-5555-555555555555'::uuid,
    (SELECT id FROM profiles WHERE role = 'restaurant' LIMIT 1),
    'Café Gourmand',
    'Pâtisseries, viennoiseries, café. Petit-déjeuner et goûter.',
    '+213 555 567 890',
    'Avenue Principale, Tigzirt',
    36.8849,
    4.1240,
    'Café',
    '07:00'::time,
    '20:00'::time,
    200,
    80,
    10,
    4.3,
    true,
    true
WHERE NOT EXISTS (SELECT 1 FROM public.restaurants WHERE id = '55555555-5555-5555-5555-555555555555');

-- ============================================
-- 2. MENU ITEMS (10 items par restaurant)
-- ============================================

-- Pizza Palace
INSERT INTO public.menu_items (restaurant_id, name, description, price, is_available, is_popular, prep_time) VALUES
('11111111-1111-1111-1111-111111111111', 'Pizza Margherita', 'Tomate, mozzarella, basilic', 800, true, true, 20),
('11111111-1111-1111-1111-111111111111', 'Pizza 4 Fromages', 'Mozzarella, gorgonzola, parmesan, chèvre', 1000, true, true, 20),
('11111111-1111-1111-1111-111111111111', 'Pizza Végétarienne', 'Légumes grillés, olives, champignons', 900, true, false, 20),
('11111111-1111-1111-1111-111111111111', 'Pizza Fruits de Mer', 'Crevettes, calamars, moules', 1200, true, true, 25),
('11111111-1111-1111-1111-111111111111', 'Calzone', 'Pizza fermée garnie au choix', 950, true, false, 25)
ON CONFLICT DO NOTHING;

-- Tacos Express
INSERT INTO public.menu_items (restaurant_id, name, description, price, is_available, is_popular, prep_time) VALUES
('22222222-2222-2222-2222-222222222222', 'Tacos Poulet', 'Poulet grillé, frites, sauce', 500, true, true, 12),
('22222222-2222-2222-2222-222222222222', 'Tacos Viande Hachée', 'Viande hachée, frites, sauce', 550, true, true, 12),
('22222222-2222-2222-2222-222222222222', 'Burger Classic', 'Steak, salade, tomate, oignon', 600, true, true, 15),
('22222222-2222-2222-2222-222222222222', 'Burger Cheese', 'Double steak, double fromage', 750, true, true, 15),
('22222222-2222-2222-2222-222222222222', 'Sandwich Poulet', 'Poulet pané, crudités', 400, true, false, 10)
ON CONFLICT DO NOTHING;

-- Le Couscous Royal
INSERT INTO public.menu_items (restaurant_id, name, description, price, is_available, is_popular, prep_time) VALUES
('33333333-3333-3333-3333-333333333333', 'Couscous Poulet', 'Couscous traditionnel au poulet', 1200, true, true, 35),
('33333333-3333-3333-3333-333333333333', 'Couscous Agneau', 'Couscous à l''agneau et légumes', 1500, true, true, 40),
('33333333-3333-3333-3333-333333333333', 'Tajine Poulet', 'Tajine aux olives et citron confit', 1100, true, false, 35),
('33333333-3333-3333-3333-333333333333', 'Méchoui', 'Agneau grillé, portion 500g', 1800, true, true, 30),
('33333333-3333-3333-3333-333333333333', 'Chorba', 'Soupe traditionnelle algérienne', 400, true, false, 15)
ON CONFLICT DO NOTHING;

-- Sushi Bar
INSERT INTO public.menu_items (restaurant_id, name, description, price, is_available, is_popular, prep_time) VALUES
('44444444-4444-4444-4444-444444444444', 'Sushi Mix 12 pièces', 'Assortiment de sushis variés', 1800, true, true, 25),
('44444444-4444-4444-4444-444444444444', 'California Roll', '8 pièces, avocat, surimi', 1200, true, true, 20),
('44444444-4444-4444-4444-444444444444', 'Maki Saumon', '6 pièces, saumon frais', 900, true, true, 15),
('44444444-4444-4444-4444-444444444444', 'Sashimi Thon', '8 tranches de thon rouge', 1500, true, false, 20),
('44444444-4444-4444-4444-444444444444', 'Plateau Découverte', '24 pièces variées', 3000, true, true, 35)
ON CONFLICT DO NOTHING;

-- Café Gourmand
INSERT INTO public.menu_items (restaurant_id, name, description, price, is_available, is_popular, prep_time) VALUES
('55555555-5555-5555-5555-555555555555', 'Croissant', 'Croissant au beurre frais', 80, true, true, 5),
('55555555-5555-5555-5555-555555555555', 'Pain au Chocolat', 'Viennoiserie au chocolat', 100, true, true, 5),
('55555555-5555-5555-5555-555555555555', 'Café Crème', 'Café avec mousse de lait', 150, true, true, 3),
('55555555-5555-5555-5555-555555555555', 'Tarte aux Pommes', 'Part de tarte maison', 250, true, false, 8),
('55555555-5555-5555-5555-555555555555', 'Jus d''Orange Frais', 'Pressé minute', 200, true, true, 5)
ON CONFLICT DO NOTHING;

-- ============================================
-- 3. LIVREURS (3 livreurs supplémentaires)
-- ============================================

-- Note: Les livreurs doivent d'abord créer un compte via l'app
-- Ce script suppose que les profils existent déjà

-- ============================================
-- 4. PROMOTIONS (2 par restaurant)
-- ============================================

INSERT INTO public.promotions (restaurant_id, name, description, discount_type, discount_value, min_order_amount, code, is_active, ends_at) VALUES
('11111111-1111-1111-1111-111111111111', 'Bienvenue Pizza', 'Réduction de bienvenue', 'percentage', 20, 500, 'PIZZA20', true, NOW() + INTERVAL '30 days'),
('22222222-2222-2222-2222-222222222222', 'Tacos Promo', '100 DA de réduction', 'fixed', 100, 300, 'TACOS100', true, NOW() + INTERVAL '15 days'),
('33333333-3333-3333-3333-333333333333', 'Couscous Famille', '15% sur commandes +1000 DA', 'percentage', 15, 1000, 'FAMILLE15', true, NOW() + INTERVAL '60 days'),
('44444444-4444-4444-4444-444444444444', 'Sushi Night', '200 DA de réduction le soir', 'fixed', 200, 1500, 'SUSHI200', true, NOW() + INTERVAL '7 days'),
('55555555-5555-5555-5555-555555555555', 'Petit Dej', '10% sur petit-déjeuner', 'percentage', 10, 200, 'PETITDEJ', true, NOW() + INTERVAL '90 days')
ON CONFLICT DO NOTHING;

-- ============================================
-- 5. MISE À JOUR DES STATS
-- ============================================

-- Mettre à jour order_count pour simuler la popularité
UPDATE public.menu_items SET order_count = FLOOR(RANDOM() * 50 + 10)::INTEGER WHERE is_popular = true;
UPDATE public.menu_items SET order_count = FLOOR(RANDOM() * 20 + 1)::INTEGER WHERE is_popular = false;

-- Mettre à jour avg_rating
UPDATE public.menu_items SET avg_rating = (RANDOM() * 1.5 + 3.5)::DECIMAL(3,2);

-- Mettre à jour total_reviews des restaurants
UPDATE public.restaurants SET total_reviews = FLOOR(RANDOM() * 100 + 20)::INTEGER;

SELECT 'Seed: Données de test créées avec succès!' AS status;
SELECT '5 restaurants, 25 menu items, 5 promotions' AS details;
