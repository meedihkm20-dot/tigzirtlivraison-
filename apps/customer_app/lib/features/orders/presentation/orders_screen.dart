import 'package:flutter/material.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/supabase_service.dart';

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
      final orders = await SupabaseService.getMyOrders();
      setState(() => _orders = orders);
    } catch (e) {
      debugPrint('Erreur chargement commandes: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes Commandes')),
      body: RefreshIndicator(
        onRefresh: _loadOrders,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _orders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('Aucune commande', style: TextStyle(color: Colors.grey[600], fontSize: 18)),
                        const SizedBox(height: 8),
                        Text('Vos commandes apparaîtront ici', style: TextStyle(color: Colors.grey[400])),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders.length,
                    itemBuilder: (context, index) => _buildOrderCard(context, _orders[index]),
                  ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Map<String, dynamic> order) {
    final statusInfo = _getStatusInfo(order['status']);
    final orderItems = order['order_items'] as List? ?? [];
    final itemCount = orderItems.fold<int>(0, (sum, item) => sum + ((item['quantity'] as int?) ?? 1));
    
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRouter.orderTracking, arguments: order['id']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
                Text('Commande #${order['order_number'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: statusInfo['color'].withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(statusInfo['text'], style: TextStyle(color: statusInfo['color'], fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    image: order['restaurant']?['logo_url'] != null
                        ? DecorationImage(image: NetworkImage(order['restaurant']['logo_url']), fit: BoxFit.cover)
                        : null,
                  ),
                  child: order['restaurant']?['logo_url'] == null ? const Icon(Icons.restaurant, color: Colors.grey) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order['restaurant']?['name'] ?? 'Restaurant', style: const TextStyle(fontWeight: FontWeight.w500)),
                      Text('$itemCount articles • ${order['total']?.toStringAsFixed(0) ?? 0} DA', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDate(order['created_at']), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const Icon(Icons.chevron_right, color: Colors.grey),
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
    return '${date.day}/${date.month}/${date.year}, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
