import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

/// Service OneSignal pour les notifications push (GRATUIT)
class OneSignalService {
  // ✅ App ID OneSignal configuré
  static const String appId = '8eccb16a-e9da-4a95-8b17-004a1b2664ba';
  
  // Navigation context pour rediriger depuis les notifications
  static GlobalKey<NavigatorState>? navigatorKey;

  /// Initialiser OneSignal
  static Future<void> initialize({GlobalKey<NavigatorState>? navKey}) async {
    navigatorKey = navKey;
    
    // Mode debug (désactiver en production)
    if (kDebugMode) {
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    }

    // Initialiser avec l'App ID
    OneSignal.initialize(appId);

    // Demander la permission pour les notifications
    OneSignal.Notifications.requestPermission(true);

    // Écouter les notifications reçues (app au premier plan)
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      debugPrint('🔔 Notification reçue (foreground): ${event.notification.title}');
      
      // Afficher la notification même si l'app est au premier plan
      event.preventDefault();
      event.notification.display();
      
      // Optionnel: Afficher un SnackBar ou dialog custom
      _showInAppNotification(event.notification);
    });

    // Écouter les clics sur les notifications (app fermée ou en arrière-plan)
    OneSignal.Notifications.addClickListener((event) {
      debugPrint('🔔 Notification cliquée: ${event.notification.title}');
      final data = event.notification.additionalData;
      if (data != null) {
        _handleNotificationClick(data);
      }
    });

    // Écouter les changements de permission
    OneSignal.Notifications.addPermissionObserver((state) {
      debugPrint('🔔 Permission notifications: ${state ? "Accordée" : "Refusée"}');
    });

    debugPrint('✅ OneSignal initialized with App ID: $appId');
  }

  /// Lier l'utilisateur Supabase à OneSignal
  /// Appeler après connexion réussie
  static Future<void> login(String userId, {String? role}) async {
    try {
      await OneSignal.login(userId);

      // Ajouter des tags pour filtrer les notifications
      final tags = <String, String>{
        'user_id': userId,
        'app_version': '1.0.0',
        'platform': 'flutter',
      };
      
      if (role != null) {
        tags['role'] = role;
      }
      
      await OneSignal.User.addTags(tags);

      debugPrint('✅ OneSignal login: $userId (role: $role)');
    } catch (e) {
      debugPrint('❌ OneSignal login error: $e');
    }
  }

  /// Déconnecter l'utilisateur de OneSignal
  /// Appeler lors de la déconnexion
  static Future<void> logout() async {
    try {
      await OneSignal.logout();
      debugPrint('✅ OneSignal logout');
    } catch (e) {
      debugPrint('❌ OneSignal logout error: $e');
    }
  }

  /// Ajouter des tags personnalisés
  static Future<void> addTags(Map<String, String> tags) async {
    try {
      await OneSignal.User.addTags(tags);
      debugPrint('✅ OneSignal tags added: $tags');
    } catch (e) {
      debugPrint('❌ OneSignal addTags error: $e');
    }
  }

  /// Supprimer des tags
  static Future<void> removeTags(List<String> keys) async {
    try {
      await OneSignal.User.removeTags(keys);
      debugPrint('✅ OneSignal tags removed: $keys');
    } catch (e) {
      debugPrint('❌ OneSignal removeTags error: $e');
    }
  }

  /// Obtenir l'ID du joueur OneSignal (pour debug)
  static Future<String?> getPlayerId() async {
    try {
      final subscription = OneSignal.User.pushSubscription;
      return subscription.id;
    } catch (e) {
      debugPrint('❌ OneSignal getPlayerId error: $e');
      return null;
    }
  }

  /// Vérifier si les notifications sont activées
  static Future<bool> areNotificationsEnabled() async {
    try {
      final subscription = OneSignal.User.pushSubscription;
      return subscription.optedIn ?? false;
    } catch (e) {
      debugPrint('❌ OneSignal areNotificationsEnabled error: $e');
      return false;
    }
  }

  /// Afficher une notification in-app (quand l'app est ouverte)
  static void _showInAppNotification(OSNotification notification) {
    final context = navigatorKey?.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.title ?? 'Notification',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (notification.body != null)
                Text(notification.body!),
            ],
          ),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Voir',
            onPressed: () {
              final data = notification.additionalData;
              if (data != null) {
                _handleNotificationClick(data);
              }
            },
          ),
        ),
      );
    }
  }

  /// Gérer le clic sur une notification
  static void _handleNotificationClick(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final orderId = data['order_id'] as String?;

    debugPrint('📱 Notification click - type: $type, orderId: $orderId');

    final context = navigatorKey?.currentContext;
    if (context == null) {
      debugPrint('❌ Navigation context not available');
      return;
    }

    // Naviguer vers l'écran approprié selon le type
    switch (type) {
      // === RESTAURANT ===
      case 'new_order':
        // Restaurant: Nouvelle commande à préparer
        debugPrint('🍽️ Navigating to restaurant kitchen');
        Navigator.pushNamed(context, '/restaurant/kitchen');
        break;
      case 'order_delivered_confirm':
        // Restaurant: Confirmation livraison
        debugPrint('✅ Navigating to restaurant orders');
        Navigator.pushNamed(context, '/restaurant/orders');
        break;

      // === CLIENT ===
      case 'order_confirmed':
      case 'order_ready':
      case 'driver_assigned':
      case 'order_picked_up':
      case 'order_delivered':
        // Client: Naviguer vers le suivi de commande
        debugPrint('👤 Navigating to order tracking: $orderId');
        if (orderId != null) {
          Navigator.pushNamed(context, '/customer/order-tracking', arguments: orderId);
        } else {
          Navigator.pushNamed(context, '/customer/orders');
        }
        break;

      // === LIVREUR ===
      case 'new_delivery':
      case 'new_delivery_available':
        // Livreur: Nouvelle livraison disponible
        debugPrint('🚚 Navigating to livreur home for new delivery');
        Navigator.pushNamed(context, '/livreur/home');
        break;
      case 'order_ready_pickup':
        // Livreur: Commande prête à récupérer
        debugPrint('📦 Navigating to delivery: $orderId');
        if (orderId != null) {
          Navigator.pushNamed(context, '/livreur/delivery', arguments: orderId);
        } else {
          Navigator.pushNamed(context, '/livreur/home');
        }
        break;

      default:
        debugPrint('⚠️ Type de notification non géré: $type');
        // Navigation par défaut vers l'accueil
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  /// Test: Envoyer une notification de test (debug uniquement)
  static Future<void> sendTestNotification() async {
    if (!kDebugMode) return;
    
    try {
      final playerId = await getPlayerId();
      final isEnabled = await areNotificationsEnabled();
      
      debugPrint('🧪 Test notification:');
      debugPrint('  - Player ID: $playerId');
      debugPrint('  - Notifications enabled: $isEnabled');
      debugPrint('  - App ID: $appId');
      
      if (!isEnabled) {
        debugPrint('❌ Notifications désactivées - demander permission');
        await OneSignal.Notifications.requestPermission(true);
        return;
      }
      
      // Simuler une notification locale
      _showInAppNotification(
        OSNotification({
          'notificationId': 'test-${DateTime.now().millisecondsSinceEpoch}',
          'title': '🧪 Test Notification',
          'body': 'Ceci est un test de notification OneSignal - ${DateTime.now().toString().substring(11, 19)}',
          'additionalData': {
            'type': 'test',
            'order_id': 'test-order-123',
            'timestamp': DateTime.now().toIso8601String(),
          },
        }),
      );
      
      debugPrint('✅ Test notification affichée');
    } catch (e) {
      debugPrint('❌ Test notification error: $e');
    }
  }

  /// Vérifier la configuration OneSignal
  static Future<Map<String, dynamic>> getDebugInfo() async {
    try {
      final playerId = await getPlayerId();
      final isEnabled = await areNotificationsEnabled();
      final subscription = OneSignal.User.pushSubscription;
      
      return {
        'app_id': appId,
        'player_id': playerId,
        'notifications_enabled': isEnabled,
        'opted_in': subscription.optedIn,
        'subscription_id': subscription.id,
        'token': subscription.token,
      };
    } catch (e) {
      return {
        'error': e.toString(),
      };
    }
  }
}
