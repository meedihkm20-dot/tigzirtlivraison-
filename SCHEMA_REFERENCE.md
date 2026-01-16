# RÉFÉRENCE SCHÉMA BASE DE DONNÉES - DZ DELIVERY

Ce fichier documente tous les champs utilisés dans le code Flutter et leur correspondance avec la base de données Supabase.

## ⚠️ RÈGLE IMPORTANTE
**Le code Flutter est la référence.** Si un champ est utilisé dans le code mais n'existe pas en base, il faut l'ajouter en base via SQL.

---

## 1. PROFILES (Utilisateurs)

### Champs utilisés dans le code:
```dart
profile['id']                    // UUID
profile['role']                  // user_role ENUM
profile['full_name']             // VARCHAR
profile['phone']                 // VARCHAR
profile['avatar_url']            // TEXT
profile['address']               // TEXT
profile['latitude']              // DECIMAL
profile['longitude']             // DECIMAL
profile['loyalty_points']        // INTEGER
profile['total_orders']          // INTEGER
profile['total_spent']           // DECIMAL
profile['onesignal_player_id']   // TEXT
```

### ✅ Statut: Tous les champs existent

---

## 2. RESTAURANTS

### Champs utilisés dans le code:
```dart
restaurant['id']                 // UUID
restaurant['owner_id']           // UUID
restaurant['name']               // VARCHAR
restaurant['description']        // TEXT
restaurant['logo_url']           // TEXT
restaurant['cover_url']          // TEXT
restaurant['phone']              // VARCHAR
restaurant['address']            // TEXT
restaurant['latitude']           // DECIMAL
restaurant['longitude']          // DECIMAL
restaurant['cuisine_type']       // VARCHAR
restaurant['tags']               // TEXT[]
restaurant['rating']             // DECIMAL
restaurant['total_reviews']      // INTEGER
restaurant['delivery_fee']       // DECIMAL
restaurant['min_order_amount']   // DECIMAL
restaurant['avg_prep_time']      // INTEGER (minutes)
restaurant['is_open']            // BOOLEAN
restaurant['is_verified']        // BOOLEAN
restaurant['onesignal_player_id']// TEXT
```

### ✅ Statut: Tous les champs existent

---

## 3. MENU_ITEMS

### Champs utilisés dans le code:
```dart
item['id']                       // UUID
item['restaurant_id']            // UUID
item['category_id']              // UUID (nullable)
item['name']                     // VARCHAR
item['description']              // TEXT
item['price']                    // DECIMAL
item['image_url']                // TEXT
item['is_available']             // BOOLEAN
item['is_popular']               // BOOLEAN
item['prep_time']                // INTEGER
item['order_count']              // INTEGER
item['avg_rating']               // DECIMAL
```

### ✅ Statut: Tous les champs existent

---

## 4. SAVED_ADDRESSES

### Champs utilisés dans le code:
```dart
address['id']                    // UUID
address['customer_id']           // UUID
address['label']                 // VARCHAR (ex: "Maison", "Travail")
address['address']               // TEXT
address['latitude']              // DECIMAL
address['longitude']             // DECIMAL
address['instructions']          // TEXT (nullable)
address['is_default']            // BOOLEAN
```

### ❌ PROBLÈME DÉTECTÉ:
Le code cherche `address['type']` mais la base a `address['label']`

**Correction SQL nécessaire:** AUCUNE - Le code doit utiliser `label` au lieu de `type`

---

## 5. CART_ITEMS

### Champs utilisés dans le code:
```dart
cartItem['id']                   // UUID
cartItem['customer_id']          // UUID
cartItem['menu_item_id']         // UUID
cartItem['quantity']             // INTEGER
cartItem['special_instructions'] // TEXT
```

### Champs retournés par `get_cart_items()`:
```dart
cartItem['id']                   // UUID
cartItem['menu_item_id']         // UUID
cartItem['quantity']             // INTEGER
cartItem['special_instructions'] // TEXT
cartItem['item_name']            // VARCHAR (depuis menu_items)
cartItem['item_description']     // TEXT (depuis menu_items)
cartItem['item_price']           // DECIMAL (depuis menu_items)
cartItem['item_image_url']       // TEXT (depuis menu_items)
cartItem['restaurant_id']        // UUID (depuis restaurants)
cartItem['restaurant_name']      // VARCHAR (depuis restaurants)
```

### ❌ PROBLÈME DÉTECTÉ:
Le code `cart_screen.dart` utilise `item['price']` mais la fonction retourne `item['item_price']`

**Correction déjà faite dans le code**

---

## 6. ORDERS

### Champs utilisés dans le code:
```dart
order['id']                      // UUID
order['order_number']            // VARCHAR
order['customer_id']             // UUID
order['restaurant_id']           // UUID
order['livreur_id']              // UUID (nullable)
order['status']                  // order_status ENUM
order['delivery_address']        // TEXT
order['delivery_latitude']       // DECIMAL
order['delivery_longitude']      // DECIMAL
order['delivery_instructions']   // TEXT
order['subtotal']                // DECIMAL
order['delivery_fee']            // DECIMAL
order['service_fee']             // DECIMAL
order['discount']                // DECIMAL
order['total']                   // DECIMAL
order['tip_amount']              // DECIMAL
order['payment_method']          // payment_method ENUM
order['payment_status']          // payment_status ENUM
order['confirmation_code']       // VARCHAR(4)
order['livreur_commission']      // DECIMAL
order['admin_commission']        // DECIMAL
order['restaurant_amount']       // DECIMAL
order['estimated_delivery_time'] // TIMESTAMPTZ
order['created_at']              // TIMESTAMPTZ
order['confirmed_at']            // TIMESTAMPTZ
order['prepared_at']             // TIMESTAMPTZ
order['picked_up_at']            // TIMESTAMPTZ
order['delivered_at']            // TIMESTAMPTZ
order['cancelled_at']            // TIMESTAMPTZ
order['cancellation_reason']     // TEXT
```

