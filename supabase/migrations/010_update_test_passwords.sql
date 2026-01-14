-- ============================================
-- MISE À JOUR DES MOTS DE PASSE DES COMPTES TEST
-- ============================================
-- Nouveaux mots de passe plus simples et uniformes

-- Fonction pour mettre à jour un mot de passe utilisateur
CREATE OR REPLACE FUNCTION update_user_password(user_email TEXT, new_password TEXT)
RETURNS BOOLEAN AS $$
DECLARE
  user_id UUID;
BEGIN
  -- Récupérer l'ID utilisateur
  SELECT id INTO user_id FROM auth.users WHERE email = user_email;
  
  IF user_id IS NULL THEN
    RAISE NOTICE 'Utilisateur % non trouvé', user_email;
    RETURN FALSE;
  END IF;
  
  -- Mettre à jour le mot de passe (hash bcrypt)
  UPDATE auth.users 
  SET 
    encrypted_password = crypt(new_password, gen_salt('bf')),
    updated_at = NOW()
  WHERE id = user_id;
  
  RAISE NOTICE 'Mot de passe mis à jour pour %', user_email;
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Mettre à jour les mots de passe des comptes test
-- Nouveau mot de passe uniforme: "test12345"

SELECT update_user_password('admin@test.com', 'test12345');
SELECT update_user_password('client@test.com', 'test12345');
SELECT update_user_password('restaurant@test.com', 'test12345');
SELECT update_user_password('livreur@test.com', 'test12345');

-- Supprimer la fonction temporaire
DROP FUNCTION IF EXISTS update_user_password(TEXT, TEXT);

-- ============================================
-- RÉCAPITULATIF DES COMPTES TEST MISE À JOUR
-- ============================================

SELECT 
  'COMPTES TEST MISE À JOUR' as info,
  'Nouveau mot de passe: test12345' as password_info;

SELECT 
  email,
  (SELECT role FROM profiles WHERE id = auth.users.id) as role,
  'test12345' as nouveau_mot_de_passe,
  created_at
FROM auth.users 
WHERE email IN ('admin@test.com', 'client@test.com', 'restaurant@test.com', 'livreur@test.com')
ORDER BY email;

SELECT 'Migration 010 exécutée avec succès!' AS status;