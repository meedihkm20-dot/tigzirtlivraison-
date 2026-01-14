# ✅ CORRECTION DU PROBLÈME D'AUTHENTIFICATION

## Problème Identifié
L'application tournait en boucle à la connexion car le token était révoqué immédiatement après la connexion.

**Cause**: Le log d'audit montrait `"action":"token_revoked"` pour `livreur@test.com`. Le code de login appelait `getUserRole()` qui retournait `null` si le profil n'existait pas, puis appelait `signOut()` ce qui révoquait le token.

## Corrections Effectuées

### 1. Migration 015 - Correction des profils utilisateurs
✅ **Appliquée avec succès**

La migration garantit que:
- Tous les utilisateurs test ont un profil avec le bon rôle
- Le restaurant test existe et est vérifié
- Le livreur test existe et est vérifié

### 2. Code de login corrigé
✅ **Modifié**: `apps/dz_delivery/lib/features/auth/presentation/login_screen.dart`

Changements:
- Gestion du cas où `role == null` avec message d'erreur clair
- Pas de boucle infinie, l'utilisateur voit un message explicite
- Gestion du cas `admin` avec message approprié
- Gestion du cas `default` pour les rôles inconnus

## Comptes Test Disponibles

Tous les comptes utilisent le mot de passe: `test12345`

| Email | Rôle | Statut | Entité |
|-------|------|--------|--------|
| admin@test.com | admin | ✅ Actif | - |
| client@test.com | customer | ✅ Actif | - |
| restaurant@test.com | restaurant | ✅ Vérifié | Restaurant Test |
| livreur@test.com | livreur | ✅ Vérifié | Livreur Test |

## Prochaines Étapes

### 1. Rebuild l'APK
```bash
cd apps/dz_delivery
flutter clean
flutter pub get
flutter build apk --release
```

### 2. Tester la connexion
- Installer le nouvel APK sur l'appareil
- Tester la connexion avec chaque compte test
- Vérifier que l'app ne tourne plus en boucle

### 3. Vérifier dans Supabase Dashboard (si nécessaire)
Si le problème persiste, exécuter `DEBUG_AUTH_ISSUE.sql` dans le SQL Editor pour voir l'état exact des utilisateurs.

### 4. Vérifier les politiques RLS (si nécessaire)
Si les utilisateurs ne peuvent pas lire leur profil, vérifier les politiques RLS sur la table `profiles`:
```sql
-- Voir les politiques actuelles
SELECT * FROM pg_policies WHERE tablename = 'profiles';
```

## Fichiers Modifiés

1. `supabase/migrations/015_force_fix_test_users.sql` - Migration de correction
2. `apps/dz_delivery/lib/features/auth/presentation/login_screen.dart` - Gestion des erreurs
3. `DEBUG_AUTH_ISSUE.sql` - Script de diagnostic (à utiliser si besoin)

## Notes Techniques

- La migration utilise des blocs `DO $$` pour éviter les erreurs de contraintes
- Les profils sont mis à jour avec `ON CONFLICT` pour éviter les doublons
- Les entités (restaurant, livreur) sont créées ou mises à jour selon leur existence
- Le code de login ne révoque plus le token en cas d'erreur, il affiche un message

## Commandes Utiles

```bash
# Voir les logs d'authentification
supabase inspect db logs --service auth

# Vérifier le statut du projet
supabase status

# Voir les migrations appliquées
supabase migration list
```
