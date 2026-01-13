import 'package:flutter/material.dart';
// Auth
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/pending_approval_screen.dart';
// Customer
import '../../features/customer/presentation/customer_home_screen.dart';
import '../../features/customer/presentation/restaurant_detail_screen.dart';
import '../../features/customer/presentation/cart_screen.dart';
import '../../features/customer/presentation/orders_screen.dart';
import '../../features/customer/presentation/order_tracking_screen.dart';
import '../../features/customer/presentation/customer_profile_screen.dart';
import '../../features/customer/presentation/review_screen.dart';
// Restaurant
import '../../features/restaurant/presentation/restaurant_home_screen.dart';
import '../../features/restaurant/presentation/menu_screen.dart';
import '../../features/restaurant/presentation/restaurant_order_detail_screen.dart';
import '../../features/restaurant/presentation/stats_screen.dart';
import '../../features/restaurant/presentation/restaurant_profile_screen.dart';
import '../../features/restaurant/presentation/kitchen_screen.dart';
import '../../features/restaurant/presentation/promotions_screen.dart';
// Livreur
import '../../features/livreur/presentation/livreur_home_screen.dart';
import '../../features/livreur/presentation/delivery_screen.dart';
import '../../features/livreur/presentation/earnings_screen.dart';
import '../../features/livreur/presentation/livreur_profile_screen.dart';
import '../../features/livreur/presentation/badges_screen.dart';

class AppRouter {
  // Auth
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String pendingApproval = '/pending-approval';
  
  // Customer
  static const String customerHome = '/customer/home';
  static const String restaurantDetail = '/customer/restaurant';
  static const String cart = '/customer/cart';
  static const String customerOrders = '/customer/orders';
  static const String orderTracking = '/customer/order-tracking';
  static const String customerProfile = '/customer/profile';
  static const String review = '/customer/review';
  
  // Restaurant
  static const String restaurantHome = '/restaurant/home';
  static const String menu = '/restaurant/menu';
  static const String restaurantOrderDetail = '/restaurant/order';
  static const String stats = '/restaurant/stats';
  static const String restaurantProfile = '/restaurant/profile';
  static const String kitchen = '/restaurant/kitchen';
  static const String promotions = '/restaurant/promotions';
  
  // Livreur
  static const String livreurHome = '/livreur/home';
  static const String delivery = '/livreur/delivery';
  static const String earnings = '/livreur/earnings';
  static const String livreurProfile = '/livreur/profile';
  static const String badges = '/livreur/badges';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Auth
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case pendingApproval:
        final role = settings.arguments as String? ?? 'restaurant';
        return MaterialPageRoute(builder: (_) => PendingApprovalScreen(role: role));
      
      // Customer
      case customerHome:
        return MaterialPageRoute(builder: (_) => const CustomerHomeScreen());
      case restaurantDetail:
        final restaurantId = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => RestaurantDetailScreen(restaurantId: restaurantId));
      case cart:
        return MaterialPageRoute(builder: (_) => const CartScreen());
      case customerOrders:
        return MaterialPageRoute(builder: (_) => const OrdersScreen());
      case orderTracking:
        final orderId = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: orderId));
      case customerProfile:
        return MaterialPageRoute(builder: (_) => const CustomerProfileScreen());
      
      // Restaurant
      case restaurantHome:
        return MaterialPageRoute(builder: (_) => const RestaurantHomeScreen());
      case menu:
        return MaterialPageRoute(builder: (_) => const MenuScreen());
      case restaurantOrderDetail:
        final orderId = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => RestaurantOrderDetailScreen(orderId: orderId));
      case stats:
        return MaterialPageRoute(builder: (_) => const StatsScreen());
      case restaurantProfile:
        return MaterialPageRoute(builder: (_) => const RestaurantProfileScreen());
      
      // Livreur
      case livreurHome:
        return MaterialPageRoute(builder: (_) => const LivreurHomeScreen());
      case delivery:
        final orderId = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => DeliveryScreen(orderId: orderId));
      case earnings:
        return MaterialPageRoute(builder: (_) => const EarningsScreen());
      case livreurProfile:
        return MaterialPageRoute(builder: (_) => const LivreurProfileScreen());
      case badges:
        return MaterialPageRoute(builder: (_) => const BadgesScreen());
      
      // Customer - Review
      case review:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(builder: (_) => ReviewScreen(
          orderId: args['orderId'],
          restaurantName: args['restaurantName'],
          livreurName: args['livreurName'],
        ));
      
      // Restaurant - Kitchen & Promotions
      case kitchen:
        return MaterialPageRoute(builder: (_) => const KitchenScreen());
      case promotions:
        return MaterialPageRoute(builder: (_) => const PromotionsScreen());
      
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(body: Center(child: Text('Page non trouvée: ${settings.name}'))),
        );
    }
  }
}
