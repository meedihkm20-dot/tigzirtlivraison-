import 'package:flutter/material.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/pending_approval_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/orders/presentation/order_detail_screen.dart';
import '../../features/orders/presentation/orders_history_screen.dart';
import '../../features/menu/presentation/menu_screen.dart';
import '../../features/menu/presentation/add_item_screen.dart';
import '../../features/stats/presentation/stats_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String pendingApproval = '/pending-approval';
  static const String home = '/home';
  static const String orderDetail = '/order-detail';
  static const String ordersHistory = '/orders-history';
  static const String menu = '/menu';
  static const String addItem = '/add-item';
  static const String stats = '/stats';
  static const String profile = '/profile';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case pendingApproval:
        return MaterialPageRoute(builder: (_) => const PendingApprovalScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case orderDetail:
        final orderId = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: orderId));
      case ordersHistory:
        return MaterialPageRoute(builder: (_) => const OrdersHistoryScreen());
      case menu:
        return MaterialPageRoute(builder: (_) => const MenuScreen());
      case addItem:
        return MaterialPageRoute(builder: (_) => const AddItemScreen());
      case stats:
        return MaterialPageRoute(builder: (_) => const StatsScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      default:
        return MaterialPageRoute(builder: (_) => Scaffold(body: Center(child: Text('Page not found: ${settings.name}'))));
    }
  }
}
