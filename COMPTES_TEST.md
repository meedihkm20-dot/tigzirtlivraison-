# 🔐 Comptes Test DZ Delivery

## Identifiants de connexion

**Mot de passe uniforme pour tous les comptes:** `test12345`

| Rôle | Email | Mot de passe | Description |
|------|-------|--------------|-------------|
| 👑 **Admin** | `admin@test.com` | `test12345` | Accès complet à l'administration |
| 🛒 **Client** | `client@test.com` | `test12345` | Commandes et suivi client |
| 🍽️ **Restaurant** | `restaurant@test.com` | `test12345` | Gestion menu et commandes |
| 🛵 **Livreur** | `livreur@test.com` | `test12345` | Livraisons et navigation |

## Instructions

1. **Exécuter la migration SQL** `010_update_test_passwords.sql` dans Supabase
2. **Tester la connexion** avec les nouveaux identifiants
3. **Vérifier les rôles** dans l'application

## Données de test

- **Restaurant de test:** "Restaurant Test" (créé automatiquement)
- **Livreur de test:** Profil livreur vérifié et actif
- **Adresses de test:** Tigzirt, Algérie (coordonnées par défaut)

## Sécurité

⚠️ **Ces comptes sont uniquement pour les tests de développement**
- Ne pas utiliser en production
- Changer les mots de passe avant le déploiement final
- Supprimer les comptes test en production

## Mise à jour

**Date:** Janvier 2025  
**Version:** 1.0  
**Statut:** ✅ Actif