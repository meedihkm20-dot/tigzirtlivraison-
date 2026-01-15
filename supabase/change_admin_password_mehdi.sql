-- ============================================
-- Modifier le mot de passe de l'admin Mehdi
-- ============================================
-- Email: mehdihakkoum@gmail.com
-- Nouveau mot de passe: epau2012
-- 
-- EXÉCUTER dans Supabase SQL Editor:
-- https://supabase.com/dashboard/project/pauqmhqriyjdqctvfvtt/sql

-- Modifier le mot de passe
UPDATE auth.users
SET 
  encrypted_password = crypt('epau2012', gen_salt('bf')),
  updated_at = now()
WHERE email = 'mehdihakkoum@gmail.com';

-- Vérification
SELECT 
  id,
  email,
  created_at,
  updated_at,
  last_sign_in_at,
  email_confirmed_at
FROM auth.users
WHERE email = 'mehdihakkoum@gmail.com';

-- Vérifier le profil admin
SELECT 
  u.id,
  u.email,
  p.full_name,
  p.role,
  p.phone,
  p.is_active
FROM auth.users u
LEFT JOIN public.profiles p ON u.id = p.id
WHERE u.email = 'mehdihakkoum@gmail.com';
