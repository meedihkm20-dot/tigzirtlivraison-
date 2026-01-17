import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/theme/app_colors.dart';
import '../../../../core/design_system/theme/app_typography.dart';

/// Écran Historique Commandes Restaurant - En développement
class RestaurantOrderHistoryScreen extends ConsumerStatefulWidget {
  const RestaurantOrderHistoryScreen({super.key});

  @override
  ConsumerState<RestaurantOrderHistoryScreen> createState() => _RestaurantOrderHistoryScreenState();
}

class _RestaurantOrderHistoryScreenState extends ConsumerState<RestaurantOrderHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Historique'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: AppColors.textSecondary.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text('Historique des commandes', style: AppTypography.titleLarge),
            const SizedBox(height: 8),
            Text('En développement', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
