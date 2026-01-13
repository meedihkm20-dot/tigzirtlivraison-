# DZ Delivery - Configuration Supabase

## 🚀 Mise en route

### 1. Créer un projet Supabase

1. Allez sur [supabase.com](https://supabase.com)
2. Créez un compte gratuit
3. Cliquez sur "New Project"
4. Choisissez un nom (ex: `dz-delivery`)
5. Définissez un mot de passe pour la base de données
6. Sélectionnez la région la plus proche (Europe West)

### 2. Exécuter les migrations

Dans le SQL Editor de Supabase, exécutez les fichiers dans cet ordre:

1. **001_initial_schema.sql** - Crée les tables
2. **002_indexes_and_rls.sql** - Ajoute les index et politiques de sécurité
3. **003_functions_and_triggers.sql** - Ajoute les fonctions et triggers

### 3. Configurer le Storage

1. Allez dans Storage
2. Créez ces buckets (tous publics):
   - `avatars` - Photos de profil
   - `restaurant-images` - Logos et covers des restaurants
   - `menu-images` - Photos des plats

### 4. Récupérer les clés API

1. Allez dans Settings → API
2. Copiez:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon public key**: `eyJhbGciOiJIUzI1NiIs...`

### 5. Configurer les apps Flutter

Mettez à jour les fichiers suivants avec vos clés:

```
apps/customer_app/lib/core/services/supabase_service.dart
apps/livreur_app/lib/core/services/supabase_service.dart
apps/restaurant_app/lib/core/services/supabase_service.dart
```

Remplacez:
```dart
static const String supabaseUrl = 'https://YOUR_PROJECT_ID.supabase.co';
static const String supabaseAnonKey = 'YOUR_ANON_KEY';
```

## 📊 Structure de la base de données

### Tables principales

| Table | Description |
|-------|-------------|
| `profiles` | Profils utilisateurs (étend auth.users) |
| `restaurants` | Informations des restaurants |
| `menu_categories` | Catégories du menu |
| `menu_items` | Plats du menu |
| `livreurs` | Profils des livreurs |
| `orders` | Commandes |
| `order_items` | Articles des commandes |
| `reviews` | Avis clients |
| `livreur_locations` | Historique positions GPS |
| `notifications` | Notifications in-app |
| `fcm_tokens` | Tokens Firebase pour push |

### Fonctions RPC

| Fonction | Description |
|----------|-------------|
| `get_nearby_restaurants(lat, lng, radius)` | Restaurants à proximité |
| `get_available_livreurs(lat, lng, radius)` | Livreurs disponibles |
| `get_restaurant_stats(restaurant_id)` | Statistiques restaurant |

### Statuts de commande

```
pending → confirmed → preparing → ready → picked_up → delivering → delivered
                                                                  ↘ cancelled
```

## 🔒 Sécurité (RLS)

Row Level Security est activé sur toutes les tables:

- **Clients**: Voient leurs propres commandes et profil
- **Restaurants**: Voient leurs commandes et peuvent gérer leur menu
- **Livreurs**: Voient les commandes assignées et peuvent mettre à jour leur position
- **Tous**: Peuvent voir les restaurants et menus publics

## 📱 Realtime

Les apps utilisent Supabase Realtime pour:

- **Customer App**: Suivi de commande en temps réel, position du livreur
- **Livreur App**: Nouvelles commandes disponibles
- **Restaurant App**: Nouvelles commandes entrantes

## 💰 Limites du plan gratuit

- 500 MB de base de données
- 1 GB de stockage fichiers
- 2 GB de bande passante
- 50,000 utilisateurs actifs/mois
- Realtime: 200 connexions simultanées

**Estimation de capacité**: ~30 restaurants, ~20 livreurs, ~2000 clients, ~100 commandes/jour

## 🔧 Commandes utiles

```bash
# Installer Supabase CLI (optionnel)
npm install -g supabase

# Lier au projet
supabase link --project-ref YOUR_PROJECT_ID

# Appliquer les migrations
supabase db push
```

## 📝 Créer des données de test

```sql
-- Créer un restaurant de test
INSERT INTO restaurants (owner_id, name, address, latitude, longitude, cuisine_type, is_verified)
VALUES (
  'USER_UUID_HERE',
  'Restaurant Test',
  'Alger Centre',
  36.7538,
  3.0588,
  'Fast Food',
  true
);

-- Créer un livreur de test
INSERT INTO livreurs (user_id, vehicle_type, is_verified, is_online, is_available)
VALUES (
  'USER_UUID_HERE',
  'moto',
  true,
  true,
  true
);
```
