# 🔄 MIGRATION SUPABASE → BACKEND

**Objectif**: Migrer toutes les opérations critiques de Supabase direct vers le Backend NestJS

---

## ✅ MIGRATIONS EFFECTUÉES

### 1. Création de commande
- ✅ `cart_screen.dart` - Ligne 101
- ✅ `cart_screen_v2.dart` - Ligne 1424
- **Avant**: `SupabaseService.createOrder()`
- **Après**: `BackendApiService.createOrder()`
- **Bénéfice**: Validation serveur, calcul prix sécurisé

---

## 🔴 MIGRATIONS À FAIRE

### 2. Changement de statut commande
**Fichiers concernés**:
- `kitchen_screen.dart` (restaurant)
- `restaurant_order_detail_screen.dart`
- `delivery_screen.dart` (livreur)

**Méthodes à migrer**:
```dart
// ❌ ANCIEN
SupabaseService.confirmOrder()
SupabaseService.startPreparing()
SupabaseService.markAsReady()
SupabaseService.updateOrderStatus()

// ✅ NOUVEAU
BackendApiService.changeOrderStatus(orderId, 'confirmed')
BackendApiService.changeOrderStatus(orderId, 'preparing')
BackendApiService.changeOrderStatus(orderId, 'ready')
```

**Bénéfice**: Transitions validées, règles métier respectées

---

### 3. Annulation de commande
**Fichiers concernés**:
- `order_tracking_screen.dart` (client)
- `restaurant_order_detail_screen.dart` (restaurant)

**Méthodes à migrer**:
```dart
// ❌ ANCIEN
SupabaseService.cancelOrder()

// ✅ NOUVEAU
BackendApiService.cancelOrder(orderId, reason, details)
```

**Bénéfice**: Règles d'annulation (bloqué après pickup)

---

### 4. Vérification livraison
**Fichiers concernés**:
- `delivery_screen.dart` (livreur)

**Méthodes à migrer**:
```dart
// ❌ ANCIEN
SupabaseService.verifyDeliveryCode()

// ✅ NOUVEAU
BackendApiService.verifyDelivery(orderId, code)
```

**Bénéfice**: Validation code côté serveur, sécurisé

---

### 5. Acceptation commande (livreur)
**Fichiers concernés**:
- `livreur_home_screen.dart`
- `delivery_screen.dart`

**Méthodes à migrer**:
```dart
// ❌ ANCIEN
SupabaseService.acceptOrder()

// ✅ NOUVEAU
BackendApiService.changeOrderStatus(orderId, 'confirmed')
```

---

## 📊 OPÉRATIONS À GARDER SUR SUPABASE

### ✅ Lectures (SELECT)
- Liste des commandes
- Détails commande
- Historique
- **Raison**: Pas de logique métier, juste affichage

### ✅ Realtime
- Écoute des changements de statut
- Mise à jour position livreur
- **Raison**: Supabase Realtime est optimal pour ça

### ✅ Auth
- Login, Register, Logout
- **Raison**: Supabase Auth est déjà bien intégré

### ✅ Storage
- Upload/Download images
- **Raison**: Supabase Storage est optimal

---

## 🎯 PLAN D'ACTION

### Phase 1: Commandes (✅ FAIT)
- [x] Création commande → Backend

### Phase 2: Statuts (À FAIRE)
- [ ] Accepter commande → Backend
- [ ] Confirmer commande → Backend
- [ ] Préparer commande → Backend
- [ ] Marquer prête → Backend
- [ ] Récupérer commande → Backend
- [ ] Livrer commande → Backend

### Phase 3: Annulations (À FAIRE)
- [ ] Annuler commande → Backend

### Phase 4: Vérifications (À FAIRE)
- [ ] Vérifier code livraison → Backend

### Phase 5: Tests
- [ ] Tester tous les flux end-to-end
- [ ] Vérifier notifications
- [ ] Vérifier Realtime

---

## 🔧 TEMPLATE DE MIGRATION

Pour chaque fichier à migrer :

```dart
// 1. Importer le service backend
import '../../core/services/backend_api_service.dart';

// 2. Créer une instance
final backendApi = BackendApiService(SupabaseService.client);

// 3. Remplacer l'appel
// AVANT
await SupabaseService.updateOrderStatus(orderId, 'ready');

// APRÈS
await backendApi.changeOrderStatus(orderId, 'ready');
```

---

## ⚠️ POINTS D'ATTENTION

1. **Gestion d'erreurs**: Le backend renvoie des erreurs différentes
2. **Format de réponse**: Vérifier la structure JSON
3. **Notifications**: Le backend envoie les notifications automatiquement
4. **Realtime**: Continue de fonctionner (backend écrit dans Supabase)

---

## 📝 CHECKLIST FINALE

Avant de considérer la migration terminée :

- [ ] Toutes les opérations critiques passent par le backend
- [ ] Tests manuels de tous les flux
- [ ] Pas d'appels directs `client.from('orders').insert/update` dans le code
- [ ] Notifications fonctionnent
- [ ] Realtime fonctionne
- [ ] Performance acceptable

---

**Prochaine étape**: Migrer les changements de statut dans les écrans restaurant et livreur.
