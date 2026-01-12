# DZ Delivery Backend

Backend API pour l'application de livraison algérienne DZ Delivery.

## Installation

```bash
$ npm install
```

## Configuration

Copier le fichier d'environnement d'exemple:
```bash
$ cp .env.example .env
```

Configurer les variables d'environnement dans le fichier `.env`:
- Base de données PostgreSQL
- Redis pour le cache
- Firebase pour les notifications
- JWT pour l'authentification

## Base de données

Créer la base de données PostgreSQL et exécuter le schéma:
```bash
$ psql -U postgres -d dz_delivery -f database-schema.sql
```

## Lancement de l'application

```bash
# Mode développement
$ npm run start:dev

# Mode production
$ npm run build
$ npm run start:prod
```

## API Documentation

L'API sera disponible sur `http://localhost:3000/api`

## Architecture

- **Auth**: Authentification JWT avec refresh tokens
- **Users**: Gestion des utilisateurs et adresses
- **Restaurants**: Gestion des restaurants et menus
- **Livreurs**: Gestion des livreurs et géolocalisation
- **Orders**: Système de commandes avec WebSocket
- **Payments**: Intégration des paiements
- **Notifications**: Notifications push Firebase

## Technologies

- NestJS
- TypeORM
- PostgreSQL
- Redis
- Socket.io
- Firebase Admin
- JWT
- Bcrypt

## License

MIT
