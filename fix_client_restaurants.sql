-- ============================================
-- FIX: Client ne voit pas les restaurants
-- ============================================

-- 1. Désactiver RLS sur restaurants
ALTER TABLE public.restaurants DISABLE ROW LEVEL SECURITY;

-- 2. S'assurer que le restaurant test est visible
UPDATE restaurants 
SET 
    is_verified = true,
    is_open = true,
    latitude = 36.8869,
    longitude = 4.1260
WHERE name = 'Restaurant Test';

-- 3. Créer quelques restaurants supplémentaires pour tester
INSERT INTO restaurants (
    owner_id, name, description, phone, address,
    latitude, longitude, cuisine_type, 
    opening_time, closing_time,
    min_order_amount, delivery_fee, avg_prep_time,
    is_open, is_verified, rating
) VALUES
(
    (SELECT id FROM auth.users WHERE email = 'restaurant@test.com'),
    'Pizza Palace',
    'Les meilleures pizzas de Tigzirt',
    '+213 555 100 200',
    'Centre Ville, Tigzirt',
    36.8870,
    4.1265,
    'Italienne',
    '11:00'::time,
    '23:00'::time,
    500,
    150,
    25,
    true,
    true,
    4.5
),
(
    (SELECT id FROM auth.users WHERE email = 'restaurant@test.com'),
    'Tacos Express',
    'Tacos et fast food',
    '+213 555 100 300',
    'Rue Principale, Tigzirt',
    36.8865,
    4.1255,
    'Fast Food',
    '10:00'::time,
    '22:00'::time,
    300,
    100,
    15,
    true,
    true,
    4.2
)
ON CONFLICT DO NOTHING;

-- 4. Vérifier les restaurants visibles
SELECT 
    id,
    name,
    address,
    is_verified,
    is_open,
    latitude,
    longitude,
    delivery_fee,
    rating
FROM restaurants
WHERE is_verified = true AND is_open = true;

-- 5. Tester la fonction get_nearby_restaurants
SELECT 
    id,
    name,
    distance_km
FROM get_nearby_restaurants(36.8869, 4.1260, 10)
ORDER BY distance_km;
