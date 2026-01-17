import 'package:flutter_tts/flutter_tts.dart';
import 'package:latlong2/latlong.dart';
import 'routing_service.dart';
import 'location_service.dart';

/// Service de navigation vocale amélioré pour les livreurs
/// Fournit des instructions vocales contextuelles et intelligentes
class VoiceNavigationService {
  static final FlutterTts _tts = FlutterTts();
  static bool _isInitialized = false;
  static bool _isEnabled = true;
  static int _lastSpokenStepIndex = -1;
  static bool _hasAnnouncedArrival = false;
  static DateTime? _lastAnnouncementTime;
  static String _currentLanguage = 'fr-FR';

  static Future<void> init() async {
    if (_isInitialized) return;
    
    await _tts.setLanguage(_currentLanguage);
    await _tts.setSpeechRate(0.6);
    await _tts.setVolume(0.8);
    await _tts.setPitch(1.0);
    
    _isInitialized = true;
  }

  static Future<void> speak(String text) async {
    if (!_isInitialized) await init();
    if (!_isEnabled) return;
    
    // Éviter les annonces trop fréquentes
    final now = DateTime.now();
    if (_lastAnnouncementTime != null && 
        now.difference(_lastAnnouncementTime!).inSeconds < 3) {
      return;
    }
    
    _lastAnnouncementTime = now;
    await _tts.speak(text);
  }

  static Future<void> stop() async {
    await _tts.stop();
  }

  static void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  static bool get isEnabled => _isEnabled;

  static void reset() {
    _lastSpokenStepIndex = -1;
    _hasAnnouncedArrival = false;
    _lastAnnouncementTime = null;
  }

  // Instructions contextuelles améliorées
  static Future<void> checkAndAnnounce({
    required LatLng currentPosition,
    required RouteResult route,
    required int currentStepIndex,
    String? destinationType,
  }) async {
    if (route.steps.isEmpty || !_isEnabled) return;

    final step = route.steps[currentStepIndex];
    
    if (currentStepIndex != _lastSpokenStepIndex) {
      _lastSpokenStepIndex = currentStepIndex;
      
      String message = _buildContextualInstruction(step, destinationType);
      await speak(message);
    }
  }

  static String _buildContextualInstruction(NavigationStep step, String? destinationType) {
    String instruction = step.instruction;
    
    // Améliorer les instructions selon le contexte
    if (step.maneuver.contains('turn')) {
      if (step.distance > 200) {
        instruction = 'Dans ${step.formattedDistance}, $instruction';
      } else if (step.distance > 50) {
        instruction = 'Préparez-vous à ${instruction.toLowerCase()}';
      }
    }
    
    // Ajouter le nom de la rue si disponible
    if (step.name.isNotEmpty && !instruction.contains(step.name)) {
      instruction += ' sur ${step.name}';
    }
    
    // Instructions spécifiques selon la destination
    if (destinationType == 'restaurant' && step.distance < 100) {
      instruction += '. Recherchez l\'entrée du restaurant';
    } else if (destinationType == 'customer' && step.distance < 100) {
      instruction += '. Préparez-vous pour la livraison';
    }
    
    return instruction;
  }

  // Annonces d'arrivée contextuelles
  static Future<void> announceArrival(String destinationType, {String? locationName}) async {
    if (_hasAnnouncedArrival) return;
    _hasAnnouncedArrival = true;
    
    String message;
    if (destinationType == 'restaurant') {
      message = locationName != null 
          ? 'Vous êtes arrivé chez $locationName. Récupérez la commande.'
          : 'Vous êtes arrivé au restaurant. Récupérez la commande.';
    } else {
      message = 'Vous êtes arrivé chez le client. Préparez la livraison.';
    }
    
    await speak(message);
  }

  // Annonces de statut de livraison
  static Future<void> announceDeliveryStatus(String status) async {
    String message;
    switch (status) {
      case 'picked_up':
        message = 'Commande récupérée. Direction le client.';
        break;
      case 'delivered':
        message = 'Livraison terminée avec succès. Bravo!';
        break;
      case 'problem':
        message = 'Problème signalé. Contactez le support si nécessaire.';
        break;
      default:
        return;
    }
    await speak(message);
  }

  // Alertes de circulation et timing
  static Future<void> announceTrafficAlert(String alertType, {int? delayMinutes}) async {
    String message;
    switch (alertType) {
      case 'heavy_traffic':
        message = delayMinutes != null 
            ? 'Trafic dense détecté. Retard estimé: $delayMinutes minutes.'
            : 'Trafic dense sur votre itinéraire.';
        break;
      case 'road_closure':
        message = 'Route fermée détectée. Recalcul de l\'itinéraire.';
        break;
      case 'accident':
        message = 'Accident signalé sur votre route. Itinéraire alternatif proposé.';
        break;
      default:
        return;
    }
    await speak(message);
  }

