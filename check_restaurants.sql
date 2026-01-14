-- Vérifier les restaurants disponibles
SELECT 
    id,
    name,
    address,
    is_verified,
    is_open,
    latitude,
    longitude,
    cuisine_type
FROM restaurants
ORDER BY created_at DESC;

-- Vérifier les menu items
SELECT 
    r.name as restaurant,
    COUNT(mi.id) as nb_items
FROM restaurants r
LEFT JOIN menu_items mi ON mi.restaurant_id = r.id
GROUP BY r.id, r.name;

-- Tester la fonction get_nearby_restaurants
SELECT * FROM get_nearby_restaurants(
    36.8869,  -- Latitude Tigzirt
    4.1260,   -- Longitude Tigzirt
    10        -- Rayon 10km
);
