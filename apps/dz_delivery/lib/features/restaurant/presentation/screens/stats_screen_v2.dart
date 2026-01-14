import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/design_system/theme/app_colors.dart';
import '../../../../core/design_system/theme/app_typography.dart';
import '../../../../core/design_system/theme/app_spacing.dart';
import '../../../../core/design_system/theme/app_shadows.dart';
import '../../../../core/design_system/components/cards/stat_card.dart';
import '../../../../core/services/supabase_service.dart';

/// Écran de statistiques avancées V2
/// Graphiques, tendances, analytics détaillés
class StatsScreenV2 extends StatefulWidget {
  const StatsScreenV2({super.key});

  @override
  State<StatsScreenV2> createState() => _StatsScreenV2State();
}

class _StatsScreenV2State extends State<StatsScreenV2> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String _selectedPeriod = 'week';
  
  Map<String, dynamic> _stats = {};
  List<_DailyData> _dailyData = [];
  List<_TopItem> _topItems = [];
  List<_HourlyData> _hourlyData = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      final stats = await SupabaseService.getRestaurantStats();
      
      // Simuler les données (à remplacer par vraies données)
      final dailyData = [
        _DailyData('Lun', 2500, 8),
        _DailyData('Mar', 3200, 12),
        _DailyData('Mer', 2800, 10),
        _DailyData('Jeu', 4100, 15),
        _DailyData('Ven', 3800, 14),
        _DailyData('Sam', 5200, 18),
        _DailyData('Dim', 6350, 22),
      ];

      final topItems = [
        _TopItem('Pizza Margherita', 45, 4.8, 22500),
        _TopItem('Burger Classic', 38, 4.6, 19000),
        _TopItem('Pâtes Carbonara', 32, 4.7, 16000),
        _TopItem('Salade César', 28, 4.5, 8400),
        _TopItem('Tiramisu', 25, 4.9, 7500),
      ];

      final hourlyData = List.generate(24, (i) {
        final orders = i >= 11 && i <= 14 ? 8 + (i - 11) * 2 
            : i >= 18 && i <= 21 ? 10 + (i - 18) * 3 
            : i >= 8 && i <= 22 ? 3 : 0;
        return _HourlyData(i, orders);
      });

      if (mounted) {
        setState(() {
          _stats = stats;
          _dailyData = dailyData;
          _topItems = topItems;
          _hourlyData = hourlyData;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement stats: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('📊 Statistiques'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textTertiary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Aperçu'),
            Tab(text: 'Ventes'),
            Tab(text: 'Plats'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildSalesTab(),
                _buildItemsTab(),
              ],
            ),
    );
  }


  // ============================================
  // TAB 1: APERÇU GÉNÉRAL
  // ============================================
  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.screen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period selector
            _buildPeriodSelector(),
            AppSpacing.vLg,
            
            // Main stats
            _buildMainStats(),
            AppSpacing.vLg,
            
            // Revenue chart
            _buildRevenueChart(),
            AppSpacing.vLg,
            
            // Performance indicators
            _buildPerformanceIndicators(),
            AppSpacing.vLg,
            
            // Peak hours
            _buildPeakHours(),
            AppSpacing.vXxl,
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppSpacing.borderRadiusRound,
      ),
      child: Row(
        children: [
          _buildPeriodChip('today', 'Aujourd\'hui'),
          _buildPeriodChip('week', 'Semaine'),
          _buildPeriodChip('month', 'Mois'),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String value, String label) {
    final isSelected = _selectedPeriod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedPeriod = value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: AppSpacing.borderRadiusRound,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.labelMedium.copyWith(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainStats() {
    final totalOrders = _stats['total_orders'] ?? 0;
    final totalRevenue = (_stats['total_revenue'] ?? 0).toDouble();
    final avgOrderValue = (_stats['avg_order_value'] ?? 0).toDouble();
    final avgPrepTime = _stats['avg_prep_time'] ?? 30;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Commandes',
                value: '$totalOrders',
                icon: Icons.receipt_long,
                color: AppColors.info,
                trend: '+18%',
                isPositiveTrend: true,
              ),
            ),
            AppSpacing.hMd,
            Expanded(
              child: StatCard(
                title: 'Revenus',
                value: totalRevenue.toStringAsFixed(0),
                unit: 'DA',
                icon: Icons.attach_money,
                color: AppColors.success,
                trend: '+25%',
                isPositiveTrend: true,
              ),
            ),
          ],
        ),
        AppSpacing.vMd,
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Panier moyen',
                value: avgOrderValue.toStringAsFixed(0),
                unit: 'DA',
                icon: Icons.shopping_cart,
                color: AppColors.secondary,
              ),
            ),
            AppSpacing.hMd,
            Expanded(
              child: StatCard(
                title: 'Temps prépa.',
                value: '$avgPrepTime',
                unit: 'min',
                icon: Icons.timer,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRevenueChart() {
    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('📈 Évolution des revenus', style: AppTypography.titleMedium),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.successSurface,
                  borderRadius: AppSpacing.borderRadiusRound,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up, size: 14, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text(
                      '+25%',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.vLg,
          SizedBox(
            height: 200,
            child: _buildLineChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    if (_dailyData.isEmpty) return const SizedBox();
    
    final maxValue = _dailyData.map((d) => d.revenue).reduce((a, b) => a > b ? a : b);
    
    return CustomPaint(
      size: const Size(double.infinity, 200),
      painter: _LineChartPainter(
        data: _dailyData,
        maxValue: maxValue,
        lineColor: AppColors.primary,
        fillColor: AppColors.primarySurface,
      ),
    );
  }

  Widget _buildPerformanceIndicators() {
    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🎯 Performance', style: AppTypography.titleMedium),
          AppSpacing.vMd,
          _buildProgressIndicator(
            label: 'Taux d\'acceptation',
            value: 0.95,
            color: AppColors.success,
            valueText: '95%',
          ),
          AppSpacing.vMd,
          _buildProgressIndicator(
            label: 'Satisfaction client',
            value: 0.88,
            color: AppColors.info,
            valueText: '4.4/5',
          ),
          AppSpacing.vMd,
          _buildProgressIndicator(
            label: 'Temps de préparation',
            value: 0.75,
            color: AppColors.warning,
            valueText: '25 min',
          ),
          AppSpacing.vMd,
          _buildProgressIndicator(
            label: 'Taux de retour',
            value: 0.42,
            color: AppColors.secondary,
            valueText: '42%',
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator({
    required String label,
    required double value,
    required Color color,
    required String valueText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.bodyMedium),
            Text(
              valueText,
              style: AppTypography.labelMedium.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: AppSpacing.borderRadiusRound,
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildPeakHours() {
    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('⏰ Heures de pointe', style: AppTypography.titleMedium),
          AppSpacing.vMd,
          SizedBox(
            height: 100,
            child: _buildHourlyChart(),
          ),
          AppSpacing.vMd,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPeakInfo('🔴 Très demandé', '12h-14h'),
              _buildPeakInfo('🟡 Demandé', '19h-21h'),
              _buildPeakInfo('🟢 Calme', '15h-18h'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyChart() {
    if (_hourlyData.isEmpty) return const SizedBox();
    
    final maxOrders = _hourlyData.map((d) => d.orders).reduce((a, b) => a > b ? a : b);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: _hourlyData.where((d) => d.hour >= 8 && d.hour <= 22).map((data) {
        final height = maxOrders > 0 ? (data.orders / maxOrders) * 80 : 0.0;
        final isPeak = data.orders >= maxOrders * 0.7;
        final isMedium = data.orders >= maxOrders * 0.4 && !isPeak;
        
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: height,
                  decoration: BoxDecoration(
                    color: isPeak ? AppColors.error 
                        : isMedium ? AppColors.warning 
                        : AppColors.success,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                  ),
                ),
                const SizedBox(height: 4),
                if (data.hour % 3 == 0)
                  Text(
                    '${data.hour}h',
                    style: AppTypography.labelSmall.copyWith(
                      fontSize: 8,
                      color: AppColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPeakInfo(String label, String time) {
    return Column(
      children: [
        Text(label, style: AppTypography.labelSmall),
        Text(
          time,
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }


  // ============================================
  // TAB 2: VENTES DÉTAILLÉES
  // ============================================
  Widget _buildSalesTab() {
    return SingleChildScrollView(
      padding: AppSpacing.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Daily breakdown
          _buildDailyBreakdown(),
          AppSpacing.vLg,
          
          // Revenue by category
          _buildRevenueByCategory(),
          AppSpacing.vLg,
          
          // Comparison
          _buildComparison(),
          AppSpacing.vXxl,
        ],
      ),
    );
  }

  Widget _buildDailyBreakdown() {
    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📅 Détail par jour', style: AppTypography.titleMedium),
          AppSpacing.vMd,
          ..._dailyData.map((data) => _buildDayRow(data)),
        ],
      ),
    );
  }

  Widget _buildDayRow(_DailyData data) {
    final maxRevenue = _dailyData.map((d) => d.revenue).reduce((a, b) => a > b ? a : b);
    final percentage = maxRevenue > 0 ? data.revenue / maxRevenue : 0.0;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              data.day,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: AppSpacing.borderRadiusSm,
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  height: 24,
                  width: MediaQuery.of(context).size.width * 0.5 * percentage,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: AppSpacing.borderRadiusSm,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 70,
            child: Text(
              '${data.revenue.toStringAsFixed(0)} DA',
              style: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 30,
            child: Text(
              '${data.orders}',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueByCategory() {
    final categories = [
      _CategoryData('Pizzas', 45, AppColors.primary),
      _CategoryData('Burgers', 25, AppColors.secondary),
      _CategoryData('Pâtes', 15, AppColors.success),
      _CategoryData('Salades', 10, AppColors.info),
      _CategoryData('Desserts', 5, AppColors.warning),
    ];

    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🍕 Revenus par catégorie', style: AppTypography.titleMedium),
          AppSpacing.vMd,
          SizedBox(
            height: 150,
            child: Row(
              children: [
                // Pie chart placeholder
                Expanded(
                  child: CustomPaint(
                    size: const Size(150, 150),
                    painter: _PieChartPainter(categories: categories),
                  ),
                ),
                // Legend
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: categories.map((cat) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: cat.color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${cat.name} (${cat.percentage}%)',
                          style: AppTypography.labelSmall,
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparison() {
    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📊 Comparaison', style: AppTypography.titleMedium),
          AppSpacing.vMd,
          _buildComparisonRow('vs Semaine dernière', '+18%', true),
          _buildComparisonRow('vs Mois dernier', '+25%', true),
          _buildComparisonRow('vs Année dernière', '+42%', true),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(String label, String value, bool isPositive) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodyMedium),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isPositive ? AppColors.successSurface : AppColors.errorSurface,
              borderRadius: AppSpacing.borderRadiusRound,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  size: 16,
                  color: isPositive ? AppColors.success : AppColors.error,
                ),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: AppTypography.labelMedium.copyWith(
                    color: isPositive ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // TAB 3: PLATS POPULAIRES
  // ============================================
  Widget _buildItemsTab() {
    return SingleChildScrollView(
      padding: AppSpacing.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top selling items
          _buildTopSellingItems(),
          AppSpacing.vLg,
          
          // Item performance
          _buildItemPerformance(),
          AppSpacing.vXxl,
        ],
      ),
    );
  }

  Widget _buildTopSellingItems() {
    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('🔥 Top 5 des ventes', style: AppTypography.titleMedium),
              Text(
                'Cette semaine',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          AppSpacing.vMd,
          ..._topItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return _buildTopItemRow(index + 1, item);
          }),
        ],
      ),
    );
  }

  Widget _buildTopItemRow(int rank, _TopItem item) {
    final rankColors = [
      AppColors.warning, // Gold
      AppColors.textTertiary, // Silver
      AppColors.primary.withOpacity(0.7), // Bronze
      AppColors.textTertiary,
      AppColors.textTertiary,
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: rank <= 3 ? rankColors[rank - 1].withOpacity(0.2) : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: AppTypography.labelMedium.copyWith(
                  color: rank <= 3 ? rankColors[rank - 1] : AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Item info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.star, size: 12, color: AppColors.warning),
                    const SizedBox(width: 2),
                    Text(
                      '${item.rating}',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${item.orders} vendus',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Revenue
          Text(
            '${item.revenue.toStringAsFixed(0)} DA',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemPerformance() {
    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📈 Performance des plats', style: AppTypography.titleMedium),
          AppSpacing.vMd,
          _buildPerformanceMetric(
            icon: Icons.trending_up,
            label: 'Plat en hausse',
            value: 'Burger Classic',
            subValue: '+35% cette semaine',
            color: AppColors.success,
          ),
          AppSpacing.vMd,
          _buildPerformanceMetric(
            icon: Icons.trending_down,
            label: 'Plat en baisse',
            value: 'Salade Niçoise',
            subValue: '-12% cette semaine',
            color: AppColors.error,
          ),
          AppSpacing.vMd,
          _buildPerformanceMetric(
            icon: Icons.new_releases,
            label: 'Nouveau populaire',
            value: 'Pizza 4 Fromages',
            subValue: '18 commandes en 3 jours',
            color: AppColors.info,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetric({
    required IconData icon,
    required String label,
    required String value,
    required String subValue,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                Text(
                  value,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subValue,
                  style: AppTypography.labelSmall.copyWith(
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// ============================================
// DATA MODELS
// ============================================
class _DailyData {
  final String day;
  final double revenue;
  final int orders;
  _DailyData(this.day, this.revenue, this.orders);
}

class _TopItem {
  final String name;
  final int orders;
  final double rating;
  final double revenue;
  _TopItem(this.name, this.orders, this.rating, this.revenue);
}

class _HourlyData {
  final int hour;
  final int orders;
  _HourlyData(this.hour, this.orders);
}

class _CategoryData {
  final String name;
  final int percentage;
  final Color color;
  _CategoryData(this.name, this.percentage, this.color);
}

// ============================================
// CUSTOM PAINTERS
// ============================================
class _LineChartPainter extends CustomPainter {
  final List<_DailyData> data;
  final double maxValue;
  final Color lineColor;
  final Color fillColor;

  _LineChartPainter({
    required this.data,
    required this.maxValue,
    required this.lineColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || maxValue == 0) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = fillColor.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final stepX = size.width / (data.length - 1);
    final points = <Offset>[];

    for (var i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - (data[i].revenue / maxValue) * (size.height - 20);
      points.add(Offset(x, y));
    }

    // Draw fill
    fillPath.moveTo(0, size.height);
    for (var point in points) {
      fillPath.lineTo(point.dx, point.dy);
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    // Draw line
    path.moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);

    // Draw points
    final pointPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    for (var point in points) {
      canvas.drawCircle(point, 4, pointPaint);
      canvas.drawCircle(point, 2, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _PieChartPainter extends CustomPainter {
  final List<_CategoryData> categories;

  _PieChartPainter({required this.categories});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    
    var startAngle = -1.5708; // -90 degrees in radians

    for (var category in categories) {
      final sweepAngle = (category.percentage / 100) * 6.2832; // 2 * pi
      
      final paint = Paint()
        ..color = category.color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
    }

    // Draw center circle (donut effect)
    canvas.drawCircle(
      center,
      radius * 0.5,
      Paint()..color = AppColors.surface,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
