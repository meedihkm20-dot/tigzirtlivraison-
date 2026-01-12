import 'package:flutter/material.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/orders/presentation/order_detail_screen.dart';
import '../../features/orders/presentation/delivery_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/earnings/presentation/earnings_screen.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String orderDetail = '/order-detail';
  static const String delivery = '/delivery';
  static const String profile = '/profile';
  static const String earnings = '/earnings';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case orderDetail:
        final orderId = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: orderId));
      case delivery:
        final orderId = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => DeliveryScreen(orderId: orderId));
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case earnings:
        return MaterialPageRoute(builder: (_) => const EarningsScreen());
      default:
        return MaterialPageRoute(builder: (_) => Scaffold(body: Center(child: Text('Page not found: ${settings.name}'))));
    }
  }
}
