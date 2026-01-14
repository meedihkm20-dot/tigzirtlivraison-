import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_shadows.dart';

/// Bouton d'action premium avec animations
class ActionButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final ActionButtonStyle style;
  final ActionButtonSize size;
  final Color? color;
  final bool isLoading;
  final bool isFullWidth;
  final int? badge;

  const ActionButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.style = ActionButtonStyle.filled,
    this.size = ActionButtonSize.medium,
    this.color,
    this.isLoading = false,
    this.isFullWidth = false,
    this.badge,
  });

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTap() {
    if (widget.onPressed != null && !widget.isLoading) {
      HapticFeedback.lightImpact();
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor = widget.color ?? AppColors.primary;
    final height = _getHeight();
    final padding = _getPadding();
    final textStyle = _getTextStyle();

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: height,
              constraints: widget.isFullWidth
                  ? const BoxConstraints(minWidth: double.infinity)
                  : null,
              padding: padding,
              decoration: _getDecoration(buttonColor),
              child: _buildContent(buttonColor, textStyle),
            ),
          );
        },
      ),
    );
  }

  BoxDecoration _getDecoration(Color color) {
    switch (widget.style) {
      case ActionButtonStyle.filled:
        return BoxDecoration(
          color: widget.onPressed == null
              ? color.withOpacity(0.5)
              : (_isPressed ? color.withOpacity(0.8) : color),
          borderRadius: AppSpacing.borderRadiusMd,
          boxShadow: widget.onPressed != null && !_isPressed
              ? AppShadows.colored(color, 0.3)
              : null,
        );
      case ActionButtonStyle.outlined:
        return BoxDecoration(
          color: _isPressed ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(
            color: widget.onPressed == null ? color.withOpacity(0.5) : color,
            width: 1.5,
          ),
        );
      case ActionButtonStyle.ghost:
        return BoxDecoration(
          color: _isPressed ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: AppSpacing.borderRadiusMd,
        );
      case ActionButtonStyle.soft:
        return BoxDecoration(
          color: _isPressed ? color.withOpacity(0.2) : color.withOpacity(0.1),
          borderRadius: AppSpacing.borderRadiusMd,
        );
    }
  }

  Widget _buildContent(Color color, TextStyle textStyle) {
    final textColor = _getTextColor(color);

    if (widget.isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(textColor),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(widget.icon, size: _getIconSize(), color: textColor),
              if (widget.badge != null && widget.badge! > 0)
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
                      '${widget.badge}',
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
        ],
        Text(
          widget.label,
          style: textStyle.copyWith(color: textColor),
        ),
      ],
    );
  }

  Color _getTextColor(Color buttonColor) {
    switch (widget.style) {
      case ActionButtonStyle.filled:
        return Colors.white;
      case ActionButtonStyle.outlined:
      case ActionButtonStyle.ghost:
      case ActionButtonStyle.soft:
        return buttonColor;
    }
  }

  double _getHeight() {
    switch (widget.size) {
      case ActionButtonSize.small:
        return 36;
      case ActionButtonSize.medium:
        return 48;
      case ActionButtonSize.large:
        return 56;
    }
  }

  EdgeInsets _getPadding() {
    switch (widget.size) {
      case ActionButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12);
      case ActionButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 20);
      case ActionButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 28);
    }
  }

  TextStyle _getTextStyle() {
    switch (widget.size) {
      case ActionButtonSize.small:
        return AppTypography.labelMedium;
      case ActionButtonSize.medium:
        return AppTypography.labelLarge;
      case ActionButtonSize.large:
        return AppTypography.titleSmall;
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case ActionButtonSize.small:
        return 16;
      case ActionButtonSize.medium:
        return 20;
      case ActionButtonSize.large:
        return 24;
    }
  }
}

enum ActionButtonStyle { filled, outlined, ghost, soft }
enum ActionButtonSize { small, medium, large }

/// Bouton d'action rapide (icône seulement)
class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final int? badge;

  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          HapticFeedback.lightImpact();
          onTap!();
        }
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
                if (badge != null && badge! > 0)
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
              style: AppTypography.labelLarge.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
