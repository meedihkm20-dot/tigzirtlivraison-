import 'dart:typed_data';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

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
  // EDGE FUNCTIONS - SÉCURITÉ MAXIMALE
  // ============================================

  /// Appel générique aux Edge Functions
  static Future<Map<String, dynamic>> _callEdgeFunction(
    String functionName,
    Map<String, dynamic> body,
  ) async {
    final session = client.auth.currentSession;
    if (session == null) {
      throw Exception('Utilisateur non connecté');
    }

    final response = await http.post(
      Uri.parse('$supabaseUrl/functions/v1/$functionName'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${session.accessToken}',
        'apikey': supabaseAnonKey,
      },
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['error'] ?? 'Erreur Edge Function');
    }
    
    return data;
  }

  /// Change le statut d'une commande via Edge Function (SÉCURISÉ)
  static Future<void> changeOrderStatusSecure(String orderId, String newStatus) async {
    await _callEdgeFunction('change-order-status', {
      'order_id': orderId,
      'new_status': newStatus,
    });
  }

  /// Annule une commande via Edge Function (SÉCURISÉ)
  static Future<void> cancelOrderSecure(String orderId, {String? reason}) async {
    await _callEdgeFunction('cancel-order', {
      'order_id': orderId,
      'reason': reason,
    });
  }

  /// Vérifie le code de confirmation et finalise la livraison (SÉCURISÉ)
  static Future<Map<String, dynamic>> verifyDeliverySecure(
    String orderId,
    String confirmationCode,
  ) async {
    return await _callEdgeFunction('verify-delivery', {
      'order_id': orderId,
      'confirmation_code': confirmationCode,
    });
  }

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
      data: {
        'full_name': fullName,
        'phone': phone,
        'role': 'customer',
      },
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

  /// Récupérer un restaurant par ID (pour le client)
  static Future<Map<String, dynamic>?> getRestaurantById(String id) async {
    return await client.from('restaurants')
        .select()
        .eq('id', id)
        .single();
  }

  /// Récupérer les plats d'un restaurant
  static Future<List<Map<String, dynamic>>> getRestaurantMenuItems(String restaurantId) async {
    final response = await client.from('menu_items')
        .select('*, category:menu_categories(name)')
        .eq('restaurant_id', restaurantId)
        .order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  /// Récupérer les catégories d'un restaurant
  static Future<List<Map<String, dynamic>>> getRestaurantCategories(String restaurantId) async {
    final response = await client.from('menu_categories')
        .select()
        .eq('restaurant_id', restaurantId)
        .order('sort_order');
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>?> getRestaurant(String id) async {
    // Récupérer le restaurant avec catégories ET tous les plats
    final restaurant = await client.from('restaurants')
        .select('*, menu_categories(*)')
        .eq('id', id).single();
    
    // Récupérer tous les plats du restaurant (avec ou sans catégorie)
    final allItems = await client.from('menu_items')
        .select()
        .eq('restaurant_id', id)
        .eq('is_available', true)
        .order('name');
    
    // Organiser les plats par catégorie
    final categories = List<Map<String, dynamic>>.from(restaurant['menu_categories'] ?? []);
    
    // Ajouter les plats à leurs catégories respectives
    for (var category in categories) {
      category['menu_items'] = allItems.where((item) => item['category_id'] == category['id']).toList();
    }
    
    // Ajouter une catégorie "Autres" pour les plats sans catégorie
    final uncategorizedItems = allItems.where((item) => item['category_id'] == null).toList();
    if (uncategorizedItems.isNotEmpty) {
      categories.add({
        'id': 'uncategorized',
        'name': 'Menu',
        'menu_items': uncategorizedItems,
      });
    }
    
    restaurant['menu_categories'] = categories;
    return restaurant;
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

  /// Annule une commande
  /// Utilise Edge Function en priorité (sécurité maximale), fallback sur validation locale
  static Future<void> cancelOrder(String orderId, String reason) async {
    try {
      // Essayer d'abord via Edge Function (RECOMMANDÉ)
      await cancelOrderSecure(orderId, reason: reason);
    } catch (e) {
      // Fallback: validation locale si Edge Function non disponible
      final order = await client.from('orders')
          .select('status')
          .eq('id', orderId)
          .single();
      final currentStatus = order['status'] as String?;
      
      final nonCancellableStatuses = ['picked_up', 'delivering', 'delivered'];
      if (currentStatus != null && nonCancellableStatuses.contains(currentStatus)) {
        throw Exception('Impossible d\'annuler une commande en cours de livraison ou livrée');
      }
      
      await client.from('orders').update({
        'status': 'cancelled',
        'cancelled_at': DateTime.now().toIso8601String(),
        'cancellation_reason': reason,
      }).eq('id', orderId);
    }
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

  /// Met à jour le statut d'une commande
  /// Utilise Edge Function en priorité (sécurité maximale), fallback sur validation locale
  static Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      // Essayer d'abord via Edge Function (RECOMMANDÉ)
      await changeOrderStatusSecure(orderId, status);
    } catch (e) {
      // Fallback: validation locale si Edge Function non disponible
      // (utile en développement ou si Edge Functions pas déployées)
      final validTransitions = {
        'pending': ['confirmed', 'cancelled'],
        'confirmed': ['preparing', 'cancelled'],
        'preparing': ['ready', 'cancelled'],
        'ready': ['picked_up'],
        'picked_up': ['delivering', 'delivered'],
        'delivering': ['delivered'],
      };
      
      final order = await client.from('orders')
          .select('status')
          .eq('id', orderId)
          .single();
      final currentStatus = order['status'] as String?;
      
      if (currentStatus != null && 
          validTransitions.containsKey(currentStatus) &&
          !validTransitions[currentStatus]!.contains(status)) {
        throw Exception('Transition de statut invalide: $currentStatus → $status');
      }
      
      final updates = <String, dynamic>{'status': status};
      if (status == 'picked_up') {
        updates['picked_up_at'] = DateTime.now().toIso8601String();
      }
      await client.from('orders').update(updates).eq('id', orderId);
    }
  }

  /// Vérifier le code de confirmation et terminer la livraison
  /// Utilise Edge Function en priorité (sécurité maximale)
  static Future<bool> verifyConfirmationCode(String orderId, String code) async {
    try {
      // Essayer d'abord via Edge Function (RECOMMANDÉ)
      await verifyDeliverySecure(orderId, code);
      await setAvailability(true);
      return true;
    } catch (e) {
      // Fallback: RPC si Edge Function non disponible
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

  // ============================================
  // FAVORIS CLIENT
  // ============================================

  static Future<List<Map<String, dynamic>>> getFavoriteRestaurants() async {
    if (currentUser == null) return [];
    final response = await client.from('favorites')
        .select('*, restaurant:restaurants(*)')
        .eq('customer_id', currentUser!.id);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> toggleFavoriteRestaurant(String restaurantId) async {
    if (currentUser == null) return;
    final existing = await client.from('favorites')
        .select().eq('customer_id', currentUser!.id).eq('restaurant_id', restaurantId).maybeSingle();
    
    if (existing != null) {
      await client.from('favorites').delete().eq('id', existing['id']);
    } else {
      await client.from('favorites').insert({'customer_id': currentUser!.id, 'restaurant_id': restaurantId});
    }
  }

  static Future<bool> isFavoriteRestaurant(String restaurantId) async {
    if (currentUser == null) return false;
    final existing = await client.from('favorites')
        .select().eq('customer_id', currentUser!.id).eq('restaurant_id', restaurantId).maybeSingle();
    return existing != null;
  }

  // ============================================
  // PROMOTIONS
  // ============================================

  static Future<List<Map<String, dynamic>>> getActivePromotions(String? restaurantId) async {
    var query = client.from('promotions').select()
        .eq('is_active', true)
        .lte('starts_at', DateTime.now().toIso8601String());
    
    if (restaurantId != null) {
      query = query.eq('restaurant_id', restaurantId);
    }
    
    final response = await query.order('discount_value', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>> applyPromoCode(String orderId, String code) async {
    final result = await client.rpc('apply_promotion', params: {
      'p_order_id': orderId,
      'p_promo_code': code,
    });
    if (result is List && result.isNotEmpty) return Map<String, dynamic>.from(result.first);
    return {'success': false, 'discount': 0, 'message': 'Erreur'};
  }

  // Restaurant: Créer une promo
  static Future<void> createPromotion({
    required String name,
    String? description,
    required String discountType,
    required double discountValue,
    double minOrderAmount = 0,
    double? maxDiscount,
    String? code,
    DateTime? endsAt,
    int? usageLimit,
  }) async {
    final restaurant = await getMyRestaurant();
    if (restaurant == null) return;
    
    await client.from('promotions').insert({
      'restaurant_id': restaurant['id'],
      'name': name,
      'description': description,
      'discount_type': discountType,
      'discount_value': discountValue,
      'min_order_amount': minOrderAmount,
      'max_discount': maxDiscount,
      'code': code,
      'ends_at': endsAt?.toIso8601String(),
      'usage_limit': usageLimit,
    });
  }

  static Future<List<Map<String, dynamic>>> getMyPromotions() async {
    final restaurant = await getMyRestaurant();
    if (restaurant == null) return [];
    final response = await client.from('promotions')
        .select().eq('restaurant_id', restaurant['id']).order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> togglePromotion(String promoId, bool isActive) async {
    await client.from('promotions').update({'is_active': isActive}).eq('id', promoId);
  }

  // ============================================
  // AVIS ET NOTATIONS
  // ============================================

  static Future<bool> submitReview({
    required String orderId,
    required int restaurantRating,
    required int livreurRating,
    String? comment,
  }) async {
    final result = await client.rpc('submit_review', params: {
      'p_order_id': orderId,
      'p_restaurant_rating': restaurantRating,
      'p_livreur_rating': livreurRating,
      'p_comment': comment,
    });
    return result == true;
  }

  static Future<List<Map<String, dynamic>>> getRestaurantReviews(String restaurantId) async {
    final response = await client.from('reviews')
        .select('*, customer:profiles!customer_id(full_name, avatar_url)')
        .eq('restaurant_id', restaurantId)
        .order('created_at', ascending: false)
        .limit(50);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>?> getOrderReview(String orderId) async {
    return await client.from('reviews').select().eq('order_id', orderId).maybeSingle();
  }

  // ============================================
  // MENU AMÉLIORÉ (Photos, Variantes, Extras)
  // ============================================

  static Future<void> updateMenuItem({
    required String itemId,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    bool? isAvailable,
    bool? isPopular,
    bool? isVegetarian,
    bool? isSpicy,
    int? prepTime,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (price != null) updates['price'] = price;
    if (imageUrl != null) updates['image_url'] = imageUrl;
    if (isAvailable != null) updates['is_available'] = isAvailable;
    if (isPopular != null) updates['is_popular'] = isPopular;
    if (isVegetarian != null) updates['is_vegetarian'] = isVegetarian;
    if (isSpicy != null) updates['is_spicy'] = isSpicy;
    if (prepTime != null) updates['prep_time'] = prepTime;
    
    if (updates.isNotEmpty) {
      await client.from('menu_items').update(updates).eq('id', itemId);
    }
  }

  static Future<void> deleteMenuItem(String itemId) async {
    await client.from('menu_items').delete().eq('id', itemId);
  }

  static Future<void> addMenuCategory({required String name, String? description}) async {
    final restaurant = await getMyRestaurant();
    if (restaurant == null) return;
    
    final maxOrder = await client.from('menu_categories')
        .select('sort_order').eq('restaurant_id', restaurant['id'])
        .order('sort_order', ascending: false).limit(1);
    
    final nextOrder = (maxOrder.isNotEmpty ? (maxOrder.first['sort_order'] as int) : 0) + 1;
    
    await client.from('menu_categories').insert({
      'restaurant_id': restaurant['id'],
      'name': name,
      'description': description,
      'sort_order': nextOrder,
    });
  }

  static Future<List<Map<String, dynamic>>> getPopularItems(String restaurantId) async {
    final response = await client.from('menu_items')
        .select('*, category:menu_categories(name)')
        .eq('restaurant_id', restaurantId)
        .eq('is_available', true)
        .order('order_count', ascending: false)
        .limit(10);
    return List<Map<String, dynamic>>.from(response);
  }

  // ============================================
  // CUISINE (KDS) - Commandes en préparation
  // ============================================

  static Future<List<Map<String, dynamic>>> getKitchenOrders() async {
    final restaurant = await getMyRestaurant();
    if (restaurant == null) return [];
    
    final response = await client.from('orders')
        .select('*, order_items(*), livreur:livreurs(*, profile:profiles(full_name, phone))')
        .eq('restaurant_id', restaurant['id'])
        .inFilter('status', ['confirmed', 'preparing'])
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  // ============================================
  // LIVREUR - BADGES ET STATS
  // ============================================

  static Future<Map<String, dynamic>> getLivreurDetailedStats() async {
    final livreur = await getLivreurProfile();
    if (livreur == null) return {};
    
    return {
      'total_deliveries': livreur['total_deliveries'] ?? 0,
      'total_earnings': livreur['total_earnings'] ?? 0,
      'rating': livreur['rating'] ?? 5.0,
      'avg_delivery_time': livreur['avg_delivery_time'] ?? 0,
      'total_distance_km': livreur['total_distance_km'] ?? 0,
      'acceptance_rate': livreur['acceptance_rate'] ?? 100,
    };
  }

  static Future<List<Map<String, dynamic>>> getLivreurDeliveryHistory() async {
    final livreur = await getLivreurProfile();
    if (livreur == null) return [];
    
    final response = await client.from('orders')
        .select('*, restaurant:restaurants(name, address), livreur_commission')
        .eq('livreur_id', livreur['id'])
        .eq('status', 'delivered')
        .order('delivered_at', ascending: false)
        .limit(50);
    return List<Map<String, dynamic>>.from(response);
  }

  // ============================================
  // UPLOAD IMAGES (Menu, Restaurant)
  // ============================================

  static Future<String?> uploadMenuItemImage(String itemId, Uint8List bytes) async {
    final path = 'menu_items/$itemId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    return await uploadImage('menu-images', path, bytes);
  }

  static Future<String?> uploadRestaurantLogo(Uint8List bytes) async {
    final restaurant = await getMyRestaurant();
    if (restaurant == null) return null;
    final path = 'restaurants/${restaurant['id']}/logo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final url = await uploadImage('restaurant-images', path, bytes);
    if (url != null) {
      await updateRestaurant({'logo_url': url});
    }
    return url;
  }

  static Future<String?> uploadRestaurantCover(Uint8List bytes) async {
    final restaurant = await getMyRestaurant();
    if (restaurant == null) return null;
    final path = 'restaurants/${restaurant['id']}/cover_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final url = await uploadImage('restaurant-images', path, bytes);
    if (url != null) {
      await updateRestaurant({'cover_url': url});
    }
    return url;
  }

  // ============================================
  // TOP RESTAURANTS & MENUS (CLIENT)
  // ============================================

  static Future<List<Map<String, dynamic>>> getTopRestaurants({int limit = 10}) async {
    final response = await client.rpc('get_top_restaurants', params: {'p_limit': limit});
    return List<Map<String, dynamic>>.from(response ?? []);
  }

  static Future<List<Map<String, dynamic>>> getTopMenuItems({String? restaurantId, int limit = 20}) async {
    final response = await client.rpc('get_top_menu_items', params: {
      'p_restaurant_id': restaurantId,
      'p_limit': limit,
    });
    return List<Map<String, dynamic>>.from(response ?? []);
  }

  static Future<List<Map<String, dynamic>>> getDailySpecials() async {
    final response = await client.from('menu_items')
        .select('*, restaurant:restaurants(id, name, logo_url)')
        .eq('is_daily_special', true)
        .eq('is_available', true)
        .order('avg_rating', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // ============================================
  // ADRESSES SAUVEGARDÉES (CLIENT)
  // ============================================

  static Future<List<Map<String, dynamic>>> getSavedAddresses() async {
    if (currentUser == null) return [];
    final response = await client.from('saved_addresses')
        .select()
        .eq('customer_id', currentUser!.id)
        .order('is_default', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> addSavedAddress({
    required String label,
    required String address,
    required double latitude,
    required double longitude,
    String? instructions,
    bool isDefault = false,
  }) async {
    if (currentUser == null) return;
    
    if (isDefault) {
      await client.from('saved_addresses')
          .update({'is_default': false})
          .eq('customer_id', currentUser!.id);
    }
    
    await client.from('saved_addresses').insert({
      'customer_id': currentUser!.id,
      'label': label,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'instructions': instructions,
      'is_default': isDefault,
    });
  }

  static Future<void> deleteSavedAddress(String addressId) async {
    await client.from('saved_addresses').delete().eq('id', addressId);
  }

  // ============================================
  // SYSTÈME LIVREUR GAMIFIÉ
  // ============================================

  static Future<Map<String, dynamic>?> getLivreurTierInfo() async {
    final livreur = await getLivreurProfile();
    if (livreur == null) return null;
    
    final tierConfig = await client.from('tier_config')
        .select()
        .eq('tier', livreur['tier'] ?? 'bronze')
        .single();
    
    return {
      'current_tier': livreur['tier'] ?? 'bronze',
      'commission_rate': tierConfig['commission_rate'],
      'total_deliveries': livreur['total_deliveries'] ?? 0,
      'rating': livreur['rating'] ?? 5.0,
      'cancellation_rate': livreur['cancellation_rate'] ?? 0,
      'weekly_deliveries': livreur['weekly_deliveries'] ?? 0,
      'monthly_deliveries': livreur['monthly_deliveries'] ?? 0,
      'streak_days': livreur['streak_days'] ?? 0,
      'bonus_earned': livreur['bonus_earned'] ?? 0,
      'next_tier': _getNextTier(livreur['tier'] ?? 'bronze'),
      'tier_config': tierConfig,
    };
  }

  static String? _getNextTier(String currentTier) {
    switch (currentTier) {
      case 'bronze': return 'silver';
      case 'silver': return 'gold';
      case 'gold': return 'diamond';
      default: return null;
    }
  }

  static Future<Map<String, dynamic>?> getNextTierRequirements() async {
    final livreur = await getLivreurProfile();
    if (livreur == null) return null;
    
    final nextTier = _getNextTier(livreur['tier'] ?? 'bronze');
    if (nextTier == null) return null;
    
    final config = await client.from('tier_config')
        .select()
        .eq('tier', nextTier)
        .single();
    
    return {
      'tier': nextTier,
      'min_deliveries': config['min_deliveries'],
      'min_rating': config['min_rating'],
      'max_cancellation_rate': config['max_cancellation_rate'],
      'commission_rate': config['commission_rate'],
      'current_deliveries': livreur['total_deliveries'] ?? 0,
      'current_rating': livreur['rating'] ?? 5.0,
      'current_cancellation_rate': livreur['cancellation_rate'] ?? 0,
    };
  }

  static Future<List<Map<String, dynamic>>> getLivreurBonusHistory({int limit = 50}) async {
    final livreur = await getLivreurProfile();
    if (livreur == null) return [];
    
    final response = await client.from('livreur_bonuses')
        .select()
        .eq('livreur_id', livreur['id'])
        .order('earned_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<List<Map<String, dynamic>>> getDailyTargets() async {
    final response = await client.from('livreur_targets')
        .select()
        .eq('is_active', true)
        .order('deliveries_required');
    return List<Map<String, dynamic>>.from(response);
  }

  // ============================================
  // MENU AMÉLIORÉ (RESTAURANT)
  // ============================================

  static Future<void> setDailySpecial(String itemId, {double? specialPrice}) async {
    await client.from('menu_items').update({
      'is_daily_special': true,
      'daily_special_price': specialPrice,
    }).eq('id', itemId);
  }

  static Future<void> removeDailySpecial(String itemId) async {
    await client.from('menu_items').update({
      'is_daily_special': false,
      'daily_special_price': null,
    }).eq('id', itemId);
  }

  static Future<void> updateMenuItemDetails({
    required String itemId,
    List<String>? ingredients,
    Map<String, dynamic>? nutritionInfo,
    List<String>? tags,
  }) async {
    final updates = <String, dynamic>{};
    if (ingredients != null) updates['ingredients'] = ingredients;
    if (nutritionInfo != null) updates['nutrition_info'] = nutritionInfo;
    if (tags != null) updates['tags'] = tags;
    
    if (updates.isNotEmpty) {
      await client.from('menu_items').update(updates).eq('id', itemId);
    }
  }

  static Future<Map<String, dynamic>> getMenuItemStats(String itemId) async {
    final item = await client.from('menu_items')
        .select('order_count, avg_rating, total_reviews, last_ordered_at')
        .eq('id', itemId)
        .single();
    return item;
  }

  // ============================================
  // AVIS SUR LES PLATS
  // ============================================

  static Future<void> submitMenuItemReview({
    required String orderId,
    required String menuItemId,
    required int rating,
    String? comment,
  }) async {
    if (currentUser == null) return;
    
    await client.from('menu_item_reviews').upsert({
      'menu_item_id': menuItemId,
      'customer_id': currentUser!.id,
      'order_id': orderId,
      'rating': rating,
      'comment': comment,
    }, onConflict: 'order_id,menu_item_id');
    
    // Mettre à jour la moyenne
    final reviews = await client.from('menu_item_reviews')
        .select('rating')
        .eq('menu_item_id', menuItemId);
    
    if (reviews.isNotEmpty) {
      final avgRating = reviews.map((r) => r['rating'] as int).reduce((a, b) => a + b) / reviews.length;
      await client.from('menu_items').update({
        'avg_rating': avgRating,
        'total_reviews': reviews.length,
      }).eq('id', menuItemId);
    }
  }

  static Future<List<Map<String, dynamic>>> getMenuItemReviews(String menuItemId) async {
    final response = await client.from('menu_item_reviews')
        .select('*, customer:profiles(full_name, avatar_url)')
        .eq('menu_item_id', menuItemId)
        .order('created_at', ascending: false)
        .limit(20);
    return List<Map<String, dynamic>>.from(response);
  }

  // ============================================
  // POINTS FIDÉLITÉ CLIENT
  // ============================================

  static Future<Map<String, dynamic>> getCustomerLoyalty() async {
    if (currentUser == null) return {'points': 0, 'total_orders': 0, 'total_spent': 0};
    
    final profile = await client.from('profiles')
        .select('loyalty_points, total_orders, total_spent')
        .eq('id', currentUser!.id)
        .single();
    
    return {
      'points': profile['loyalty_points'] ?? 0,
      'total_orders': profile['total_orders'] ?? 0,
      'total_spent': profile['total_spent'] ?? 0,
      'level': _getLoyaltyLevel(profile['total_orders'] ?? 0),
    };
  }

  static String _getLoyaltyLevel(int totalOrders) {
    if (totalOrders >= 100) return 'Platinum';
    if (totalOrders >= 50) return 'Gold';
    if (totalOrders >= 20) return 'Silver';
    return 'Bronze';
  }

  // ============================================
  // HISTORIQUE RECHERCHE
  // ============================================

  static Future<void> saveSearchQuery(String query) async {
    if (currentUser == null || query.trim().isEmpty) return;
    await client.from('search_history').insert({
      'customer_id': currentUser!.id,
      'query': query.trim(),
    });
  }

  static Future<List<String>> getRecentSearches({int limit = 10}) async {
    if (currentUser == null) return [];
    final response = await client.from('search_history')
        .select('query')
        .eq('customer_id', currentUser!.id)
        .order('searched_at', ascending: false)
        .limit(limit);
    return (response as List).map((r) => r['query'] as String).toSet().toList();
  }

  static Future<void> clearSearchHistory() async {
    if (currentUser == null) return;
    await client.from('search_history').delete().eq('customer_id', currentUser!.id);
  }

  // ============================================
  // CHAT CLIENT-LIVREUR
  // ============================================

  static Future<List<Map<String, dynamic>>> getOrderMessages(String orderId) async {
    final response = await client.from('order_messages')
        .select('*, sender:profiles!sender_id(full_name)')
        .eq('order_id', orderId)
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> sendOrderMessage({
    required String orderId,
    required String message,
    required String senderType, // 'customer', 'livreur'
  }) async {
    if (currentUser == null) return;
    await client.from('order_messages').insert({
      'order_id': orderId,
      'sender_id': currentUser!.id,
      'message': message,
      'sender_type': senderType,
    });
  }

  // ============================================
  // POURBOIRE
  // ============================================

  static Future<bool> addTip(String orderId, double amount) async {
    try {
      final result = await client.rpc('add_tip', params: {
        'p_order_id': orderId,
        'p_amount': amount,
      });
      return result == true;
    } catch (e) {
      return false;
    }
  }

  // ============================================
  // PARRAINAGE
  // ============================================

  static Future<String?> getReferralCode() async {
    if (currentUser == null) return null;
    final profile = await client.from('profiles')
        .select('referral_code')
        .eq('id', currentUser!.id)
        .single();
    return profile['referral_code'] as String?;
  }

  static Future<Map<String, dynamic>> applyReferralCode(String code) async {
    try {
      final result = await client.rpc('apply_referral_code', params: {'p_code': code});
      if (result is List && result.isNotEmpty) {
        return Map<String, dynamic>.from(result.first);
      }
      return {'success': false, 'message': 'Erreur'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<List<Map<String, dynamic>>> getMyReferrals() async {
    if (currentUser == null) return [];
    final response = await client.from('referrals')
        .select('*, referred:profiles!referred_id(full_name, created_at)')
        .eq('referrer_id', currentUser!.id)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>> getReferralStats() async {
    if (currentUser == null) return {'total_referrals': 0, 'total_earnings': 0};
    
    final profile = await client.from('profiles')
        .select('referral_earnings')
        .eq('id', currentUser!.id)
        .single();
    
    final referrals = await client.from('referrals')
        .select('id')
        .eq('referrer_id', currentUser!.id)
        .eq('status', 'rewarded');
    
    return {
      'total_referrals': (referrals as List).length,
      'total_earnings': profile['referral_earnings'] ?? 0,
    };
  }

  // ============================================
  // SUGGESTIONS RECOMMANDE
  // ============================================

  static Future<List<Map<String, dynamic>>> getReorderSuggestions() async {
    if (currentUser == null) return [];
    final response = await client.from('reorder_suggestions')
        .select('*, restaurant:restaurants(id, name, logo_url, rating)')
        .eq('customer_id', currentUser!.id)
        .order('last_ordered_at', ascending: false)
        .limit(10);
    return List<Map<String, dynamic>>.from(response);
  }

  // ============================================
  // CLIENT V2 - MÉTHODES ADDITIONNELLES
  // ============================================

  static Future<List<Map<String, dynamic>>> getCartItems() async {
    if (currentUser == null) return [];
    final response = await client.from('cart_items')
        .select('*, menu_item:menu_items(*, restaurant:restaurants(name))')
        .eq('customer_id', currentUser!.id);
    return List<Map<String, dynamic>>.from(response).map((item) {
      final menuItem = item['menu_item'] as Map<String, dynamic>?;
      return {
        'id': item['id'],
        'menu_item_id': item['menu_item_id'],
        'quantity': item['quantity'],
        'name': menuItem?['name'],
        'price': menuItem?['price'],
        'image_url': menuItem?['image_url'],
        'restaurant_id': menuItem?['restaurant_id'],
        'restaurant_name': menuItem?['restaurant']?['name'],
      };
    }).toList();
  }

  static Future<void> addToCart(String menuItemId, int quantity) async {
    if (currentUser == null) return;
    final existing = await client.from('cart_items')
        .select()
        .eq('customer_id', currentUser!.id)
        .eq('menu_item_id', menuItemId)
        .maybeSingle();
    
    if (existing != null) {
      await client.from('cart_items')
          .update({'quantity': (existing['quantity'] as int) + quantity})
          .eq('id', existing['id']);
    } else {
      await client.from('cart_items').insert({
        'customer_id': currentUser!.id,
        'menu_item_id': menuItemId,
        'quantity': quantity,
      });
    }
  }

  static Future<void> updateCartItemQuantity(String cartItemId, int quantity) async {
    await client.from('cart_items').update({'quantity': quantity}).eq('id', cartItemId);
  }

  static Future<void> removeFromCart(String cartItemId) async {
    await client.from('cart_items').delete().eq('id', cartItemId);
  }

  static Future<void> clearCart() async {
    if (currentUser == null) return;
    await client.from('cart_items').delete().eq('customer_id', currentUser!.id);
  }

  static Future<List<Map<String, dynamic>>> getMenuSuggestions(String restaurantId, {int limit = 4}) async {
    final response = await client.from('menu_items')
        .select()
        .eq('restaurant_id', restaurantId)
        .eq('is_available', true)
        .eq('is_popular', true)
        .limit(limit);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>?> getOrderDetails(String orderId) async {
    return await client.from('orders')
        .select('*, restaurant:restaurants(*), livreur:livreurs(*, profile:profiles(*)), order_items(*), customer:profiles!customer_id(*)')
        .eq('id', orderId)
        .maybeSingle();
  }

  static Stream<Map<String, dynamic>?> subscribeToOrderStream(String orderId) {
    return client.from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', orderId)
        .map((list) => list.isNotEmpty ? list.first : null);
  }

  static Stream<Map<String, dynamic>?> subscribeToLivreurLocation(String orderId) {
    return client.from('livreur_locations')
        .stream(primaryKey: ['id'])
        .eq('order_id', orderId)
        .order('created_at', ascending: false)
        .limit(1)
        .map((list) => list.isNotEmpty ? {'lat': list.first['latitude'], 'lng': list.first['longitude']} : null);
  }

  static Future<List<dynamic>> getRoute(dynamic start, dynamic end) async {
    // Placeholder - would use OSRM API
    return [];
  }

  static Future<Map<String, dynamic>> getRouteInfo(dynamic start, dynamic end) async {
    // Placeholder - would use OSRM API
    return {'duration': 15, 'distance': 2.5, 'instruction': 'Continuez tout droit'};
  }

  static Future<Map<String, dynamic>> getCustomerStats() async {
    if (currentUser == null) return {};
    final profile = await client.from('profiles')
        .select('total_orders, total_spent')
        .eq('id', currentUser!.id)
        .maybeSingle();
    return {
      'total_orders': profile?['total_orders'] ?? 0,
      'total_spent': profile?['total_spent'] ?? 0,
      'avg_rating': 4.5,
      'favorite_restaurant': 'Pizza Tigzirt',
    };
  }

  static Future<List<Map<String, dynamic>>> getCustomerBadges() async {
    if (currentUser == null) return [];
    final response = await client.from('customer_badges')
        .select('*, badge:badges(*)')
        .eq('customer_id', currentUser!.id);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<List<Map<String, dynamic>>> getRecentOrders({int limit = 3}) async {
    if (currentUser == null) return [];
    final response = await client.from('orders')
        .select('*, restaurant:restaurants(name)')
        .eq('customer_id', currentUser!.id)
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(response).map((o) => {
      ...o,
      'restaurant_name': o['restaurant']?['name'],
    }).toList();
  }

  // ============================================
  // LIVREUR V2 - MÉTHODES ADDITIONNELLES
  // ============================================

  static Future<Map<String, dynamic>> getLivreurTodayStats() async {
    final livreur = await getLivreurProfile();
    if (livreur == null) return {};
    
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    
    final deliveries = await client.from('orders')
        .select('livreur_commission, tip_amount')
        .eq('livreur_id', livreur['id'])
        .eq('status', 'delivered')
        .gte('delivered_at', startOfDay.toIso8601String());
    
    double earnings = 0, tips = 0;
    for (final d in deliveries) {
      earnings += (d['livreur_commission'] as num?)?.toDouble() ?? 0;
      tips += (d['tip_amount'] as num?)?.toDouble() ?? 0;
    }
    
    return {
      'deliveries': deliveries.length,
      'earnings': earnings,
      'tips': tips,
      'distance': deliveries.length * 2.5,
      'hours': deliveries.length * 0.5,
    };
  }

  static Stream<List<Map<String, dynamic>>> subscribeToAvailableOrders() {
    return client.from('orders')
        .stream(primaryKey: ['id'])
        .eq('status', 'pending')
        .map((list) => List<Map<String, dynamic>>.from(list.where((o) => o['livreur_id'] == null)));
  }

  static Future<void> setLivreurOnlineStatus(bool isOnline) async {
    await setOnlineStatus(isOnline);
  }

  static Future<Map<String, dynamic>?> getCurrentDelivery() async {
    final livreur = await getLivreurProfile();
    if (livreur == null) return null;
    
    final response = await client.from('orders')
        .select('*, restaurant:restaurants(*)')
        .eq('livreur_id', livreur['id'])
        .inFilter('status', ['confirmed', 'preparing', 'ready', 'picked_up'])
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    
    return response;
  }

  static Future<void> updateLivreurLocationForOrder(String orderId, double lat, double lng) async {
    final livreur = await getLivreurProfile();
    if (livreur == null) return;
    
    await client.from('livreurs')
        .update({'current_latitude': lat, 'current_longitude': lng})
        .eq('id', livreur['id']);
    
    await client.from('livreur_locations').insert({
      'livreur_id': livreur['id'],
      'order_id': orderId,
      'latitude': lat,
      'longitude': lng,
    });
  }

  static Future<void> confirmDelivery(String orderId, String code) async {
    final verified = await verifyConfirmationCode(orderId, code);
    if (!verified) throw Exception('Code incorrect');
  }

  static Future<void> cancelDelivery(String orderId) async {
    final livreur = await getLivreurProfile();
    if (livreur == null) return;
    
    await client.from('orders').update({
      'livreur_id': null,
      'status': 'pending',
    }).eq('id', orderId);
    
    await setAvailability(true);
  }

  static Future<Map<String, dynamic>> getLivreurWeekStats() async {
    final livreur = await getLivreurProfile();
    if (livreur == null) return {};
    
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    
    final deliveries = await client.from('orders')
        .select('livreur_commission, tip_amount')
        .eq('livreur_id', livreur['id'])
        .eq('status', 'delivered')
        .gte('delivered_at', startOfWeek.toIso8601String());
    
    double earnings = 0, tips = 0;
    for (final d in deliveries) {
      earnings += (d['livreur_commission'] as num?)?.toDouble() ?? 0;
      tips += (d['tip_amount'] as num?)?.toDouble() ?? 0;
    }
    
    return {
      'deliveries': deliveries.length,
      'earnings': earnings,
      'tips': tips,
      'distance': deliveries.length * 2.5,
      'hours': deliveries.length * 0.5,
    };
  }

  static Future<Map<String, dynamic>> getLivreurMonthStats() async {
    final livreur = await getLivreurProfile();
    if (livreur == null) return {};
    
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    
    final deliveries = await client.from('orders')
        .select('livreur_commission, tip_amount')
        .eq('livreur_id', livreur['id'])
        .eq('status', 'delivered')
        .gte('delivered_at', startOfMonth.toIso8601String());
    
    double earnings = 0, tips = 0;
    for (final d in deliveries) {
      earnings += (d['livreur_commission'] as num?)?.toDouble() ?? 0;
      tips += (d['tip_amount'] as num?)?.toDouble() ?? 0;
    }
    
    return {
      'deliveries': deliveries.length,
      'earnings': earnings,
      'tips': tips,
      'distance': deliveries.length * 2.5,
      'hours': deliveries.length * 0.5,
    };
  }

  static Future<List<Map<String, dynamic>>> getLivreurTransactions({int limit = 10}) async {
    final livreur = await getLivreurProfile();
    if (livreur == null) return [];
    
    final response = await client.from('transactions')
        .select()
        .eq('recipient_id', currentUser!.id)
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<List<double>> getLivreurWeeklyData() async {
    final livreur = await getLivreurProfile();
    if (livreur == null) return [];
    
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    
    List<double> data = [];
    for (int i = 0; i < 7; i++) {
      final day = startOfWeek.add(Duration(days: i));
      final nextDay = day.add(const Duration(days: 1));
      
      final deliveries = await client.from('orders')
          .select('livreur_commission')
          .eq('livreur_id', livreur['id'])
          .eq('status', 'delivered')
          .gte('delivered_at', day.toIso8601String())
          .lt('delivered_at', nextDay.toIso8601String());
      
      double dayEarnings = 0;
      for (final d in deliveries) {
        dayEarnings += (d['livreur_commission'] as num?)?.toDouble() ?? 0;
      }
      data.add(dayEarnings);
    }
    
    return data;
  }

  static Future<List<Map<String, dynamic>>> getLivreurBadges() async {
    final livreur = await getLivreurProfile();
    if (livreur == null) return [];
    
    final response = await client.from('livreur_badges')
        .select('*, badge:badges(*)')
        .eq('livreur_id', livreur['id']);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<List<Map<String, dynamic>>> getLivreurChallenges() async {
    final livreur = await getLivreurProfile();
    if (livreur == null) return [];
    
    final response = await client.from('challenges')
        .select('*, progress:challenge_progress(*)')
        .eq('is_active', true);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<List<Map<String, dynamic>>> getLivreurLeaderboard() async {
    final response = await client.from('livreurs')
        .select('*, profile:profiles(full_name)')
        .eq('is_verified', true)
        .order('total_deliveries', ascending: false)
        .limit(10);
    
    return List<Map<String, dynamic>>.from(response).asMap().entries.map((e) => {
      'rank': e.key + 1,
      'name': e.value['profile']?['full_name'] ?? 'Livreur',
      'deliveries': e.value['total_deliveries'] ?? 0,
      'tier': _getTierFromDeliveries(e.value['total_deliveries'] ?? 0),
    }).toList();
  }

  static String _getTierFromDeliveries(int deliveries) {
    if (deliveries >= 500) return 'Diamond';
    if (deliveries >= 150) return 'Gold';
    if (deliveries >= 50) return 'Silver';
    return 'Bronze';
  }
}
