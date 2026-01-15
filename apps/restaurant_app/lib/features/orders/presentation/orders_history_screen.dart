import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';

class OrdersHistoryScreen extends StatefulWidget {
  const OrdersHistoryScreen({super.key});

  @override
  State<OrdersHistoryScreen> createState() => _OrdersHistoryScreenState();
}

class _OrdersHistoryScreenState extends State<OrdersHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _todayOrders = [];
  List<Map<String, dynamic>> _historyOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final today = await SupabaseService.getTodayOrders();
      final history = await SupabaseService.getOrderHistory(limit: 100);
      
      setState(() {
        _todayOrders = today;
        _historyOrders = history;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erreur chargement historique: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des commandes'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Aujourd\'hui (${_todayOrders.length})'),
            Tab(text: 'Historique (${_historyOrders.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrdersList(_todayOrders, isToday: true),
                _buildOrdersList(_historyOrders, isToday: false),
              ],
            ),
    );
  }

  Widget _buildOrdersList(List<Map<String, dynamic>> orders, {required bool isToday}) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              isToday ? 'Aucune commande aujourd\'hui' : 'Aucun historique',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // Calculer les totaux
    double totalRevenue = 0;
    int deliveredCount = 0;
    int cancelledCount = 0;
    
    for (var order in orders) {
      if (order['status'] == 'delivered') {
        totalRevenue += (order['total'] as num?)?.toDouble() ?? 0;
        deliveredCount++;
      } else if (order['status'] == 'cancelled') {
        cancelledCount++;
      }
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: Column(
        children: [
          // Résumé
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFE65100).withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('Livrées', '$deliveredCount', Colors.green),
                _buildSummaryItem('Annulées', '$cancelledCount', Colors.red),
                _buildSummaryItem('Revenus', '${totalRevenue.toStringAsFixed(0)} DA', const Color(0xFFE65100)),
              ],
            ),
          ),
          // Liste
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) => _buildOrderCard(orders[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] as String?;
    final statusInfo = _getStatusInfo(status);
    final orderItems = order['order_items'] as List? ?? [];
    final itemCount = orderItems.fold<int>(0, (sum, item) => sum + ((item['quantity'] as int?) ?? 1));
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#${order['order_number'] ?? ''}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusInfo['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusInfo['text'],
                  style: TextStyle(color: statusInfo['color'], fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                order['customer']?['full_name'] ?? 'Client',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$itemCount articles',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              Text(
                '${(order['total'] as num?)?.toStringAsFixed(0) ?? 0} DA',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE65100)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _formatDate(order['created_at']),
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
          // Afficher les items
          if (orderItems.isNotEmpty) ...[
            const Divider(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: orderItems.take(3).map<Widget>((item) {
                return Chip(
                  label: Text(
                    '${item['quantity']}x ${item['name']}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: Colors.grey[100],
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
            if (orderItems.length > 3)
              Text(
                '+${orderItems.length - 3} autres',
                style: TextStyle(color: Colors.grey[500], fontSize: 11),
              ),
          ],
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(String? status) {
    switch (status) {
      case 'delivered':
        return {'text': 'Livrée', 'color': Colors.green};
      case 'cancelled':
        return {'text': 'Annulée', 'color': Colors.red};
      case 'pending':
        return {'text': 'En attente', 'color': Colors.orange};
      case 'confirmed':
        return {'text': 'Confirmée', 'color': Colors.blue};
      case 'preparing':
        return {'text': 'En préparation', 'color': Colors.purple};
      case 'ready':
        return {'text': 'Prête', 'color': Colors.teal};
      default:
        return {'text': status ?? '', 'color': Colors.grey};
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    
    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      return 'Aujourd\'hui à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.day == yesterday.day && date.month == yesterday.month && date.year == yesterday.year) {
      return 'Hier à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    
    return '${date.day}/${date.month}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
