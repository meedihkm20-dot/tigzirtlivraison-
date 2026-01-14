# 🍽️ PLAN DE TEST - APPLICATION RESTAURANT

## Compte de test
- **Email**: `restaurant@test.com`
- **Mot de passe**: `test12345`
- **Restaurant**: Restaurant Test (Tigzirt)

---

## ✅ PHASE 1: CONNEXION & PROFIL

### Test 1.1: Connexion
- [ ] Se connecter avec `restaurant@test.com` / `test12345`
- [ ] Vérifier que l'écran d'accueil s'affiche
- [ ] Vérifier que le nom du restaurant apparaît dans l'AppBar

**Résultat attendu**: Connexion réussie, affichage du dashboard restaurant

### Test 1.2: Profil restaurant
- [ ] Aller dans l'onglet "Profil" (bottom nav)
- [ ] Vérifier les informations du restaurant:
  - Nom
  - Adresse
  - Téléphone
  - Horaires d'ouverture
  - Logo/Photo de couverture
- [ ] Tester le bouton "Modifier le profil"

**Résultat attendu**: Toutes les infos du restaurant sont affichées correctement

---

## ✅ PHASE 2: GESTION DU STATUT (OUVERT/FERMÉ)

### Test 2.1: Toggle Ouvert/Fermé
- [ ] Sur l'écran d'accueil, vérifier le switch "Ouvert/Fermé" en haut à droite
- [ ] Basculer de "Ouvert" à "Fermé"
- [ ] Vérifier que le texte change de couleur (vert → rouge)
- [ ] Basculer de nouveau à "Ouvert"

**Résultat attendu**: Le statut change instantanément, les clients ne voient plus le restaurant quand il est fermé

### Test 2.2: Impact sur les clients
- [ ] Mettre le restaurant en "Fermé"
- [ ] Se connecter avec le compte client (`client@test.com`)
- [ ] Vérifier que le restaurant n'apparaît plus dans la liste
- [ ] Remettre le restaurant en "Ouvert"
- [ ] Vérifier que le restaurant réapparaît

**Résultat attendu**: Le statut impacte immédiatement la visibilité

---

## ✅ PHASE 3: STATISTIQUES DU DASHBOARD

### Test 3.1: Cartes de statistiques
- [ ] Vérifier la carte "Aujourd'hui" (nombre de commandes du jour)
- [ ] Vérifier la carte "Revenus" (revenus du jour en DA)
- [ ] Vérifier la carte "En attente" (commandes pending/confirmed/preparing)
- [ ] Vérifier la carte "Total" (total des commandes)

**Résultat attendu**: Les stats s'affichent correctement (même si à 0)

### Test 3.2: Rafraîchissement des stats
- [ ] Tirer vers le bas (pull to refresh) sur l'écran d'accueil
- [ ] Vérifier que les stats se rechargent

**Résultat attendu**: Indicateur de chargement puis mise à jour des données

---

## ✅ PHASE 4: GESTION DES COMMANDES

### Test 4.1: Réception d'une nouvelle commande
**Préparation**: Créer une commande avec le compte client

- [ ] Se connecter avec `client@test.com`
- [ ] Créer une commande (ajouter des plats au panier, commander)
- [ ] Attendre qu'un livreur accepte la commande
- [ ] Revenir sur le compte restaurant

