-- Tester la fonction verify_confirmation_code directement

-- 1. Voir la commande en cours
SELECT 
    id,
    order_number,
    status,
    confirmation_code,
    livreur_id
FROM orders 
WHERE order_number = 'DZ2601140001';

-- 2. Tester la fonction avec le bon code
SELECT verify_confirmation_code(
    (SELECT id FROM orders WHERE order_number = 'DZ2601140001'),
    '9137'
) as resultat;

-- 3. Vérifier après
SELECT 
    order_number,
    status,
    delivered_at
FROM orders 
WHERE order_number = 'DZ2601140001';
