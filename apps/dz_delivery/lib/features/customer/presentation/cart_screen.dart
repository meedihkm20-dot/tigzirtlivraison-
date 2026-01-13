import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';

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

  void _loadCart() {
    final cartBox = Hive.box('cart');
    setState(() {
      _items = List<Map<String, dynamic>>.from(cartBox.get('items', defaultValue: []));
      _restaurantId = cartBox.get('restaurant_id');
      if (_items.isNotEmpty) _restaurantName = _items.first['restaurant_name'];
    });
  }

  void _updateQuantity(int index, int delta) {
    setState(() {
      _items[index]['quantity'] = (_items[index]['quantity'] ?? 1) + delta;
      if (_items[index]['quantity'] <= 0) {
        _items.removeAt(index);
      }
    });
    _saveCart();
  }

  void _saveCart() {
    final cartBox = Hive.box('cart');
    cartBox.put('items', _items);
    if (_items.isEmpty) {
      cartBox.delete('restaurant_id');
    }
  }

  void _clearCart() {
    final cartBox = Hive.box('cart');
    cartBox.delete('items');
    cartBox.delete('restaurant_id');
    setState(() {
      _items = [];
      _restaurantId = null;
    });
  }

  double get _subtotal => _items.fold(0, (sum, item) => sum + (item['price'] ?? 0) * (item['quantity'] ?? 1));
  double get _deliveryFee => 150;
  double get _total => _subtotal + _deliveryFee;

  Future<void> _placeOrder() async {
    if (_items.isEmpty || _restaurantId == null) return;
    if (_addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entrez votre adresse de livraison')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final order = await SupabaseService.createOrder(
        restaurantId: _restaurantId!,
        items: _items,
        deliveryAddress: _addressController.text,
        deliveryLat: 36.8869,
        deliveryLng: 4.1260,
        subtotal: _subtotal,
        deliveryFee: _deliveryFee,
        total: _total,
      );

      _clearCart();
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRouter.orderTracking, arguments: order['id']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
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
