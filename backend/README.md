# 🚀 Tigzirt Livraison - Backend NestJS

Backend API pour DZ Delivery avec notifications push OneSignal.

## 💰 Stack 100% GRATUITE

| Service | Coût | Carte requise |
|---------|------|---------------|
| Koyeb | Gratuit | ❌ Non |
| Supabase | Gratuit | ❌ Non |
| OneSignal | Gratuit | ❌ Non |

## 🏗️ Architecture

```
📱 Apps Flutter (dz_delivery + admin_app)
│
├──→ 🖥️ Backend NestJS (Koyeb)
│         │
│         ├──→ 🔔 OneSignal (Push notifications)
│         │
│         ▼
└──→ 🗄️ Supabase (BDD, Auth, Realtime)
```

## 📦 Installation locale

```bash
cd backend
npm install
cp .env.example .env
# Remplir les variables dans .env
npm run start:dev
```

## 🔧 Variables d'environnement

| Variable | Description |
|----------|-------------|
| `PORT` | Port du serveur (3000) |
| `SUPABASE_URL` | URL projet Supabase |
| `SUPABASE_SERVICE_KEY` | Service key Supabase |
| `ONESIGNAL_APP_ID` | App ID OneSignal |
| `ONESIGNAL_API_KEY` | REST API Key OneSignal |

## 📡 Endpoints API

### Health
- `GET /health` - Health check

### Orders (authentifié)
- `POST /api/orders/create` - Créer commande
- `POST /api/orders/:id/accept` - Accepter (restaurant)
- `POST /api/orders/:id/ready` - Marquer prête
- `POST /api/orders/:id/delivered` - Confirmer livraison

### Delivery
- `GET /api/delivery/calculate-price?distance=5&zone=tigzirt`
- `GET /api/delivery/estimate-time?distance=5&preparation_time=15`
- `POST /api/delivery/assign-driver`

### Notifications
- `POST /api/notifications/test`
- `POST /api/notifications/new-order`
- `POST /api/notifications/order-accepted`
- etc.

### Documentation
- `GET /api/docs` - Swagger UI

## 🚀 Déploiement Koyeb

Voir `DEPLOY.md` pour le guide complet.

```bash
# Quick deploy
.\scripts\deploy.ps1
```

## 🧪 Tests

```bash
# Test local
.\scripts\test-local.ps1

# Ou manuellement
curl http://localhost:3000/health
```
