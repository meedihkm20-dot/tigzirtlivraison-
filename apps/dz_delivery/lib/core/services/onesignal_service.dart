import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

/// Service OneSignal pour les notifications push (GRATUIT)
class OneSignalService {
  // ✅ App ID OneSignal configuré
  static const String appId = '8eccb16a-e9da-4a95-8b17-004a1b2664ba';

  /// Initialiser OneSignal
  static Future<void> initialize() async {
    // Mode debug (désactiver en production)
    if (kDebugMode) {
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    }

    // Initialiser avec l'App ID
    OneSignal.initialize(appId);

    // Demander la permission pour les notifications
    OneSignal.Notifications.requestPermission(true);

    // Écouter les notifications reçues
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      debugPrint('🔔 Notification reçue: ${event.notification.title}');
      // Afficher la notification même si l'app est au premier plan
      event.preventDefault();
      event.notification.display();
    });

    // Écouter les clics sur les notifications
    OneSignal.Notifications.addClickListener((event) {
      debugPrint('🔔 Notification cliquée: ${event.notification.title}');
      final data = event.notification.additionalData;
      if (data != null) {
        _handleNotificationClick(data);
      }
    });

    debugPrint('✅ OneSignal initialized');
  }

  /// Lier l'utilisateur Supabase à OneSignal
  /// Appeler après connexion réussie
  static Future<void> login(String userId, {String? role}) async {
    await OneSignal.login(userId);

    // Ajouter des tags pour filtrer les notifications
    if (role != null) {
      await OneSignal.User.addTags({
        'role': role,
        'user_id': userId,
      });
    }

    debugPrint('✅ OneSignal login: $userId (role: $role)');
  }

  /// Déconnecter l'utilisateur de OneSignal
  /// Appeler lors de la déconnexion
  static Future<void> logout() async {
    await OneSignal.logout();
    debugPrint('✅ OneSignal logout');
  }

  /// Ajouter des tags personnalisés
  static Future<void> addTags(Map<String, String> tags) async {
    await OneSignal.User.addTags(tags);
    debugPrint('✅ OneSignal tags added: $tags');
  }

  /// Supprimer des tags
  static Future<void> removeTags(List<String> keys) async {
    await OneSignal.User.removeTags(keys);
    debugPrint('✅ OneSignal tags removed: $keys');
  }

  /// Gérer le clic sur une notification
  static void _handleNotificationClick(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final orderId = data['order_id'] as String?;

    debugPrint('📱 Notification type: $type, orderId: $orderId');

    // TODO: Naviguer vers l'écran approprié selon le type
    // switch (type) {
    //   case 'new_order':
    //     // Naviguer vers les détails de la commande
    //     break;
    //   case 'order_accepted':
    //   case 'order_ready':
    //   case 'driver_assigned':
    //   case 'order_delivered':
    //     // Naviguer vers le suivi de commande
    //     break;
    // }
  }
}
