import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service de gestion réseau avec retry et cache offline
/// Utilisable dans toutes les apps (client, restaurant, livreur)
class NetworkService {
  static final Connectivity _connectivity = Connectivity();
  static bool _isOnline = true;
  static StreamSubscription? _subscription;
  static final List<VoidCallback> _listeners = [];
  
  /// Initialiser le service (appeler dans main.dart)
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox('offline_cache');
    await Hive.openBox('pending_actions');
    
    // Écouter les changements de connectivité
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      final wasOffline = !_isOnline;
      _isOnline = result != ConnectivityResult.none;
      
      // Si on revient en ligne, exécuter les actions en attente
      if (wasOffline && _isOnline) {
        _processPendingActions();
      }
      
      // Notifier les listeners
      for (final listener in _listeners) {
        listener();
      }
    });
    
    // Vérifier l'état initial
    final result = await _connectivity.checkConnectivity();
    _isOnline = result != ConnectivityResult.none;
  }
  
  static bool get isOnline => _isOnline;
  
  /// Ajouter un listener pour les changements de connectivité
  static void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }
  
  static void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }
  
  /// Exécuter une requête avec retry automatique
  static Future<T> withRetry<T>({
    required Future<T> Function() request,
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
    Duration timeout = const Duration(seconds: 15),
  }) async {
    int attempts = 0;
    Duration delay = initialDelay;
    
    while (attempts < maxRetries) {
      try {
        return await request().timeout(timeout);
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          rethrow;
        }
        
        debugPrint('Retry $attempts/$maxRetries après erreur: $e');
        await Future.delayed(delay);
        delay *= 2; // Backoff exponentiel
      }
    }
    
    throw Exception('Échec après $maxRetries tentatives');
  }
  
  /// Sauvegarder des données en cache local
  static Future<void> cacheData(String key, dynamic data) async {
    final box = Hive.box('offline_cache');
    await box.put(key, jsonEncode({
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    }));
  }
  
  /// Récupérer des données du cache
  static T? getCachedData<T>(String key, {Duration maxAge = const Duration(hours: 1)}) {
    final box = Hive.box('offline_cache');
    final cached = box.get(key);
    
    if (cached == null) return null;
    
    try {
      final decoded = jsonDecode(cached);
      final timestamp = DateTime.parse(decoded['timestamp']);
      
      // Vérifier si le cache n'est pas trop vieux
      if (DateTime.now().difference(timestamp) > maxAge) {
        return null;
      }
      
      return decoded['data'] as T;
    } catch (e) {
      return null;
    }
  }
  
  /// Ajouter une action à exécuter quand le réseau revient
  static Future<void> addPendingAction({
    required String type,
    required Map<String, dynamic> data,
  }) async {
    final box = Hive.box('pending_actions');
    final actions = List<Map<String, dynamic>>.from(
      (box.get('actions') as List?)?.cast<Map<String, dynamic>>() ?? []
    );
    
    actions.add({
      'type': type,
      'data': data,
      'created_at': DateTime.now().toIso8601String(),
    });
    
    await box.put('actions', actions);
  }
  
  /// Traiter les actions en attente
  static Future<void> _processPendingActions() async {
    final box = Hive.box('pending_actions');
    final actions = List<Map<String, dynamic>>.from(
      (box.get('actions') as List?)?.cast<Map<String, dynamic>>() ?? []
    );
    
    if (actions.isEmpty) return;
    
    debugPrint('Traitement de ${actions.length} actions en attente...');
    
    final failedActions = <Map<String, dynamic>>[];
    
    for (final action in actions) {
      try {
        await _executeAction(action);
      } catch (e) {
        debugPrint('Échec action ${action['type']}: $e');
        failedActions.add(action);
      }
    }
    
    // Garder seulement les actions échouées
    await box.put('actions', failedActions);
  }
  
  static Future<void> _executeAction(Map<String, dynamic> action) async {
    // À implémenter selon les besoins de chaque app
    // Exemple: sync de position GPS, mise à jour de statut, etc.
    debugPrint('Exécution action: ${action['type']}');
  }
  
  static void dispose() {
    _subscription?.cancel();
    _listeners.clear();
  }
}

/// Mixin pour les widgets qui ont besoin de gérer l'état réseau
mixin NetworkAwareMixin<T extends StatefulWidget> on State<T> {
  bool _isOnline = true;
  
  bool get isOnline => _isOnline;
  
  @override
  void initState() {
    super.initState();
    _isOnline = NetworkService.isOnline;
    NetworkService.addListener(_onNetworkChange);
  }
  
  @override
  void dispose() {
    NetworkService.removeListener(_onNetworkChange);
    super.dispose();
  }
  
  void _onNetworkChange() {
    if (mounted) {
      setState(() {
        _isOnline = NetworkService.isOnline;
      });
      onNetworkChanged(_isOnline);
    }
  }
  
  /// À surcharger pour réagir aux changements de réseau
  void onNetworkChanged(bool isOnline) {}
}
