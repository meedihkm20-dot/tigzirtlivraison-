import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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
  final _codeController = TextEditingController();
  bool _isVerifying = false;

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
        _updateLivreurPosition(newPosition);
      }
    });
  }

  Future<void> _updateLivreurPosition(LatLng position) async {
    try {
      await SupabaseService.updateLivreurLocation(position.latitude, position.longitude);
    } catch (e) {}
  }

  Future<void> _loadOrder() async {
    try {
      final order = await SupabaseService.getOrder(widget.orderId);
      setState(() {
        _order = order;
        _isLoading = false;
      });
      _calculateRoute();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _calculateRoute() async {
    if (_currentPosition == null || _order == null) return;

    final status = _order!['status'] as String?;
    LatLng destination;
    
    if (status == 'delivering' || status == 'picked_up') {
      destination = LatLng(
        (_order!['delivery_latitude'] as num?)?.toDouble() ?? 36.7538,
        (_order!['delivery_longitude'] as num?)?.toDouble() ?? 3.0588,
      );
    } else {
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
          onRerouteNeeded: () {
            VoiceNavigationService.announceRerouting();
            _calculateRoute();
          },
          onStepChanged: (i) => setState(() => _currentStepIndex = i),
          onArrival: () {
            final s = _order!['status'] as String?;
            VoiceNavigationService.announceArrival(s == 'delivering' ? 'client' : 'restaurant');
            setState(() => _isNavigating = false);
          },
        );
      });
    }
  }

  Future<void> _startNavigation() async {
    await VoiceNavigationService.init();
    VoiceNavigationService.reset();
    await _calculateRoute();
    setState(() => _isNavigating = true);
    VoiceNavigationService.speak('Navigation démarrée');
  }

  Future<void> _pickupOrder() async {
    await SupabaseService.updateOrderStatus(widget.orderId, 'picked_up');
    await _loadOrder();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Commande récupérée! En route vers le client'), backgroundColor: Colors.blue),
    );
  }

  Future<void> _startDelivering() async {
    await SupabaseService.updateOrderStatus(widget.orderId, 'delivering');
    await _loadOrder();
  }

  /// Afficher le dialog pour entrer le code de confirmation
  void _showCodeDialog() {
    _codeController.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Code de confirmation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Demandez le code à 4 chiffres au client'),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 8),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                counterText: '',
                border: OutlineInputBorder(),
                hintText: '0000',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: _isVerifying ? null : _verifyCode,
            child: _isVerifying 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Vérifier'),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrez un code à 4 chiffres'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isVerifying = true);
    
    try {
      final success = await SupabaseService.verifyConfirmationCode(
        widget.orderId,
        _codeController.text,
      );

      if (success) {
        Navigator.pop(context); // Fermer le dialog
        VoiceNavigationService.speak('Code correct! Livraison terminée. Félicitations!');
        
        // Afficher la commission gagnée
        final commission = (_order!['livreur_commission'] as num?)?.toDouble() ?? 0;
        
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 32),
                SizedBox(width: 8),
                Text('Livraison terminée!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Vous avez gagné:'),
                const SizedBox(height: 8),
                Text(
                  '${commission.toStringAsFixed(0)} DA',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, AppRouter.livreurHome);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Retour à l\'accueil'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Code incorrect! Réessayez'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isVerifying = false);
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'confirmed': return 'En attente de préparation';
      case 'preparing': return 'Restaurant prépare';
      case 'ready': return 'Prêt à récupérer';
      case 'picked_up': return 'En route vers le client';
      case 'delivering': return 'Livraison en cours';
      default: return 'En cours';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'confirmed':
      case 'preparing': return Colors.orange;
      case 'ready': return Colors.green;
      case 'picked_up':
      case 'delivering': return Colors.blue;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_order == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('Commande non trouvée')));

    final status = _order!['status'] as String?;
    final isAtClient = status == 'picked_up' || status == 'delivering';
    final isReady = status == 'ready';
    final commission = (_order!['livreur_commission'] as num?)?.toDouble() ?? 0;

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
              polylines: _route != null ? [Polyline(points: _route!.points, color: Colors.blue, strokeWidth: 5)] : null,
            )
          else
            const Center(child: CircularProgressIndicator()),
          
          // Header
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
                    Expanded(child: Text('Commande #${_order!['order_number'] ?? ''}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                    if (!_isNavigating) IconButton(icon: const Icon(Icons.navigation, color: Colors.white), onPressed: _startNavigation),
                  ],
                ),
              ),
            ),
          ),
          
          // Instructions navigation
          if (_isNavigating && _route != null && _route!.steps.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 70, left: 16, right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_route!.steps[_currentStepIndex].instruction, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('${_route!.steps[_currentStepIndex].formattedDistance} - ${_route!.formattedDuration}', style: TextStyle(color: Colors.white.withOpacity(0.8))),
                  ],
                ),
              ),
            ),
          
          // Bottom panel
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Status
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: _getStatusColor(status).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Icon(isAtClient ? Icons.delivery_dining : Icons.restaurant, color: _getStatusColor(status)),
                          const SizedBox(width: 12),
                          Expanded(child: Text(_getStatusText(status), style: const TextStyle(fontWeight: FontWeight.bold))),
                          if (_route != null) Text(_route!.formattedDistance, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Destination
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(isAtClient ? (_order!['customer']?['full_name'] ?? 'Client') : (_order!['restaurant']?['name'] ?? 'Restaurant'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text(isAtClient ? (_order!['delivery_address'] ?? '') : (_order!['restaurant']?['address'] ?? ''), style: TextStyle(color: Colors.grey[600], fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.phone, color: Colors.green), onPressed: () {}),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Montants
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: Column(
                              children: [
                                const Text('À collecter', style: TextStyle(fontSize: 12)),
                                Text('${_order!['total']?.toStringAsFixed(0) ?? 0} DA', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 18)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: Column(
                              children: [
                                const Text('Votre gain', style: TextStyle(fontSize: 12)),
                                Text('${commission.toStringAsFixed(0)} DA', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 18)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Action button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: isReady ? _pickupOrder : (isAtClient ? _showCodeDialog : null),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isReady ? Colors.orange : (isAtClient ? Colors.green : Colors.grey),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          isReady ? 'J\'ai récupéré la commande' : (isAtClient ? 'Entrer le code de confirmation' : 'En attente...'),
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
    if (_currentPosition != null) markers.add(MapMarkers.livreur(_currentPosition!));
    
    final rLat = (_order!['restaurant']?['latitude'] as num?)?.toDouble();
    final rLng = (_order!['restaurant']?['longitude'] as num?)?.toDouble();
    if (rLat != null && rLng != null) markers.add(MapMarkers.restaurant(LatLng(rLat, rLng)));
    
    final cLat = (_order!['delivery_latitude'] as num?)?.toDouble();
    final cLng = (_order!['delivery_longitude'] as num?)?.toDouble();
    if (cLat != null && cLng != null) markers.add(MapMarkers.client(LatLng(cLat, cLng)));
    
    return markers;
  }

  @override
  void dispose() {
    VoiceNavigationService.stop();
    _codeController.dispose();
    super.dispose();
  }
}
