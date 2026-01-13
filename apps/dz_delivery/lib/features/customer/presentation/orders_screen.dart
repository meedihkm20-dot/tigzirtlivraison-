import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/router/app_router.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final orders = await SupabaseService.getCustomerOrders();
      setState(() => _orders = orders);
    } catch (e) {
      debugPrint('Erreur: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes commandes')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('Aucune commande', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders.length,
                    itemBuilder: (context, index) => _buildOrderCard(_orders[index]),
                  ),
                ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] as String?;
    final statusInfo = _getStatusInfo(status);
    
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRouter.orderTracking, arguments: order['id']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('#${order['order_number'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: statusInfo['color'].withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(statusInfo['text'], style: TextStyle(color: statusInfo['color'], fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.restaurant, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(order['restaurant']?['name'] ?? 'Restaurant', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${order['total']?.toStringAsFixed(0) ?? 0} DA', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(_formatDate(order['created_at']), style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(String? status) {
    switch (status) {
      case 'pending': return {'text': 'En attente', 'color': Colors.orange};
      case 'confirmed': return {'text': 'Confirmée', 'color': Colors.blue};
      case 'preparing': return {'text': 'En préparation', 'color': Colors.purple};
      case 'ready': return {'text': 'Prête', 'color': Colors.teal};
      case 'picked_up': return {'text': 'Récupérée', 'color': Colors.indigo};
      case 'delivering': return {'text': 'En livraison', 'color': Colors.blue};
      case 'delivered': return {'text': 'Livrée', 'color': Colors.green};
      case 'cancelled': return {'text': 'Annulée', 'color': Colors.red};
      default: return {'text': status ?? '', 'color': Colors.grey};
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.parse(dateStr);
    return '${date.day}/${date.month}/${date.year}';
  }
}
