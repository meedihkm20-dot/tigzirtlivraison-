import 'package:flutter/material.dart';
import '../../../core/services/cart_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Map<String, dynamic>> _cartItems = [];
  Map<String, dynamic>? _restaurant;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  void _loadCart() {
    setState(() {
      _cartItems = CartService.getItems();
      _restaurant = CartService.getRestaurant();
    });
  }

  double get _subtotal => CartService.getSubtotal();
  int get _deliveryFee => 200; // TODO: Calculer dynamiquement
  double get _total => _subtotal + _deliveryFee;

  Future<void> _updateQuantity(String itemId, int delta) async {
    final item = _cartItems.firstWhere((e) => e['id'] == itemId);
    final newQty = (item['quantity'] as int) + delta;
    await CartService.updateQuantity(itemId, newQty);
    _loadCart();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Panier'),
        actions: [
          if (_cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Vider le panier?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Vider', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (confirm == true) {
                  await CartService.clear();
                  _loadCart();
                }
              },
            ),
        ],
      ),
      body: _cartItems.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Votre panier est vide', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            )
          : Column(
              children: [
                // Restaurant info
                if (_restaurant != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.grey[100],
                    child: Row(
                      children: [
                        const Icon(Icons.restaurant, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(_restaurant!['name'] ?? 'Restaurant', style: const TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _cartItems.length,
                    itemBuilder: (context, index) => _buildCartItem(index),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))],
                  ),
                  child: Column(
                    children: [
                      _buildPriceRow('Sous-total', '${_subtotal.toStringAsFixed(0)} DA'),
                      _buildPriceRow('Livraison', '$_deliveryFee DA'),
                      const Divider(),
                      _buildPriceRow('Total', '${_total.toStringAsFixed(0)} DA', isBold: true),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _showOrderConfirmation(context),
                          child: const Text('Commander'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCartItem(int index) {
    final item = _cartItems[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              image: item['image_url'] != null
                  ? DecorationImage(image: NetworkImage(item['image_url']), fit: BoxFit.cover)
                  : null,
            ),
            child: item['image_url'] == null ? const Icon(Icons.fastfood, color: Colors.grey) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${item['price']} DA', style: const TextStyle(color: Color(0xFFFF6B35))),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () => _updateQuantity(item['id'], -1),
              ),
              Text('${item['quantity']}', style: const TextStyle(fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => _updateQuantity(item['id'], 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: isBold ? const Color(0xFFFF6B35) : null)),
        ],
      ),
    );
  }

  void _showOrderConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la commande'),
        content: Text('Total: ${_total.toStringAsFixed(0)} DA\n\nVoulez-vous confirmer votre commande?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // TODO: Créer la commande via SupabaseService
              await CartService.clear();
              _loadCart();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Commande confirmée!')));
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }
}
