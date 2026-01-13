import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';

/// Écran de suivi en temps réel avec carte animée
class LiveTrackingScreen extends StatefulWidget {
  final String orderId;
  const LiveTrackingScreen({super.key, required this.orderId});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> with TickerProviderStateMixin {
  Map<String, dynamic>? _order;
  LatLng? _livreurPosition;
  LatLng? _restaurantPosition;
  LatLng? _customerPosition;
  RealtimeChannel? _channel;
  final MapController _mapController = MapController();
  bool _isLoading = true;
  late AnimationController _pulseController;
  String? _confirmationCode;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _loadOrder();
    _subscribeToUpdates();
  }

  Future<void> _loadOrder() async {
    try {
      final order = await SupabaseService.getOrder(widget.orderId);
      final code = await SupabaseService.getConfirmationCode(widget.orderId);
      
      setState(() {
        _order = order;
        _confirmationCode = code;
        _isLoading = false;
        
        if (order != null) {
          final restaurant = order['restaurant'] as Map<String, dynamic>?;
          if (restaurant != null) {
            _restaurantPosition = LatLng(
              (restaurant['latitude'] as num?)?.toDouble() ?? 36.7538,
              (restaurant['longitude'] as num?)?.toDouble() ?? 3.0588,
            );
          }
          
          _customerPosition = LatLng(
            (order['delivery_latitude'] as num?)?.toDouble() ?? 36.7538,
            (order['delivery_longitude'] as num?)?.toDouble() ?? 3.0588,
          );
          
          final livreur = order['livreur'] as Map<String, dynamic>?;
          if (livreur != null) {
            _livreurPosition = LatLng(
              (livreur['current_latitude'] as num?)?.toDouble() ?? 36.7538,
              (livreur['current_longitude'] as num?)?.toDouble() ?? 3.0588,
            );
          }
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _subscribeToUpdates() {
    _channel = SupabaseService.client.channel('live_tracking_${widget.orderId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: widget.orderId,
          ),
          callback: (payload) {
            _loadOrder();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'livreur_locations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'order_id',
            value: widget.orderId,
          ),
          callback: (payload) {
            final newRecord = payload.newRecord;
            if (newRecord['latitude'] != null && newRecord['longitude'] != null) {
              setState(() {
                _livreurPosition = LatLng(
                  (newRecord['latitude'] as num).toDouble(),
                  (newRecord['longitude'] as num).toDouble(),
                );
              });
            }
          },
        )
        .subscribe();
  }

  String _getStatusMessage(String? status) {
    switch (status) {
      case 'pending': return 'En attente d\'un livreur...';
      case 'confirmed': return 'Commande confirmée, préparation en cours';
      case 'preparing': return 'Le restaurant prépare votre commande';
      case 'ready': return 'Commande prête! Le livreur arrive';
      case 'picked_up': return 'Le livreur a récupéré votre commande';
      case 'delivering': return 'En route vers vous! 🛵';
      case 'delivered': return 'Livré! Bon appétit! 🎉';
      default: return 'En cours...';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'confirmed':
      case 'preparing': return Colors.blue;
      case 'ready': return Colors.purple;
      case 'picked_up':
      case 'delivering': return Colors.green;
      case 'delivered': return Colors.teal;
      default: return Colors.grey;
    }
  }

  int _getStatusStep(String? status) {
    switch (status) {
      case 'pending': return 0;
      case 'confirmed': return 1;
      case 'preparing': return 2;
      case 'ready': return 3;
      case 'picked_up': return 4;
      case 'delivering': return 5;
      case 'delivered': return 6;
      default: return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final status = _order?['status'] as String?;
    final currentStep = _getStatusStep(status);
    final showCode = status == 'picked_up' || status == 'delivering';
    final livreur = _order?['livreur'] as Map<String, dynamic>?;
    final livreurProfile = livreur?['profile'] as Map<String, dynamic>?;

    return Scaffold(
      body: Stack(
        children: [
          // Carte
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _livreurPosition ?? _customerPosition ?? const LatLng(36.7538, 3.0588),
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.dzdelivery.app',
              ),
              MarkerLayer(markers: _buildMarkers()),
              if (_livreurPosition != null && _customerPosition != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [_livreurPosition!, _customerPosition!],
                      color: AppTheme.primaryColor.withValues(alpha: 0.5),
                      strokeWidth: 3,
                      pattern: const StrokePattern.dotted(),
                    ),
                  ],
                ),
            ],
          ),

          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        'Suivi en direct',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: _loadOrder,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20)],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Status avec animation
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status).withValues(alpha: 0.1 + (_pulseController.value * 0.1)),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: _getStatusColor(status)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(status),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _getStatusMessage(status),
                                  style: TextStyle(
                                    color: _getStatusColor(status),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // Progress steps
                      _buildProgressSteps(currentStep),
                      const SizedBox(height: 20),

                      // Code de confirmation
                      if (showCode && _confirmationCode != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.orange, Colors.deepOrange],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                '🔐 Code de confirmation',
                                style: TextStyle(color: Colors.white, fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _confirmationCode!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Donnez ce code au livreur',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Infos livreur
                      if (livreur != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                                child: Text(
                                  (livreurProfile?['full_name'] ?? 'L')[0].toUpperCase(),
                                  style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      livreurProfile?['full_name'] ?? 'Livreur',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.star, color: Colors.amber, size: 16),
                                        Text(' ${(livreur['rating'] ?? 5.0).toStringAsFixed(1)}'),
                                        Text(' • ${livreur['vehicle_type'] ?? 'Moto'}', style: TextStyle(color: Colors.grey[600])),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.phone, color: Colors.white, size: 20),
                                ),
                                onPressed: () {
                                  // TODO: Appeler le livreur
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSteps(int currentStep) {
    final steps = ['Confirmé', 'Préparation', 'Prêt', 'Récupéré', 'En route', 'Livré'];
    
    return Row(
      children: List.generate(steps.length, (index) {
        final isCompleted = index < currentStep;
        final isCurrent = index == currentStep;
        
        return Expanded(
          child: Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isCompleted || isCurrent ? AppTheme.primaryColor : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : isCurrent
                        ? Container(
                            margin: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
              ),
              const SizedBox(height: 4),
              Text(
                steps[index],
                style: TextStyle(
                  fontSize: 9,
                  color: isCompleted || isCurrent ? AppTheme.primaryColor : Colors.grey,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }),
    );
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    // Restaurant
    if (_restaurantPosition != null) {
      markers.add(Marker(
        point: _restaurantPosition!,
        width: 40,
        height: 40,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.orange,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(Icons.restaurant, color: Colors.white, size: 20),
        ),
      ));
    }

    // Client
    if (_customerPosition != null) {
      markers.add(Marker(
        point: _customerPosition!,
        width: 40,
        height: 40,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(Icons.home, color: Colors.white, size: 20),
        ),
      ));
    }

    // Livreur (animé)
    if (_livreurPosition != null) {
      markers.add(Marker(
        point: _livreurPosition!,
        width: 50,
        height: 50,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 50 * (1 + _pulseController.value * 0.3),
                  height: 50 * (1 + _pulseController.value * 0.3),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.3 * (1 - _pulseController.value)),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(Icons.delivery_dining, color: Colors.white, size: 22),
                ),
              ],
            );
          },
        ),
      ));
    }

    return markers;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _channel?.unsubscribe();
    super.dispose();
  }
}
