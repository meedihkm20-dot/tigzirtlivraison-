import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'supabase_service.dart';

/// Service de gestion des préférences utilisateur
/// Mode sombre, notifications, sons, etc.
class PreferencesService {
  static const String _boxName = 'preferences';
  static Box? _box;

  // Keys
  static const String _darkModeKey = 'dark_mode';
  static const String _notificationsKey = 'notifications_enabled';
  static const String _soundKey = 'sound_enabled';
  static const String _hapticKey = 'haptic_enabled';
  static const String _languageKey = 'language';

  /// Initialiser le service
  static Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  /// Mode sombre
  static bool get isDarkMode => _box?.get(_darkModeKey, defaultValue: false) ?? false;
  
  static Future<void> setDarkMode(bool value) async {
    await _box?.put(_darkModeKey, value);
    await _syncToServer();
  }

  /// Notifications
  static bool get notificationsEnabled => _box?.get(_notificationsKey, defaultValue: true) ?? true;
  
  static Future<void> setNotificationsEnabled(bool value) async {
    await _box?.put(_notificationsKey, value);
    await _syncToServer();
  }

  /// Sons
  static bool get soundEnabled => _box?.get(_soundKey, defaultValue: true) ?? true;
  
  static Future<void> setSoundEnabled(bool value) async {
    await _box?.put(_soundKey, value);
    await _syncToServer();
  }

  /// Haptic feedback
  static bool get hapticEnabled => _box?.get(_hapticKey, defaultValue: true) ?? true;
  
  static Future<void> setHapticEnabled(bool value) async {
    await _box?.put(_hapticKey, value);
    await _syncToServer();
  }

  /// Langue
  static String get language => _box?.get(_languageKey, defaultValue: 'fr') ?? 'fr';
  
  static Future<void> setLanguage(String value) async {
    await _box?.put(_languageKey, value);
    await _syncToServer();
  }

  /// Obtenir le ThemeMode
  static ThemeMode get themeMode => isDarkMode ? ThemeMode.dark : ThemeMode.light;

  /// Synchroniser avec le serveur
  static Future<void> _syncToServer() async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) return;

      await SupabaseService.client.from('user_preferences').upsert({
        'user_id': userId,
        'dark_mode': isDarkMode,
        'notifications_enabled': notificationsEnabled,
        'sound_enabled': soundEnabled,
        'haptic_enabled': hapticEnabled,
        'language': language,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Erreur sync préférences: $e');
    }
  }

  /// Charger depuis le serveur
  static Future<void> loadFromServer() async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) return;

      final data = await SupabaseService.client
          .from('user_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (data != null) {
        await _box?.put(_darkModeKey, data['dark_mode'] ?? false);
        await _box?.put(_notificationsKey, data['notifications_enabled'] ?? true);
        await _box?.put(_soundKey, data['sound_enabled'] ?? true);
        await _box?.put(_hapticKey, data['haptic_enabled'] ?? true);
        await _box?.put(_languageKey, data['language'] ?? 'fr');
      }
    } catch (e) {
      debugPrint('Erreur chargement préférences: $e');
    }
  }

  /// Réinitialiser les préférences
  static Future<void> reset() async {
    await _box?.clear();
  }
}
