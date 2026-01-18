import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/design_system/theme/app_colors.dart';
import '../../../../core/design_system/theme/app_typography.dart';
import '../../../../core/design_system/theme/app_spacing.dart';
import '../../../../core/design_system/theme/app_shadows.dart';
import '../../../../core/design_system/components/badges/status_badge.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/router/app_router.dart';
import '../../../../providers/providers.dart';

/// Écran détail restaurant premium V2
/// Design attractif et séduisant pour le client
class RestaurantDetailScreenV2 extends ConsumerStatefulWidget {
  final String restaurantId;

  const RestaurantDetailScreenV2({super.key, required this.restaurantId});

  @override
  ConsumerState<RestaurantDetailScreenV2> createState() => _RestaurantDetailScreenV2State();
}

class _RestaurantDetailScreenV2State extends ConsumerState<RestaurantDetailScreenV2>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _restaurant;
  List<Map<String, dynamic>> _menuItems = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _reviews = [];
  List<Map<String, dynamic>> _gallery = [];
  bool _isLoading = true;
  bool _isFavorite = false;
  
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  double _headerOpacity = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController.addListener(_onScroll);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    setState(() {
      _headerOpacity = (offset / 200).clamp(0.0, 1.0);
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final restaurant = await SupabaseService.getRestaurantById(widget.restaurantId);
      final menuItems = await SupabaseService.getRestaurantMenuItems(widget.restaurantId);
      final categories = await SupabaseService.getRestaurantCategories(widget.restaurantId);
      final reviews = await SupabaseService.getRestaurantReviews(widget.restaurantId);
      
      // Charger l'état favori depuis le provider
      final isFav = ref.read(favoritesProvider).isRestaurantFavorite(widget.restaurantId);
      
      if (mounted) {
        setState(() {
          _restaurant = restaurant;
          _menuItems = menuItems;
          _categories = categories;
          _reviews = reviews;
          _isFavorite = isFav;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement restaurant: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFavorite() async {
    HapticFeedback.lightImpact();
    setState(() => _isFavorite = !_isFavorite);
    // Utiliser le provider pour toggle le favori
    await ref.read(favoritesProvider.notifier).toggleRestaurantFavorite(widget.restaurantId);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_restaurant == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Restaurant non trouvé')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Header avec image
          _buildSliverAppBar(),
          
          // Contenu
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Info principale
                _buildMainInfo(),
                
                // Badges
                _buildBadges(),
                
                // Tabs
                _buildTabs(),
              ],
            ),
          ),
          
          // Contenu des tabs
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMenuTab(),
                _buildInfoTab(),
                _buildReviewsTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildSliverAppBar() {
    final coverUrl = _restaurant!['cover_url'] ?? _restaurant!['logo_url'];
    
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.surface,
      leading: _buildBackButton(),
      actions: [
        _buildFavoriteButton(),
        _buildShareButton(),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Image de couverture
            if (coverUrl != null)
              CachedNetworkImage(
                imageUrl: coverUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.surfaceVariant,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.primarySurface,
                  child: const Icon(Icons.restaurant, size: 64, color: AppColors.primary),
                ),
              )
            else
              Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: const Icon(Icons.restaurant, size: 64, color: Colors.white),
              ),
            
            // Overlay gradient
            Container(
              decoration: const BoxDecoration(
                gradient: AppColors.darkOverlay,
              ),
            ),
            
            // Status ouvert/fermé
            Positioned(
              top: 100,
              right: 16,
              child: _buildOpenStatus(),
            ),
            
            // Logo restaurant
            Positioned(
              bottom: 16,
              left: 16,
              child: _buildRestaurantLogo(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildFavoriteButton() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(
          _isFavorite ? Icons.favorite : Icons.favorite_border,
          color: _isFavorite ? AppColors.error : Colors.white,
        ),
        onPressed: _toggleFavorite,
      ),
    );
  }

  Widget _buildShareButton() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: const Icon(Icons.share, color: Colors.white),
        onPressed: () {
          // TODO: Partager
        },
      ),
    );
  }

  Widget _buildOpenStatus() {
    final isOpen = _restaurant!['is_open'] ?? false;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOpen ? AppColors.success : AppColors.error,
        borderRadius: AppSpacing.borderRadiusRound,
        boxShadow: AppShadows.md,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isOpen ? 'Ouvert' : 'Fermé',
            style: AppTypography.labelMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantLogo() {
    final logoUrl = _restaurant!['logo_url'];
    
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        boxShadow: AppShadows.lg,
        border: Border.all(color: Colors.white, width: 3),
        image: logoUrl != null
            ? DecorationImage(
                image: CachedNetworkImageProvider(logoUrl),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: logoUrl == null
          ? const Icon(Icons.restaurant, color: AppColors.primary, size: 40)
          : null,
    );
  }

  Widget _buildMainInfo() {
    final rating = (_restaurant!['rating'] ?? 0).toDouble();
    final reviewCount = _restaurant!['total_reviews'] ?? 0;
    final deliveryFee = (_restaurant!['delivery_fee'] ?? 0).toDouble();
    final minOrder = (_restaurant!['min_order_amount'] ?? 0).toDouble();
    final avgPrepTime = _restaurant!['avg_prep_time'] ?? 30;

    return Container(
      padding: AppSpacing.screen,
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nom et note
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _restaurant!['name'] ?? '',
                      style: AppTypography.headlineMedium,
                    ),
                    AppSpacing.vXs,
                    Text(
                      _restaurant!['cuisine_type'] ?? 'Restaurant',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Note
              GestureDetector(
                onTap: () => _tabController.animateTo(2),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.warningSurface,
                    borderRadius: AppSpacing.borderRadiusMd,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: AppColors.warning, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '($reviewCount)',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          AppSpacing.vMd,
          
          // Infos rapides
          Row(
            children: [
              _buildInfoChip(
                icon: Icons.delivery_dining,
                label: deliveryFee > 0 ? '${deliveryFee.toStringAsFixed(0)} DA' : 'Gratuit',
                color: AppColors.success,
              ),
              AppSpacing.hSm,
              _buildInfoChip(
                icon: Icons.timer,
                label: '$avgPrepTime min',
                color: AppColors.info,
              ),
              AppSpacing.hSm,
              _buildInfoChip(
                icon: Icons.shopping_bag,
                label: 'Min ${minOrder.toStringAsFixed(0)} DA',
                color: AppColors.secondary,
              ),
            ],
          ),
          
          AppSpacing.vMd,
          
          // Adresse
          Row(
            children: [
              const Icon(Icons.location_on, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _restaurant!['address'] ?? '',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Ouvrir la carte
                },
                child: const Text('Voir sur la carte'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppSpacing.borderRadiusRound,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadges() {
    final isVerified = _restaurant!['is_verified'] ?? false;
    final rating = (_restaurant!['rating'] ?? 0).toDouble();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (isVerified) ...[
              const CertificationBadge(type: 'verified'),
              AppSpacing.hSm,
            ],
            if (rating >= 4.5) ...[
              const CertificationBadge(type: 'top_rated'),
              AppSpacing.hSm,
            ],
            const CertificationBadge(type: 'fast_delivery'),
            AppSpacing.hSm,
            const CertificationBadge(type: 'popular'),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: AppColors.surface,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        tabs: const [
          Tab(text: 'Menu'),
          Tab(text: 'Infos'),
          Tab(text: 'Avis'),
        ],
      ),
    );
  }

  Widget _buildMenuTab() {
    if (_menuItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 64, color: AppColors.textTertiary),
            AppSpacing.vMd,
            Text(
              'Aucun plat disponible',
              style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    // Grouper par catégorie
    final itemsByCategory = <String, List<Map<String, dynamic>>>{};
    for (final item in _menuItems) {
      final categoryName = item['category']?['name'] ?? 'Autres';
      itemsByCategory.putIfAbsent(categoryName, () => []).add(item);
    }

    return ListView.builder(
      padding: AppSpacing.screen,
      itemCount: itemsByCategory.length,
      itemBuilder: (context, index) {
        final category = itemsByCategory.keys.elementAt(index);
        final items = itemsByCategory[category]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index > 0) AppSpacing.vLg,
            Text(
              category,
              style: AppTypography.titleMedium,
            ),
            AppSpacing.vMd,
            ...items.map((item) => _buildMenuItem(item)),
          ],
        );
      },
    );
  }

  Widget _buildMenuItem(Map<String, dynamic> item) {
    final price = (item['price'] ?? 0).toDouble();
    final isAvailable = item['is_available'] ?? true;
    final isDailySpecial = item['is_daily_special'] ?? false;
    final imageUrl = item['image_url'];

    return GestureDetector(
      onTap: isAvailable ? () => _addToCart(item) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.borderRadiusLg,
          boxShadow: AppShadows.sm,
          border: isDailySpecial
              ? Border.all(color: AppColors.warning, width: 2)
              : null,
        ),
        child: Row(
          children: [
            // Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: AppSpacing.borderRadiusMd,
                color: AppColors.surfaceVariant,
                image: imageUrl != null
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(imageUrl),
                        fit: BoxFit.cover,
                        colorFilter: !isAvailable
                            ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                            : null,
                      )
                    : null,
              ),
              child: Stack(
                children: [
                  if (imageUrl == null)
                    const Center(
                      child: Icon(Icons.fastfood, color: AppColors.textTertiary),
                    ),
                  if (isDailySpecial)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.warning,
                          borderRadius: AppSpacing.borderRadiusSm,
                        ),
                        child: Text(
                          '🔥 PROMO',
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 8,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            AppSpacing.hMd,
            
            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'] ?? '',
                    style: AppTypography.titleSmall.copyWith(
                      color: isAvailable ? AppColors.textPrimary : AppColors.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item['description'] != null) ...[
                    AppSpacing.vXs,
                    Text(
                      item['description'],
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  AppSpacing.vSm,
                  Row(
                    children: [
                      Text(
                        '${price.toStringAsFixed(0)} DA',
                        style: AppTypography.priceMedium.copyWith(
                          color: isAvailable ? AppColors.primary : AppColors.textTertiary,
                        ),
                      ),
                      if (!isAvailable) ...[
                        AppSpacing.hSm,
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.errorSurface,
                            borderRadius: AppSpacing.borderRadiusSm,
                          ),
                          child: Text(
                            'Indisponible',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            
            // Bouton ajouter
            if (isAvailable)
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: AppSpacing.borderRadiusMd,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
          ],
        ),
      ),
    );
  }

  void _addToCart(Map<String, dynamic> item) {
    HapticFeedback.mediumImpact();
    
    // Utiliser le cartProvider pour ajouter au panier
    ref.read(cartProvider.notifier).addFromMenuItem(
      item,
      widget.restaurantId,
      _restaurant?['name'] ?? 'Restaurant',
    );
    
    // Afficher le nombre d'articles dans le panier
    final cartCount = ref.read(cartItemCountProvider);
    
    // ✅ Utilisation du Top Toast non intrusif
    _showTopToast('${item['name']} ajouté! ($cartCount)');
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: AppSpacing.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // À propos
          _buildSection(
            title: '📖 À propos',
            child: Text(
              _restaurant!['description'] ?? 'Bienvenue dans notre restaurant ! Nous vous proposons une cuisine de qualité avec des ingrédients frais et locaux.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ),
          
          AppSpacing.vLg,
          
          // Horaires
          _buildSection(
            title: '⏰ Horaires d\'ouverture',
            child: Column(
              children: [
                _buildHoursRow('Lundi - Vendredi', '${_restaurant!['opening_time'] ?? '08:00'} - ${_restaurant!['closing_time'] ?? '23:00'}'),
                _buildHoursRow('Samedi - Dimanche', '${_restaurant!['opening_time'] ?? '08:00'} - ${_restaurant!['closing_time'] ?? '23:00'}'),
              ],
            ),
          ),
          
          AppSpacing.vLg,
          
          // Contact
          _buildSection(
            title: '📞 Contact',
            child: Column(
              children: [
                _buildContactRow(
                  icon: Icons.phone,
                  label: _restaurant!['phone'] ?? '+213 555 000 000',
                  onTap: () {
                    // TODO: Appeler
                  },
                ),
                AppSpacing.vSm,
                _buildContactRow(
                  icon: Icons.location_on,
                  label: _restaurant!['address'] ?? '',
                  onTap: () {
                    // TODO: Ouvrir carte
                  },
                ),
              ],
            ),
          ),
          
          AppSpacing.vLg,
          
          // Infos livraison
          _buildSection(
            title: '🚚 Livraison',
            child: Column(
              children: [
                _buildInfoRow('Frais de livraison', '${(_restaurant!['delivery_fee'] ?? 0).toStringAsFixed(0)} DA'),
                _buildInfoRow('Commande minimum', '${(_restaurant!['min_order_amount'] ?? 0).toStringAsFixed(0)} DA'),
                _buildInfoRow('Temps de préparation', '${_restaurant!['avg_prep_time'] ?? 30} min'),
              ],
            ),
          ),
          
          AppSpacing.vXxl,
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.titleMedium),
        AppSpacing.vMd,
        Container(
          width: double.infinity,
          padding: AppSpacing.card,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppSpacing.borderRadiusLg,
            boxShadow: AppShadows.sm,
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _buildHoursRow(String day, String hours) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(day, style: AppTypography.bodyMedium),
          Text(
            hours,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: AppSpacing.borderRadiusMd,
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          AppSpacing.hMd,
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodyMedium,
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textTertiary),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    if (_reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review, size: 64, color: AppColors.textTertiary),
            AppSpacing.vMd,
            Text(
              'Aucun avis pour le moment',
              style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
            ),
            AppSpacing.vSm,
            Text(
              'Soyez le premier à donner votre avis !',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: AppSpacing.screen,
      itemCount: _reviews.length,
      itemBuilder: (context, index) => _buildReviewCard(_reviews[index]),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final rating = (review['rating'] ?? 0).toDouble();
    final userName = review['user']?['full_name'] ?? 'Client';
    final comment = review['comment'] ?? '';
    final createdAt = DateTime.tryParse(review['created_at'] ?? '') ?? DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'C',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              AppSpacing.hMd,
              
              // Nom et date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName, style: AppTypography.titleSmall),
                    Text(
                      _formatDate(createdAt),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Note
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < rating ? Icons.star : Icons.star_border,
                    color: AppColors.warning,
                    size: 18,
                  );
                }),
              ),
            ],
          ),
          
          if (comment.isNotEmpty) ...[
            AppSpacing.vMd,
            Text(
              comment,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) return 'Aujourd\'hui';
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} jours';
    if (diff.inDays < 30) return 'Il y a ${(diff.inDays / 7).floor()} semaines';
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildBottomBar() {
    final cartCount = ref.watch(cartItemCountProvider);
    final cartSubtotal = ref.watch(cartSubtotalProvider);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppShadows.lg,
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Panier avec compteur
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRouter.cart),
                icon: Badge(
                  isLabelVisible: cartCount > 0,
                  label: Text('$cartCount'),
                  child: const Icon(Icons.shopping_cart),
                ),
                label: Text(
                  cartCount > 0 
                    ? 'Panier (${cartSubtotal.toStringAsFixed(0)} DA)'
                    : 'Voir le panier',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Notification personnalisée en haut (Overlay)
  void _showTopToast(String message, {Color color = AppColors.success}) {
    if (!mounted) return;
    
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16, // En haut (sous la status bar)
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, -20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      message,
                      style: AppTypography.labelLarge.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    
    // Auto remove après 2 secondes (rapide)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        overlayEntry.remove();
      }
    });
  }
}
