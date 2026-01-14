# 📦 Installation Supabase CLI sur Windows

## Méthode Officielle: Scoop (Recommandé par Supabase)

### 1. Installer Scoop (si pas déjà installé)

Ouvre PowerShell et exécute:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
```

### 2. Installer Supabase CLI via Scoop
```bash
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
scoop install supabase
```

### 3. Vérifier l'installation
```bash
supabase --version
```

### 4. Mettre à jour (plus tard)
```bash
scoop update supabase
```

## ✅ Alternative: Utiliser npx (Sans installation)

Au lieu d'installer globalement, utilise **npx** pour exécuter Supabase CLI directement:

```bash
# Pas besoin d'installation!
npx supabase --version
npx supabase login
npx supabase link --project-ref pauqmhqriyjdqctvfvtt
npx supabase db push
```

### Avantages de npx:
- ✅ Pas d'installation nécessaire
- ✅ Toujours la dernière version
- ✅ Fonctionne sur tous les systèmes
- ✅ Pas de problèmes de permissions

## 🚀 Utilisation Rapide

### 1. Se connecter à Supabase
```bash
npx supabase login
```
Cela ouvrira ton navigateur pour te connecter.

### 2. Lier ton projet
```bash
npx supabase link --project-ref pauqmhqriyjdqctvfvtt
```

### 3. Appliquer les migrations
```bash
npx supabase db push
```

Cela appliquera automatiquement toutes les migrations dans `supabase/migrations/`.

## 📝 Alternative: Exécuter manuellement dans Supabase Dashboard

Si npx ne fonctionne pas, tu peux toujours:

1. Ouvrir https://supabase.com/dashboard/project/pauqmhqriyjdqctvfvtt
2. Aller dans **SQL Editor**
3. Copier le contenu de `supabase/migrations/011_fix_schema_bugs.sql`
4. Coller et exécuter

## 🔧 Commandes Utiles

```bash
# Voir la version
npx supabase --version

# Voir l'aide
npx supabase --help

# Voir les migrations
npx supabase migration list

# Créer une nouvelle migration
npx supabase migration new nom_migration

# Appliquer les migrations
npx supabase db push

# Réinitialiser la base de données locale
npx supabase db reset
```

## 📊 Workflow Complet

```bash
# 1. Se connecter
npx supabase login

# 2. Lier le projet
npx supabase link --project-ref pauqmhqriyjdqctvfvtt

# 3. Appliquer toutes les migrations
npx supabase db push

# 4. Vérifier que tout fonctionne
npx supabase db diff
```

## ⚠️ Notes Importantes

- **npx** télécharge et exécute la dernière version à chaque fois
- La première exécution peut prendre quelques secondes
- Tes identifiants Supabase seront sauvegardés localement
- Les migrations sont appliquées dans l'ordre (001, 002, 003, etc.)

## 🎯 Pour ce Projet

Exécute simplement:

```bash
npx supabase login
npx supabase link --project-ref pauqmhqriyjdqctvfvtt
npx supabase db push
```

Cela appliquera automatiquement:
- ✅ `009_fix_add_tip.sql`
- ✅ `010_update_test_passwords.sql`
- ✅ `011_fix_schema_bugs.sql`

Et tous les bugs seront corrigés! 🎉
