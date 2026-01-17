import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/design_system/theme/app_colors.dart';
import '../../../../core/design_system/theme/app_typography.dart';
import '../../../../core/design_system/theme/app_spacing.dart';
import '../../../../core/design_system/theme/app_shadows.dart';
import '../../../../core/design_system/components/loaders/skeleton_loader.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/onesignal_service.dart';
import '../../../../core/services/preferences_service.dart';
import '../../../../core/router/app_router.dart';
import '../../../../main.dart';

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
  Map<String, dynamic>? _stats;
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
        _safeCall(() => SupabaseService.getCustomerStats(), <String, dynamic>{}),
        _safeCall(() => SupabaseService.getRecentOrders(limit: 3), <Map<String, dynamic>>[]),
      ]);

      if (mounted) {
        setState(() {
          _profile = results[0] as Map<String, dynamic>?;
          _stats = results[1] as Map<String, dynamic>;
          _recentOrders = results[2] as List<Map<String, dynamic>>;
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
                  SliverToBoxAdapter(child: _buildStatsGrid()),
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
                      child: GestureDetector(
                        onTap: _changeProfilePicture,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.clientPrimary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: AppShadows.sm,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 16,
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
                Text(
                  email,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
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
      {'icon': Icons.notifications, 'label': 'Notifications', 'route': AppRouter.notifications},
      {'icon': Icons.bug_report, 'label': 'Test Notifications', 'route': null, 'action': 'test_notifications'},
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
                        final action = item['action'] as String?;
                        
                        if (action == 'test_notifications') {
                          _testNotifications();
                        } else if (route != null) {
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
                _editProfile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('Mode sombre'),
              trailing: Switch(
                value: PreferencesService.isDarkMode,
                onChanged: (value) async {
                  await PreferencesService.setDarkMode(value);
                  // Mettre à jour le thème de l'app
                  if (mounted) {
                    DZDeliveryApp.setThemeMode(
                      value ? ThemeMode.dark : ThemeMode.light,
                    );
                  }
                },
                activeColor: AppColors.clientPrimary,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Langue'),
              subtitle: Text(_getLanguageLabel(PreferencesService.language)),
              onTap: () {
                Navigator.pop(ctx);
                _showLanguageSelector();
              },
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

  /// Changer la photo de profil
  void _changeProfilePicture() async {
    HapticFeedback.lightImpact();
    
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
            const Text(
              'Changer la photo de profil',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceOption(
                  icon: Icons.camera_alt,
                  label: 'Caméra',
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildImageSourceOption(
                  icon: Icons.photo_library,
                  label: 'Galerie',
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                if (_profile?['avatar_url'] != null)
                  _buildImageSourceOption(
                    icon: Icons.delete,
                    label: 'Supprimer',
                    color: AppColors.error,
                    onTap: () {
                      Navigator.pop(ctx);
                      _removeProfilePicture();
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: (color ?? AppColors.clientPrimary).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color ?? AppColors.clientPrimary,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color ?? AppColors.textPrimary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Sélectionner et uploader une image
  void _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image == null) return;

      // Afficher un loader
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(color: AppColors.clientPrimary),
        ),
      );

      // Upload vers Supabase Storage
      final bytes = await image.readAsBytes();
      final userId = SupabaseService.currentUserId;
      final fileName = 'avatar_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      final avatarUrl = await SupabaseService.uploadAvatar(fileName, bytes);
      
      // Mettre à jour le profil
      await SupabaseService.updateProfile({'avatar_url': avatarUrl});
      
      // Recharger les données
      await _loadData();
      
      if (mounted) {
        Navigator.pop(context); // Fermer le loader
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo de profil mise à jour! 📸'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Fermer le loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Supprimer la photo de profil
  void _removeProfilePicture() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(color: AppColors.clientPrimary),
        ),
      );

      await SupabaseService.updateProfile({'avatar_url': null});
      await _loadData();
      
      if (mounted) {
        Navigator.pop(context); // Fermer le loader
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo de profil supprimée'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Obtenir le label de la langue
  String _getLanguageLabel(String languageCode) {
    switch (languageCode) {
      case 'fr':
        return 'Français';
      case 'ar':
        return 'العربية';
      case 'en':
        return 'English';
      default:
        return 'Français';
    }
  }

  /// Afficher le sélecteur de langue
  void _showLanguageSelector() {
    final languages = [
      {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
      {'code': 'ar', 'name': 'العربية', 'flag': '🇩🇿'},
      {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choisir la langue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.map((lang) => ListTile(
            leading: Text(lang['flag']!, style: const TextStyle(fontSize: 24)),
            title: Text(lang['name']!),
            trailing: PreferencesService.language == lang['code']
                ? const Icon(Icons.check, color: AppColors.clientPrimary)
                : null,
            onTap: () async {
              await PreferencesService.setLanguage(lang['code']!);
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Langue changée: ${lang['name']}'),
                    backgroundColor: AppColors.success,
                  ),
                );
                // Note: Pour une implémentation complète, il faudrait redémarrer l'app
                // ou utiliser un système d'internationalisation comme flutter_localizations
              }
            },
          )).toList(),
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

  /// Éditer le profil utilisateur
  void _editProfile() {
    final nameController = TextEditingController(text: _profile?['full_name'] ?? '');
    final phoneController = TextEditingController(text: _profile?['phone'] ?? '');
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modifier le profil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nom complet',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final phone = phoneController.text.trim();
              
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Le nom ne peut pas être vide'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              
              try {
                Navigator.pop(ctx);
                
                // Afficher loader
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) => const Center(
                    child: CircularProgressIndicator(color: AppColors.clientPrimary),
                  ),
                );
                
                await SupabaseService.updateProfile({
                  'full_name': name,
                  'phone': phone.isNotEmpty ? phone : null,
                });
                
                await _loadData();
                
                if (mounted) {
                  Navigator.pop(context); // Fermer loader
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profil mis à jour! ✅'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context); // Fermer loader
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: ${e.toString()}'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.clientPrimary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sauvegarder'),
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

  /// Test des notifications OneSignal
  void _testNotifications() async {
    HapticFeedback.lightImpact();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🧪 Test Notifications'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tester les notifications OneSignal:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.notifications_active, color: AppColors.clientPrimary),
              title: const Text('Notification de test'),
              subtitle: const Text('Affiche une notification locale'),
              onTap: () {
                Navigator.pop(ctx);
                OneSignalService.sendTestNotification();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🧪 Notification de test envoyée!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info, color: AppColors.textSecondary),
              title: const Text('Statut OneSignal'),
              subtitle: FutureBuilder<bool>(
                future: OneSignalService.areNotificationsEnabled(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Text(
                      snapshot.data! ? '✅ Activées' : '❌ Désactivées',
                      style: TextStyle(
                        color: snapshot.data! ? AppColors.success : AppColors.error,
                      ),
                    );
                  }
                  return const Text('Vérification...');
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.fingerprint, color: AppColors.textSecondary),
              title: const Text('Player ID'),
              subtitle: FutureBuilder<String?>(
                future: OneSignalService.getPlayerId(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return Text(
                      snapshot.data!.length > 8 
                          ? '${snapshot.data!.substring(0, 8)}...'
                          : snapshot.data!,
                      style: const TextStyle(fontFamily: 'monospace'),
                    );
                  }
                  return const Text('Non disponible');
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.bug_report, color: AppColors.warning),
              title: const Text('Debug complet'),
              subtitle: const Text('Afficher toutes les infos'),
              onTap: () {
                Navigator.pop(ctx);
                _showDebugInfo();
              },
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

  /// Afficher les informations de debug OneSignal
  void _showDebugInfo() async {
    final debugInfo = await OneSignalService.getDebugInfo();
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🔍 Debug OneSignal'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...debugInfo.entries.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        '${entry.key}:',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        entry.value?.toString() ?? 'null',
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 16),
              const Text(
                'Si Player ID est null, les notifications ne fonctionneront pas.',
                style: TextStyle(
                  color: AppColors.warning,
                  fontSize: 12,
                ),
              ),
            ],
          ),
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
}
