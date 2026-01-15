# Tests Backend - DZ Delivery

## Installation

```bash
cd backend
npm install
```

## Lancer les tests

### Tests unitaires
```bash
npm test
```

### Tests en mode watch (développement)
```bash
npm run test:watch
```

### Tests avec couverture de code
```bash
npm run test:cov
```

### Tests E2E (End-to-End)
```bash
npm run test:e2e
```

## Structure des tests

```
backend/
├── src/
│   └── modules/
│       ├── delivery/
│       │   └── delivery.service.spec.ts    # Tests unitaires
│       └── health/
│           └── health.controller.spec.ts   # Tests unitaires
└── test/
    ├── app.e2e-spec.ts                     # Tests E2E
    └── jest-e2e.json                       # Config Jest E2E
```

## Tests implémentés

### ✅ DeliveryService
- Calcul du prix de livraison
- Application des multiplicateurs de zone
- Arrondi au 10 DA près
- Estimation du temps de livraison

### ✅ HealthController
- Endpoint de santé
- Validation du timestamp
- Vérification de l'uptime

### ✅ Tests E2E
- Health check endpoint
- Calculate delivery price endpoint
- Estimate delivery time endpoint

## Couverture de code

Après `npm run test:cov`, ouvrir `coverage/lcov-report/index.html`

## Prochains tests à ajouter

- [ ] OrdersService (création, statuts, annulation)
- [ ] NotificationsService (OneSignal)
- [ ] Auth guards
- [ ] DTOs validation
- [ ] Webhooks

## CI/CD

Les tests seront automatiquement exécutés sur GitHub Actions avant chaque build.
