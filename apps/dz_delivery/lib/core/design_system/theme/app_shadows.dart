import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Design System - Shadows & Elevations
/// Ombres premium pour DZ Delivery
class AppShadows {
  AppShadows._();

  // ============================================
  // STANDARD SHADOWS
  // ============================================
  
  /// No shadow
  static const List<BoxShadow> none = [];

  /// Extra small shadow (subtle)
  static const List<BoxShadow> xs = [
    BoxShadow(
      color: Color(0x08000000),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  /// Small shadow
  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  /// Medium shadow (default for cards)
  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];

  /// Large shadow (elevated elements)
  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x1F000000),
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];

  /// Extra large shadow (modals, dialogs)
  static const List<BoxShadow> xl = [
    BoxShadow(
      color: Color(0x29000000),
      blurRadius: 24,
      offset: Offset(0, 12),
    ),
  ];

  /// 2XL shadow (floating elements)
  static const List<BoxShadow> xxl = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 32,
      offset: Offset(0, 16),
    ),
  ];

  // ============================================
  // SOFT SHADOWS (More diffuse)
  // ============================================
  
  static const List<BoxShadow> softSm = [
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 8,
      spreadRadius: 2,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> softMd = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 16,
      spreadRadius: 4,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> softLg = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 24,
      spreadRadius: 6,
      offset: Offset(0, 8),
    ),
  ];

  // ============================================
  // COLORED SHADOWS
  // ============================================
  
  /// Primary color shadow
  static List<BoxShadow> primary([double opacity = 0.3]) => [
    BoxShadow(
      color: AppColors.primary.withOpacity(opacity),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  /// Success color shadow
  static List<BoxShadow> success([double opacity = 0.3]) => [
    BoxShadow(
      color: AppColors.success.withOpacity(opacity),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  /// Error color shadow
  static List<BoxShadow> error([double opacity = 0.3]) => [
    BoxShadow(
      color: AppColors.error.withOpacity(opacity),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  /// Warning color shadow
  static List<BoxShadow> warning([double opacity = 0.3]) => [
    BoxShadow(
      color: AppColors.warning.withOpacity(opacity),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  /// Info color shadow
  static List<BoxShadow> info([double opacity = 0.3]) => [
    BoxShadow(
      color: AppColors.info.withOpacity(opacity),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  /// Custom colored shadow
  static List<BoxShadow> colored(Color color, [double opacity = 0.3]) => [
    BoxShadow(
      color: color.withOpacity(opacity),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // ============================================
  // INNER SHADOWS
  // ============================================
  
  static const List<BoxShadow> innerSm = [
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 4,
      offset: Offset(0, 2),
      blurStyle: BlurStyle.inner,
    ),
  ];

  static const List<BoxShadow> innerMd = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 8,
      offset: Offset(0, 4),
      blurStyle: BlurStyle.inner,
    ),
  ];

  // ============================================
  // GLOW EFFECTS
  // ============================================
  
  /// Primary glow
  static List<BoxShadow> glowPrimary([double intensity = 0.4]) => [
    BoxShadow(
      color: AppColors.primary.withOpacity(intensity),
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];

  /// Success glow
  static List<BoxShadow> glowSuccess([double intensity = 0.4]) => [
    BoxShadow(
      color: AppColors.success.withOpacity(intensity),
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];

  /// Error glow (for alerts)
  static List<BoxShadow> glowError([double intensity = 0.4]) => [
    BoxShadow(
      color: AppColors.error.withOpacity(intensity),
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];

  // ============================================
  // DARK MODE SHADOWS
  // ============================================
  
  static const List<BoxShadow> darkSm = [
    BoxShadow(
      color: Color(0x40000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> darkMd = [
    BoxShadow(
      color: Color(0x50000000),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> darkLg = [
    BoxShadow(
      color: Color(0x60000000),
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];

  // ============================================
  // SPECIAL EFFECTS
  // ============================================
  
  /// Bottom sheet shadow
  static const List<BoxShadow> bottomSheet = [
    BoxShadow(
      color: Color(0x1F000000),
      blurRadius: 16,
      offset: Offset(0, -4),
    ),
  ];

  /// App bar shadow
  static const List<BoxShadow> appBar = [
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  /// FAB shadow
  static const List<BoxShadow> fab = [
    BoxShadow(
      color: Color(0x29000000),
      blurRadius: 12,
      offset: Offset(0, 6),
    ),
  ];

  /// Card hover shadow
  static const List<BoxShadow> cardHover = [
    BoxShadow(
      color: Color(0x1F000000),
      blurRadius: 20,
      offset: Offset(0, 10),
    ),
  ];

  // ============================================
  // HELPER METHODS
  // ============================================
  
  /// Get shadow by elevation level (0-5)
  static List<BoxShadow> byElevation(int level) {
    switch (level) {
      case 0:
        return none;
      case 1:
        return xs;
      case 2:
        return sm;
      case 3:
        return md;
      case 4:
        return lg;
      case 5:
        return xl;
      default:
        return md;
    }
  }
}
