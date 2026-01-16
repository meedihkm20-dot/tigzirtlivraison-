import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/design_system/theme/app_colors.dart';
import '../../../../core/design_system/theme/app_typography.dart';
import '../../../../core/design_system/theme/app_spacing.dart';
import '../../../../core/design_system/theme/app_shadows.dart';
import '../../../../core/design_system/components/cards/stat_card.dart';
import '../../../../core/design_system/components/cards/order_card.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/backend_api_service.dart';
import '../../../../core/router/app_router.dart';
import '../../../../providers/providers.dart';

class RestaurantDashboardScreen extends ConsumerStatefulWidget {
  const RestaurantDashboardScreen({super.key});

  @override
  ConsumerState<RestaurantDashboardScreen> createState() => _RestaurantDashboardScreenState();
}

class _RestaurantDashboardScreenState extends ConsumerState<RestaurantDashboardScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  int _currentIndex = 0;
  
  List<double> _weeklyRevenue = [];
  
  RealtimeChannel? _ordersChannel;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _loadData();
  }

  @override
  void dispose() {
    _ordersChannel?.unsubscribe();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // ✅ Utiliser le provider pour charger les données
      await ref.read(restaurantProvider.notifier).loadAll();
      
      final restaurantState = ref.read(restaurantProvider);
      
      if (restaurantState.restaurant == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Restaurant non trouvé'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
      
      // Simuler les données hebdomadaires (à remplacer par vraies données)
      final weeklyData = [2500.0, 3200.0, 2800.0, 4100.0, 3800.0, 5200.0, 6350.0];

      if (mounted) {
        setState(() {
          _weeklyRevenue = weeklyData;
        });

        // Subscribe to realtime orders
        _subscribeToOrders(restaurantState.restaurantId!);
      }
    } catch (e) {
      debugPrint('Erreur chargement: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _subscribeToOrders(String restaurantId) {
    _ordersChannel?.unsubscribe();
    _ordersChannel = SupabaseService.subscribeToNewRestaurantOrders(
      restaurantId,
      (order) {
        HapticFeedback.heavyImpact();
        // ✅ Ajouter la commande via le provider
        ref.read(restaurantProvider.notifier).addPendingOrder(order);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.notifications_active, color: Colors.white),
                  const SizedBox(width: 12),
                  const Text('🔔 Nouvelle commande!'),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }

  Future<void> _toggleOpen(bool value) async {
    HapticFeedback.mediumImpact();
    try {
      // ✅ Utiliser le provider pour toggle open
      await ref.read(restaurantProvider.notifier).toggleOpen(value);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
    switch (index) {
      case 1:
        Navigator.pushNamed(context, AppRouter.menu);
        break;
      case 2:
        Navigator.pushNamed(context, AppRouter.stats);
        break;
      case 3:
        Navigator.pushNamed(context, AppRouter.restaurantProfile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Utiliser le provider pour les données
    final restaurantState = ref.watch(restaurantProvider);
    final restaurant = restaurantState.restaurant;
    final isOpen = restaurantState.isOpen;
    final pendingOrders = restaurantState.pendingOrders;
    final stats = restaurantState.stats;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.primary,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // App Bar
                    _buildAppBar(restaurant, isOpen),
                    
                    // Content
                    SliverPadding(
                      padding: AppSpacing.screen,
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // Stats Grid
                          _buildStatsGrid(stats, pendingOrders.length),
                          AppSpacing.vLg,
                          
                          // Weekly Chart
                          _buildWeeklyChart(),
                          AppSpacing.vLg,
                          
                          // Quick Actions
                          _buildQuickActions(pendingOrders.length),
                          AppSpacing.vLg,
                          
                          // Live Activity
                          _buildLiveActivity(pendingOrders),
                          AppSpacing.vLg,
                          
                          // Pending Orders
                          _buildPendingOrders(pendingOrders),
                          AppSpacing.vXxl,
                        ]),
                      ),
                    ),
                  ],
                ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildAppBar(RestaurantModel? restaurant, bool isOpen) {
    return SliverAppBar(
      floating: true,
      backgroundColor: AppColors.surface,
      elevation: 0,
      title: Row(
        children: [
          // Restaurant logo
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: AppSpacing.borderRadiusMd,
              image: restaurant?.logoUrl != null
                  ? DecorationImage(
                      image: NetworkImage(restaurant!.logoUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: restaurant?.logoUrl == null
                ? const Icon(Icons.restaurant, color: AppColors.primary, size: 20)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  restaurant?.name ?? 'Mon Restaurant',
                  style: AppTypography.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 14,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${(restaurant?.rating ?? 0).toStringAsFixed(1)}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${restaurant?.totalReviews ?? 0} avis)',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Open/Close toggle
        _buildOpenToggle(isOpen),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildOpenToggle(bool isOpen) {
    return GestureDetector(
      onTap: () => _toggleOpen(!isOpen),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isOpen ? AppColors.successSurface : AppColors.errorSurface,
          borderRadius: AppSpacing.borderRadiusRound,
          border: Border.all(
            color: isOpen ? AppColors.success : AppColors.error,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isOpen ? AppColors.success : AppColors.error,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              isOpen ? 'Ouvert' : 'Fermé',
              style: AppTypography.labelSmall.copyWith(
                color: isOpen ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> stats, int pendingCount) {
    final ordersToday = stats['orders_today'] ?? 0;
    final revenueToday = (stats['revenue_today'] ?? 0).toDouble();
    final totalOrders = stats['total_orders'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aujourd\'hui',
          style: AppTypography.headlineSmall,
        ),
        AppSpacing.vMd,
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Commandes',
                value: '$ordersToday',
                icon: Icons.receipt_long,
                color: AppColors.info,
                trend: '+15%',
                isPositiveTrend: true,
              ),
            ),
            AppSpacing.hMd,
            Expanded(
              child: StatCard(
                title: 'Revenus',
                value: revenueToday.toStringAsFixed(0),
                unit: 'DA',
                icon: Icons.attach_money,
                color: AppColors.success,
                trend: '+22%',
                isPositiveTrend: true,
              ),
            ),
          ],
        ),
        AppSpacing.vMd,
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'En attente',
                value: '$pendingCount',
                icon: Icons.pending_actions,
                color: pendingCount > 0 ? AppColors.warning : AppColors.textTertiary,
              ),
            ),
            AppSpacing.hMd,
            Expanded(
              child: StatCard(
                title: 'Total',
                value: '$totalOrders',
                icon: Icons.history,
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeeklyChart() {
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '📈 Revenus de la semaine',
                style: AppTypography.titleMedium,
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRouter.stats),
                child: const Text('Voir plus'),
              ),
            ],
          ),
          AppSpacing.vMd,
          SizedBox(
            height: 120,
            child: _buildBarChart(),
          ),
          AppSpacing.vSm,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim']
                .map((day) => Text(
                      day,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    if (_weeklyRevenue.isEmpty) return const SizedBox();
    
    final maxValue = _weeklyRevenue.reduce((a, b) => a > b ? a : b);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: _weeklyRevenue.asMap().entries.map((entry) {
        final index = entry.key;
        final value = entry.value;
        final height = maxValue > 0 ? (value / maxValue) * 100 : 0.0;
        final isToday = index == _weeklyRevenue.length - 1;
        
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${(value / 1000).toStringAsFixed(1)}k',
                  style: AppTypography.labelSmall.copyWith(
                    color: isToday ? AppColors.primary : AppColors.textTertiary,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  height: height,
                  decoration: BoxDecoration(
                    gradient: isToday
                        ? AppColors.primaryGradient
                        : LinearGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.3),
                              AppColors.primary.withOpacity(0.5),
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuickActions(int pendingCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '⚡ Actions rapides',
          style: AppTypography.titleMedium,
        ),
        AppSpacing.vMd,
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.restaurant_menu,
                label: 'Cuisine',
                color: AppColors.warning,
                badge: pendingCount,
                onTap: () => Navigator.pushNamed(context, AppRouter.kitchen),
              ),
            ),
            AppSpacing.hMd,
            Expanded(
              child: _buildActionButton(
                icon: Icons.local_offer,
                label: 'Promos',
                color: AppColors.error,
                onTap: () => Navigator.pushNamed(context, AppRouter.promotions),
              ),
            ),
          ],
        ),
        AppSpacing.vMd,
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.bar_chart,
                label: 'Stats',
                color: AppColors.info,
                onTap: () => Navigator.pushNamed(context, AppRouter.statsV2),
              ),
            ),
            AppSpacing.hMd,
            Expanded(
              child: _buildActionButton(
                icon: Icons.menu_book,
                label: 'Menu',
                color: AppColors.success,
                onTap: () => Navigator.pushNamed(context, AppRouter.menu),
              ),
            ),
          ],
        ),
        AppSpacing.vMd,
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.inventory_2,
                label: 'Stocks',
                color: AppColors.secondary,
                onTap: () => Navigator.pushNamed(context, AppRouter.stockManagement),
              ),
            ),
            AppSpacing.hMd,
            Expanded(
              child: _buildActionButton(
                icon: Icons.people,
                label: 'Équipe',
                color: AppColors.primary,
                onTap: () => Navigator.pushNamed(context, AppRouter.teamManagement),
              ),
            ),
          ],
        ),
        AppSpacing.vMd,
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.description,
                label: 'Rapports',
                color: AppColors.textSecondary,
                onTap: () => Navigator.pushNamed(context, AppRouter.reports),
              ),
            ),
            AppSpacing.hMd,
            Expanded(
              child: _buildActionButton(
                icon: Icons.settings,
                label: 'Paramètres',
                color: AppColors.textTertiary,
                onTap: () => Navigator.pushNamed(context, AppRouter.restaurantSettings),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    int badge = 0,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: AppSpacing.card,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: color, size: 24),
                if (badge > 0)
                  Positioned(
                    right: -8,
                    top: -8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$badge',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.labelLarge.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveActivity(List<Map<String, dynamic>> pendingOrders) {
    if (pendingOrders.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        boxShadow: AppShadows.sm,
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(
                        0.5 + (_pulseController.value * 0.5),
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withOpacity(0.5),
                          blurRadius: 8 * _pulseController.value,
                          spreadRadius: 2 * _pulseController.value,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              Text(
                'LIVE',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${pendingOrders.length} commande${pendingOrders.length > 1 ? 's' : ''} en cours',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          AppSpacing.vMd,
          ...pendingOrders.take(3).map((order) {
            final status = order['status'] as String? ?? '';
            final statusInfo = _getStatusInfo(status);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: statusInfo.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '#${order['order_number']}',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusInfo.color.withOpacity(0.1),
                      borderRadius: AppSpacing.borderRadiusRound,
                    ),
                    child: Text(
                      statusInfo.label,
                      style: AppTypography.labelSmall.copyWith(
                        color: statusInfo.color,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPendingOrders(List<Map<String, dynamic>> pendingOrders) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '📋 Commandes en cours',
              style: AppTypography.titleMedium,
            ),
            if (pendingOrders.isNotEmpty)
              TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRouter.kitchen),
                child: const Text('Voir tout'),
              ),
          ],
        ),
        AppSpacing.vMd,
        if (pendingOrders.isEmpty)
          _buildEmptyState()
        else
          ...pendingOrders.map((order) => _buildOrderCard(order)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.successSurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              size: 48,
              color: AppColors.success,
            ),
          ),
          AppSpacing.vMd,
          Text(
            'Aucune commande en cours',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          AppSpacing.vSm,
          Text(
            'Les nouvelles commandes apparaîtront ici',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderItems = order['order_items'] as List? ?? [];
    final items = orderItems.map((item) => OrderItemData(
      name: item['name'] ?? '',
      quantity: item['quantity'] ?? 1,
      specialInstructions: item['special_instructions'],
    )).toList();

    return OrderCard(
      orderNumber: order['order_number'] ?? '',
      status: order['status'] ?? '',
      customerName: order['customer']?['full_name'] ?? 'Client',
      customerPhone: order['customer']?['phone'],
      itemCount: orderItems.fold<int>(0, (sum, item) => sum + ((item['quantity'] as int?) ?? 1)),
      total: (order['total'] ?? 0).toDouble(),
      createdAt: DateTime.tryParse(order['created_at'] ?? '') ?? DateTime.now(),
      livreurName: order['livreur']?['profile']?['full_name'],
      items: items,
      onAccept: () => _confirmOrder(order['id']),
      onReject: () => _cancelOrder(order['id']),
      onStartPreparing: () => _startPreparing(order['id']),
      onMarkReady: () => _markAsReady(order['id']),
    );
  }

  Future<void> _confirmOrder(String orderId) async {
    HapticFeedback.mediumImpact();
    try {
      final backendApi = BackendApiService(SupabaseService.client);
      await backendApi.changeOrderStatus(orderId, 'confirmed');
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Commande confirmée'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _startPreparing(String orderId) async {
    HapticFeedback.mediumImpact();
    try {
      final backendApi = BackendApiService(SupabaseService.client);
      await backendApi.changeOrderStatus(orderId, 'preparing');
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _markAsReady(String orderId) async {
    HapticFeedback.heavyImpact();
    try {
      final backendApi = BackendApiService(SupabaseService.client);
      await backendApi.changeOrderStatus(orderId, 'ready');
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🍽️ Commande prête!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _cancelOrder(String orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refuser la commande?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Refuser'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final backendApi = BackendApiService(SupabaseService.client);
        await backendApi.cancelOrder(orderId, 'restaurant_unavailable', details: 'Refusé par le restaurant');
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Commande refusée'),
              backgroundColor: AppColors.warning,
            ),
          );
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

  _StatusInfo _getStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return _StatusInfo('Nouvelle', AppColors.statusPending);
      case 'confirmed':
        return _StatusInfo('Confirmée', AppColors.statusConfirmed);
      case 'preparing':
        return _StatusInfo('En préparation', AppColors.statusPreparing);
      case 'ready':
        return _StatusInfo('Prête', AppColors.statusReady);
      default:
        return _StatusInfo(status, AppColors.textSecondary);
    }
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
              _buildNavItem(0, Icons.home, 'Accueil'),
              _buildNavItem(1, Icons.restaurant_menu, 'Menu'),
              _buildNavItem(2, Icons.bar_chart, 'Stats'),
              _buildNavItem(3, Icons.person, 'Profil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onNavTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySurface : Colors.transparent,
          borderRadius: AppSpacing.borderRadiusRound,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textTertiary,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
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

class _StatusInfo {
  final String label;
  final Color color;
  _StatusInfo(this.label, this.color);
}
