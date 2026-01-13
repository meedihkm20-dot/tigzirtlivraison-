import 'package:flutter_tts/flutter_tts.dart';
import 'package:latlong2/latlong.dart';
import 'routing_service.dart';
import 'location_service.dart';

class VoiceNavigationService {
  static final FlutterTts _tts = FlutterTts();
  static bool _isInitialized = false;
  static int _lastSpokenStepIndex = -1;
  static bool _hasAnnouncedArrival = false;

  static Future<void> init() async {
    if (_isInitialized) return;
    
    await _tts.setLanguage('fr-FR');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    
    _isInitialized = true;
  }

  static Future<void> speak(String text) async {
    if (!_isInitialized) await init();
    await _tts.speak(text);
  }

  static Future<void> stop() async {
    await _tts.stop();
  }

  static void reset() {
    _lastSpokenStepIndex = -1;
    _hasAnnouncedArrival = false;
  }

  static Future<void> checkAndAnnounce({
    required LatLng currentPosition,
    required RouteResult route,
    required int currentStepIndex,
  }) async {
    if (route.steps.isEmpty) return;

    final step = route.steps[currentStepIndex];
    
    if (currentStepIndex != _lastSpokenStepIndex) {
      _lastSpokenStepIndex = currentStepIndex;
      
      String message = step.instruction;
      
      if (step.name.isNotEmpty) {
        message += ', ${step.name}';
      }
      
      if (step.distance > 100) {
        message += ', dans ${step.formattedDistance}';
      }
      
      await speak(message);
    }
  }

  static Future<void> announceArrival(String destinationType) async {
    if (_hasAnnouncedArrival) return;
    _hasAnnouncedArrival = true;
    
    if (destinationType == 'restaurant') {
      await speak('Vous êtes arrivé au restaurant. Récupérez la commande.');
    } else {
      await speak('Vous êtes arrivé chez le client. Bonne livraison!');
    }
  }

  static Future<void> announceRerouting() async {
    await speak('Recalcul de l\'itinéraire en cours.');
  }

  static Future<void> announceRemainingDistance(double meters) async {
    final formatted = RoutingService.formatDistance(meters);
    await speak('Plus que $formatted avant destination.');
  }
}

class NavigationTracker {
  final RouteResult route;
  final LatLng destination;
  final void Function() onRerouteNeeded;
  final void Function(int) onStepChanged;
  final void Function() onArrival;
  
  int _currentStepIndex = 0;
  static const double _rerouteThreshold = 50.0;
  static const double _arrivalThreshold = 30.0;

  NavigationTracker({
    required this.route,
    required this.destination,
    required this.onRerouteNeeded,
    required this.onStepChanged,
    required this.onArrival,
  });

  int get currentStepIndex => _currentStepIndex;
  NavigationStep get currentStep => route.steps[_currentStepIndex];

  void updatePosition(LatLng position) {
    final distanceToDestination = LocationService.calculateDistance(position, destination);
    if (distanceToDestination < _arrivalThreshold) {
      onArrival();
      return;
    }

    final distanceToRoute = _calculateDistanceToRoute(position);
    if (distanceToRoute > _rerouteThreshold) {
      onRerouteNeeded();
      return;
    }

    _checkStepProgress(position);
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

  void _checkStepProgress(LatLng position) {
    if (_currentStepIndex >= route.steps.length - 1) return;

    final nextStepIndex = _currentStepIndex + 1;
    
    int pointIndex = 0;
    for (int i = 0; i <= _currentStepIndex && i < route.steps.length; i++) {
      pointIndex += (route.points.length / route.steps.length).round();
    }
    
    if (pointIndex < route.points.length) {
      final nextStepPoint = route.points[pointIndex.clamp(0, route.points.length - 1)];
      final distanceToNextStep = LocationService.calculateDistance(position, nextStepPoint);
      
      if (distanceToNextStep < 30) {
        _currentStepIndex = nextStepIndex;
        onStepChanged(_currentStepIndex);
      }
    }
  }
}
