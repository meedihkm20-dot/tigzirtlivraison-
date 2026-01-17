import 'package:flutter/material.dart';
import '../../../../core/design_system/theme/app_colors.dart';
import '../../../../core/design_system/theme/app_typography.dart';
import 'restaurant_orders_screen.dart';
import 'kitchen_screen_v2.dart';
import 'restaurant_order_history_screen.dart';

/// Hub des commandes avec 3 onglets : En Cours, Cuisine, Historique
class RestaurantOrdersHubScreen extends StatefulWidget {
  const RestaurantOrdersHubScreen({super.key});

  @override
  State<RestaurantOrdersHubScreen> createState() => _RestaurantOrdersHubScreenState();
}

class _RestaurantOrdersHubScreenState extends State<RestaurantOrdersHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('Commandes'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'En Cours', icon: Icon(Icons.list_alt, size: 20)),
            Tab(text: 'Cuisine', icon: Icon(Icons.restaurant, size: 20)),
            Tab(text: 'Historique', icon: Icon(Icons.history, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          RestaurantOrdersScreen(),
          KitchenScreenV2(),
          RestaurantOrderHistoryScreen(),
        ],
      ),
    );
  }
}
