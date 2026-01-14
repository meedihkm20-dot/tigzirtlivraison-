import 'package:flutter/material.dart';

/// Design System - Couleurs
/// Palette premium pour DZ Delivery
class AppColors {
  AppColors._();

  // ============================================
  // PRIMARY COLORS
  // ============================================
  static const Color primary = Color(0xFFFF6B35);
  static const Color primaryLight = Color(0xFFFF8F66);
  static const Color primaryDark = Color(0xFFE55A2B);
  static const Color primarySurface = Color(0xFFFFF3EE);

  // ============================================
  // SECONDARY COLORS
  // ============================================
  static const Color secondary = Color(0xFF004E89);
  static const Color secondaryLight = Color(0xFF3373A3);
  static const Color secondaryDark = Color(0xFF003A66);
  static const Color secondarySurface = Color(0xFFE8F1F8);

  // ============================================
  // STATUS COLORS
  // ============================================
  static const Color success = Color(0xFF06D6A0);
  static const Color successLight = Color(0xFF34E4B8);
  static const Color successDark = Color(0xFF05B586);
  static const Color successSurface = Color(0xFFE6FBF5);

  static const Color warning = Color(0xFFFFD23F);
  static const Color warningLight = Color(0xFFFFDE6B);
  static const Color warningDark = Color(0xFFE5BC38);
  static const Color warningSurface = Color(0xFFFFFBE6);

  static const Color error = Color(0xFFEE4266);
  static const Color errorLight = Color(0xFFF26B87);
  static const Color errorDark = Color(0xFFD63B5B);
  static const Color errorSurface = Color(0xFFFDE8EC);

  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFF60A5FA);
  static const Color infoDark = Color(0xFF2563EB);
  static const Color infoSurface = Color(0xFFEBF2FE);

  // ============================================
  // NEUTRAL COLORS - LIGHT MODE
  // ============================================
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F3F4);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color outline = Color(0xFFE0E0E0);
  static const Color outlineVariant = Color(0xFFEEEEEE);
  static const Color divider = Color(0xFFE5E7EB);

  // ============================================
  // TEXT COLORS - LIGHT MODE
  // ============================================
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textDisabled = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFFFFFFFF);
  static const Color textOnSurface = Color(0xFF1A1A1A);

  // ============================================
  // NEUTRAL COLORS - DARK MODE
  // ============================================
  static const Color darkBackground = Color(0xFF0F0F0F);
  static const Color darkSurface = Color(0xFF1A1A1A);
  static const Color darkSurfaceVariant = Color(0xFF262626);
  static const Color darkSurfaceElevated = Color(0xFF2D2D2D);
  static const Color darkOutline = Color(0xFF404040);
  static const Color darkDivider = Color(0xFF333333);

  // ============================================
  // TEXT COLORS - DARK MODE
  // ============================================
  static const Color darkTextPrimary = Color(0xFFF5F5F5);
  static const Color darkTextSecondary = Color(0xFFA3A3A3);
  static const Color darkTextTertiary = Color(0xFF737373);

  // ============================================
  // ORDER STATUS COLORS
  // ============================================
  static const Color statusPending = Color(0xFFFF9800);
  static const Color statusConfirmed = Color(0xFF2196F3);
  static const Color statusPreparing = Color(0xFF9C27B0);
  static const Color statusReady = Color(0xFF4CAF50);
  static const Color statusPickedUp = Color(0xFF00BCD4);
  static const Color statusDelivered = Color(0xFF06D6A0);
  static const Color statusCancelled = Color(0xFFEE4266);

  // ============================================
  // PRIORITY COLORS (Kitchen)
  // ============================================
  static const Color priorityUrgent = Color(0xFFEF4444);
  static const Color priorityHigh = Color(0xFFF97316);
  static const Color priorityMedium = Color(0xFFEAB308);
  static const Color priorityLow = Color(0xFF22C55E);

  // ============================================
  // ROLE-SPECIFIC COLORS
  // ============================================
  
  // Restaurant (Orange - déjà défini comme primary)
  static const Color restaurantPrimary = primary;
  static const Color restaurantGradientStart = Color(0xFFFF6B35);
  static const Color restaurantGradientEnd = Color(0xFFFF8F66);
  
  // Client (Teal/Vert)
  static const Color clientPrimary = Color(0xFF00BFA6);
  static const Color clientPrimaryLight = Color(0xFF33CCBB);
  static const Color clientPrimaryDark = Color(0xFF00A896);
  static const Color clientSurface = Color(0xFFE0F7F4);
  static const Color clientGradientStart = Color(0xFF00BFA6);
  static const Color clientGradientEnd = Color(0xFF00D9C4);
  
  // Livreur (Bleu)
  static const Color livreurPrimary = Color(0xFF2196F3);
  static const Color livreurPrimaryLight = Color(0xFF64B5F6);
  static const Color livreurPrimaryDark = Color(0xFF1976D2);
  static const Color livreurSurface = Color(0xFFE3F2FD);
  static const Color livreurGradientStart = Color(0xFF2196F3);
  static const Color livreurGradientEnd = Color(0xFF42A5F5);
  
  // Tier Colors (Livreur)
  static const Color tierBronze = Color(0xFFCD7F32);
  static const Color tierSilver = Color(0xFFC0C0C0);
  static const Color tierGold = Color(0xFFFFD700);
  static const Color tierDiamond = Color(0xFF00CED1);

  // ============================================
  // GRADIENTS
  // ============================================
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [success, successLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [warning, warningLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient errorGradient = LinearGradient(
    colors: [error, errorLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Role-specific gradients
  static const LinearGradient clientGradient = LinearGradient(
    colors: [clientGradientStart, clientGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient livreurGradient = LinearGradient(
    colors: [livreurGradientStart, livreurGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient restaurantGradient = LinearGradient(
    colors: [restaurantGradientStart, restaurantGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Tier gradients
  static const LinearGradient bronzeGradient = LinearGradient(
    colors: [Color(0xFFCD7F32), Color(0xFFE8A854)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient silverGradient = LinearGradient(
    colors: [Color(0xFFC0C0C0), Color(0xFFE0E0E0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFE44D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient diamondGradient = LinearGradient(
    colors: [Color(0xFF00CED1), Color(0xFF40E0D0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkOverlay = LinearGradient(
    colors: [Colors.transparent, Color(0x99000000)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ============================================
  // SHIMMER COLORS
  // ============================================
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
  static const Color darkShimmerBase = Color(0xFF2D2D2D);
  static const Color darkShimmerHighlight = Color(0xFF404040);

  // ============================================
  // HELPER METHODS
  // ============================================
  
  /// Get status color by order status
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return statusPending;
      case 'confirmed':
        return statusConfirmed;
      case 'preparing':
        return statusPreparing;
      case 'ready':
        return statusReady;
      case 'picked_up':
        return statusPickedUp;
      case 'delivered':
        return statusDelivered;
      case 'cancelled':
        return statusCancelled;
      default:
        return textSecondary;
    }
  }

  /// Get priority color by elapsed minutes
  static Color getPriorityColor(int elapsedMinutes) {
    if (elapsedMinutes > 20) return priorityUrgent;
    if (elapsedMinutes > 15) return priorityHigh;
    if (elapsedMinutes > 10) return priorityMedium;
    return priorityLow;
  }

  /// Get color with opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }
}
