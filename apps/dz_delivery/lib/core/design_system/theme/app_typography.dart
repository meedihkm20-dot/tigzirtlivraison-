import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Design System - Typographie
/// Styles de texte premium pour DZ Delivery
class AppTypography {
  AppTypography._();

  // ============================================
  // FONT FAMILIES
  // ============================================
  static const String fontFamily = 'Poppins';
  static const String fontFamilyMono = 'RobotoMono';

  // ============================================
  // DISPLAY STYLES (Hero text)
  // ============================================
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 40,
    fontWeight: FontWeight.bold,
    height: 1.1,
    letterSpacing: -1,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );

  // ============================================
  // HEADLINE STYLES
  // ============================================
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.3,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  // ============================================
  // TITLE STYLES
  // ============================================
  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  // ============================================
  // BODY STYLES (AMÉLIORÉS)
  // ============================================
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,        // Augmenté de 16 à 17
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.1,  // Ajout d'espacement
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,        // Augmenté de 14 à 15
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.1,  // Ajout d'espacement
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,        // Augmenté de 12 à 13
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0.1,  // Ajout d'espacement
  );

  // ============================================
  // LABEL STYLES (AMÉLIORÉS)
  // ============================================
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,        // Augmenté de 14 à 15
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.3,  // Réduit de 0.5 à 0.3
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,        // Augmenté de 12 à 13
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.3,  // Réduit de 0.5 à 0.3
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,        // Augmenté de 10 à 11
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.3,  // Réduit de 0.5 à 0.3
  );

  // ============================================
  // SPECIAL STYLES
  // ============================================
  
  /// Price style (monospace for alignment)
  static const TextStyle priceLarge = TextStyle(
    fontFamily: fontFamilyMono,
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );

  static const TextStyle priceMedium = TextStyle(
    fontFamily: fontFamilyMono,
    fontSize: 18,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );

  static const TextStyle priceSmall = TextStyle(
    fontFamily: fontFamilyMono,
    fontSize: 14,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );

  /// Badge text
  static const TextStyle badge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.bold,
    height: 1.2,
    letterSpacing: 0.5,
  );

  /// Button text
  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.5,
  );

  /// Caption text
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.normal,
    height: 1.4,
    color: AppColors.textTertiary,
  );

  /// Overline text
  static const TextStyle overline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 1.5,
  );

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Apply color to text style
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  /// Apply primary color
  static TextStyle primary(TextStyle style) {
    return style.copyWith(color: AppColors.primary);
  }

  /// Apply secondary text color
  static TextStyle secondary(TextStyle style) {
    return style.copyWith(color: AppColors.textSecondary);
  }

  /// Apply error color
  static TextStyle error(TextStyle style) {
    return style.copyWith(color: AppColors.error);
  }

  /// Apply success color
  static TextStyle success(TextStyle style) {
    return style.copyWith(color: AppColors.success);
  }

  /// Make text bold
  static TextStyle bold(TextStyle style) {
    return style.copyWith(fontWeight: FontWeight.bold);
  }

  /// Make text semibold
  static TextStyle semiBold(TextStyle style) {
    return style.copyWith(fontWeight: FontWeight.w600);
  }

  /// Add line through (strikethrough)
  static TextStyle lineThrough(TextStyle style) {
    return style.copyWith(decoration: TextDecoration.lineThrough);
  }
}
