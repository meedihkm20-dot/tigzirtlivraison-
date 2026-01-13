import 'package:flutter/material.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _currentIndex = 0;
  List<Map<String, dynamic>> _restaurants = [];
  bool _isLoading = true;
  String _userAddress = 'Tigzirt, Algérie';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final profile = await SupabaseService.getProfile();
      if (profile != null && profile['address'] != null) {
        _userAddress = profile['address'];
      }
      
      final restaurants = await SupabaseService.getNearbyRestaurants(
        latitude: profile?['latitude'] ?? 36.8869,
        longitude: profile?['longitude'] ?? 4.1260,
        radiusKm: 10,
      );
      setState(() => _restaurants = restaurants);
    } catch (e) {
      debugPrint('Erreur: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchRestaurants(String query) async {
    if (query.isEmpty) {
      _loadData();
      return;
    }
    try {
      final results = await SupabaseService.searchRestaurants(query);
      setState(() => _restaurants = results);
    } catch (e) {
      debugPrint('Erreur recherche: $e');
    }
  }

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
    if (index == 1) Navigator.pushNamed(context, AppRouter.customerOrders);
    if (index == 2) Navigator.pushNamed(context, AppRouter.customerProfile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Livrer à', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text(_userAddress, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => Navigator.pushNamed(context, AppRouter.cart),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  onChanged: _searchRestaurants,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un restaurant...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Catégories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildCategoryItem(Icons.fastfood, 'Fast Food'),
                    _buildCategoryItem(Icons.local_pizza, 'Pizza'),
                    _buildCategoryItem(Icons.restaurant, 'Traditionnel'),
                    _buildCategoryItem(Icons.cake, 'Desserts'),
                    _buildCategoryItem(Icons.local_cafe, 'Café'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Restaurants', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
              else if (_restaurants.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.restaurant, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('Aucun restaurant trouvé', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _restaurants.length,
                  itemBuilder: (context, index) => _buildRestaurantCard(_restaurants[index]),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Commandes'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(IconData icon, String label) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: AppTheme.primaryColor, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildRestaurantCard(Map<String, dynamic> restaurant) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRouter.restaurantDetail, arguments: restaurant['id']),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                image: restaurant['logo_url'] != null
                    ? DecorationImage(image: NetworkImage(restaurant['logo_url']), fit: BoxFit.cover)
                    : null,
              ),
              child: restaurant['logo_url'] == null
                  ? const Center(child: Icon(Icons.restaurant, size: 50, color: Colors.grey))
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(restaurant['name'] ?? 'Restaurant', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                      if (!(restaurant['is_open'] ?? true))
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Text('Fermé', style: TextStyle(color: Colors.red, fontSize: 12)),
                        ),
                    ],
                  ),
                  if (restaurant['cuisine_type'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(restaurant['cuisine_type'], style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      Text(' ${(restaurant['rating'] ?? 0).toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      const Icon(Icons.access_time, size: 16, color: Colors.grey),
                      Text(' ${restaurant['avg_prep_time'] ?? 30} min', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
