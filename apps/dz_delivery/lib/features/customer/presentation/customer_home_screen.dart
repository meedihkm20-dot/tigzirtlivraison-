import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  List<Map<String, dynamic>> _topRestaurants = [];
  List<Map<String, dynamic>> _nearbyRestaurants = [];
  List<Map<String, dynamic>> _dailySpecials = [];
  List<Map<String, dynamic>> _topMenuItems = [];
  List<Map<String, dynamic>> _recentSearches = [];
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _loyalty;
  bool _isLoading = true;
  final _searchController = TextEditingController();
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Charger en parallèle avec gestion d'erreur individuelle
      final results = await Future.wait([
        _safeCall(() => SupabaseService.getTopRestaurants(limit: 5), <Map<String, dynamic>>[]),
        _safeCall(() => SupabaseService.getDailySpecials(), <Map<String, dynamic>>[]),
        _safeCall(() => SupabaseService.getTopMenuItems(limit: 10), <Map<String, dynamic>>[]),
        _safeCall(() => SupabaseService.getProfile(), null),
        _safeCall(() => SupabaseService.getCustomerLoyalty(), {'points': 0, 'total_orders': 0}),
        _safeCall(() => SupabaseService.getRecentSearches(limit: 5), <String>[]),
        _loadNearbyRestaurants(),
      ]);
      
      if (!mounted) return;
      setState(() {
        _topRestaurants = results[0] as List<Map<String, dynamic>>;
        _dailySpecials = results[1] as List<Map<String, dynamic>>;
        _topMenuItems = results[2] as List<Map<String, dynamic>>;
        _profile = results[3] as Map<String, dynamic>?;
        _loyalty = results[4] as Map<String, dynamic>;
        _recentSearches = (results[5] as List<String>).map((s) => {'query': s}).toList();
        _nearbyRestaurants = results[6] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
      
      // Charger le nombre de notifications non lues
      _loadUnreadNotifications();
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('Erreur chargement: $e');
    }
  }
  
  Future<T> _safeCall<T>(Future<T> Function() call, T defaultValue) async {
    try {
      return await call();
    } catch (e) {
      debugPrint('Erreur appel: $e');
      return defaultValue;
    }
  }
  
  Future<void> _loadUnreadNotifications() async {
    try {
      final count = await NotificationService.getUnreadCount();
      if (mounted) setState(() => _unreadNotifications = count);
    } catch (e) {
      debugPrint('Erreur notifications: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _loadNearbyRestaurants() async {
    try {
      final position = await LocationService.getCurrentLocation();
      if (position != null) {
        return await SupabaseService.getNearbyRestaurants(
          latitude: position.latitude,
          longitude: position.longitude,
          radiusKm: 10000, // Temporaire: rayon énorme pour tester
        );
      }
    } catch (e) {
      debugPrint('Erreur localisation: $e');
    }
    return [];
  }

  void _onSearch(String query) async {
    if (query.trim().isEmpty) return;
    await SupabaseService.saveSearchQuery(query);
    final results = await SupabaseService.searchRestaurants(query);
    // Afficher les résultats dans une bottom sheet
    _showSearchResults(results);
  }

  void _showSearchResults(List<Map<String, dynamic>> results) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '${results.length} résultat(s)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: results.isEmpty
                  ? const Center(child: Text('Aucun restaurant trouvé'))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: results.length,
                      itemBuilder: (context, index) => _buildRestaurantTile(results[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // Header avec recherche
            SliverAppBar(
              expandedHeight: 180,
              floating: true,
              pinned: true,
              backgroundColor: AppTheme.primaryColor,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.8)],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bonjour ${_profile?['full_name']?.split(' ').first ?? ''} 👋',
                                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                                  ),
                                  const Text(
                                    'Qu\'est-ce qui vous ferait plaisir?',
                                    style: TextStyle(color: Colors.white70, fontSize: 14),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  // Points fidélité
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.stars, color: Colors.amber, size: 18),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${_loyalty?['points'] ?? 0}',
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Notifications
                                  Stack(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                                        onPressed: () => Navigator.pushNamed(context, AppRouter.notifications),
                                      ),
                                      if (_unreadNotifications > 0)
                                        Positioned(
                                          right: 8,
                                          top: 8,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                            child: Text(
                                              '$_unreadNotifications',
                                              style: const TextStyle(color: Colors.white, fontSize: 10),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Barre de recherche
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
                            ),
                            child: TextField(
                              controller: _searchController,
                              onSubmitted: _onSearch,
                              decoration: InputDecoration(
                                hintText: 'Rechercher un restaurant, un plat...',
                                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.tune, color: Colors.grey),
                                  onPressed: () {},
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Contenu
            if (_isLoading)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            else ...[
              // Plats du jour
              if (_dailySpecials.isNotEmpty) ...[
                _buildSectionHeader('🔥 Plats du jour', onSeeAll: () {}),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _dailySpecials.length,
                      itemBuilder: (context, index) => _buildDailySpecialCard(_dailySpecials[index]),
                    ),
                  ),
                ),
              ],

              // Top restaurants
              _buildSectionHeader('⭐ Top restaurants', onSeeAll: () {}),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _topRestaurants.length,
                    itemBuilder: (context, index) => _buildTopRestaurantCard(_topRestaurants[index]),
                  ),
                ),
              ),

              // Restaurants à proximité
              if (_nearbyRestaurants.isNotEmpty) ...[
                _buildSectionHeader('📍 À proximité', onSeeAll: () {}),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildRestaurantTile(_nearbyRestaurants[index]),
                    childCount: _nearbyRestaurants.take(5).length,
                  ),
                ),
              ],

              // Plats populaires
              if (_topMenuItems.isNotEmpty) ...[
                _buildSectionHeader('🍽️ Plats populaires', onSeeAll: () {}),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 160,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _topMenuItems.length,
                      itemBuilder: (context, index) => _buildPopularItemCard(_topMenuItems[index]),
                    ),
                  ),
                ),
              ],

              // Espace en bas
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (onSeeAll != null)
              TextButton(
                onPressed: onSeeAll,
                child: const Text('Voir tout'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailySpecialCard(Map<String, dynamic> item) {
    final restaurant = item['restaurant'] as Map<String, dynamic>?;
    final specialPrice = item['daily_special_price'] as num?;
    final originalPrice = item['price'] as num;
    
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRouter.restaurantDetail, arguments: item['restaurant_id']),
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10)],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: item['image_url'] != null
                      ? CachedNetworkImage(
                          imageUrl: item['image_url'],
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          height: 100,
                          color: Colors.grey[200],
                          child: const Icon(Icons.restaurant, size: 40, color: Colors.grey),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        restaurant?['name'] ?? '',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (specialPrice != null) ...[
                            Text(
                              '${specialPrice.toStringAsFixed(0)} DA',
                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${originalPrice.toStringAsFixed(0)} DA',
                              style: TextStyle(
                                color: Colors.grey[400],
                                decoration: TextDecoration.lineThrough,
                                fontSize: 12,
                              ),
                            ),
                          ] else
                            Text(
                              '${originalPrice.toStringAsFixed(0)} DA',
                              style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'PROMO',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopRestaurantCard(Map<String, dynamic> restaurant) {
    // La fonction SQL retourne avg_prep_time, pas avg_delivery_time
    final prepTime = restaurant['avg_delivery_time'] ?? restaurant['avg_prep_time'] ?? 30;
    
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRouter.restaurantDetail, arguments: restaurant['id']),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: restaurant['cover_url'] != null || restaurant['logo_url'] != null
                      ? CachedNetworkImage(
                          imageUrl: restaurant['cover_url'] ?? restaurant['logo_url'],
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          height: 100,
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          child: Center(
                            child: Text(
                              (restaurant['name'] ?? 'R')[0].toUpperCase(),
                              style: TextStyle(fontSize: 40, color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        Text(
                          ' ${(restaurant['rating'] ?? 0).toStringAsFixed(1)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant['name'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    restaurant['cuisine_type'] ?? 'Restaurant',
                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                      Text(
                        ' $prepTime min',
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
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

  Widget _buildRestaurantTile(Map<String, dynamic> restaurant) {
    // La fonction SQL retourne distance_km, pas distance
    final distance = restaurant['distance'] ?? restaurant['distance_km'];
    
    return ListTile(
      onTap: () => Navigator.pushNamed(context, AppRouter.restaurantDetail, arguments: restaurant['id']),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
        backgroundImage: restaurant['logo_url'] != null ? CachedNetworkImageProvider(restaurant['logo_url']) : null,
        child: restaurant['logo_url'] == null
            ? Text((restaurant['name'] ?? 'R')[0], style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold))
            : null,
      ),
      title: Text(restaurant['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Row(
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 14),
          Text(' ${(restaurant['rating'] ?? 0).toStringAsFixed(1)}'),
          Text(' • ${restaurant['cuisine_type'] ?? ''}', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('${distance?.toStringAsFixed(1) ?? '?'} km', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('${restaurant['avg_prep_time'] ?? 30} min', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildPopularItemCard(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRouter.restaurantDetail, arguments: item['restaurant_id']),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: item['image_url'] != null
                  ? CachedNetworkImage(
                      imageUrl: item['image_url'],
                      height: 80,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: 80,
                      color: Colors.grey[200],
                      child: const Icon(Icons.fastfood, color: Colors.grey),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    item['restaurant_name'] ?? '',
                    style: TextStyle(color: Colors.grey[600], fontSize: 10),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(item['price'] as num).toStringAsFixed(0)} DA',
                        style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 12),
                          Text(' ${(item['avg_rating'] ?? 0).toStringAsFixed(1)}', style: const TextStyle(fontSize: 10)),
                        ],
                      ),
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

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Accueil', true, () {}),
              _buildNavItem(Icons.search, 'Explorer', false, () {}),
              _buildNavItem(Icons.shopping_bag_outlined, 'Commandes', false, 
                  () => Navigator.pushNamed(context, AppRouter.customerOrders)),
              _buildNavItem(Icons.favorite_border, 'Favoris', false, 
                  () => Navigator.pushNamed(context, AppRouter.favorites)),
              _buildNavItem(Icons.person_outline, 'Profil', false, 
                  () => Navigator.pushNamed(context, AppRouter.customerProfile)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? AppTheme.primaryColor : Colors.grey),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isActive ? AppTheme.primaryColor : Colors.grey,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
