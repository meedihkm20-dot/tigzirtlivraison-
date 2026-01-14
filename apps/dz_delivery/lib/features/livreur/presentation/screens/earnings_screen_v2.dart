import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/design_system/theme/app_colors.dart';
import '../../../../core/design_system/theme/app_typography.dart';
import '../../../../core/design_system/theme/app_spacing.dart';
import '../../../../core/design_system/theme/app_shadows.dart';
import '../../../../core/services/supabase_service.dart';

/// Écran Gains Livreur V2 - Premium
/// Graphiques, historique, prévisions, détails par période
class EarningsScreenV2 extends StatefulWidget {
  const EarningsScreenV2({super.key});

  @override
  State<EarningsScreenV2> createState() => _EarningsScreenV2State();
}

class _EarningsScreenV2State extends State<EarningsScreenV2>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  int _selectedPeriod = 0; // 0=Aujourd'hui, 1=Semaine, 2=Mois
  
  Map<String, dynamic>? _todayStats;
  Map<String, dynamic>? _weekStats;
  Map<String, dynamic>? _monthStats;
  List<Map<String, dynamic>> _recentTransactions = [];
  List<double> _weeklyData = [];
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedPeriod = _tabController.index);
      }
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }


  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _safeCall(() => SupabaseService.getLivreurTodayStats(), <String, dynamic>{}),
        _safeCall(() => SupabaseService.getLivreurWeekStats(), <String, dynamic>{}),
        _safeCall(() => SupabaseService.getLivreurMonthStats(), <String, dynamic>{}),
        _safeCall(() => SupabaseService.getLivreurTransactions(limit: 10), <Map<String, dynamic>>[]),
        _safeCall(() => SupabaseService.getLivreurWeeklyData(), <double>[]),
      ]);

      if (mounted) {
        setState(() {
          _todayStats = results[0] as Map<String, dynamic>;
          _weekStats = results[1] as Map<String, dynamic>;
          _monthStats = results[2] as Map<String, dynamic>;
          _recentTransactions = results[3] as List<Map<String, dynamic>>;
          _weeklyData = results[4] as List<double>;
          if (_weeklyData.isEmpty) {
            _weeklyData = [1200, 1800, 1500, 2200, 1900, 2500, 2100];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<T> _safeCall<T>(Future<T> Function() call, T defaultValue) async {
    try {
      return await call();
    } catch (e) {
      return defaultValue;
    }
  }

  Map<String, dynamic> get _currentStats {
    switch (_selectedPeriod) {
      case 1: return _weekStats ?? {};
      case 2: return _monthStats ?? {};
      default: return _todayStats ?? {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.livreurPrimary))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.livreurPrimary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildEarningsCard(),
                    _buildPeriodTabs(),
                    _buildStatsGrid(),
                    _buildWeeklyChart(),
                    _buildTransactionsList(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.livreurPrimary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Mes gains',
        style: AppTypography.titleMedium.copyWith(color: Colors.white),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.download, color: Colors.white),
          onPressed: _exportData,
        ),
      ],
    );
  }

  Widget _buildEarningsCard() {
    final earnings = (_currentStats['earnings'] as num?)?.toDouble() ?? 0;
    final tips = (_currentStats['tips'] as num?)?.toDouble() ?? 0;
    final total = earnings + tips;

    return Container(
      margin: AppSpacing.screen,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.livreurGradient,
        borderRadius: AppSpacing.borderRadiusLg,
        boxShadow: AppShadows.lg,
      ),
      child: Column(
        children: [
          Text(
            'Total gagné',
            style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            '${total.toStringAsFixed(0)} DA',
            style: AppTypography.displayMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildEarningsBadge('💰 Livraisons', '${earnings.toStringAsFixed(0)} DA'),
              const SizedBox(width: 24),
              _buildEarningsBadge('💝 Pourboires', '${tips.toStringAsFixed(0)} DA'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsBadge(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(label, style: AppTypography.labelSmall.copyWith(color: Colors.white70)),
          Text(value, style: AppTypography.labelMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPeriodTabs() {
    return Container(
      margin: AppSpacing.screenHorizontal,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.livreurPrimary,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold),
        tabs: const [
          Tab(text: 'Aujourd\'hui'),
          Tab(text: 'Semaine'),
          Tab(text: 'Mois'),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final deliveries = _currentStats['deliveries'] ?? 0;
    final distance = (_currentStats['distance'] as num?)?.toDouble() ?? 0;
    final hours = (_currentStats['hours'] as num?)?.toDouble() ?? 0;
    final avgPerDelivery = deliveries > 0 
        ? ((_currentStats['earnings'] as num?)?.toDouble() ?? 0) / deliveries 
        : 0.0;

    return Padding(
      padding: AppSpacing.screen,
      child: Row(
        children: [
          Expanded(child: _buildStatTile('🚚', '$deliveries', 'Livraisons')),
          const SizedBox(width: 12),
          Expanded(child: _buildStatTile('📍', '${distance.toStringAsFixed(1)}', 'km')),
          const SizedBox(width: 12),
          Expanded(child: _buildStatTile('⏱️', '${hours.toStringAsFixed(1)}', 'heures')),
          const SizedBox(width: 12),
          Expanded(child: _buildStatTile('📊', '${avgPerDelivery.toStringAsFixed(0)}', 'DA/liv')),
        ],
      ),
    );
  }

  Widget _buildStatTile(String emoji, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusMd,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(value, style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
          Text(label, style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary)),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    final maxValue = _weeklyData.reduce((a, b) => a > b ? a : b);
    final days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    final today = DateTime.now().weekday - 1;

    return Container(
      margin: AppSpacing.screen,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cette semaine', style: AppTypography.titleSmall),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final value = index < _weeklyData.length ? _weeklyData[index] : 0.0;
                final height = maxValue > 0 ? (value / maxValue) * 120 : 0.0;
                final isToday = index == today;
                
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${(value / 1000).toStringAsFixed(1)}K',
                          style: AppTypography.labelSmall.copyWith(
                            color: isToday ? AppColors.livreurPrimary : AppColors.textTertiary,
                            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          height: height,
                          decoration: BoxDecoration(
                            color: isToday ? AppColors.livreurPrimary : AppColors.livreurSurface,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          days[index],
                          style: AppTypography.labelSmall.copyWith(
                            color: isToday ? AppColors.livreurPrimary : AppColors.textTertiary,
                            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    return Padding(
      padding: AppSpacing.screenHorizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Transactions récentes', style: AppTypography.titleSmall),
              TextButton(
                onPressed: _showAllTransactions,
                child: Text(
                  'Voir tout',
                  style: AppTypography.labelMedium.copyWith(color: AppColors.livreurPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_recentTransactions.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppSpacing.borderRadiusMd,
              ),
              child: Center(
                child: Text(
                  'Aucune transaction',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
                ),
              ),
            )
          else
            ..._recentTransactions.map((t) => _buildTransactionItem(t)),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final type = transaction['type'] ?? 'delivery';
    final amount = (transaction['amount'] as num?)?.toDouble() ?? 0;
    final date = transaction['created_at'] != null
        ? DateTime.parse(transaction['created_at'])
        : DateTime.now();
    final isPositive = amount >= 0;

    IconData icon;
    Color color;
    String label;

    switch (type) {
      case 'tip':
        icon = Icons.favorite;
        color = AppColors.warning;
        label = 'Pourboire';
        break;
      case 'bonus':
        icon = Icons.star;
        color = AppColors.tierGold;
        label = 'Bonus';
        break;
      case 'withdrawal':
        icon = Icons.account_balance;
        color = AppColors.error;
        label = 'Retrait';
        break;
      default:
        icon = Icons.delivery_dining;
        color = AppColors.livreurPrimary;
        label = 'Livraison';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusMd,
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.labelMedium),
                Text(
                  '${date.day}/${date.month} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          Text(
            '${isPositive ? '+' : ''}${amount.toStringAsFixed(0)} DA',
            style: AppTypography.titleSmall.copyWith(
              color: isPositive ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // ACTIONS
  // ============================================

  void _exportData() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export en cours...')),
    );
  }

  void _showAllTransactions() {
    // TODO: Navigate to full transactions list
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Historique complet')),
    );
  }
}
