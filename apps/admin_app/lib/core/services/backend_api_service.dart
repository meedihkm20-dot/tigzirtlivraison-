import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service pour communiquer avec le backend NestJS (Koyeb)
class BackendApiService {
  // ⚠️ REMPLACER par ton URL Koyeb après déploiement
  static const String baseUrl = 'https://tigzirt-backend.koyeb.app';

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
  // ADMIN ENDPOINTS
  // ═══════════════════════════════════════════════

  /// Envoyer notification à un utilisateur
  Future<void> sendNotification(
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

  /// Notifier nouvelle commande au restaurant
  Future<void> notifyNewOrder(String orderId) async {
    await post('/api/notifications/new-order', {'order_id': orderId});
  }

  /// Notifier commande acceptée au client
  Future<void> notifyOrderAccepted(String orderId) async {
    await post('/api/notifications/order-accepted', {'order_id': orderId});
  }

  /// Notifier commande prête au client
  Future<void> notifyOrderReady(String orderId) async {
    await post('/api/notifications/order-ready', {'order_id': orderId});
  }

  /// Notifier livreur assigné
  Future<void> notifyDriverAssigned(String orderId, String driverId) async {
    await post('/api/notifications/driver-assigned', {
      'order_id': orderId,
      'driver_id': driverId,
    });
  }

  /// Notifier commande livrée
  Future<void> notifyOrderDelivered(String orderId) async {
    await post('/api/notifications/order-delivered', {'order_id': orderId});
  }

  /// Notifier commande annulée
  Future<void> notifyOrderCancelled(String orderId, {String? reason}) async {
    await post('/api/notifications/order-cancelled', {
      'order_id': orderId,
      if (reason != null) 'reason': reason,
    });
  }
}
