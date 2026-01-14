# 🔄 SCÉNARIOS COMPLETS - GESTION DES COMMANDES

## 📊 TABLEAU RÉCAPITULATIF

| Scénario | Restaurant | Livreur | Résultat | Action Client |
|----------|-----------|---------|----------|---------------|
| 1 | ✅ Accepte | ✅ Accepte | ✅ Livraison OK | Reçoit sa commande |
| 2 | ✅ Accepte | ❌ Refuse | ⚠️ Chercher autre livreur | Attend |
| 3 | ✅ Accepte | ⏱️ Timeout | ❌ Annulation | Remboursé |
| 4 | ❌ Refuse | - | ❌ Annulation | Commander ailleurs |
| 5 | ⏱️ Timeout | - | ❌ Annulation | Commander ailleurs |
| 6 | ✅ Accepte | ✅ Accepte puis annule | ⚠️ Chercher autre livreur | Attend |

---

## 🎯 SCÉNARIO 1 : TOUT SE PASSE BIEN ✅

### Flux complet
```
Client → Restaurant → Livreur → Livraison
  ✅        ✅          ✅         ✅
```

### Étapes détaillées
1. **Client crée commande**
   - `status = 'pending'`
   - Notification → Restaurant
   - Message client : "En attente de confirmation du restaurant..."

2. **Restaurant accepte** (dans les 5 min)
   - `status = 'confirmed'`
   - `confirmed_at = NOW()`
   - `estimated_delivery_time = NOW() + 30 min`
   - Notification → Client : "Restaurant a accepté ! Préparation : 30 min"
   - Notification → Livreurs disponibles : "Nouvelle commande disponible"

3. **Livreur accepte** (dans les 5 min)
   - `livreur_id = [ID_LIVREUR]`
   - Notification → Restaurant : "Livreur [Nom] a accepté"
   - Notification → Client : "Livreur [Nom] assigné"

4. **Restaurant prépare**
   - `status = 'preparing'`
   - Notification → Livreur : "Restaurant prépare votre commande"

5. **Restaurant termine**
   - `status = 'ready'`
   - `prepared_at = NOW()`
   - Notification → Livreur : "Commande prête ! Vous pouvez récupérer"

6. **Livreur récupère**
   - `status = 'picked_up'`
   - Notification → Client : "Livreur en route vers vous"

7. **Livreur livre**
   - Code PIN validé
   - `status = 'delivered'`
   - `delivered_at = NOW()`
   - Transactions créées (livreur + restaurant)
   - Notification → Client : "Bon appétit ! Notez votre commande"

### Résultat
✅ **Commande livrée avec succès**
- Client satisfait
- Restaurant payé
- Livreur payé

---

## ⚠️ SCÉNARIO 2 : RESTAURANT ACCEPTE, LIVREUR REFUSE

### Flux
```
Client → Restaurant → Livreur 1 → Livreur 2 → Livraison
  ✅        ✅           ❌          ✅          ✅
```

### Étapes
1. Client crée commande → `status = 'pending'`
2. Restaurant accepte → `status = 'confirmed'`
3. **Livreur 1 refuse** (ou timeout 5 min)
   - `livreur_id = NULL` (reste null)
   - Notification → Autres livreurs : "Commande toujours disponible"
   - Message client : "Recherche d'un livreur..."

4. **Livreur 2 accepte**
   - `livreur_id = [ID_LIVREUR_2]`
   - Suite du flux normal

### Résultat
✅ **Commande livrée avec succès** (avec délai)
- Client attend un peu plus
- Restaurant prépare normalement
- Livreur 2 livre

### Gestion technique
```sql
-- Si aucun livreur n'accepte après 10 min
UPDATE orders
SET status = 'cancelled',
    cancellation_reason = 'Aucun livreur disponible',
    cancelled_at = NOW()
WHERE status = 'confirmed'
  AND livreur_id IS NULL
  AND confirmed_at < NOW() - INTERVAL '10 minutes';
```

---

## ❌ SCÉNARIO 3 : RESTAURANT ACCEPTE, AUCUN LIVREUR (TIMEOUT)

### Flux
```
Client → Restaurant → ⏱️ Timeout (10 min) → Annulation
  ✅        ✅              ❌                  ❌
```

### Étapes
1. Client crée commande → `status = 'pending'`
2. Restaurant accepte → `status = 'confirmed'`
3. **Aucun livreur n'accepte pendant 10 min**
   - Auto-annulation par trigger/fonction
   - `status = 'cancelled'`
   - `cancellation_reason = 'Aucun livreur disponible'`
   - `cancelled_at = NOW()`

4. **Notifications**
   - Client : "Désolé, aucun livreur disponible. Vous serez remboursé."
   - Restaurant : "Commande #XXX annulée (pas de livreur)"

