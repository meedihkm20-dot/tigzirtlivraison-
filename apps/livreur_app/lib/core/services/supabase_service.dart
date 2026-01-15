import 'package:supabase_flutter/supabase_flutter.dart';

/// Service Supabase centralisé pour l'app Livreur
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
        eventsPerSecond: 10, // Plus fréquent pour le tracking GPS
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

  /// Inscription livreur (non vérifié par défaut)
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
      data: {
        'full_name': fullName,
        'phone': phone,
        'role': 'livreur',
      },
    );
    
    // Créer le livreur (non vérifié)
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

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  // ============================================
  // LIVREUR PROFILE
  // ============================================
  
  /// Récupérer le profil livreur
  static Future<Map<String, dynamic>?> getLivreurProfile() async {
    if (currentUser == null) return null;
    final response = await client
        .from('livreurs')
        .select('*, profile:profiles(*)')
        .eq('user_id', currentUser!.id)
        .single();
    return response;
  }

  /// Mettre à jour le statut en ligne
  static Future<void> setOnlineStatus(bool isOnline) async {
    if (currentUser == null) return;
    await client
        .from('livreurs')
        .update({'is_online': isOnline, 'is_available': isOnline})
        .eq('user_id', currentUser!.id);
  }

  /// Mettre à jour la disponibilité
  static Future<void> setAvailability(bool isAvailable) async {
    if (currentUser == null) return;
    await client
        .from('livreurs')
        .update({'is_available': isAvailable})
        .eq('user_id', currentUser!.id);
  }

  // ============================================
  // LOCATION TRACKING
  // ============================================
  
  /// Mettre à jour la position actuelle
  static Future<void> updateCurrentLocation(double lat, double lng) async {
    if (currentUser == null) return;
    await client
        .from('livreurs')
        .update({
          'current_latitude': lat,
          'current_longitude': lng,
        })
        .eq('user_id', currentUser!.id);
  }

  /// Enregistrer la position pour une commande (tracking)
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
  // ORDERS
  // ============================================
  
  /// Récupérer les commandes disponibles (à proximité) avec retry
  static Future<List<Map<String, dynamic>>> getAvailableOrders({
    required double lat,
    required double lng,
    double radiusKm = 5,
  }) async {
    try {
      final response = await client
          .from('orders')
          .select('*, restaurant:restaurants(*), customer:profiles!customer_id(full_name, phone)')
          .eq('status', 'ready')
          .isFilter('livreur_id', null)
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 10));
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Erreur getAvailableOrders: $e');
      // Retourner une liste vide en cas d'erreur plutôt que de crasher
      return [];
    }
  }

  /// Récupérer mes commandes en cours avec retry
  static Future<List<Map<String, dynamic>>> getMyActiveOrders() async {
    if (currentUser == null) return [];
    
    try {
      // D'abord récupérer l'ID du livreur
      final livreur = await getLivreurProfile();
      if (livreur == null) return [];
      
      final response = await client
          .from('orders')
          .select('*, restaurant:restaurants(*), customer:profiles!customer_id(full_name, phone, address)')
          .eq('livreur_id', livreur['id'])
          .inFilter('status', ['picked_up', 'delivering'])
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 10));
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Erreur getMyActiveOrders: $e');
      return [];
    }
  }

  /// Récupérer l'historique des livraisons
  static Future<List<Map<String, dynamic>>> getDeliveryHistory() async {
    if (currentUser == null) return [];
    
    final livreur = await getLivreurProfile();
    if (livreur == null) return [];
    
    final response = await client
        .from('orders')
        .select('*, restaurant:restaurants(name)')
        .eq('livreur_id', livreur['id'])
        .eq('status', 'delivered')
        .order('delivered_at', ascending: false)
        .limit(50);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Accepter une commande (ATOMIQUE - anti race condition)
  /// Retourne un résultat avec success/error
  static Future<Map<String, dynamic>> acceptOrder(String orderId) async {
    final livreur = await getLivreurProfile();
    if (livreur == null) {
      return {
        'success': false,
        'error': 'NOT_LOGGED_IN',
        'message': 'Vous devez être connecté',
      };
    }
    
    try {
      // Appel de la fonction atomique côté serveur
      final result = await client.rpc('accept_order_atomic', params: {
        'p_order_id': orderId,
        'p_livreur_id': livreur['id'],
      });
      
      // Le résultat est directement le JSONB retourné
      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
      
      return {
        'success': false,
        'error': 'INVALID_RESPONSE',
        'message': 'Réponse invalide du serveur',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'NETWORK_ERROR',
        'message': 'Erreur réseau: $e',
      };
    }
  }

  /// Mettre à jour le statut de la commande
  static Future<void> updateOrderStatus(String orderId, String status) async {
    final updates = <String, dynamic>{'status': status};
    
    if (status == 'delivering') {
      // Rien de spécial
    } else if (status == 'delivered') {
      updates['delivered_at'] = DateTime.now().toIso8601String();
    }
    
    await client.from('orders').update(updates).eq('id', orderId);
    
    // Si livré, redevenir disponible
    if (status == 'delivered') {
      await setAvailability(true);
    }
  }

  // ============================================
  // REALTIME - Nouvelles commandes
  // ============================================
  
  /// S'abonner aux nouvelles commandes disponibles
  static RealtimeChannel subscribeToNewOrders(
    void Function(Map<String, dynamic>) onNewOrder,
  ) {
    return client
        .channel('new_orders')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'status',
            value: 'ready',
          ),
          callback: (payload) {
            final order = payload.newRecord;
            if (order['livreur_id'] == null) {
              onNewOrder(order);
            }
          },
        )
        .subscribe();
  }

  /// S'abonner aux mises à jour de mes commandes
  static RealtimeChannel subscribeToMyOrders(
    String livreurId,
    void Function(Map<String, dynamic>) onUpdate,
  ) {
    return client
        .channel('my_orders_$livreurId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'livreur_id',
            value: livreurId,
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
  // EARNINGS
  // ============================================
  
  /// Récupérer les gains
  static Future<Map<String, dynamic>> getEarnings() async {
    final livreur = await getLivreurProfile();
    if (livreur == null) {
      return {'total': 0, 'today': 0, 'week': 0, 'deliveries': 0};
    }
    
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfWeek = startOfDay.subtract(Duration(days: now.weekday - 1));
    
    final allDeliveries = await client
        .from('orders')
        .select('delivery_fee, delivered_at')
        .eq('livreur_id', livreur['id'])
        .eq('status', 'delivered');
    
    double total = 0;
    double today = 0;
    double week = 0;
    
    for (final order in allDeliveries) {
      final fee = (order['delivery_fee'] as num).toDouble();
      total += fee;
      
      final deliveredAt = DateTime.parse(order['delivered_at']);
      if (deliveredAt.isAfter(startOfDay)) {
        today += fee;
      }
      if (deliveredAt.isAfter(startOfWeek)) {
        week += fee;
      }
    }
    
    return {
      'total': total,
      'today': today,
      'week': week,
      'deliveries': allDeliveries.length,
    };
  }
}


  // ============================================
  // VÉRIFICATION CODE SÉCURISÉE
  // ============================================
  
  /// Vérifier le code de confirmation (sécurisé avec limite de tentatives)
  static Future<Map<String, dynamic>> verifyConfirmationCode({
    required String orderId,
    required String code,
  }) async {
    final livreur = await getLivreurProfile();
    if (livreur == null) {
      return {
        'success': false,
        'error': 'NOT_LOGGED_IN',
        'message': 'Vous devez être connecté',
      };
    }
    
    try {
      final result = await client.rpc('verify_confirmation_code_secure', params: {
        'p_order_id': orderId,
        'p_code': code.toUpperCase(),
        'p_livreur_id': livreur['id'],
      }).timeout(const Duration(seconds: 10));
      
      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
      
      return {
        'success': false,
        'error': 'INVALID_RESPONSE',
        'message': 'Réponse invalide',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'NETWORK_ERROR',
        'message': 'Erreur réseau. Vérifiez votre connexion.',
      };
    }
  }
