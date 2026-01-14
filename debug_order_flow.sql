-- ============================================
-- DEBUG: Pourquoi le livreur ne voit pas la commande?
-- ============================================

-- 1. Voir TOUTES les commandes
SELECT 
    '=== TOUTES LES COMMANDES ===' as section,
    o.id,
    o.order_number,
    o.status,
    o.created_at,
    cp.full_name as client_name,
    r.name as restaurant_name,
    o.livreur_id,
    CASE 
        WHEN o.livreur_id IS NULL THEN '⚠️ Pas de livreur assigné'
        ELSE '✅ Livreur assigné'
    END as livreur_status
FROM orders o
JOIN profiles cp ON cp.id = o.customer_id
JOIN restaurants r ON r.id = o.restaurant_id
ORDER BY o.created_at DESC
LIMIT 10;

-- 2. Voir les commandes que le livreur DEVRAIT voir
-- (status = 'pending' ET livreur_id = NULL)
SELECT 
    '=== COMMANDES DISPONIBLES POUR LIVREURS ===' as section,
    o.id,
    o.order_number,
    o.status,
    o.total,
    r.name as restaurant_name,
    r.address as restaurant_address
FROM orders o
JOIN restaurants r ON r.id = o.restaurant_id
WHERE o.status = 'pending' 
  AND o.livreur_id IS NULL
ORDER BY o.created_at DESC;

-- 3. Voir l'ID du livreur test
SELECT 
    '=== LIVREUR TEST ===' as section,
    l.id as livreur_id,
    l.user_id,
    u.email,
    l.is_verified,
    l.is_available,
    l.is_online
FROM livreurs l
JOIN auth.users u ON u.id = l.user_id
WHERE u.email = 'livreur@test.com';

-- 4. Vérifier les politiques RLS sur orders
SELECT 
    '=== POLITIQUES RLS ORDERS ===' as section,
    policyname,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'orders';

-- 5. Tester la requête que l'app utilise
-- (getAvailableOrders dans supabase_service.dart)
SELECT 
    '=== TEST REQUÊTE APP ===' as section,
    o.*,
    r.name as restaurant_name,
    cp.full_name as customer_name
FROM orders o
JOIN restaurants r ON r.id = o.restaurant_id
JOIN profiles cp ON cp.id = o.customer_id
WHERE o.status = 'pending'
  AND o.livreur_id IS NULL
ORDER BY o.created_at DESC;
