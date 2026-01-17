import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

/// Service Supabase centralisé pour l'app Admin V2
/// Avec audit logs, rôles granulaires et sécurité renforcée
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
  // AUTH ADMIN
  // ============================================
  
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    
    // Mettre à jour last_login
    if (response.user != null) {
      await client.from('admin_users')
          .update({'last_login_at': DateTime.now().toIso8601String()})
          .eq('user_id', response.user!.id);
    }
    
    return response;
  }

  static Future<bool> isAdmin() async {
    if (currentUser == null) return false;
    final profile = await client
        .from('profiles')
        .select('role')
        .eq('id', currentUser!.id)
        .maybeSingle();
    return profile?['role'] == 'admin';
  }

  static Future<String?> getAdminRole() async {
    if (currentUser == null) return null;
    final admin = await client
        .from('admin_users')
        .select('admin_role')
        .eq('user_id', currentUser!.id)
        .maybeSingle();
    return admin?['admin_role'] as String?;
  }

  static Future<Map<String, dynamic>?> getAdminProfile() async {
    if (currentUser == null) return null;
    final admin = await client
        .from('admin_users')
        .select('*, profile:profiles!user_id(full_name, email:id)')
        .eq('user_id', currentUser!.id)
        .maybeSingle();
    return admin;
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  // ============================================
  // AUDIT LOGS (CRITIQUE)
  // ============================================

  static Future<void> logAction({
    required String action,
    required String entityType,
    String? entityId,
    Map<String, dynamic>? oldValue,
    Map<String, dynamic>? newValue,
    String? reason,
  }) async {
    try {
      await client.from('admin_audit_logs').insert({
        'admin_id': currentUser?.id,
        'admin_role': await getAdminRole(),
        'action': action,
        'entity_type': entityType,
        'entity_id': entityId,
        'old_value': oldValue,
        'new_value': newValue,
        'reason': reason,
      });
    } catch (e) {
      // Ne pas bloquer l'action si le log échoue
      print('Audit log error: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getAuditLogs({
    int limit = 100,
    String? entityType,
    String? action,
  }) async {
    var query = client.from('admin_audit_logs')
        .select('*, admin:profiles!admin_id(full_name)');
    
    if (entityType != null) {
      query = query.eq('entity_type', entityType);
    }
    if (action != null) {
      query = query.eq('action', action);
    }
    
    final response = await query.order('created_at', ascending: false).limit(limit);
    return List<Map<String, dynamic>>.from(response);
  }

  // ============================================
  // DASHBOARD TEMPS RÉEL
  // ============================================

  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await client.rpc('get_admin_dashboard_stats');
      if (response is Map) {
        return Map<String, dynamic>.from(response);
      }
    } catch (e) {
      print('Dashboard stats error: $e');
    }
    
    // Fallback
    return await _getDashboardStatsFallback();
  }

  static Future<Map<String, dynamic>> _getDashboardStatsFallback() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    final pendingOrders = await client.from('orders').select('id').eq('status', 'pending').count(CountOption.exact);
    final preparingOrders = await client.from('orders').select('id').inFilter('status', ['confirmed', 'preparing']).count(CountOption.exact);
    final deliveringOrders = await client.from('orders').select('id').inFilter('status', ['picked_up', 'delivering']).count(CountOption.exact);
    
    final todayOrders = await client.from('orders')
        .select('total, admin_commission, status')
        .gte('created_at', startOfDay.toIso8601String());

    double todayRevenue = 0, todayCommission = 0;
    int todayDelivered = 0;
    for (var order in todayOrders) {
      if (order['status'] == 'delivered') {
        todayRevenue += (order['total'] ?? 0).toDouble();
        todayCommission += (order['admin_commission'] ?? 0).toDouble();
        todayDelivered++;
      }
    }

    final restaurants = await client.from('restaurants').select('is_verified, is_open');
    final livreurs = await client.from('livreurs').select('is_verified, is_online, is_available');
    
    int onlineRestaurants = 0, pendingRestaurants = 0;
    for (var r in restaurants) {
      if (r['is_verified'] == true && r['is_open'] == true) onlineRestaurants++;
      if (r['is_verified'] == false) pendingRestaurants++;
    }

    int onlineLivreurs = 0, availableLivreurs = 0, pendingLivreurs = 0;
    for (var l in livreurs) {
      if (l['is_verified'] == true && l['is_online'] == true) onlineLivreurs++;
      if (l['is_verified'] == true && l['is_online'] == true && l['is_available'] == true) availableLivreurs++;
      if (l['is_verified'] == false) pendingLivreurs++;
    }

    return {
      'pending_orders': pendingOrders.count,
      'preparing_orders': preparingOrders.count,
      'delivering_orders': deliveringOrders.count,
      'today_orders': todayOrders.length,
      'today_delivered': todayDelivered,
      'today_revenue': todayRevenue,
      'today_commission': todayCommission,
      'total_restaurants': restaurants.length,
      'online_restaurants': onlineRestaurants,
      'pending_restaurants': pendingRestaurants,
      'total_livreurs': livreurs.length,
      'online_livreurs': onlineLivreurs,
      'available_livreurs': availableLivreurs,
      'pending_livreurs': pendingLivreurs,
    };
  }

  // Realtime subscription pour le dashboard
  static RealtimeChannel subscribeToDashboard(void Function() onUpdate) {
    return client.channel('admin_dashboard')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          callback: (_) => onUpdate(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'livreurs',
          callback: (_) => onUpdate(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'restaurants',
          callback: (_) => onUpdate(),
        )
        .subscribe();
  }

  // ============================================
  // RESTAURANTS MANAGEMENT
  // ============================================
  
  static Future<List<Map<String, dynamic>>> getAllRestaurants() async {
    final response = await client
        .from('restaurants')
        .select('*, owner:profiles!restaurants_owner_id_fkey(full_name, phone)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<List<Map<String, dynamic>>> getPendingRestaurants() async {
    final response = await client
        .from('restaurants')
        .select('*, owner:profiles!restaurants_owner_id_fkey(full_name, phone)')
        .eq('is_verified', false)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> verifyRestaurant(String restaurantId, {String? reason}) async {
    final old = await client.from('restaurants').select().eq('id', restaurantId).single();
    
    await client.from('restaurants').update({
      'is_verified': true,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', restaurantId);

    await logAction(
      action: 'verify_restaurant',
      entityType: 'restaurant',
      entityId: restaurantId,
      oldValue: {'is_verified': false},
      newValue: {'is_verified': true},
      reason: reason ?? 'Validation manuelle',
    );
  }

  static Future<void> toggleRestaurantStatus(String restaurantId, bool isOpen, {String? reason}) async {
    await client.from('restaurants').update({
      'is_open': isOpen,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', restaurantId);

    await logAction(
      action: isOpen ? 'enable_restaurant' : 'disable_restaurant',
      entityType: 'restaurant',
      entityId: restaurantId,
      oldValue: {'is_open': !isOpen},
      newValue: {'is_open': isOpen},
      reason: reason,
    );
  }

  static Future<void> suspendRestaurant(String restaurantId, String reason, {DateTime? expiresAt}) async {
    final restaurant = await client.from('restaurants').select('owner_id').eq('id', restaurantId).single();
    
    await client.from('user_suspensions').insert({
      'user_id': restaurant['owner_id'],
      'user_type': 'restaurant',
      'reason': reason,
      'suspended_by': currentUser?.id,
      'expires_at': expiresAt?.toIso8601String(),
    });

    await client.from('restaurants').update({
      'is_open': false,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', restaurantId);

    await logAction(
      action: 'suspend_restaurant',
      entityType: 'restaurant',
      entityId: restaurantId,
      newValue: {'suspended': true, 'expires_at': expiresAt?.toIso8601String()},
      reason: reason,
    );
  }

  // ============================================
  // LIVREURS MANAGEMENT
  // ============================================
  
  static Future<List<Map<String, dynamic>>> getAllLivreurs() async {
    final response = await client
        .from('livreurs')
        .select('*, user:profiles!user_id(full_name, phone)')
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

  static Future<List<Map<String, dynamic>>> getOnlineLivreurs() async {
    final response = await client
        .from('livreurs')
        .select('*, user:profiles!user_id(full_name, phone)')
        .eq('is_verified', true)
        .eq('is_online', true)
        .order('is_available', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> verifyLivreur(String livreurId, {String? reason}) async {
    await client.from('livreurs').update({
      'is_verified': true,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', livreurId);

    await logAction(
      action: 'verify_livreur',
      entityType: 'livreur',
      entityId: livreurId,
      oldValue: {'is_verified': false},
      newValue: {'is_verified': true},
      reason: reason ?? 'Validation manuelle',
    );
  }

  static Future<void> suspendLivreur(String livreurId, String reason, {DateTime? expiresAt}) async {
    final livreur = await client.from('livreurs').select('user_id').eq('id', livreurId).single();
    
    await client.from('user_suspensions').insert({
      'user_id': livreur['user_id'],
      'user_type': 'livreur',
      'reason': reason,
      'suspended_by': currentUser?.id,
      'expires_at': expiresAt?.toIso8601String(),
    });

    await client.from('livreurs').update({
      'is_online': false,
      'is_available': false,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', livreurId);

    await logAction(
      action: 'suspend_livreur',
      entityType: 'livreur',
      entityId: livreurId,
      newValue: {'suspended': true, 'expires_at': expiresAt?.toIso8601String()},
      reason: reason,
    );
  }

  // ============================================
  // ORDERS MANAGEMENT
  // ============================================
  
  static Future<List<Map<String, dynamic>>> getAllOrders({
    int limit = 100,
    String? status,
    String? search,
  }) async {
    try {
      var query = client.from('orders').select('''
        *,
        customer:profiles!orders_customer_id_fkey(full_name, phone),
        restaurant:restaurants!orders_restaurant_id_fkey(name, phone),
        livreur:livreurs!orders_livreur_id_fkey(*, user:profiles(full_name, phone))
      ''');

      if (status != null && status.isNotEmpty) {
        query = query.eq('status', status);
      }

      final response = await query.order('created_at', ascending: false).limit(limit);
      var orders = List<Map<String, dynamic>>.from(response);

      print('✅ Admin getAllOrders: ${orders.length} commandes récupérées');

      // Filtrer par recherche côté client si nécessaire
      if (search != null && search.isNotEmpty) {
        final searchLower = search.toLowerCase();
        orders = orders.where((o) {
          final orderNumber = (o['order_number'] ?? '').toString().toLowerCase();
          final customerName = (o['customer']?['full_name'] ?? '').toString().toLowerCase();
          final customerPhone = (o['customer']?['phone'] ?? '').toString().toLowerCase();
          return orderNumber.contains(searchLower) ||
                 customerName.contains(searchLower) ||
                 customerPhone.contains(searchLower);
        }).toList();
      }

      return orders;
    } catch (e) {
      print('❌ Erreur getAllOrders: $e');
      // Retourner liste vide au lieu de throw pour éviter crash
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getOrderDetails(String orderId) async {
    final response = await client.from('orders').select('''
      *,
      customer:profiles!orders_customer_id_fkey(full_name, phone, email:id),
      restaurant:restaurants!orders_restaurant_id_fkey(name, phone, address),
      livreur:livreurs!orders_livreur_id_fkey(*, user:profiles(full_name, phone)),
      order_items(*)
    ''').eq('id', orderId).single();
    return response;
  }

  static Future<List<Map<String, dynamic>>> getOrderTimeline(String orderId) async {
    // Récupérer les événements d'audit pour cette commande
    final logs = await client.from('admin_audit_logs')
        .select()
        .eq('entity_type', 'order')
        .eq('entity_id', orderId)
        .order('created_at', ascending: true);
    
    // Récupérer aussi les changements de statut depuis audit_events
    final events = await client.from('audit_events')
        .select()
        .eq('table_name', 'orders')
        .eq('record_id', orderId)
        .order('created_at', ascending: true);

    return [...List<Map<String, dynamic>>.from(logs), ...List<Map<String, dynamic>>.from(events)];
  }

  /// Forcer le changement de statut (admin only)
  static Future<void> forceOrderStatus(String orderId, String newStatus, String reason) async {
    final order = await client.from('orders').select('status').eq('id', orderId).single();
    final oldStatus = order['status'];

    await client.from('orders').update({
      'status': newStatus,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', orderId);

    await logAction(
      action: 'force_order_status',
      entityType: 'order',
      entityId: orderId,
      oldValue: {'status': oldStatus},
      newValue: {'status': newStatus},
      reason: reason,
    );
  }

  /// Réassigner un livreur
  static Future<void> reassignLivreur(String orderId, String newLivreurId, String reason) async {
    final order = await client.from('orders').select('livreur_id').eq('id', orderId).single();
    final oldLivreurId = order['livreur_id'];

    // Libérer l'ancien livreur
    if (oldLivreurId != null) {
      await client.from('livreurs').update({'is_available': true}).eq('id', oldLivreurId);
    }

    // Assigner le nouveau
    await client.from('orders').update({
      'livreur_id': newLivreurId,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', orderId);

    await client.from('livreurs').update({'is_available': false}).eq('id', newLivreurId);

    await logAction(
      action: 'reassign_livreur',
      entityType: 'order',
      entityId: orderId,
      oldValue: {'livreur_id': oldLivreurId},
      newValue: {'livreur_id': newLivreurId},
      reason: reason,
    );
  }

  /// Annuler une commande (admin)
  static Future<void> adminCancelOrder(String orderId, String reason) async {
    final order = await client.from('orders').select('status, livreur_id').eq('id', orderId).single();
    
    await client.from('orders').update({
      'status': 'cancelled',
      'cancelled_at': DateTime.now().toIso8601String(),
      'cancellation_reason': reason,
      'cancelled_by': 'admin',
    }).eq('id', orderId);

    // Libérer le livreur si assigné
    if (order['livreur_id'] != null) {
      await client.from('livreurs').update({'is_available': true}).eq('id', order['livreur_id']);
    }

    await logAction(
      action: 'admin_cancel_order',
      entityType: 'order',
      entityId: orderId,
      oldValue: {'status': order['status']},
      newValue: {'status': 'cancelled'},
      reason: reason,
    );
  }

  // ============================================
  // INCIDENTS
  // ============================================

  static Future<List<Map<String, dynamic>>> getIncidents({
    String? status,
    String? priority,
    int limit = 50,
  }) async {
    var query = client.from('incidents')
        .select('*, order:orders(order_number), assigned:profiles!assigned_to(full_name)');

    if (status != null) query = query.eq('status', status);
    if (priority != null) query = query.eq('priority', priority);

    final response = await query.order('created_at', ascending: false).limit(limit);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> createIncident({
    required String title,
    required String incidentType,
    String? description,
    String? priority,
    String? orderId,
    String? customerId,
    String? restaurantId,
    String? livreurId,
  }) async {
    final incident = await client.from('incidents').insert({
      'title': title,
      'description': description,
      'incident_type': incidentType,
      'priority': priority ?? 'medium',
      'order_id': orderId,
      'customer_id': customerId,
      'restaurant_id': restaurantId,
      'livreur_id': livreurId,
      'created_by': currentUser?.id,
    }).select().single();

    await logAction(
      action: 'create_incident',
      entityType: 'incident',
      entityId: incident['id'],
      newValue: {'title': title, 'type': incidentType},
    );
  }

  static Future<void> updateIncidentStatus(String incidentId, String status, {String? resolution}) async {
    final updates = <String, dynamic>{
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (status == 'resolved' || status == 'closed') {
      updates['resolved_at'] = DateTime.now().toIso8601String();
      updates['resolved_by'] = currentUser?.id;
      if (resolution != null) updates['resolution'] = resolution;
    }

    await client.from('incidents').update(updates).eq('id', incidentId);

    await logAction(
      action: 'update_incident',
      entityType: 'incident',
      entityId: incidentId,
      newValue: {'status': status},
    );
  }

  // ============================================
  // PARAMÈTRES PLATEFORME
  // ============================================

  static Future<Map<String, dynamic>> getPlatformSettings() async {
    final response = await client.from('platform_settings').select();
    final settings = <String, dynamic>{};
    for (var s in response) {
      settings[s['key']] = s['value'];
    }
    return settings;
  }

  static Future<void> updatePlatformSetting(String key, dynamic value, {String? reason}) async {
    final old = await client.from('platform_settings').select('value').eq('key', key).single();
    
    await client.from('platform_settings').update({
      'value': value.toString(),
      'updated_by': currentUser?.id,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('key', key);

    await logAction(
      action: 'update_setting',
      entityType: 'settings',
      oldValue: {'key': key, 'value': old['value']},
      newValue: {'key': key, 'value': value},
      reason: reason,
    );
  }

  // ============================================
  // FINANCE
  // ============================================

  static Future<Map<String, dynamic>> getGlobalFinanceReport() async {
    final deliveredOrders = await client
        .from('orders')
        .select('total, delivery_fee, admin_commission, livreur_commission, restaurant_amount, created_at')
        .eq('status', 'delivered');

    final today = DateTime.now();
    final startOfMonth = DateTime(today.year, today.month, 1);

    double totalRevenue = 0, totalAdminCommission = 0, totalLivreurCommission = 0;
    double totalRestaurantAmount = 0, monthRevenue = 0, monthCommission = 0;
    double totalDeliveryFees = 0, totalServiceFees = 0;

    for (var order in deliveredOrders) {
      totalRevenue += (order['total'] ?? 0).toDouble();
      totalAdminCommission += (order['admin_commission'] ?? 0).toDouble();
      totalLivreurCommission += (order['livreur_commission'] ?? 0).toDouble();
      totalRestaurantAmount += (order['restaurant_amount'] ?? 0).toDouble();
      totalDeliveryFees += (order['delivery_fee'] ?? 0).toDouble();

      final createdAt = DateTime.parse(order['created_at']);
      if (createdAt.isAfter(startOfMonth)) {
        monthRevenue += (order['total'] ?? 0).toDouble();
        monthCommission += (order['admin_commission'] ?? 0).toDouble();
      }
    }

    return {
      'total_orders': deliveredOrders.length,
      'total_revenue': totalRevenue,
      'total_commission': totalAdminCommission,
      'total_admin_commission': totalAdminCommission,
      'total_livreur_commission': totalLivreurCommission,
      'total_restaurant_amount': totalRestaurantAmount,
      'total_delivery_fees': totalDeliveryFees,
      'total_service_fees': totalServiceFees,
      'month_revenue': monthRevenue,
      'month_commission': monthCommission,
    };
  }

  static Future<List<Map<String, dynamic>>> getAllRestaurantsWithStats() async {
    final restaurants = await getAllRestaurants();
    List<Map<String, dynamic>> result = [];

    for (var restaurant in restaurants) {
      final orders = await client
          .from('orders')
          .select('total, admin_commission, restaurant_amount')
          .eq('restaurant_id', restaurant['id'])
          .eq('status', 'delivered');

      double totalRevenue = 0, totalCommission = 0, netRevenue = 0;
      for (var order in orders) {
        totalRevenue += (order['total'] ?? 0).toDouble();
        totalCommission += (order['admin_commission'] ?? 0).toDouble();
        netRevenue += (order['restaurant_amount'] ?? 0).toDouble();
      }

      result.add({
        ...restaurant,
        'stats': {
          'total_orders': orders.length,
          'total_revenue': totalRevenue,
          'total_commission': totalCommission,
          'net_revenue': netRevenue,
        },
      });
    }

    return result;
  }

  // ============================================
  // DELETE OPERATIONS (avec audit)
  // ============================================

  static Future<void> deleteRestaurant(String restaurantId) async {
    final restaurant = await client.from('restaurants').select('name').eq('id', restaurantId).single();
    
    await client.from('restaurants').delete().eq('id', restaurantId);

    await logAction(
      action: 'delete_restaurant',
      entityType: 'restaurant',
      entityId: restaurantId,
      oldValue: {'name': restaurant['name']},
      reason: 'Suppression manuelle',
    );
  }

  static Future<void> deleteLivreur(String livreurId) async {
    final livreur = await client.from('livreurs').select('user:profiles!user_id(full_name)').eq('id', livreurId).single();
    
    await client.from('livreurs').delete().eq('id', livreurId);

    await logAction(
      action: 'delete_livreur',
      entityType: 'livreur',
      entityId: livreurId,
      oldValue: {'name': livreur['user']?['full_name']},
      reason: 'Suppression manuelle',
    );
  }

  // ============================================
  // ACTIONS D'URGENCE (CRISE)
  // ============================================

  /// Forcer la libération d'un livreur bloqué
  static Future<bool> forceReleaseLivreur(String livreurId, String reason) async {
    try {
      await client.from('livreurs').update({
        'is_available': true,
        'is_online': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', livreurId);

      await logAction(
        action: 'force_release_livreur',
        entityType: 'livreur',
        entityId: livreurId,
        reason: reason,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Débloquer le code de confirmation d'une commande
  static Future<bool> unblockConfirmationCode(String orderId) async {
    try {
      final result = await client.rpc('admin_unblock_code', params: {
        'p_order_id': orderId,
        'p_admin_id': currentUser?.id,
      });
      return result == true;
    } catch (e) {
      return false;
    }
  }

  /// Forcer le statut "livré" (cas extrême)
  static Future<bool> forceDelivered(String orderId, String reason) async {
    try {
      await client.from('orders').update({
        'status': 'delivered',
        'delivered_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      // Libérer le livreur
      final order = await client.from('orders').select('livreur_id').eq('id', orderId).single();
      if (order['livreur_id'] != null) {
        await client.from('livreurs').update({'is_available': true}).eq('id', order['livreur_id']);
      }

      await logAction(
        action: 'force_delivered',
        entityType: 'order',
        entityId: orderId,
        reason: reason,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Récupérer les commandes bloquées (en cours depuis trop longtemps)
  static Future<List<Map<String, dynamic>>> getStuckOrders() async {
    final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
    
    final response = await client
        .from('orders')
        .select('*, restaurant:restaurants(name), livreur:livreurs(user:profiles!user_id(full_name, phone))')
        .inFilter('status', ['pending', 'confirmed', 'preparing', 'ready', 'picked_up', 'delivering'])
        .lt('created_at', oneHourAgo.toIso8601String())
        .order('created_at', ascending: true);
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// Récupérer les livreurs inactifs (en ligne mais pas de mouvement)
  static Future<List<Map<String, dynamic>>> getInactiveLivreurs() async {
    final thirtyMinAgo = DateTime.now().subtract(const Duration(minutes: 30));
    
    final response = await client
        .from('livreurs')
        .select('*, user:profiles!user_id(full_name, phone)')
        .eq('is_online', true)
        .eq('is_available', false)
        .lt('updated_at', thirtyMinAgo.toIso8601String());
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// Envoyer une notification push à un utilisateur
  static Future<void> sendPushNotification({
    required String userId,
    required String title,
    required String body,
  }) async {
    final tokens = await client
        .from('fcm_tokens')
        .select('token')
        .eq('user_id', userId);
    
    if (tokens.isEmpty) return;
    
    await client.from('notifications').insert({
      'user_id': userId,
      'title': title,
      'body': body,
      'notification_type': 'admin_alert',
    });
  }

  // ============================================
  // SYSTEM SETTINGS
  // ============================================

  /// Récupérer les paramètres système
  static Future<Map<String, dynamic>?> getSystemSettings() async {
    try {
      final response = await client
          .from('system_settings')
          .select()
          .limit(1)
          .maybeSingle();
      
      if (response == null) {
        // Retourner valeurs par défaut si pas de settings
        return {
          'commission_rate': 10.0,
          'service_fee': 50.0,
          'min_order_amount': 500.0,
          'base_delivery_fee': 150.0,
          'per_km_fee': 30.0,
          'max_delivery_distance': 10.0,
          'max_active_orders': 5,
          'max_daily_orders': 100,
        };
      }
      
      return response;
    } catch (e) {
      print('❌ Erreur getSystemSettings: $e');
      // Retourner valeurs par défaut en cas d'erreur
      return {
        'commission_rate': 10.0,
        'service_fee': 50.0,
        'min_order_amount': 500.0,
        'base_delivery_fee': 150.0,
        'per_km_fee': 30.0,
        'max_delivery_distance': 10.0,
        'max_active_orders': 5,
        'max_daily_orders': 100,
      };
    }
  }

  /// Mettre à jour les paramètres système
  static Future<void> updateSystemSettings(Map<String, dynamic> settings) async {
    try {
      // Vérifier si des settings existent
      final existing = await client
          .from('system_settings')
          .select('id')
          .limit(1)
          .maybeSingle();
      
      if (existing != null) {
        // Update
        await client
            .from('system_settings')
            .update({
              ...settings,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existing['id']);
      } else {
        // Insert
        await client.from('system_settings').insert({
          ...settings,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      await logAction(
        action: 'update_system_settings',
        entityType: 'system_settings',
        newValue: settings,
        reason: 'Mise à jour des paramètres système',
      );
      
      print('✅ Paramètres système mis à jour');
    } catch (e) {
      print('❌ Erreur updateSystemSettings: $e');
      rethrow;
    }
  }

  // ============================================
  // UTILS
  // ============================================

  static Future<void> unsubscribe(RealtimeChannel channel) async {
    await client.removeChannel(channel);
  }
}
