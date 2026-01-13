import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final String restaurantId;
  const RestaurantDetailScreen({super.key, required this.restaurantId});

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  Map<String, dynamic>? _restaurant;
  bool _isLoading = true;
  final Map<String, int> _cart = {};

  @override
  void initState() {
    super.initState();
    _loadRestaurant();
  }

  Future<void> _loadRestaurant() async {
    try {
      final restaurant = await SupabaseService.getRestaurant(widget.restaurantId);
      setState(() {
        _restaurant = restaurant;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _addToCart(Map<String, dynamic> item) {
    final itemId = item['id'] as String;
    setState(() {
      _cart[itemId] = (_cart[itemId] ?? 0) + 1;
    });
    
    // Sauvegarder dans Hive
    final cartBox = Hive.box('cart');
    final cartItems = List<Map<String, dynamic>>.from(cartBox.get('items', defaultValue: []));
    final existingIndex = cartItems.indexWhere((i) => i['id'] == itemId);
    
    if (existingIndex >= 0) {
      cartItems[existingIndex]['quantity'] = (cartItems[existingIndex]['quantity'] ?? 1) + 1;
    } else {
      cartItems.add({
        'id': itemId,
        'name': item['name'],
        'price': item['price'],
        'quantity': 1,
        'restaurant_id': widget.restaurantId,
        'restaurant_name': _restaurant?['name'],
      });
    }
    cartBox.put('items', cartItems);
    cartBox.put('restaurant_id', widget.restaurantId);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item['name']} ajouté au panier'), duration: const Duration(seconds: 1)),
    );
  }

  int get _totalItems => _cart.values.fold(0, (sum, qty) => sum + qty);

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_restaurant == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Restaurant non trouvé')),
      );
    }

    final categories = _restaurant!['menu_categories'] as List? ?? [];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(_restaurant!['name'] ?? '', style: const TextStyle(shadows: [Shadow(blurRadius: 10)])),
              background: Container(
                color: Colors.grey[300],
                child: _restaurant!['cover_url'] != null
                    ? Image.network(_restaurant!['cover_url'], fit: BoxFit.cover)
                    : const Icon(Icons.restaurant, size: 80, color: Colors.grey),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      Text(' ${(_restaurant!['rating'] ?? 0).toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 16),
                      const Icon(Icons.access_time, color: Colors.grey, size: 20),
                      Text(' ${_restaurant!['avg_prep_time'] ?? 30} min'),
                      const SizedBox(width: 16),
                      if (_restaurant!['delivery_fee'] != null) ...[
                        const Icon(Icons.delivery_dining, color: Colors.grey, size: 20),
                        Text(' ${_restaurant!['delivery_fee']} DA'),
                      ],
                    ],
                  ),
                  if (_restaurant!['description'] != null) ...[
                    const SizedBox(height: 12),
                    Text(_restaurant!['description'], style: TextStyle(color: Colors.grey[600])),
                  ],
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, categoryIndex) {
                final category = categories[categoryIndex];
                final items = category['menu_items'] as List? ?? [];
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(category['name'] ?? 'Menu', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    ...items.map((item) => _buildMenuItem(item)),
                  ],
                );
              },
              childCount: categories.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      bottomSheet: _totalItems > 0
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))],
              ),
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, AppRouter.cart),
                  child: Text('Voir le panier ($_totalItems articles)'),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildMenuItem(Map<String, dynamic> item) {
    final isAvailable = item['is_available'] ?? true;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                Text(item['name'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, color: isAvailable ? Colors.black : Colors.grey)),
                if (item['description'] != null)
                  Text(item['description'], style: TextStyle(color: Colors.grey[600], fontSize: 12), maxLines: 2),
                const SizedBox(height: 4),
                Text('${item['price']} DA', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          if (isAvailable)
            IconButton(
              onPressed: () => _addToCart(item),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
            )
          else
            const Text('Indisponible', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}
