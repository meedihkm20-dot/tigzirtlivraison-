-- Voir TOUTES les commandes avec leurs détails
SELECT 
    o.order_number,
    o.status,
    o.livreur_id IS NOT NULL as has_livreur,
    o.created_at,
    c.full_name as client,
    r.name as restaurant
FROM orders o
JOIN profiles c ON c.id = o.customer_id
JOIN restaurants r ON r.id = o.restaurant_id
ORDER BY o.created_at DESC;

-- Voir spécifiquement les commandes "ready" sans livreur
SELECT 
    'Commandes READY sans livreur' as probleme,
    o.order_number,
    o.status,
    o.total,
    o.created_at
FROM orders o
WHERE o.status = 'ready' AND o.livreur_id IS NULL;

-- Voir les commandes du client test
SELECT 
    'Commandes du client' as type,
    o.order_number,
    o.status,
    o.livreur_id IS NOT NULL as has_livreur
FROM orders o
JOIN auth.users u ON u.id = o.customer_id
WHERE u.email = 'client@test.com'
ORDER BY o.created_at DESC;
