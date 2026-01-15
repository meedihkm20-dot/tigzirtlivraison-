# 📋 PLAN DE TEST MANUEL - DZ DELIVERY

**Date**: 15 Janvier 2025  
**Version**: 1.0.0+1

---

## 🎯 OBJECTIF

Tester toutes les fonctionnalités de l'application pour chaque rôle utilisateur (Client, Restaurant, Livreur, Admin).

---

## 📱 PRÉREQUIS

### Comptes de test

| Rôle | Email | Mot de passe | Notes |
|------|-------|--------------|-------|
| **Admin** | mehdihakkoum@gmail.com | epau2012 | Dashboard admin |
| **Client** | client@test.com | test123 | À créer si nécessaire |
| **Restaurant** | restaurant@test.com | test123 | À créer si nécessaire |
| **Livreur** | livreur@test.com | test123 | À créer si nécessaire |

### Environnement
- ✅ Backend déployé : https://angry-bertha-1tigizrtlivraison1-86549eb3.koyeb.app
- ✅ Supabase : https://pauqmhqriyjdqctvfvtt.supabase.co
- ✅ APKs buildés via GitHub Actions

---

## 🧪 TESTS PAR RÔLE

---

## 👤 1. CLIENT

### 1.1 Authentification
- [ ] **Inscription**
  - Ouvrir l'app dz_delivery
  - Cliquer sur "S'inscrire"
  - Remplir : nom, email, téléphone, mot de passe
  - Vérifier : compte créé, redirection vers home
  
- [ ] **Connexion**
  - Email : client@test.com
  - Mot de passe : test123
  - Vérifier : connexion réussie, token stocké
  
- [ ] **Déconnexion**
  - Cliquer sur "Déconnexion"
  - Vérifier : retour à l'écran de login

### 1.2 Navigation
- [ ] **Bottom Navigation**
  - Tester tous les onglets : Home, Commandes, Profil
  - Vérifier : navigation fluide, pas de crash

### 1.3 Restaurants
- [ ] **Liste des restaurants**
  - Voir la liste des restaurants disponibles
  - Vérifier : images, noms, statut (ouvert/fermé)
  
- [ ] **Filtres**
  - Filtrer par catégorie (si disponible)
  - Rechercher un restaurant
  - Vérifier : résultats corrects
  
- [ ] **Détails restaurant**
  - Cliquer sur un restaurant
  - Voir le menu complet
  - Vérifier : prix, descriptions, disponibilité

### 1.4 Panier & Commande
- [ ] **Ajouter au panier**
  - Ajouter plusieurs plats
  - Modifier quantités (+/-)
  - Supprimer un article
  - Vérifier : total mis à jour
  
- [ ] **Passer commande**
  - Cliquer sur "Commander"
  - Remplir adresse de livraison
  - Ajouter une note (optionnel)
  - Confirmer la commande
  - Vérifier : 
    - Commande créée dans Supabase
    - Notification push reçue (restaurant)
    - Prix de livraison calculé côté serveur
  
- [ ] **Validation serveur**
  - Essayer de commander un restaurant fermé
  - Essayer de commander un plat indisponible
  - Vérifier : erreurs bloquées côté backend

### 1.5 Suivi de commande
- [ ] **Liste des commandes**
  - Voir l'historique des commandes
  - Filtrer par statut (en cours, livrées, annulées)
  
- [ ] **Détails commande**
  - Cliquer sur une commande
  - Voir : statut, articles, prix, livreur (si assigné)
  - Vérifier : mise à jour en temps réel (Supabase Realtime)
  
- [ ] **Suivi en temps réel**
  - Voir la position du livreur sur la carte (si en livraison)
  - Vérifier : mise à jour de la position
  
- [ ] **Annulation**
  - Annuler une commande en statut "pending" ou "confirmed"
  - Essayer d'annuler après "picked_up" → doit être bloqué
  - Vérifier : règles métier respectées

### 1.6 Notifications
- [ ] **Réception notifications**
  - Commande acceptée par restaurant
  - Commande prête
  - Livreur assigné
  - Commande en route
  - Commande livrée
  - Vérifier : notifications OneSignal reçues

### 1.7 Profil
- [ ] **Voir profil**
  - Nom, email, téléphone
  
- [ ] **Modifier profil**
  - Changer nom, téléphone
  - Sauvegarder
  - Vérifier : modifications enregistrées
  
- [ ] **Changer mot de passe**
  - Ancien mot de passe
  - Nouveau mot de passe
  - Confirmer
  - Vérifier : connexion avec nouveau mot de passe

---

## 🍽️ 2. RESTAURANT

### 2.1 Authentification
- [ ] **Connexion**
  - Email : restaurant@test.com
  - Mot de passe : test123
  - Vérifier : accès interface restaurant

### 2.2 Dashboard
- [ ] **Statistiques**
  - Voir : commandes du jour, revenus, commandes en attente
  - Vérifier : chiffres corrects

