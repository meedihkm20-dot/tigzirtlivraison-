import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/design_system/theme/app_colors.dart';
import '../../../../core/design_system/theme/app_typography.dart';
import '../../../../core/design_system/theme/app_spacing.dart';
import '../../../../core/design_system/theme/app_shadows.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/backend_api_service.dart';
import '../../../../core/router/app_router.dart';
import '../../../../providers/providers.dart';

/// Écran Gestion Commandes Livreur V2
/// Liste des commandes acceptées avec alertes timing et gestion
class LivreurOrdersScreen extends ConsumerStatefulWidget {
  const LivreurOrdersScreen({super.key});

  @override
  ConsumerState<LivreurOrdersScreen> createState() => _LivreurOrdersScreenState();
}

class _LivreurOrdersScreenState extends ConsumerState<LivreurOrdersScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  List<Map<String, dynamic>> _acceptedOrders = [];
  List<Map<String, dynamic>> _availableOrders = [];
  Timer? _refreshTimer;
  
  late TabController _tabController;
  final _dateFormat = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadOrders();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadOrders();
    });
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final livreurState = ref.read(livreurProvider);
      
      // Charger commandes acceptées
      final accepted = await SupabaseService.getLivreurAcceptedOrders();
      
      // Charger commandes disponibles
      final available = await SupabaseService.getAvailableOrders();
      
      if (mounted) {
        setState(() {
          _acceptedOrders = accepted;
          _availableOrders = available;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement commandes: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mes Commandes'),
        backgroundColor: AppColors.livreurPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.assignment_turned_in, size: 18),
                  const SizedBox(width: 8),
                  Text('Acceptées (${_acceptedOrders.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.assignment, size: 18),
                  const SizedBox(width: 8),
                  Text('Disponibles (${_availableOrders.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.livreurPrimary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAcceptedOrdersTab(),
                _buildAvailableOrdersTab(),
              ],
            ),
    );
  }

  Widget _buildAcceptedOrdersTab() {
    if (_acceptedOrders.isEmpty) {
      return _buildEmptyState(
        icon: Icons.assignment_turned_in,
        title: 'Aucune commande acceptée',
        subtitle: 'Vos commandes acceptées apparaîtront ici',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: AppColors.livreurPrimary,
      child: ListView.builder(
        padding: AppSpacing.screen,
        itemCount: _acceptedOrders.length,
        itemBuilder: (ctx, i) => _buildAcceptedOrderCard(_acceptedOrders[i]),
      ),
    );
  }

  Widget _buildAvailableOrdersTab() {
    if (_availableOrders.isEmpty) {
      return _buildEmptyState(
        icon: Icons.assignment,
        title: 'Aucune commande disponible',
        subtitle: 'De nouvelles commandes arrivent régulièrement',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: AppColors.livreurPrimary,
      child: ListView.builder(
        padding: AppSpacing.screen,
        itemCount: _availableOrders.length,
        itemBuilder: (ctx, i) => _buildAvailableOrderCard(_availableOrders[i]),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: AppSpacing.screen,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(title, style: AppTypography.titleMedium.copyWith(color: AppColors.textTertiary)),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcceptedOrderCard(Map<String, dynamic> order) {
    final restaurantName = order['restaurant_name'] ?? 'Restaurant';
    final customerName = order['customer_name'] ?? 'Client';
    final status = order['status'] ?? 'confirmed';
    final createdAt = DateTime.parse(order['created_at']);
    final prepTime = order['prep_time'] ?? 15;
    final isUrgent = _isOrderUrgent(createdAt, prepTime, status);
    final timeInfo = _getTimeInfo(createdAt, prepTime, status);

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        AppRouter.delivery,
        arguments: order['id'],
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.borderRadiusMd,
          boxShadow: AppShadows.sm,
          border: Border.all(
            color: isUrgent ? AppColors.warning : AppColors.outline,
            width: isUrgent ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: AppColors.livreurGradient,
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
                      Text(
                        'Client: $customerName',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
            const Divider(height: 20),
            if (isUrgent)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.warningSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: AppColors.warning, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Commande urgente! ${timeInfo['message']}',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Commande: ${_dateFormat.format(createdAt)}',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                    ),
                    Text(
                      timeInfo['display'],
                      style: AppTypography.labelMedium.copyWith(
                        color: isUrgent ? AppColors.warning : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _openChat(order),
                      icon: const Icon(Icons.chat_bubble_outline, size: 16),
                      label: const Text('Chat'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.livreurPrimary,
                        side: const BorderSide(color: AppColors.livreurPrimary),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppRouter.delivery,
                        arguments: order['id'],
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.livreurPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text('Voir'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableOrderCard(Map<String, dynamic> order) {
    final restaurantName = order['restaurant_name'] ?? 'Restaurant';
    final distance = (order['distance'] as num?)?.toDouble() ?? 0;
    final earnings = (order['delivery_fee'] as num?)?.toDouble() ?? 200;
    final itemCount = order['item_count'] ?? 1;
    final prepTime = order['prep_time'] ?? 15;

    return Container(
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
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    
    switch (status) {
      case 'confirmed':
        color = AppColors.info;
        label = 'Confirmée';
        break;
      case 'preparing':
        color = AppColors.warning;
        label = 'En préparation';
        break;
      case 'ready':
        color = AppColors.success;
        label = 'Prête';
        break;
      case 'picked_up':
        color = AppColors.livreurPrimary;
        label = 'Récupérée';
        break;
      default:
        color = AppColors.textTertiary;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  bool _isOrderUrgent(DateTime createdAt, int prepTime, String status) {
    final now = DateTime.now();
    final timeSinceOrder = now.difference(createdAt).inMinutes;
    
    switch (status) {
      case 'confirmed':
        return timeSinceOrder > 10; // Plus de 10 min sans préparation
      case 'preparing':
        return timeSinceOrder > (prepTime + 10); // Dépassement temps préparation
      case 'ready':
        return timeSinceOrder > (prepTime + 20); // Commande prête depuis trop longtemps
      default:
        return false;
    }
  }

  Map<String, String> _getTimeInfo(DateTime createdAt, int prepTime, String status) {
    final now = DateTime.now();
    final timeSinceOrder = now.difference(createdAt).inMinutes;
    
    switch (status) {
      case 'confirmed':
        final remaining = 10 - timeSinceOrder;
        return {
          'display': remaining > 0 ? 'Préparation dans ${remaining}min' : 'En retard de ${-remaining}min',
          'message': 'Préparation en retard',
        };
      case 'preparing':
        final remaining = prepTime - timeSinceOrder;
        return {
          'display': remaining > 0 ? 'Prête dans ${remaining}min' : 'En retard de ${-remaining}min',
          'message': 'Préparation en retard',
        };
      case 'ready':
        return {
          'display': 'Prête depuis ${timeSinceOrder - prepTime}min',
          'message': 'À récupérer rapidement',
        };
      default:
        return {
          'display': 'Il y a ${timeSinceOrder}min',
          'message': '',
        };
    }
  }

  void _openChat(Map<String, dynamic> order) {
    Navigator.pushNamed(
      context,
      AppRouter.deliveryChat,
      arguments: {
        'orderId': order['id'],
        'recipientName': order['customer_name'] ?? 'Client',
        'recipientType': 'customer',
      },
    );
  }

  void _acceptOrder(Map<String, dynamic> order) async {
    HapticFeedback.heavyImpact();
    
    try {
      final backendApi = BackendApiService(SupabaseService.client);
      await backendApi.changeOrderStatus(order['id'], 'confirmed');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commande acceptée! 🎉'),
            backgroundColor: AppColors.success,
          ),
        );
        
        _loadOrders(); // Refresh
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