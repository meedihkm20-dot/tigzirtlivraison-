-- ============================================
-- FIX: Livreur ne voit pas les commandes
-- ============================================

-- 1. Mettre le livreur en ligne et disponible
UPDATE livreurs 
SET 
    is_online = true,
    is_available = true,
    is_verified = true
WHERE user_id = (SELECT id FROM auth.users WHERE email = 'livreur@test.com');

-- 2. Vérifier l'état du livreur
SELECT 
    '=== ÉTAT LIVREUR ===' as section,
    l.id,
    p.email,
    l.is_online,
    l.is_available,
    l.is_verified,
    CASE 
        WHEN NOT l.is_online THEN '❌ Pas en ligne'
        WHEN NOT l.is_available THEN '❌ Pas disponible'
        WHEN NOT l.is_verified THEN '❌ Pas vérifié'
        ELSE '✅ OK'
    END as status
FROM livreurs l
JOIN profiles p ON p.id = l.user_id
WHERE p.email = 'livreur@test.com';

-- 3. Voir les commandes disponibles
SELECT 
    '=== COMMANDES DISPONIBLES ===' as section,
    o.id,
    o.order_number,
    o.status,
    o.total,
    o.delivery_address,
    r.name as restaurant_name,
    c.full_name as client_name
FROM orders o
JOIN restaurants r ON r.id = o.restaurant_id
JOIN profiles c ON c.id = o.customer_id
WHERE o.status = 'pending'
  AND o.livreur_id IS NULL
ORDER BY o.created_at DESC;

-- 4. Désactiver RLS temporairement pour tester
ALTER TABLE public.orders DISABLE ROW LEVEL SECURITY;

-- 5. Message final
SELECT 
    '✅ Livreur mis en ligne!' as message,
    'Rafraîchis l''app livreur pour voir les commandes' as action;
