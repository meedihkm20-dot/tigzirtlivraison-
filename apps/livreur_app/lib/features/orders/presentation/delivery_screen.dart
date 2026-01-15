import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/osm_map.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/routing_service.dart';
import '../../../core/services/voice_navigation_service.dart';

class DeliveryScreen extends StatefulWidget {
  final String orderId;
  const DeliveryScreen({super.key, required this.orderId});

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  int _currentStep = 0;
  final List<String> _steps = ['Récupération', 'En route', 'Arrivé', 'Livré'];
  final MapController _mapController = MapController();
  
  LatLng _currentPosition = const LatLng(36.7538, 3.0588);
  final LatLng _restaurantPosition = const LatLng(36.7520, 3.0420);
  final LatLng _clientPosition = const LatLng(36.7600, 3.0700);
  
  RouteResult? _currentRoute;
  bool _isLoadingRoute = true;
  int _currentInstructionIndex = 0;
  StreamSubscription? _locationSubscription;
  
  // Navigation
  NavigationTracker? _navigationTracker;
  bool _voiceEnabled = true;
  bool _isRerouting = false;

  @override
  void initState() {
    super.initState();
    _initDelivery();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    VoiceNavigationService.stop();
    super.dispose();
  }

  Future<void> _initDelivery() async {
    // Init voice
    await VoiceNavigationService.init();
    VoiceNavigationService.reset();
    
    // Get current position
    final pos = await LocationService.getCurrentLocation();
    if (pos != null && mounted) setState(() => _currentPosition = pos);
    
    // Calculate route
    await _calculateRoute();
    
    // Start tracking
    _startLocationTracking();
    
    // Announce start
    if (_voiceEnabled) {
      await VoiceNavigationService.speak('Navigation démarrée. Direction le restaurant.');
    }
  }

  void _startLocationTracking() {
    _locationSubscription = LocationService.getLocationStream().listen((position) {
      if (!mounted) return;
      
      // LocationData has nullable lat/lng
      if (position.latitude == null || position.longitude == null) return;
      
      final newPosition = LatLng(position.latitude!, position.longitude!);
      setState(() => _currentPosition = newPosition);
      
      // Update navigation tracker
      _navigationTracker?.updatePosition(newPosition);
      
      // Check voice announcement
      if (_voiceEnabled && _currentRoute != null) {
        VoiceNavigationService.checkAndAnnounce(
          currentPosition: newPosition,
          route: _currentRoute!,
          currentStepIndex: _currentInstructionIndex,
        );
      }
    });
  }

  Future<void> _calculateRoute() async {
    setState(() {
      _isLoadingRoute = true;
      _isRerouting = false;
    });
    
    final destination = _currentStep < 2 ? _restaurantPosition : _clientPosition;
    final route = await RoutingService.getRoute(_currentPosition, destination);
    
    if (mounted && route != null) {
      setState(() {
        _currentRoute = route;
        _isLoadingRoute = false;
        _currentInstructionIndex = 0;
      });
      
      // Setup navigation tracker
      _navigationTracker = NavigationTracker(
        route: route,
        destination: destination,
        onRerouteNeeded: _handleReroute,
        onStepChanged: _handleStepChanged,
        onArrival: _handleArrival,
      );
    }
  }

  void _handleReroute() async {
    if (_isRerouting) return;
    _isRerouting = true;
    
    if (_voiceEnabled) {
      await VoiceNavigationService.announceRerouting();
    }
    
    // Recalculate route
    await _calculateRoute();
  }

  void _handleStepChanged(int newIndex) {
    setState(() => _currentInstructionIndex = newIndex);
  }

