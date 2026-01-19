import 'package:flutter/material.dart';
import '../../../../core/design_system/theme/app_colors.dart';
import '../../../../core/design_system/theme/app_typography.dart';
import '../../../../core/design_system/theme/app_spacing.dart';
import '../../../../core/design_system/theme/app_shadows.dart';

/// Widget SettingsMenuItem pour afficher un élément de menu paramètre
class SettingsMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool isDestructive;
  final Widget? trailing;
  final Color? iconColor;

  const SettingsMenuItem({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.isDestructive = false,
    this.trailing,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = isDestructive 
        ? AppColors.error 
        : iconColor ?? AppColors.textSecondary;
    final effectiveTextColor = isDestructive 
        ? AppColors.error 
        : AppColors.textPrimary;

    return ListTile(
      leading: Icon(icon, color: effectiveIconColor),
      title: Text(
        title,
        style: AppTypography.bodyMedium.copyWith(color: effectiveTextColor),
      ),
      subtitle: subtitle != null
          ? Text(subtitle!, style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary))
          : null,
      trailing: trailing ?? const Icon(Icons.chevron_right, color: AppColors.textTertiary),
      onTap: onTap,
    );
  }
}

/// Widget SettingsSection pour grouper des éléments de paramètres
class SettingsSection extends StatelessWidget {
  final String? title;
  final List<SettingsMenuItem> items;
  final EdgeInsetsGeometry? padding;

  const SettingsSection({
    super.key,
    this.title,
    required this.items,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? AppSpacing.screenHorizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!, style: AppTypography.titleMedium),
            const SizedBox(height: 12),
          ],
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppSpacing.borderRadiusMd,
              boxShadow: AppShadows.sm,
            ),
            child: Column(
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isLast = index == items.length - 1;

                return Column(
                  children: [
                    item,
                    if (!isLast) const Divider(height: 1, indent: 56),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget simple pour une liste de paramètres sans conteneur
class SettingsList extends StatelessWidget {
  final String? title;
  final List<SettingsMenuItem> items;
  final bool showDividers;

  const SettingsList({
    super.key,
    this.title,
    required this.items,
    this.showDividers = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.screenHorizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!, style: AppTypography.titleMedium),
            const SizedBox(height: 12),
          ],
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == items.length - 1;

            return Column(
              children: [
                item,
                if (!isLast && showDividers) const Divider(height: 1),
              ],
            );
          }),
        ],
      ),
    );
  }
}
