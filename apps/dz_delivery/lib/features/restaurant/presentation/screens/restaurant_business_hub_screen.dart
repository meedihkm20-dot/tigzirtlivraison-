import 'package:flutter/material.dart';
import '../../../../core/design_system/theme/app_colors.dart';
import '../../../../core/design_system/theme/app_typography.dart';
import 'restaurant_finance_screen.dart';
import 'restaurant_livreur_management_screen.dart';
import 'stats_screen_v2.dart';
import 'reports_screen.dart';

/// Hub business avec 4 onglets : Finance, Livreurs, Stats, Rapports
class RestaurantBusinessHubScreen extends StatefulWidget {
  const RestaurantBusinessHubScreen({super.key});

  @override
  State<RestaurantBusinessHubScreen> createState() => _RestaurantBusinessHubScreenState();
}

class _RestaurantBusinessHubScreenState extends State<RestaurantBusinessHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Business'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Finance', icon: Icon(Icons.account_balance_wallet, size: 20)),
            Tab(text: 'Livreurs', icon: Icon(Icons.delivery_dining, size: 20)),
            Tab(text: 'Stats', icon: Icon(Icons.bar_chart, size: 20)),
            Tab(text: 'Rapports', icon: Icon(Icons.description, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          RestaurantFinanceScreen(),
          RestaurantLivreurManagementScreen(),
          StatsScreenV2(),
          ReportsScreen(),
        ],
      ),
    );
  }
}
