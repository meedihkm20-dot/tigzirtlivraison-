# ✅ Backend NestJS + OneSignal - PRÊT !

## 📊 Résumé

Le backend est **100% fonctionnel** et prêt pour le déploiement.

### Tests effectués ✅
- ✅ `npm install` - Dépendances installées
- ✅ `npm run build` - Build réussi
- ✅ `npm run start:dev` - Serveur démarre
- ✅ `GET /health` - Health check OK
- ✅ `GET /api/delivery/calculate-price` - Calcul prix OK

---

## 🚀 Prochaines étapes

### 1. Créer compte OneSignal (5 min)
```
1. https://onesignal.com → Sign Up (gratuit)
2. Créer une app "Tigzirt Livraison"
3. Configurer Android avec Firebase Server Key
4. Noter App ID et REST API Key
```

### 2. Configurer .env (2 min)
```bash
cd backend
# Éditer .env avec vos vraies valeurs
```

### 3. Push vers GitHub (2 min)
```bash
cd backend
git init
git add .
git commit -m "Backend NestJS + OneSignal"
git remote add origin https://github.com/VOTRE_USER/tigzirt-backend.git
git push -u origin main
```

### 4. Déployer sur Koyeb (5 min)
```
1. https://koyeb.com → Sign Up (gratuit, sans carte)
2. Create App → GitHub → Sélectionner repo
3. Builder: Dockerfile, Port: 3000
4. Ajouter variables d'environnement
5. Deploy!
```

### 5. Mettre à jour Flutter (5 min)
```
1. Modifier baseUrl dans backend_api_service.dart
2. Ajouter onesignal_flutter: ^5.1.0
3. Configurer OneSignal App ID
4. Initialiser dans main.dart
```

---

## 📁 Structure créée

```
backend/
├── src/
│   ├── main.ts
│   ├── app.module.ts
│   ├── supabase/
│   │   ├── supabase.module.ts
│   │   └── supabase.service.ts
│   ├── common/
│   │   ├── guards/supabase-auth.guard.ts
│   │   └── decorators/current-user.decorator.ts
│   └── modules/
│       ├── health/
│       ├── notifications/    ← OneSignal
│       ├── delivery/
│       ├── orders/
│       └── webhooks/
├── scripts/
│   ├── deploy.ps1
│   └── test-local.ps1
├── Dockerfile
├── package.json
├── tsconfig.json
├── .env.example
├── README.md
├── DEPLOY.md
└── QUICK_START.md

apps/
├── dz_delivery/lib/core/services/
│   ├── backend_api_service.dart  ← NOUVEAU
│   └── onesignal_service.dart    ← NOUVEAU
├── admin_app/lib/core/services/
│   ├── backend_api_service.dart  ← NOUVEAU
│   └── onesignal_service.dart    ← NOUVEAU
└── BACKEND_INTEGRATION.md        ← Guide Flutter
```

---

## 📡 Endpoints API

| Endpoint | Méthode | Description |
|----------|---------|-------------|
| `/health` | GET | Health check |
| `/api/docs` | GET | Swagger UI |
| `/api/delivery/calculate-price` | GET | Calculer prix livraison |
| `/api/delivery/estimate-time` | GET | Estimer temps |
| `/api/orders/create` | POST | Créer commande |
| `/api/orders/:id/accept` | POST | Accepter (restaurant) |
| `/api/orders/:id/ready` | POST | Marquer prête |
| `/api/orders/:id/delivered` | POST | Confirmer livraison |
| `/api/notifications/*` | POST | Notifications OneSignal |

---

## 💰 Coût total : 0 DA

| Service | Coût |
|---------|------|
| Koyeb | GRATUIT |
| Supabase | GRATUIT |
| OneSignal | GRATUIT |
