import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/backend_api_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';

/// NOTE: Cette version est obsolète - utiliser CartScreenV2
/// Le panier est géré en state local, pas en base de données
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Map<String, dynamic>> _items = [];
  String? _restaurantId;
  String? _restaurantName;
  bool _isLoading = false;
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() => _isLoading = true);
    try {
      // Panier géré en state local - pas de chargement depuis la base
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Erreur chargement panier: $e');
    }
  }

  Future<void> _updateQuantity(int index, int delta) async {
    final newQuantity = (_items[index]['quantity'] as int) + delta;
    
    if (newQuantity <= 0) {
      setState(() => _items.removeAt(index));
    } else {
      setState(() => _items[index]['quantity'] = newQuantity);
    }
  }

  Future<void> _clearCart() async {
    setState(() => _items.clear());
  }

  double get _subtotal => _items.fold(0.0, (sum, item) => sum + ((item['item_price'] as num?)?.toDouble() ?? 0) * ((item['quantity'] as num?)?.toInt() ?? 1));
  double get _deliveryFee => 150;
  double get _total => _subtotal + _deliveryFee;

  Future<void> _placeOrder() async {
    // Validation complète
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Votre panier est vide'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    if (_restaurantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur: restaurant non identifié'), backgroundColor: Colors.red),
      );
      return;
    }
    
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrez votre adresse de livraison'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    if (_addressController.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adresse trop courte, soyez plus précis'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ✅ MIGRATION: Utiliser le backend au lieu de Supabase direct
      final backendApi = BackendApiService(SupabaseService.client);
      
      final orderResponse = await backendApi.createOrder(
        restaurantId: _restaurantId!,
        items: _items.map((item) => {
          'menu_item_id': item['id'],
          'quantity': item['quantity'],
        }).toList(),
        deliveryAddress: _addressController.text.trim(),
        deliveryLat: 36.8869,
        deliveryLng: 4.1260,
        notes: null,
      );

      final order = orderResponse['order'];
      
      _clearCart();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Commande passée avec succès! 🎉'), backgroundColor: Colors.green),
        );
        Navigator.pushReplacementNamed(context, AppRouter.orderTracking, arguments: order['id']);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString().replaceAll('Exception:', '')}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon panier'),
        actions: [
          if (_items.isNotEmpty)
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: _clearCart),
        ],
      ),
      body: _items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('Votre panier est vide', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Parcourir les restaurants'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                if (_restaurantName != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey[100],
                    child: Row(
                      children: [
                        const Icon(Icons.restaurant, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        Text(_restaurantName!, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text('${item['price']} DA', style: TextStyle(color: Colors.grey[600])),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () => _updateQuantity(index, -1),
                                ),
                                Text('${item['quantity'] ?? 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryColor),
                                  onPressed: () => _updateQuantity(index, 1),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        TextField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Adresse de livraison',
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Sous-total'),
                            Text('${_subtotal.toStringAsFixed(0)} DA'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Livraison'),
                            Text('${_deliveryFee.toStringAsFixed(0)} DA'),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            Text('${_total.toStringAsFixed(0)} DA', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryColor)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _placeOrder,
                            child: _isLoading
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Commander', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }
}
