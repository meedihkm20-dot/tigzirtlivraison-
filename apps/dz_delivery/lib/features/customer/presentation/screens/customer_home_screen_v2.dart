import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/design_system/theme/app_colors.dart';
import '../../../../core/design_system/theme/app_typography.dart';
import '../../../../core/design_system/theme/app_spacing.dart';
import '../../../../core/design_system/theme/app_shadows.dart';
import '../../../../core/design_system/components/loaders/skeleton_loader.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/router/app_router.dart';

/// Écran d'accueil Client V2 - Premium
/// Design moderne avec gradient teal, catégories, promos, recommandations
class CustomerHomeScreenV2 extends StatefulWidget {
  const CustomerHomeScreenV2({super.key});

  @override
  State<CustomerHomeScreenV2> createState() => _CustomerHomeScreenV2State();
}

class _CustomerHomeScreenV2State extends State<CustomerHomeScreenV2> {
  bool _isLoading = true;
  int _currentNavIndex = 0;
  
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _loyalty;
  List<Map<String, dynamic>> _topRestaurants = [];
  List<Map<String, dynamic>> _nearbyRestaurants = [];
  List<Map<String, dynamic>> _dailySpecials = [];
  List<Map<String, dynamic>> _categories = [];
  int _unreadNotifications = 0;
  int _cartItemCount = 0;

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _safeCall(() => SupabaseService.getProfile(), null),
        _safeCall(() => SupabaseService.getCustomerLoyalty(), {'points': 0, 'total_orders': 0}),
        _safeCall(() => SupabaseService.getTopRestaurants(limit: 6), <Map<String, dynamic>>[]),
        _safeCall(() => SupabaseService.getDailySpecials(), <Map<String, dynamic>>[]),
      ]);

      if (mounted) {
        setState(() {
          _profile = results[0] as Map<String, dynamic>?;
          _loyalty = results[1] as Map<String, dynamic>;
          _topRestaurants = results[2] as List<Map<String, dynamic>>;
          _dailySpecials = results[3] as List<Map<String, dynamic>>;
          _categories = _getCategories();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<T> _safeCall<T>(Future<T> Function() call, T defaultValue) async {
    try {
      return await call();
    } catch (e) {
      debugPrint('Erreur: $e');
      return defaultValue;
    }
  }

  List<Map<String, dynamic>> _getCategories() {
    return [
      {'name': 'Pizza', 'icon': '🍕', 'color': AppColors.error},
      {'name': 'Burger', 'icon': '🍔', 'color': AppColors.warning},
      {'name': 'Asiatique', 'icon': '🍜', 'color': AppColors.info},
      {'name': 'Salades', 'icon': '🥗', 'color': AppColors.success},
      {'name': 'Desserts', 'icon': '🍰', 'color': AppColors.primary},
      {'name': 'Café', 'icon': '☕', 'color': AppColors.tierBronze},
      {'name': 'Tacos', 'icon': '🌮', 'color': AppColors.warning},
      {'name': 'Sushi', 'icon': '🍣', 'color': AppColors.error},
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.clientPrimary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Header avec gradient
            _buildHeader(),
            
            // Contenu
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppColors.clientPrimary)),
              )
            else ...[
              // Catégories
              _buildCategoriesSection(),
              
              // Bannière promo
              _buildPromoBanner(),
              
              // Plats du jour
              if (_dailySpecials.isNotEmpty) _buildDailySpecialsSection(),
              
              // Top restaurants
              _buildTopRestaurantsSection(),
              
              // À proximité
              _buildNearbySection(),
              
              // Espace en bas
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }


  // ============================================
  // HEADER AVEC GRADIENT TEAL
  // ============================================
  Widget _buildHeader() {
    final firstName = _profile?['full_name']?.toString().split(' ').first ?? 'Client';
    final points = _loyalty?['points'] ?? 0;

    return SliverAppBar(
      expandedHeight: 200,
      floating: true,
      pinned: true,
      backgroundColor: AppColors.clientPrimary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.clientGradient,
          ),
          child: SafeArea(
            child: Padding(
              padding: AppSpacing.screen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Greeting
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bonjour $firstName 👋',
                            style: AppTypography.headlineSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Qu\'est-ce qui vous ferait plaisir?',
                            style: AppTypography.bodyMedium.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      // Points & Notifications
                      Row(
                        children: [
                          // Points badge
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, AppRouter.customerProfile),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: AppSpacing.borderRadiusRound,
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.stars, color: Colors.amber, size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$points',
                                    style: AppTypography.labelMedium.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
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
                                    decoration: const BoxDecoration(
                                      color: AppColors.error,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '$_unreadNotifications',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Search bar
                  _buildSearchBar(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to search screen
        HapticFeedback.lightImpact();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppSpacing.borderRadiusLg,
          boxShadow: AppShadows.md,
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: AppColors.textTertiary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Rechercher un restaurant, un plat...',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.clientSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.tune, color: AppColors.clientPrimary, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // CATÉGORIES
  // ============================================
  Widget _buildCategoriesSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: AppSpacing.screenHorizontal,
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              return _buildCategoryChip(category);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(Map<String, dynamic> category) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        // TODO: Filter by category
      },
      child: Container(
        width: 75,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: (category['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (category['color'] as Color).withOpacity(0.3),
                ),
              ),
              child: Center(
                child: Text(
                  category['icon'] as String,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category['name'] as String,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // BANNIÈRE PROMO
  // ============================================
  Widget _buildPromoBanner() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: AppSpacing.screen,
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B35), Color(0xFFFF8F66)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: AppSpacing.borderRadiusLg,
            boxShadow: AppShadows.md,
          ),
          child: Stack(
            children: [
              // Pattern
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  Icons.local_offer,
                  size: 150,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '🎉 OFFRE SPÉCIALE',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '-30% sur votre 1ère commande',
                      style: AppTypography.titleLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Code: BIENVENUE30',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // PLATS DU JOUR
  // ============================================
  Widget _buildDailySpecialsSection() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('🔥 Plats du jour', onSeeAll: () {}),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: AppSpacing.screenHorizontal,
              itemCount: _dailySpecials.length,
              itemBuilder: (context, index) {
                return _buildDailySpecialCard(_dailySpecials[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailySpecialCard(Map<String, dynamic> item) {
    final restaurant = item['restaurant'] as Map<String, dynamic>?;
    final specialPrice = item['daily_special_price'] as num?;
    final originalPrice = item['price'] as num;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pushNamed(context, AppRouter.restaurantDetail, arguments: item['restaurant_id']);
      },
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.borderRadiusLg,
          boxShadow: AppShadows.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: item['image_url'] != null
                      ? CachedNetworkImage(
                          imageUrl: item['image_url'],
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const SkeletonLoader(height: 100),
                          errorWidget: (_, __, ___) => Container(
                            height: 100,
                            color: AppColors.surfaceVariant,
                            child: const Icon(Icons.restaurant, color: AppColors.textTertiary),
                          ),
                        )
                      : Container(
                          height: 100,
                          color: AppColors.surfaceVariant,
                          child: const Icon(Icons.restaurant, color: AppColors.textTertiary),
                        ),
                ),
                // Badge promo
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'PROMO',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'] ?? '',
                    style: AppTypography.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    restaurant?['name'] ?? '',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (specialPrice != null) ...[
                        Text(
                          '${specialPrice.toStringAsFixed(0)} DA',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${originalPrice.toStringAsFixed(0)} DA',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textTertiary,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ] else
                        Text(
                          '${originalPrice.toStringAsFixed(0)} DA',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.clientPrimary,
                            fontWeight: FontWeight.bold,
                          ),
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


  // ============================================
  // TOP RESTAURANTS
  // ============================================
  Widget _buildTopRestaurantsSection() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('⭐ Top restaurants', onSeeAll: () {}),
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: AppSpacing.screenHorizontal,
              itemCount: _topRestaurants.length,
              itemBuilder: (context, index) {
                return _buildRestaurantCard(_topRestaurants[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantCard(Map<String, dynamic> restaurant) {
    final rating = (restaurant['rating'] as num?)?.toDouble() ?? 0;
    final prepTime = restaurant['avg_prep_time'] ?? 30;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pushNamed(context, AppRouter.restaurantDetail, arguments: restaurant['id']);
      },
      child: Container(
        width: 170,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.borderRadiusLg,
          boxShadow: AppShadows.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: restaurant['cover_url'] != null || restaurant['logo_url'] != null
                      ? CachedNetworkImage(
                          imageUrl: restaurant['cover_url'] ?? restaurant['logo_url'],
                          height: 110,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const SkeletonLoader(height: 110),
                          errorWidget: (_, __, ___) => _buildRestaurantPlaceholder(restaurant),
                        )
                      : _buildRestaurantPlaceholder(restaurant),
                ),
                // Rating badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: AppShadows.sm,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          rating.toStringAsFixed(1),
                          style: AppTypography.labelSmall.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Favorite button
                Positioned(
                  top: 8,
                  left: 8,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      // TODO: Toggle favorite
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: AppShadows.sm,
                      ),
                      child: const Icon(
                        Icons.favorite_border,
                        size: 18,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant['name'] ?? '',
                    style: AppTypography.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    restaurant['cuisine_type'] ?? 'Restaurant',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Text(
                        '$prepTime min',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.successSurface,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '🚚 Gratuit',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.success,
                            fontSize: 10,
                          ),
                        ),
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

  Widget _buildRestaurantPlaceholder(Map<String, dynamic> restaurant) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        gradient: AppColors.clientGradient,
      ),
      child: Center(
        child: Text(
          (restaurant['name'] ?? 'R')[0].toUpperCase(),
          style: AppTypography.displayMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ============================================
  // À PROXIMITÉ
  // ============================================
  Widget _buildNearbySection() {
    if (_topRestaurants.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('📍 À proximité', onSeeAll: () {}),
          Padding(
            padding: AppSpacing.screenHorizontal,
            child: Column(
              children: _topRestaurants.take(5).map((r) => _buildRestaurantTile(r)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantTile(Map<String, dynamic> restaurant) {
    final rating = (restaurant['rating'] as num?)?.toDouble() ?? 0;
    final prepTime = restaurant['avg_prep_time'] ?? 30;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pushNamed(context, AppRouter.restaurantDetail, arguments: restaurant['id']);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.borderRadiusMd,
          boxShadow: AppShadows.sm,
        ),
        child: Row(
          children: [
            // Logo
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: restaurant['logo_url'] != null
                  ? CachedNetworkImage(
                      imageUrl: restaurant['logo_url'],
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const SkeletonLoader(width: 60, height: 60),
                      errorWidget: (_, __, ___) => _buildSmallPlaceholder(restaurant),
                    )
                  : _buildSmallPlaceholder(restaurant),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant['name'] ?? '',
                    style: AppTypography.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 2),
                      Text(
                        rating.toStringAsFixed(1),
                        style: AppTypography.labelSmall,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• ${restaurant['cuisine_type'] ?? 'Restaurant'}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Time & Distance
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '0.8 km',
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$prepTime min',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallPlaceholder(Map<String, dynamic> restaurant) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: AppColors.clientGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          (restaurant['name'] ?? 'R')[0].toUpperCase(),
          style: AppTypography.titleLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ============================================
  // HELPERS
  // ============================================
  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTypography.titleMedium),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: Text(
                'Voir tout',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.clientPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================
  // BOTTOM NAVIGATION
  // ============================================
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppShadows.lg,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home, 'Accueil'),
              _buildNavItem(1, Icons.search, 'Explorer'),
              _buildNavItem(2, Icons.shopping_bag_outlined, 'Commandes'),
              _buildNavItem(3, Icons.favorite_border, 'Favoris'),
              _buildNavItem(4, Icons.person_outline, 'Profil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentNavIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _currentNavIndex = index);
        switch (index) {
          case 2:
            Navigator.pushNamed(context, AppRouter.customerOrders);
            break;
          case 3:
            Navigator.pushNamed(context, AppRouter.favorites);
            break;
          case 4:
            Navigator.pushNamed(context, AppRouter.customerProfile);
            break;
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.clientSurface : Colors.transparent,
          borderRadius: AppSpacing.borderRadiusRound,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.clientPrimary : AppColors.textTertiary,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.clientPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
