import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Service de chat pour la communication livreur-client
class DeliveryChatService {
  static final _supabase = SupabaseService.client;
  
  /// Envoyer un message dans le chat de livraison
  static Future<void> sendMessage({
    required String orderId,
    required String message,
    required String senderType, // 'livreur' ou 'customer'
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Utilisateur non connecté');
      
      await _supabase.from('delivery_messages').insert({
        'order_id': orderId,
        'sender_id': userId,
        'sender_type': senderType,
        'message': message,
        'sent_at': DateTime.now().toIso8601String(),
      });
      
      debugPrint('✅ Message envoyé: $message');
    } catch (e) {
      debugPrint('❌ Erreur envoi message: $e');
      rethrow;
    }
  }
  
  /// Écouter les messages d'une commande en temps réel
  static Stream<List<DeliveryMessage>> listenToMessages(String orderId) {
    return _supabase
        .from('delivery_messages')
        .stream(primaryKey: ['id'])
        .eq('order_id', orderId)
        .order('sent_at', ascending: true)
        .map((data) => data.map((json) => DeliveryMessage.fromJson(json)).toList());
  }
  
  /// Obtenir l'historique des messages
  static Future<List<DeliveryMessage>> getMessageHistory(String orderId) async {
    try {
      final response = await _supabase
          .from('delivery_messages')
          .select()
          .eq('order_id', orderId)
          .order('sent_at', ascending: true);
      
      return (response as List)
          .map((json) => DeliveryMessage.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Erreur récupération messages: $e');
      return [];
    }
  }
  
  /// Marquer les messages comme lus
  static Future<void> markMessagesAsRead({
    required String orderId,
    required String userType,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      
      // Marquer comme lus tous les messages de l'autre utilisateur
      final otherUserType = userType == 'livreur' ? 'customer' : 'livreur';
      
      await _supabase
          .from('delivery_messages')
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('order_id', orderId)
          .eq('sender_type', otherUserType)
          .isFilter('read_at', null);
          
    } catch (e) {
      debugPrint('❌ Erreur marquage messages lus: $e');
    }
  }
  
  /// Compter les messages non lus
  static Future<int> getUnreadCount({
    required String orderId,
    required String userType,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;
      
      // Compter les messages de l'autre utilisateur non lus
      final otherUserType = userType == 'livreur' ? 'customer' : 'livreur';
      
      final response = await _supabase
          .from('delivery_messages')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('order_id', orderId)
          .eq('sender_type', otherUserType)
          .isFilter('read_at', null);
      
      return response.count ?? 0;
    } catch (e) {
      debugPrint('❌ Erreur comptage messages non lus: $e');
      return 0;
    }
  }
  
  /// Messages prédéfinis pour les livreurs
  static const List<String> quickMessages = [
    "Je suis en route vers le restaurant 🚗",
    "J'ai récupéré votre commande ✅",
    "Je suis en route vers vous 🛵",
    "J'arrive dans 5 minutes ⏰",
    "Je suis devant votre adresse 📍",
    "Pouvez-vous descendre s'il vous plaît? 🏠",
    "Merci et bonne dégustation! 😊",
    "Désolé pour le retard 😅",
    "Le restaurant prépare encore votre commande ⏳",
    "Problème de circulation, j'arrive bientôt 🚦",
  ];
  
  /// Messages prédéfinis pour les clients
  static const List<String> customerQuickMessages = [
    "Merci, j'attends 😊",
    "Je descends tout de suite 🏃‍♂️",
    "Pouvez-vous sonner à l'interphone? 🔔",
    "Je suis au bureau, 2ème étage 🏢",
    "Laissez devant la porte s'il vous plaît 🚪",
    "Combien de temps encore? ⏰",
    "Merci beaucoup! 🙏",
  ];
}

/// Modèle pour un message de livraison
class DeliveryMessage {
  final String id;
  final String orderId;
  final String senderId;
  final String senderType;
  final String message;
  final DateTime sentAt;
  final DateTime? readAt;
  
  const DeliveryMessage({
    required this.id,
    required this.orderId,
    required this.senderId,
    required this.senderType,
    required this.message,
    required this.sentAt,
    this.readAt,
  });
  
  factory DeliveryMessage.fromJson(Map<String, dynamic> json) {
    return DeliveryMessage(
      id: json['id'].toString(),
      orderId: json['order_id'],
      senderId: json['sender_id'],
      senderType: json['sender_type'],
      message: json['message'],
      sentAt: DateTime.parse(json['sent_at']),
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'sender_id': senderId,
      'sender_type': senderType,
      'message': message,
      'sent_at': sentAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
    };
  }
  
  /// Vérifier si le message est lu
  bool get isRead => readAt != null;
  
  /// Vérifier si c'est un message du livreur
  bool get isFromLivreur => senderType == 'livreur';
  
  /// Vérifier si c'est un message du client
  bool get isFromCustomer => senderType == 'customer';
  
  /// Temps formaté
  String get formattedTime {
    final now = DateTime.now();
    final diff = now.difference(sentAt);
    
    if (diff.inMinutes < 1) {
      return 'À l\'instant';
    } else if (diff.inMinutes < 60) {
      return 'Il y a ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return 'Il y a ${diff.inHours}h';
    } else {
      return '${sentAt.day}/${sentAt.month} ${sentAt.hour}:${sentAt.minute.toString().padLeft(2, '0')}';
    }
  }
}