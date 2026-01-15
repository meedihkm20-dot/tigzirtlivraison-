-- Diagnostic du compte admin Mehdi
-- Exécuter dans Supabase SQL Editor

-- 1. Vérifier si le compte existe
SELECT 
  id,
  email,
  email_confirmed_at,
  banned_until,
  deleted_at,
  created_at,
  last_sign_in_at
FROM auth.users
WHERE email = 'mehdihakkoum@gmail.com';

-- 2. Vérifier le profil
SELECT 
  id,
  role,
  full_name,
  is_active
FROM public.profiles
WHERE id = (SELECT id FROM auth.users WHERE email = 'mehdihakkoum@gmail.com');

-- 3. FIX COMPLET - Tout débloquer
UPDATE auth.users
SET 
  encrypted_password = crypt('epau2012', gen_salt('bf')),
  email_confirmed_at = now(),
  banned_until = NULL,
  deleted_at = NULL,
  updated_at = now()
WHERE email = 'mehdihakkoum@gmail.com';

UPDATE public.profiles
SET 
  is_active = true,
  updated_at = now()
WHERE id = (SELECT id FROM auth.users WHERE email = 'mehdihakkoum@gmail.com');

-- Vérification finale
SELECT 
  u.email,
  u.email_confirmed_at,
  u.banned_until,
  p.role,
  p.is_active
FROM auth.users u
LEFT JOIN public.profiles p ON u.id = p.id
WHERE u.email = 'mehdihakkoum@gmail.com';
