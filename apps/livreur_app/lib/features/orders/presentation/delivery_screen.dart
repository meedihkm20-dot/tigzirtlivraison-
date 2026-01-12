import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/osm_map.dart';
import '../../../core/services/location_service.dart';

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
  
  // Positions simulées (Alger)
  LatLng _currentPosition = const LatLng(36.7538, 3.0588);
  final LatLng _restaurantPosition = const LatLng(36.7520, 3.0420);
  final LatLng _clientPosition = const LatLng(36.7600, 3.0700);

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final pos = await LocationService.getCurrentLocation();
    if (pos != null && mounted) {
      setState(() => _currentPosition = pos);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Livraison en cours')),
      body: Column(
        children: [
          SizedBox(
            height: 280,
            child: OsmMap(
              center: _currentPosition,
              zoom: 14,
              controller: _mapController,
              markers: [
                MapMarkers.livreur(_currentPosition),
                MapMarkers.restaurant(_restaurantPosition),
                MapMarkers.client(_clientPosition),
              ],
              polylines: [
                Polyline(
                  points: [_currentPosition, _currentStep < 2 ? _restaurantPosition : _clientPosition],
                  color: const Color(0xFF2E7D32),
                  strokeWidth: 4,
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(_steps.length, (i) => _buildStepIndicator(i)),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openNavigation,
                          icon: const Icon(Icons.navigation),
                          label: const Text('Navigation'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
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
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int index) {
    final isCompleted = index <= _currentStep;
    return Column(
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(shape: BoxShape.circle, color: isCompleted ? const Color(0xFF2E7D32) : Colors.grey[300]),
          child: Icon(isCompleted ? Icons.check : Icons.circle, color: Colors.white, size: 18),
        ),
        const SizedBox(height: 4),
        Text(_steps[index], style: TextStyle(fontSize: 9, color: isCompleted ? const Color(0xFF2E7D32) : Colors.grey)),
      ],
    );
  }

  Widget _buildInfoCard() {
    final isPickup = _currentStep < 2;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(
        children: [
          Row(
            children: [
              Icon(isPickup ? Icons.restaurant : Icons.person, color: const Color(0xFF2E7D32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isPickup ? 'Restaurant Exemple' : 'Ahmed B.', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(isPickup ? '+213 555 111 222' : '+213 555 123 456', style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.phone, color: Color(0xFF2E7D32)), onPressed: () {}),
            ],
          ),
          const Divider(),
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.grey),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isPickup ? 'Rue Didouche Mourad, Alger Centre' : 'Rue des Frères Bouadou, Bir Mourad Raïs',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openNavigation() {
    final dest = _currentStep < 2 ? _restaurantPosition : _clientPosition;
    // Ouvre l'app de navigation externe
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navigation vers: ${dest.latitude}, ${dest.longitude}')),
    );
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      _showDeliveryComplete();
    }
  }

  void _showDeliveryComplete() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Livraison terminée!'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 80),
            SizedBox(height: 16),
            Text('Vous avez gagné 200 DA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, AppRouter.home, (route) => false),
            child: const Text('Retour'),
          ),
        ],
      ),
    );
  }
}
