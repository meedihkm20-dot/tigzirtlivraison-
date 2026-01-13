import 'package:supabase_flutter/supabase_flutter.dart';

/// Service Supabase centralisé pour l'app Restaurant
class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;
  
  // TODO: Remplacer par vos vraies clés Supabase
  static const String supabaseUrl = 'https://YOUR_PROJECT_ID.supabase.co';
  static const String supabaseAnonKey = 'YOUR_ANON_KEY';

  /// Initialise Supabase
  static Future<void> init() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      realtimeClientOptions: const RealtimeClientOptions(
        eventsPerSecond: 2,
      ),
    );
  }

  static User? get currentUser => client.auth.currentUser;
  static bool get isLoggedIn => currentUser != null;

  // ============================================
  // AUTH
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

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  // ============================================
  // RESTAURANT PROFILE
  // ============================================
  
  /// Récupérer mon restaurant
  static Future<Map<String, dynamic>?> getMyRestaurant() async {
    if (currentUser == null) return null;
    final response = await client
        .from('restaurants')
        .select()
        .eq('owner_id', currentUser!.id)
        .single();
    return response;
  }

  /// Mettre à jour le restaurant
  static Future<void> updateRestaurant(Map<String, dynamic> data) async {
    if (currentUser == null) return;
    await client
        .from('restaurants')
        .update(data)
        .eq('owner_id', currentUser!.id);
  }

  /// Ouvrir/Fermer le restaurant
  static Future<void> setRestaurantOpen(bool isOpen) async {
    await updateRestaurant({'is_open': isOpen});
  }

  // ============================================
  // MENU MANAGEMENT
  // ============================================
  
  /// Récupérer les catégories du menu
  static Future<List<Map<String, dynamic>>> getMenuCategories() async {
    final restaurant = await getMyRestaurant();
    if (restaurant == null) return [];
    
    final response = await client
        .from('menu_categories')
        .select()
        .eq('restaurant_id', restaurant['id'])
        .order('sort_order');
    return List<Map<String, dynamic>>.from(response);
  }

  /// Ajouter une catégorie
  static Future<void> addCategory(String name, String? description) async {
    final restaurant = await getMyRestaurant();
    if (restaurant == null) return;
    
    await client.from('menu_categories').insert({
      'restaurant_id': restaurant['id'],
      'name': name,
      'description': description,
    });
  }

  /// Récupérer les items du menu
  static Future<List<Map<String, dynamic>>> getMenuItems() async {
    final restaurant = await getMyRestaurant();
    if (restaurant == null) return [];
    
    final response = await client
        .from('menu_items')
        .select('*, category:menu_categories(name)')
        .eq('restaurant_id', restaurant['id'])
        .order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  /// Ajouter un item au menu
  static Future<void> addMenuItem({
    required String name,
    required double price,
    String? description,
    String? categoryId,
    String? imageUrl,
    int prepTime = 15,
  }) async {
    final restaurant = await getMyRestaurant();
    if (restaurant == null) return;
    
    await client.from('menu_items').insert({
      'restaurant_id': restaurant['id'],
      'category_id': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'prep_time': prepTime,
    });
  }

  /// Mettre à jour un item
  static Future<void> updateMenuItem(String itemId, Map<String, dynamic> data) async {
    await client.from('menu_items').update(data).eq('id', itemId);
  }

  /// Supprimer un item
  static Future<void> deleteMenuItem(String itemId) async {
    await client.from('menu_items').delete().eq('id', itemId);
  }

  /// Changer la disponibilité d'un item
  static Future<void> setItemAvailability(String itemId, bool isAvailable) async {
    await updateMenuItem(itemId, {'is_available': isAvailable});
  }

  // ============================================
  // ORDERS
  // ============================================
  
  /// Récupérer les commandes en attente
  static Future<List<Map<String, dynamic>>> getPendingOrders() async {
    final restaurant = await getMyRestaurant();
    if (restaurant == null) return [];
    
    final response = await client
        .from('orders')
        .select('*, customer:profiles!customer_id(full_name, phone), order_items(*)')
        .eq('restaurant_id', restaurant['id'])
        .inFilter('status', ['pending', 'confirmed', 'preparing'])
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Récupérer les commandes du jour
  static Future<List<Map<String, dynamic>>> getTodayOrders() async {
    final restaurant = await getMyRestaurant();
    if (restaurant == null) return [];
    
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    
    final response = await client
        .from('orders')
        .select('*, customer:profiles!customer_id(full_name), order_items(*)')
        .eq('restaurant_id', restaurant['id'])
        .gte('created_at', startOfDay.toIso8601String())
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Récupérer l'historique des commandes
  static Future<List<Map<String, dynamic>>> getOrderHistory({int limit = 50}) async {
    final restaurant = await getMyRestaurant();
    if (restaurant == null) return [];
    
    final response = await client
        .from('orders')
        .select('*, customer:profiles!customer_id(full_name)')
        .eq('restaurant_id', restaurant['id'])
        .inFilter('status', ['delivered', 'cancelled'])
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Confirmer une commande
  static Future<void> confirmOrder(String orderId, int prepTimeMinutes) async {
    final estimatedTime = DateTime.now().add(Duration(minutes: prepTimeMinutes));
    await client.from('orders').update({
      'status': 'confirmed',
      'confirmed_at': DateTime.now().toIso8601String(),
      'estimated_delivery_time': estimatedTime.toIso8601String(),
    }).eq('id', orderId);
  }

  /// Marquer comme en préparation
  static Future<void> startPreparing(String orderId) async {
    await client.from('orders').update({
      'status': 'preparing',
    }).eq('id', orderId);
  }

  /// Marquer comme prêt
  static Future<void> markAsReady(String orderId) async {
    await client.from('orders').update({
      'status': 'ready',
      'prepared_at': DateTime.now().toIso8601String(),
    }).eq('id', orderId);
  }

  /// Annuler une commande
  static Future<void> cancelOrder(String orderId, String reason) async {
    await client.from('orders').update({
      'status': 'cancelled',
      'cancelled_at': DateTime.now().toIso8601String(),
      'cancellation_reason': reason,
    }).eq('id', orderId);
  }

  // ============================================
  // REALTIME - Nouvelles commandes
  // ============================================
  
  /// S'abonner aux nouvelles commandes
  static RealtimeChannel subscribeToNewOrders(
    String restaurantId,
    void Function(Map<String, dynamic>) onNewOrder,
  ) {
    return client
        .channel('restaurant_orders_$restaurantId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'restaurant_id',
            value: restaurantId,
          ),
          callback: (payload) {
            onNewOrder(payload.newRecord);
          },
        )
        .subscribe();
  }

  /// S'abonner aux mises à jour des commandes
  static RealtimeChannel subscribeToOrderUpdates(
    String restaurantId,
    void Function(Map<String, dynamic>) onUpdate,
  ) {
    return client
        .channel('restaurant_order_updates_$restaurantId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'restaurant_id',
            value: restaurantId,
          ),
          callback: (payload) {
            onUpdate(payload.newRecord);
          },
        )
        .subscribe();
  }

  static Future<void> unsubscribe(RealtimeChannel channel) async {
    await client.removeChannel(channel);
  }

  // ============================================
  // STATISTICS
  // ============================================
  
  /// Récupérer les statistiques
  static Future<Map<String, dynamic>> getStats() async {
    final restaurant = await getMyRestaurant();
    if (restaurant == null) {
      return {
        'total_orders': 0,
        'total_revenue': 0,
        'orders_today': 0,
        'revenue_today': 0,
        'avg_order_value': 0,
        'pending_orders': 0,
      };
    }
    
    final response = await client.rpc('get_restaurant_stats', params: {
      'restaurant_uuid': restaurant['id'],
    });
    
    if (response is List && response.isNotEmpty) {
      return Map<String, dynamic>.from(response.first);
    }
    return {
      'total_orders': 0,
      'total_revenue': 0,
      'orders_today': 0,
      'revenue_today': 0,
      'avg_order_value': 0,
      'pending_orders': 0,
    };
  }

  // ============================================
  // STORAGE
  // ============================================
  
  /// Upload une image de plat
  static Future<String?> uploadMenuItemImage(String itemId, List<int> bytes) async {
    final path = 'menu_items/$itemId.jpg';
    await client.storage.from('menu-images').uploadBinary(path, bytes as dynamic);
    return client.storage.from('menu-images').getPublicUrl(path);
  }
}
