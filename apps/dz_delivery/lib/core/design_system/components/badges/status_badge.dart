import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';

/// Badge de statut premium
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool showDot;
  final bool isAnimated;
  final BadgeSize size;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.showDot = false,
    this.isAnimated = false,
    this.size = BadgeSize.medium,
  });

  /// Factory pour créer un badge de statut de commande
  factory StatusBadge.orderStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return StatusBadge(
          label: 'Nouvelle',
          color: AppColors.statusPending,
          showDot: true,
          isAnimated: true,
        );
      case 'confirmed':
        return StatusBadge(
          label: 'Confirmée',
          color: AppColors.statusConfirmed,
          icon: Icons.check,
        );
      case 'preparing':
        return StatusBadge(
          label: 'En préparation',
          color: AppColors.statusPreparing,
          icon: Icons.restaurant,
        );
      case 'ready':
        return StatusBadge(
          label: 'Prête',
          color: AppColors.statusReady,
          icon: Icons.check_circle,
        );
      case 'picked_up':
        return StatusBadge(
          label: 'En livraison',
          color: AppColors.statusPickedUp,
          icon: Icons.delivery_dining,
        );
      case 'delivered':
        return StatusBadge(
          label: 'Livrée',
          color: AppColors.statusDelivered,
          icon: Icons.done_all,
        );
      case 'cancelled':
        return StatusBadge(
          label: 'Annulée',
          color: AppColors.statusCancelled,
          icon: Icons.cancel,
        );
      default:
        return StatusBadge(
          label: status,
          color: AppColors.textSecondary,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = _getPadding();
    final textStyle = _getTextStyle();

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: AppSpacing.borderRadiusRound,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            _buildDot(),
            const SizedBox(width: 6),
          ],
          if (icon != null) ...[
            Icon(icon, size: _getIconSize(), color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: textStyle.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot() {
    if (isAnimated) {
      return _AnimatedDot(color: color, size: _getDotSize());
    }
    return Container(
      width: _getDotSize(),
      height: _getDotSize(),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case BadgeSize.small:
        return const EdgeInsets.symmetric(horizontal: 6, vertical: 2);
      case BadgeSize.medium:
        return const EdgeInsets.symmetric(horizontal: 10, vertical: 4);
      case BadgeSize.large:
        return const EdgeInsets.symmetric(horizontal: 14, vertical: 6);
    }
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case BadgeSize.small:
        return AppTypography.labelSmall;
      case BadgeSize.medium:
        return AppTypography.labelMedium;
      case BadgeSize.large:
        return AppTypography.labelLarge;
    }
  }

  double _getIconSize() {
    switch (size) {
      case BadgeSize.small:
        return 12;
      case BadgeSize.medium:
        return 14;
      case BadgeSize.large:
        return 18;
    }
  }

  double _getDotSize() {
    switch (size) {
      case BadgeSize.small:
        return 6;
      case BadgeSize.medium:
        return 8;
      case BadgeSize.large:
        return 10;
    }
  }
}

enum BadgeSize { small, medium, large }

/// Dot animé pour les badges
class _AnimatedDot extends StatefulWidget {
  final Color color;
  final double size;

  const _AnimatedDot({required this.color, required this.size});

  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.5 + (_controller.value * 0.5)),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.3 * _controller.value),
                blurRadius: 4 * _controller.value,
                spreadRadius: 2 * _controller.value,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Badge numérique (pour notifications, compteurs)
class CountBadge extends StatelessWidget {
  final int count;
  final Color? color;
  final bool showZero;

  const CountBadge({
    super.key,
    required this.count,
    this.color,
    this.showZero = false,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0 && !showZero) return const SizedBox.shrink();

    final displayCount = count > 99 ? '99+' : '$count';
    final bgColor = color ?? AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      constraints: const BoxConstraints(minWidth: 18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppSpacing.borderRadiusRound,
      ),
      child: Text(
        displayCount,
        style: AppTypography.labelSmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Badge de certification restaurant
class CertificationBadge extends StatelessWidget {
  final String type;

  const CertificationBadge({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final config = _getConfig();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.1),
        borderRadius: AppSpacing.borderRadiusSm,
        border: Border.all(color: config.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 14, color: config.color),
          const SizedBox(width: 4),
          Text(
            config.label,
            style: AppTypography.labelSmall.copyWith(
              color: config.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeConfig _getConfig() {
    switch (type.toLowerCase()) {
      case 'verified':
        return _BadgeConfig('Vérifié', Icons.verified, AppColors.info);
      case 'top_rated':
        return _BadgeConfig('Top', Icons.star, AppColors.warning);
      case 'fast_delivery':
        return _BadgeConfig('Rapide', Icons.bolt, AppColors.success);
      case 'hygiene_a':
        return _BadgeConfig('Hygiène A+', Icons.health_and_safety, AppColors.success);
      case 'eco_friendly':
        return _BadgeConfig('Éco', Icons.eco, AppColors.success);
      case 'popular':
        return _BadgeConfig('Populaire', Icons.local_fire_department, AppColors.error);
      default:
        return _BadgeConfig(type, Icons.badge, AppColors.textSecondary);
    }
  }
}

class _BadgeConfig {
  final String label;
  final IconData icon;
  final Color color;
  _BadgeConfig(this.label, this.icon, this.color);
}
