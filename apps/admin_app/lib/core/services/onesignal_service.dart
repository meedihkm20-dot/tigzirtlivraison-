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
      event.preventDefault();
      event.notification.display();
    });

    // Écouter les clics sur les notifications
    OneSignal.Notifications.addClickListener((event) {
      debugPrint('🔔 Notification cliquée: ${event.notification.title}');
    });

    debugPrint('✅ OneSignal initialized');
  }

  /// Lier l'utilisateur Supabase à OneSignal
  static Future<void> login(String userId, {String? role}) async {
    await OneSignal.login(userId);

    if (role != null) {
      await OneSignal.User.addTags({
        'role': role,
        'user_id': userId,
      });
    }

    debugPrint('✅ OneSignal login: $userId (role: $role)');
  }

  /// Déconnecter l'utilisateur de OneSignal
  static Future<void> logout() async {
    await OneSignal.logout();
    debugPrint('✅ OneSignal logout');
  }
}
