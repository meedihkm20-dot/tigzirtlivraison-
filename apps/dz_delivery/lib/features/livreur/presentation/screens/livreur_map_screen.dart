import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../../core/design_system/theme/app_colors.dart';
import '../../../../core/design_system/theme/app_typography.dart';
import '../../../../core/design_system/theme/app_spacing.dart';
import '../../../../core/design_system/theme/app_shadows.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/voice_navigation_service.dart';
import '../../../../core/services/delivery_pricing_service.dart';

/// Écran de carte pour livreurs avec navigation et guidage vocal
class LivreurMapScreen extends StatefulWidget {
  const LivreurMapScreen({super.key});

  @override
  State<LivreurMapScreen> createState() => _LivreurMapScreenState();
}

class _LivreurMapScreenState extends State<LivreurMapScreen> {
  late MapController _mapController;
  FlutterTts? _flutterTts;
  
  LatLng? _currentPosition;
  List<Map<String, dynamic>> _restaurants = [];
  List<Map<String, dynamic>> _availableOrders = [];
  Map<String, dynamic>? _selectedRestaurant;
  
  bool _isLoading = true;
  bool _isNavigating = false;
  bool _voiceEnabled = true;
  String _mapStyle = 'osm'; // osm, satellite
  
  StreamSubscription<Position>? _positionStream;
  Timer? _restaurantUpdateTimer;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initTts();
    _loadData();
    _startLocationTracking();
    _startPeriodicUpdates();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _restaurantUpdateTimer?.cancel();
    _flutterTts?.stop();
    super.dispose();
  }

  Future<void> _initTts() async {
    _flutterTts = FlutterTts();
    await _flutterTts?.setLanguage('fr-FR');
    await _flutterTts?.setSpeechRate(0.8);
    await _flutterTts?.setVolume(0.8);
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final results = await Future.wait([
        _loadRestaurants(),
        _loadAvailableOrders(),
        _getCurrentLocation(),
      ]);
      
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Erreur chargement données: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRestaurants() async {
    try {
      final restaurants = await SupabaseService.client
          .from('restaurants')
          .select('*')
          .eq('is_active', true)
          .eq('is_open', true);
      
      setState(() {
        _restaurants = List<Map<String, dynamic>>.from(restaurants);
      });
    } catch (e) {
      debugPrint('Erreur chargement restaurants: $e');
    }
  }

  Future<void> _loadAvailableOrders() async {
    try {
      final orders = await SupabaseService.client
          .from('orders')
          .select('*, restaurants(*)')
          .eq('status', 'ready')
          .isFilter('livreur_id', null);
      
      setState(() {
        _availableOrders = List<Map<String, dynamic>>.from(orders);
      });
    } catch (e) {
      debugPrint('Erreur chargement commandes: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
      
      if (_currentPosition != null) {
        _mapController.move(_currentPosition!, 15);
      }
    } catch (e) {
      debugPrint('Erreur géolocalisation: $e');
    }
  }

  void _startLocationTracking() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((position) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
    });
  }

  void _startPeriodicUpdates() {
    _restaurantUpdateTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) => _loadAvailableOrders(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          _buildMap(),
          if (_isLoading) _buildLoadingOverlay(),
          _buildMapControls(),
          if (_selectedRestaurant != null) _buildRestaurantDetails(),
        ],
      ),
      floatingActionButton: _buildFABs(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.livreurPrimary,
      foregroundColor: Colors.white,
      title: const Text('Carte des restaurants'),
      actions: [
        IconButton(
          icon: Icon(_voiceEnabled ? Icons.volume_up : Icons.volume_off),
          onPressed: () {
            setState(() => _voiceEnabled = !_voiceEnabled);
            _speak(_voiceEnabled ? 'Guidage vocal activé' : 'Guidage vocal désactivé');
          },
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'refresh':
                _loadData();
                break;
              case 'style':
                _toggleMapStyle();
                break;
              case 'center':
                _centerOnCurrentLocation();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh),
                  SizedBox(width: 8),
                  Text('Actualiser'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'style',
              child: Row(
                children: [
                  Icon(Icons.layers),
                  SizedBox(width: 8),
                  Text('Style de carte'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'center',
              child: Row(
                children: [
                  Icon(Icons.my_location),
                  SizedBox(width: 8),
                  Text('Me localiser'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentPosition ?? const LatLng(36.7538, 3.0588), // Alger par défaut
        initialZoom: 13,
        minZoom: 10,
        maxZoom: 18,
        onTap: (_, __) => setState(() => _selectedRestaurant = null),
      ),
      children: [
        TileLayer(
          urlTemplate: _mapStyle == 'osm'
              ? 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'
              : 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
          userAgentPackageName: 'com.dzdelivery.app',
        ),
        MarkerLayer(
          markers: [
            // Position actuelle
            if (_currentPosition != null)
              Marker(
                point: _currentPosition!,
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.livreurPrimary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: AppShadows.md,
                  ),
                  child: const Icon(
                    Icons.delivery_dining,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            
            // Restaurants
            ..._restaurants.map((restaurant) => _buildRestaurantMarker(restaurant)),
            
            // Commandes disponibles
            ..._availableOrders.map((order) => _buildOrderMarker(order)),
          ],
        ),
      ],
    );
  }

  Marker _buildRestaurantMarker(Map<String, dynamic> restaurant) {
    final hasOrders = _availableOrders.any((order) => order['restaurant_id'] == restaurant['id']);
    
    return Marker(
      point: LatLng(
        (restaurant['latitude'] as num).toDouble(),
        (restaurant['longitude'] as num).toDouble(),
      ),
      width: 50,
      height: 50,
      child: GestureDetector(
        onTap: () => _selectRestaurant(restaurant),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: hasOrders ? AppColors.success : AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: AppShadows.md,
              ),
              child: const Icon(
                Icons.restaurant,
                color: Colors.white,
                size: 24,
              ),
            ),
            if (hasOrders)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _availableOrders.where((o) => o['restaurant_id'] == restaurant['id']).length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Marker _buildOrderMarker(Map<String, dynamic> order) {
    return Marker(
      point: LatLng(
        (order['delivery_latitude'] as num).toDouble(),
        (order['delivery_longitude'] as num).toDouble(),
      ),
      width: 40,
      height: 40,
      child: GestureDetector(
        onTap: () => _showOrderDetails(order),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.warning,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: AppShadows.md,
          ),
          child: const Icon(
            Icons.location_on,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.livreurPrimary),
      ),
    );
  }

  Widget _buildMapControls() {
    return Positioned(
      right: 16,
      top: 100,
      child: Column(
        children: [
          FloatingActionButton.small(
            heroTag: 'zoom_in',
            onPressed: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1),
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'zoom_out',
            onPressed: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1),
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
            child: const Icon(Icons.remove),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantDetails() {
    final restaurant = _selectedRestaurant!;
    final ordersCount = _availableOrders.where((o) => o['restaurant_id'] == restaurant['id']).length;
    
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.borderRadiusLg,
          boxShadow: AppShadows.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurant['name'] ?? 'Restaurant',
                        style: AppTypography.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        restaurant['address'] ?? '',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _selectedRestaurant = null),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip(Icons.shopping_bag, '$ordersCount commandes'),
                const SizedBox(width: 8),
                _buildInfoChip(Icons.star, '${restaurant['rating'] ?? 5.0}'),
                const SizedBox(width: 8),
                if (_currentPosition != null)
                  _buildInfoChip(
                    Icons.directions,
                    '${_calculateDistance(restaurant).toStringAsFixed(1)} km',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToRestaurant(restaurant),
                    icon: const Icon(Icons.directions),
                    label: const Text('Navigation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.livreurPrimary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _callRestaurant(restaurant),
                  icon: const Icon(Icons.phone),
                  label: const Text('Appeler'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildFABs() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          heroTag: 'current_location',
          onPressed: _centerOnCurrentLocation,
          backgroundColor: AppColors.livreurPrimary,
          child: const Icon(Icons.my_location, color: Colors.white),
        ),
        const SizedBox(height: 16),
        FloatingActionButton(
          heroTag: 'available_orders',
          onPressed: _showAvailableOrdersList,
          backgroundColor: AppColors.success,
          child: Badge(
            label: Text(_availableOrders.length.toString()),
            child: const Icon(Icons.list_alt, color: Colors.white),
          ),
        ),
      ],
    );
  }

  void _selectRestaurant(Map<String, dynamic> restaurant) {
    setState(() => _selectedRestaurant = restaurant);
    
    final restaurantPosition = LatLng(
      (restaurant['latitude'] as num).toDouble(),
      (restaurant['longitude'] as num).toDouble(),
    );
    
    _mapController.move(restaurantPosition, 16);
    
    if (_voiceEnabled) {
      _speak('Restaurant ${restaurant['name']} sélectionné');
    }
  }

  double _calculateDistance(Map<String, dynamic> restaurant) {
    if (_currentPosition == null) return 0;
    
    final restaurantPos = LatLng(
      (restaurant['latitude'] as num).toDouble(),
      (restaurant['longitude'] as num).toDouble(),
    );
    
    const Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, _currentPosition!, restaurantPos);
  }

  void _navigateToRestaurant(Map<String, dynamic> restaurant) async {
    final lat = restaurant['latitude'];
    final lng = restaurant['longitude'];
    final name = restaurant['name'];
    
    // Ouvrir Google Maps ou Waze
    final googleMapsUrl = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=$name';
    final wazeUrl = 'https://waze.com/ul?ll=$lat,$lng&navigate=yes';
    
    try {
      // Essayer Waze d'abord, puis Google Maps
      if (await canLaunchUrl(Uri.parse(wazeUrl))) {
        await launchUrl(Uri.parse(wazeUrl));
      } else if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
        await launchUrl(Uri.parse(googleMapsUrl));
      }
      
      if (_voiceEnabled) {
        _speak('Navigation vers ${restaurant['name']} lancée');
      }
    } catch (e) {
      debugPrint('Erreur navigation: $e');
    }
  }

  void _callRestaurant(Map<String, dynamic> restaurant) async {
    final phone = restaurant['phone'];
    if (phone != null) {
      final url = 'tel:$phone';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      }
    }
  }

  void _centerOnCurrentLocation() {
    if (_currentPosition != null) {
      _mapController.move(_currentPosition!, 15);
      if (_voiceEnabled) {
        _speak('Centré sur votre position');
      }
    }
  }

  void _toggleMapStyle() {
    setState(() {
      _mapStyle = _mapStyle == 'osm' ? 'satellite' : 'osm';
    });
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Commande disponible', style: AppTypography.titleMedium),
            const SizedBox(height: 16),
            Text('Restaurant: ${order['restaurants']?['name'] ?? 'N/A'}'),
            Text('Total: ${order['total']} DA'),
            Text('Distance: ${_calculateOrderDistance(order).toStringAsFixed(1)} km'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _acceptOrder(order);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Accepter la commande'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateOrderDistance(Map<String, dynamic> order) {
    if (_currentPosition == null) return 0;
    
    final orderPos = LatLng(
      (order['delivery_latitude'] as num).toDouble(),
      (order['delivery_longitude'] as num).toDouble(),
    );
    
    const Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, _currentPosition!, orderPos);
  }

  void _acceptOrder(Map<String, dynamic> order) async {
    try {
      // Logique d'acceptation de commande
      if (_voiceEnabled) {
        _speak('Commande acceptée');
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Commande acceptée!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      debugPrint('Erreur acceptation commande: $e');
    }
  }

  void _showAvailableOrdersList() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                'Commandes disponibles (${_availableOrders.length})',
                style: AppTypography.titleMedium,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _availableOrders.length,
                  itemBuilder: (context, index) {
                    final order = _availableOrders[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(order['restaurants']?['name'] ?? 'Restaurant'),
                        subtitle: Text('${order['total']} DA • ${_calculateOrderDistance(order).toStringAsFixed(1)} km'),
                        trailing: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _acceptOrder(order);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Accepter'),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _speak(String text) async {
    if (_voiceEnabled && _flutterTts != null) {
      await _flutterTts!.speak(text);
    }
  }
}