import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/design_system/theme/app_theme_v2.dart';
import 'core/router/app_router.dart';
import 'core/services/supabase_service.dart';
import 'core/services/preferences_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  await SupabaseService.init();
  await Hive.initFlutter();
  await Hive.openBox('settings');
  await Hive.openBox('cart');
  await PreferencesService.init();
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(const ProviderScope(child: DZDeliveryApp()));
}

class DZDeliveryApp extends StatefulWidget {
  const DZDeliveryApp({super.key});

  // Global key for theme switching
  static final GlobalKey<_DZDeliveryAppState> appKey = GlobalKey<_DZDeliveryAppState>();

  static void setThemeMode(ThemeMode mode) {
    appKey.currentState?.setThemeMode(mode);
  }

  @override
  State<DZDeliveryApp> createState() => _DZDeliveryAppState();
}

class _DZDeliveryAppState extends State<DZDeliveryApp> {
  ThemeMode _themeMode = PreferencesService.themeMode;

  void setThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      key: DZDeliveryApp.appKey,
      title: 'DZ Delivery',
      debugShowCheckedModeBanner: false,
      theme: AppThemeV2.lightTheme,
      darkTheme: AppThemeV2.darkTheme,
      themeMode: _themeMode,
      initialRoute: AppRouter.splash,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
