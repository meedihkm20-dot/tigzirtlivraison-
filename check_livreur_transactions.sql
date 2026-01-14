-- Voir toutes les transactions du livreur
SELECT 
    t.type,
    t.amount,
    t.status,
    t.created_at,
    o.order_number
FROM transactions t
LEFT JOIN orders o ON o.id = t.order_id
WHERE t.recipient_id = (
    SELECT user_id FROM livreurs WHERE id = (
        SELECT id FROM livreurs l
        JOIN auth.users u ON u.id = l.user_id
        WHERE u.email = 'livreur@test.com'
    )
)
ORDER BY t.created_at DESC;

-- Voir toutes les commandes livrées par ce livreur
SELECT 
    order_number,
    status,
    livreur_commission,
    delivered_at
FROM orders
WHERE livreur_id = (
    SELECT id FROM livreurs l
    JOIN auth.users u ON u.id = l.user_id
    WHERE u.email = 'livreur@test.com'
)
AND status = 'delivered'
ORDER BY delivered_at DESC;
