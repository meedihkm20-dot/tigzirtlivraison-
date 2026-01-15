import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service pour communiquer avec le backend NestJS (Koyeb)
class BackendApiService {
  // ✅ Backend Koyeb déployé
  static const String baseUrl = 'https://angry-bertha-1tigizrtlivraison1-86549eb3.koyeb.app';

  final SupabaseClient _supabase;

  BackendApiService(this._supabase);

  /// Headers avec token Supabase
  Future<Map<String, String>> get _headers async {
    final session = _supabase.auth.currentSession;
    return {
      'Content-Type': 'application/json',
      if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
    };
  }

  /// POST request
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _headers,
      body: json.encode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('API Error: ${response.body}');
    }

    return json.decode(response.body);
  }

  /// GET request
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? params,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint').replace(queryParameters: params);
    final response = await http.get(uri, headers: await _headers);

    if (response.statusCode != 200) {
      throw Exception('API Error: ${response.body}');
    }

    return json.decode(response.body);
  }

  // ═══════════════════════════════════════════════
  // DELIVERY ENDPOINTS
  // ═══════════════════════════════════════════════

  /// Calculer le prix de livraison (côté serveur = sécurisé)
  Future<int> calculateDeliveryPrice(double distance, String zone) async {
    final result = await get('/api/delivery/calculate-price', params: {
      'distance': distance.toString(),
      'zone': zone,
    });
    return result['price'];
  }

  /// Estimer le temps de livraison
  Future<int> estimateDeliveryTime(
    double distance,
    int preparationTime,
  ) async {
    final result = await get('/api/delivery/estimate-time', params: {
      'distance': distance.toString(),
      'preparation_time': preparationTime.toString(),
    });
    return result['estimated_minutes'];
  }

  // ═══════════════════════════════════════════════
  // ORDERS ENDPOINTS
  // ═══════════════════════════════════════════════

  /// Créer une commande (validation côté serveur)
  Future<Map<String, dynamic>> createOrder({
    required String restaurantId,
    required List<Map<String, dynamic>> items,
    required String deliveryAddress,
    required double deliveryLat,
    required double deliveryLng,
    String? notes,
  }) async {
    return post('/api/orders/create', {
      'restaurant_id': restaurantId,
      'items': items,
      'delivery_address': deliveryAddress,
      'delivery_lat': deliveryLat,
      'delivery_lng': deliveryLng,
      if (notes != null) 'notes': notes,
    });
  }

  /// Accepter une commande (restaurant)
  Future<void> acceptOrder(String orderId) async {
    await post('/api/orders/$orderId/accept', {});
  }

  /// Marquer commande prête (restaurant)
  Future<Map<String, dynamic>> markOrderReady(String orderId) async {
    return post('/api/orders/$orderId/ready', {});
  }

  /// Confirmer livraison (livreur)
  Future<void> markOrderDelivered(String orderId) async {
    await post('/api/orders/$orderId/delivered', {});
  }

  // ═══════════════════════════════════════════════
  // NOTIFICATIONS ENDPOINTS
  // ═══════════════════════════════════════════════

  /// Tester une notification
  Future<void> testNotification(
    String userId,
    String title,
    String message,
  ) async {
    await post('/api/notifications/test', {
      'user_id': userId,
      'title': title,
      'message': message,
    });
  }

  // ═══════════════════════════════════════════════
  // ORDER STATUS ENDPOINTS (Migration Edge Functions)
  // ═══════════════════════════════════════════════

  /// Changer le statut d'une commande (transitions validées côté serveur)
  Future<Map<String, dynamic>> changeOrderStatus(
    String orderId,
    String status, {
    String? note,
  }) async {
    return post('/api/orders/$orderId/status', {
      'status': status,
      if (note != null) 'note': note,
    });
  }

  /// Annuler une commande
  Future<Map<String, dynamic>> cancelOrder(
    String orderId,
    String reason, {
    String? details,
  }) async {
    return post('/api/orders/$orderId/cancel', {
      'reason': reason,
      if (details != null) 'details': details,
    });
  }

  /// Vérifier le code de confirmation et finaliser la livraison
  Future<Map<String, dynamic>> verifyDelivery(
    String orderId,
    String verificationCode,
  ) async {
    return post('/api/delivery/verify', {
      'order_id': orderId,
      'verification_code': verificationCode,
    });
  }
}
