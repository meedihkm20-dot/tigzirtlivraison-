import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/design_system/theme/app_colors.dart';
import '../../../../core/design_system/theme/app_typography.dart';
import '../../../../core/design_system/theme/app_spacing.dart';
import '../../../../core/design_system/theme/app_shadows.dart';

/// Widget ProfileHeader réutilisable entre Customer, Livreur et Restaurant
/// Affiche l'avatar, le nom, le sous-titre et un badge optionnel
class ProfileHeader extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final String? subtitle;
  final Widget? badge;
  final VoidCallback? onAvatarTap;
  final Color primaryColor;
  final Gradient? gradient;
  final double expandedHeight;
  final List<Widget>? actions;
  final bool showBackButton;

  const ProfileHeader({
    super.key,
    required this.name,
    this.avatarUrl,
    this.subtitle,
    this.badge,
    this.onAvatarTap,
    this.primaryColor = AppColors.primary,
    this.gradient,
    this.expandedHeight = 200,
    this.actions,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: expandedHeight,
      floating: true,
      pinned: true,
      backgroundColor: primaryColor,
      automaticallyImplyLeading: showBackButton,
      actions: actions,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: gradient ?? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryColor, primaryColor.withOpacity(0.8)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: AppSpacing.screen,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: showBackButton ? 40 : 40),
                  _buildAvatar(),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    style: AppTypography.titleLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                  if (badge != null) ...[
                    const SizedBox(height: 8),
                    badge!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return GestureDetector(
      onTap: onAvatarTap,
      child: Stack(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: ClipOval(
              child: avatarUrl != null
                  ? CachedNetworkImage(
                      imageUrl: avatarUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.white.withOpacity(0.2),
                        child: const Icon(Icons.person, color: Colors.white, size: 40),
                      ),
                      errorWidget: (context, url, error) => _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),
          ),
          if (onAvatarTap != null)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.white.withOpacity(0.2),
      child: Center(
        child: name.isNotEmpty
            ? Text(
                name[0].toUpperCase(),
                style: AppTypography.displayMedium.copyWith(color: Colors.white),
              )
            : const Icon(Icons.person, color: Colors.white, size: 40),
      ),
    );
  }
}

/// Widget StatCardSimple pour afficher une statistique avec emoji
class StatCardSimple extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;

  const StatCardSimple({
    super.key,
    required this.emoji,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
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
}
