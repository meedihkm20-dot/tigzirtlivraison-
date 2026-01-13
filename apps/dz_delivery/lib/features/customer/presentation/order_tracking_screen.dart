import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/router/app_router.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  Map<String, dynamic>? _order;
  bool _isLoading = true;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _loadOrder();
    _subscribeToUpdates();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
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

  void _subscribeToUpdates() {
    _channel = SupabaseService.subscribeToOrder(widget.orderId, (update) {
      _loadOrder();
    });
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

    return Scaffold(
      appBar: AppBar(title: Text('Commande #${_order!['order_number'] ?? ''}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status tracker
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
                  _buildStatusStep('En livraison', 'Le livreur est en route', 5, currentStep),
                  _buildStatusStep('Livrée', 'Bon appétit!', 6, currentStep, isLast: true),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Restaurant info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.restaurant, color: Colors.grey),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_order!['restaurant']?['name'] ?? 'Restaurant', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(_order!['restaurant']?['address'] ?? '', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Delivery address
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.location_on, color: Colors.green),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Adresse de livraison', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(_order!['delivery_address'] ?? '', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Order summary
            const Text('Récapitulatif', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...(_order!['order_items'] as List? ?? []).map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${item['quantity']}x ${item['name']}'),
                  Text('${((item['price'] ?? 0) * (item['quantity'] ?? 1)).toStringAsFixed(0)} DA'),
                ],
              ),
            )),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text('${_order!['total']?.toStringAsFixed(0) ?? 0} DA', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusStep(String title, String subtitle, int step, int currentStep, {bool isLast = false}) {
    final isCompleted = step <= currentStep;
    final isCurrent = step == currentStep;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: isCompleted ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? Colors.green : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal, color: isCompleted ? Colors.black : Colors.grey)),
                Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