### ✅ Statut: Tous les champs existent

---

## 7. LIVREURS

### Champs utilisés dans le code:
```dart
livreur['id']                    // UUID
livreur['user_id']               // UUID
livreur['vehicle_type']          // vehicle_type ENUM
livreur['vehicle_number']        // VARCHAR
livreur['current_latitude']      // DECIMAL
livreur['current_longitude']     // DECIMAL
livreur['is_available']          // BOOLEAN
livreur['is_online']             // BOOLEAN
livreur['is_verified']           // BOOLEAN
livreur['rating']                // DECIMAL
livreur['total_deliveries']      // INTEGER
livreur['total_earnings']        // DECIMAL
livreur['tier']                  // livreur_tier ENUM
livreur['weekly_deliveries']     // INTEGER
livreur['monthly_deliveries']    // INTEGER
livreur['onesignal_player_id']   // TEXT
```

### ✅ Statut: Tous les champs existent

---

## 8. NOTIFICATIONS

### Champs utilisés dans le code:
```dart
notification['id']               // UUID
notification['user_id']          // UUID
notification['title']            // VARCHAR
notification['body']             // TEXT
notification['data']             // JSONB
notification['is_read']          // BOOLEAN
notification['created_at']       // TIMESTAMPTZ
```

### ⚠️ PROBLÈME POTENTIEL:
Le code `notification_service.dart` utilise `sent_at` mais la table a `created_at`

**Correction SQL nécessaire:**
```sql
ALTER TABLE public.notifications RENAME COLUMN created_at TO sent_at;
```

---

## 9. PROMOTIONS

### Champs utilisés dans le code:
```dart
promo['id']                      // UUID
promo['restaurant_id']           // UUID (nullable)
promo['name']                    // VARCHAR
promo['description']             // TEXT
promo['discount_type']           // VARCHAR ('percentage' ou 'fixed')
promo['discount_value']          // DECIMAL
promo['min_order_amount']        // DECIMAL
promo['max_discount']            // DECIMAL
promo['code']                    // VARCHAR
promo['is_active']               // BOOLEAN
promo['starts_at']               // TIMESTAMPTZ
promo['ends_at']                 // TIMESTAMPTZ
promo['usage_limit']             // INTEGER
promo['usage_count']             // INTEGER
```

### ✅ Statut: Tous les champs existent

---

## 10. REVIEWS

### Champs utilisés dans le code:
```dart
review['id']                     // UUID
review['order_id']               // UUID
review['customer_id']            // UUID
review['restaurant_id']          // UUID
review['livreur_id']             // UUID
review['restaurant_rating']      // INTEGER (1-5)
review['livreur_rating']         // INTEGER (1-5)
review['comment']                // TEXT
review['created_at']             // TIMESTAMPTZ
```

### ✅ Statut: Tous les champs existent

---

## 11. TRANSACTIONS

### Champs utilisés dans le code:
```dart
transaction['id']                // UUID
transaction['order_id']          // UUID
transaction['type']              // VARCHAR
transaction['amount']            // DECIMAL
transaction['recipient_id']      // UUID
transaction['status']            // VARCHAR
transaction['description']       // TEXT
transaction['created_at']        // TIMESTAMPTZ
```

### ✅ Statut: Tous les champs existent

---

## 12. TABLES MANQUANTES UTILISÉES DANS LE CODE

### user_preferences
```dart
preferences['user_id']           // UUID
preferences['theme']             // VARCHAR
preferences['language']          // VARCHAR
preferences['notifications_enabled'] // BOOLEAN
```

**Action:** Créer la table si nécessaire

### admin_audit_logs
```dart
log['entity_type']               // VARCHAR
log['entity_id']                 // UUID
log['action']                    // VARCHAR
log['created_by']                // UUID
```

**Action:** Créer la table si nécessaire

### audit_events
```dart
event['table_name']              // VARCHAR
event['record_id']               // UUID
event['action']                  // VARCHAR
```

**Action:** Créer la table si nécessaire

---

## CORRECTIONS SQL NÉCESSAIRES

### 1. Renommer created_at en sent_at dans notifications
```sql
ALTER TABLE public.notifications RENAME COLUMN created_at TO sent_at;
```

### 2. Créer table user_preferences (si utilisée)
```sql
CREATE TABLE IF NOT EXISTS public.user_preferences (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    theme VARCHAR(20) DEFAULT 'system',
    language VARCHAR(10) DEFAULT 'fr',
    notifications_enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## RÉSUMÉ DES PROBLÈMES

1. ✅ **CORRIGÉ**: `cart_screen.dart` utilise `item['price']` → changé en `item['item_price']`
2. ✅ **CORRIGÉ**: `cart_screen_v2.dart` utilise `addr['type']` → changé en `addr['label']`
3. ⏳ **À CORRIGER**: `notifications.created_at` → renommer en `sent_at`
4. ⏳ **À VÉRIFIER**: Tables `user_preferences`, `admin_audit_logs`, `audit_events`