  // Annonces de timing pour les livreurs
  static Future<void> announceTimingAlert(String alertType, int minutes) async {
    String message;
    switch (alertType) {
      case 'pickup_delay':
        message = 'Attention: vous êtes en retard de $minutes minutes pour la récupération.';
        break;
      case 'delivery_urgent':
        message = 'Livraison urgente: plus que $minutes minutes avant l\'heure limite.';
        break;
      case 'eta_update':
        message = 'Temps d\'arrivée estimé: $minutes minutes.';
        break;
      default:
        return;
    }
    await speak(message);
  }

  static Future<void> announceRerouting({String? reason}) async {
    String message = 'Recalcul de l\'itinéraire';
    if (reason != null) {
      message += ' - $reason';
    }
    message += '.';
    await speak(message);
  }

  static Future<void> announceRemainingDistance(double meters, {String? destinationType}) async {
    final formatted = RoutingService.formatDistance(meters);
    String message = 'Plus que $formatted';
    
    if (destinationType == 'restaurant') {
      message += ' avant le restaurant';
    } else if (destinationType == 'customer') {
      message += ' avant le client';
    } else {
      message += ' avant destination';
    }
    
    await speak(message);
  }

  // Annonces de sécurité
  static Future<void> announceSpeedAlert() async {
    await speak('Attention à votre vitesse. Conduisez prudemment.');
  }

  static Future<void> announceWeatherAlert(String weatherType) async {
    String message;
    switch (weatherType) {
      case 'rain':
        message = 'Pluie détectée. Conduisez prudemment et protégez les commandes.';
        break;
      case 'fog':
        message = 'Brouillard signalé. Réduisez votre vitesse.';
        break;
      case 'wind':
        message = 'Vent fort. Attention aux deux-roues.';
        break;
      default:
        message = 'Conditions météo difficiles. Soyez prudent.';
    }
    await speak(message);
  }

  // Gestion des préférences vocales
  static Future<void> setVoiceSettings({
    double? speechRate,
    double? volume,
    double? pitch,
    String? language,
  }) async {
    if (speechRate != null) await _tts.setSpeechRate(speechRate);
    if (volume != null) await _tts.setVolume(volume);
    if (pitch != null) await _tts.setPitch(pitch);
    if (language != null) {
      _currentLanguage = language;
      await _tts.setLanguage(language);
    }
  }
}

/// Tracker de navigation intelligent avec détection avancée
class NavigationTracker {
  final RouteResult route;
  final LatLng destination;
  final String destinationType;
  final void Function() onRerouteNeeded;
  final void Function(int) onStepChanged;
  final void Function() onArrival;
  final void Function(String, int)? onTimingAlert;
  final void Function(String)? onTrafficAlert;
  
  int _currentStepIndex = 0;
  DateTime? _startTime;
  DateTime? _lastPositionUpdate;
  double _totalDistance = 0;
  List<LatLng> _traveledPath = [];
  
  // Seuils configurables
  static const double _rerouteThreshold = 50.0;
  static const double _arrivalThreshold = 30.0;
  static const double _stepProgressThreshold = 25.0;
  static const int _stuckDetectionSeconds = 120;
  static const double _minimumSpeedKmh = 5.0;

  NavigationTracker({
    required this.route,
    required this.destination,
    required this.destinationType,
    required this.onRerouteNeeded,
    required this.onStepChanged,
    required this.onArrival,
    this.onTimingAlert,
    this.onTrafficAlert,
  }) {
    _startTime = DateTime.now();
  }

  int get currentStepIndex => _currentStepIndex;
  NavigationStep get currentStep => route.steps.isNotEmpty ? route.steps[_currentStepIndex] : NavigationStep.empty();
  double get totalDistance => _totalDistance;
  Duration get elapsedTime => DateTime.now().difference(_startTime ?? DateTime.now());
  List<LatLng> get traveledPath => List.unmodifiable(_traveledPath);

  void updatePosition(LatLng position) {
    _recordPosition(position);
    
    final distanceToDestination = LocationService.calculateDistance(position, destination);
    
    // Vérifier l'arrivée
    if (distanceToDestination < _arrivalThreshold) {
      onArrival();
      return;
    }

    // Vérifier si on s'écarte de la route
    final distanceToRoute = _calculateDistanceToRoute(position);
    if (distanceToRoute > _rerouteThreshold) {
      onRerouteNeeded();
      return;
    }

    // Détecter les problèmes de circulation
    _detectTrafficIssues(position);
    
    // Vérifier la progression des étapes
    _checkStepProgress(position);
    
    // Alertes de timing
    _checkTimingAlerts(distanceToDestination);
  }

  void _recordPosition(LatLng position) {
    final now = DateTime.now();
    
    if (_traveledPath.isNotEmpty) {
      final lastPosition = _traveledPath.last;
      final distance = LocationService.calculateDistance(lastPosition, position);
      _totalDistance += distance;
    }
    
    _traveledPath.add(position);
    _lastPositionUpdate = now;
    
    // Limiter l'historique pour éviter la surcharge mémoire
    if (_traveledPath.length > 1000) {
      _traveledPath.removeRange(0, 500);
    }
  }

