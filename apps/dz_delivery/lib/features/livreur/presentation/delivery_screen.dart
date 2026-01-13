import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';
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

  @override
  void initState() {
    super.initState();
    _loadOrder();
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

  Future<void> _startDelivery() async {
    await SupabaseService.updateOrderStatus(widget.orderId, 'delivering');
    _loadOrder();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Livraison démarrée'), backgroundColor: Colors.blue));
  }

  Future<void> _completeDelivery() async {
    await SupabaseService.updateOrderStatus(widget.orderId, 'delivered');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Livraison terminée!'), backgroundColor: Colors.green));
    Navigator.pushReplacementNamed(context, AppRouter.livreurHome);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_order == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('Commande non trouvée')));

    final status = _order!['status'] as String?;
    final isDelivering = status == 'delivering';

    return Scaffold(
      appBar: AppBar(title: Text('Livraison #${_order!['order_number'] ?? ''}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDelivering ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(isDelivering ? Icons.delivery_dining : Icons.restaurant, color: isDelivering ? Colors.blue : Colors.orange, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isDelivering ? 'En route vers le client' : 'Récupérer la commande', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(isDelivering ? 'Dirigez-vous vers l\'adresse de livraison' : 'Rendez-vous au restaurant', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Restaurant
            const Text('Restaurant', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
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
                  IconButton(icon: const Icon(Icons.phone, color: Colors.green), onPressed: () {}),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Client
            const Text('Client', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
              child: Column(
                children: [
                  Row(
                    children: [
                      const CircleAvatar(child: Icon(Icons.person)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_order!['customer']?['full_name'] ?? 'Client', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(_order!['customer']?['phone'] ?? '', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          ],
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.phone, color: Colors.green), onPressed: () {}),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_order!['delivery_address'] ?? '', style: TextStyle(color: Colors.grey[600]))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Montant
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Montant à collecter', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('${_order!['total']?.toStringAsFixed(0) ?? 0} DA', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: isDelivering ? _completeDelivery : _startDelivery,
              style: ElevatedButton.styleFrom(backgroundColor: isDelivering ? Colors.green : Colors.blue),
              child: Text(isDelivering ? 'Livraison terminée' : 'Démarrer la livraison', style: const TextStyle(fontSize: 16)),
            ),
          ),
        ),
      ),
    );
  }
}
