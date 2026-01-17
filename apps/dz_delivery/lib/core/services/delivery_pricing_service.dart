import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:dio/dio.dart';
import 'backend_api_service.dart';
import 'supabase_service.dart';

/// Service de calcul de prix de livraison dynamique
/// Intégré avec le backend NestJS pour pricing intelligent
class DeliveryPricingService {
  static final Dio _dio = Dio();
  static const String _baseUrl = 'https://tigzirt-backend.koyeb.app';
  
  // Prix de base et coefficients (fallback)
  static const double _basePriceDA = 200.0; // Prix de base en DA
  static const double _pricePerKmDA = 50.0; // Prix par kilomètre
  static const double _nightSurcharge = 0.3; // +30% la nuit (20h-6h)
  static const double _badWeatherSurcharge = 0.2; // +20% mauvais temps
  static const double _rushHourSurcharge = 0.15; // +15% heures de pointe
  static const double _weekendSurcharge = 0.1; // +10% weekend
  
  // Heures spéciales
  static const int _nightStartHour = 20; // 20h
  static const int _nightEndHour = 6; // 6h
  static const List<int> _rushHours = [12, 13, 19, 20, 21]; // Heures de pointe
  
  /// Calculer le prix de livraison avec backend intelligent
  static Future<DeliveryPrice> calculatePriceAdvanced({
    required LatLng restaurantLocation,
    required LatLng deliveryLocation,
    String? orderId,
    String? livreurId,
    DateTime? orderTime,
    WeatherCondition? weather,
    VehicleType vehicleType = VehicleType.moto,
    bool hasRainGear = false,
    bool isUrgent = false,
  }) async {
    try {
      final distance = _calculateDistance(restaurantLocation, deliveryLocation);
      
      // Appel au backend pour calcul intelligent
      final response = await _dio.post(
        '$_baseUrl/pricing/calculate',
        data: {
          'orderId': orderId,
          'livreurId': livreurId,
          'distance': distance,
          'restaurantLatitude': restaurantLocation.latitude,
          'restaurantLongitude': restaurantLocation.longitude,
          'deliveryLatitude': deliveryLocation.latitude,
          'deliveryLongitude': deliveryLocation.longitude,
          'vehicleType': vehicleType.name.toUpperCase(),
          'hasRainGear': hasRainGear,
          'weatherOverride': weather?.name.toUpperCase(),
        },
        options: Options(
          headers: await _getAuthHeaders(),
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return DeliveryPrice.fromBackend(data, distance);
      } else {
        // Fallback vers calcul local
        return calculatePrice(
          restaurantLocation: restaurantLocation,
          deliveryLocation: deliveryLocation,
          orderTime: orderTime,
          weather: weather ?? WeatherCondition.clear,
          isUrgent: isUrgent,
        );
      }
    } catch (e) {
      print('Erreur calcul pricing backend: $e');
      // Fallback vers calcul local
      return calculatePrice(
        restaurantLocation: restaurantLocation,
        deliveryLocation: deliveryLocation,
        orderTime: orderTime,
        weather: weather ?? WeatherCondition.clear,
        isUrgent: isUrgent,
      );
    }
  }

  /// Obtenir les prédictions de gains pour un livreur
  static Future<EarningsPrediction?> getEarningsPredictions(String livreurId) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/pricing/earnings-prediction/$livreurId',
        options: Options(headers: await _getAuthHeaders()),
      );

