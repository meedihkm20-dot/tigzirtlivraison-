import 'package:flutter/material.dart';
import '../../../core/design_system/theme/app_colors.dart';
import '../../../core/design_system/theme/app_typography.dart';
import '../../../core/design_system/theme/app_spacing.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/router/app_router.dart';

/// Écran Plus avec menu de navigation vers écrans secondaires
class RestaurantMoreScreen extends StatelessWidget {
  const RestaurantMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Plus'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          // Section Gestion Restaurant
          _SectionHeader(title: '🍽️  GESTION RESTAURANT'),
          _MenuItem(
            icon: Icons.restaurant_menu,
            title: 'Menu & Plats',
            subtitle: 'Gérer les plats et catégories',
            onTap: () => Navigator.pushNamed(context, AppRouter.menu),
          ),
          _MenuItem(
            icon: Icons.local_offer,
            title: 'Promotions',
            subtitle: 'Codes promo et réductions',
            onTap: () => Navigator.pushNamed(context, AppRouter.promotions),
          ),
          _MenuItem(
            icon: Icons.inventory,
            title: 'Stocks',
            subtitle: 'Gestion inventaire',
            onTap: () => Navigator.pushNamed(context, AppRouter.stockManagement),
          ),
          
          const SizedBox(height: 24),
          
          // Section Mon Compte
          _SectionHeader(title: '👤 MON COMPTE'),
          _MenuItem(
            icon: Icons.store,
            title: 'Profil Restaurant',
            subtitle: 'Infos, photos, avis clients',
            onTap: () => Navigator.pushNamed(context, AppRouter.restaurantProfileV2),
          ),
          _MenuItem(
            icon: Icons.people,
            title: 'Équipe',
            subtitle: 'Gestion membres et rôles',
            onTap: () => Navigator.pushNamed(context, AppRouter.teamManagement),
          ),
          _MenuItem(
            icon: Icons.settings,
            title: 'Paramètres',
            subtitle: 'Notifications, langue, thème',
            onTap: () => Navigator.pushNamed(context, AppRouter.restaurantSettings),
          ),
          
          const SizedBox(height: 24),
          
          // Déconnexion
          _MenuItem(
            icon: Icons.logout,
            title: 'Déconnexion',
            subtitle: 'Se déconnecter du compte',
            color: AppColors.error,
            onTap: () => _showLogoutDialog(context),
          ),
          
          const SizedBox(height: 32),
          
          // Version
          Center(
            child: Text(
              'Version 1.0.0',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              await SupabaseService.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRouter.login,
                  (route) => false,
                );
              }
            },
            child: Text('Déconnexion', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: AppTypography.titleSmall.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? color;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final itemColor = color ?? AppColors.textPrimary;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppColors.surface,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (color ?? AppColors.primary).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: itemColor, size: 24),
        ),
        title: Text(
          title,
          style: AppTypography.titleSmall.copyWith(
            color: itemColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        trailing: Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }
}
