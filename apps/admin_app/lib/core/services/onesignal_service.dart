import 'package:flutter/foundation.dart';
// import 'package:onesignal_flutter/onesignal_flutter.dart';

/// Service OneSignal pour les notifications push (GRATUIT)
/// 
/// ⚠️ IMPORTANT: Décommenter les imports et le code après avoir ajouté
/// onesignal_flutter: ^5.1.0 dans pubspec.yaml
class OneSignalService {
  // ⚠️ REMPLACER par ton App ID OneSignal
  static const String appId = 'TON_ONESIGNAL_APP_ID';

  /// Initialiser OneSignal
  static Future<void> initialize() async {
    // OneSignal.Debug.setLogLevel(OSLogLevel.verbose); // Désactiver en prod
    // OneSignal.initialize(appId);
    // OneSignal.Notifications.requestPermission(true);
    
    debugPrint('🔔 OneSignal initialized (placeholder)');
  }

  /// Lier l'utilisateur Supabase à OneSignal
  /// Appeler après connexion réussie
  static Future<void> login(String userId, {String? role}) async {
    // OneSignal.login(userId);
    
    // Ajouter des tags pour filtrer les notifications
    // if (role != null) {
    //   OneSignal.User.addTags({
    //     'role': role,
    //     'user_id': userId,
    //   });
    // }
    
    debugPrint('🔔 OneSignal login: $userId (role: $role)');
  }

  /// Déconnecter l'utilisateur de OneSignal
  /// Appeler lors de la déconnexion
  static Future<void> logout() async {
    // OneSignal.logout();
    debugPrint('🔔 OneSignal logout');
  }

  /// Ajouter des tags personnalisés
  static Future<void> addTags(Map<String, String> tags) async {
    // OneSignal.User.addTags(tags);
    debugPrint('🔔 OneSignal tags: $tags');
  }

  /// Supprimer des tags
  static Future<void> removeTags(List<String> keys) async {
    // OneSignal.User.removeTags(keys);
    debugPrint('🔔 OneSignal remove tags: $keys');
  }
}