### Résultat
❌ **Commande annulée**
- Client remboursé (si paiement effectué)
- Restaurant ne prépare pas
- Peut commander ailleurs

---

## ❌ SCÉNARIO 4 : RESTAURANT REFUSE

### Flux
```
Client → Restaurant → Annulation
  ✅        ❌           ❌
```

### Étapes
1. Client crée commande → `status = 'pending'`
2. **Restaurant refuse** (débordé, fermé, rupture stock...)
   - `status = 'cancelled'`
   - `cancellation_reason = 'Refusé par le restaurant : [raison]'`
   - `cancelled_at = NOW()`

3. **Notification client**
   - "Le restaurant ne peut pas prendre votre commande"
   - Raison affichée (si fournie)
   - Bouton "Commander ailleurs"

### Résultat
❌ **Commande annulée immédiatement**
- Client peut commander dans un autre restaurant
- Pas de perte de temps

### Interface restaurant
```dart
// Dialogue de refus
showDialog(
  title: 'Refuser la commande',
  content: TextField(
    label: 'Raison (optionnel)',
    options: [
      'Restaurant débordé',
      'Ingrédients manquants',
      'Problème technique',
      'Autre...'
    ]
  )
);
```

---

## ⏱️ SCÉNARIO 5 : RESTAURANT NE RÉPOND PAS (TIMEOUT)

### Flux
```
Client → ⏱️ Timeout (5-10 min) → Annulation
  ✅              ❌                  ❌
```

### Étapes
1. Client crée commande → `status = 'pending'`
2. **Restaurant ne répond pas pendant 5-10 min**
   - Auto-annulation
   - `status = 'cancelled'`
   - `cancellation_reason = 'Restaurant non disponible (timeout)'`
   - `cancelled_at = NOW()`

3. **Notification client**
   - "Le restaurant ne répond pas"
   - "Vous pouvez commander ailleurs"

### Résultat
❌ **Commande annulée automatiquement**
- Client ne perd pas trop de temps
- Peut commander ailleurs rapidement

### Fonction automatique
```sql
-- Trigger qui s'exécute toutes les minutes
CREATE OR REPLACE FUNCTION auto_cancel_pending_orders()
RETURNS void AS $$
BEGIN
  UPDATE orders
  SET status = 'cancelled',
      cancellation_reason = 'Restaurant non disponible (timeout)',
      cancelled_at = NOW()
  WHERE status = 'pending'
    AND created_at < NOW() - INTERVAL '10 minutes';
END;
$$ LANGUAGE plpgsql;
```

---

## ⚠️ SCÉNARIO 6 : LIVREUR ACCEPTE PUIS ANNULE

### Flux
```
Client → Restaurant → Livreur 1 → Annulation → Livreur 2 → Livraison
  ✅        ✅          ✅            ❌           ✅          ✅
```

