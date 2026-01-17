-- Script pour générer des données de test pour l'app admin
-- À exécuter dans Supabase SQL Editor

-- 1. Créer un admin de test si n'existe pas
DO $$
DECLARE
  admin_user_id uuid;
BEGIN
  -- Vérifier si l'admin existe déjà
  SELECT id INTO admin_user_id FROM auth.users WHERE email = 'admin@test.com';
  
  IF admin_user_id IS NULL THEN
    -- Créer l'utilisateur admin dans auth.users
    INSERT INTO auth.users (
      instance_id,
      id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      created_at,
      updated_at,
      raw_app_meta_data,
      raw_user_meta_data,
      is_super_admin,
      confirmation_token,
      email_change,
      email_change_token_new,
      recovery_token
    ) VALUES (
      '00000000-0000-0000-0000-000000000000',
      gen_random_uuid(),
      'authenticated',
      'authenticated',
      'admin@test.com',
      crypt('admin123', gen_salt('bf')),
      now(),
      now(),
      now(),
      '{"provider":"email","providers":["email"]}',
      '{}',
      false,
      '',
      '',
      '',
      ''
    ) RETURNING id INTO admin_user_id;

    -- Créer le profil
    INSERT INTO profiles (id, full_name, phone, role, created_at)
    VALUES (admin_user_id, 'Admin Test', '+213555000000', 'admin', now());

    -- Créer l'entrée admin_users
    INSERT INTO admin_users (user_id, admin_role, permissions, created_at)
    VALUES (admin_user_id, 'super_admin', '["all"]', now());
  END IF;
END $$;

-- 2. Créer des restaurants de test
INSERT INTO restaurants (name, phone, address, latitude, longitude, is_verified, is_open, owner_id, created_at)
SELECT 
  'Restaurant ' || i,
  '+21355500' || LPAD(i::text, 4, '0'),
  'Adresse Restaurant ' || i || ', Tigzirt',
  36.8 + (random() * 0.1),
  4.1 + (random() * 0.1),
  true,
  (i % 3 != 0), -- 2/3 ouverts
  (SELECT id FROM profiles WHERE role = 'restaurant' LIMIT 1 OFFSET (i % 3)),
  now() - (i || ' days')::interval
FROM generate_series(1, 10) AS i
ON CONFLICT DO NOTHING;

-- 3. Créer des livreurs de test
INSERT INTO livreurs (user_id, vehicle_type, is_verified, is_online, is_available, created_at)
SELECT 
  (SELECT id FROM profiles WHERE role = 'livreur' LIMIT 1 OFFSET (i % 5)),
  CASE (i % 3) 
    WHEN 0 THEN 'moto'
    WHEN 1 THEN 'voiture'
    ELSE 'velo'
  END,
  true,
  (i % 2 = 0), -- 50% en ligne
  (i % 3 = 0), -- 33% disponibles
  now() - (i || ' days')::interval
FROM generate_series(1, 15) AS i
ON CONFLICT DO NOTHING;

-- 4. Créer des commandes de test avec tous les statuts
DO $$
DECLARE
  restaurant_id uuid;
  customer_id uuid;
  livreur_id uuid;
  order_id uuid;
  statuses text[] := ARRAY['pending', 'confirmed', 'preparing', 'ready', 'picked_up', 'delivering', 'delivered', 'cancelled'];
  status_val text;
  i int;
BEGIN
  -- Récupérer des IDs valides
  SELECT id INTO restaurant_id FROM restaurants WHERE is_verified = true LIMIT 1;
  SELECT id INTO customer_id FROM profiles WHERE role = 'customer' LIMIT 1;
  SELECT id INTO livreur_id FROM livreurs WHERE is_verified = true LIMIT 1;

  -- Créer 50 commandes avec différents statuts
  FOR i IN 1..50 LOOP
    status_val := statuses[(i % 8) + 1];
    
    INSERT INTO orders (
      order_number,
      customer_id,
      restaurant_id,
      livreur_id,
      status,
      subtotal,
      delivery_fee,
      service_fee,
      total,
      admin_commission,
      livreur_commission,
      restaurant_amount,
      delivery_address,
      delivery_latitude,
      delivery_longitude,
      payment_method,
      created_at,
      confirmed_at,
      prepared_at,
      picked_up_at,
      delivered_at
    ) VALUES (
      'ORD' || LPAD(i::text, 6, '0'),
      customer_id,
      restaurant_id,
      CASE WHEN status_val IN ('picked_up', 'delivering', 'delivered') THEN livreur_id ELSE NULL END,
      status_val,
      1000 + (random() * 3000)::int,
      200,
      50,
      1250 + (random() * 3000)::int,
      125 + (random() * 300)::int,
      100,
      1025 + (random() * 2700)::int,
      'Adresse test ' || i || ', Tigzirt',
      36.8 + (random() * 0.1),
      4.1 + (random() * 0.1),
      CASE (i % 2) WHEN 0 THEN 'cash' ELSE 'card' END,
      now() - (i || ' hours')::interval,
      CASE WHEN status_val != 'pending' THEN now() - ((i-1) || ' hours')::interval ELSE NULL END,
      CASE WHEN status_val IN ('preparing', 'ready', 'picked_up', 'delivering', 'delivered') THEN now() - ((i-2) || ' hours')::interval ELSE NULL END,
      CASE WHEN status_val IN ('picked_up', 'delivering', 'delivered') THEN now() - ((i-3) || ' hours')::interval ELSE NULL END,
      CASE WHEN status_val = 'delivered' THEN now() - ((i-4) || ' hours')::interval ELSE NULL END
    ) RETURNING id INTO order_id;

    -- Ajouter des items à la commande
    INSERT INTO order_items (order_id, name, quantity, price, notes)
    VALUES 
      (order_id, 'Pizza Margherita', 1 + (random() * 2)::int, 800, NULL),
      (order_id, 'Coca Cola', 1, 150, NULL);
  END LOOP;
END $$;

-- 5. Créer des audit logs de test
INSERT INTO admin_audit_logs (admin_id, admin_role, action, entity_type, entity_id, reason, created_at)
SELECT 
  (SELECT id FROM profiles WHERE role = 'admin' LIMIT 1),
  'super_admin',
  CASE (i % 5)
    WHEN 0 THEN 'verify_restaurant'
    WHEN 1 THEN 'verify_livreur'
    WHEN 2 THEN 'force_order_status'
    WHEN 3 THEN 'admin_cancel_order'
    ELSE 'update_setting'
  END,
  CASE (i % 5)
    WHEN 0 THEN 'restaurant'
    WHEN 1 THEN 'livreur'
    WHEN 2 THEN 'order'
    WHEN 3 THEN 'order'
    ELSE 'settings'
  END,
  gen_random_uuid(),
  'Action de test ' || i,
  now() - (i || ' hours')::interval
FROM generate_series(1, 30) AS i;

-- 6. Vérifier les données créées
SELECT 
  'Restaurants' as type, COUNT(*)::text as count FROM restaurants
UNION ALL
SELECT 'Livreurs', COUNT(*)::text FROM livreurs
UNION ALL
SELECT 'Commandes', COUNT(*)::text FROM orders
UNION ALL
SELECT 'Audit Logs', COUNT(*)::text FROM admin_audit_logs;

-- 7. Afficher la répartition des statuts de commandes
SELECT status, COUNT(*) as count
FROM orders
GROUP BY status
ORDER BY count DESC;
