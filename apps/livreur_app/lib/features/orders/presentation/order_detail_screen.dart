import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/osm_map.dart';
import '../../../core/services/routing_service.dart';
import '../../../core/services/location_service.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  // Positions simulées (Alger)
  LatLng _currentPosition = const LatLng(36.7538, 3.0588);
  final LatLng _restaurantPos = const LatLng(36.7520, 3.0420);
  final LatLng _clientPos = const LatLng(36.7600, 3.0700);
  
  RouteResult? _routeToRestaurant;
  RouteResult? _routeToClient;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    // Get current position
    final pos = await LocationService.getCurrentLocation();
    if (pos != null) _currentPosition = pos;

    // Calculate routes
    final toRestaurant = await RoutingService.getRoute(_currentPosition, _restaurantPos);
    final toClient = await RoutingService.getRoute(_restaurantPos, _clientPos);

    if (mounted) {
      setState(() {
        _routeToRestaurant = toRestaurant;
        _routeToClient = toClient;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Commande #${widget.orderId}')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Map
                  SizedBox(
                    height: 220,
                    child: OsmMap(
                      center: _restaurantPos,
                      zoom: 13,
                      markers: [
                        MapMarkers.livreur(_currentPosition),
                        MapMarkers.restaurant(_restaurantPos),
                        MapMarkers.client(_clientPos),
                      ],
                      polylines: [
                        if (_routeToRestaurant != null)
                          Polyline(points: _routeToRestaurant!.points, color: const Color(0xFF2E7D32), strokeWidth: 4),
                        if (_routeToClient != null)
                          Polyline(points: _routeToClient!.points, color: const Color(0xFF1976D2), strokeWidth: 4),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Route summary
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)]),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildRouteStat(
                                'Distance totale',
                                _getTotalDistance(),
                                Icons.straighten,
                              ),
                              Container(width: 1, height: 40, color: Colors.white30),
                              _buildRouteStat(
                                'Temps estimé',
                                _getTotalDuration(),
                                Icons.access_time,
                              ),
                              Container(width: 1, height: 40, color: Colors.white30),
                              _buildRouteStat(
                                'Gain',
                                '200 DA',
                                Icons.attach_money,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Restaurant section
                        _buildLocationCard(
                          'Restaurant',
                          'Restaurant Exemple',
                          'Rue Didouche Mourad, Alger Centre',
                          _routeToRestaurant?.formattedDistance ?? '...',
                          _routeToRestaurant?.formattedDuration ?? '...',
                          Icons.restaurant,
                          const Color(0xFFE65100),
                        ),
                        const SizedBox(height: 12),
                        // Client section
                        _buildLocationCard(
                          'Client',
                          'Ahmed B.',
                          'Rue des Frères Bouadou, Bir Mourad Raïs',
                          _routeToClient?.formattedDistance ?? '...',
                          _routeToClient?.formattedDuration ?? '...',
                          Icons.person,
                          const Color(0xFF1976D2),
                        ),
                        const SizedBox(height: 16),
                        // Order items
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Articles à récupérer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 12),
                              _buildItem('Pizza Margherita', 1),
                              _buildItem('Burger Classic', 2),
                              _buildItem('Coca Cola', 2),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Accept button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pushNamed(context, AppRouter.delivery, arguments: widget.orderId),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Commencer la livraison'),
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _getTotalDistance() {
    if (_routeToRestaurant == null || _routeToClient == null) return '...';
    final total = _routeToRestaurant!.distanceMeters + _routeToClient!.distanceMeters;
    return RoutingService.formatDistance(total);
  }

  String _getTotalDuration() {
    if (_routeToRestaurant == null || _routeToClient == null) return '...';
    final total = _routeToRestaurant!.durationSeconds + _routeToClient!.durationSeconds;
    return RoutingService.formatDuration(total);
  }

  Widget _buildRouteStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }

  Widget _buildLocationCard(String type, String name, String address, String distance, String duration, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(address, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(distance, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const SizedBox(height: 4),
              Text(duration, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItem(String name, int qty) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(color: const Color(0xFF2E7D32).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
            child: Center(child: Text('$qty', style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 12))),
          ),
          const SizedBox(width: 12),
          Text(name),
          const Spacer(),
          const Icon(Icons.check_circle_outline, color: Colors.grey, size: 20),
        ],
      ),
    );
  }
}
