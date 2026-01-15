# 🔗 Intégration Backend NestJS + OneSignal

## 📦 Fichiers ajoutés

### dz_delivery
- `lib/core/services/backend_api_service.dart` - Service API backend
- `lib/core/services/onesignal_service.dart` - Service OneSignal

### admin_app
- `lib/core/services/backend_api_service.dart` - Service API backend
- `lib/core/services/onesignal_service.dart` - Service OneSignal

---

## 1️⃣ Ajouter la dépendance OneSignal

Dans `pubspec.yaml` des deux apps :

```yaml
dependencies:
  onesignal_flutter: ^5.1.0
```

Puis :
```bash
flutter pub get
```

---

## 2️⃣ Configurer l'URL du backend

Après déploiement sur Koyeb, modifier dans les deux apps :

`lib/core/services/backend_api_service.dart` :
```dart
static const String baseUrl = 'https://VOTRE-APP.koyeb.app';
```

---

## 3️⃣ Configurer OneSignal App ID

Dans `lib/core/services/onesignal_service.dart` :
```dart
static const String appId = 'VOTRE_ONESIGNAL_APP_ID';
```

Puis décommenter tout le code OneSignal dans le fichier.

---

## 4️⃣ Initialiser OneSignal dans main.dart

```dart
import 'core/services/onesignal_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Services existants...
  await SupabaseService.init();
  
  // ✅ AJOUTER
  await OneSignalService.initialize();
  
  runApp(const ProviderScope(child: DZDeliveryApp()));
}
```

---

## 5️⃣ Lier utilisateur après connexion

Dans votre logique d'authentification :

```dart
// Après connexion réussie
final user = Supabase.instance.client.auth.currentUser;
if (user != null) {
  final profile = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single();
  
  await OneSignalService.login(user.id, role: profile['role']);
}
```

---

## 6️⃣ Déconnecter de OneSignal

```dart
// Lors de la déconnexion
await OneSignalService.logout();
await Supabase.instance.client.auth.signOut();
```

---

## 7️⃣ Utiliser le service API

```dart
final api = BackendApiService(Supabase.instance.client);

// Calculer prix livraison
final price = await api.calculateDeliveryPrice(5.0, 'tigzirt');

// Créer commande
final result = await api.createOrder(
  restaurantId: 'xxx',
  items: [{'menu_item_id': 'yyy', 'quantity': 2}],
  deliveryAddress: '123 Rue...',
  deliveryLat: 36.xxx,
  deliveryLng: 4.xxx,
);

// Accepter commande (restaurant)
await api.acceptOrder('order_id');

// Marquer prête (restaurant)
await api.markOrderReady('order_id');

// Confirmer livraison (livreur)
await api.markOrderDelivered('order_id');
```

---

## 📱 Configuration Android

Dans `android/app/build.gradle` :

```gradle
android {
    defaultConfig {
        manifestPlaceholders += [
            onesignal_app_id: 'VOTRE_ONESIGNAL_APP_ID',
            onesignal_google_project_number: 'REMOTE'
        ]
    }
}
```

---

## 🍎 Configuration iOS (optionnel)

1. Ouvrir le projet dans Xcode
2. Signing & Capabilities → + Capability
3. Ajouter "Push Notifications"
4. Ajouter "Background Modes" → cocher "Remote notifications"
