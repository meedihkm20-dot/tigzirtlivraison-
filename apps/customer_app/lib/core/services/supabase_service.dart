import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service Supabase centralisé pour l'app Customer
class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;
  
  static const String supabaseUrl = 'https://pauqmhqriyjdqctvfvtt.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBhdXFtaHFyaXlqZHFjdHZmdnR0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjgyNTgxNzksImV4cCI6MjA4MzgzNDE3OX0.ZdhrCmf465g2-dHf1DUMJ5GlR9t-kZnPvo7uvvoA0x8';

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

  /// Utilisateur actuel
  static User? get currentUser => client.auth.currentUser;
  static bool get isLoggedIn => currentUser != null;

  // ============================================
  // AUTH
  // ============================================
  
  /// Inscription avec email
  static Future<AuthResponse> signUp({
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

  /// Connexion avec email
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Connexion avec téléphone (OTP)
  static Future<void> signInWithPhone(String phone) async {
    await client.auth.signInWithOtp(phone: phone);
  }

  /// Vérifier OTP
  static Future<AuthResponse> verifyOtp({
    required String phone,
    required String token,
  }) async {
    return await client.auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );
  }

  /// Déconnexion
  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  // ============================================
  // PROFILE
  // ============================================
  
  /// Récupérer le profil
  static Future<Map<String, dynamic>?> getProfile() async {
    if (currentUser == null) return null;
    final response = await client
        .from('profiles')
        .select()
        .eq('id', currentUser!.id)
        .single();
    return response;
  }

  /// Mettre à jour le profil
  static Future<void> updateProfile(Map<String, dynamic> data) async {
    if (currentUser == null) return;
    await client
        .from('profiles')
        .update(data)
        .eq('id', currentUser!.id);
  }

  // ============================================
  // RESTAURANTS
  // ============================================
  
  /// Récupérer les restaurants proches
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

  /// Récupérer un restaurant
  static Future<Map<String, dynamic>?> getRestaurant(String id) async {
    final response = await client
        .from('restaurants')
        .select('*, menu_categories(*, menu_items(*))')
        .eq('id', id)
        .single();
    return response;
  }

  /// Rechercher des restaurants
  static Future<List<Map<String, dynamic>>> searchRestaurants(String query) async {
    final response = await client
        .from('restaurants')
        .select()
        .or('name.ilike.%$query%,cuisine_type.ilike.%$query%')
        .eq('is_verified', true)
        .limit(20);
    return List<Map<String, dynamic>>.from(response);
  }

  // ============================================
  // ORDERS
  // ============================================
  
  /// Créer une commande
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
    // Créer la commande
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

    // Ajouter les items
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

  /// Récupérer les commandes du client
  static Future<List<Map<String, dynamic>>> getMyOrders() async {
    if (currentUser == null) return [];
    final response = await client
        .from('orders')
        .select('*, restaurant:restaurants(name, logo_url), order_items(*)')
        .eq('customer_id', currentUser!.id)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Récupérer une commande
  static Future<Map<String, dynamic>?> getOrder(String orderId) async {
    final response = await client
        .from('orders')
        .select('*, restaurant:restaurants(*), livreur:livreurs(*, profile:profiles(*)), order_items(*)')
        .eq('id', orderId)
        .single();
    return response;
  }

  // ============================================
  // REALTIME - Suivi commande
  // ============================================
  
  /// S'abonner aux mises à jour d'une commande
  static RealtimeChannel subscribeToOrder(
    String orderId,
    void Function(Map<String, dynamic>) onUpdate,
  ) {
    return client
        .channel('order_$orderId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: orderId,
          ),
          callback: (payload) {
            onUpdate(payload.newRecord);
          },
        )
        .subscribe();
  }

  /// S'abonner à la position du livreur
  static RealtimeChannel subscribeToLivreurLocation(
    String livreurId,
    String orderId,
    void Function(double lat, double lng) onLocationUpdate,
  ) {
    return client
        .channel('livreur_location_$orderId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'livreur_locations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'order_id',
            value: orderId,
          ),
          callback: (payload) {
            final data = payload.newRecord;
            onLocationUpdate(
              double.parse(data['latitude'].toString()),
              double.parse(data['longitude'].toString()),
            );
          },
        )
        .subscribe();
  }

  /// Se désabonner d'un channel
  static Future<void> unsubscribe(RealtimeChannel channel) async {
    await client.removeChannel(channel);
  }

  // ============================================
  // REVIEWS
  // ============================================
  
  /// Créer un avis
  static Future<void> createReview({
    required String orderId,
    required String restaurantId,
    String? livreurId,
    required int restaurantRating,
    int? livreurRating,
    String? comment,
  }) async {
    await client.from('reviews').insert({
      'order_id': orderId,
      'customer_id': currentUser!.id,
      'restaurant_id': restaurantId,
      'livreur_id': livreurId,
      'restaurant_rating': restaurantRating,
      'livreur_rating': livreurRating,
      'comment': comment,
    });
  }

  // ============================================
  // STORAGE
  // ============================================
  
  /// Upload une image
  static Future<String?> uploadImage(String bucket, String path, Uint8List bytes) async {
    await client.storage.from(bucket).uploadBinary(path, bytes);
    return client.storage.from(bucket).getPublicUrl(path);
  }
}
