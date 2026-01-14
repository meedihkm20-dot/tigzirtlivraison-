# 📘 Guide Complet Supabase CLI - DZ Delivery

**Date**: 14 Janvier 2026  
**Projet**: Tigzirt Livraison  
**Supabase Project ID**: pauqmhqriyjdqctvfvtt

---

## ✅ État Actuel

### Migrations Appliquées
Toutes les migrations (000-012) sont maintenant synchronisées entre local et remote:

```
✅ 000_complete_schema.sql
✅ 001_initial_schema.sql
✅ 002_indexes_and_rls.sql
✅ 003_functions_and_triggers.sql
✅ 004_new_order_flow.sql
✅ 005_enhanced_features.sql
✅ 006_complete_system_upgrade.sql
✅ 007_chat_and_extras.sql
✅ 008_missing_functions.sql
✅ 009_fix_add_tip.sql
✅ 010_update_test_passwords.sql
✅ 011_fix_schema_bugs.sql (20 bugs corrigés)
✅ 012_optimize_indexes.sql (Index optimisés)
```

### Prochaine Étape: Créer les Données de Test

---

## 🎯 Comment Exécuter le Seed (Données de Test)

### Option 1: Via Supabase Dashboard (Recommandé)

1. **Ouvrir le SQL Editor**
   - Aller sur: https://supabase.com/dashboard/project/pauqmhqriyjdqctvfvtt/sql/new
   - Ou: Dashboard → SQL Editor → New Query

2. **Copier le contenu du fichier**
   - Ouvrir: `supabase/seed.sql`
   - Copier tout le contenu (Ctrl+A, Ctrl+C)

3. **Coller et Exécuter**
   - Coller dans le SQL Editor
   - Cliquer sur "Run" (ou F5)
   - Attendre le message de succès

4. **Vérifier les Résultats**
   ```sql
   -- Vérifier les restaurants créés
   SELECT COUNT(*) FROM restaurants;
   -- Devrait retourner: 6 (1 existant + 5 nouveaux)
   
   -- Vérifier les menu items
   SELECT COUNT(*) FROM menu_items;
   -- Devrait retourner: 28 (3 existants + 25 nouveaux)
   
   -- Vérifier les promotions
   SELECT COUNT(*) FROM promotions;
   -- Devrait retourner: 5
   ```

### Option 2: Via psql (Avancé)

Si vous avez psql installé:

```bash
# Obtenir l'URL de connexion
supabase status

# Exécuter le seed
psql "postgresql://postgres:[PASSWORD]@db.[PROJECT_REF].supabase.co:5432/postgres" -f supabase/seed.sql
```

---

## 📊 Commandes Supabase CLI Utiles

### Gestion des Migrations

```bash
# Lister toutes les migrations
supabase migration list

# Créer une nouvelle migration
supabase migration new nom_de_la_migration

# Appliquer les migrations en attente
supabase db push

# Réparer l'historique des migrations
supabase migration repair --status applied 000
```

### Inspection de la Base de Données

```bash
# Statistiques des tables
supabase inspect db table-stats

# Statistiques des index
supabase inspect db index-stats

# Voir les index inutilisés
supabase inspect db index-stats | findstr "true"

# Dump du schéma
supabase db dump --schema public -f backup.sql

# Dump des données
supabase db dump --data-only -f data.sql
```

### Gestion du Projet

```bash
# Lister les projets
supabase projects list

# Voir le statut
supabase status

# Se connecter à un projet
supabase link --project-ref pauqmhqriyjdqctvfvtt
```

---

## 🔧 Résolution de Problèmes

### Problème: "Migration history does not match"

**Solution**: Réparer l'historique
```bash
supabase migration repair --status applied 000
supabase migration repair --status applied 001
# ... pour chaque migration
```

### Problème: "Function does not exist"

**Cause**: Extension PostgreSQL manquante  
**Solution**: Activer l'extension dans Supabase Dashboard
```sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";
```

### Problème: "Cannot drop index because constraint requires it"

**Cause**: L'index est utilisé par une contrainte unique  
**Solution**: Ne pas supprimer cet index, il est nécessaire

---

## 📈 Statistiques Actuelles de la Base

### Tables Principales
| Table | Lignes | Taille | Status |
|-------|--------|--------|--------|
| restaurants | 1 | 16 KB | ⚠️ Besoin de seed |
| menu_items | 3 | 16 KB | ⚠️ Besoin de seed |
| livreurs | 1 | 16 KB | ⚠️ Besoin de seed |
| orders | 1 | 16 KB | ⚠️ Besoin de seed |
| profiles | 4 | 16 KB | ✅ OK |

### Index
- **Total**: 89 index
- **Utilisés**: 72 index
- **Inutilisés**: 17 index (19%)
- **Optimisés**: ✅ Migration 012 appliquée

---

## 🎯 Prochaines Actions

### 1. Exécuter le Seed (Urgent)
```sql
-- Fichier: supabase/seed.sql
-- Créera:
-- - 5 nouveaux restaurants à Tigzirt
-- - 25 menu items (5 par restaurant)
-- - 5 promotions actives
```

### 2. Tester l'Application
- ✅ Connexion admin: admin@test.com / test12345
- ✅ Connexion client: client@test.com / test12345
- ✅ Connexion restaurant: restaurant@test.com / test12345
- ✅ Connexion livreur: livreur@test.com / test12345

### 3. Vérifier les Fonctions SQL
```sql
-- Tester get_nearby_restaurants
SELECT * FROM get_nearby_restaurants(36.8869, 4.1260, 10);

-- Tester get_all_restaurants (admin)
SELECT * FROM get_all_restaurants(10, 0);

-- Tester get_pending_verifications (admin)
SELECT * FROM get_pending_verifications();
```

---

## 📝 Notes Importantes

### Mots de Passe des Comptes Test
Tous les comptes utilisent le même mot de passe: **test12345**

### Localisation
Tous les restaurants de test sont situés à **Tigzirt** (36.88°N, 4.12°E)

### Promotions
Les promotions créées sont valides pour 7-90 jours

### Index Optimisés
- ✅ Supprimé 15 index inutilisés
- ✅ Créé 4 index composites optimisés
- ✅ Utilisé des partial indexes pour meilleures performances

---

## 🔗 Liens Utiles

- **Dashboard**: https://supabase.com/dashboard/project/pauqmhqriyjdqctvfvtt
- **SQL Editor**: https://supabase.com/dashboard/project/pauqmhqriyjdqctvfvtt/sql/new
- **Table Editor**: https://supabase.com/dashboard/project/pauqmhqriyjdqctvfvtt/editor
- **Auth**: https://supabase.com/dashboard/project/pauqmhqriyjdqctvfvtt/auth/users
- **Logs**: https://supabase.com/dashboard/project/pauqmhqriyjdqctvfvtt/logs/explorer

---

**Créé par**: Kiro AI  
**Dernière mise à jour**: 14 Janvier 2026
