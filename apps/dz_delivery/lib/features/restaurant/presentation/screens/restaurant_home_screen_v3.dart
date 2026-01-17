import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/design_system/theme/app_colors.dart';
import '../../../../core/design_system/theme/app_typography.dart';
import '../../../../core/design_system/theme/app_spacing.dart';
import '../../../../core/design_system/theme/app_shadows.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/backend_api_service.dart';
import '../../../../core/router/app_router.dart';
import '../../../../providers/providers.dart';

/// Écran d'accueil restaurant V3 - SIMPLIFIÉ
/// Focus: Commandes en temps réel
class RestaurantHomeScreenV3 extends ConsumerStatefulWidget {
  const RestaurantHomeScreenV3({super.key});

  @override
  ConsumerState<RestaurantHomeScreenV3> createState() => _RestaurantHomeScreenV3State();
}

class _RestaurantHomeScreenV3State extends ConsumerState<RestaurantHomeScreenV3> {
  bool _isLoading = true;
  int _currentIndex = 0;
  RealtimeChannel? _ordersChannel;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _ordersChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(restaurantProvider.notifier).loadAll();
      
      final restaurantState = ref.read(restaurantProvider);
      if (restaurantState.restaurant != null) {
        _subscribeToOrders(restaurantState.restaurantId!);
      }
    } catch (e) {
      debugPrint('Erreur chargement: $e');
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
        ref.read(restaurantProvider.notifier).addPendingOrder(order);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.notifications_active, color: Colors.white),
                  const SizedBox(width: 12),
                  Text('🔔 Nouvelle commande #${order['order_number']}'),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
    );
  }

  Future<void> _toggleOpen(bool value) async {
    HapticFeedback.mediumImpact();
    try {
      await ref.read(restaurantProvider.notifier).toggleOpen(value);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final restaurantState = ref.watch(restaurantProvider);
    final restaurant = restaurantState.restaurant;
    final isOpen = restaurantState.isOpen;
    final pendingOrders = restaurantState.pendingOrders;
    final stats = restaurantState.stats;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Header compact
                    _buildHeader(restaurant, isOpen),
                    
                    // Commandes en cours (PRIORITÉ)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: AppSpacing.screen,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(
                              '📋 Commandes en cours',
                              pendingOrders.length,
                              onViewAll: () => Navigator.pushNamed(context, AppRouter.restaurantOrders),
                            ),
                            AppSpacing.vMd,
                            if (pendingOrders.isEmpty)
                              _buildEmptyOrders()
                            else
                              ...pendingOrders.take(3).map((order) => _buildOrderCard(order)),
                            
                            if (pendingOrders.length > 3) ...[
                              AppSpacing.vMd,
                              Center(
                                child: TextButton.icon(
                                  onPressed: () => Navigator.pushNamed(context, AppRouter.restaurantOrders),
                                  icon: const Icon(Icons.arrow_forward),
                                  label: Text('Voir les ${pendingOrders.length - 3} autres'),
                                ),
                              ),
                            ],
                            
                            AppSpacing.vLg,
                            
                            // Stats rapides
                            _buildQuickStats(stats),
                            
                            AppSpacing.vXxl,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader(dynamic restaurant, bool isOpen) {
    return SliverAppBar(
      floating: true,
      backgroundColor: AppColors.surface,
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(8),
              image: restaurant?.logoUrl != null
                  ? DecorationImage(
                      image: NetworkImage(restaurant!.logoUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: restaurant?.logoUrl == null
                ? const Icon(Icons.restaurant, color: AppColors.primary, size: 18)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              restaurant?.name ?? 'Restaurant',
              style: AppTypography.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        // Toggle ouvert/fermé
        GestureDetector(
          onTap: () => _toggleOpen(!isOpen),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(right: 8),
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
        ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => Navigator.pushNamed(context, AppRouter.restaurantSettings),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count, {VoidCallback? onViewAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(title, style: AppTypography.titleMedium),
            if (count > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: AppSpacing.borderRadiusRound,
                ),
                child: Text(
                  '$count',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (onViewAll != null && count > 0)
          TextButton(
            onPressed: onViewAll,
            child: const Text('Voir tout'),
          ),
      ],
    );
  }

  Widget _buildEmptyOrders() {
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
    final status = order['status'] as String? ?? '';
    final items = order['order_items'] as List? ?? [];
    final itemCount = items.fold<int>(0, (sum, item) => sum + ((item['quantity'] as int?) ?? 1));
    final total = (order['total'] ?? 0).toDouble();
    final createdAt = DateTime.tryParse(order['created_at'] ?? '') ?? DateTime.now();
    final elapsedMinutes = DateTime.now().difference(createdAt).inMinutes;
    
    Color statusColor;
    String statusLabel;
    List<Widget> actions = [];
    
    switch (status) {
      case 'pending':
        statusColor = AppColors.warning;
        statusLabel = 'Nouvelle';
        actions = [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _cancelOrder(order['id']),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
              child: const Text('Refuser'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _acceptOrder(order['id']),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
              ),
              child: const Text('Accepter'),
            ),
          ),
        ];
        break;
      case 'confirmed':
        statusColor = AppColors.info;
        statusLabel = 'Confirmée';
        actions = [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _startPreparing(order['id']),
              icon: const Icon(Icons.restaurant, size: 18),
              label: const Text('Démarrer préparation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
            ),
          ),
        ];
        break;
      case 'preparing':
        statusColor = AppColors.primary;
        statusLabel = 'En préparation';
        actions = [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _markAsReady(order['id']),
              icon: const Icon(Icons.check_circle, size: 18),
              label: const Text('Marquer prêt'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
              ),
            ),
          ),
        ];
        break;
      case 'ready':
        statusColor = AppColors.success;
        statusLabel = 'Prêt';
        actions = [];
        break;
      default:
        statusColor = AppColors.textTertiary;
        statusLabel = status;
        actions = [];
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        boxShadow: AppShadows.sm,
        border: elapsedMinutes > 15
            ? Border.all(color: AppColors.error, width: 2)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pushNamed(
            context,
            AppRouter.restaurantOrderDetail,
            arguments: order['id'],
          ),
          borderRadius: AppSpacing.borderRadiusLg,
          child: Padding(
            padding: AppSpacing.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            '#${order['order_number']}',
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: AppSpacing.borderRadiusRound,
                            ),
                            child: Text(
                              statusLabel,
                              style: AppTypography.labelSmall.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: elapsedMinutes > 15 ? AppColors.errorSurface : AppColors.surfaceVariant,
                        borderRadius: AppSpacing.borderRadiusSm,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer,
                            size: 12,
                            color: elapsedMinutes > 15 ? AppColors.error : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$elapsedMinutes min',
                            style: AppTypography.labelSmall.copyWith(
                              color: elapsedMinutes > 15 ? AppColors.error : AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                AppSpacing.vSm,
                
                // Info
                Row(
                  children: [
                    Icon(Icons.shopping_bag, size: 16, color: AppColors.textTertiary),
                    const SizedBox(width: 6),
                    Text(
                      '$itemCount article${itemCount > 1 ? 's' : ''}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.attach_money, size: 16, color: AppColors.success),
                    Text(
                      '${total.toStringAsFixed(0)} DA',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                
                // Actions
                if (actions.isNotEmpty) ...[
                  AppSpacing.vMd,
                  Row(children: actions),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(Map<String, dynamic> stats) {
    final ordersToday = stats['orders_today'] ?? 0;
    final revenueToday = (stats['revenue_today'] ?? 0).toDouble();

    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: AppSpacing.borderRadiusLg,
        boxShadow: AppShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📊 Aujourd\'hui',
            style: AppTypography.titleMedium.copyWith(color: Colors.white),
          ),
          AppSpacing.vMd,
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Commandes',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      '$ordersToday',
                      style: AppTypography.headlineMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Revenus',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      '${revenueToday.toStringAsFixed(0)} DA',
                      style: AppTypography.headlineMedium.copyWith(
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
              _buildNavItem(0, Icons.home, 'Accueil'),
              _buildNavItem(1, Icons.receipt_long, 'Commandes'),
              _buildNavItem(2, Icons.account_balance_wallet, 'Finance'),
              _buildNavItem(3, Icons.restaurant_menu, 'Menu'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = index);
        switch (index) {
          case 1:
            Navigator.pushNamed(context, AppRouter.restaurantOrders);
            break;
          case 2:
            Navigator.pushNamed(context, AppRouter.restaurantFinance);
            break;
          case 3:
            Navigator.pushNamed(context, AppRouter.menu);
            break;
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySurface : Colors.transparent,
          borderRadius: AppSpacing.borderRadiusRound,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textTertiary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textTertiary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptOrder(String orderId) async {
    HapticFeedback.mediumImpact();
    try {
      final backendApi = BackendApiService(SupabaseService.client);
      await backendApi.changeOrderStatus(orderId, 'confirmed');
      ref.read(restaurantProvider.notifier).refreshPendingOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Commande acceptée'),
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
      ref.read(restaurantProvider.notifier).refreshPendingOrders();
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
      ref.read(restaurantProvider.notifier).refreshPendingOrders();
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
        ref.read(restaurantProvider.notifier).refreshPendingOrders();
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
}
