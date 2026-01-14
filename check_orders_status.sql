-- Vérifier l'état des commandes
SELECT 
    o.id,
    o.order_number,
    o.status,
    o.livreur_id,
    o.created_at,
    c.full_name as client,
    r.name as restaurant,
    CASE 
        WHEN o.livreur_id IS NULL THEN '❌ Pas de livreur'
        ELSE '✅ Livreur assigné'
    END as livreur_status
FROM orders o
JOIN profiles c ON c.id = o.customer_id
JOIN restaurants r ON r.id = o.restaurant_id
ORDER BY o.created_at DESC
LIMIT 10;

-- Voir les commandes que le livreur DEVRAIT voir
-- (status = 'pending' ET livreur_id = NULL)
SELECT 
    'Commandes disponibles pour livreurs' as type,
    o.order_number,
    o.status,
    o.livreur_id
FROM orders o
WHERE o.status = 'pending' AND o.livreur_id IS NULL;

-- Voir les commandes en cours pour un livreur
SELECT 
    'Commandes en cours du livreur' as type,
    o.order_number,
    o.status,
    l.id as livreur_id
FROM orders o
JOIN livreurs l ON l.id = o.livreur_id
JOIN auth.users u ON u.id = l.user_id
WHERE u.email = 'livreur@test.com'
  AND o.status IN ('confirmed', 'preparing', 'ready', 'picked_up', 'delivering');