**Sur le compte restaurant**:
- [ ] Vérifier qu'une notification "🔔 Nouvelle commande!" apparaît
- [ ] Vérifier que la commande apparaît dans "Commandes en cours"
- [ ] Vérifier les infos de la commande:
  - Numéro de commande (#DZ...)
  - Nom du client
  - Nombre d'articles
  - Montant total
  - Statut "Nouvelle" (orange)

**Résultat attendu**: La commande apparaît en temps réel avec toutes les infos

### Test 4.2: Refuser une commande
- [ ] Cliquer sur le bouton "Refuser" d'une commande en statut "pending"
- [ ] Vérifier que la commande disparaît de la liste
- [ ] Vérifier le message "Commande refusée"

**Résultat attendu**: La commande est annulée, le client est notifié

### Test 4.3: Confirmer une commande
- [ ] Cliquer sur le bouton "Confirmer" d'une commande en statut "pending"
- [ ] Vérifier le message "Commande confirmée ✅"
- [ ] Vérifier que le statut passe à "Confirmée" (bleu)
- [ ] Vérifier que le bouton devient "Commencer préparation"

**Résultat attendu**: Commande confirmée, temps de préparation estimé à 30 min

### Test 4.4: Commencer la préparation
- [ ] Cliquer sur "Commencer préparation"
- [ ] Vérifier que le statut passe à "En préparation" (violet)
- [ ] Vérifier que le bouton devient "Marquer comme prêt"

**Résultat attendu**: Statut mis à jour, le livreur voit que la préparation a commencé

### Test 4.5: Marquer comme prêt
- [ ] Cliquer sur "Marquer comme prêt"
- [ ] Vérifier le message "Commande prête! 🍽️"
- [ ] Vérifier que le statut passe à "Prête" (vert)
- [ ] Vérifier que la commande disparaît de la liste (car prise en charge par le livreur)

**Résultat attendu**: Le livreur est notifié et peut récupérer la commande

---

## ✅ PHASE 5: ÉCRAN CUISINE (Kitchen Screen)

### Test 5.1: Accès à l'écran cuisine
- [ ] Sur l'écran d'accueil, cliquer sur le bouton "Cuisine" (orange)
- [ ] Vérifier que l'écran cuisine s'affiche en grille (2 colonnes)
- [ ] Vérifier le compteur "X en cours" dans l'AppBar

**Résultat attendu**: Vue en grille des commandes en cours

### Test 5.2: Affichage des commandes en cuisine
Pour chaque carte de commande, vérifier:
- [ ] Numéro de commande
- [ ] Statut (Nouvelle / En préparation)
- [ ] Timer (temps écoulé depuis la création)
- [ ] Couleur de la bordure:
  - Vert: < 10 min
  - Orange: 10-15 min
  - Rouge: > 15 min (urgent!)
- [ ] Liste des articles avec quantités
- [ ] Instructions spéciales (si présentes)
- [ ] Nom du livreur (si assigné)

**Résultat attendu**: Toutes les infos sont visibles, les commandes urgentes sont en rouge

### Test 5.3: Actions depuis la cuisine
- [ ] Cliquer sur "PRÉPARER" pour une commande nouvelle
- [ ] Vérifier que la bordure devient orange
- [ ] Vérifier que le bouton devient "✓ PRÊT"
- [ ] Cliquer sur "✓ PRÊT"
- [ ] Vérifier le message "Commande prête! 🍽️ Le livreur est notifié"
- [ ] Vérifier que la commande disparaît de la grille

**Résultat attendu**: Workflow fluide, notifications claires

### Test 5.4: Rafraîchissement automatique
- [ ] Laisser l'écran cuisine ouvert
- [ ] Créer une nouvelle commande avec le compte client
- [ ] Attendre 10 secondes (auto-refresh)
- [ ] Vérifier qu'une vibration se produit
- [ ] Vérifier le message "🔔 Nouvelle commande en cuisine!"
- [ ] Vérifier que la nouvelle commande apparaît

**Résultat attendu**: Rafraîchissement automatique toutes les 10 secondes

---

## ✅ PHASE 6: GESTION DU MENU

### Test 6.1: Accès au menu
- [ ] Aller dans l'onglet "Menu" (bottom nav)
- [ ] Vérifier les deux onglets: "Plats" et "Catégories"

**Résultat attendu**: Interface avec tabs

### Test 6.2: Ajouter une catégorie
- [ ] Aller dans l'onglet "Catégories"
- [ ] Cliquer sur le bouton "+" en haut à droite
- [ ] Entrer un nom: "Entrées"
- [ ] Entrer une description: "Entrées froides et chaudes"
- [ ] Cliquer sur "Ajouter"
- [ ] Vérifier que la catégorie apparaît dans la liste

**Résultat attendu**: Catégorie créée et visible

### Test 6.3: Ajouter un plat
- [ ] Aller dans l'onglet "Plats"
- [ ] Cliquer sur le bouton "+"
- [ ] Cliquer sur la zone photo pour ajouter une image
- [ ] Sélectionner une image depuis la galerie
- [ ] Remplir les champs:
  - Nom: "Couscous Royal"
  - Description: "Couscous avec viande et légumes"
  - Prix: "800"
  - Temps de préparation: "30"
  - Catégorie: Sélectionner une catégorie
- [ ] Ajouter des ingrédients: "Semoule", "Viande", "Légumes"
- [ ] Cocher "Végétarien" ou "Épicé" si applicable
- [ ] Cliquer sur "Ajouter le plat"

**Résultat attendu**: Plat créé avec photo et visible dans la liste

### Test 6.4: Modifier un plat
- [ ] Cliquer sur un plat existant
- [ ] Cliquer sur "Modifier"
- [ ] Changer le prix: "850"
- [ ] Cliquer sur "Enregistrer"
- [ ] Vérifier que le prix est mis à jour

**Résultat attendu**: Modifications enregistrées

### Test 6.5: Marquer un plat indisponible
- [ ] Cliquer sur un plat
- [ ] Cliquer sur "Marquer indisponible"
- [ ] Vérifier le badge rouge "Indisponible"
- [ ] Vérifier que le plat est grisé
- [ ] Remettre disponible

**Résultat attendu**: Le plat n'apparaît plus chez les clients quand indisponible

### Test 6.6: Définir un plat du jour
- [ ] Cliquer sur un plat
- [ ] Cliquer sur "Définir comme plat du jour"
- [ ] Entrer un prix spécial: "700" (au lieu de 800)
- [ ] Cliquer sur "Confirmer"
- [ ] Vérifier le badge "🔥 PROMO"

**Résultat attendu**: Le plat apparaît en promotion chez les clients

### Test 6.7: Voir les statistiques d'un plat
- [ ] Cliquer sur un plat
- [ ] Cliquer sur "Voir les statistiques"
- [ ] Vérifier:
  - Nombre de commandes
  - Note moyenne
  - Nombre d'avis
  - Date de dernière commande

**Résultat attendu**: Stats affichées (même si à 0)

### Test 6.8: Supprimer un plat
- [ ] Cliquer sur un plat
- [ ] Cliquer sur "Supprimer"
- [ ] Confirmer la suppression
- [ ] Vérifier que le plat disparaît

**Résultat attendu**: Plat supprimé de la base de données

---

## ✅ PHASE 7: STATISTIQUES DÉTAILLÉES

### Test 7.1: Accès aux stats
- [ ] Aller dans l'onglet "Stats" (bottom nav)
- [ ] Vérifier l'affichage des statistiques

**Résultat attendu**: Page de stats détaillées

### Test 7.2: Statistiques affichées
Vérifier les métriques suivantes:
- [ ] Commandes aujourd'hui
- [ ] Revenus aujourd'hui
- [ ] Commandes cette semaine
- [ ] Revenus cette semaine
- [ ] Commandes ce mois
- [ ] Revenus ce mois
- [ ] Total des commandes
- [ ] Revenu total
- [ ] Note moyenne
- [ ] Nombre d'avis

**Résultat attendu**: Toutes les stats sont affichées avec des icônes et couleurs

---

## ✅ PHASE 8: PROMOTIONS

### Test 8.1: Accès aux promotions
- [ ] Sur l'écran d'accueil, cliquer sur "Promos" (rose)
- [ ] Vérifier l'affichage de l'écran promotions

**Résultat attendu**: Interface de gestion des promotions

### Test 8.2: Créer une promotion
- [ ] Cliquer sur le bouton "+"
- [ ] Remplir les champs:
  - Titre: "Promo Week-end"
  - Description: "-20% sur tous les plats"
  - Code promo: "WEEKEND20"
  - Pourcentage de réduction: "20"
  - Date de début
  - Date de fin
- [ ] Cliquer sur "Créer"

**Résultat attendu**: Promotion créée et visible

---

## ✅ PHASE 9: NOTIFICATIONS EN TEMPS RÉEL

### Test 9.1: Notification nouvelle commande
- [ ] Laisser l'app restaurant ouverte sur l'écran d'accueil
- [ ] Créer une commande avec le compte client
- [ ] Vérifier qu'une SnackBar verte apparaît: "🔔 Nouvelle commande!"
- [ ] Vérifier que la commande apparaît immédiatement dans la liste

**Résultat attendu**: Notification instantanée via Supabase Realtime

---

## ✅ PHASE 10: TESTS DE FLUX COMPLET

### Test 10.1: Flux complet d'une commande
1. **Client** crée une commande
2. **Livreur** accepte la commande
3. **Restaurant** reçoit la notification
4. **Restaurant** confirme la commande
5. **Restaurant** commence la préparation
6. **Restaurant** marque comme prêt
7. **Livreur** récupère la commande
8. **Livreur** livre au client

À chaque étape, vérifier:
- [ ] Les notifications
- [ ] Les changements de statut
- [ ] Les mises à jour en temps réel
- [ ] Les stats qui s'incrémentent

**Résultat attendu**: Flux fluide sans erreur

---

## 🐛 BUGS À VÉRIFIER

### Bug potentiel 1: Fonction get_restaurant_stats
- [ ] Vérifier que les stats s'affichent sans erreur PostgreSQL
- [ ] Si erreur, vérifier les logs Supabase

**Fix appliqué**: Migration 016 (délimiteurs `$$` et alias corrects)

### Bug potentiel 2: Upload d'images
- [ ] Vérifier que l'upload de photos de plats fonctionne
- [ ] Vérifier que les images s'affichent correctement

### Bug potentiel 3: RLS (Row Level Security)
- [ ] Vérifier que le restaurant ne voit que SES commandes
- [ ] Vérifier que le restaurant ne peut modifier que SON menu

**Note**: RLS temporairement désactivé sur certaines tables pour les tests

---

## 📊 RÉSUMÉ DES FONCTIONNALITÉS

### ✅ Fonctionnalités implémentées
- [x] Connexion restaurant
- [x] Dashboard avec stats en temps réel
- [x] Toggle Ouvert/Fermé
- [x] Gestion des commandes (confirmer, préparer, marquer prêt)
- [x] Écran cuisine avec vue en grille
- [x] Timer et code couleur pour urgence
- [x] Gestion du menu (catégories + plats)
- [x] Upload de photos
- [x] Plat du jour / Promotions
- [x] Marquer plats disponibles/indisponibles
- [x] Statistiques détaillées
- [x] Notifications en temps réel (Supabase Realtime)
- [x] Rafraîchissement automatique

### 🚧 Améliorations possibles
- [ ] Graphiques pour les stats (courbes de revenus)
- [ ] Historique des commandes avec filtres
- [ ] Gestion des avis clients
- [ ] Impression de tickets de cuisine
- [ ] Gestion des horaires d'ouverture par jour
- [ ] Gestion des zones de livraison
- [ ] Tableau de bord analytique avancé

---

## 🎯 PROCHAINES ÉTAPES

1. **Tester toutes les fonctionnalités** listées ci-dessus
2. **Noter les bugs** rencontrés
3. **Prioriser les améliorations** nécessaires
4. **Optimiser les performances** (chargement, images)
5. **Améliorer l'UX** (animations, transitions)

---

**Date de création**: 14 janvier 2026
**Dernière mise à jour**: 14 janvier 2026