  void _handleArrival() async {
    final destinationType = _currentStep < 2 ? 'restaurant' : 'client';
    
    if (_voiceEnabled) {
      await VoiceNavigationService.announceArrival(destinationType);
    }
    
    // Show arrival notification
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_currentStep < 2 
            ? 'Vous êtes arrivé au restaurant!' 
            : 'Vous êtes arrivé chez le client!'),
          backgroundColor: const Color(0xFF2E7D32),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _openExternalNavigation() async {
    final dest = _currentStep < 2 ? _restaurantPosition : _clientPosition;
    final googleUrl = 'google.navigation:q=${dest.latitude},${dest.longitude}&mode=d';
    final osmUrl = 'https://www.openstreetmap.org/directions?from=${_currentPosition.latitude},${_currentPosition.longitude}&to=${dest.latitude},${dest.longitude}';
    
    if (await canLaunchUrl(Uri.parse(googleUrl))) {
      await launchUrl(Uri.parse(googleUrl));
    } else {
      await launchUrl(Uri.parse(osmUrl), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                OsmMap(
                  center: _currentPosition,
                  zoom: 16,
                  controller: _mapController,
                  markers: [
                    MapMarkers.livreur(_currentPosition),
                    MapMarkers.restaurant(_restaurantPosition),
                    MapMarkers.client(_clientPosition),
                  ],
                  polylines: _currentRoute != null
                      ? [Polyline(points: _currentRoute!.points, color: const Color(0xFF2E7D32), strokeWidth: 5)]
                      : [],
                ),
                // Top bar
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 8,
                  right: 8,
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        child: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
                      ),
                      const Spacer(),
                      if (_currentRoute != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)]),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.directions, color: Color(0xFF2E7D32), size: 20),
                              const SizedBox(width: 8),
                              Text(_currentRoute!.formattedDistance, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(' • ${_currentRoute!.formattedDuration}', style: TextStyle(color: Colors.grey[600])),
                            ],
                          ),
                        ),
                      const SizedBox(width: 8),
                      // Voice toggle
                      CircleAvatar(
                        backgroundColor: _voiceEnabled ? const Color(0xFF2E7D32) : Colors.white,
                        child: IconButton(
                          icon: Icon(_voiceEnabled ? Icons.volume_up : Icons.volume_off, color: _voiceEnabled ? Colors.white : Colors.grey),
                          onPressed: () {
                            setState(() => _voiceEnabled = !_voiceEnabled);
                            if (!_voiceEnabled) VoiceNavigationService.stop();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // Rerouting indicator
                if (_isRerouting)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 60,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(20)),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                            SizedBox(width: 8),
                            Text('Recalcul...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                // Center button
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton.small(
                    heroTag: 'center',
                    backgroundColor: Colors.white,
                    onPressed: () => _mapController.move(_currentPosition, 16),
                    child: const Icon(Icons.my_location, color: Color(0xFF2E7D32)),
                  ),
                ),
              ],
            ),
          ),
          _buildBottomPanel(),
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_currentRoute != null && _currentRoute!.steps.isNotEmpty) _buildNavigationInstruction(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: List.generate(_steps.length, _buildStepIndicator)),
                const SizedBox(height: 16),
                _buildDestinationCard(),
                const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _openExternalNavigation,
                            icon: const Icon(Icons.navigation),
                            label: const Text('GPS'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Bouton problème
                        OutlinedButton.icon(
                          onPressed: _reportProblem,
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.orange),
                          icon: const Icon(Icons.warning_amber),
                          label: const Text('Problème'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _nextStep,
                            child: Text(_currentStep < _steps.length - 1 ? _steps[_currentStep + 1] : 'Confirmer'),
                          ),
                        ),
                      ],
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationInstruction() {
    final step = _currentRoute!.steps[_currentInstructionIndex.clamp(0, _currentRoute!.steps.length - 1)];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF2E7D32),
      child: Row(
        children: [
          _getDirectionIcon(step.instruction),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.instruction, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                if (step.name.isNotEmpty) Text(step.name, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(step.formattedDistance, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              if (_voiceEnabled) const Icon(Icons.volume_up, color: Colors.white54, size: 16),
            ],
          ),
        ],
      ),
    );
  }

  Widget _getDirectionIcon(String instruction) {
    IconData icon = Icons.straight;
    if (instruction.contains('gauche')) icon = Icons.turn_left;
    if (instruction.contains('droite')) icon = Icons.turn_right;
    if (instruction.contains('demi-tour')) icon = Icons.u_turn_left;
    if (instruction.contains('rond-point')) icon = Icons.roundabout_left;
    if (instruction.contains('arrivé')) icon = Icons.flag;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }

  Widget _buildStepIndicator(int index) {
    final isCompleted = index <= _currentStep;
    final isCurrent = index == _currentStep;
    return Column(
      children: [
        Container(
          width: isCurrent ? 40 : 32, height: isCurrent ? 40 : 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted ? const Color(0xFF2E7D32) : Colors.grey[300],
            border: isCurrent ? Border.all(color: const Color(0xFF2E7D32), width: 3) : null,
          ),
          child: Icon(isCompleted ? Icons.check : Icons.circle, color: Colors.white, size: isCurrent ? 20 : 16),
        ),
        const SizedBox(height: 4),
        Text(_steps[index], style: TextStyle(fontSize: 10, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal, color: isCompleted ? const Color(0xFF2E7D32) : Colors.grey)),
      ],
    );
  }

  Widget _buildDestinationCard() {
    final isPickup = _currentStep < 2;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: isPickup ? const Color(0xFFE65100) : const Color(0xFF1976D2), borderRadius: BorderRadius.circular(10)),
            child: Icon(isPickup ? Icons.restaurant : Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isPickup ? 'Restaurant Exemple' : 'Ahmed B.', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(isPickup ? 'Rue Didouche Mourad' : 'Rue des Frères Bouadou', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          IconButton(icon: Icon(Icons.phone, color: isPickup ? const Color(0xFFE65100) : const Color(0xFF1976D2)), onPressed: () => launchUrl(Uri.parse('tel:+213555123456'))),
        ],
      ),
    );
  }

  void _nextStep() async {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
      VoiceNavigationService.reset();
      
      if (_currentStep == 2) {
        if (_voiceEnabled) {
          await VoiceNavigationService.speak('Commande récupérée. Direction le client.');
        }
        await _calculateRoute();
      }
    } else {
      _showDeliveryComplete();
    }
  }

  void _showDeliveryComplete() async {
    if (_voiceEnabled) {
      await VoiceNavigationService.speak('Félicitations! Livraison terminée. Vous avez gagné 200 dinars.');
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(padding: const EdgeInsets.all(16), decoration: const BoxDecoration(color: Color(0xFF2E7D32), shape: BoxShape.circle), child: const Icon(Icons.check, color: Colors.white, size: 50)),
            const SizedBox(height: 16),
            const Text('Livraison terminée!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Vous avez gagné', style: TextStyle(color: Colors.grey)),
            const Text('200 DA', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
          ],
        ),
        actions: [SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pushNamedAndRemoveUntil(context, AppRouter.home, (route) => false), child: const Text('Retour')))],
      ),
    );
  }

  /// Signaler un problème
  void _reportProblem() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Signaler un problème', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildProblemOption(Icons.location_off, 'Adresse introuvable', 'address_not_found'),
            _buildProblemOption(Icons.person_off, 'Client injoignable', 'client_unreachable'),
            _buildProblemOption(Icons.restaurant, 'Problème restaurant', 'restaurant_issue'),
            _buildProblemOption(Icons.car_crash, 'Problème véhicule', 'vehicle_issue'),
            _buildProblemOption(Icons.help_outline, 'Autre problème', 'other'),
            const SizedBox(height: 16),
            const Text('Un admin sera notifié et vous contactera.', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildProblemOption(IconData icon, String label, String type) {
    return ListTile(
      leading: Icon(icon, color: Colors.orange),
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        _submitProblem(type, label);
      },
    );
  }

  Future<void> _submitProblem(String type, String label) async {
    // TODO: Envoyer à l'API pour créer un incident
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Problème signalé: $label'),
        backgroundColor: Colors.orange,
        action: SnackBarAction(
          label: 'Appeler support',
          textColor: Colors.white,
          onPressed: () => launchUrl(Uri.parse('tel:+213555000000')),
        ),
      ),
    );
  }
}
