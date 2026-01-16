# VERSIONS DU PROJET - SOURCE DE VÉRITÉ

**Dernière mise à jour**: En attente du build CI

## ⚠️ RÈGLE IMPORTANTE
Toujours utiliser ces versions exactes lors des corrections et mises à jour.
Ne pas downgrader sans raison valide.

---

## Flutter & Dart

| Composant | Version | Notes |
|-----------|---------|-------|
| Flutter | stable (latest) | Workflow CI utilise `channel: stable` |
| Dart SDK | ^3.9.0 | Requis par flutter_lints 6.0.0 |

---

## Dépendances Flutter (dz_delivery)

| Package | Version | Usage |
|---------|---------|-------|
| flutter_riverpod | ^3.1.0 | State management |
| supabase_flutter | ^2.12.0 | Backend Supabase |
| firebase_core | ^4.3.0 | Firebase base |
| firebase_auth | ^6.1.3 | Auth Firebase |
| dio | ^5.9.0 | HTTP client |
| http | ^1.6.0 | HTTP requests |
| shared_preferences | ^2.5.4 | Local storage |
| hive | ^2.2.3 | Local DB |
| hive_flutter | ^1.1.0 | Hive Flutter |
| cached_network_image | ^3.4.1 | Image cache |
| shimmer | ^3.0.0 | Loading effects |
| intl | ^0.20.2 | Internationalization |
| fl_chart | ^1.1.1 | Charts |
| cupertino_icons | ^1.0.8 | iOS icons |
| url_launcher | ^6.3.2 | Open URLs |
| image_picker | ^1.2.1 | Pick images |
| flutter_map | ^8.2.2 | Maps OSM |
| latlong2 | ^0.9.1 | Coordinates |
| location | ^8.0.1 | Location service |
| geolocator | ^14.0.2 | Geolocation |
| flutter_tts | ^4.2.5 | Text to speech |
| permission_handler | ^12.0.1 | Permissions |
| audioplayers | ^6.5.1 | Audio playback |
| onesignal_flutter | ^5.3.5 | Push notifications |
| flutter_lints | ^6.0.0 | Linting |

---

## Dépendances Flutter (admin_app)

| Package | Version | Usage |
|---------|---------|-------|
| flutter_riverpod | ^3.1.0 | State management |
| supabase_flutter | ^2.12.0 | Backend Supabase |
| dio | ^5.9.0 | HTTP client |
| http | ^1.6.0 | HTTP requests |
| shared_preferences | ^2.5.4 | Local storage |
| intl | ^0.20.2 | Internationalization |
| fl_chart | ^1.1.1 | Charts |
| cupertino_icons | ^1.0.8 | iOS icons |
| data_table_2 | ^2.5.15 | Data tables |
| onesignal_flutter | ^5.3.5 | Push notifications |
| flutter_lints | ^6.0.0 | Linting |

---

## Android Build

| Composant | Version |
|-----------|---------|
| compileSdk | 36 |
| targetSdk | 35 |
| minSdk | 26 |
| Java | 21 |
| Kotlin JVM Target | 17 |
| Gradle | 8.13 |
| NDK | 27.0.12077973 |

---

## Backend (NestJS)

| Package | Version |
|---------|---------|
| Node.js | 20 |
| NestJS | (voir package.json) |

---

## Commandes utiles

```bash
# Mettre à jour les dépendances Flutter
cd apps/dz_delivery && flutter pub upgrade
cd apps/admin_app && flutter pub upgrade

# Vérifier les versions outdated
flutter pub outdated
```
