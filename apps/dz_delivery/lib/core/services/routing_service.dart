import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

class RoutingService {
  static final Dio _dio = Dio();
  static const String _osrmBaseUrl = 'https://router.project-osrm.org/route/v1/driving';

  /// Calcule l'itinéraire entre deux points via OSRM (gratuit)
  static Future<RouteResult?> getRoute(LatLng origin, LatLng destination) async {
    try {
      final url = '$_osrmBaseUrl/${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}';
      
      final response = await _dio.get(url, queryParameters: {
        'overview': 'full',
        'geometries': 'geojson',
        'steps': 'true',
        'annotations': 'true',
      });

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 'Ok' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          
          final coordinates = route['geometry']['coordinates'] as List;
          final routePoints = coordinates
              .map<LatLng>((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()))
              .toList();

          final legs = route['legs'] as List;
          final steps = <NavigationStep>[];
          
          for (final leg in legs) {
            for (final step in leg['steps']) {
              steps.add(NavigationStep(
                instruction: _translateManeuver(step['maneuver']),
                distance: (step['distance'] as num).toDouble(),
                duration: (step['duration'] as num).toDouble(),
                name: step['name'] ?? '',
              ));
            }
          }

          return RouteResult(
            points: routePoints,
            distanceMeters: (route['distance'] as num).toDouble(),
            durationSeconds: (route['duration'] as num).toDouble(),
            steps: steps,
          );
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static String _translateManeuver(Map<String, dynamic> maneuver) {
    final type = maneuver['type'] ?? '';
    final modifier = maneuver['modifier'] ?? '';

    switch (type) {
      case 'depart':
        return 'Démarrer';
      case 'arrive':
        return 'Vous êtes arrivé';
      case 'turn':
        switch (modifier) {
          case 'left':
            return 'Tournez à gauche';
          case 'right':
            return 'Tournez à droite';
          case 'slight left':
            return 'Légèrement à gauche';
          case 'slight right':
            return 'Légèrement à droite';
          case 'sharp left':
            return 'Tournez fortement à gauche';
          case 'sharp right':
            return 'Tournez fortement à droite';
          case 'uturn':
            return 'Faites demi-tour';
          default:
            return 'Continuez';
        }
      case 'continue':
        return 'Continuez tout droit';
      case 'merge':
        return 'Rejoignez la voie';
      case 'roundabout':
        return 'Prenez le rond-point';
      case 'exit roundabout':
        return 'Sortez du rond-point';
      case 'fork':
        return modifier == 'left' ? 'Prenez à gauche' : 'Prenez à droite';
      default:
        return 'Continuez';
    }
  }

  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  static String formatDuration(double seconds) {
    final minutes = (seconds / 60).round();
    if (minutes < 60) {
      return '$minutes min';
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}h ${remainingMinutes}min';
  }
}

class RouteResult {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
  final List<NavigationStep> steps;

  RouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.steps,
  });

  String get formattedDistance => RoutingService.formatDistance(distanceMeters);
  String get formattedDuration => RoutingService.formatDuration(durationSeconds);
}

class NavigationStep {
  final String instruction;
  final double distance;
  final double duration;
  final String name;

  NavigationStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.name,
  });

  String get formattedDistance => RoutingService.formatDistance(distance);
}
