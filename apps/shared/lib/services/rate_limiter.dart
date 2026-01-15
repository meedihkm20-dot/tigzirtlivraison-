import 'dart:async';

/// Limiteur de requêtes pour éviter de surcharger le serveur
class RateLimiter {
  static final Map<String, DateTime> _lastCalls = {};
  static final Map<String, Completer<void>> _pendingCalls = {};
  
  /// Exécuter une fonction avec limite de fréquence
  /// [key] identifiant unique de l'action
  /// [minInterval] intervalle minimum entre deux appels
  /// [action] fonction à exécuter
  static Future<T> throttle<T>({
    required String key,
    required Duration minInterval,
    required Future<T> Function() action,
  }) async {
    final now = DateTime.now();
    final lastCall = _lastCalls[key];
    
    if (lastCall != null) {
      final elapsed = now.difference(lastCall);
      if (elapsed < minInterval) {
        // Attendre le temps restant
        await Future.delayed(minInterval - elapsed);
      }
    }
    
    _lastCalls[key] = DateTime.now();
    return await action();
  }
  
  /// Debounce: exécuter seulement après un délai sans nouvel appel
  /// Utile pour la recherche
  static Future<T?> debounce<T>({
    required String key,
    required Duration delay,
    required Future<T> Function() action,
  }) async {
    // Annuler l'appel précédent s'il existe
    _pendingCalls[key]?.complete();
    
    final completer = Completer<void>();
    _pendingCalls[key] = completer;
    
    try {
      await Future.delayed(delay);
      
      // Vérifier si on n'a pas été annulé
      if (completer.isCompleted) return null;
      
      return await action();
    } finally {
      _pendingCalls.remove(key);
    }
  }
  
  /// Réinitialiser le limiteur (utile pour les tests)
  static void reset() {
    _lastCalls.clear();
    _pendingCalls.clear();
  }
}

/// Extension pour faciliter l'utilisation
extension RateLimitedFuture<T> on Future<T> Function() {
  Future<T> throttled(String key, {Duration interval = const Duration(seconds: 2)}) {
    return RateLimiter.throttle(key: key, minInterval: interval, action: this);
  }
}
