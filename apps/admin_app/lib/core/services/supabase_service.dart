import 'package:supabase_flutter/supabase_flutter.dart';

/// Service Supabase centralisé pour l'app Admin
class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;
  
  static const String supabaseUrl = 'https://pauqmhqriyjdqctvfvtt.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBhdXFtaHFyaXlqZHFjdHZmdnR0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjgyNTgxNzksImV4cCI6MjA4MzgzNDE3OX0.ZdhrCmf465g2-dHf1DUMJ5GlR9t-kZnPvo7uvvoA0x8';

  static Future<void> init() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static User? get currentUser => client.auth.currentUser;
  static bool get isLoggedIn => currentUser != null;

  // ============================================
  // AUTH ADMIN
  // ============================================
  
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<bool> isAdmin() async {
    if (currentUser == null) return false;
    final profile = await client
        .from('profiles')
        .select('role')
        .eq('id', currentUser!.id)
        .single();
    return profile['role'] == 'admin';
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  // ============================================
  // RESTAURANTS MANAGEMENT
  // ============================================
  
  static Future<List<Map<String, dynamic>>> getAllRestaurants() async {
    final response = await client
        .from('restaurants')
        .select('*, owner:profiles!owner_id(full_name, phone, email:id)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<List<Map<String, dynamic>>> getPendingRestaurants() async {
    final response = await client
        .from('restaurants')
        .select('*, owner:profiles!owner_id(full_name, phone)')
        .eq('is_verified', false)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> verifyRestaurant(String restaurantId) async {
    await client.from('restaurants').update({
      'is_verified': true,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', restaurantId);
  }

  static Future<void> toggleRestaurantStatus(String restaurantId, bool isOpen) async {
    await client.from('restaurants').update({
      'is_open': isOpen,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', restaurantId);
  }

  static Future<void> deleteRestaurant(String restaurantId) async {
    await client.from('restaurants').delete().eq('id', restaurantId);
  }

  // ============================================
  // LIVREURS MANAGEMENT
  // ============================================
  
  static Future<List<Map<String, dynamic>>> getAllLivreurs() async {
    final response = await client
        .from('livreurs')
        .select('*, user:profiles!user_id(full_name, phone, email:id)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<List<Map<String, dynamic>>> getPendingLivreurs() async {
    final response = await client
        .from('livreurs')
        .select('*, user:profiles!user_id(full_name, phone)')
        .eq('is_verified', false)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> verifyLivreur(String livreurId) async {
    await client.from('livreurs').update({
      'is_verified': true,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', livreurId);
  }

  static Future<void> toggleLivreurStatus(String livreurId, bool isAvailable) async {
    await client.from('livreurs').update({
      'is_available': isAvailable,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', livreurId);
  }

  static Future<void> deleteLivreur(String livreurId) async {
    await client.from('livreurs').delete().eq('id', livreurId);
  }


  // ============================================
  // ORDERS MANAGEMENT
  // ============================================
  
  static Future<List<Map<String, dynamic>>> getAllOrders({int limit = 100}) async {
    final response = await client
        .from('orders')
        .select('''
          *,
          customer:profiles!customer_id(full_name, phone),
          restaurant:restaurants!restaurant_id(name),
          livreur:livreurs!livreur_id(user:profiles!user_id(full_name))
        ''')
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<List<Map<String, dynamic>>> getTodayOrders() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    
    final response = await client
        .from('orders')
        .select('*, restaurant:restaurants!restaurant_id(name)')
        .gte('created_at', startOfDay.toIso8601String())
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // ============================================
  // FINANCE & STATISTICS (avec commissions)
  // ============================================
  
  static Future<Map<String, dynamic>> getDashboardStats() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final startOfMonth = DateTime(today.year, today.month, 1);

    // Total restaurants
    final restaurantsCount = await client
        .from('restaurants')
        .select('id')
        .count(CountOption.exact);

    // Pending restaurants
    final pendingRestaurants = await client
        .from('restaurants')
        .select('id')
        .eq('is_verified', false)
        .count(CountOption.exact);

    // Total livreurs
    final livreursCount = await client
        .from('livreurs')
        .select('id')
        .count(CountOption.exact);

    // Pending livreurs
    final pendingLivreurs = await client
        .from('livreurs')
        .select('id')
        .eq('is_verified', false)
        .count(CountOption.exact);

    // Today orders avec commissions
    final todayOrders = await client
        .from('orders')
        .select('id, total, admin_commission, livreur_commission, restaurant_amount')
        .gte('created_at', startOfDay.toIso8601String());

    // Month orders
    final monthOrders = await client
        .from('orders')
        .select('id, total, admin_commission')
        .gte('created_at', startOfMonth.toIso8601String())
        .eq('status', 'delivered');

    // Calculate totals
    double todayRevenue = 0;
    double todayCommission = 0;
    for (var order in todayOrders) {
      todayRevenue += (order['total'] ?? 0).toDouble();
      todayCommission += (order['admin_commission'] ?? 0).toDouble();
    }

    double monthRevenue = 0;
    double monthCommission = 0;
    for (var order in monthOrders) {
      monthRevenue += (order['total'] ?? 0).toDouble();
      monthCommission += (order['admin_commission'] ?? 0).toDouble();
    }

    return {
      'total_restaurants': restaurantsCount.count,
      'pending_restaurants': pendingRestaurants.count,
      'total_livreurs': livreursCount.count,
      'pending_livreurs': pendingLivreurs.count,
      'today_orders': todayOrders.length,
      'today_revenue': todayRevenue,
      'today_commission': todayCommission,
      'month_orders': monthOrders.length,
      'month_revenue': monthRevenue,
      'month_commission': monthCommission,
    };
  }

  /// Stats admin avec les vraies commissions
  static Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final response = await client.rpc('get_admin_stats');
      if (response is List && response.isNotEmpty) {
        return Map<String, dynamic>.from(response.first);
      }
    } catch (e) {
      // Fallback si la fonction n'existe pas encore
    }
    return {
      'total_orders': 0,
      'total_revenue': 0,
      'total_admin_commission': 0,
      'today_orders': 0,
      'today_commission': 0,
      'pending_restaurant_payments': 0,
    };
  }

  /// Récupérer toutes les transactions
  static Future<List<Map<String, dynamic>>> getAllTransactions({int limit = 100}) async {
    try {
      final response = await client
          .from('transactions')
          .select('*, order:orders(order_number)')
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Paiements en attente pour les restaurants
  static Future<List<Map<String, dynamic>>> getPendingRestaurantPayments() async {
    try {
      final response = await client
          .from('transactions')
          .select('*, order:orders(order_number), restaurant:profiles!recipient_id(full_name)')
          .eq('type', 'restaurant_payment')
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Marquer un paiement restaurant comme effectué
  static Future<void> markPaymentCompleted(String transactionId) async {
    await client.from('transactions').update({
      'status': 'completed',
    }).eq('id', transactionId);
  }

  static Future<List<Map<String, dynamic>>> getRestaurantTransactions(String restaurantId) async {
    final response = await client
        .from('orders')
        .select('id, order_number, total, delivery_fee, admin_commission, restaurant_amount, status, created_at')
        .eq('restaurant_id', restaurantId)
        .eq('status', 'delivered')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>> getRestaurantFinanceStats(String restaurantId) async {
    final orders = await client
        .from('orders')
        .select('total, admin_commission, restaurant_amount, created_at')
        .eq('restaurant_id', restaurantId)
        .eq('status', 'delivered');

    double totalRevenue = 0;
    double totalCommission = 0;
    double netRevenue = 0;

    for (var order in orders) {
      totalRevenue += (order['total'] ?? 0).toDouble();
      totalCommission += (order['admin_commission'] ?? 0).toDouble();
      netRevenue += (order['restaurant_amount'] ?? 0).toDouble();
    }

    return {
      'total_orders': orders.length,
      'total_revenue': totalRevenue,
      'total_commission': totalCommission,
      'net_revenue': netRevenue,
    };
  }

  static Future<List<Map<String, dynamic>>> getAllRestaurantsWithStats() async {
    final restaurants = await getAllRestaurants();
    List<Map<String, dynamic>> result = [];

    for (var restaurant in restaurants) {
      final stats = await getRestaurantFinanceStats(restaurant['id']);
      result.add({
        ...restaurant,
        'stats': stats,
      });
    }

    return result;
  }

  static Future<Map<String, dynamic>> getGlobalFinanceReport() async {
    final today = DateTime.now();
    final startOfMonth = DateTime(today.year, today.month, 1);

    final deliveredOrders = await client
        .from('orders')
        .select('total, delivery_fee, admin_commission, livreur_commission, restaurant_amount, created_at')
        .eq('status', 'delivered');

    double totalRevenue = 0;
    double totalAdminCommission = 0;
    double totalLivreurCommission = 0;
    double totalRestaurantAmount = 0;
    double monthRevenue = 0;
    double monthCommission = 0;

    for (var order in deliveredOrders) {
      totalRevenue += (order['total'] ?? 0).toDouble();
      totalAdminCommission += (order['admin_commission'] ?? 0).toDouble();
      totalLivreurCommission += (order['livreur_commission'] ?? 0).toDouble();
      totalRestaurantAmount += (order['restaurant_amount'] ?? 0).toDouble();

      final createdAt = DateTime.parse(order['created_at']);
      if (createdAt.isAfter(startOfMonth)) {
        monthRevenue += (order['total'] ?? 0).toDouble();
        monthCommission += (order['admin_commission'] ?? 0).toDouble();
      }
    }

    return {
      'total_orders': deliveredOrders.length,
      'total_revenue': totalRevenue,
      'total_admin_commission': totalAdminCommission,
      'total_livreur_commission': totalLivreurCommission,
      'total_restaurant_amount': totalRestaurantAmount,
      'month_revenue': monthRevenue,
      'month_commission': monthCommission,
    };
  }
}
