-- Vérifier quel restaurant est dans le panier du client
-- Et lier le code promo à ce restaurant

-- 1. Voir tous les restaurants
SELECT id, name FROM restaurants ORDER BY name;

-- 2. Mettre à jour le code promo avec le bon restaurant_id
-- Remplace 'RESTAURANT_ID' par l'ID du restaurant Pizza Tigzirt
-- UPDATE promotions
-- SET restaurant_id = 'RESTAURANT_ID'
-- WHERE code = 'TEST20';
