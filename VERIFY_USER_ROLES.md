# 🔍 Vérification des Rôles Utilisateurs

## 📋 Scripts Disponibles

### 1. `check_user_roles.sql` - Vérification Complète
Ce script vérifie tous les utilisateurs et détecte les incohérences.

**Exécuter dans Supabase SQL Editor:**
```
https://supabase.com/dashboard/project/pauqmhqriyjdqctvfvtt/sql/new
```

**Ce qu'il fait:**
- ✅ Liste tous les utilisateurs avec leurs rôles
- ✅ Compte les utilisateurs par rôle
- ✅ Vérifie les restaurants liés aux utilisateurs
- ✅ Vérifie les livreurs liés aux utilisateurs
- ✅ Détecte les incohérences (rôle incorrect, entité manquante)

### 2. `create_test_users.sql` - Correction Automatique
Ce script corrige automatiquement tous les problèmes de rôles.

**Ce qu'il fait:**
- ✅ Vérifie les utilisateurs existants
- ✅ Crée les profils manquants avec le bon rôle
- ✅ Corrige les rôles incorrects
- ✅ Crée les entités liées (restaurant, livreur) si manquantes
- ✅ Affiche un rapport final

---

## 🎯 Rôles Attendus pour les Comptes Test

| Email | Rôle Attendu | Entité Liée | Status |
|-------|--------------|-------------|--------|
| admin@test.com | `admin` | - | Profil uniquement |
| client@test.com | `customer` | - | Profil uniquement |
| restaurant@test.com | `restaurant` | Restaurant | Profil + Restaurant |
| livreur@test.com | `livreur` | Livreur | Profil + Livreur |

---

## 🔧 Comment Vérifier et Corriger

### Étape 1: Vérifier l'État Actuel

1. **Ouvrir SQL Editor**
   ```
   https://supabase.com/dashboard/project/pauqmhqriyjdqctvfvtt/sql/new
   ```

2. **Copier et exécuter** `check_user_roles.sql`

3. **Analyser les résultats:**
   - Section 1: Liste des utilisateurs avec rôles
   - Section 2: Comptage par rôle
   - Section 3: Restaurants liés
   - Section 4: Livreurs liés
   - Section 5: Incohérences détectées
   - Section 6: Résumé

### Étape 2: Corriger les Problèmes (si nécessaire)

Si des incohérences sont détectées:

1. **Copier et exécuter** `create_test_users.sql`

2. **Le script va automatiquement:**
   - Créer les profils manquants
   - Corriger les rôles incorrects
   - Créer les restaurants manquants
   - Créer les livreurs manquants

3. **Vérifier le rapport final**

---

## 🐛 Problèmes Courants et Solutions

### Problème 1: Profil Manquant
**Symptôme:** Utilisateur existe dans `auth.users` mais pas dans `profiles`

**Solution:**
```sql
-- Le script create_test_users.sql crée automatiquement le profil
-- Ou manuellement:
INSERT INTO public.profiles (id, role, full_name, phone)
SELECT id, 'customer', 'Nom Test', '+213 555 000 000'
FROM auth.users WHERE email = 'email@test.com';
```

### Problème 2: Rôle Incorrect
**Symptôme:** Utilisateur a le mauvais rôle (ex: restaurant@test.com avec rôle 'customer')

**Solution:**
```sql
-- Le script create_test_users.sql corrige automatiquement
-- Ou manuellement:
UPDATE public.profiles 
SET role = 'restaurant'
WHERE id = (SELECT id FROM auth.users WHERE email = 'restaurant@test.com');
```

### Problème 3: Restaurant Manquant
**Symptôme:** Utilisateur avec rôle 'restaurant' mais pas de restaurant dans la table `restaurants`

**Solution:**
```sql
-- Le script create_test_users.sql crée automatiquement le restaurant
-- Ou manuellement: voir le script pour l'INSERT complet
```

### Problème 4: Livreur Manquant
**Symptôme:** Utilisateur avec rôle 'livreur' mais pas de livreur dans la table `livreurs`

**Solution:**
```sql
-- Le script create_test_users.sql crée automatiquement le livreur
-- Ou manuellement: voir le script pour l'INSERT complet
```

---

## 📊 Requêtes Rapides

### Voir tous les rôles
```sql
SELECT email, role FROM auth.users u
JOIN profiles p ON p.id = u.id
ORDER BY role;
```

### Compter par rôle
```sql
SELECT role, COUNT(*) FROM profiles GROUP BY role;
```

### Vérifier un utilisateur spécifique
```sql
SELECT u.email, p.role, p.full_name
FROM auth.users u
LEFT JOIN profiles p ON p.id = u.id
WHERE u.email = 'admin@test.com';
```

### Vérifier les restaurants
```sql
SELECT u.email, r.name, r.is_verified
FROM restaurants r
JOIN auth.users u ON u.id = r.owner_id;
```

### Vérifier les livreurs
```sql
SELECT u.email, l.vehicle_type, l.is_verified
FROM livreurs l
JOIN auth.users u ON u.id = l.user_id;
```

---

## ✅ Checklist de Vérification

- [ ] Tous les utilisateurs ont un profil dans `profiles`
- [ ] Tous les rôles sont corrects:
  - [ ] admin@test.com → `admin`
  - [ ] client@test.com → `customer`
  - [ ] restaurant@test.com → `restaurant`
  - [ ] livreur@test.com → `livreur`
- [ ] restaurant@test.com a un restaurant dans `restaurants`
- [ ] livreur@test.com a un livreur dans `livreurs`
- [ ] Le restaurant est vérifié (`is_verified = true`)
- [ ] Le livreur est vérifié (`is_verified = true`)

---

## 🔐 Sécurité

**Important:** Ces comptes sont pour les tests uniquement!

- ⚠️ Ne jamais utiliser en production
- ⚠️ Changer les mots de passe avant déploiement
- ⚠️ Supprimer les comptes test en production

---

## 📚 Documentation Liée

- **COMPTES_TEST.md** - Identifiants des comptes test
- **supabase/migrations/010_update_test_passwords.sql** - Mise à jour des mots de passe
- **supabase/migrations/000_complete_schema.sql** - Définition du type `user_role`

---

## 🎯 Prochaines Actions

1. **Exécuter** `check_user_roles.sql` pour vérifier l'état actuel
2. **Si problèmes détectés**, exécuter `create_test_users.sql`
3. **Vérifier** que tous les comptes fonctionnent dans l'app
4. **Tester** la connexion avec chaque rôle

---

**Créé par**: Kiro AI  
**Date**: 14 Janvier 2026  
**Version**: 1.0
