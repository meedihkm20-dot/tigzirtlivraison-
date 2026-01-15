# 🔔 Intégration OneSignal - DZ Delivery

## 1. Ajouter la dépendance

Dans `pubspec.yaml`, ajouter :

```yaml
dependencies:
  onesignal_flutter: ^5.1.0
```

Puis exécuter :
```bash
flutter pub get
```

## 2. Modifier main.dart

```dart
import 'core/services/onesignal_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Services existants
  await SupabaseService.init();
  await Hive.initFlutter();
  // ...
  
  // ✅ AJOUTER: Initialiser OneSignal
  await OneSignalService.initialize();
  
  runApp(const ProviderScope(child: DZDeliveryApp()));
}
```

## 3. Lier utilisateur après connexion

Dans ton service d'authentification ou écran de login :

```dart
// Après connexion réussie
final user = Supabase.instance.client.auth.currentUser;
if (user != null) {
  // Récupérer le profil pour le rôle
  final profile = await supabase.from('profiles').select().eq('id', user.id).single();
  
  // Lier à OneSignal
  await OneSignalService.login(user.id, role: profile['role']);
}
```

## 4. Déconnecter de OneSignal

```dart
// Lors de la déconnexion
await OneSignalService.logout();
await Supabase.instance.client.auth.signOut();
```

## 5. Configuration Android

Dans `android/app/build.gradle` :

```gradle
android {
    defaultConfig {
        // ...
        manifestPlaceholders += [
            onesignal_app_id: 'TON_ONESIGNAL_APP_ID',
            onesignal_google_project_number: 'REMOTE'
        ]
    }
}
```

## 6. Configuration iOS (optionnel)

Dans Xcode :
1. Activer "Push Notifications" capability
2. Activer "Background Modes" → Remote notifications

## 7. Décommenter le code

Dans `onesignal_service.dart`, décommenter tout le code OneSignal.

## 8. Obtenir les clés OneSignal

1. Créer compte sur https://onesignal.com (gratuit)
2. Créer une app
3. Configurer Android (Firebase Cloud Messaging)
4. Récupérer :
   - App ID → `onesignal_service.dart`
   - REST API Key → Backend `.env`
