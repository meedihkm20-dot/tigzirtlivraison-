import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/widgets/osm_map.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  Map<String, dynamic>? _order;
  bool _isLoading = true;
  RealtimeChannel? _orderChannel;
  RealtimeChannel? _locationChannel;
  
  LatLng? _livreurPosition;
  LatLng? _restaurantPosition;
  LatLng? _clientPosition;
  String? _confirmationCode;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  @override
  void dispose() {
    _orderChannel?.unsubscribe();
    _locationChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadOrder() async {
    try {
      final order = await SupabaseService.getOrder(widget.orderId);
      if (mounted && order != null) {
        setState(() {
          _order = order;
          _isLoading = false;
          
          // Code de confirmation
          _confirmationCode = order['confirmation_code'];
          
          // Position restaurant
          final restaurant = order['restaurant'] as Map<String, dynamic>?;
          if (restaurant != null) {
            _restaurantPosition = LatLng(
              (restaurant['latitude'] as num?)?.toDouble() ?? 36.8869,
              (restaurant['longitude'] as num?)?.toDouble() ?? 4.1260,
            );
          }
          
          // Position client (livraison)
          _clientPosition = LatLng(
            (order['delivery_latitude'] as num?)?.toDouble() ?? 36.8869,
            (order['delivery_longitude'] as num?)?.toDouble() ?? 4.1260,
          );
          
          // Position livreur
          final livreur = order['livreur'] as Map<String, dynamic>?;
          if (livreur != null) {
            _livreurPosition = LatLng(
              (livreur['current_latitude'] as num?)?.toDouble() ?? 36.8869,
              (livreur['current_longitude'] as num?)?.toDouble() ?? 4.1260,
            );
          }
        });
        
        _subscribeToUpdates();
      }
    } catch (e) {
      debugPrint('Erreur chargement commande: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _subscribeToUpdates() {
    // S'abonner aux mises à jour de la commande
    _orderChannel = SupabaseService.subscribeToOrder(widget.orderId, (update) {
      _loadOrder();
    });
    
    // S'abonner à la position du livreur si assigné
    final livreur = _order?['livreur'] as Map<String, dynamic>?;
    if (livreur != null) {
      _locationChannel = SupabaseService.subscribeToLivreurLocation(
        livreur['id'],
        widget.orderId,
        (lat, lng) {
          if (mounted) {
            setState(() {
              _livreurPosition = LatLng(lat, lng);
            });
          }
        },
      );
    }
  }

  void _copyCode() {
    if (_confirmationCode != null) {
      Clipboard.setData(ClipboardData(text: _confirmationCode!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code copié!'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_order == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Commande non trouvée')),
      );
    }

    final status = _order!['status'] as String?;
    final steps = ['pending', 'confirmed', 'preparing', 'ready', 'picked_up', 'delivering', 'delivered'];
    final currentStep = steps.indexOf(status ?? 'pending');
    final showCode = ['picked_up', 'delivering'].contains(status);

    return Scaffold(
      appBar: AppBar(
        title: Text('Commande #${_order!['order_number'] ?? ''}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrder,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Carte
            SizedBox(
              height: 220,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _livreurPosition ?? _restaurantPosition ?? const LatLng(36.8869, 4.1260),
                      initialZoom: 14,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.dzdelivery.customer',
                      ),
                      MarkerLayer(
                        markers: [
                          if (_restaurantPosition != null) MapMarkers.restaurant(_restaurantPosition!),
                          if (_clientPosition != null) MapMarkers.destination(_clientPosition!),
                          if (_livreurPosition != null) MapMarkers.livreur(_livreurPosition!),
                        ],
                      ),
                      if (_livreurPosition != null && _clientPosition != null)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: [_livreurPosition!, _clientPosition!],
                              color: const Color(0xFFFF6B35),
                              strokeWidth: 3,
                            ),
                          ],
                        ),
                    ],
                  ),
                  // Bouton recentrer
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: FloatingActionButton.small(
                      heroTag: 'center',
                      backgroundColor: Colors.white,
                      onPressed: () {
                        if (_livreurPosition != null) {
                          _mapController.move(_livreurPosition!, 15);
                        }
                      },
                      child: const Icon(Icons.my_location, color: Color(0xFFFF6B35)),
                    ),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CODE PIN - TRÈS VISIBLE
                  if (showCode && _confirmationCode != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B35), Color(0xFFFF8F5C)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF6B35).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.lock, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'CODE DE CONFIRMATION',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: _copyCode,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _confirmationCode!,
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 8,
                                      color: Color(0xFFFF6B35),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.copy, color: Color(0xFFFF6B35)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Donnez ce code au livreur à la réception',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  
                  // Statut
                  const Text('Statut de la commande', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                    ),
                    child: Column(
                      children: [
                        _buildStatusStep('En attente', 'Le restaurant a reçu votre commande', 0, currentStep),
                        _buildStatusStep('Confirmée', 'Le restaurant prépare votre commande', 1, currentStep),
                        _buildStatusStep('En préparation', 'Votre commande est en cours de préparation', 2, currentStep),
                        _buildStatusStep('Prête', 'En attente du livreur', 3, currentStep),
                        _buildStatusStep('Récupérée', 'Le livreur a récupéré votre commande', 4, currentStep),
                        _buildStatusStep('En livraison', 'Le livreur est en route vers vous', 5, currentStep),
                        _buildStatusStep('Livrée', 'Commande livrée! Bon appétit!', 6, currentStep, isLast: true),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Livreur
                  if (_order!['livreur'] != null) _buildLivreurCard(),
                  
                  const SizedBox(height: 16),
                  
                  // Détails commande
                  _buildOrderDetails(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusStep(String title, String subtitle, int stepIndex, int currentStep, {bool isLast = false}) {
    final isCompleted = stepIndex <= currentStep;
    final isActive = stepIndex == currentStep;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? const Color(0xFFFF6B35) : Colors.grey[300],
                border: isActive ? Border.all(color: const Color(0xFFFF6B35), width: 3) : null,
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? const Color(0xFFFF6B35) : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isCompleted ? Colors.black : Colors.grey,
                    fontSize: isActive ? 16 : 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLivreurCard() {
    final livreur = _order!['livreur'] as Map<String, dynamic>;
    final profile = livreur['profile'] as Map<String, dynamic>?;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: const Color(0xFF2E7D32),
            child: Text(
              (profile?['full_name'] ?? 'L')[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile?['full_name'] ?? 'Livreur',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                    Text(
                      ' ${(livreur['rating'] ?? 4.5).toStringAsFixed(1)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    Text(
                      ' • ${livreur['vehicle_type'] ?? 'Moto'}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.phone, color: Color(0xFFFF6B35)),
            onPressed: () {
              final phone = profile?['phone'];
              if (phone != null) {
                // TODO: Appeler le livreur
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetails() {
    final items = _order!['order_items'] as List? ?? [];
    final restaurant = _order!['restaurant'] as Map<String, dynamic>?;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.restaurant, color: Color(0xFFFF6B35)),
              const SizedBox(width: 8),
              Text(
                restaurant?['name'] ?? 'Restaurant',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const Divider(height: 24),
          ...items.map((item) => _buildItemRow(item)),
          const Divider(height: 24),
          _buildPriceRow('Sous-total', '${(_order!['subtotal'] as num?)?.toStringAsFixed(0) ?? 0} DA'),
          _buildPriceRow('Livraison', '${(_order!['delivery_fee'] as num?)?.toStringAsFixed(0) ?? 0} DA'),
          const SizedBox(height: 8),
          _buildPriceRow('Total', '${(_order!['total'] as num?)?.toStringAsFixed(0) ?? 0} DA', isBold: true),
        ],
      ),
    );
  }

  Widget _buildItemRow(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '${item['quantity'] ?? 1}',
                style: const TextStyle(
                  color: Color(0xFFFF6B35),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(item['name'] ?? '')),
          Text('${((item['price'] as num?) ?? 0) * ((item['quantity'] as num?) ?? 1)} DA'),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? const Color(0xFFFF6B35) : null,
              fontSize: isBold ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
