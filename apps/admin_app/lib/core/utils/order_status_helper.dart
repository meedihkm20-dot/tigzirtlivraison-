import 'package:flutter/material.dart';

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
        return const OrderStatusInfo(
          label: 'En attente',
          color: Colors.orange,
          icon: Icons.schedule,
        );
      case 'confirmed':
        return const OrderStatusInfo(
          label: 'Confirmée',
          color: Colors.blue,
          icon: Icons.check,
        );
      case 'preparing':
        return const OrderStatusInfo(
          label: 'Préparation',
          color: Colors.purple,
          icon: Icons.restaurant,
        );
      case 'ready':
        return const OrderStatusInfo(
          label: 'Prête',
          color: Colors.teal,
          icon: Icons.check_circle,
        );
      case 'picked_up':
        return const OrderStatusInfo(
          label: 'Récupérée',
          color: Colors.indigo,
          icon: Icons.local_shipping,
        );
      case 'delivering':
        return const OrderStatusInfo(
          label: 'En livraison',
          color: Colors.blue,
          icon: Icons.delivery_dining,
        );
      case 'delivered':
        return const OrderStatusInfo(
          label: 'Livrée',
          color: Colors.green,
          icon: Icons.done_all,
        );
      case 'cancelled':
        return const OrderStatusInfo(
          label: 'Annulée',
          color: Colors.red,
          icon: Icons.cancel,
        );
      default:
        return OrderStatusInfo(
          label: status ?? 'Inconnu',
          color: Colors.grey,
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
}

/// Informations de statut de commande
class OrderStatusInfo {
  final String label;
  final Color color;
  final IconData icon;

  const OrderStatusInfo({
    required this.label,
    required this.color,
    required this.icon,
  });
}
