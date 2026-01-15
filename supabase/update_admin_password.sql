-- ============================================
-- Modifier le mot de passe de l'admin
-- ============================================
-- IMPORTANT: Exécuter ce script dans le SQL Editor de Supabase Dashboard
-- URL: https://supabase.com/dashboard/project/pauqmhqriyjdqctvfvtt/sql

-- Option 1: Modifier par email
-- Remplace 'admin@dzdelivery.com' par l'email de l'admin
-- Remplace 'NOUVEAU_MOT_DE_PASSE' par le nouveau mot de passe (min 6 caractères)

UPDATE auth.users
SET 
  encrypted_password = crypt('NOUVEAU_MOT_DE_PASSE', gen_salt('bf')),
  updated_at = now()
WHERE email = 'admin@dzdelivery.com';

-- Vérification
SELECT 
  id,
  email,
  created_at,
  updated_at,
  last_sign_in_at
FROM auth.users
WHERE email = 'admin@dzdelivery.com';


-- ============================================
-- Option 2: Modifier par ID utilisateur
-- ============================================
-- Si tu connais l'ID de l'admin

-- UPDATE auth.users
-- SET 
--   encrypted_password = crypt('NOUVEAU_MOT_DE_PASSE', gen_salt('bf')),
--   updated_at = now()
-- WHERE id = 'UUID_DE_L_ADMIN';


-- ============================================
-- Option 3: Lister tous les admins
-- ============================================
-- Pour trouver l'email/ID de l'admin

SELECT 
  u.id,
  u.email,
  p.full_name,
  p.role,
  u.created_at,
  u.last_sign_in_at
FROM auth.users u
JOIN public.profiles p ON u.id = p.id
WHERE p.role = 'admin'
ORDER BY u.created_at;


-- ============================================
-- Option 4: Réinitialiser et forcer changement
-- ============================================
-- Force l'utilisateur à changer son mot de passe à la prochaine connexion

-- UPDATE auth.users
-- SET 
--   encrypted_password = crypt('MotDePasseTemporaire123', gen_salt('bf')),
--   updated_at = now(),
--   confirmation_sent_at = now() -- Force reconfirmation
-- WHERE email = 'admin@dzdelivery.com';


-- ============================================
-- NOTES IMPORTANTES
-- ============================================
-- 1. Le mot de passe doit faire minimum 6 caractères
-- 2. Utilise un mot de passe fort (majuscules, minuscules, chiffres, symboles)
-- 3. Ne partage jamais ce script avec le mot de passe en clair
-- 4. Après modification, teste la connexion immédiatement
-- 5. Si l'admin ne peut plus se connecter, utilise ce script pour réinitialiser
