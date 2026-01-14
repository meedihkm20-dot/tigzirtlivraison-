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
import '../../features/customer/presentation/notifications_screen.dart';
import '../../features/customer/presentation/favorites_screen.dart';
import '../../features/customer/presentation/saved_addresses_screen.dart';
import '../../features/customer/presentation/live_tracking_screen.dart';
import '../../features/customer/presentation/reorder_screen.dart';
import '../../features/customer/presentation/referral_screen.dart';
import '../../features/shared/presentation/chat_screen.dart';
// Restaurant
import '../../features/restaurant/presentation/restaurant_home_screen.dart';
import '../../features/restaurant/presentation/screens/restaurant_dashboard_screen.dart';
import '../../features/restaurant/presentation/screens/kitchen_screen_v2.dart';
import '../../features/restaurant/presentation/screens/stats_screen_v2.dart';
import '../../features/restaurant/presentation/screens/stock_management_screen.dart';
import '../../features/restaurant/presentation/screens/team_management_screen.dart';
import '../../features/restaurant/presentation/screens/reports_screen.dart';
import '../../features/restaurant/presentation/screens/settings_screen.dart';
import '../../features/restaurant/presentation/menu_screen.dart';
import '../../features/restaurant/presentation/restaurant_order_detail_screen.dart';
import '../../features/restaurant/presentation/stats_screen.dart';
import '../../features/restaurant/presentation/restaurant_profile_screen.dart';
import '../../features/restaurant/presentation/kitchen_screen.dart';
import '../../features/restaurant/presentation/promotions_screen.dart';
// Customer V2
import '../../features/customer/presentation/screens/restaurant_detail_screen_v2.dart';
import '../../features/customer/presentation/screens/customer_home_screen_v2.dart';
import '../../features/customer/presentation/screens/cart_screen_v2.dart';
import '../../features/customer/presentation/screens/order_tracking_screen_v2.dart';
import '../../features/customer/presentation/screens/customer_profile_screen_v2.dart';
// Livreur
import '../../features/livreur/presentation/livreur_home_screen.dart';
import '../../features/livreur/presentation/delivery_screen.dart';
import '../../features/livreur/presentation/earnings_screen.dart';
import '../../features/livreur/presentation/livreur_profile_screen.dart';
import '../../features/livreur/presentation/badges_screen.dart';
import '../../features/livreur/presentation/tier_progress_screen.dart';
// Livreur V2
import '../../features/livreur/presentation/screens/livreur_home_screen_v2.dart';
import '../../features/livreur/presentation/screens/delivery_screen_v2.dart';
import '../../features/livreur/presentation/screens/earnings_screen_v2.dart';
import '../../features/livreur/presentation/screens/tier_progress_screen_v2.dart';

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
  static const String statsV2 = '/restaurant/stats-v2';
  static const String restaurantProfile = '/restaurant/profile';
  static const String kitchen = '/restaurant/kitchen';
  static const String promotions = '/restaurant/promotions';
  static const String stockManagement = '/restaurant/stock';
  static const String teamManagement = '/restaurant/team';
  static const String reports = '/restaurant/reports';
  static const String restaurantSettings = '/restaurant/settings';
  
  // Livreur
  static const String livreurHome = '/livreur/home';
  static const String delivery = '/livreur/delivery';
  static const String earnings = '/livreur/earnings';
  static const String livreurProfile = '/livreur/profile';
  static const String badges = '/livreur/badges';
  static const String tierProgress = '/livreur/tier-progress';
  
  // Customer extras
  static const String notifications = '/customer/notifications';
  static const String favorites = '/customer/favorites';
  static const String savedAddresses = '/customer/addresses';
  static const String liveTracking = '/customer/live-tracking';
  static const String reorder = '/customer/reorder';
  static const String referral = '/customer/referral';
  static const String chat = '/chat';

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
      
      // Customer - Using V2 screens
      case customerHome:
        return MaterialPageRoute(builder: (_) => const CustomerHomeScreenV2());
      case restaurantDetail:
        final restaurantId = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => RestaurantDetailScreenV2(restaurantId: restaurantId));
      case cart:
        return MaterialPageRoute(builder: (_) => const CartScreenV2());
      case customerOrders:
        return MaterialPageRoute(builder: (_) => const OrdersScreen());
      case orderTracking:
        final orderId = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => OrderTrackingScreenV2(orderId: orderId));
      case customerProfile:
        return MaterialPageRoute(builder: (_) => const CustomerProfileScreenV2());
      
      // Restaurant
      case restaurantHome:
        return MaterialPageRoute(builder: (_) => const RestaurantDashboardScreen());
      case menu:
        return MaterialPageRoute(builder: (_) => const MenuScreen());
      case restaurantOrderDetail:
        final orderId = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => RestaurantOrderDetailScreen(orderId: orderId));
      case stats:
        return MaterialPageRoute(builder: (_) => const StatsScreen());
      case statsV2:
        return MaterialPageRoute(builder: (_) => const StatsScreenV2());
      case restaurantProfile:
        return MaterialPageRoute(builder: (_) => const RestaurantProfileScreen());
      case stockManagement:
        return MaterialPageRoute(builder: (_) => const StockManagementScreen());
      case teamManagement:
        return MaterialPageRoute(builder: (_) => const TeamManagementScreen());
      case reports:
        return MaterialPageRoute(builder: (_) => const ReportsScreen());
      case restaurantSettings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      
      // Livreur - Using V2 screens
      case livreurHome:
        return MaterialPageRoute(builder: (_) => const LivreurHomeScreenV2());
      case delivery:
        final orderId = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => DeliveryScreenV2(orderId: orderId));
      case earnings:
        return MaterialPageRoute(builder: (_) => const EarningsScreenV2());
      case livreurProfile:
        return MaterialPageRoute(builder: (_) => const LivreurProfileScreen());
      case badges:
        return MaterialPageRoute(builder: (_) => const BadgesScreen());
      case tierProgress:
        return MaterialPageRoute(builder: (_) => const TierProgressScreenV2());
      
      // Customer extras
      case notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());
      case favorites:
        return MaterialPageRoute(builder: (_) => const FavoritesScreen());
      case savedAddresses:
        return MaterialPageRoute(builder: (_) => const SavedAddressesScreen());
      case liveTracking:
        final orderId = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => LiveTrackingScreen(orderId: orderId));
      case reorder:
        return MaterialPageRoute(builder: (_) => const ReorderScreen());
      case referral:
        return MaterialPageRoute(builder: (_) => const ReferralScreen());
      case chat:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(builder: (_) => ChatScreen(
          orderId: args['orderId'],
          recipientName: args['recipientName'],
          isLivreur: args['isLivreur'] ?? false,
        ));
      
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
        return MaterialPageRoute(builder: (_) => const KitchenScreenV2());
      case promotions:
        return MaterialPageRoute(builder: (_) => const PromotionsScreen());
      
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(body: Center(child: Text('Page non trouvée: ${settings.name}'))),
        );
    }
  }
}
