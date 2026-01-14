-- ============================================
-- VÉRIFIER LE PROCESSUS DE LIVRAISON
-- ============================================

-- 1. Voir l'état de la commande en cours
SELECT 
    'État de la commande' as section,
    o.order_number,
    o.status,
    o.confirmation_code,
    o.created_at,
    o.confirmed_at,
    o.prepared_at,
    o.picked_up_at,
    o.delivered_at,
    o.livreur_commission,
    l.user_id as livreur_user_id
FROM orders o
LEFT JOIN livreurs l ON l.id = o.livreur_id
WHERE o.order_number = 'DZ2601140001';

-- 2. Vérifier les transactions du livreur
SELECT 
    'Transactions livreur' as section,
    t.type,
    t.amount,
    t.status,
    t.created_at,
    o.order_number
FROM transactions t
LEFT JOIN orders o ON o.id = t.order_id
WHERE t.recipient_id = (
    SELECT user_id FROM livreurs WHERE id = (
        SELECT livreur_id FROM orders WHERE order_number = 'DZ2601140001'
    )
)
ORDER BY t.created_at DESC;

-- 3. Vérifier les transactions du restaurant
SELECT 
    'Transactions restaurant' as section,
    t.type,
    t.amount,
    t.status,
    t.created_at,
    o.order_number
FROM transactions t
LEFT JOIN orders o ON o.id = t.order_id
WHERE t.recipient_id = (
    SELECT owner_id FROM restaurants WHERE id = (
        SELECT restaurant_id FROM orders WHERE order_number = 'DZ2601140001'
    )
)
ORDER BY t.created_at DESC;

-- 4. Vérifier le statut du livreur
SELECT 
    'Statut livreur' as section,
    l.is_available,
    l.is_online,
    l.total_deliveries,
    l.total_earnings,
    p.full_name
FROM livreurs l
JOIN profiles p ON p.id = l.user_id
JOIN auth.users u ON u.id = l.user_id
WHERE u.email = 'livreur@test.com';

-- 5. Vérifier si un avis a été laissé
SELECT 
    'Avis client' as section,
    r.restaurant_rating,
    r.livreur_rating,
    r.comment,
    r.created_at
FROM reviews r
WHERE r.order_id = (SELECT id FROM orders WHERE order_number = 'DZ2601140001');
