import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';

/// Écran pour recommander facilement une commande précédente
class ReorderScreen extends StatefulWidget {
  const ReorderScreen({super.key});

  @override
  State<ReorderScreen> createState() => _ReorderScreenState();
}

class _ReorderScreenState extends State<ReorderScreen> {
  List<Map<String, dynamic>> _pastOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPastOrders();
  }

  Future<void> _loadPastOrders() async {
    setState(() => _isLoading = true);
    try {
      final orders = await SupabaseService.getCustomerOrders();
      // Filtrer les commandes livrées et grouper par restaurant
      final deliveredOrders = orders.where((o) => o['status'] == 'delivered').toList();
      setState(() {
        _pastOrders = deliveredOrders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _reorder(Map<String, dynamic> order) async {
    // Afficher confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recommander?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Restaurant: ${order['restaurant']?['name'] ?? ''}'),
            const SizedBox(height: 8),
            const Text('Articles:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...(order['order_items'] as List? ?? []).map((item) => 
              Text('• ${item['quantity']}x ${item['name']}')
            ),
            const SizedBox(height: 12),
            Text(
              'Total: ${(order['total'] as num?)?.toStringAsFixed(0) ?? 0} DA',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Commander'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Pré-remplir le panier avec les items de la commande
      final items = order['order_items'] as List? ?? [];
      final restaurantId = order['restaurant_id'] as String?;
      final restaurantName = order['restaurant']?['name'] as String?;
      
      if (restaurantId != null && items.isNotEmpty) {
        final cartBox = Hive.box('cart');
        
        // Vider le panier actuel
        await cartBox.delete('items');
        await cartBox.delete('restaurant_id');
        
        // Ajouter les items de la commande précédente
        final cartItems = items.map((item) => {
          'id': item['menu_item_id'],
          'name': item['name'],
          'price': item['price'],
          'quantity': item['quantity'] ?? 1,
          'restaurant_id': restaurantId,
          'restaurant_name': restaurantName,
        }).toList();
        
        await cartBox.put('items', cartItems);
        await cartBox.put('restaurant_id', restaurantId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Panier pré-rempli! 🛒'), backgroundColor: Colors.green),
          );
          Navigator.pushNamed(context, AppRouter.cart);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommander 🔄'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pastOrders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('Aucune commande passée', style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, AppRouter.customerHome),
                        child: const Text('Explorer les restaurants'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPastOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _pastOrders.length,
                    itemBuilder: (context, index) => _buildOrderCard(_pastOrders[index]),
                  ),
                ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final restaurant = order['restaurant'] as Map<String, dynamic>?;
    final items = order['order_items'] as List? ?? [];
    final total = (order['total'] as num?)?.toDouble() ?? 0;
    final createdAt = DateTime.tryParse(order['created_at'] ?? '');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _reorder(order),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  // Logo restaurant
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      image: restaurant?['logo_url'] != null
                          ? DecorationImage(
                              image: CachedNetworkImageProvider(restaurant!['logo_url']),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: restaurant?['logo_url'] == null
                        ? Center(
                            child: Text(
                              (restaurant?['name'] ?? 'R')[0].toUpperCase(),
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          restaurant?['name'] ?? 'Restaurant',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        if (createdAt != null)
                          Text(
                            _formatDate(createdAt),
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${total.toStringAsFixed(0)} DA',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              
              // Items
              ...items.take(3).map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${item['quantity']}x',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item['name'] ?? '',
                        style: const TextStyle(fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )),
              if (items.length > 3)
                Text(
                  '+${items.length - 3} autre(s)',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              
              const SizedBox(height: 12),
              
              // Bouton recommander
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _reorder(order),
                  icon: const Icon(Icons.replay),
                  label: const Text('Recommander'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) return "Aujourd'hui";
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} jours';
    return '${date.day}/${date.month}/${date.year}';
  }
}
