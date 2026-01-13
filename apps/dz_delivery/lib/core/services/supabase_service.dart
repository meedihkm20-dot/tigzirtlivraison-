import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service Supabase centralisé pour l'app DZ Delivery (multi-rôle)
class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;
  
  static const String supabaseUrl = 'https://pauqmhqriyjdqctvfvtt.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBhdXFtaHFyaXlqZHFjdHZmdnR0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjgyNTgxNzksImV4cCI6MjA4MzgzNDE3OX0.ZdhrCmf465g2-dHf1DUMJ5GlR9t-kZnPvo7uvvoA0x8';

  static Future<void> init() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      realtimeClientOptions: const RealtimeClientOptions(eventsPerSecond: 10),
    );
  }

  static User? get currentUser => client.auth.currentUser;
  static bool get isLoggedIn => currentUser != null;

  // ============================================
  // AUTH - COMMUN
  // ============================================
  
  static Future<AuthResponse> signIn({required String email, required String password}) async {
    return await client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// Récupère le rôle de l'utilisateur connecté
  static Future<String?> getUserRole() async {
    if (currentUser == null) return null;
    final profile = await client.from('profiles').select('role').eq('id', currentUser!.id).single();
    return profile['role'] as String?;
  }

  /// Récupère le profil complet
  static Future<Map<String, dynamic>?> getProfile() async {
    if (currentUser == null) return null;
    return await client.from('profiles').select().eq('id', currentUser!.id).single();
  }

  // ============================================
  // INSCRIPTION CLIENT
  // ============================================
  
  static Future<AuthResponse> signUpCustomer({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName, 'phone': phone, 'role': 'customer'},
    );
  }

  // ============================================
  // INSCRIPTION RESTAURANT (non vérifié)
  // ============================================
  
  static Future<AuthResponse> signUpRestaurant({
    required String email,
    required String password,
    required String ownerName,
    required String restaurantName,
    required String phone,
    required String address,
  }) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': ownerName, 'phone': phone, 'role': 'restaurant'},
    );
    
    if (response.user != null) {
      await client.from('restaurants').insert({
        'owner_id': response.user!.id,
        'name': restaurantName,
        'address': address,
        'phone': phone,
        'latitude': 36.8869,
        'longitude': 4.1260,
        'is_verified': false,
        'is_open': false,
      });
    }
    return response;
  }

  // ============================================
  // INSCRIPTION LIVREUR (non vérifié)
  // ============================================
  
  static Future<AuthResponse> signUpLivreur({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String vehicleType,
  }) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName, 'phone': phone, 'role': 'livreur'},
    );
    
    if (response.user != null) {
      await client.from('livreurs').insert({
        'user_id': response.user!.id,
        'vehicle_type': vehicleType,
        'is_verified': false,
        'is_online': false,
        'is_available': false,
      });
    }
    return response;
  }

  // ============================================
  // VÉRIFICATION STATUT (Restaurant/Livreur)
  // ============================================
  
  static Future<bool> isRestaurantVerified() async {
    if (currentUser == null) return false;
    final restaurant = await client.from('restaurants').select('is_verified').eq('owner_id', currentUser!.id).maybeSingle();
    return restaurant?['is_verified'] ?? false;
  }

  static Future<bool> isLivreurVerified() async {
    if (currentUser == null) return false;
    final livreur = await client.from('livreurs').select('is_verified').eq('user_id', currentUser!.id).maybeSingle();
    return livreur?['is_verified'] ?? false;
  }


  // ============================================
  // CLIENT - RESTAURANTS
  // ============================================
  
  static Future<List<Map<String, dynamic>>> getNearbyRestaurants({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  }) async {
    final response = await client.rpc('get_nearby_restaurants', params: {
      'user_lat': latitude,
      'user_lng': longitude,
      'radius_km': radiusKm,
    });
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>?> getRestaurant(String id) async {
    return await client.from('restaurants')
        .select('*, menu_categories(*, menu_items(*))')
        .eq('id', id).single();
  }

  static Future<List<Map<String, dynamic>>> searchRestaurants(String query) async {
    final response = await client.from('restaurants').select()
        .or('name.ilike.%$query%,cuisine_type.ilike.%$query%')
        .eq('is_verified', true).limit(20);
    return List<Map<String, dynamic>>.from(response);
  }

  // ============================================
  // CLIENT - COMMANDES
  // ============================================
  
  static Future<Map<String, dynamic>> createOrder({
    required String restaurantId,
    required List<Map<String, dynamic>> items,
    required String deliveryAddress,
    required double deliveryLat,
    required double deliveryLng,
    String? deliveryInstructions,
    required double subtotal,
    required double deliveryFee,
    required double total,
    String paymentMethod = 'cash',
  }) async {
    final orderResponse = await client.from('orders').insert({
      'customer_id': currentUser!.id,
      'restaurant_id': restaurantId,
      'delivery_address': deliveryAddress,
      'delivery_latitude': deliveryLat,
      'delivery_longitude': deliveryLng,
      'delivery_instructions': deliveryInstructions,
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
      'total': total,
      'payment_method': paymentMethod,
    }).select().single();

    final orderId = orderResponse['id'];
    final orderItems = items.map((item) => {
      'order_id': orderId,
      'menu_item_id': item['id'],
      'name': item['name'],
      'price': item['price'],
      'quantity': item['quantity'],
      'special_instructions': item['instructions'],
    }).toList();

    await client.from('order_items').insert(orderItems);
    return orderResponse;
  }

  static Future<List<Map<String, dynamic>>> getCustomerOrders() async {
    if (currentUser == null) return [];
    final response = await client.from('orders')
        .select('*, restaurant:restaurants(name, logo_url), order_items(*)')
        .eq('customer_id', currentUser!.id)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>?> getOrder(String orderId) async {
    return await client.from('orders')
        .select('*, restaurant:restaurants(*), livreur:livreurs(*, profile:profiles(*)), order_items(*)')
        .eq('id', orderId).single();
  }

  // ============================================
  // RESTAURANT - GESTION
  // ============================================
  
  static Future<Map<String, dynamic>?> getMyRestaurant() async {
    if (currentUser == null) return null;
    return await client.from('restaurants').select().eq('owner_id', currentUser!.id).single();
  }

  static Future<void> updateRestaurant(Map<String, dynamic> data) async {
    if (currentUser == null) return;
    await client.from('restaurants').update(data).eq('owner_id', currentUser!.id);
  }

  static Future<void> setRestaurantOpen(bool isOpen) async {
    await updateRestaurant({'is_open': isOpen});
  }

  static Future<List<Map<String, dynamic>>> getMenuCategories() async {
    final restaurant = await getMyRestaurant();
    if (restaurant == null) return [];
    final response = await client.from('menu_categories').select()
        .eq('restaurant_id', restaurant['id']).order('sort_order');
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<List<Map<String, dynamic>>> getMenuItems() async {
    final restaurant = await getMyRestaurant();
    if (restaurant == null) return [];
    final response = await client.from('menu_items')
        .select('*, category:menu_categories(name)')
        .eq('restaurant_id', restaurant['id']).order('name');
    return List<Map<String, dynamic>>.from(response);
  }

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

  static Future<List<Map<String, dynamic>>> getRestaurantPendingOrders() async {
    final restaurant = await getMyRestaurant();
    if (restaurant == null) return [];
    final response = await client.from('orders')
        .select('*, customer:profiles!customer_id(full_name, phone), order_items(*)')
        .eq('restaurant_id', restaurant['id'])
        .inFilter('status', ['pending', 'confirmed', 'preparing'])
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> confirmOrder(String orderId, int prepTimeMinutes) async {
    final estimatedTime = DateTime.now().add(Duration(minutes: prepTimeMinutes));
    await client.from('orders').update({
      'status': 'confirmed',
      'confirmed_at': DateTime.now().toIso8601String(),
      'estimated_delivery_time': estimatedTime.toIso8601String(),
    }).eq('id', orderId);
  }

  static Future<void> startPreparing(String orderId) async {
    await client.from('orders').update({'status': 'preparing'}).eq('id', orderId);
  }

  static Future<void> markAsReady(String orderId) async {
    await client.from('orders').update({
      'status': 'ready',
      'prepared_at': DateTime.now().toIso8601String(),
    }).eq('id', orderId);
  }

  static Future<void> cancelOrder(String orderId, String reason) async {
    await client.from('orders').update({
      'status': 'cancelled',
      'cancelled_at': DateTime.now().toIso8601String(),
      'cancellation_reason': reason,
    }).eq('id', orderId);
  }

  static Future<Map<String, dynamic>> getRestaurantStats() async {
    final restaurant = await getMyRestaurant();
    if (restaurant == null) return {'total_orders': 0, 'total_revenue': 0, 'orders_today': 0, 'revenue_today': 0};
    
    final response = await client.rpc('get_restaurant_stats', params: {'restaurant_uuid': restaurant['id']});
    if (response is List && response.isNotEmpty) return Map<String, dynamic>.from(response.first);
    return {'total_orders': 0, 'total_revenue': 0, 'orders_today': 0, 'revenue_today': 0};
  }


  // ============================================
  // LIVREUR - GESTION
  // ============================================
  
  static Future<Map<String, dynamic>?> getLivreurProfile() async {
    if (currentUser == null) return null;
    return await client.from('livreurs')
        .select('*, profile:profiles(*)')
        .eq('user_id', currentUser!.id).single();
  }

  static Future<void> setOnlineStatus(bool isOnline) async {
    if (currentUser == null) return;
    await client.from('livreurs')
        .update({'is_online': isOnline, 'is_available': isOnline})
        .eq('user_id', currentUser!.id);
  }

  static Future<void> setAvailability(bool isAvailable) async {
    if (currentUser == null) return;
    await client.from('livreurs').update({'is_available': isAvailable}).eq('user_id', currentUser!.id);
  }

  static Future<void> updateLivreurLocation(double lat, double lng) async {
    if (currentUser == null) return;
    await client.from('livreurs')
        .update({'current_latitude': lat, 'current_longitude': lng})
        .eq('user_id', currentUser!.id);
  }

  static Future<void> recordLocationForOrder({
    required String livreurId,
    required String orderId,
    required double lat,
    required double lng,
  }) async {
    await client.from('livreur_locations').insert({
      'livreur_id': livreurId,
      'order_id': orderId,
      'latitude': lat,
      'longitude': lng,
    });
  }

  // ============================================
  // NOUVEAU FLUX: Livreur accepte en premier
  // ============================================

  /// Livreurs voient les nouvelles commandes (status = pending, pas encore de livreur)
  static Future<List<Map<String, dynamic>>> getAvailableOrders() async {
    final response = await client.from('orders')
        .select('*, restaurant:restaurants(*), customer:profiles!customer_id(full_name, phone)')
        .eq('status', 'pending')
        .isFilter('livreur_id', null)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<List<Map<String, dynamic>>> getLivreurActiveOrders() async {
    if (currentUser == null) return [];
    final livreur = await getLivreurProfile();
    if (livreur == null) return [];
    
    final response = await client.from('orders')
        .select('*, restaurant:restaurants(*), customer:profiles!customer_id(full_name, phone, address), confirmation_code, livreur_commission')
        .eq('livreur_id', livreur['id'])
        .inFilter('status', ['confirmed', 'preparing', 'ready', 'picked_up', 'delivering'])
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Livreur accepte la commande EN PREMIER (avant le restaurant)
  static Future<void> acceptOrder(String orderId) async {
    final livreur = await getLivreurProfile();
    if (livreur == null) return;
    
    // Vérifier que la commande n'est pas déjà prise
    final order = await client.from('orders')
        .select('livreur_id')
        .eq('id', orderId)
        .single();
    
    if (order['livreur_id'] != null) {
      throw Exception('Commande déjà acceptée par un autre livreur');
    }
    
    await client.from('orders').update({
      'livreur_id': livreur['id'],
      'livreur_accepted_at': DateTime.now().toIso8601String(),
      'status': 'confirmed', // Passe à confirmed pour que le restaurant prépare
    }).eq('id', orderId);
    
    await setAvailability(false);
  }

  static Future<void> updateOrderStatus(String orderId, String status) async {
    final updates = <String, dynamic>{'status': status};
    if (status == 'picked_up') {
      updates['picked_up_at'] = DateTime.now().toIso8601String();
    }
    await client.from('orders').update(updates).eq('id', orderId);
  }

  /// Vérifier le code de confirmation et terminer la livraison
  static Future<bool> verifyConfirmationCode(String orderId, String code) async {
    final result = await client.rpc('verify_confirmation_code', params: {
      'p_order_id': orderId,
      'p_code': code,
    });
    
    if (result == true) {
      await setAvailability(true);
      return true;
    }
    return false;
  }

  /// Récupérer le code de confirmation (pour le client)
  static Future<String?> getConfirmationCode(String orderId) async {
    final order = await client.from('orders')
        .select('confirmation_code')
        .eq('id', orderId)
        .single();
    return order['confirmation_code'] as String?;
  }

  static Future<Map<String, dynamic>> getLivreurEarnings() async {
    final livreur = await getLivreurProfile();
    if (livreur == null) return {'total': 0, 'today': 0, 'week': 0, 'deliveries': 0};
    
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfWeek = startOfDay.subtract(Duration(days: now.weekday - 1));
    
    // Utiliser livreur_commission au lieu de delivery_fee
    final allDeliveries = await client.from('orders')
        .select('livreur_commission, delivered_at')
        .eq('livreur_id', livreur['id'])
        .eq('status', 'delivered');
    
    double total = 0, today = 0, week = 0;
    for (final order in allDeliveries) {
      final commission = (order['livreur_commission'] as num?)?.toDouble() ?? 0;
      total += commission;
      if (order['delivered_at'] != null) {
        final deliveredAt = DateTime.parse(order['delivered_at']);
        if (deliveredAt.isAfter(startOfDay)) today += commission;
        if (deliveredAt.isAfter(startOfWeek)) week += commission;
      }
    }
    
    return {'total': total, 'today': today, 'week': week, 'deliveries': allDeliveries.length};
  }

  /// Récupérer les transactions du livreur
  static Future<List<Map<String, dynamic>>> getLivreurTransactions() async {
    if (currentUser == null) return [];
    final response = await client.from('transactions')
        .select('*, order:orders(order_number)')
        .eq('recipient_id', currentUser!.id)
        .eq('type', 'livreur_earning')
        .order('created_at', ascending: false)
        .limit(50);
    return List<Map<String, dynamic>>.from(response);
  }

  // ============================================
  // REALTIME - NOUVEAU FLUX
  // ============================================
  
  static RealtimeChannel subscribeToOrder(String orderId, void Function(Map<String, dynamic>) onUpdate) {
    return client.channel('order_$orderId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'id', value: orderId),
          callback: (payload) => onUpdate(payload.newRecord),
        ).subscribe();
  }

  /// Restaurant écoute les commandes confirmées par un livreur
  static RealtimeChannel subscribeToNewRestaurantOrders(String restaurantId, void Function(Map<String, dynamic>) onNewOrder) {
    return client.channel('restaurant_orders_$restaurantId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'restaurant_id', value: restaurantId),
          callback: (payload) {
            // Notifier quand un livreur accepte (status = confirmed)
            if (payload.newRecord['status'] == 'confirmed' && payload.newRecord['livreur_id'] != null) {
              onNewOrder(payload.newRecord);
            }
          },
        ).subscribe();
  }

  /// Livreurs écoutent les NOUVELLES commandes (status = pending)
  static RealtimeChannel subscribeToNewOrders(void Function(Map<String, dynamic>) onNewOrder) {
    return client.channel('new_orders_for_livreurs')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'orders',
          callback: (payload) {
            // Nouvelle commande créée
            onNewOrder(payload.newRecord);
          },
        ).subscribe();
  }

  static Future<void> unsubscribe(RealtimeChannel channel) async {
    await client.removeChannel(channel);
  }

  // ============================================
  // STORAGE
  // ============================================
  
  static Future<String?> uploadImage(String bucket, String path, Uint8List bytes) async {
    await client.storage.from(bucket).uploadBinary(path, bytes);
    return client.storage.from(bucket).getPublicUrl(path);
  }
}
