# ⚡ Quick Start - 10 minutes

## 1️⃣ Installer les dépendances (2 min)

```powershell
cd backend
npm install
```

## 2️⃣ Configurer l'environnement (3 min)

Éditer `backend/.env` avec vos vraies valeurs:

```env
PORT=3000
NODE_ENV=development
SUPABASE_URL=https://VOTRE_ID.supabase.co
SUPABASE_SERVICE_KEY=eyJ...
ONESIGNAL_APP_ID=xxx-xxx-xxx
ONESIGNAL_API_KEY=xxx...
```

## 3️⃣ Tester localement (1 min)

```powershell
npm run start:dev
```

Ouvrir: http://localhost:3000/api/docs

## 4️⃣ Déployer sur Koyeb (4 min)

```powershell
# Push vers GitHub
git init
git add .
git commit -m "Backend NestJS"
git remote add origin https://github.com/USER/tigzirt-backend.git
git push -u origin main
```

Puis sur https://koyeb.com:
1. Create App → GitHub
2. Sélectionner repo
3. Builder: Dockerfile, Port: 3000
4. Ajouter variables d'environnement
5. Deploy!

## ✅ C'est tout!

URL: `https://votre-app.koyeb.app`
Swagger: `https://votre-app.koyeb.app/api/docs`
