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

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _restaurant;
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;
  bool _isFavorite = false;
  final Map<String, int> _cart = {};
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRestaurant();
    _loadReviews();
    _checkFavorite();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  Future<void> _loadReviews() async {
    try {
      final reviews = await SupabaseService.getRestaurantReviews(widget.restaurantId);
      setState(() => _reviews = reviews);
    } catch (e) {
      debugPrint('Erreur chargement avis: $e');
    }
  }

  Future<void> _checkFavorite() async {
    final isFav = await SupabaseService.isFavoriteRestaurant(widget.restaurantId);
    setState(() => _isFavorite = isFav);
  }

  Future<void> _toggleFavorite() async {
    await SupabaseService.toggleFavoriteRestaurant(widget.restaurantId);
    setState(() => _isFavorite = !_isFavorite);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFavorite ? 'Ajouté aux favoris' : 'Retiré des favoris'),
        duration: const Duration(seconds: 1),
      ),
    );
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
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            actions: [
              IconButton(
                onPressed: _toggleFavorite,
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : Colors.white,
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(_restaurant!['name'] ?? '', style: const TextStyle(shadows: [Shadow(blurRadius: 10)])),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _restaurant!['cover_url'] != null
                      ? Image.network(_restaurant!['cover_url'], fit: BoxFit.cover)
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.restaurant, size: 80, color: Colors.grey),
                        ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                      ),
                    ),
                  ),
                ],
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
                      GestureDetector(
                        onTap: () => _tabController.animateTo(1),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 20),
                            Text(' ${(_restaurant!['rating'] ?? 0).toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(' (${_restaurant!['total_reviews'] ?? 0})', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          ],
                        ),
                      ),
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
                  if (_restaurant!['cuisine_type'] != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(_restaurant!['cuisine_type'], style: TextStyle(color: AppTheme.primaryColor, fontSize: 12)),
                    ),
                  ],
                  if (_restaurant!['description'] != null) ...[
                    const SizedBox(height: 12),
                    Text(_restaurant!['description'], style: TextStyle(color: Colors.grey[600])),
                  ],
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppTheme.primaryColor,
                tabs: [
                  const Tab(text: 'Menu'),
                  Tab(text: 'Avis (${_reviews.length})'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            // Menu Tab
            _buildMenuTab(categories),
            // Reviews Tab
            _buildReviewsTab(),
          ],
        ),
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

  Widget _buildMenuTab(List categories) {
    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Menu non disponible', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: categories.length,
      itemBuilder: (context, categoryIndex) {
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
    );
  }

  Widget _buildReviewsTab() {
    if (_reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Aucun avis pour le moment', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('Soyez le premier à donner votre avis!', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reviews.length,
      itemBuilder: (context, index) => _buildReviewCard(_reviews[index]),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final rating = review['restaurant_rating'] as int? ?? 5;
    final comment = review['comment'] as String?;
    final customer = review['customer'] as Map<String, dynamic>?;
    final createdAt = review['created_at'] as String?;

    return Container(
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
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                backgroundImage: customer?['avatar_url'] != null ? NetworkImage(customer!['avatar_url']) : null,
                child: customer?['avatar_url'] == null
                    ? Text(
                        (customer?['full_name'] ?? 'C')[0].toUpperCase(),
                        style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer?['full_name'] ?? 'Client', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(_formatDate(createdAt), style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (i) => Icon(
                  i < rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 18,
                )),
              ),
            ],
          ),
          if (comment != null && comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(comment, style: TextStyle(color: Colors.grey[700])),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuItem(Map<String, dynamic> item) {
    final isAvailable = item['is_available'] ?? true;
    final isPopular = item['is_popular'] ?? false;
    final isVegetarian = item['is_vegetarian'] ?? false;
    final isSpicy = item['is_spicy'] ?? false;
    
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
          // Image du plat
          if (item['image_url'] != null)
            Container(
              width: 70,
              height: 70,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: NetworkImage(item['image_url']),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item['name'] ?? '',
                        style: TextStyle(fontWeight: FontWeight.bold, color: isAvailable ? Colors.black : Colors.grey),
                      ),
                    ),
                    if (isPopular)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4)),
                        child: const Text('Populaire', style: TextStyle(color: Colors.white, fontSize: 10)),
                      ),
                  ],
                ),
                if (item['description'] != null)
                  Text(item['description'], style: TextStyle(color: Colors.grey[600], fontSize: 12), maxLines: 2),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('${item['price']} DA', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                    if (isVegetarian) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.eco, color: Colors.green, size: 16),
                    ],
                    if (isSpicy) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.local_fire_department, color: Colors.red, size: 16),
                    ],
                  ],
                ),
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

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) return "Aujourd'hui";
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} jours';
    if (diff.inDays < 30) return 'Il y a ${(diff.inDays / 7).floor()} semaines';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Colors.white, child: tabBar);
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}