      if (response.statusCode == 200) {
        return EarningsPrediction.fromJson(response.data);
      }
    } catch (e) {
      print('Erreur prédictions gains: $e');
    }
    return null;
  }

  /// Obtenir les opportunités temps réel
  static Future<List<PricingOpportunity>> getRealTimeOpportunities() async {
    try {
      final response = await _dio.get(
        '$_baseUrl/pricing/opportunities',
        options: Options(headers: await _getAuthHeaders()),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((item) => PricingOpportunity.fromJson(item)).toList();
      }
    } catch (e) {
      print('Erreur opportunités: $e');
    }
    return [];
  }

  /// Headers d'authentification
  static Future<Map<String, String>> _getAuthHeaders() async {
    final session = SupabaseService.client.auth.currentSession;
    return {
      'Content-Type': 'application/json',
      if (session?.accessToken != null)
        'Authorization': 'Bearer ${session!.accessToken}',
    };
  }
  /// Calculer le prix de livraison (méthode locale de fallback)
  static DeliveryPrice calculatePrice({
    required LatLng restaurantLocation,
    required LatLng deliveryLocation,
    DateTime? orderTime,
    WeatherCondition weather = WeatherCondition.clear,
    bool isUrgent = false,
  }) {
    final now = orderTime ?? DateTime.now();
    final distance = _calculateDistance(restaurantLocation, deliveryLocation);
    
    // Prix de base + distance
    double basePrice = _basePriceDA + (distance * _pricePerKmDA);
    
    // Facteurs multiplicateurs
    double multiplier = 1.0;
    List<String> factors = [];
    
    // Majoration nocturne
    if (_isNightTime(now)) {
      multiplier += _nightSurcharge;
      factors.add('Livraison nocturne (+${(_nightSurcharge * 100).toInt()}%)');
    }
    
    // Majoration mauvais temps
    if (weather != WeatherCondition.clear) {
      multiplier += _badWeatherSurcharge;
      factors.add('Mauvais temps (+${(_badWeatherSurcharge * 100).toInt()}%)');
    }
    
    // Majoration heures de pointe
    if (_isRushHour(now)) {
      multiplier += _rushHourSurcharge;
      factors.add('Heure de pointe (+${(_rushHourSurcharge * 100).toInt()}%)');
    }
    
    // Majoration weekend
    if (_isWeekend(now)) {
      multiplier += _weekendSurcharge;
      factors.add('Weekend (+${(_weekendSurcharge * 100).toInt()}%)');
    }
    
    // Majoration urgente
    if (isUrgent) {
      multiplier += 0.25; // +25% pour livraison urgente
      factors.add('Livraison urgente (+25%)');
    }
    
    final finalPrice = basePrice * multiplier;
    final estimatedTime = _calculateEstimatedTime(distance, weather);
    
    return DeliveryPrice(
      basePrice: basePrice,
      finalPrice: finalPrice,
      distance: distance,
      estimatedTime: estimatedTime,
      factors: factors,
      multiplier: multiplier,
    );
  }
  
  /// Calculer la distance entre deux points (en km)
  static double _calculateDistance(LatLng point1, LatLng point2) {
    const Distance distance = Distance();
    final meters = distance.as(LengthUnit.Meter, point1, point2);
    return meters / 1000; // Convertir en kilomètres
  }
  
  /// Calculer le temps estimé de livraison (en minutes)
  static int _calculateEstimatedTime(double distanceKm, WeatherCondition weather) {
    // Vitesse moyenne selon les conditions
    double avgSpeedKmh = 25.0; // Vitesse moyenne en ville
    
    switch (weather) {
      case WeatherCondition.rain:
      case WeatherCondition.storm:
        avgSpeedKmh *= 0.7; // -30% en cas de pluie/orage
        break;
      case WeatherCondition.fog:
        avgSpeedKmh *= 0.6; // -40% en cas de brouillard
        break;
      case WeatherCondition.clear:
      case WeatherCondition.cloudy:
        break; // Vitesse normale
    }
    
    final timeHours = distanceKm / avgSpeedKmh;
    final timeMinutes = (timeHours * 60).round();
    
    // Temps minimum de 10 minutes, maximum de 60 minutes
    return timeMinutes.clamp(10, 60);
  }
  
  /// Vérifier si c'est la nuit
  static bool _isNightTime(DateTime time) {
    final hour = time.hour;
    return hour >= _nightStartHour || hour < _nightEndHour;
  }
  
  /// Vérifier si c'est une heure de pointe
  static bool _isRushHour(DateTime time) {
    return _rushHours.contains(time.hour);
  }
  
  /// Vérifier si c'est le weekend
  static bool _isWeekend(DateTime time) {
    return time.weekday == DateTime.friday || time.weekday == DateTime.saturday;
  }
  
  /// Obtenir la condition météo actuelle (simulation)
  /// En production, intégrer une API météo réelle
  static WeatherCondition getCurrentWeather() {
    // Simulation aléatoire pour la démo
    final random = Random();
    final conditions = WeatherCondition.values;
    return conditions[random.nextInt(conditions.length)];
  }
  
  /// Calculer les gains du livreur (commission)
  static double calculateLivreurEarnings(double deliveryPrice) {
    // Le livreur reçoit 70% du prix de livraison
    return deliveryPrice * 0.7;
  }
  
  /// Calculer la commission admin
  static double calculateAdminCommission(double deliveryPrice) {
    // L'admin reçoit 30% du prix de livraison
    return deliveryPrice * 0.3;
  }
}

/// Modèle pour le prix de livraison
class DeliveryPrice {
  final double basePrice;
  final double finalPrice;
  final double distance;
  final int estimatedTime;
  final List<String> factors;
  final double multiplier;
  final String? calculationId;
  final Map<String, double>? multipliers;
  final Map<String, double>? bonuses;
  
  const DeliveryPrice({
    required this.basePrice,
    required this.finalPrice,
    required this.distance,
    required this.estimatedTime,
    required this.factors,
    required this.multiplier,
    this.calculationId,
    this.multipliers,
    this.bonuses,
  });

  /// Créer depuis la réponse backend
  factory DeliveryPrice.fromBackend(Map<String, dynamic> data, double distance) {
    final multipliers = data['multipliers'] as Map<String, dynamic>? ?? {};
    final bonuses = data['bonuses'] as Map<String, dynamic>? ?? {};
    final warnings = List<String>.from(data['warnings'] ?? []);
    
    return DeliveryPrice(
      basePrice: (data['basePrice'] as num).toDouble(),
      finalPrice: (data['finalPrice'] as num).toDouble(),
      distance: distance,
      estimatedTime: _calculateEstimatedTime(distance, WeatherCondition.clear),
      factors: warnings,
      multiplier: multipliers.values.fold(1.0, (a, b) => a * (b as num).toDouble()),
      calculationId: data['calculationId'],
      multipliers: multipliers.map((k, v) => MapEntry(k, (v as num).toDouble())),
      bonuses: bonuses.map((k, v) => MapEntry(k, (v as num).toDouble())),
    );
  }
  
