import 'package:latlong2/latlong.dart';
import 'supabase_service.dart';
import 'routing_service.dart';

/// Service de calcul dynamique des prix de livraison
class DeliveryPricingService {
  // Configuration par défaut
  static const double _baseFee = 100; // DA
  static const double _perKmFee = 30; // DA par km
  static const double _minFee = 100;
  static const double _maxFee = 500;
  
  /// Calculer le prix de livraison basé sur la distance réelle (route)
  static Future<DeliveryPrice> calculatePrice({
    required LatLng restaurantLocation,
    required LatLng customerLocation,
  }) async {
    // Calculer la distance via OSRM (route réelle)
    final route = await RoutingService.getRoute(restaurantLocation, customerLocation);
    
    double distanceKm;
    int estimatedMinutes;
    
    if (route != null) {
      distanceKm = route.distanceMeters / 1000;
      estimatedMinutes = (route.durationSeconds / 60).ceil();
    } else {
      // Fallback: distance à vol d'oiseau
      distanceKm = _calculateHaversineDistance(restaurantLocation, customerLocation);
      estimatedMinutes = (distanceKm * 3 + 10).ceil(); // 3 min/km + 10 min préparation
    }
    
    // Calculer le prix
    double baseFee = _baseFee;
    double distanceFee = distanceKm * _perKmFee;
    double totalFee = baseFee + distanceFee;
    
    // Appliquer min/max
    totalFee = totalFee.clamp(_minFee, _maxFee);
    
    // Arrondir à 10 DA près
    totalFee = (totalFee / 10).round() * 10;
    
    return DeliveryPrice(
      distanceKm: distanceKm,
      baseFee: baseFee,
      distanceFee: distanceFee,
      totalFee: totalFee,
      estimatedMinutes: estimatedMinutes,
    );
  }

  /// Calculer via la fonction Supabase (plus précis avec zones)
  static Future<DeliveryPrice> calculatePriceFromDB({
    required double restaurantLat,
    required double restaurantLng,
    required double customerLat,
    required double customerLng,
  }) async {
    try {
      final result = await SupabaseService.client.rpc('calculate_delivery_fee', params: {
        'p_restaurant_lat': restaurantLat,
        'p_restaurant_lng': restaurantLng,
        'p_customer_lat': customerLat,
        'p_customer_lng': customerLng,
      });
      
      if (result is List && result.isNotEmpty) {
        final data = result.first;
        return DeliveryPrice(
          distanceKm: (data['distance_km'] as num).toDouble(),
          baseFee: (data['base_fee'] as num).toDouble(),
          distanceFee: (data['distance_fee'] as num).toDouble(),
          totalFee: (data['total_fee'] as num).toDouble(),
          estimatedMinutes: data['estimated_time'] as int,
        );
      }
    } catch (e) {
      // Fallback au calcul local
    }
    
    // Calcul local si erreur DB
    return calculatePrice(
      restaurantLocation: LatLng(restaurantLat, restaurantLng),
      customerLocation: LatLng(customerLat, customerLng),
    );
  }

  /// Distance Haversine (vol d'oiseau)
  static double _calculateHaversineDistance(LatLng from, LatLng to) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, from, to);
  }

  /// Obtenir une estimation rapide (sans appel API)
  static DeliveryPrice quickEstimate(double distanceKm) {
    double totalFee = _baseFee + (distanceKm * _perKmFee);
    totalFee = totalFee.clamp(_minFee, _maxFee);
    totalFee = (totalFee / 10).round() * 10;
    
    return DeliveryPrice(
      distanceKm: distanceKm,
      baseFee: _baseFee,
      distanceFee: distanceKm * _perKmFee,
      totalFee: totalFee,
      estimatedMinutes: (distanceKm * 3 + 15).ceil(),
    );
  }

  /// Calculer la commission livreur selon son tier
  static Future<double> calculateLivreurCommission(String livreurId, double deliveryFee) async {
    try {
      final result = await SupabaseService.client.rpc('calculate_livreur_commission', params: {
        'p_livreur_id': livreurId,
        'p_delivery_fee': deliveryFee,
      });
      return (result as num?)?.toDouble() ?? deliveryFee * 0.10;
    } catch (e) {
      // Fallback: 10% par défaut
      return deliveryFee * 0.10;
    }
  }
}

/// Modèle de prix de livraison
class DeliveryPrice {
  final double distanceKm;
  final double baseFee;
  final double distanceFee;
  final double totalFee;
  final int estimatedMinutes;

  DeliveryPrice({
    required this.distanceKm,
    required this.baseFee,
    required this.distanceFee,
    required this.totalFee,
    required this.estimatedMinutes,
  });

  String get formattedDistance => '${distanceKm.toStringAsFixed(1)} km';
  String get formattedFee => '${totalFee.toStringAsFixed(0)} DA';
  String get formattedTime => '$estimatedMinutes min';
  
  @override
  String toString() => 'DeliveryPrice($formattedDistance, $formattedFee, $formattedTime)';
}