  double _calculateDistanceToRoute(LatLng position) {
    if (route.points.isEmpty) return 0;
    
    double minDistance = double.infinity;
    for (final point in route.points) {
      final distance = LocationService.calculateDistance(position, point);
      if (distance < minDistance) {
        minDistance = distance;
      }
    }
    return minDistance;
  }

  void _detectTrafficIssues(LatLng position) {
    if (_traveledPath.length < 3) return;
    
    final now = DateTime.now();
    final recentPositions = _traveledPath.where((pos) {
      final index = _traveledPath.indexOf(pos);
      return index >= _traveledPath.length - 10; // 10 dernières positions
    }).toList();
    
    if (recentPositions.length >= 3) {
      final recentDistance = _calculatePathDistance(recentPositions);
      final timeSpan = Duration(seconds: recentPositions.length * 5); // Estimation
      final speedKmh = (recentDistance / 1000) / (timeSpan.inSeconds / 3600);
      
      if (speedKmh < _minimumSpeedKmh) {
        onTrafficAlert?.call('heavy_traffic');
      }
    }
    
    // Détection de blocage (position stationnaire)
    if (_lastPositionUpdate != null) {
      final timeSinceLastMove = now.difference(_lastPositionUpdate!);
      if (timeSinceLastMove.inSeconds > _stuckDetectionSeconds) {
        onTrafficAlert?.call('stuck');
      }
    }
  }

  double _calculatePathDistance(List<LatLng> path) {
    double distance = 0;
    for (int i = 1; i < path.length; i++) {
      distance += LocationService.calculateDistance(path[i-1], path[i]);
    }
    return distance;
  }

  void _checkStepProgress(LatLng position) {
    if (_currentStepIndex >= route.steps.length - 1) return;

    final currentStep = route.steps[_currentStepIndex];
    final nextStep = route.steps[_currentStepIndex + 1];
    
    // Calculer la position approximative de la prochaine étape
    final stepProgress = _calculateStepProgress(position, currentStep);
    
    if (stepProgress > 0.8) { // 80% de progression vers l'étape suivante
      _currentStepIndex++;
      onStepChanged(_currentStepIndex);
    }
  }

  double _calculateStepProgress(LatLng position, NavigationStep step) {
    // Logique simplifiée - dans un vrai cas, on utiliserait les points de route
    final stepStartIndex = _currentStepIndex * (route.points.length ~/ route.steps.length);
    final stepEndIndex = (_currentStepIndex + 1) * (route.points.length ~/ route.steps.length);
    
    if (stepStartIndex >= route.points.length || stepEndIndex >= route.points.length) {
      return 0;
    }
    
    final stepStart = route.points[stepStartIndex.clamp(0, route.points.length - 1)];
    final stepEnd = route.points[stepEndIndex.clamp(0, route.points.length - 1)];
    
    final totalStepDistance = LocationService.calculateDistance(stepStart, stepEnd);
    final remainingDistance = LocationService.calculateDistance(position, stepEnd);
    
    return totalStepDistance > 0 ? (1 - (remainingDistance / totalStepDistance)).clamp(0, 1) : 0;
  }

  void _checkTimingAlerts(double distanceToDestination) {
    if (onTimingAlert == null) return;
    
    final elapsed = elapsedTime;
    final estimatedTotalTime = _estimateRemainingTime(distanceToDestination);
    
    // Alertes selon le type de destination et le timing
    if (destinationType == 'restaurant') {
      // Alerte si on prend trop de temps pour arriver au restaurant
      if (elapsed.inMinutes > 20) {
        onTimingAlert!('pickup_delay', elapsed.inMinutes - 15);
      }
    } else if (destinationType == 'customer') {
      // Alerte si la livraison risque d'être en retard
      if (estimatedTotalTime.inMinutes > 30) {
        onTimingAlert!('delivery_urgent', estimatedTotalTime.inMinutes);
      }
    }
  }

  Duration _estimateRemainingTime(double remainingDistance) {
    // Estimation basée sur la vitesse moyenne et la distance restante
    const averageSpeedKmh = 25.0; // Vitesse moyenne en ville
    final remainingTimeHours = (remainingDistance / 1000) / averageSpeedKmh;
    return Duration(minutes: (remainingTimeHours * 60).round());
  }

  // Méthodes utilitaires pour les statistiques
  Map<String, dynamic> getNavigationStats() {
    return {
      'total_distance': _totalDistance,
      'elapsed_time': elapsedTime.inMinutes,
      'average_speed': _calculateAverageSpeed(),
      'current_step': _currentStepIndex + 1,
      'total_steps': route.steps.length,
      'progress_percentage': (_currentStepIndex / route.steps.length * 100).round(),
    };
  }

  double _calculateAverageSpeed() {
    if (elapsedTime.inSeconds == 0) return 0;
    return (_totalDistance / 1000) / (elapsedTime.inSeconds / 3600); // km/h
  }

  void reset() {
    _currentStepIndex = 0;
    _startTime = DateTime.now();
    _totalDistance = 0;
    _traveledPath.clear();
    _lastPositionUpdate = null;
  }
}
