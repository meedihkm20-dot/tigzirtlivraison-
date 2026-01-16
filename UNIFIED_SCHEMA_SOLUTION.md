# 🔧 SOLUTION: Schéma Unifié - Source de Vérité Unique

## 📋 Problèmes Identifiés

### 1. Divergences Backend ↔ SQL
| Backend (DTO/Service) | SQL (Correct) | Action |
|----------------------|---------------|--------|
| `delivery_lat` | `delivery_latitude` | ✅ Mapper dans service |
| `delivery_lng` | `delivery_longitude` | ✅ Mapper dans service |
| `cancelled_by` | ❌ N'existe pas | ⚠️ Ajouter au SQL |
| `driver_id` (delivery.service) | `livreur_id` | ✅ Déjà corrigé |

### 2. Colonnes manquantes dans SQL
- `cancelled_by` (utilisé par backend pour tracer qui annule)

### 3. Tables utilisées par Flutter mais pas Backend
- `order_messages` (chat)
- `livreur_locations` (tracking)
- `saved_addresses`
- `favorites`

### 4. Tables utilisées par Backend mais pas Flutter
- Aucune divergence majeure

---

## ✅ SOLUTION EN 3 ÉTAPES

### Étape 1: Migration SQL (ajouter colonnes manquantes)
Fichier: `supabase/migrations/102_unified_schema_fix.sql`

### Étape 2: Types Backend synchronisés
Fichier: `backend/src/types/database.types.ts` (déjà fait)

### Étape 3: Modèles Flutter synchronisés
Fichier: `apps/dz_delivery/lib/core/models/database_models.dart` (déjà fait)

---

## 📁 Architecture Finale

```
┌─────────────────────────────────────────────────────────────┐
│                    SOURCE DE VÉRITÉ                         │
│                                                             │
│   supabase/migrations/000_complete_schema.sql               │
│   + supabase/migrations/102_unified_schema_fix.sql          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                           │
           ┌───────────────┼───────────────┐
           ▼               ▼               ▼
┌─────────────────┐ ┌─────────────┐ ┌─────────────────┐
│   BACKEND       │ │   FLUTTER   │ │   ADMIN APP     │
│   NestJS        │ │   dz_delivery│ │   admin_app     │
│                 │ │             │ │                 │
│ database.types  │ │ database_   │ │ (même modèles)  │
│ .ts             │ │ models.dart │ │                 │
└─────────────────┘ └─────────────┘ └─────────────────┘
```

---

## 🗄️ Tables Complètes (Source de Vérité)

### Tables Principales
1. `profiles` - Utilisateurs (tous rôles)
2. `restaurants` - Restaurants
3. `menu_categories` - Catégories de menu
4. `menu_items` - Plats
5. `livreurs` - Livreurs
6. `orders` - Commandes
7. `order_items` - Items de commande
8. `reviews` - Avis

### Tables Support
9. `transactions` - Transactions financières
10. `notifications` - Notifications
11. `commission_settings` - Paramètres commissions
12. `delivery_pricing` - Tarification livraison
13. `delivery_zones` - Zones de livraison

### Tables Flutter-Only (lecture directe)
14. `order_messages` - Chat commande
15. `livreur_locations` - Tracking GPS
16. `saved_addresses` - Adresses sauvegardées
17. `favorites` - Restaurants favoris
18. `favorite_items` - Plats favoris
19. `promotions` - Promotions
20. `referrals` - Parrainages

### Tables Gamification Livreur
21. `livreur_badges` - Badges
22. `livreur_bonuses` - Bonus
23. `tier_config` - Configuration tiers
24. `livreur_targets` - Objectifs

---

## 🔄 Workflow de Modification

```
1. MODIFIER LE SQL
   └── supabase/migrations/XXX_description.sql
   └── Mettre à jour supabase/SCHEMA_MASTER.sql

2. METTRE À JOUR BACKEND
   └── backend/src/types/database.types.ts
   └── Vérifier les DTOs si nécessaire

3. METTRE À JOUR FLUTTER
   └── apps/dz_delivery/lib/core/models/database_models.dart

4. METTRE À JOUR SCHEMA_REFERENCE.md
   └── Documentation pour l'équipe

5. TESTER
   └── Backend: npm run test
   └── Flutter: flutter analyze
```
