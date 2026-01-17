import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/theme/app_colors.dart';
import '../../../../core/design_system/theme/app_typography.dart';
import '../../../../core/design_system/theme/app_spacing.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/router/app_router.dart';

/// Dashboard restaurant simplifié - Commandes en priorité
class RestaurantHomeScreenV3 extends ConsumerStatefulWidget {
  const RestaurantHomeScreenV3({super.key});

  @override
  ConsumerState<RestaurantHomeScreenV3> createState() => _RestaurantHomeScreenV3State();
}

class _RestaurantHomeScreenV3State extends ConsumerState<RestaurantHomeScreenV3> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _pendingOrders = [];
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final orders = await SupabaseService.getRestaurantPendingOrders();
      final stats = await SupabaseService.getRestaurantStats();
      
      setState(() {
        _pendingOrders = orders;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dashboard Restaurant'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: AppSpacing.screen,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats du jour
                    Text('Aujourd\'hui', style: AppTypography.titleLarge),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Commandes',
                            value: '${_stats['orders_today'] ?? 0}',
                            icon: Icons.shopping_bag,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: 'Revenus',
                            value: '${(_stats['revenue_today'] ?? 0).toStringAsFixed(0)} DA',
                            icon: Icons.attach_money,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Actions rapides
                    Text('Actions rapides', style: AppTypography.titleLarge),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            label: 'Commandes',
                            icon: Icons.list_alt,
                            onTap: () => Navigator.pushNamed(context, AppRouter.restaurantOrders),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionButton(
                            label: 'Finance',
                            icon: Icons.account_balance_wallet,
                            onTap: () => Navigator.pushNamed(context, AppRouter.restaurantFinance),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            label: 'Historique',
                            icon: Icons.history,
                            onTap: () => Navigator.pushNamed(context, AppRouter.restaurantOrderHistory),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionButton(
                            label: 'Menu',
                            icon: Icons.restaurant_menu,
                            onTap: () => Navigator.pushNamed(context, AppRouter.menu),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Commandes en attente
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Commandes en attente', style: AppTypography.titleLarge),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, AppRouter.restaurantOrders),
                          child: const Text('Voir tout'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    if (_pendingOrders.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.check_circle, size: 64, color: AppColors.success.withOpacity(0.3)),
                              const SizedBox(height: 16),
                              Text('Aucune commande en attente', style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._pendingOrders.take(5).map((order) => _OrderCard(
                        order: order,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRouter.restaurantOrderDetail,
                            arguments: order['id'],
                          ).then((_) => _loadData());
                        },
                      )),
                  ],
                ),
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
          Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 32),
            const SizedBox(height: 8),
            Text(label, style: AppTypography.labelMedium.copyWith(color: AppColors.primary)),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.shopping_bag, color: AppColors.warning),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('#${order['order_number'] ?? ''}', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                  Text(order['customer']?['full_name'] ?? 'Client', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            Text('${(order['total'] ?? 0).toStringAsFixed(0)} DA', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
          ],
        ),
      ),
    );
  }
}
