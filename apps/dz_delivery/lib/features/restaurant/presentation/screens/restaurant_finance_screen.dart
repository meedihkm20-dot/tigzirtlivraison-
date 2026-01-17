import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/theme/app_colors.dart';
import '../../../../core/design_system/theme/app_typography.dart';

/// Écran Finance Restaurant - En développement
class RestaurantFinanceScreen extends ConsumerStatefulWidget {
  const RestaurantFinanceScreen({super.key});

  @override
  ConsumerState<RestaurantFinanceScreen> createState() => _RestaurantFinanceScreenState();
}

class _RestaurantFinanceScreenState extends ConsumerState<RestaurantFinanceScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Finance'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet, size: 64, color: AppColors.textSecondary.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text('Section Finance', style: AppTypography.titleLarge),
            const SizedBox(height: 8),
            Text('En développement', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
