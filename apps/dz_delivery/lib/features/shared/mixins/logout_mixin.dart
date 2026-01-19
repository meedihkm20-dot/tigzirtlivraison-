import 'package:flutter/material.dart';
import '../../../core/design_system/theme/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/onesignal_service.dart';
import '../../../core/router/app_router.dart';

/// Mixin pour la gestion de la déconnexion
/// Utilisable par Customer, Livreur et Restaurant
mixin LogoutMixin<T extends StatefulWidget> on State<T> {
  
  /// Affiche le dialogue de confirmation de déconnexion
  void showLogoutConfirmation({
    Color primaryColor = AppColors.primary,
    VoidCallback? onBeforeLogout,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: AppColors.error),
            SizedBox(width: 12),
            Text('Déconnexion'),
          ],
        ),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await performLogout(onBeforeLogout: onBeforeLogout);
    }
  }

  /// Effectue la déconnexion
  Future<void> performLogout({VoidCallback? onBeforeLogout}) async {
    try {
      // Exécuter callback avant déconnexion si fourni
      onBeforeLogout?.call();
      
      // Déconnecter de OneSignal
      await OneSignalService.logout();
      
      // Déconnecter de Supabase
      await SupabaseService.signOut();
      
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRouter.login,
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la déconnexion: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
