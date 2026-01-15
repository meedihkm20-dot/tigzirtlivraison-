import 'package:location/location.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;

/// Service de localisation 100% gratuit
/// Utilise le GPS natif du téléphone via le package 'location'
class LocationService {
  static final Location _location = Location();
  static bool _initialized = false;

  /// Vérifie et demande les permissions GPS
  static Future<bool> checkPermission() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return false;
    }

    PermissionStatus permission = await _location.hasPermission();
    if (permission == PermissionStatus.denied) {
      permission = await _location.requestPermission();
      if (permission != PermissionStatus.granted) return false;
    }
    
    _initialized = true;
    return true;
  }

  /// Récupère la position actuelle
  static Future<LatLng?> getCurrentLocation() async {
    try {
      if (!_initialized && !await checkPermission()) return null;
      
      final locationData = await _location.getLocation();
      if (locationData.latitude != null && locationData.longitude != null) {
        return LatLng(locationData.latitude!, locationData.longitude!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Stream de position en temps réel (optimisé batterie)
  /// Mise à jour tous les 5 secondes OU 20 mètres de déplacement
  static Stream<LocationData> getLocationStream({bool highAccuracy = false}) {
    _location.changeSettings(
      accuracy: highAccuracy ? LocationAccuracy.high : LocationAccuracy.balanced,
      interval: 5000, // 5 secondes (au lieu de 1)
      distanceFilter: 20, // 20 mètres (au lieu de 10)
    );
    return _location.onLocationChanged;
  }

  /// Mode économie de batterie (pour quand le livreur attend)
  static void setLowPowerMode() {
    _location.changeSettings(
      accuracy: LocationAccuracy.low,
      interval: 30000, // 30 secondes
      distanceFilter: 100, // 100 mètres
    );
  }

  /// Mode haute précision (pour la navigation active)
  static void setHighAccuracyMode() {
    _location.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 3000, // 3 secondes
      distanceFilter: 10, // 10 mètres
    );
  }

  /// Active le mode background pour le suivi continu
  static Future<void> enableBackgroundMode() async {
    await _location.enableBackgroundMode(enable: true);
  }

  /// Calcule la distance entre 2 points (formule Haversine)
  static double calculateDistance(LatLng from, LatLng to) {
    const double earthRadius = 6371000; // mètres
    final double lat1 = from.latitude * math.pi / 180;
    final double lat2 = to.latitude * math.pi / 180;
    final double dLat = (to.latitude - from.latitude) * math.pi / 180;
    final double dLon = (to.longitude - from.longitude) * math.pi / 180;

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(dLon / 2) * math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  /// Formate la distance en texte lisible
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}
