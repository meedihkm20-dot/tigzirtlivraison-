import 'package:flutter/material.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isOpen = true;
  int _currentIndex = 0;
  List<Map<String, dynamic>> _pendingOrders = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  Map<String, dynamic>? _restaurant;
  RealtimeChannel? _ordersChannel;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _ordersChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final restaurant = await SupabaseService.getMyRestaurant();
      final orders = await SupabaseService.getPendingOrders();
      final stats = await SupabaseService.getStats();
      
      setState(() {
        _restaurant = restaurant;
        _isOpen = restaurant?['is_open'] ?? true;
        _pendingOrders = orders;
        _stats = stats;
      });
      
      // S'abonner aux nouvelles commandes
      if (restaurant != null && _ordersChannel == null) {
        _ordersChannel = SupabaseService.subscribeToNewOrders(
          restaurant['id'],
          (order) {
            _loadData(); // Recharger les données
            _showNewOrderNotification();
          },
        );
      }
    } catch (e) {
      debugPrint('Erreur chargement: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showNewOrderNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔔 Nouvelle commande reçue!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _toggleOpen(bool value) async {
    setState(() => _isOpen = value);
    await SupabaseService.setRestaurantOpen(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_restaurant?['name'] ?? 'Mon Restaurant'),
        actions: [
          Switch(value: _isOpen, onChanged: _toggleOpen, activeColor: Colors.green),
          Text(_isOpen ? 'Ouvert' : 'Fermé', style: TextStyle(color: _isOpen ? Colors.green : Colors.red)),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildStatCard('Aujourd\'hui', '${_stats['orders_today'] ?? 0}', 'commandes', Icons.receipt_long, Colors.blue)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatCard('Revenus', '${(_stats['revenue_today'] ?? 0).toStringAsFixed(0)}', 'DA', Icons.attach_money, Colors.green)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildStatCard('En attente', '${_stats['pending_orders'] ?? 0}', 'commandes', Icons.pending_actions, Colors.orange)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatCard('Total', '${_stats['total_orders'] ?? 0}', 'commandes', Icons.history, Colors.purple)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Commandes en cours', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        TextButton(onPressed: () {}, child: const Text('Voir tout')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_pendingOrders.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text('Aucune commande en cours', style: TextStyle(color: Colors.grey[600])),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._pendingOrders.map((order) => _buildOrderCard(context, order)),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (i) {
          setState(() => _currentIndex = i);
          if (i == 1) Navigator.pushNamed(context, AppRouter.menu);
          if (i == 2) Navigator.pushNamed(context, AppRouter.stats);
          if (i == 3) Navigator.pushNamed(context, AppRouter.profile);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Menu'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String unit, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(width: 4),
              Text(unit, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Map<String, dynamic> order) {
    final status = order['status'] as String?;
    final statusInfo = _getStatusInfo(status);
    final orderItems = order['order_items'] as List? ?? [];
    final itemCount = orderItems.fold<int>(0, (sum, item) => sum + ((item['quantity'] as int?) ?? 1));
    
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRouter.orderDetail, arguments: order['id']),
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
                Text('Commande #${order['order_number'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(order['customer']?['full_name'] ?? 'Client', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 4),
            Text('$itemCount articles • ${order['total']?.toStringAsFixed(0) ?? 0} DA', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text(_getTimeAgo(order['created_at']), style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            const SizedBox(height: 12),
            _buildActionButtons(order),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> order) {
    final status = order['status'] as String?;
    final orderId = order['id'] as String;
    
    switch (status) {
      case 'pending':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _cancelOrder(orderId),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Refuser'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _confirmOrder(orderId),
                child: const Text('Confirmer'),
              ),
            ),
          ],
        );
      case 'confirmed':
        return ElevatedButton(
          onPressed: () => _startPreparing(orderId),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          child: const Text('Commencer préparation'),
        );
      case 'preparing':
        return ElevatedButton(
          onPressed: () => _markAsReady(orderId),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('Marquer comme prêt'),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _confirmOrder(String orderId) async {
    try {
      await SupabaseService.confirmOrder(orderId, 30);
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Commande confirmée'), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _startPreparing(String orderId) async {
    try {
      await SupabaseService.startPreparing(orderId);
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _markAsReady(String orderId) async {
    try {
      await SupabaseService.markAsReady(orderId);
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Commande prête! En attente du livreur'), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _cancelOrder(String orderId) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refuser la commande'),
        content: TextField(
          decoration: const InputDecoration(hintText: 'Raison du refus'),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, 'Indisponible'), child: const Text('Confirmer')),
        ],
      ),
    );
    
    if (reason != null) {
      try {
        await SupabaseService.cancelOrder(orderId, reason);
        _loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Map<String, dynamic> _getStatusInfo(String? status) {
    switch (status) {
      case 'pending': return {'text': 'Nouvelle', 'color': Colors.orange};
      case 'confirmed': return {'text': 'Confirmée', 'color': Colors.blue};
      case 'preparing': return {'text': 'En préparation', 'color': Colors.purple};
      case 'ready': return {'text': 'Prête', 'color': Colors.green};
      default: return {'text': status ?? '', 'color': Colors.grey};
    }
  }

  String _getTimeAgo(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.parse(dateStr);
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return 'Il y a ${diff.inDays}j';
  }
}
