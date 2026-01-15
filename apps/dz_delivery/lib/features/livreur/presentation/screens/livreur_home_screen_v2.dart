import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/design_system/theme/app_colors.dart';
import '../../../../core/design_system/theme/app_typography.dart';
import '../../../../core/design_system/theme/app_spacing.dart';
import '../../../../core/design_system/theme/app_shadows.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/backend_api_service.dart';
import '../../../../core/router/app_router.dart';

/// Écran Accueil Livreur V2 - Premium
/// Stats temps réel, commandes disponibles, quick actions, gamification
class LivreurHomeScreenV2 extends StatefulWidget {
  const LivreurHomeScreenV2({super.key});

  @override
  State<LivreurHomeScreenV2> createState() => _LivreurHomeScreenV2State();
}

class _LivreurHomeScreenV2State extends State<LivreurHomeScreenV2>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  bool _isOnline = false;
  
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _todayStats;
  Map<String, dynamic>? _tierInfo;
  List<Map<String, dynamic>> _availableOrders = [];
  Map<String, dynamic>? _currentDelivery;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  StreamSubscription? _ordersSubscription;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _loadData();
    _subscribeToOrders();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _ordersSubscription?.cancel();
    super.dispose();
  }


  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _safeCall(() => SupabaseService.getProfile(), null),
        _safeCall(() => SupabaseService.getLivreurTodayStats(), <String, dynamic>{}),
        _safeCall(() => SupabaseService.getLivreurTierInfo(), <String, dynamic>{}),
        _safeCall(() => SupabaseService.getAvailableOrders(), <Map<String, dynamic>>[]),
        _safeCall(() => SupabaseService.getCurrentDelivery(), null),
      ]);

      if (mounted) {
        setState(() {
          _profile = results[0] as Map<String, dynamic>?;
          _todayStats = results[1] as Map<String, dynamic>;
          _tierInfo = results[2] as Map<String, dynamic>;
          _availableOrders = results[3] as List<Map<String, dynamic>>;
          _currentDelivery = results[4] as Map<String, dynamic>?;
          _isOnline = _profile?['is_online'] ?? false;
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
      return defaultValue;
    }
  }

  void _subscribeToOrders() {
    _ordersSubscription = SupabaseService.subscribeToAvailableOrders().listen((orders) {
      if (mounted) {
        setState(() => _availableOrders = orders);
      }
    });
  }

  String get _tierName => _tierInfo?['tier'] ?? 'Bronze';
  Color get _tierColor {
    switch (_tierName.toLowerCase()) {
      case 'diamond': return AppColors.tierDiamond;
      case 'gold': return AppColors.tierGold;
      case 'silver': return AppColors.tierSilver;
      default: return AppColors.tierBronze;
    }
  }
  LinearGradient get _tierGradient {
    switch (_tierName.toLowerCase()) {
      case 'diamond': return AppColors.diamondGradient;
      case 'gold': return AppColors.goldGradient;
      case 'silver': return AppColors.silverGradient;
      default: return AppColors.bronzeGradient;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.livreurPrimary))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.livreurPrimary,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  _buildHeader(),
                  SliverToBoxAdapter(child: _buildOnlineToggle()),
                  if (_currentDelivery != null)
                    SliverToBoxAdapter(child: _buildCurrentDelivery()),
                  SliverToBoxAdapter(child: _buildTodayStats()),
                  SliverToBoxAdapter(child: _buildQuickActions()),
                  SliverToBoxAdapter(child: _buildAvailableOrders()),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    final name = _profile?['full_name']?.toString().split(' ').first ?? 'Livreur';
    final rating = (_profile?['rating'] as num?)?.toDouble() ?? 4.5;

    return SliverAppBar(
      expandedHeight: 180,
      floating: true,
      pinned: true,
      backgroundColor: AppColors.livreurPrimary,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: AppColors.livreurGradient),
          child: SafeArea(
            child: Padding(
              padding: AppSpacing.screen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Greeting
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Salut $name! 👋',
                            style: AppTypography.headlineSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                rating.toStringAsFixed(1),
                                style: AppTypography.labelMedium.copyWith(color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: _tierGradient,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.workspace_premium, color: Colors.white, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      _tierName,
                                      style: AppTypography.labelSmall.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Profile & Notifications
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                            onPressed: () => Navigator.pushNamed(context, AppRouter.notifications),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, AppRouter.livreurProfile),
                            child: Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  name[0].toUpperCase(),
                                  style: AppTypography.titleMedium.copyWith(color: Colors.white),
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOnlineToggle() {
    return Container(
      margin: AppSpacing.screen,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isOnline ? AppColors.successSurface : AppColors.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: _isOnline ? AppColors.success : AppColors.outline,
          width: 2,
        ),
        boxShadow: AppShadows.md,
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) => Transform.scale(
              scale: _isOnline ? _pulseAnimation.value : 1.0,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _isOnline ? AppColors.success : AppColors.textTertiary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isOnline ? Icons.delivery_dining : Icons.delivery_dining_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isOnline ? 'Vous êtes en ligne' : 'Vous êtes hors ligne',
                  style: AppTypography.titleSmall.copyWith(
                    color: _isOnline ? AppColors.success : AppColors.textPrimary,
                  ),
                ),
                Text(
                  _isOnline 
                      ? 'Prêt à recevoir des commandes'
                      : 'Activez pour recevoir des commandes',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          Switch(
            value: _isOnline,
            onChanged: _toggleOnline,
            activeColor: AppColors.success,
            activeTrackColor: AppColors.success.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentDelivery() {
    if (_currentDelivery == null) return const SizedBox.shrink();
    
    final restaurantName = _currentDelivery!['restaurant_name'] ?? 'Restaurant';
    final customerAddress = _currentDelivery!['delivery_address'] ?? 'Adresse';
    final status = _currentDelivery!['status'] ?? 'picked_up';

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context, 
        AppRouter.delivery, 
        arguments: _currentDelivery!['id'],
      ),
      child: Container(
        margin: AppSpacing.screenHorizontal,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.livreurGradient,
          borderRadius: AppSpacing.borderRadiusLg,
          boxShadow: AppShadows.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delivery_dining, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Livraison en cours',
                        style: AppTypography.labelMedium.copyWith(color: Colors.white70),
                      ),
                      Text(
                        restaurantName,
                        style: AppTypography.titleSmall.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Voir',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.livreurPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    customerAddress,
                    style: AppTypography.bodySmall.copyWith(color: Colors.white70),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayStats() {
    final deliveries = _todayStats?['deliveries'] ?? 0;
    final earnings = (_todayStats?['earnings'] as num?)?.toDouble() ?? 0;
    final tips = (_todayStats?['tips'] as num?)?.toDouble() ?? 0;
    final distance = (_todayStats?['distance'] as num?)?.toDouble() ?? 0;

    return Padding(
      padding: AppSpacing.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Aujourd\'hui', style: AppTypography.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatCard('🚚', '$deliveries', 'Livraisons', AppColors.livreurPrimary)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('💰', '${earnings.toStringAsFixed(0)}', 'DA gagnés', AppColors.success)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatCard('💝', '${tips.toStringAsFixed(0)}', 'DA pourboires', AppColors.warning)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('📍', '${distance.toStringAsFixed(1)}', 'km parcourus', AppColors.info)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String emoji, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusMd,
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: AppSpacing.screenHorizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Actions rapides', style: AppTypography.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildActionButton(Icons.account_balance_wallet, 'Gains', AppRouter.earnings)),
              const SizedBox(width: 12),
              Expanded(child: _buildActionButton(Icons.emoji_events, 'Niveau', AppRouter.tierProgress)),
              const SizedBox(width: 12),
              Expanded(child: _buildActionButton(Icons.history, 'Historique', AppRouter.customerOrders)),
              const SizedBox(width: 12),
              Expanded(child: _buildActionButton(Icons.map, 'Zones', null)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, String? route) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (route != null) Navigator.pushNamed(context, route);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.borderRadiusMd,
          boxShadow: AppShadows.sm,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.livreurSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.livreurPrimary, size: 24),
            ),
            const SizedBox(height: 8),
            Text(label, style: AppTypography.labelSmall),
          ],
        ),
      ),
    );
  }


  Widget _buildAvailableOrders() {
    return Padding(
      padding: AppSpacing.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Commandes disponibles', style: AppTypography.titleMedium),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.livreurSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_availableOrders.length}',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.livreurPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!_isOnline)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppSpacing.borderRadiusMd,
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.wifi_off, size: 48, color: AppColors.textTertiary),
                    const SizedBox(height: 12),
                    Text(
                      'Passez en ligne pour voir les commandes',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else if (_availableOrders.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppSpacing.borderRadiusMd,
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inbox, size: 48, color: AppColors.textTertiary),
                    const SizedBox(height: 12),
                    Text(
                      'Aucune commande disponible',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Restez en ligne, de nouvelles commandes arrivent!',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ..._availableOrders.map((order) => _buildOrderCard(order)),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final restaurantName = order['restaurant_name'] ?? 'Restaurant';
    final distance = (order['distance'] as num?)?.toDouble() ?? 0;
    final earnings = (order['delivery_fee'] as num?)?.toDouble() ?? 200;
    final itemCount = order['item_count'] ?? 1;
    final prepTime = order['prep_time'] ?? 15;

    return GestureDetector(
      onTap: () => _showOrderDetails(order),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.borderRadiusMd,
          boxShadow: AppShadows.sm,
          border: Border.all(color: AppColors.outline),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      restaurantName[0].toUpperCase(),
                      style: AppTypography.titleLarge.copyWith(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(restaurantName, style: AppTypography.titleSmall),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.shopping_bag, size: 14, color: AppColors.textTertiary),
                          const SizedBox(width: 4),
                          Text(
                            '$itemCount article${itemCount > 1 ? 's' : ''}',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.access_time, size: 14, color: AppColors.textTertiary),
                          const SizedBox(width: 4),
                          Text(
                            'Prêt dans $prepTime min',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.infoSurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: AppColors.info),
                          const SizedBox(width: 4),
                          Text(
                            '${distance.toStringAsFixed(1)} km',
                            style: AppTypography.labelSmall.copyWith(color: AppColors.info),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.successSurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.attach_money, size: 14, color: AppColors.success),
                          Text(
                            '${earnings.toStringAsFixed(0)} DA',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () => _acceptOrder(order),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.livreurPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Accepter'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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
              _buildNavItem(0, Icons.home, 'Accueil', true),
              _buildNavItem(1, Icons.map, 'Carte', false),
              _buildNavItem(2, Icons.account_balance_wallet, 'Gains', false),
              _buildNavItem(3, Icons.emoji_events, 'Niveau', false),
              _buildNavItem(4, Icons.person_outline, 'Profil', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        switch (index) {
          case 2:
            Navigator.pushNamed(context, AppRouter.earnings);
            break;
          case 3:
            Navigator.pushNamed(context, AppRouter.tierProgress);
            break;
          case 4:
            Navigator.pushNamed(context, AppRouter.livreurProfile);
            break;
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.livreurSurface : Colors.transparent,
          borderRadius: AppSpacing.borderRadiusRound,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.livreurPrimary : AppColors.textTertiary,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.livreurPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================
  // ACTIONS
  // ============================================

  void _toggleOnline(bool value) async {
    HapticFeedback.mediumImpact();
    setState(() => _isOnline = value);
    
    try {
      await SupabaseService.setLivreurOnlineStatus(value);
      if (value) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vous êtes maintenant en ligne! 🚀'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _isOnline = !value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  void _showOrderDetails(Map<String, dynamic> order) {
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
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      (order['restaurant_name'] ?? 'R')[0].toUpperCase(),
                      style: AppTypography.headlineSmall.copyWith(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order['restaurant_name'] ?? '', style: AppTypography.titleMedium),
                      Text(
                        order['restaurant_address'] ?? '',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            _buildDetailRow(Icons.location_on, 'Livraison', order['delivery_address'] ?? ''),
            _buildDetailRow(Icons.straighten, 'Distance', '${(order['distance'] ?? 0).toStringAsFixed(1)} km'),
            _buildDetailRow(Icons.attach_money, 'Gain', '${(order['delivery_fee'] ?? 200).toStringAsFixed(0)} DA'),
            _buildDetailRow(Icons.shopping_bag, 'Articles', '${order['item_count'] ?? 1}'),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Fermer'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _acceptOrder(order);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.livreurPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Accepter la commande'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textTertiary),
          const SizedBox(width: 12),
          Text(label, style: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary)),
          const Spacer(),
          Text(value, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _acceptOrder(Map<String, dynamic> order) async {
    HapticFeedback.heavyImpact();
    
    try {
      // ✅ Migration: Utilise le backend au lieu de Supabase direct
      final backendApi = BackendApiService(SupabaseService.client);
      await backendApi.changeOrderStatus(order['id'], 'accepted');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commande acceptée! 🎉'),
            backgroundColor: AppColors.success,
          ),
        );
        
        Navigator.pushNamed(context, AppRouter.delivery, arguments: order['id']);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }
}
