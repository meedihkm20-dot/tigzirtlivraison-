import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';

class RestaurantOrderDetailScreen extends StatefulWidget {
  final String orderId;
  const RestaurantOrderDetailScreen({super.key, required this.orderId});

  @override
  State<RestaurantOrderDetailScreen> createState() => _RestaurantOrderDetailScreenState();
}

class _RestaurantOrderDetailScreenState extends State<RestaurantOrderDetailScreen> {
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_order == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('Commande non trouvée')));

    final items = _order!['order_items'] as List? ?? [];

    return Scaffold(
      appBar: AppBar(title: Text('Commande #${_order!['order_number'] ?? ''}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Articles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                    child: Center(child: Text('${item['quantity']}', style: const TextStyle(fontWeight: FontWeight.bold))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(item['name'] ?? '')),
                  Text('${((item['price'] ?? 0) * (item['quantity'] ?? 1)).toStringAsFixed(0)} DA'),
                ],
              ),
            )),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('${_order!['total']?.toStringAsFixed(0) ?? 0} DA', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Client', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(_order!['customer']?['full_name'] ?? 'Client'),
              subtitle: Text(_order!['customer']?['phone'] ?? ''),
            ),
            const SizedBox(height: 16),
            const Text('Adresse de livraison', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_order!['delivery_address'] ?? '')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
