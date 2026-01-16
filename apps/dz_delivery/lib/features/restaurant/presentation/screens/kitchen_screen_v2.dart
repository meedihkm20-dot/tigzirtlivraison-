import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../core/design_system/theme/app_colors.dart';
import '../../../../core/design_system/theme/app_typography.dart';
import '../../../../core/design_system/theme/app_spacing.dart';
import '../../../../core/design_system/theme/app_shadows.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/backend_api_service.dart';
import '../../../../providers/providers.dart';

/// Écran Cuisine Premium V2
/// Vue en grille avec priorités visuelles, sons et animations
class KitchenScreenV2 extends ConsumerStatefulWidget {
  const KitchenScreenV2({super.key});

  @override
  ConsumerState<KitchenScreenV2> createState() => _KitchenScreenV2State();
}

class _KitchenScreenV2State extends ConsumerState<KitchenScreenV2>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  Timer? _refreshTimer;
  int _previousOrderCount = 0;
  
  late AnimationController _pulseController;
  late AnimationController _urgentController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Filtres
  String _filter = 'all'; // 'all', 'new', 'preparing'
  bool _soundEnabled = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    _urgentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    
    _loadOrders();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _refreshOrders(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _pulseController.dispose();
    _urgentController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      // ✅ Utiliser le provider pour charger les commandes
      await ref.read(restaurantProvider.notifier).refreshPendingOrders();
      
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Erreur chargement cuisine: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshOrders() async {
    try {
      final orders = await SupabaseService.getKitchenOrders();
      
      // Détecter nouvelles commandes
      if (orders.length > _previousOrderCount && _previousOrderCount > 0) {
        _notifyNewOrder();
      }
      _previousOrderCount = orders.length;
      
      // ✅ Mettre à jour via le provider
      ref.read(restaurantProvider.notifier).setPendingOrders(orders);
    } catch (e) {
      debugPrint('Erreur refresh cuisine: $e');
    }
  }

  void _notifyNewOrder() {
    // Vibration
    HapticFeedback.heavyImpact();
    
    // Son (si activé)
    if (_soundEnabled) {
      _playNotificationSound();
    }
    
    // Snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.notifications_active, color: Colors.white),
              const SizedBox(width: 12),
              const Text('🔔 Nouvelle commande en cuisine!'),
            ],
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _playNotificationSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/new_order.mp3'));
    } catch (e) {
      debugPrint('Erreur son: $e');
    }
  }

  List<Map<String, dynamic>> _getFilteredOrders(List<Map<String, dynamic>> orders) {
    switch (_filter) {
      case 'new':
        return orders.where((o) => o['status'] == 'confirmed').toList();
      case 'preparing':
        return orders.where((o) => o['status'] == 'preparing').toList();
      default:
        return orders;
    }
  }

  Future<void> _startPreparing(String orderId) async {
    HapticFeedback.mediumImpact();
    try {
      final backendApi = BackendApiService(SupabaseService.client);
      await backendApi.changeOrderStatus(orderId, 'preparing');
      _refreshOrders();
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🍽️ Commande prête! Le livreur est notifié'),
            backgroundColor: AppColors.success,
          ),
        );
      }
      _refreshOrders();
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
    // ✅ Utiliser le provider pour les commandes (synchronisé avec Dashboard)
    final orders = ref.watch(pendingOrdersProvider);
    final filteredOrders = _getFilteredOrders(orders);
    final newCount = orders.where((o) => o['status'] == 'confirmed').length;
    final preparingCount = orders.where((o) => o['status'] == 'preparing').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(orders.length, newCount, preparingCount),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredOrders.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: Column(
                    children: [
                      // Filtres
                      _buildFilters(newCount, preparingCount),
                      
                      // Grille des commandes
                      Expanded(
                        child: GridView.builder(
                          padding: AppSpacing.screen,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                            childAspectRatio: 0.72,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: filteredOrders.length,
                          itemBuilder: (context, index) => _buildOrderCard(filteredOrders[index]),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  PreferredSizeWidget _buildAppBar(int totalCount, int newCount, int preparingCount) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          const Icon(Icons.restaurant_menu, color: AppColors.primary),
          const SizedBox(width: 8),
          const Text('Cuisine'),
        ],
      ),
      actions: [
        // Badge total
        Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: totalCount == 0 ? AppColors.successSurface : AppColors.warningSurface,
            borderRadius: AppSpacing.borderRadiusRound,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (totalCount > 0)
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(
                          0.5 + (_pulseController.value * 0.5),
                        ),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                ),
              Text(
                '$totalCount en cours',
                style: AppTypography.labelMedium.copyWith(
                  color: totalCount == 0 ? AppColors.success : AppColors.warning,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        
        // Toggle son
        IconButton(
          icon: Icon(
            _soundEnabled ? Icons.volume_up : Icons.volume_off,
            color: _soundEnabled ? AppColors.primary : AppColors.textTertiary,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            setState(() => _soundEnabled = !_soundEnabled);
          },
        ),
        
        // Refresh
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadOrders,
        ),
      ],
    );
  }

  Widget _buildFilters(int newCount, int preparingCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildFilterChip('all', 'Toutes', _orders.length),
          const SizedBox(width: 8),
          _buildFilterChip('new', 'Nouvelles', newCount, AppColors.warning),
          const SizedBox(width: 8),
          _buildFilterChip('preparing', 'En préparation', preparingCount, AppColors.info),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, int count, [Color? color]) {
    final isSelected = _filter == value;
    final chipColor = color ?? AppColors.primary;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _filter = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor.withOpacity(0.15) : AppColors.surface,
          borderRadius: AppSpacing.borderRadiusRound,
          border: Border.all(
            color: isSelected ? chipColor : AppColors.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected ? chipColor : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? chipColor : AppColors.surfaceVariant,
                borderRadius: AppSpacing.borderRadiusRound,
              ),
              child: Text(
                '$count',
                style: AppTypography.labelSmall.copyWith(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.successSurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              size: 64,
              color: AppColors.success,
            ),
          ),
          AppSpacing.vLg,
          Text(
            'Aucune commande en attente',
            style: AppTypography.headlineSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          AppSpacing.vSm,
          Text(
            'Les nouvelles commandes apparaîtront ici',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          AppSpacing.vXl,
          OutlinedButton.icon(
            onPressed: _loadOrders,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualiser'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] as String? ?? '';
    final items = order['order_items'] as List? ?? [];
    final createdAt = DateTime.tryParse(order['created_at'] ?? '') ?? DateTime.now();
    final elapsedMinutes = DateTime.now().difference(createdAt).inMinutes;
    final priorityColor = AppColors.getPriorityColor(elapsedMinutes);
    final isPreparing = status == 'preparing';
    final isUrgent = elapsedMinutes > 20;
    final livreur = order['livreur'];

    return AnimatedBuilder(
      animation: isUrgent ? _urgentController : const AlwaysStoppedAnimation(0),
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppSpacing.borderRadiusLg,
            border: Border.all(
              color: isUrgent
                  ? AppColors.error.withOpacity(0.5 + (_urgentController.value * 0.5))
                  : priorityColor,
              width: isUrgent ? 3 : 2,
            ),
            boxShadow: isUrgent
                ? AppShadows.glowError(_urgentController.value * 0.3)
                : AppShadows.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildCardHeader(order, elapsedMinutes, priorityColor, isPreparing),
              
              // Items
              Expanded(
                child: _buildItemsList(items),
              ),
              
              // Livreur info
              if (livreur != null) _buildLivreurInfo(livreur),
              
              // Action button
              _buildActionButton(order['id'], isPreparing),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCardHeader(
    Map<String, dynamic> order,
    int elapsedMinutes,
    Color priorityColor,
    bool isPreparing,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: priorityColor.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg - 2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${order['order_number'] ?? ''}',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isPreparing ? AppColors.info : AppColors.warning,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isPreparing ? 'En préparation' : 'Nouvelle',
                      style: AppTypography.labelSmall.copyWith(
                        color: isPreparing ? AppColors.info : AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Timer badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: priorityColor,
              borderRadius: AppSpacing.borderRadiusSm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer, size: 12, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  '$elapsedMinutes\'',
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
    );
  }

  Widget _buildItemsList(List items) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final hasInstructions = item['special_instructions'] != null &&
            item['special_instructions'].toString().isNotEmpty;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quantity badge
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: Center(
                  child: Text(
                    '${item['quantity']}',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              
              // Item details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'] ?? '',
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hasInstructions)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.warningSurface,
                          borderRadius: AppSpacing.borderRadiusSm,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.warning_amber, size: 12, color: AppColors.warning),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                item['special_instructions'],
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.warning,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLivreurInfo(Map<String, dynamic> livreur) {
    final name = livreur['profile']?['full_name'] ?? 'Livreur';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.infoSurface,
        border: Border(
          top: BorderSide(color: AppColors.info.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.delivery_dining, size: 16, color: AppColors.info),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              name,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.info,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String orderId, bool isPreparing) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => isPreparing ? _markAsReady(orderId) : _startPreparing(orderId),
          style: ElevatedButton.styleFrom(
            backgroundColor: isPreparing ? AppColors.success : AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: AppSpacing.borderRadiusMd,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPreparing ? Icons.check_circle : Icons.restaurant,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                isPreparing ? 'PRÊT' : 'PRÉPARER',
                style: AppTypography.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}