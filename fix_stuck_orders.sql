-- ============================================
-- FIX: Commandes bloquées sans livreur
-- ============================================

-- 1. Voir les commandes problématiques
SELECT 
    'Commandes bloquées' as probleme,
    o.order_number,
    o.status,
    o.livreur_id,
    o.created_at
FROM orders o
WHERE o.livreur_id IS NULL 
  AND o.status NOT IN ('pending', 'cancelled', 'delivered');

-- 2. Remettre ces commandes en "pending" pour que les livreurs puissent les accepter
UPDATE orders 
SET 
    status = 'pending',
    confirmed_at = NULL,
    prepared_at = NULL,
    picked_up_at = NULL
WHERE livreur_id IS NULL 
  AND status NOT IN ('pending', 'cancelled', 'delivered');

-- 3. Vérifier après correction
SELECT 
    'Après correction' as status,
    o.order_number,
    o.status,
    o.livreur_id IS NULL as sans_livreur
FROM orders o
WHERE o.status = 'pending'
ORDER BY o.created_at DESC;

-- 4. Message
SELECT '✅ Commandes remises en pending. Rafraîchis l''app livreur!' as message;
