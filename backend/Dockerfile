FROM node:20-alpine AS builder

WORKDIR /app

# Copier les fichiers de dépendances
COPY package*.json ./
COPY tsconfig.json ./
COPY nest-cli.json ./

# Installer toutes les dépendances (dev inclus pour build)
RUN npm ci

# Copier le code source
COPY src ./src

# Build
RUN npm run build

# Stage production
FROM node:20-alpine AS production

WORKDIR /app

# Copier package.json
COPY package*.json ./

# Installer uniquement les dépendances de production
RUN npm ci --only=production && npm cache clean --force

# Copier le build depuis le stage builder
COPY --from=builder /app/dist ./dist

# Utilisateur non-root pour la sécurité
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nestjs -u 1001 && \
    chown -R nestjs:nodejs /app

USER nestjs

EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

CMD ["node", "dist/main.js"]
