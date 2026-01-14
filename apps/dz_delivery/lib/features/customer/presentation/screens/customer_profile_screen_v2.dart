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

/// Écran Profil Client V2 - Premium
/// Gamification complète: niveaux, badges, fidélité, stats, parrainage
class CustomerProfileScreenV2 extends StatefulWidget {
  const CustomerProfileScreenV2({super.key});

  @override
  State<CustomerProfileScreenV2> createState() => _CustomerProfileScreenV2State();
}

class _CustomerProfileScreenV2State extends State<CustomerProfileScreenV2>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _loyalty;
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _badges = [];
  List<Map<String, dynamic>> _recentOrders = [];
  
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );
    _loadData();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }


  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _safeCall(() => SupabaseService.getProfile(), null),
        _safeCall(() => SupabaseService.getCustomerLoyalty(), <String, dynamic>{}),
        _safeCall(() => SupabaseService.getCustomerStats(), <String, dynamic>{}),
        _safeCall(() => SupabaseService.getCustomerBadges(), <Map<String, dynamic>>[]),
        _safeCall(() => SupabaseService.getRecentOrders(limit: 3), <Map<String, dynamic>>[]),
      ]);

      if (mounted) {
        setState(() {
          _profile = results[0] as Map<String, dynamic>?;
          _loyalty = results[1] as Map<String, dynamic>;
          _stats = results[2] as Map<String, dynamic>;
          _badges = results[3] as List<Map<String, dynamic>>;
          _recentOrders = results[4] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
        _progressController.forward();
      }
    } catch (e) {
      debugPrint('Erreur chargement profil: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<T> _safeCall<T>(Future<T> Function() call, T defaultValue) async {
    try {
      return await call();
    } catch (e) {
      return defaultValue;
    }
  }

  // Loyalty level calculation
  int get _currentLevel => ((_loyalty?['points'] ?? 0) / 500).floor() + 1;
  int get _pointsInLevel => (_loyalty?['points'] ?? 0) % 500;
  int get _pointsToNextLevel => 500 - _pointsInLevel;
  double get _levelProgress => _pointsInLevel / 500;

  String get _levelName {
    if (_currentLevel >= 5) return 'Diamant';
    if (_currentLevel >= 4) return 'Or';
    if (_currentLevel >= 3) return 'Argent';
    if (_currentLevel >= 2) return 'Bronze';
    return 'Débutant';
  }

  Color get _levelColor {
    if (_currentLevel >= 5) return AppColors.tierDiamond;
    if (_currentLevel >= 4) return AppColors.tierGold;
    if (_currentLevel >= 3) return AppColors.tierSilver;
    if (_currentLevel >= 2) return AppColors.tierBronze;
    return AppColors.textTertiary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.clientPrimary))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.clientPrimary,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  _buildHeader(),
                  SliverToBoxAdapter(child: _buildLoyaltyCard()),
                  SliverToBoxAdapter(child: _buildStatsGrid()),
                  SliverToBoxAdapter(child: _buildBadgesSection()),
                  SliverToBoxAdapter(child: _buildRecentOrders()),
                  SliverToBoxAdapter(child: _buildMenuSection()),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    final name = _profile?['full_name'] ?? 'Client';
    final email = _profile?['email'] ?? '';
    final avatarUrl = _profile?['avatar_url'];

    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppColors.clientPrimary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed: () => _showSettings(),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: AppColors.clientGradient),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                // Avatar
                Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: AppShadows.lg,
                      ),
                      child: ClipOval(
                        child: avatarUrl != null
                            ? CachedNetworkImage(
                                imageUrl: avatarUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => const SkeletonLoader(),
                                errorWidget: (_, __, ___) => _buildAvatarPlaceholder(name),
                              )
                            : _buildAvatarPlaceholder(name),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _levelColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Text(
                          '$_currentLevel',
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: AppTypography.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.workspace_premium, color: _levelColor, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            _levelName,
                            style: AppTypography.labelMedium.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder(String name) {
    return Container(
      color: AppColors.clientPrimaryDark,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'C',
          style: AppTypography.displayMedium.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildLoyaltyCard() {
    final points = _loyalty?['points'] ?? 0;

    return Container(
      margin: AppSpacing.screen,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        boxShadow: AppShadows.md,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Points fidélité', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.stars, color: Colors.amber, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        '$points',
                        style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(' pts', style: AppTypography.titleMedium.copyWith(color: AppColors.textTertiary)),
                    ],
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: _showRewardsSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.clientPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Échanger'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Niveau $_currentLevel → ${_currentLevel + 1}',
                    style: AppTypography.labelMedium,
                  ),
                  Text(
                    '$_pointsToNextLevel pts restants',
                    style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) => Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: _levelProgress * _progressAnimation.value,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: AppColors.clientGradient,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Benefits
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.clientSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.card_giftcard, color: AppColors.clientPrimary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Prochain avantage: Livraison gratuite',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.clientPrimary),
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.clientPrimary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final totalOrders = _stats?['total_orders'] ?? 0;
    final totalSpent = (_stats?['total_spent'] as num?)?.toDouble() ?? 0;
    final avgRating = (_stats?['avg_rating'] as num?)?.toDouble() ?? 0;
    final favoriteRestaurant = _stats?['favorite_restaurant'] ?? '-';

    return Padding(
      padding: AppSpacing.screenHorizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vos statistiques', style: AppTypography.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatCard('🛒', '$totalOrders', 'Commandes')),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('💰', '${(totalSpent / 1000).toStringAsFixed(1)}K', 'DA dépensés')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatCard('⭐', avgRating.toStringAsFixed(1), 'Note moyenne')),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('❤️', favoriteRestaurant, 'Favori')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String emoji, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusMd,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }


  Widget _buildBadgesSection() {
    if (_badges.isEmpty) {
      // Show default badges
      _badges = [
        {'id': '1', 'name': 'Première commande', 'icon': '🎉', 'unlocked': true},
        {'id': '2', 'name': 'Gourmet', 'icon': '🍽️', 'unlocked': true},
        {'id': '3', 'name': 'Fidèle', 'icon': '💎', 'unlocked': false},
        {'id': '4', 'name': 'Explorateur', 'icon': '🗺️', 'unlocked': false},
        {'id': '5', 'name': 'Généreux', 'icon': '💝', 'unlocked': false},
        {'id': '6', 'name': 'VIP', 'icon': '👑', 'unlocked': false},
      ];
    }

    return Padding(
      padding: AppSpacing.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Badges', style: AppTypography.titleMedium),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRouter.badges),
                child: Text(
                  'Voir tout',
                  style: AppTypography.labelMedium.copyWith(color: AppColors.clientPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _badges.length,
              itemBuilder: (context, index) => _buildBadgeItem(_badges[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeItem(Map<String, dynamic> badge) {
    final unlocked = badge['unlocked'] == true;
    
    return GestureDetector(
      onTap: () => _showBadgeDetails(badge),
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: unlocked ? AppColors.clientSurface : AppColors.surfaceVariant,
                shape: BoxShape.circle,
                border: unlocked 
                    ? Border.all(color: AppColors.clientPrimary, width: 2)
                    : null,
              ),
              child: Center(
                child: Opacity(
                  opacity: unlocked ? 1 : 0.3,
                  child: Text(
                    badge['icon'] ?? '🏆',
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              badge['name'] ?? '',
              style: AppTypography.labelSmall.copyWith(
                color: unlocked ? AppColors.textPrimary : AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrders() {
    return Padding(
      padding: AppSpacing.screenHorizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Commandes récentes', style: AppTypography.titleMedium),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRouter.customerOrders),
                child: Text(
                  'Historique',
                  style: AppTypography.labelMedium.copyWith(color: AppColors.clientPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_recentOrders.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppSpacing.borderRadiusMd,
              ),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.receipt_long, size: 48, color: AppColors.textTertiary),
                    const SizedBox(height: 12),
                    Text(
                      'Aucune commande récente',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._recentOrders.map((order) => _buildOrderItem(order)),
        ],
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> order) {
    final status = order['status'] ?? 'pending';
    final total = (order['total'] as num?)?.toDouble() ?? 0;
    final date = order['created_at'] != null 
        ? DateTime.parse(order['created_at'])
        : DateTime.now();

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRouter.orderTracking, arguments: order['id']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.borderRadiusMd,
          boxShadow: AppShadows.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.getStatusColor(status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getStatusIcon(status),
                color: AppColors.getStatusColor(status),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order['restaurant_name'] ?? 'Restaurant',
                    style: AppTypography.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}/${date.month}/${date.year} • ${total.toStringAsFixed(0)} DA',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.getStatusColor(status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getStatusLabel(status),
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.getStatusColor(status),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection() {
    final menuItems = [
      {'icon': Icons.location_on, 'label': 'Mes adresses', 'route': AppRouter.savedAddresses},
      {'icon': Icons.favorite, 'label': 'Favoris', 'route': AppRouter.favorites},
      {'icon': Icons.card_giftcard, 'label': 'Parrainage', 'route': AppRouter.referral},
      {'icon': Icons.notifications, 'label': 'Notifications', 'route': AppRouter.notifications},
      {'icon': Icons.help_outline, 'label': 'Aide & Support', 'route': null},
      {'icon': Icons.info_outline, 'label': 'À propos', 'route': null},
    ];

    return Padding(
      padding: AppSpacing.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Menu', style: AppTypography.titleMedium),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppSpacing.borderRadiusMd,
              boxShadow: AppShadows.sm,
            ),
            child: Column(
              children: menuItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isLast = index == menuItems.length - 1;
                
                return Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.clientSurface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(item['icon'] as IconData, color: AppColors.clientPrimary, size: 20),
                      ),
                      title: Text(item['label'] as String, style: AppTypography.bodyMedium),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        final route = item['route'] as String?;
                        if (route != null) {
                          Navigator.pushNamed(context, route);
                        }
                      },
                    ),
                    if (!isLast) const Divider(height: 1, indent: 60),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          // Logout button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: Text(
                'Déconnexion',
                style: AppTypography.labelMedium.copyWith(color: AppColors.error),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // HELPERS & ACTIONS
  // ============================================

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'delivered': return Icons.check_circle;
      case 'cancelled': return Icons.cancel;
      case 'picked_up': return Icons.delivery_dining;
      default: return Icons.pending;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending': return 'En attente';
      case 'confirmed': return 'Confirmée';
      case 'preparing': return 'Préparation';
      case 'ready': return 'Prête';
      case 'picked_up': return 'En route';
      case 'delivered': return 'Livrée';
      case 'cancelled': return 'Annulée';
      default: return status;
    }
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Modifier le profil'),
              onTap: () {
                Navigator.pop(ctx);
                // TODO: Edit profile
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('Mode sombre'),
              trailing: Switch(
                value: false,
                onChanged: (v) {},
                activeColor: AppColors.clientPrimary,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Langue'),
              subtitle: const Text('Français'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: AppColors.error),
              title: Text('Supprimer le compte', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(ctx);
                _showDeleteAccountDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRewardsSheet() {
    final rewards = [
      {'points': 100, 'reward': 'Livraison gratuite', 'icon': '🚚'},
      {'points': 250, 'reward': '-10% sur commande', 'icon': '🏷️'},
      {'points': 500, 'reward': 'Dessert offert', 'icon': '🍰'},
      {'points': 1000, 'reward': '-25% sur commande', 'icon': '🎁'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Échanger vos points', style: AppTypography.titleMedium),
            const SizedBox(height: 16),
            ...rewards.map((r) => ListTile(
              leading: Text(r['icon'] as String, style: const TextStyle(fontSize: 28)),
              title: Text(r['reward'] as String),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (_loyalty?['points'] ?? 0) >= (r['points'] as int)
                      ? AppColors.clientPrimary
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${r['points']} pts',
                  style: AppTypography.labelSmall.copyWith(
                    color: (_loyalty?['points'] ?? 0) >= (r['points'] as int)
                        ? Colors.white
                        : AppColors.textTertiary,
                  ),
                ),
              ),
              onTap: (_loyalty?['points'] ?? 0) >= (r['points'] as int)
                  ? () => _redeemReward(r)
                  : null,
            )),
          ],
        ),
      ),
    );
  }

  void _showBadgeDetails(Map<String, dynamic> badge) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(badge['icon'] ?? '🏆', style: const TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            Text(badge['name'] ?? '', style: AppTypography.titleMedium),
            const SizedBox(height: 8),
            Text(
              badge['unlocked'] == true
                  ? 'Badge débloqué! 🎉'
                  : 'Continuez pour débloquer ce badge',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _redeemReward(Map<String, dynamic> reward) {
    HapticFeedback.heavyImpact();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${reward['reward']} échangé! 🎉'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le compte?'),
        content: const Text('Cette action est irréversible. Toutes vos données seront supprimées.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: Delete account
            },
            child: Text('Supprimer', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _logout() async {
    HapticFeedback.mediumImpact();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Déconnexion', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SupabaseService.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, AppRouter.login, (route) => false);
      }
    }
  }
}
