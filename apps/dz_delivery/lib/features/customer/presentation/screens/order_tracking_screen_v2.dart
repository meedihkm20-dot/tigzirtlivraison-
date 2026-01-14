import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/design_system/theme/app_colors.dart';
import '../../../../core/design_system/theme/app_typography.dart';
import '../../../../core/design_system/theme/app_spacing.dart';
import '../../../../core/design_system/theme/app_shadows.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/router/app_router.dart';

/// Écran Suivi Commande V2 - Premium
/// Carte OSM temps réel, timeline, chat livreur, ETA dynamique
class OrderTrackingScreenV2 extends StatefulWidget {
  final String orderId;
  
  const OrderTrackingScreenV2({super.key, required this.orderId});

  @override
  State<OrderTrackingScreenV2> createState() => _OrderTrackingScreenV2State();
}

class _OrderTrackingScreenV2State extends State<OrderTrackingScreenV2> 
    with TickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic>? _order;
  Map<String, dynamic>? _livreur;
  LatLng? _livreurPosition;
  LatLng? _restaurantPosition;
  LatLng? _deliveryPosition;
  List<LatLng> _routePoints = [];
  
  late MapController _mapController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  StreamSubscription? _orderSubscription;
  StreamSubscription? _locationSubscription;
  Timer? _etaTimer;
  
  int _estimatedMinutes = 0;
  String _currentStatus = 'pending';
  
  final _statusSteps = [
    {'status': 'confirmed', 'label': 'Confirmée', 'icon': Icons.check_circle},
    {'status': 'preparing', 'label': 'En préparation', 'icon': Icons.restaurant},
    {'status': 'ready', 'label': 'Prête', 'icon': Icons.inventory_2},
    {'status': 'picked_up', 'label': 'En route', 'icon': Icons.delivery_dining},
    {'status': 'delivered', 'label': 'Livrée', 'icon': Icons.home},
  ];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _loadOrder();
    _subscribeToUpdates();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _orderSubscription?.cancel();
    _locationSubscription?.cancel();
    _etaTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrder() async {
    setState(() => _isLoading = true);
    try {
      final order = await SupabaseService.getOrderDetails(widget.orderId);
      
      if (order != null && mounted) {
        setState(() {
          _order = order;
          _currentStatus = order['status'] ?? 'pending';
          _estimatedMinutes = order['estimated_delivery_minutes'] ?? 30;
          
          // Parse positions
          if (order['restaurant_lat'] != null && order['restaurant_lng'] != null) {
            _restaurantPosition = LatLng(
              (order['restaurant_lat'] as num).toDouble(),
              (order['restaurant_lng'] as num).toDouble(),
            );
          }
          if (order['delivery_lat'] != null && order['delivery_lng'] != null) {
            _deliveryPosition = LatLng(
              (order['delivery_lat'] as num).toDouble(),
              (order['delivery_lng'] as num).toDouble(),
            );
          }
          
          // Livreur info
          if (order['livreur'] != null) {
            _livreur = order['livreur'];
            if (_livreur!['current_lat'] != null && _livreur!['current_lng'] != null) {
              _livreurPosition = LatLng(
                (_livreur!['current_lat'] as num).toDouble(),
                (_livreur!['current_lng'] as num).toDouble(),
              );
            }
          }
          
          _isLoading = false;
        });
        
        // Load route if livreur is on the way
        if (_livreurPosition != null && _deliveryPosition != null) {
          _loadRoute();
        }
      }
    } catch (e) {
      debugPrint('Erreur chargement commande: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _subscribeToUpdates() {
    // Subscribe to order status updates
    _orderSubscription = SupabaseService.subscribeToOrder(widget.orderId).listen((update) {
      if (mounted && update != null) {
        setState(() {
          _currentStatus = update['status'] ?? _currentStatus;
          _estimatedMinutes = update['estimated_delivery_minutes'] ?? _estimatedMinutes;
        });
        
        if (_currentStatus == 'delivered') {
          _showDeliveredDialog();
        }
      }
    });
    
    // Subscribe to livreur location updates
    _locationSubscription = SupabaseService.subscribeToLivreurLocation(widget.orderId).listen((location) {
      if (mounted && location != null) {
        setState(() {
          _livreurPosition = LatLng(
            (location['lat'] as num).toDouble(),
            (location['lng'] as num).toDouble(),
          );
        });
        _loadRoute();
      }
    });
    
    // Update ETA every minute
    _etaTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_estimatedMinutes > 0) {
        setState(() => _estimatedMinutes--);
      }
    });
  }

  Future<void> _loadRoute() async {
    if (_livreurPosition == null || _deliveryPosition == null) return;
    
    try {
      final route = await SupabaseService.getRoute(
        _livreurPosition!,
        _deliveryPosition!,
      );
      if (mounted && route.isNotEmpty) {
        setState(() => _routePoints = route);
      }
    } catch (e) {
      debugPrint('Erreur chargement route: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.clientPrimary))
          : Stack(
              children: [
                // Map
                _buildMap(),
                
                // Top bar
                _buildTopBar(),
                
                // Bottom sheet
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
            colors: [
              Colors.black.withOpacity(0.5),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppShadows.md,
                    ),
                    child: const Icon(Icons.arrow_back, size: 20),
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
                            color: AppColors.clientSurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getStatusIcon(_currentStatus),
                            color: AppColors.clientPrimary,
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
                                _getStatusLabel(_currentStatus),
                                style: AppTypography.labelMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Commande #${widget.orderId.substring(0, 8)}',
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
                  onTap: _centerOnLivreur,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppShadows.md,
                    ),
                    child: const Icon(Icons.my_location, size: 20, color: AppColors.clientPrimary),
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
    final center = _livreurPosition ?? _restaurantPosition ?? const LatLng(36.7538, 3.0588);
    
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 14,
        minZoom: 10,
        maxZoom: 18,
      ),
      children: [
        // OSM Tile Layer
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.dzdelivery.app',
        ),
        
        // Route polyline
        if (_routePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _routePoints,
                color: AppColors.clientPrimary,
                strokeWidth: 4,
              ),
            ],
          ),
        
        // Markers
        MarkerLayer(
          markers: [
            // Restaurant marker
            if (_restaurantPosition != null)
              Marker(
                point: _restaurantPosition!,
                width: 50,
                height: 50,
                child: _buildMarker(Icons.restaurant, AppColors.primary, 'Restaurant'),
              ),
            
            // Delivery marker
            if (_deliveryPosition != null)
              Marker(
                point: _deliveryPosition!,
                width: 50,
                height: 50,
                child: _buildMarker(Icons.home, AppColors.success, 'Livraison'),
              ),
            
            // Livreur marker (animated)
            if (_livreurPosition != null)
              Marker(
                point: _livreurPosition!,
                width: 60,
                height: 60,
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) => Transform.scale(
                    scale: _pulseAnimation.value,
                    child: _buildLivreurMarker(),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMarker(IconData icon, Color color, String label) {
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
        Container(
          width: 3,
          height: 10,
          color: color,
        ),
      ],
    );
  }

  Widget _buildLivreurMarker() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.livreurPrimary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.livreurPrimary.withOpacity(0.4),
            blurRadius: 12,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.delivery_dining,
          color: AppColors.livreurPrimary,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildBottomSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.2,
      maxChildSize: 0.8,
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
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // ETA Card
              _buildETACard(),
              
              // Timeline
              _buildTimeline(),
              
              // Livreur info
              if (_livreur != null) _buildLivreurCard(),
              
              // Order details
              _buildOrderDetails(),
              
              // Actions
              _buildActions(),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildETACard() {
    final isDelivered = _currentStatus == 'delivered';
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isDelivered ? AppColors.successGradient : AppColors.clientGradient,
        borderRadius: AppSpacing.borderRadiusLg,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isDelivered ? Icons.check_circle : Icons.access_time,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDelivered ? 'Livrée!' : 'Arrivée estimée',
                  style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  isDelivered 
                      ? 'Bon appétit! 🎉'
                      : '$_estimatedMinutes min',
                  style: AppTypography.headlineMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (!isDelivered && _livreur != null)
            GestureDetector(
              onTap: _callLivreur,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.phone, color: AppColors.clientPrimary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    final currentIndex = _statusSteps.indexWhere((s) => s['status'] == _currentStatus);
    
    return Padding(
      padding: AppSpacing.screenHorizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Suivi de commande', style: AppTypography.titleSmall),
          const SizedBox(height: 16),
          ...List.generate(_statusSteps.length, (index) {
            final step = _statusSteps[index];
            final isCompleted = index <= currentIndex;
            final isCurrent = index == currentIndex;
            final isLast = index == _statusSteps.length - 1;
            
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isCompleted ? AppColors.clientPrimary : AppColors.surfaceVariant,
                        shape: BoxShape.circle,
                        border: isCurrent 
                            ? Border.all(color: AppColors.clientPrimary, width: 3)
                            : null,
                      ),
                      child: Icon(
                        step['icon'] as IconData,
                        color: isCompleted ? Colors.white : AppColors.textTertiary,
                        size: 16,
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 30,
                        color: isCompleted ? AppColors.clientPrimary : AppColors.outline,
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step['label'] as String,
                          style: AppTypography.labelMedium.copyWith(
                            color: isCompleted ? AppColors.textPrimary : AppColors.textTertiary,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        if (isCurrent)
                          Text(
                            'En cours...',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.clientPrimary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLivreurCard() {
    return Container(
      margin: AppSpacing.screen,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: AppColors.livreurGradient,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                (_livreur!['full_name'] ?? 'L')[0].toUpperCase(),
                style: AppTypography.titleLarge.copyWith(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _livreur!['full_name'] ?? 'Livreur',
                  style: AppTypography.titleSmall,
                ),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${(_livreur!['rating'] ?? 4.5).toStringAsFixed(1)}',
                      style: AppTypography.bodySmall,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• ${_livreur!['total_deliveries'] ?? 0} livraisons',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Actions
          Row(
            children: [
              _buildLivreurAction(Icons.phone, _callLivreur),
              const SizedBox(width: 8),
              _buildLivreurAction(Icons.chat_bubble_outline, _openChat),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLivreurAction(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.livreurPrimary, size: 20),
      ),
    );
  }

  Widget _buildOrderDetails() {
    if (_order == null) return const SizedBox.shrink();
    
    final items = _order!['items'] as List<dynamic>? ?? [];
    final total = (_order!['total'] as num?)?.toDouble() ?? 0;
    
    return Container(
      margin: AppSpacing.screenHorizontal,
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
              Text('Détails commande', style: AppTypography.titleSmall),
              Text(
                '${total.toStringAsFixed(0)} DA',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.clientPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          ...items.take(3).map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.clientSurface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${item['quantity']}x',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.clientPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item['name'] ?? '',
                    style: AppTypography.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          )),
          if (items.length > 3)
            Text(
              '+${items.length - 3} autres articles',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
            ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: AppSpacing.screen,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _contactSupport,
              icon: const Icon(Icons.support_agent, color: AppColors.textSecondary),
              label: Text(
                'Support',
                style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.outline),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _shareTracking,
              icon: const Icon(Icons.share, color: AppColors.clientPrimary),
              label: Text(
                'Partager',
                style: AppTypography.labelMedium.copyWith(color: AppColors.clientPrimary),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.clientPrimary),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // HELPERS
  // ============================================
  
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'confirmed': return Icons.check_circle;
      case 'preparing': return Icons.restaurant;
      case 'ready': return Icons.inventory_2;
      case 'picked_up': return Icons.delivery_dining;
      case 'delivered': return Icons.home;
      default: return Icons.pending;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending': return 'En attente';
      case 'confirmed': return 'Confirmée';
      case 'preparing': return 'En préparation';
      case 'ready': return 'Prête';
      case 'picked_up': return 'En livraison';
      case 'delivered': return 'Livrée';
      case 'cancelled': return 'Annulée';
      default: return status;
    }
  }

  void _centerOnLivreur() {
    if (_livreurPosition != null) {
      _mapController.move(_livreurPosition!, 16);
    }
  }

  void _callLivreur() {
    HapticFeedback.lightImpact();
    // TODO: Implement call
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Appel du livreur...')),
    );
  }

  void _openChat() {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, AppRouter.chat, arguments: {
      'orderId': widget.orderId,
      'recipientName': _livreur?['full_name'] ?? 'Livreur',
      'isLivreur': false,
    });
  }

  void _contactSupport() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contact support...')),
    );
  }

  void _shareTracking() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lien de suivi copié!')),
    );
  }

  void _showDeliveredDialog() {
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
            Text('Commande livrée!', style: AppTypography.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Bon appétit! 🎉\nN\'oubliez pas de noter votre expérience.',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Plus tard'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, AppRouter.review, arguments: {
                'orderId': widget.orderId,
                'restaurantName': _order?['restaurant_name'] ?? '',
                'livreurName': _livreur?['full_name'] ?? '',
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.clientPrimary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Noter'),
          ),
        ],
      ),
    );
  }
}
