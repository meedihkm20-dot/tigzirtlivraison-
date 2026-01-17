-- Créer un code promo de test

-- Remplace RESTAURANT_ID par l'ID de ton restaurant
INSERT INTO promotions (
  restaurant_id,
  name,
  description,
  discount_type,
  discount_value,
  min_order_amount,
  code,
  is_active,
  ends_at
) VALUES (
  (SELECT id FROM restaurants WHERE owner_id = auth.uid() LIMIT 1),
  'Promo Test',
  'Réduction de test',
  'percentage',
  20,
  500,
  'TEST20',
  true,
  NOW() + INTERVAL '30 days'
);

-- Vérifier que c'est créé
SELECT * FROM promotions WHERE code = 'TEST20';