### 2.3 Gestion des commandes
- [ ] **Nouvelles commandes**
  - Recevoir notification nouvelle commande
  - Voir détails : client, articles, adresse
  - Son de notification
  
- [ ] **Accepter commande**
  - Cliquer sur "Accepter"
  - Vérifier : 
    - Statut → "confirmed"
    - Notification envoyée au client
    - Backend appelé
  
- [ ] **Refuser commande**
  - Cliquer sur "Refuser"
  - Donner une raison
  - Vérifier : commande annulée, client notifié
  
- [ ] **Commande en préparation**
  - Changer statut → "preparing"
  - Vérifier : mise à jour temps réel
  
- [ ] **Commande prête**
  - Changer statut → "ready"
  - Vérifier :
    - Notification client
    - Livreur assigné automatiquement
    - Notification livreur

### 2.4 Gestion du menu
- [ ] **Liste des plats**
  - Voir tous les plats du menu
  
- [ ] **Ajouter un plat**
  - Nom, description, prix, catégorie
  - Upload photo
  - Sauvegarder
  - Vérifier : plat visible côté client
  
- [ ] **Modifier un plat**
  - Changer prix, description
  - Marquer indisponible
  - Vérifier : modifications visibles
  
- [ ] **Supprimer un plat**
  - Supprimer un plat
  - Vérifier : plus visible côté client

### 2.5 Disponibilité
- [ ] **Ouvrir/Fermer restaurant**
  - Toggle "Ouvert/Fermé"
  - Vérifier : 
    - Statut visible côté client
    - Impossible de commander si fermé

### 2.6 Historique
- [ ] **Voir historique**
  - Toutes les commandes passées
  - Filtrer par date, statut
  - Exporter (si disponible)

---

## 🚚 3. LIVREUR

### 3.1 Authentification
- [ ] **Connexion**
  - Email : livreur@test.com
  - Mot de passe : test123
  - Vérifier : accès interface livreur

### 3.2 Dashboard
- [ ] **Statistiques**
  - Livraisons du jour
  - Gains du jour
  - Statut (disponible/occupé)

### 3.3 Disponibilité
- [ ] **Toggle disponibilité**
  - Activer "Disponible"
  - Vérifier : peut recevoir des commandes
  - Désactiver
  - Vérifier : ne reçoit plus de commandes

### 3.4 Nouvelles livraisons
- [ ] **Recevoir notification**
  - Quand restaurant marque "ready"
  - Voir : restaurant, adresse, montant
  - Son de notification
  
- [ ] **Accepter livraison**
  - Cliquer sur "Accepter"
  - Vérifier :
    - Statut → "driver_assigned"
    - Client notifié
    - Itinéraire affiché sur carte

### 3.5 Récupération commande
- [ ] **Aller au restaurant**
  - Voir itinéraire vers restaurant
  - Navigation GPS (si intégrée)
  
- [ ] **Confirmer récupération**
  - Arrivé au restaurant
  - Cliquer sur "Commande récupérée"
  - Vérifier : statut → "picked_up"

### 3.6 Livraison
- [ ] **En route vers client**
  - Voir itinéraire vers client
  - Position mise à jour en temps réel
  - Vérifier : client voit position sur carte
  
- [ ] **Appeler client**
  - Bouton "Appeler"
  - Vérifier : appel téléphonique lancé
  
- [ ] **Confirmer livraison**
  - Arrivé chez client
  - Demander code de confirmation (4-6 chiffres)
  - Entrer le code
  - Vérifier :
    - Code validé côté backend
    - Statut → "delivered"
    - Gains mis à jour
    - Client et restaurant notifiés
  
- [ ] **Code incorrect**
  - Entrer mauvais code
  - Vérifier : erreur, livraison non validée

### 3.7 Historique
- [ ] **Voir historique**
  - Toutes les livraisons
  - Gains par livraison
  - Statistiques

### 3.8 Géolocalisation
- [ ] **Permissions**
  - Autoriser localisation
  - Vérifier : position mise à jour
  
- [ ] **Carte**
  - Voir position actuelle
  - Itinéraires affichés
  - Zoom/dézoom

---

## 👨‍💼 4. ADMIN

### 4.1 Authentification
- [ ] **Connexion**
  - Email : mehdihakkoum@gmail.com
  - Mot de passe : epau2012
  - Vérifier : accès dashboard admin

### 4.2 Dashboard
- [ ] **Vue d'ensemble**
  - Statistiques globales
  - Graphiques (fl_chart)
  - Commandes en temps réel
  - Revenus du jour/mois

### 4.3 Gestion utilisateurs
- [ ] **Liste utilisateurs**
  - Voir tous les utilisateurs
  - Filtrer par rôle (client, restaurant, livreur)
  - Rechercher
  
- [ ] **Détails utilisateur**
  - Voir profil complet
  - Historique d'activité
  
- [ ] **Activer/Désactiver**
  - Désactiver un utilisateur
  - Vérifier : ne peut plus se connecter
  - Réactiver
  
