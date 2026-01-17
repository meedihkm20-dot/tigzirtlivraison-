import 'package:flutter/material.dart';

/// Espacements de l'application Admin
class AppSpacing {
  // Espacements de base
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  
  // Padding pour les écrans
  static const EdgeInsets screen = EdgeInsets.all(md);
  static const EdgeInsets screenHorizontal = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets screenVertical = EdgeInsets.symmetric(vertical: md);
  
  // Padding pour les cartes
  static const EdgeInsets card = EdgeInsets.all(md);
  static const EdgeInsets cardSmall = EdgeInsets.all(sm);
  
  // Margin
  static const EdgeInsets marginSmall = EdgeInsets.all(sm);
  static const EdgeInsets marginMedium = EdgeInsets.all(md);
  static const EdgeInsets marginLarge = EdgeInsets.all(lg);
}