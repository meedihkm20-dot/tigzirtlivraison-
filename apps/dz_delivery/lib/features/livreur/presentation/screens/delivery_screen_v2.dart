import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/design_system/theme/app_colors.dart';
import '../../../../core/design_system/theme/app_typography.dart';
import '../../../../core/design_system/theme/app_spacing.dart';
import '../../../../core/design_system/theme/app_shadows.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/backend_api_service.dart';
import '../../../../core/services/voice_navigation_service.dart';

/// Écran Livraison V2 - Premium
/// Navigation OSM temps réel, instructions vocales, code confirmation
class DeliveryScreenV2 extends StatefulWidget {
  final String orderId;
  
  const DeliveryScreenV2({super.key, required this.orderId});

  @override
  State<DeliveryScreenV2> createState() => _DeliveryScreenV2State();
}

class _DeliveryScreenV2State extends State<DeliveryScreenV2>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic>? _order;
  
  LatLng? _currentPosition;
  LatLng? _restaurantPosition;
  LatLng? _deliveryPosition;
  List<LatLng> _routePoints = [];
  
  String _currentStep = 'pickup'; // pickup, delivery
  int _etaMinutes = 0;
  double _distanceKm = 0;
  String _nextInstruction = '';
  
  late MapController _mapController;
  late AnimationController _pulseController;
  StreamSubscription<Position>? _positionStream;
  Timer? _locationUpdateTimer;
  NavigationTracker? _navigationTracker;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    // Initialiser la navigation vocale
    VoiceNavigationService.init();
    
    _loadOrder();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _positionStream?.cancel();
    _locationUpdateTimer?.cancel();
    VoiceNavigationService.stop();
    super.dispose();
  }


  Future<void> _loadOrder() async {
    setState(() => _isLoading = true);
    try {
      final order = await SupabaseService.getOrderDetails(widget.orderId);
      
      if (order != null && mounted) {
        setState(() {
          _order = order;
          _currentStep = order['status'] == 'picked_up' ? 'delivery' : 'pickup';
          
          // ⚠️ Utilise les noms SQL corrects
          final restaurant = order['restaurant'];
          if (restaurant != null && restaurant['latitude'] != null) {
            _restaurantPosition = LatLng(
              (restaurant['latitude'] as num).toDouble(),
              (restaurant['longitude'] as num).toDouble(),
            );
          }
          if (order['delivery_latitude'] != null) {
            _deliveryPosition = LatLng(
              (order['delivery_latitude'] as num).toDouble(),
              (order['delivery_longitude'] as num).toDouble(),
            );
          }
          _isLoading = false;
        });
        _loadRoute();
      }
    } catch (e) {
      debugPrint('Erreur: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startLocationTracking() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });
        
        // Mettre à jour le tracker de navigation
        _navigationTracker?.updatePosition(_currentPosition!);
        
        _updateLocationOnServer();
        
        // Recharger la route seulement si nécessaire (pas à chaque position)
        if (_routePoints.isEmpty) {
          _loadRoute();
        }
      }
    });

    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updateLocationOnServer();
    });
  }

  void _updateLocationOnServer() async {
    if (_currentPosition == null) return;
    await SupabaseService.updateLivreurLocation(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );
  }

  Future<void> _loadRoute() async {
    if (_currentPosition == null) return;
    
    final destination = _currentStep == 'pickup' ? _restaurantPosition : _deliveryPosition;
    if (destination == null) return;

    try {
      final route = await RoutingService.getRoute(_currentPosition!, destination);
      
      if (route != null && mounted) {
        setState(() {
          _routePoints = route.points;
          _etaMinutes = (route.durationSeconds / 60).round();
          _distanceKm = route.distanceMeters / 1000;
          _nextInstruction = route.steps.isNotEmpty ? route.steps.first.instruction : 'Continuez tout droit';
        });

        // Initialiser le tracker de navigation
        _navigationTracker = NavigationTracker(
          route: route,
          destination: destination,
          destinationType: _currentStep,
          onRerouteNeeded: () {
            VoiceNavigationService.announceRerouting(reason: 'Écart de route détecté');
            _loadRoute(); // Recalculer la route
          },
          onStepChanged: (stepIndex) {
            if (route.steps.isNotEmpty && stepIndex < route.steps.length) {
              final step = route.steps[stepIndex];
              setState(() => _nextInstruction = step.instruction);
              VoiceNavigationService.checkAndAnnounce(
                currentPosition: _currentPosition!,
                route: route,
                currentStepIndex: stepIndex,
                destinationType: _currentStep,
              );
            }
          },
          onArrival: () {
            VoiceNavigationService.announceArrival(
              _currentStep,
              locationName: _currentStep == 'pickup' 
                  ? _order?['restaurant_name'] 
                  : _order?['customer_name'],
            );
          },
          onTimingAlert: (alertType, minutes) {
            VoiceNavigationService.announceTimingAlert(alertType, minutes);
          },
          onTrafficAlert: (alertType) {
            VoiceNavigationService.announceTrafficAlert(alertType);
          },
        );
      }
    } catch (e) {
      debugPrint('Erreur route: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.livreurPrimary))
          : Stack(
              children: [
                _buildMap(),
                _buildTopBar(),
                _buildNavigationCard(),
                _buildBottomSheet(),
              ],
            ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.6), Colors.transparent],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _showExitConfirmation(),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppShadows.md,
                    ),
                    child: const Icon(Icons.close, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppShadows.md,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _currentStep == 'pickup' 
                                ? AppColors.primarySurface 
                                : AppColors.successSurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _currentStep == 'pickup' ? Icons.restaurant : Icons.home,
                            color: _currentStep == 'pickup' 
                                ? AppColors.primary 
                                : AppColors.success,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currentStep == 'pickup' 
                                    ? 'Récupération' 
                                    : 'Livraison',
                                style: AppTypography.labelMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _currentStep == 'pickup'
                                    ? (_order?['restaurant_name'] as String? ?? '')
                                    : (_order?['customer_name'] as String? ?? 'Client'),
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _centerOnMe,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppShadows.md,
                    ),
                    child: const Icon(Icons.my_location, size: 20, color: AppColors.livreurPrimary),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      VoiceNavigationService.setEnabled(!VoiceNavigationService.isEnabled);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(VoiceNavigationService.isEnabled 
                            ? 'Navigation vocale activée' 
                            : 'Navigation vocale désactivée'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: VoiceNavigationService.isEnabled ? AppColors.success : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppShadows.md,
                    ),
                    child: Icon(
                      VoiceNavigationService.isEnabled ? Icons.volume_up : Icons.volume_off,
                      size: 20,
                      color: VoiceNavigationService.isEnabled ? Colors.white : AppColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMap() {
    final center = _currentPosition ?? _restaurantPosition ?? const LatLng(36.7538, 3.0588);
    
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 15,
        minZoom: 10,
        maxZoom: 18,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.dzdelivery.app',
        ),
        if (_routePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _routePoints,
                color: AppColors.livreurPrimary,
                strokeWidth: 5,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            if (_restaurantPosition != null)
              Marker(
                point: _restaurantPosition!,
                width: 50,
                height: 50,
                child: _buildMarker(Icons.restaurant, AppColors.primary),
              ),
            if (_deliveryPosition != null)
              Marker(
                point: _deliveryPosition!,
                width: 50,
                height: 50,
                child: _buildMarker(Icons.home, AppColors.success),
              ),
            if (_currentPosition != null)
              Marker(
                point: _currentPosition!,
                width: 60,
                height: 60,
                child: _buildCurrentLocationMarker(),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMarker(IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: AppShadows.md,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        Container(width: 3, height: 10, color: color),
      ],
    );
  }

  Widget _buildCurrentLocationMarker() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) => Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.livreurPrimary.withOpacity(0.3 * _pulseController.value),
              blurRadius: 20 * _pulseController.value,
              spreadRadius: 10 * _pulseController.value,
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.livreurPrimary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: const Icon(Icons.navigation, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  Widget _buildNavigationCard() {
    return Positioned(
      top: 120,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.livreurPrimary,
          borderRadius: AppSpacing.borderRadiusLg,
          boxShadow: AppShadows.lg,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.navigation, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _nextInstruction,
                    style: AppTypography.titleSmall.copyWith(color: Colors.white),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${_distanceKm.toStringAsFixed(1)} km',
                        style: AppTypography.labelMedium.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '~$_etaMinutes min',
                        style: AppTypography.labelMedium.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.volume_up, color: Colors.white),
              onPressed: _speakInstruction,
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildBottomSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.15,
      maxChildSize: 0.6,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: AppShadows.lg,
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _buildStepIndicator(),
              _buildDestinationInfo(),
              _buildOrderInfo(),
              _buildActionButtons(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStepDot('1', 'Récupérer', _currentStep == 'pickup' || _currentStep == 'delivery'),
          Expanded(
            child: Container(
              height: 2,
              color: _currentStep == 'delivery' ? AppColors.success : AppColors.outline,
            ),
          ),
          _buildStepDot('2', 'Livrer', _currentStep == 'delivery'),
        ],
      ),
    );
  }

  Widget _buildStepDot(String number, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? AppColors.livreurPrimary : AppColors.surfaceVariant,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isActive && number == '1' && _currentStep == 'delivery'
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
                    number,
                    style: AppTypography.labelMedium.copyWith(
                      color: isActive ? Colors.white : AppColors.textTertiary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isActive ? AppColors.livreurPrimary : AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildDestinationInfo() {
    final isPickup = _currentStep == 'pickup';
    final name = isPickup 
        ? (_order?['restaurant_name'] as String? ?? 'Restaurant')
        : (_order?['customer_name'] as String? ?? 'Client');
    final address = isPickup
        ? (_order?['restaurant_address'] as String? ?? '')
        : (_order?['delivery_address'] as String? ?? '');
    final phone = isPickup
        ? (_order?['restaurant_phone'] as String?)
        : (_order?['customer_phone'] as String?);

    return Container(
      margin: AppSpacing.screenHorizontal,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isPickup ? AppColors.primarySurface : AppColors.successSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isPickup ? Icons.restaurant : Icons.home,
                  color: isPickup ? AppColors.primary : AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTypography.titleSmall),
                    Text(
                      address,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (phone != null) ...[
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _callContact(phone),
                    icon: const Icon(Icons.phone, size: 18),
                    label: const Text('Appeler'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.livreurPrimary,
                      side: const BorderSide(color: AppColors.livreurPrimary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openChat,
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text('Message'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.livreurPrimary,
                      side: const BorderSide(color: AppColors.livreurPrimary),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderInfo() {
    final items = _order?['items'] as List<dynamic>? ?? [];
    final total = (_order?['total'] as num?)?.toDouble() ?? 0;
    final note = _order?['delivery_instructions'];

    return Container(
      margin: AppSpacing.screen,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Commande', style: AppTypography.titleSmall),
              Text(
                '${total.toStringAsFixed(0)} DA',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.livreurPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          ...items.take(3).map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Text('${item['quantity']}x ', style: AppTypography.labelMedium),
                Expanded(child: Text(item['name'] ?? '', style: AppTypography.bodyMedium)),
              ],
            ),
          )),
          if (items.length > 3)
            Text(
              '+${items.length - 3} autres',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
            ),
          if (note != null && note.isNotEmpty) ...[
            const Divider(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warningSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.note_alt, size: 20, color: AppColors.warning),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Note du client',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          note,
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: AppSpacing.screenHorizontal,
      child: Column(
        children: [
          if (_currentStep == 'pickup')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _confirmPickup,
                icon: const Icon(Icons.check_circle),
                label: const Text('Commande récupérée'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusLg),
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showConfirmationDialog,
                icon: const Icon(Icons.check_circle),
                label: const Text('Confirmer la livraison'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusLg),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _reportProblem,
                  icon: const Icon(Icons.warning_amber, color: AppColors.warning),
                  label: Text(
                    'Problème',
                    style: TextStyle(color: AppColors.warning),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.warning),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openNavigation,
                  icon: const Icon(Icons.directions, color: AppColors.livreurPrimary),
                  label: Text(
                    'Navigation',
                    style: TextStyle(color: AppColors.livreurPrimary),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.livreurPrimary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================
  // ACTIONS
  // ============================================

  void _centerOnMe() {
    if (_currentPosition != null) {
      _mapController.move(_currentPosition!, 16);
    }
  }

  void _speakInstruction() {
    HapticFeedback.lightImpact();
    VoiceNavigationService.speak(_nextInstruction);
  }

  void _callContact(String phone) async {
    HapticFeedback.lightImpact();
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossible de lancer l\'appel')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _openChat() {
    Navigator.pushNamed(
      context,
      AppRouter.deliveryChat,
      arguments: {
        'orderId': widget.orderId,
        'recipientName': _currentStep == 'pickup' 
            ? (_order?['restaurant_name'] as String? ?? 'Restaurant')
            : (_order?['customer_name'] as String? ?? 'Client'),
        'recipientType': _currentStep == 'pickup' ? 'restaurant' : 'customer',
      },
    );
  }

  void _confirmPickup() async {
    HapticFeedback.heavyImpact();
    try {
      final backendApi = BackendApiService(SupabaseService.client);
      await backendApi.changeOrderStatus(widget.orderId, 'picked_up');
      
      // Annoncer le changement de statut
      VoiceNavigationService.announceDeliveryStatus('picked_up');
      
      setState(() => _currentStep = 'delivery');
      VoiceNavigationService.reset(); // Reset pour la nouvelle étape
      _loadRoute();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Commande récupérée! En route vers le client 🚀'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  void _showConfirmationDialog() {
    final codeController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Code de confirmation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Demandez le code au client pour confirmer la livraison',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: AppTypography.headlineMedium,
              decoration: InputDecoration(
                hintText: '0000',
                counterText: '',
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _confirmDelivery(codeController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _confirmDelivery(String code) async {
    HapticFeedback.heavyImpact();
    try {
      await SupabaseService.confirmDelivery(widget.orderId, code);
      
      // Annoncer la livraison terminée
      VoiceNavigationService.announceDeliveryStatus('delivered');
      
      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Code incorrect ou erreur: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.successSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: AppColors.success, size: 60),
            ),
            const SizedBox(height: 20),
            Text('Livraison terminée!', style: AppTypography.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Bravo! 🎉\n+${(_order?['delivery_fee'] ?? 200).toStringAsFixed(0)} DA',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacementNamed(context, AppRouter.livreurHome);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.livreurPrimary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Retour à l\'accueil'),
          ),
        ],
      ),
    );
  }

  void _reportProblem() {
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
            Text('Signaler un problème', style: AppTypography.titleMedium),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.location_off, color: AppColors.warning),
              title: const Text('Adresse introuvable'),
              onTap: () => _submitProblem('address_not_found'),
            ),
            ListTile(
              leading: const Icon(Icons.phone_disabled, color: AppColors.warning),
              title: const Text('Client injoignable'),
              onTap: () => _submitProblem('customer_unreachable'),
            ),
            ListTile(
              leading: const Icon(Icons.restaurant, color: AppColors.warning),
              title: const Text('Problème avec la commande'),
              onTap: () => _submitProblem('order_issue'),
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: AppColors.error),
              title: Text('Annuler la livraison', style: TextStyle(color: AppColors.error)),
              onTap: () => _cancelDelivery(),
            ),
          ],
        ),
      ),
    );
  }

  void _submitProblem(String type) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Problème signalé au support')),
    );
  }

  void _cancelDelivery() async {
    Navigator.pop(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler la livraison?'),
        content: const Text('Cette action peut affecter votre note.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Non')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Oui, annuler', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await SupabaseService.cancelDelivery(widget.orderId);
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRouter.livreurHome);
      }
    }
  }

  void _openNavigation() {
    HapticFeedback.lightImpact();
    // TODO: Open external navigation app
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ouverture de la navigation...')),
    );
  }

  void _showExitConfirmation() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitter la navigation?'),
        content: const Text('Vous avez une livraison en cours.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Rester')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Quitter')),
        ],
      ),
    );
    
    if (confirm == true && mounted) {
      Navigator.pop(context);
    }
  }
}