### Étapes
1. Client crée commande → `status = 'pending'`
2. Restaurant accepte → `status = 'confirmed'`
3. Livreur 1 accepte → `livreur_id = [ID_LIVREUR_1]`
4. **Livreur 1 annule** (problème véhicule, urgence...)
   - `livreur_id = NULL`
   - `status = 'confirmed'` (retour à l'état précédent)
   - Notification → Autres livreurs : "Commande disponible"
   - Notification → Client : "Recherche d'un nouveau livreur..."
   - Notification → Restaurant : "Livreur a annulé, recherche en cours"

5. **Livreur 2 accepte**
   - `livreur_id = [ID_LIVREUR_2]`
   - Suite du flux normal

### Résultat
✅ **Commande livrée avec succès** (avec délai)
- Client attend un peu plus
- Restaurant continue la préparation
- Livreur 2 livre

### Pénalité livreur (optionnel)
```sql
-- Incrémenter compteur d'annulations
UPDATE livreurs
SET cancellation_count = cancellation_count + 1
WHERE id = [ID_LIVREUR_1];

-- Si trop d'annulations (> 3 par jour), suspendre
UPDATE livreurs
SET is_available = false,
    suspension_reason = 'Trop d\'annulations'
WHERE cancellation_count > 3
  AND DATE(last_cancellation) = CURRENT_DATE;
```

---

## 🚨 SCÉNARIO 7 : LIVREUR ACCEPTE, RESTAURANT ANNULE APRÈS

### Flux
```
Client → Restaurant → Livreur → Restaurant annule → Annulation
  ✅        ✅          ✅              ❌               ❌
```

### Étapes
1. Client crée commande → `status = 'pending'`
2. Restaurant accepte → `status = 'confirmed'`
3. Livreur accepte → `livreur_id = [ID_LIVREUR]`
4. **Restaurant annule** (rupture stock découverte, problème...)
   - `status = 'cancelled'`
   - `cancellation_reason = 'Annulé par le restaurant : [raison]'`
   - `cancelled_at = NOW()`

5. **Notifications**
   - Client : "Commande annulée par le restaurant. Vous serez remboursé."
   - Livreur : "Commande #XXX annulée par le restaurant"

### Résultat
❌ **Commande annulée**
- Client remboursé
- Livreur reçoit compensation (ex: 50 DA pour déplacement)
- Restaurant peut être pénalisé (taux d'annulation)

### Compensation livreur
```sql
-- Créer une transaction de compensation
INSERT INTO transactions (
  livreur_id,
  type,
  amount,
  status,
  description
) VALUES (
  [ID_LIVREUR],
  'compensation',
  50.00,
  'completed',
  'Compensation pour annulation restaurant'
);
```

---

## 🚨 SCÉNARIO 8 : CLIENT ANNULE APRÈS ACCEPTATION

### Flux
```
Client → Restaurant → Livreur → Client annule → Annulation
  ✅        ✅          ✅            ❌            ❌
```

### Étapes
1. Client crée commande → `status = 'pending'`
2. Restaurant accepte → `status = 'confirmed'`
3. Livreur accepte → `livreur_id = [ID_LIVREUR]`
4. **Client annule** (changement d'avis, erreur...)
   - Vérifier si annulation possible (selon statut)
   - Si `status = 'confirmed'` ou `'preparing'` → Annulation possible avec frais
   - Si `status = 'ready'` ou `'picked_up'` → Annulation impossible

### Règles d'annulation client
```dart
bool canClientCancel(String status) {
  switch (status) {
    case 'pending':
      return true; // Gratuit
    case 'confirmed':
      return true; // Frais 10%
    case 'preparing':
      return true; // Frais 30%
    case 'ready':
    case 'picked_up':
      return false; // Impossible
    default:
      return false;
  }
}
```

### Résultat
❌ **Commande annulée avec frais**
- Client paie des frais d'annulation (10-30%)
- Restaurant compensé pour préparation
- Livreur compensé pour déplacement

---

## 📊 TABLEAU DES STATUTS

| Statut | Description | Peut annuler ? |
|--------|-------------|----------------|
| `pending` | En attente restaurant | Client ✅ (gratuit), Restaurant ✅ |
| `confirmed` | Restaurant accepté | Client ✅ (frais 10%), Restaurant ✅, Livreur ✅ |
| `preparing` | En préparation | Client ✅ (frais 30%), Restaurant ✅, Livreur ✅ |
| `ready` | Prêt à récupérer | Restaurant ✅, Livreur ✅ |
| `picked_up` | En livraison | Livreur ✅ (urgence) |
| `delivered` | Livré | ❌ Aucune annulation |
| `cancelled` | Annulé | - |

---

## 🔔 NOTIFICATIONS À IMPLÉMENTER

### Client
- ✅ Restaurant a accepté
- ❌ Restaurant a refusé
- ⏱️ Restaurant ne répond pas
- ✅ Livreur assigné
- ❌ Livreur a annulé
- 🚗 Livreur en route
- 📦 Commande livrée

### Restaurant
- 🔔 Nouvelle commande
- ✅ Livreur assigné
- ❌ Livreur a annulé
- ❌ Client a annulé
- ⏱️ Aucun livreur disponible

### Livreur
- 🔔 Nouvelle commande disponible
- ✅ Commande assignée
- ❌ Restaurant a annulé
- ❌ Client a annulé
- 📦 Commande prête à récupérer

---

## 🎯 RECOMMANDATIONS

### Timeouts recommandés
- **Restaurant répond** : 5-10 minutes max
- **Livreur accepte** : 5-10 minutes max
- **Restaurant prépare** : Selon `estimated_delivery_time`

### Compensations recommandées
- **Livreur annule** : Aucune compensation (sauf urgence)
- **Restaurant annule après acceptation** : 50-100 DA au livreur
- **Client annule** :
  - Avant préparation : 10% de frais
  - Pendant préparation : 30% de frais
  - Après préparation : Impossible

### Pénalités recommandées
- **Restaurant** : Taux d'annulation > 20% → Avertissement
- **Livreur** : > 3 annulations/jour → Suspension temporaire
- **Client** : > 5 annulations/mois → Avertissement

---

## 🚀 PROCHAINES ÉTAPES

1. **Implémenter les timeouts automatiques**
2. **Ajouter les notifications en temps réel**
3. **Créer les interfaces d'annulation**
4. **Implémenter le système de compensation**
5. **Ajouter les règles de pénalité**
6. **Tester tous les scénarios**

---

**Date de création** : 14 janvier 2026