  /// Prix formaté en DA
  String get formattedPrice => '${finalPrice.toStringAsFixed(0)} DA';
  
  /// Distance formatée
  String get formattedDistance => '${distance.toStringAsFixed(1)} km';
  
  /// Temps formaté
  String get formattedTime => '${estimatedTime} min';
  
  /// Économies par rapport au prix majoré
  double get savings => finalPrice - basePrice;
  
  /// Pourcentage de majoration
  double get surchargePercentage => (multiplier - 1) * 100;
  
  @override
  String toString() {
    return 'DeliveryPrice(finalPrice: $formattedPrice, distance: $formattedDistance, time: $formattedTime)';
  }
}

/// Conditions météorologiques
enum WeatherCondition {
  clear,    // Temps clair
  cloudy,   // Nuageux
  rain,     // Pluie
  storm,    // Orage
  fog,      // Brouillard
}

/// Extension pour les conditions météo
extension WeatherConditionExtension on WeatherCondition {
  String get label {
    switch (this) {
      case WeatherCondition.clear:
        return 'Temps clair';
      case WeatherCondition.cloudy:
        return 'Nuageux';
      case WeatherCondition.rain:
        return 'Pluie';
      case WeatherCondition.storm:
        return 'Orage';
      case WeatherCondition.fog:
        return 'Brouillard';
    }
  }
  
  String get emoji {
    switch (this) {
      case WeatherCondition.clear:
        return '☀️';
      case WeatherCondition.cloudy:
        return '☁️';
      case WeatherCondition.rain:
        return '🌧️';
      case WeatherCondition.storm:
        return '⛈️';
      case WeatherCondition.fog:
        return '🌫️';
    }
  }
  
  bool get isBadWeather {
    return this == WeatherCondition.rain || 
           this == WeatherCondition.storm || 
           this == WeatherCondition.fog;
  }
}

/// Types de véhicules
enum VehicleType {
  moto,
  velo,
  voiture,
}

/// Prédictions de gains
class EarningsPrediction {
  final double todayPrediction;
  final double weekPrediction;
  final double monthPrediction;
  final List<HourlyPrediction> hourlyPredictions;
  final List<String> recommendations;

  const EarningsPrediction({
    required this.todayPrediction,
    required this.weekPrediction,
    required this.monthPrediction,
    required this.hourlyPredictions,
    required this.recommendations,
  });

  factory EarningsPrediction.fromJson(Map<String, dynamic> json) {
    return EarningsPrediction(
      todayPrediction: (json['todayPrediction'] as num).toDouble(),
      weekPrediction: (json['weekPrediction'] as num).toDouble(),
      monthPrediction: (json['monthPrediction'] as num).toDouble(),
      hourlyPredictions: (json['hourlyPredictions'] as List)
          .map((item) => HourlyPrediction.fromJson(item))
          .toList(),
      recommendations: List<String>.from(json['recommendations'] ?? []),
    );
  }
}

/// Prédiction par heure
class HourlyPrediction {
  final int hour;
  final double expectedEarnings;
  final double demandMultiplier;
  final String description;

  const HourlyPrediction({
    required this.hour,
    required this.expectedEarnings,
    required this.demandMultiplier,
    required this.description,
  });

  factory HourlyPrediction.fromJson(Map<String, dynamic> json) {
    return HourlyPrediction(
      hour: json['hour'],
      expectedEarnings: (json['expectedEarnings'] as num).toDouble(),
      demandMultiplier: (json['demandMultiplier'] as num).toDouble(),
      description: json['description'] ?? '',
    );
  }
}

/// Opportunité de pricing temps réel
class PricingOpportunity {
  final String id;
  final String zoneName;
  final double multiplier;
  final int availableOrders;
  final String description;
  final double estimatedEarnings;
  final int durationMinutes;

  const PricingOpportunity({
    required this.id,
    required this.zoneName,
    required this.multiplier,
    required this.availableOrders,
    required this.description,
    required this.estimatedEarnings,
    required this.durationMinutes,
  });

  factory PricingOpportunity.fromJson(Map<String, dynamic> json) {
    return PricingOpportunity(
      id: json['id'],
      zoneName: json['zoneName'],
      multiplier: (json['multiplier'] as num).toDouble(),
      availableOrders: json['availableOrders'],
      description: json['description'],
      estimatedEarnings: (json['estimatedEarnings'] as num).toDouble(),
      durationMinutes: json['durationMinutes'],
    );
  }

  String get formattedEarnings => '${estimatedEarnings.toStringAsFixed(0)} DA';
  String get formattedMultiplier => 'x${multiplier.toStringAsFixed(1)}';
}