import 'package:flutter/material.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen_v2.dart';
import '../../features/restaurants/presentation/restaurants_screen.dart';
import '../../features/restaurants/presentation/restaurants_management_screen.dart';
import '../../features/livreurs/presentation/livreurs_screen.dart';
import '../../features/livreurs/presentation/livreurs_management_screen.dart';
import '../../features/orders/presentation/orders_screen_v2.dart';
import '../../features/finance/presentation/finance_screen.dart';
import '../../features/incidents/presentation/incidents_screen.dart';
import '../../features/audit/presentation/audit_logs_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/settings/presentation/system_settings_screen.dart';
import '../../features/pricing/presentation/screens/pricing_management_screen.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String restaurants = '/restaurants';
  static const String restaurantsManagement = '/restaurants-management';
  static const String livreurs = '/livreurs';
  static const String livreursManagement = '/livreurs-management';
  static const String orders = '/orders';
  static const String finance = '/finance';
  static const String incidents = '/incidents';
  static const String auditLogs = '/audit-logs';
  static const String settings = '/settings';
  static const String systemSettings = '/system-settings';
  static const String pricing = '/pricing';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreenV2());
      case restaurants:
        return MaterialPageRoute(builder: (_) => const RestaurantsScreen());
      case restaurantsManagement:
        return MaterialPageRoute(builder: (_) => const RestaurantsManagementScreen());
      case livreurs:
        return MaterialPageRoute(builder: (_) => const LivreursScreen());
      case livreursManagement:
        return MaterialPageRoute(builder: (_) => const LivreursManagementScreen());
      case orders:
        return MaterialPageRoute(builder: (_) => const OrdersScreenV2());
      case finance:
        return MaterialPageRoute(builder: (_) => const FinanceScreen());
      case incidents:
        return MaterialPageRoute(builder: (_) => const IncidentsScreen());
      case auditLogs:
        return MaterialPageRoute(builder: (_) => const AuditLogsScreen());
      case settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case systemSettings:
        return MaterialPageRoute(builder: (_) => const SystemSettingsScreen());
      case pricing:
        return MaterialPageRoute(builder: (_) => const PricingManagementScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Route non trouvée: ${settings.name}')),
          ),
        );
    }
  }
}
