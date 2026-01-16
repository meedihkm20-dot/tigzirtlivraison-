# RÈGLES SCHÉMA SQL - SOURCE DE VÉRITÉ

## Fichier de référence
`supabase/SOURCE_DE_VERITE.sql` est la SEULE source de vérité pour les noms de colonnes et tables.

## ⚠️ NOMS DE COLONNES CRITIQUES

### INTERDITS → CORRECTS
| ❌ NE JAMAIS UTILISER | ✅ UTILISER |
|----------------------|-------------|
| `driver_id` | `livreur_id` |
| `delivery_lat` | `delivery_latitude` |
| `delivery_lng` | `delivery_longitude` |
| `total_amount` | `total` |
| `preparing_at` | `prepared_at` |
| `'accepted'` (status) | `'confirmed'` |

### Status de commande valides (SQL)
```
'pending', 'confirmed', 'preparing', 'ready', 'picked_up', 'delivering', 'delivered', 'cancelled'
```

## Règles de développement

1. **Avant toute modification** de code touchant aux commandes, livreurs, ou restaurants:
   - Consulter `supabase/SOURCE_DE_VERITE.sql`
   - Vérifier les noms de colonnes exacts

2. **Backend NestJS** (`backend/src/`):
   - Types dans `backend/src/types/database.types.ts`
   - Toujours utiliser les noms SQL exacts

3. **Flutter** (`apps/dz_delivery/`):
   - Modèles dans `lib/core/models/database_models.dart`
   - Providers dans `lib/providers/`
   - Toujours utiliser les noms SQL exacts dans les requêtes Supabase

4. **Panier**:
   - Géré en mémoire via `cartProvider` (pas de table SQL)
   - Converti en `order_items` lors de la création de commande

## Fichiers synchronisés

Ces fichiers DOIVENT être synchronisés avec SOURCE_DE_VERITE.sql:
- `backend/src/types/database.types.ts`
- `apps/dz_delivery/lib/core/models/database_models.dart`
- `SCHEMA_REFERENCE.md`
