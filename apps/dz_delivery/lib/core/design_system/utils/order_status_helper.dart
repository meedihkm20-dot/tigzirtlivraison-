import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Classe utilitaire pour les informations de statut de commande
/// SOURCE DE VÉRITÉ pour les labels et couleurs de statut
/// 
/// Status valides (SQL): 'pending', 'confirmed', 'preparing', 'ready', 
/// 'picked_up', 'delivering', 'delivered', 'cancelled'
class OrderStatusHelper {
  /// Obtenir les informations de statut (label + couleur)
  static OrderStatusInfo getInfo(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return OrderStatusInfo(
          label: 'Nouvelle',
          labelCustomer: 'En attente',
          color: AppColors.statusPending,
          icon: Icons.schedule,
        );
      case 'confirmed':
        return OrderStatusInfo(
          label: 'Confirmée',
          labelCustomer: 'Confirmée',
          color: AppColors.statusConfirmed,
          icon: Icons.check,
        );
      case 'preparing':
        return OrderStatusInfo(
          label: 'En préparation',
          labelCustomer: 'En préparation',
          color: AppColors.statusPreparing,
          icon: Icons.restaurant,
        );
      case 'ready':
        return OrderStatusInfo(
          label: 'Prête',
          labelCustomer: 'Prête',
          color: AppColors.statusReady,
          icon: Icons.check_circle,
        );
      case 'picked_up':
        return OrderStatusInfo(
          label: 'En livraison',
          labelCustomer: 'Récupérée',
          color: AppColors.statusPickedUp,
          icon: Icons.delivery_dining,
        );
      case 'delivering':
        return OrderStatusInfo(
          label: 'En livraison',
          labelCustomer: 'En livraison',
          color: AppColors.statusPickedUp,
          icon: Icons.delivery_dining,
        );
      case 'delivered':
        return OrderStatusInfo(
          label: 'Livrée',
          labelCustomer: 'Livrée',
          color: AppColors.statusDelivered,
          icon: Icons.done_all,
        );
      case 'cancelled':
        return OrderStatusInfo(
          label: 'Annulée',
          labelCustomer: 'Annulée',
          color: AppColors.statusCancelled,
          icon: Icons.cancel,
        );
      default:
        return OrderStatusInfo(
          label: status ?? 'Inconnu',
          labelCustomer: status ?? 'Inconnu',
          color: AppColors.textSecondary,
          icon: Icons.help_outline,
        );
    }
  }

  /// Vérifier si le statut est actif (commande en cours)
  static bool isActive(String? status) {
    return ['pending', 'confirmed', 'preparing', 'ready', 'picked_up', 'delivering']
        .contains(status?.toLowerCase());
  }

  /// Vérifier si le statut est final
  static bool isFinal(String? status) {
    return ['delivered', 'cancelled'].contains(status?.toLowerCase());
  }

  /// Obtenir l'ordre du statut (pour timeline)
  static int getOrder(String? status) {
    const order = {
      'pending': 0,
      'confirmed': 1,
      'preparing': 2,
      'ready': 3,
      'picked_up': 4,
      'delivering': 5,
      'delivered': 6,
      'cancelled': -1,
    };
    return order[status?.toLowerCase()] ?? -2;
  }
}

/// Informations de statut de commande
class OrderStatusInfo {
  final String label;
  final String labelCustomer;
  final Color color;
  final IconData icon;

  const OrderStatusInfo({
    required this.label,
    required this.labelCustomer,
    required this.color,
    required this.icon,
  });
}
