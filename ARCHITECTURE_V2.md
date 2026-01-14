# 🏗️ ARCHITECTURE V2 - DZ DELIVERY PREMIUM

## 📊 ANALYSE GLOBALE

### État actuel
- Architecture basique (features/presentation seulement)
- Pas de séparation Domain/Data
- Services monolithiques
- Thème simple sans mode sombre
- Pas de state management structuré

### Objectif V2
- Clean Architecture complète
- State management avec Riverpod
- Design System premium
- Offline-first
- Analytics intégrés
- IA & suggestions

---

## 🏛️ NOUVELLE ARCHITECTURE

```
lib/
├── core/
│   ├── config/
│   │   ├── app_config.dart
│   │   ├── env_config.dart
│   │   └── feature_flags.dart
│   ├── constants/
│   │   ├── app_constants.dart
│   │   ├── api_constants.dart
│   │   └── storage_keys.dart
│   ├── design_system/
│   │   ├── theme/
│   │   │   ├── app_theme.dart
│   │   │   ├── app_colors.dart
│   │   │   ├── app_typography.dart
│   │   │   ├── app_spacing.dart
│   │   │   └── app_shadows.dart
│   │   ├── components/
│   │   │   ├── buttons/
│   │   │   ├── cards/
│   │   │   ├── inputs/
│   │   │   ├── dialogs/
│   │   │   ├── loaders/
│   │   │   └── badges/
│   │   └── animations/
│   │       ├── fade_animation.dart
│   │       ├── slide_animation.dart
│   │       └── scale_animation.dart
│   ├── extensions/
│   │   ├── context_extensions.dart
│   │   ├── string_extensions.dart
│   │   ├── datetime_extensions.dart
│   │   └── num_extensions.dart
│   ├── router/
│   │   └── app_router.dart
│   ├── services/
│   │   ├── analytics_service.dart
│   │   ├── cache_service.dart
│   │   ├── connectivity_service.dart
│   │   ├── location_service.dart
│   │   ├── notification_service.dart
│   │   ├── sound_service.dart
│   │   └── haptic_service.dart
│   └── utils/
│       ├── validators.dart
│       ├── formatters.dart
│       └── helpers.dart
│
├── data/
│   ├── datasources/
│   │   ├── remote/
│   │   │   ├── supabase_datasource.dart
│   │   │   └── api_client.dart
│   │   └── local/
│   │       ├── hive_datasource.dart
│   │       └── secure_storage.dart
│   ├── models/
│   │   ├── restaurant_model.dart
│   │   ├── menu_item_model.dart
│   │   ├── order_model.dart
│   │   ├── user_model.dart
│   │   └── ...
│   └── repositories/
│       ├── restaurant_repository_impl.dart
│       ├── order_repository_impl.dart
│       └── ...
│
├── domain/
│   ├── entities/
│   │   ├── restaurant.dart
│   │   ├── menu_item.dart
│   │   ├── order.dart
│   │   └── ...
│   ├── repositories/
│   │   ├── restaurant_repository.dart
│   │   ├── order_repository.dart
│   │   └── ...
│   └── usecases/
│       ├── restaurant/
│       │   ├── get_restaurant_stats.dart
│       │   ├── update_menu_item.dart
│       │   └── ...
│       └── order/
│           ├── create_order.dart
│           ├── update_order_status.dart
│           └── ...
│
├── features/
│   ├── restaurant/
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   ├── widgets/
│   │   │   └── controllers/
│   │   └── providers/
│   ├── customer/
│   ├── livreur/
│   └── auth/
│
└── main.dart
```

---

## 🎨 DESIGN SYSTEM V2

### Palette de couleurs

```dart
// core/design_system/theme/app_colors.dart
class AppColors {
  // Primary
  static const primary = Color(0xFFFF6B35);
  static const primaryLight = Color(0xFFFF8F66);
  static const primaryDark = Color(0xFFE55A2B);
  
  // Secondary
  static const secondary = Color(0xFF004E89);
  static const secondaryLight = Color(0xFF3373A3);
  static const secondaryDark = Color(0xFF003A66);
  
  // Status
  static const success = Color(0xFF06D6A0);
  static const warning = Color(0xFFFFD23F);
  static const error = Color(0xFFEE4266);
  static const info = Color(0xFF3B82F6);
  
  // Neutrals
  static const background = Color(0xFFF8F9FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF1F3F4);
  static const outline = Color(0xFFE0E0E0);
  
  // Text
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF6B7280);
  static const textTertiary = Color(0xFF9CA3AF);
  static const textOnPrimary = Color(0xFFFFFFFF);
  
  // Dark mode
  static const darkBackground = Color(0xFF121212);
  static const darkSurface = Color(0xFF1E1E1E);
  static const darkSurfaceVariant = Color(0xFF2D2D2D);
  
  // Gradients
  static const primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const successGradient = LinearGradient(
    colors: [success, Color(0xFF34D399)],
  );
}
```

### Typographie
```dart
// core/design_system/theme/app_typography.dart
class AppTypography {
  static const fontFamily = 'Poppins';
  static const fontFamilyMono = 'RobotoMono';
  
  // Headings
  static const h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );
  
  static const h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.3,
  );
  
  static const h3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  
  // Body
  static const bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );
  
  static const bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );
  
  static const bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.4,
  );
  
  // Labels
  static const labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
  
  // Numbers (for prices)
  static const price = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    fontFamily: fontFamilyMono,
  );
}
```

### Spacing
```dart
// core/design_system/theme/app_spacing.dart
class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
  
  static const cardPadding = EdgeInsets.all(16);
  static const screenPadding = EdgeInsets.all(16);
  static const listItemPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);
}
```

### Shadows
```dart
// core/design_system/theme/app_shadows.dart
class AppShadows {
  static const sm = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];
  
  static const md = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];
  
  static const lg = [
    BoxShadow(
      color: Color(0x1F000000),
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];
  
  static const colored = (Color color) => [
    BoxShadow(
      color: color.withOpacity(0.3),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];
}
```

---

## 🗄️ SCHÉMA BASE DE DONNÉES V2

### Nouvelles tables à créer
