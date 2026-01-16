# 🔧 DIAGNOSTIC & SOLUTION - Problème Login Restaurant

## 📋 PROBLÈMES IDENTIFIÉS

### 1. **Login échoue : "Email ou mot de passe incorrect"**
- **Compte** : `restaurant@test.com` / `test123456`
- **Cause possible** :
  - ❌ Utilisateur n'existe pas dans `auth.users`
  - ❌ Mot de passe incorrect
  - ❌ Email non confirmé
  - ❌ Profil manquant dans `profiles`
  - ❌ Restaurant non créé dans `restaurants`

### 2. **App bloquée au chargement après redémarrage**
- **Cause** : Exception non gérée dans `splash_screen.dart`
- **Scénario** :
  1. Login échoue mais session Supabase reste active
  2. Au redémarrage, `isLoggedIn = true`
  3. `getUserRole()` ou `isRestaurantVerified()` lance une exception
  4. Pas de `try-catch` → app bloquée

---

## ✅ SOLUTIONS APPLIQUÉES

### **Fix 1 : Gestion d'erreur dans Splash Screen**

**Fichier** : `apps/dz_delivery/lib/features/auth/presentation/splash_screen.dart`

```dart
Future<void> _checkAuth() async {
  try {
    // ... logique existante ...
    
    final role = await SupabaseService.getUserRole();
    
    if (role == null) {
      // ✅ Profil introuvable → déconnecter
      await SupabaseService.signOut();
      Navigator.pushReplacementNamed(context, AppRouter.login);
      return;
    }
    
  } catch (e) {
    // ✅ En cas d'erreur → déconnecter et retourner au login
    debugPrint('Erreur splash: $e');
    await SupabaseService.signOut();
    Navigator.pushReplacementNamed(context, AppRouter.login);
  }
}
```

**Résultat** : L'app ne reste plus bloquée, elle retourne au login en cas d'erreur.

---

### **Fix 2 : Gestion d'erreur dans SupabaseService**

**Fichier** : `apps/dz_delivery/lib/core/services/supabase_service.dart`

```dart
static Future<String?> getUserRole() async {
  try {
    if (currentUser == null) return null;
    // ✅ Utiliser maybeSingle() au lieu de single()
    final profile = await client
      .from('profiles')
      .select('role')
      .eq('id', currentUser!.id)
      .maybeSingle();
    return profile?['role'] as String?;
  } catch (e) {
    debugPrint('Erreur getUserRole: $e');
    return null;
  }
}
```

