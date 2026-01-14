import 'package:flutter/material.dart';

/// Design System - Spacing & Dimensions
/// Système d'espacement cohérent pour DZ Delivery
class AppSpacing {
  AppSpacing._();

  // ============================================
  // BASE SPACING VALUES
  // ============================================
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  // ============================================
  // COMMON PADDINGS
  // ============================================
  
  /// Screen padding (horizontal)
  static const EdgeInsets screenHorizontal = EdgeInsets.symmetric(horizontal: md);
  
  /// Screen padding (all sides)
  static const EdgeInsets screen = EdgeInsets.all(md);
  
  /// Card padding
  static const EdgeInsets card = EdgeInsets.all(md);
  
  /// Card padding compact
  static const EdgeInsets cardCompact = EdgeInsets.all(sm);
  
  /// List item padding
  static const EdgeInsets listItem = EdgeInsets.symmetric(horizontal: md, vertical: sm);
  
  /// List item padding large
  static const EdgeInsets listItemLarge = EdgeInsets.symmetric(horizontal: md, vertical: md);
  
  /// Button padding
  static const EdgeInsets button = EdgeInsets.symmetric(horizontal: lg, vertical: 14);
  
  /// Button padding compact
  static const EdgeInsets buttonCompact = EdgeInsets.symmetric(horizontal: md, vertical: sm);
  
  /// Input padding
  static const EdgeInsets input = EdgeInsets.symmetric(horizontal: md, vertical: 14);
  
  /// Dialog padding
  static const EdgeInsets dialog = EdgeInsets.all(lg);
  
  /// Bottom sheet padding
  static const EdgeInsets bottomSheet = EdgeInsets.fromLTRB(md, lg, md, md);
  
  /// Badge padding
  static const EdgeInsets badge = EdgeInsets.symmetric(horizontal: sm, vertical: xs);
  
  /// Chip padding
  static const EdgeInsets chip = EdgeInsets.symmetric(horizontal: sm, vertical: xs);

  // ============================================
  // GAPS (SizedBox shortcuts)
  // ============================================
  
  /// Horizontal gaps
  static const SizedBox hXs = SizedBox(width: xs);
  static const SizedBox hSm = SizedBox(width: sm);
  static const SizedBox hMd = SizedBox(width: md);
  static const SizedBox hLg = SizedBox(width: lg);
  static const SizedBox hXl = SizedBox(width: xl);
  
  /// Vertical gaps
  static const SizedBox vXs = SizedBox(height: xs);
  static const SizedBox vSm = SizedBox(height: sm);
  static const SizedBox vMd = SizedBox(height: md);
  static const SizedBox vLg = SizedBox(height: lg);
  static const SizedBox vXl = SizedBox(height: xl);
  static const SizedBox vXxl = SizedBox(height: xxl);

  // ============================================
  // BORDER RADIUS
  // ============================================
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusRound = 100.0;

  static const BorderRadius borderRadiusXs = BorderRadius.all(Radius.circular(radiusXs));
  static const BorderRadius borderRadiusSm = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius borderRadiusMd = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius borderRadiusLg = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius borderRadiusXl = BorderRadius.all(Radius.circular(radiusXl));
  static const BorderRadius borderRadiusRound = BorderRadius.all(Radius.circular(radiusRound));

  /// Top only radius (for bottom sheets)
  static const BorderRadius borderRadiusTopLg = BorderRadius.vertical(top: Radius.circular(radiusLg));
  static const BorderRadius borderRadiusTopXl = BorderRadius.vertical(top: Radius.circular(radiusXl));

  // ============================================
  // ICON SIZES
  // ============================================
  static const double iconXs = 12.0;
  static const double iconSm = 16.0;
  static const double iconMd = 20.0;
  static const double iconLg = 24.0;
  static const double iconXl = 32.0;
  static const double iconXxl = 48.0;

  // ============================================
  // AVATAR SIZES
  // ============================================
  static const double avatarXs = 24.0;
  static const double avatarSm = 32.0;
  static const double avatarMd = 40.0;
  static const double avatarLg = 56.0;
  static const double avatarXl = 80.0;
  static const double avatarXxl = 120.0;

  // ============================================
  // IMAGE SIZES
  // ============================================
  static const double thumbnailSm = 48.0;
  static const double thumbnailMd = 64.0;
  static const double thumbnailLg = 80.0;
  static const double thumbnailXl = 120.0;

  // ============================================
  // CARD DIMENSIONS
  // ============================================
  static const double cardMinHeight = 80.0;
  static const double cardImageHeight = 120.0;
  static const double cardImageHeightLarge = 180.0;
  static const double cardImageHeightHero = 240.0;

  // ============================================
  // BUTTON DIMENSIONS
  // ============================================
  static const double buttonHeight = 48.0;
  static const double buttonHeightSm = 36.0;
  static const double buttonHeightLg = 56.0;
  static const double buttonMinWidth = 120.0;

  // ============================================
  // INPUT DIMENSIONS
  // ============================================
  static const double inputHeight = 48.0;
  static const double inputHeightLg = 56.0;

  // ============================================
  // BOTTOM NAV & APP BAR
  // ============================================
  static const double appBarHeight = 56.0;
  static const double bottomNavHeight = 64.0;
  static const double bottomSheetMinHeight = 200.0;

  // ============================================
  // HELPER METHODS
  // ============================================
  
  /// Create symmetric padding
  static EdgeInsets symmetric({double horizontal = 0, double vertical = 0}) {
    return EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
  }

  /// Create padding from LTRB
  static EdgeInsets only({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) {
    return EdgeInsets.fromLTRB(left, top, right, bottom);
  }

  /// Create uniform padding
  static EdgeInsets all(double value) {
    return EdgeInsets.all(value);
  }

  /// Create horizontal gap
  static SizedBox horizontalGap(double width) {
    return SizedBox(width: width);
  }

  /// Create vertical gap
  static SizedBox verticalGap(double height) {
    return SizedBox(height: height);
  }
}
