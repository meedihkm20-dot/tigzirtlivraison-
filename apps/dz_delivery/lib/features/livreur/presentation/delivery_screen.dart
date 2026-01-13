import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/routing_service.dart';
import '../../../core/services/voice_navigation_service.dart';
import '../../../core/widgets/osm_map.dart';
import '../../../core/router/app_router.dart';

class DeliveryScreen extends StatefulWidget {
  final String orderId;
  const DeliveryScreen({super.key, required this.orderId});

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  Map<String, dynamic>? _order;
  bool _isLoading = true;
  LatLng? _currentPosition;
  RouteResult? _route;
  final MapController _mapController = MapController();
  NavigationTracker? _tracker;
  int _currentStepIndex = 0;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _loadOrder();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final hasPermission = await LocationService.checkPermission();
    if (hasPermission) {
      final position = await LocationService.getCurrentLocation();
      if (position != null && mounted) {
        setState(() => _currentPosition = position);
      }
      _startLocationTracking();
    }
  }

  void _startLocationTracking() {
    LocationService.getLocationStream().listen((locationData) {
      if (locationData.latitude != null && locationData.longitude != null && mounted) {
        final newPosition = LatLng(locationData.latitude!, locationData.longitude!);
        setState(() => _currentPosition = newPosition);
        
        if (_tracker != null && _isNavigating) {
          _tracker!.updatePosition(newPosition);
          VoiceNavigationService.checkAndAnnounce(
            currentPosition: newPosition,
            route: _route!,
            currentStepIndex: _currentStepIndex,
          );
        }
        
        // Mettre à jour la position du livreur dans Supabase
        _updateLivreurPosition(newPosition);
      }
    });
  }

  Future<void> _updateLivreurPosition(LatLng position) async {
    try {
      await SupabaseService.updateLivreurLocation(position.latitude, position.longitude);
    } catch (e) {
      // Ignorer les erreurs silencieusement
    }
  }

  Future<void> _loadOrder() async {
    try {
      final order = await SupabaseService.getOrder(widget.orderId);
      setState(() {
        _order = order;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _calculateRoute() async {
    if (_currentPosition == null || _order == null) return;

    final status = _order!['status'] as String?;
    LatLng destination;
    
    if (status == 'delivering') {
      // Vers le client
      destination = LatLng(
        (_order!['delivery_latitude'] as num?)?.toDouble() ?? 36.7538,
        (_order!['delivery_longitude'] as num?)?.toDouble() ?? 3.0588,
      );
    } else {
      // Vers le restaurant
      destination = LatLng(
        (_order!['restaurant']?['latitude'] as num?)?.toDouble() ?? 36.7538,
        (_order!['restaurant']?['longitude'] as num?)?.toDouble() ?? 3.0588,
      );
    }

    final route = await RoutingService.getRoute(_currentPosition!, destination);
    if (route != null && mounted) {
      setState(() {
        _route = route;
        _tracker = NavigationTracker(
          route: route,
          destination: destination,
          onRerouteNeeded: _onRerouteNeeded,
          onStepChanged: _onStepChanged,
          onArrival: _onArrival,
        );
      });
    }
  }

  void _onRerouteNeeded() {
    VoiceNavigationService.announceRerouting();
    _calculateRoute();
  }

  void _onStepChanged(int newIndex) {
    setState(() => _currentStepIndex = newIndex);
  }

  void _onArrival() {
    final status = _order!['status'] as String?;
    VoiceNavigationService.announceArrival(status == 'delivering' ? 'client' : 'restaurant');
    setState(() => _isNavigating = false);
  }

  Future<void> _startNavigation() async {
    await VoiceNavigationService.init();
    VoiceNavigationService.reset();
    await _calculateRoute();
    setState(() => _isNavigating = true);
    VoiceNavigationService.speak('Navigation démarrée');
  }

  Future<void> _startDelivery() async {
    await SupabaseService.updateOrderStatus(widget.orderId, 'delivering');
    await _loadOrder();
    await _calculateRoute();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Livraison démarrée'), backgroundColor: Colors.blue),
    );
  }

  Future<void> _completeDelivery() async {
    await SupabaseService.updateOrderStatus(widget.orderId, 'delivered');
    VoiceNavigationService.speak('Livraison terminée. Félicitations!');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Livraison terminée!'), backgroundColor: Colors.green),
    );
    Navigator.pushReplacementNamed(context, AppRouter.livreurHome);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_order == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Commande non trouvée')));
    }

    final status = _order!['status'] as String?;
    final isDelivering = status == 'delivering';

    return Scaffold(
      body: Stack(
        children: [
          // Carte
          if (_currentPosition != null)
            OsmMap(
              center: _currentPosition!,
              zoom: 16,
              controller: _mapController,
              markers: _buildMarkers(),
              polylines: _route != null ? [
                Polyline(
                  points: _route!.points,
                  color: Colors.blue,
                  strokeWidth: 5,
                ),
              ] : null,
            )
          else
            const Center(child: CircularProgressIndicator()),
          
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
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
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
                        'Livraison #${_order!['order_number'] ?? ''}',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (!_isNavigating)
                      IconButton(
                        icon: const Icon(Icons.navigation, color: Colors.white),
                        onPressed: _startNavigation,
                      ),
                  ],
                ),
              ),
            ),
          ),
          
          // Instructions de navigation
          if (_isNavigating && _route != null && _route!.steps.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 70,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _route!.steps[_currentStepIndex].instruction,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_route!.steps[_currentStepIndex].formattedDistance} - ${_route!.formattedDuration} restant',
                      style: TextStyle(color: Colors.white.withOpacity(0.8)),
                    ),
                  ],
                ),
              ),
            ),
          
          // Bottom panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Status
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDelivering ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isDelivering ? Icons.delivery_dining : Icons.restaurant,
                            color: isDelivering ? Colors.blue : Colors.orange,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isDelivering ? 'En route vers le client' : 'Récupérer au restaurant',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (_route != null)
                            Text(
                              _route!.formattedDistance,
                              style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Destination info
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isDelivering 
                                    ? (_order!['customer']?['full_name'] ?? 'Client')
                                    : (_order!['restaurant']?['name'] ?? 'Restaurant'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                isDelivering 
                                    ? (_order!['delivery_address'] ?? '')
                                    : (_order!['restaurant']?['address'] ?? ''),
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.phone, color: Colors.green),
                          onPressed: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Montant
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('À collecter'),
                          Text(
                            '${_order!['total']?.toStringAsFixed(0) ?? 0} DA',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Action button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: isDelivering ? _completeDelivery : _startDelivery,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDelivering ? Colors.green : Colors.blue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          isDelivering ? 'Livraison terminée' : 'Commande récupérée',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];
    
    // Position actuelle du livreur
    if (_currentPosition != null) {
      markers.add(MapMarkers.livreur(_currentPosition!));
    }
    
    // Restaurant
    final restaurantLat = (_order!['restaurant']?['latitude'] as num?)?.toDouble();
    final restaurantLng = (_order!['restaurant']?['longitude'] as num?)?.toDouble();
    if (restaurantLat != null && restaurantLng != null) {
      markers.add(MapMarkers.restaurant(LatLng(restaurantLat, restaurantLng)));
    }
    
    // Client
    final clientLat = (_order!['delivery_latitude'] as num?)?.toDouble();
    final clientLng = (_order!['delivery_longitude'] as num?)?.toDouble();
    if (clientLat != null && clientLng != null) {
      markers.add(MapMarkers.client(LatLng(clientLat, clientLng)));
    }
    
    return markers;
  }

  @override
  void dispose() {
    VoiceNavigationService.stop();
    super.dispose();
  }
}