**Changements** :
- ✅ `.single()` → `.maybeSingle()` (ne lance pas d'exception si 0 résultat)
- ✅ `try-catch` pour capturer les erreurs réseau
- ✅ Retourne `null` en cas d'erreur

---

## 🔍 DIAGNOSTIC SQL - Vérifier le compte restaurant

**Fichier créé** : `debug_restaurant_login.sql`

### **Étape 1 : Vérifier si l'utilisateur existe**

```sql
-- Exécuter dans Supabase Dashboard > SQL Editor
SELECT 
    id,
    email,
    email_confirmed_at,
    created_at
FROM auth.users
WHERE email = 'restaurant@test.com';
```

**Résultats possibles** :
- ✅ **Utilisateur trouvé** → Passer à l'étape 2
- ❌ **Aucun résultat** → Créer l'utilisateur (voir section "Créer le compte")

---

### **Étape 2 : Vérifier le profil**

```sql
SELECT 
    id,
    role,
    full_name,
    is_active
FROM profiles
WHERE id IN (SELECT id FROM auth.users WHERE email = 'restaurant@test.com');
```

**Vérifications** :
- ✅ `role = 'restaurant'`
- ✅ `is_active = true`

---

### **Étape 3 : Vérifier le restaurant**

```sql
SELECT 
    id,
    owner_id,
    name,
    is_verified,
    is_open
FROM restaurants
WHERE owner_id IN (SELECT id FROM auth.users WHERE email = 'restaurant@test.com');
```

**Vérifications** :
- ✅ `is_verified = true` (sinon → écran "En attente d'approbation")
- ✅ `is_open = true` (sinon → restaurant fermé)

---

## 🛠️ CRÉER LE COMPTE RESTAURANT (si n'existe pas)

### **Option 1 : Via l'app (Inscription)**

1. Ouvrir l'app `dz_delivery`
2. Cliquer "S'inscrire"
3. Choisir "Restaurant"
4. Remplir le formulaire
5. **Important** : Le restaurant sera créé avec `is_verified = false`

### **Option 2 : Via SQL (Compte de test)**

```sql
-- 1. Générer un UUID
SELECT gen_random_uuid(); -- Copier le résultat

-- 2. Créer l'utilisateur dans auth.users
-- ⚠️ À exécuter dans Supabase Dashboard (accès admin requis)
INSERT INTO auth.users (
    id,
    email,
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at,
    raw_app_meta_data,
    raw_user_meta_data,
    is_super_admin,
    role
) VALUES (
    'REMPLACER_PAR_UUID', -- UUID généré à l'étape 1
    'restaurant@test.com',
    crypt('test123456', gen_salt('bf')),
    NOW(),
    NOW(),
    NOW(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Restaurant Test","phone":"0555000001","role":"restaurant"}',
    false,
    'authenticated'
);

-- 3. Créer le profil
INSERT INTO profiles (id, role, full_name, phone, is_active)
VALUES (
    'REMPLACER_PAR_UUID', -- Même UUID
    'restaurant',
    'Restaurant Test',
    '0555000001',
    true
);

-- 4. Créer le restaurant
INSERT INTO restaurants (
    owner_id,
    name,
    address,
    phone,
    latitude,
    longitude,
    is_verified,
    is_open
) VALUES (
    'REMPLACER_PAR_UUID', -- Même UUID
    'Restaurant Test',
    'Tigzirt Centre',
    '0555000001',
    36.8869,
    4.1260,
    true, -- ✅ VÉRIFIÉ
    true  -- ✅ OUVERT
);
```

---

## 🔧 ACTIVER UN RESTAURANT EXISTANT

Si le restaurant existe mais n'est pas vérifié :

```sql
-- Activer le restaurant
UPDATE restaurants
SET 
    is_verified = true,
    is_open = true
WHERE owner_id IN (SELECT id FROM auth.users WHERE email = 'restaurant@test.com');

-- Activer le profil
UPDATE profiles
SET is_active = true
WHERE id IN (SELECT id FROM auth.users WHERE email = 'restaurant@test.com');
```

---

## 🔐 RÉINITIALISER LE MOT DE PASSE

### **Option 1 : Via Supabase Dashboard**

1. Aller dans **Authentication > Users**
2. Chercher `restaurant@test.com`
3. Cliquer sur l'utilisateur
4. Cliquer **"Send password reset email"**
5. Ou cliquer **"Reset password"** pour définir un nouveau mot de passe

### **Option 2 : Via l'app**

1. Écran de login
2. Cliquer "Mot de passe oublié ?"
3. Entrer `restaurant@test.com`
4. Suivre le lien dans l'email

---

## ✅ VÉRIFICATION FINALE

Après avoir appliqué les corrections, exécuter :

```sql
SELECT 
    u.email,
    u.email_confirmed_at,
    p.role,
    p.full_name,
    p.is_active,
    r.name as restaurant_name,
    r.is_verified,
    r.is_open
FROM auth.users u
LEFT JOIN profiles p ON p.id = u.id
LEFT JOIN restaurants r ON r.owner_id = u.id
WHERE u.email = 'restaurant@test.com';
```

**Résultat attendu** :
```
email                  | restaurant@test.com
email_confirmed_at     | 2025-01-16 ... (non NULL)
role                   | restaurant
full_name              | Restaurant Test
is_active              | true
restaurant_name        | Restaurant Test
is_verified            | true
is_open                | true
```

---

## 📱 TESTER LA CONNEXION

1. **Fermer complètement l'app** (swipe up dans le multitâche)
2. **Rouvrir l'app**
3. **Se connecter** :
   - Email : `restaurant@test.com`
   - Mot de passe : `test123456`
4. **Résultat attendu** :
   - ✅ Connexion réussie
   - ✅ Redirection vers `RestaurantHomeScreen`
   - ✅ Voir les commandes en attente

---

## 🐛 SI LE PROBLÈME PERSISTE

### **Logs à vérifier**

```bash
# Android
adb logcat | grep -i "flutter\|supabase\|error"

# Ou dans l'app
# Chercher les messages debugPrint dans la console
```

### **Vérifier la connexion Supabase**

```dart
// Dans l'app, ajouter temporairement :
print('Supabase URL: ${SupabaseService.client.supabaseUrl}');
print('Is logged in: ${SupabaseService.isLoggedIn}');
print('Current user: ${SupabaseService.currentUser?.email}');
```

### **Vider le cache de l'app**

```bash
# Android
adb shell pm clear com.dzdelivery.app

# Ou dans les paramètres Android :
# Paramètres > Apps > DZ Delivery > Stockage > Vider le cache
```

---

## 📝 RÉSUMÉ DES CHANGEMENTS

### **Fichiers modifiés** :
1. ✅ `apps/dz_delivery/lib/features/auth/presentation/splash_screen.dart`
   - Ajout `try-catch` dans `_checkAuth()`
   - Gestion du cas `role == null`

2. ✅ `apps/dz_delivery/lib/core/services/supabase_service.dart`
   - `getUserRole()` : `.single()` → `.maybeSingle()` + `try-catch`
   - `getProfile()` : `.single()` → `.maybeSingle()` + `try-catch`

### **Fichiers créés** :
1. ✅ `debug_restaurant_login.sql` - Requêtes de diagnostic
2. ✅ `DIAGNOSTIC_RESTAURANT_LOGIN.md` - Ce document

---

## 🚀 PROCHAINES ÉTAPES

1. **Pousser les changements sur GitHub**
2. **Exécuter les requêtes SQL** dans Supabase Dashboard
3. **Tester la connexion** avec le compte restaurant
4. **Vérifier que l'app ne reste plus bloquée** au redémarrage

---

**Date** : 2025-01-16  
**Status** : ✅ Corrections appliquées, en attente de test
