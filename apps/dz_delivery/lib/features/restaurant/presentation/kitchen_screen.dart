import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';

class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key});

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  Timer? _refreshTimer;
  int _previousOrderCount = 0;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadOrders());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    try {
      final orders = await SupabaseService.getKitchenOrders();
      
      // Vibrer et notification si nouvelle commande
      if (orders.length > _previousOrderCount && _previousOrderCount > 0) {
        _notifyNewOrder();
      }
      _previousOrderCount = orders.length;
      
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _notifyNewOrder() {
    // Vibration pour alerter
    HapticFeedback.heavyImpact();
    // Afficher snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔔 Nouvelle commande en cuisine!'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _startPreparing(String orderId) async {
    await SupabaseService.startPreparing(orderId);
    _loadOrders();
  }

  Future<void> _markAsReady(String orderId) async {
    await SupabaseService.markAsReady(orderId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Commande prête! Le livreur est notifié'), backgroundColor: Colors.green),
    );
    _loadOrders();
  }

  Color _getOrderColor(Map<String, dynamic> order) {
    final status = order['status'] as String?;
    final createdAt = DateTime.tryParse(order['created_at'] ?? '');
    
    if (status == 'preparing') return Colors.orange;
    
    if (createdAt != null) {
      final elapsed = DateTime.now().difference(createdAt).inMinutes;
      if (elapsed > 15) return Colors.red; // Urgent
      if (elapsed > 10) return Colors.orange; // Attention
    }
    return Colors.green; // OK
  }

  String _getElapsedTime(String? createdAt) {
    if (createdAt == null) return '0 min';
    final created = DateTime.tryParse(createdAt);
    if (created == null) return '0 min';
    final elapsed = DateTime.now().difference(created).inMinutes;
    return '$elapsed min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.restaurant_menu),
            const SizedBox(width: 8),
            const Text('Cuisine'),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _orders.isEmpty ? Colors.green : Colors.orange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_orders.length} en cours',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadOrders),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 80, color: Colors.green[300]),
                      const SizedBox(height: 16),
                      const Text('Aucune commande en attente', style: TextStyle(fontSize: 18, color: Colors.grey)),
                      const SizedBox(height: 8),
                      const Text('Les nouvelles commandes apparaîtront ici', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _orders.length,
                    itemBuilder: (context, index) => _buildOrderCard(_orders[index]),
                  ),
                ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] as String?;
    final items = order['order_items'] as List? ?? [];
    final orderColor = _getOrderColor(order);
    final isPreparing = status == 'preparing';
    final livreur = order['livreur'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: orderColor, width: 3),
        boxShadow: [BoxShadow(color: orderColor.withValues(alpha: 0.3), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: orderColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${order['order_number'] ?? ''}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        isPreparing ? 'En préparation' : 'Nouvelle',
                        style: TextStyle(color: orderColor, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: orderColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        _getElapsedTime(order['created_at']),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${item['quantity']}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                            if (item['special_instructions'] != null)
                              Text(
                                item['special_instructions'],
                                style: TextStyle(color: Colors.orange[700], fontSize: 11, fontStyle: FontStyle.italic),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Livreur info
          if (livreur != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: Colors.blue.withValues(alpha: 0.1),
              child: Row(
                children: [
                  const Icon(Icons.delivery_dining, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      livreur['profile']?['full_name'] ?? 'Livreur',
                      style: const TextStyle(fontSize: 12, color: Colors.blue),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          
          // Action button
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => isPreparing ? _markAsReady(order['id']) : _startPreparing(order['id']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPreparing ? Colors.green : AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  isPreparing ? '✓ PRÊT' : 'PRÉPARER',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
