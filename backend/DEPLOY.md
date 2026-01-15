# 🚀 Guide de Déploiement Complet

## Prérequis

- ✅ Compte GitHub (gratuit)
- ✅ Compte Koyeb (gratuit, sans carte)
- ✅ Compte OneSignal (gratuit)
- ✅ Projet Supabase existant

---

## Étape 1 : Configurer OneSignal (5 min)

### 1.1 Créer un compte
1. Aller sur https://onesignal.com
2. Sign Up (gratuit, sans carte bancaire)

### 1.2 Créer une app
1. Dashboard → "New App"
2. Nom: `Tigzirt Livraison`
3. Platform: `Android` (et iOS si besoin)

### 1.3 Configurer Android
1. Settings → Platforms → Android
2. Vous aurez besoin d'une **Firebase Server Key**:
   - Aller sur https://console.firebase.google.com
   - Créer un projet (ou utiliser existant)
   - Project Settings → Cloud Messaging
   - Copier la "Server Key"
3. Coller dans OneSignal

### 1.4 Récupérer les clés
Dans OneSignal Dashboard → Settings → Keys & IDs:
- **App ID**: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`
- **REST API Key**: `xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

---

## Étape 2 : Récupérer les clés Supabase

Dans le dashboard Supabase → Settings → API:
- **URL**: `https://xxxxx.supabase.co`
- **service_role key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

⚠️ Utiliser la **service_role key** (pas l'anon key)

---

## Étape 3 : Push vers GitHub

### 3.1 Créer le repo GitHub
1. https://github.com/new
2. Nom: `tigzirt-backend`
3. Public ou Private
4. Ne pas initialiser avec README

### 3.2 Push le code

```powershell
cd backend

# Initialiser git
git init
git add .
git commit -m "Initial commit - Backend NestJS + OneSignal"

# Connecter à GitHub
git remote add origin https://github.com/VOTRE_USERNAME/tigzirt-backend.git
git branch -M main
git push -u origin main
```

---

## Étape 4 : Déployer sur Koyeb (5 min)

### 4.1 Créer un compte Koyeb
1. Aller sur https://www.koyeb.com
2. Sign Up avec GitHub (recommandé)
3. **Aucune carte bancaire requise**

### 4.2 Créer l'application
1. Dashboard → "Create App"
2. Choisir "GitHub"
3. Autoriser l'accès au repo `tigzirt-backend`

### 4.3 Configurer le build

```
┌─────────────────────────────────────────────────┐
│  Source                                         │
│  ──────                                         │
│  Repository: tigzirt-backend                    │
│  Branch: main                                   │
│                                                 │
│  Build settings                                 │
│  ──────────────                                 │
│  Builder: Dockerfile ✓                          │
│                                                 │
│  Run settings                                   │
│  ────────────                                   │
│  Port: 3000                                     │
└─────────────────────────────────────────────────┘
```

### 4.4 Variables d'environnement

Cliquer "Add Variable" pour chaque:

| Name | Value |
|------|-------|
| `PORT` | `3000` |
| `NODE_ENV` | `production` |
| `SUPABASE_URL` | `https://xxxxx.supabase.co` |
| `SUPABASE_SERVICE_KEY` | `eyJxxx...` |
| `ONESIGNAL_APP_ID` | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `ONESIGNAL_API_KEY` | `xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx` |

### 4.5 Déployer
1. Cliquer "Deploy"
2. Attendre 2-3 minutes
3. URL générée: `https://tigzirt-backend-xxx.koyeb.app`

---

## Étape 5 : Tester le déploiement

```bash
# Health check
curl https://VOTRE-APP.koyeb.app/health

# Réponse attendue:
# {"status":"ok","timestamp":"...","service":"tigzirt-liv-backend"}
```

Swagger UI: `https://VOTRE-APP.koyeb.app/api/docs`

---

## Étape 6 : Mettre à jour les apps Flutter

### 6.1 Modifier l'URL du backend

Dans `apps/dz_delivery/lib/core/services/backend_api_service.dart`:

```dart
static const String baseUrl = 'https://VOTRE-APP.koyeb.app';
```

Même chose pour `apps/admin_app/lib/core/services/backend_api_service.dart`

### 6.2 Ajouter OneSignal

Dans `pubspec.yaml` des deux apps:

```yaml
dependencies:
  onesignal_flutter: ^5.1.0
```

### 6.3 Configurer l'App ID OneSignal

Dans `onesignal_service.dart`:

```dart
static const String appId = 'VOTRE_ONESIGNAL_APP_ID';
```

---

## 🔄 Mises à jour automatiques

Koyeb redéploie automatiquement à chaque push sur `main`:

```bash
git add .
git commit -m "Update"
git push
# → Koyeb redéploie automatiquement
```

---

## 📊 Monitoring

- **Logs**: Dashboard Koyeb → Votre app → Logs
- **Métriques**: Dashboard Koyeb → Votre app → Metrics
- **Health**: `GET /health`

---

## 🆘 Troubleshooting

### Le build échoue
- Vérifier les logs de build dans Koyeb
- S'assurer que le Dockerfile est correct

### 502 Bad Gateway
- L'app n'a pas démarré
- Vérifier les variables d'environnement
- Vérifier les logs

### Notifications ne fonctionnent pas
- Vérifier ONESIGNAL_APP_ID et ONESIGNAL_API_KEY
- Vérifier que l'utilisateur est connecté à OneSignal (login)

---

## ✅ Checklist finale

- [ ] OneSignal configuré
- [ ] Clés Supabase récupérées
- [ ] Code poussé sur GitHub
- [ ] App déployée sur Koyeb
- [ ] Variables d'environnement configurées
- [ ] Health check OK
- [ ] URL mise à jour dans Flutter
- [ ] onesignal_flutter ajouté aux apps
