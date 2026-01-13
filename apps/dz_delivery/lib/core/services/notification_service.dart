import 'package:flutter/material.dart';
import 'supabase_service.dart';

/// Service de notifications (Firebase FCM + Local)
/// Note: Firebase nécessite configuration dans Firebase Console
class NotificationService {
  static String? _fcmToken;
  
  static String? get fcmToken => _fcmToken;

  /// Initialiser les notifications
  static Future<void> init() async {
    // Pour l'instant, on utilise les notifications locales via Supabase Realtime
    // Firebase FCM sera ajouté quand tu configureras le projet Firebase
    debugPrint('NotificationService initialized');
  }

  /// Sauvegarder le token FCM dans le profil utilisateur
  static Future<void> saveToken(String token) async {
    _fcmToken = token;
    final user = SupabaseService.currentUser;
    if (user != null) {
      await SupabaseService.client
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', user.id);
    }
  }

  /// Envoyer une notification (stockée en DB, envoyée via Edge Function)
  static Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    await SupabaseService.client.from('notifications').insert({
      'user_id': userId,
      'title': title,
      'body': body,
      'notification_type': type,
      'data': data,
    });
  }

  /// Récupérer les notifications de l'utilisateur
  static Future<List<Map<String, dynamic>>> getNotifications({int limit = 50}) async {
    final user = SupabaseService.currentUser;
    if (user == null) return [];
    
    final response = await SupabaseService.client
        .from('notifications')
        .select()
        .eq('user_id', user.id)
        .order('sent_at', ascending: false)
        .limit(limit);
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// Marquer une notification comme lue
  static Future<void> markAsRead(String notificationId) async {
    await SupabaseService.client
        .from('notifications')
        .update({'is_read': true, 'read_at': DateTime.now().toIso8601String()})
        .eq('id', notificationId);
  }

  /// Marquer toutes comme lues
  static Future<void> markAllAsRead() async {
    final user = SupabaseService.currentUser;
    if (user == null) return;
    
    await SupabaseService.client
        .from('notifications')
        .update({'is_read': true, 'read_at': DateTime.now().toIso8601String()})
        .eq('user_id', user.id)
        .eq('is_read', false);
  }

  /// Compter les notifications non lues
  static Future<int> getUnreadCount() async {
    final user = SupabaseService.currentUser;
    if (user == null) return 0;
    
    final response = await SupabaseService.client
        .from('notifications')
        .select('id')
        .eq('user_id', user.id)
        .eq('is_read', false);
    
    return (response as List).length;
  }

  /// Notifications par type
  static Future<void> notifyOrderStatus({
    required String customerId,
    required String orderNumber,
    required String status,
  }) async {
    String title, body;
    
    switch (status) {
      case 'confirmed':
        title = '✅ Commande confirmée';
        body = 'Votre commande #$orderNumber est en préparation';
        break;
      case 'ready':
        title = '🍽️ Commande prête';
        body = 'Votre commande #$orderNumber est prête, le livreur arrive';
        break;
      case 'picked_up':
        title = '🛵 Livreur en route';
        body = 'Votre commande #$orderNumber est en chemin!';
        break;
      case 'delivered':
        title = '🎉 Commande livrée';
        body = 'Bon appétit! N\'oubliez pas de noter votre expérience';
        break;
      case 'cancelled':
        title = '❌ Commande annulée';
        body = 'Votre commande #$orderNumber a été annulée';
        break;
      default:
        return;
    }
    
    await sendNotification(
      userId: customerId,
      title: title,
      body: body,
      type: 'order_status',
      data: {'order_number': orderNumber, 'status': status},
    );
  }

  /// Notifier le restaurant d'une nouvelle commande
  static Future<void> notifyNewOrderToRestaurant({
    required String restaurantOwnerId,
    required String orderNumber,
    required double total,
  }) async {
    await sendNotification(
      userId: restaurantOwnerId,
      title: '🔔 Nouvelle commande!',
      body: 'Commande #$orderNumber - ${total.toStringAsFixed(0)} DA',
      type: 'new_order',
      data: {'order_number': orderNumber},
    );
  }

  /// Notifier les livreurs d'une commande disponible
  static Future<void> notifyLivreursNewOrder({
    required String restaurantName,
    required String orderNumber,
    required double commission,
  }) async {
    // Récupérer tous les livreurs disponibles
    final livreurs = await SupabaseService.client
        .from('livreurs')
        .select('user_id')
        .eq('is_online', true)
        .eq('is_available', true);
    
    for (final livreur in livreurs) {
      await sendNotification(
        userId: livreur['user_id'],
        title: '📦 Nouvelle livraison disponible',
        body: '$restaurantName - Gain: ${commission.toStringAsFixed(0)} DA',
        type: 'new_delivery',
        data: {'order_number': orderNumber, 'commission': commission},
      );
    }
  }

  /// Notifier un bonus gagné
  static Future<void> notifyBonusEarned({
    required String livreurUserId,
    required double amount,
    required String reason,
  }) async {
    await sendNotification(
      userId: livreurUserId,
      title: '🎁 Bonus gagné!',
      body: '+${amount.toStringAsFixed(0)} DA - $reason',
      type: 'bonus',
      data: {'amount': amount},
    );
  }

  /// Notifier changement de tier
  static Future<void> notifyTierChange({
    required String livreurUserId,
    required String newTier,
    required double newCommissionRate,
  }) async {
    final tierEmoji = {
      'bronze': '🥉',
      'silver': '🥈',
      'gold': '🥇',
      'diamond': '💎',
    };
    
    await sendNotification(
      userId: livreurUserId,
      title: '${tierEmoji[newTier]} Niveau ${newTier.toUpperCase()}!',
      body: 'Nouvelle commission: ${newCommissionRate.toStringAsFixed(0)}%',
      type: 'tier_change',
      data: {'tier': newTier, 'commission_rate': newCommissionRate},
    );
  }
}