- [ ] **Supprimer utilisateur**
  - Supprimer (soft delete)
  - Vérifier : données anonymisées

### 4.4 Gestion restaurants
- [ ] **Liste restaurants**
  - Voir tous les restaurants
  - Statut, propriétaire, commandes
  
- [ ] **Approuver restaurant**
  - Nouveau restaurant en attente
  - Approuver/Refuser
  - Vérifier : restaurant visible/invisible
  
- [ ] **Modifier restaurant**
  - Changer infos, commission
  - Sauvegarder

### 4.5 Gestion livreurs
- [ ] **Liste livreurs**
  - Voir tous les livreurs
  - Statut (disponible, en livraison)
  
- [ ] **Vérifier livreur**
  - Marquer comme vérifié
  - Vérifier : peut accepter livraisons
  
- [ ] **Voir position**
  - Position en temps réel sur carte
  - Historique des trajets

### 4.6 Gestion commandes
- [ ] **Toutes les commandes**
  - Voir toutes les commandes
  - Filtrer par statut, date, restaurant
  
- [ ] **Détails commande**
  - Voir tous les détails
  - Historique des statuts
  
- [ ] **Annuler commande**
  - Annuler manuellement (admin override)
  - Donner raison
  - Vérifier : toutes les parties notifiées

### 4.7 Rapports & Analytics
- [ ] **Rapports**
  - Revenus par période
  - Commandes par restaurant
  - Performance livreurs
  - Exporter CSV/PDF

### 4.8 Notifications
- [ ] **Envoyer notification**
  - Notification globale
  - Notification ciblée (rôle, utilisateur)
  - Vérifier : réception

### 4.9 Paramètres
- [ ] **Configuration**
  - Frais de livraison
  - Commission restaurant
  - Commission livreur
  - Zones de livraison
  - Sauvegarder
  - Vérifier : calculs mis à jour

---

## 🔄 TESTS TRANSVERSAUX

### Temps réel (Supabase Realtime)
- [ ] **Mise à jour statut**
  - Restaurant change statut
  - Vérifier : client voit changement instantané
  - Vérifier : livreur voit changement
  - Vérifier : admin voit changement

### Notifications (OneSignal)
- [ ] **Push notifications**
  - Tester tous les types de notifications
  - Vérifier : réception sur tous les appareils
  - Vérifier : son, vibration, badge

### Backend API
- [ ] **Endpoints**
  - Tester via Swagger : https://angry-bertha-1tigizrtlivraison1-86549eb3.koyeb.app/api/docs
  - Health check
  - Calculate delivery price
  - Estimate time
  - Create order
  - Change status
  - Cancel order
  - Verify delivery

### Sécurité
- [ ] **Auth**
  - Essayer d'accéder sans token → 401
  - Essayer d'accéder avec mauvais rôle → 403
  - Token expiré → refresh automatique
  
- [ ] **RLS Supabase**
  - Client ne voit que ses commandes
  - Restaurant ne voit que ses commandes
  - Livreur ne voit que ses livraisons

### Performance
- [ ] **Chargement**
  - Temps de démarrage app
  - Temps de chargement listes
  - Fluidité navigation
  
- [ ] **Offline**
  - Couper internet
  - Vérifier : messages d'erreur clairs
  - Reconnecter
  - Vérifier : synchronisation automatique

---

## 📊 CHECKLIST FINALE

### Fonctionnel
- [ ] Toutes les fonctionnalités testées
- [ ] Aucun crash identifié
- [ ] Notifications fonctionnelles
- [ ] Temps réel opérationnel
- [ ] Backend répond correctement

### UX/UI
- [ ] Navigation intuitive
- [ ] Messages d'erreur clairs
- [ ] Loading states présents
- [ ] Design cohérent
- [ ] Responsive (différentes tailles écran)

### Sécurité
- [ ] Auth fonctionnelle
- [ ] RLS respectée
- [ ] Validation côté serveur
- [ ] Pas de données sensibles exposées

### Performance
- [ ] App fluide (60 FPS)
- [ ] Pas de memory leaks
- [ ] Chargement rapide
- [ ] Batterie OK

---

## 🐛 RAPPORT DE BUGS

Pour chaque bug trouvé, noter :

| ID | Écran | Rôle | Description | Priorité | Statut |
|----|-------|------|-------------|----------|--------|
| 1 | | | | 🔴/🟡/🟢 | |
| 2 | | | | | |

**Priorités** :
- 🔴 Critique (bloquant)
- 🟡 Important (gênant)
- 🟢 Mineur (cosmétique)

---

## 📝 NOTES

- Tester sur plusieurs appareils (différentes versions Android)
- Tester avec connexion lente (3G)
- Tester avec batterie faible
- Tester en mode sombre (si disponible)
- Tester avec différentes langues (si multilingue)

---

**Testeur** : _______________  
**Date** : _______________  
**Durée** : _______________  
**Bugs trouvés** : _______________
