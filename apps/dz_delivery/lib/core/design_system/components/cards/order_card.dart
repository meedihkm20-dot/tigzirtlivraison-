import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_shadows.dart';
import '../../utils/order_status_helper.dart';

/// Carte de commande premium pour le restaurant
class OrderCard extends StatelessWidget {
  final String orderNumber;
  final String status;
  final String customerName;
  final String? customerPhone;
  final int itemCount;
  final double total;
  final DateTime createdAt;
  final String? livreurName;
  final List<OrderItemData> items;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onStartPreparing;
  final VoidCallback? onMarkReady;
  final bool showActions;
  final bool isUrgent;

  const OrderCard({
    super.key,
    required this.orderNumber,
    required this.status,
    required this.customerName,
    this.customerPhone,
    required this.itemCount,
    required this.total,
    required this.createdAt,
    this.livreurName,
    this.items = const [],
    this.onTap,
    this.onAccept,
    this.onReject,
    this.onStartPreparing,
    this.onMarkReady,
    this.showActions = true,
    this.isUrgent = false,
  });

  @override
  Widget build(BuildContext context) {
    final statusInfo = OrderStatusHelper.getInfo(status);
    final elapsedMinutes = DateTime.now().difference(createdAt).inMinutes;
    final priorityColor = AppColors.getPriorityColor(elapsedMinutes);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.borderRadiusLg,
          boxShadow: isUrgent ? AppShadows.glowError(0.3) : AppShadows.sm,
          border: Border.all(
            color: isUrgent ? AppColors.error : statusInfo.color.withOpacity(0.3),
            width: isUrgent ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(statusInfo, elapsedMinutes, priorityColor),
            
            // Divider
            const Divider(height: 1),
            
            // Content
            Padding(
              padding: AppSpacing.card,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer info
                  _buildCustomerInfo(),
                  
                  AppSpacing.vSm,
                  
                  // Items preview
                  if (items.isNotEmpty) ...[
                    _buildItemsPreview(),
                    AppSpacing.vSm,
                  ],
                  
                  // Total
                  _buildTotal(),
                  
                  // Livreur info
                  if (livreurName != null) ...[
                    AppSpacing.vSm,
                    _buildLivreurInfo(),
                  ],
                  
                  // Actions
                  if (showActions) ...[
                    AppSpacing.vMd,
                    _buildActions(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(OrderStatusInfo statusInfo, int elapsedMinutes, Color priorityColor) {
    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: statusInfo.color.withOpacity(0.05),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg - 1),
        ),
      ),
      child: Row(
        children: [
          // Order number
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#$orderNumber',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTime(createdAt),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          
          // Timer badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: priorityColor,
              borderRadius: AppSpacing.borderRadiusRound,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer, size: 14, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  '$elapsedMinutes min',
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusInfo.color.withOpacity(0.15),
              borderRadius: AppSpacing.borderRadiusRound,
            ),
            child: Text(
              statusInfo.label,
              style: AppTypography.labelSmall.copyWith(
                color: statusInfo.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: AppSpacing.borderRadiusRound,
          ),
          child: const Icon(Icons.person, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                customerName,
                style: AppTypography.titleSmall,
              ),
              if (customerPhone != null)
                Text(
                  customerPhone!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        // Call button
        if (customerPhone != null)
          IconButton(
            onPressed: () {
              // TODO: Call customer
            },
            icon: const Icon(Icons.phone, color: AppColors.primary),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primarySurface,
            ),
          ),
      ],
    );
  }

  Widget _buildItemsPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: Column(
        children: [
          ...items.take(3).map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: AppSpacing.borderRadiusSm,
                  ),
                  child: Center(
                    child: Text(
                      '${item.quantity}',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: AppTypography.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.specialInstructions != null)
                        Text(
                          '⚠️ ${item.specialInstructions}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.warning,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          )),
          if (items.length > 3)
            Text(
              '+${items.length - 3} autres articles',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTotal() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$itemCount article${itemCount > 1 ? 's' : ''}',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          '${total.toStringAsFixed(0)} DA',
          style: AppTypography.priceMedium.copyWith(
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildLivreurInfo() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.infoSurface,
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: Row(
        children: [
          const Icon(Icons.delivery_dining, size: 18, color: AppColors.info),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              livreurName!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.info,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.info),
        ],
      ),
    );
  }

  Widget _buildActions() {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'confirmed':
        return Row(
          children: [
            if (onReject != null)
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  child: const Text('Refuser'),
                ),
              ),
            if (onReject != null) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: status.toLowerCase() == 'pending' ? onAccept : onStartPreparing,
                icon: Icon(status.toLowerCase() == 'pending' ? Icons.check : Icons.restaurant),
                label: Text(status.toLowerCase() == 'pending' ? 'Accepter' : 'Préparer'),
              ),
            ),
          ],
        );
      case 'preparing':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onMarkReady,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            icon: const Icon(Icons.check_circle),
            label: const Text('Marquer prêt'),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

}

/// Data class pour les items de commande
class OrderItemData {
  final String name;
  final int quantity;
  final String? specialInstructions;

  const OrderItemData({
    required this.name,
    required this.quantity,
    this.specialInstructions,
  });
}
