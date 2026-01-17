import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/design_system/theme/app_colors.dart';
import '../../../../core/design_system/theme/app_typography.dart';
import '../../../../core/design_system/theme/app_spacing.dart';
import '../../../../core/design_system/theme/app_shadows.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/delivery_pricing_service.dart';

/// Dashboard Gains Livreur V2 - Avec pricing dynamique et prédictions
class EarningsDashboardScreenV2 extends ConsumerStatefulWidget {
  const EarningsDashboardScreenV2({super.key});

  @override
  ConsumerState<EarningsDashboardScreenV2> createState() => _EarningsDashboardScreenV2State();
}

class _EarningsDashboardScreenV2State extends ConsumerState<EarningsDashboardScreenV2>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  
  Map<String, dynamic> _todayStats = {};
  Map<String, dynamic> _weekStats = {};
  List<Map<String, dynamic>> _recentCalculations = [];
  List<Map<String, dynamic>> _hourlyPredictions = [];
  Map<String, dynamic> _currentOpportunities = {};

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
      final results = await Future.wait([
        _loadTodayStats(),
        _loadWeekStats(),
        _loadRecentCalculations(),
        _loadHourlyPredictions(),
        _loadCurrentOpportunities(),
      ]);
      
      if (mounted) {
        setState(() {
          _todayStats = results[0] as Map<String, dynamic>;
          _weekStats = results[1] as Map<String, dynamic>;
          _recentCalculations = results[2] as List<Map<String, dynamic>>;
          _hourlyPredictions = results[3] as List<Map<String, dynamic>>;
          _currentOpportunities = results[4] as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement earnings: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>> _loadTodayStats() async {
    // Utiliser le service existant + nouvelles données pricing
    final baseStats = await SupabaseService.getLivreurTodayStats();
    
    // Ajouter les données de pricing
    final pricingStats = await _loadPricingStats('today');
    
    return {
      ...baseStats,
      'averagePrice': pricingStats['averagePrice'] ?? 0,
      'bestPrice': pricingStats['bestPrice'] ?? 0,
      'totalBonuses': pricingStats['totalBonuses'] ?? 0,
      'nightDeliveries': pricingStats['nightDeliveries'] ?? 0,
      'weatherDeliveries': pricingStats['weatherDeliveries'] ?? 0,
    };
  }

  Future<Map<String, dynamic>> _loadWeekStats() async {
    final baseStats = await SupabaseService.getLivreurWeekStats();
    final pricingStats = await _loadPricingStats('week');
    
    return {
      ...baseStats,
      'averagePrice': pricingStats['averagePrice'] ?? 0,
      'bestDay': pricingStats['bestDay'] ?? 'Lundi',
      'peakHours': pricingStats['peakHours'] ?? [],
    };
  }

  Future<Map<String, dynamic>> _loadPricingStats(String period) async {
    // Simuler les stats de pricing - À remplacer par vraie API
    return {
      'averagePrice': 420,
      'bestPrice': 680,
      'totalBonuses': 150,
      'nightDeliveries': 3,
      'weatherDeliveries': 2,
      'bestDay': 'Vendredi',
      'peakHours': ['19h-21h', '12h-14h'],
    };
  }

  Future<List<Map<String, dynamic>>> _loadRecentCalculations() async {
    // Simuler l'historique des calculs de prix
    return List.generate(10, (index) => {
      'id': 'calc_$index',
      'orderId': 'order_$index',
      'finalPrice': 300 + (index * 20) + (index % 3 * 50),
      'basePrice': 250 + (index * 15),
      'multipliers': {
        'zone': 1.0 + (index % 4 * 0.1),
        'time': 1.0 + (index % 3 * 0.2),
        'weather': 1.0 + (index % 2 * 0.3),
        'demand': 1.0 + (index % 5 * 0.15),
      },
      'bonuses': {
        'nightSafety': index % 3 == 0 ? 50 : 0,
        'equipment': index % 4 == 0 ? 30 : 0,
      },
      'distance': 2.5 + (index * 0.8),
      'createdAt': DateTime.now().subtract(Duration(hours: index)),
      'warnings': index % 3 == 0 ? ['Livraison nocturne'] : [],
    });
  }

  Future<List<Map<String, dynamic>>> _loadHourlyPredictions() async {
    // Prédictions des gains par heure pour aujourd'hui
    final now = DateTime.now();
    return List.generate(24, (hour) {
      final demand = _calculateHourlyDemand(hour);
      final baseEarnings = 300;
      final predictedEarnings = (baseEarnings * demand).round();
      
      return {
        'hour': hour,
        'predictedEarnings': predictedEarnings,
        'demand': demand,
        'confidence': demand > 1.2 ? 'high' : demand > 0.8 ? 'medium' : 'low',
        'isPeak': hour >= 11 && hour <= 14 || hour >= 19 && hour <= 22,
        'isNight': hour >= 20 || hour <= 6,
      };
    });
  }

  double _calculateHourlyDemand(int hour) {
    // Simulation de la demande selon l'heure
    if (hour >= 11 && hour <= 14) return 1.4; // Déjeuner
    if (hour >= 19 && hour <= 22) return 1.6; // Dîner
    if (hour >= 20 || hour <= 6) return 1.2;  // Nuit
    return 0.8; // Heures creuses
  }

  Future<Map<String, dynamic>> _loadCurrentOpportunities() async {
    final currentHour = DateTime.now().hour;
    final demand = _calculateHourlyDemand(currentHour);
    
    return {
      'currentDemand': demand,
      'availableOrders': 8,
      'averagePrice': 450,
      'peakMultiplier': 1.5,
      'weatherBonus': 30,
      'nightBonus': currentHour >= 20 || currentHour <= 6 ? 50 : 0,
      'recommendations': _generateRecommendations(currentHour, demand),
    };
  }

  List<String> _generateRecommendations(int hour, double demand) {
    List<String> recommendations = [];
    
    if (demand > 1.5) {
      recommendations.add('🔥 Forte demande - Gains élevés possibles');
    }
    
    if (hour >= 19 && hour <= 22) {
      recommendations.add('🌙 Créneau premium - Majoration nocturne active');
    }
    
    if (hour >= 11 && hour <= 14) {
      recommendations.add('🍽️ Rush déjeuner - Opportunités multiples');
    }
    
    // Simulation météo
    if (DateTime.now().hour % 3 == 0) {
      recommendations.add('🌧️ Pluie prévue - Bonus météo disponible');
    }
    
    return recommendations;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dashboard Gains'),
        backgroundColor: AppColors.livreurPrimary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.today), text: 'Aujourd\'hui'),
            Tab(icon: Icon(Icons.analytics), text: 'Tendances'),
            Tab(icon: Icon(Icons.lightbulb), text: 'Opportunités'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.livreurPrimary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTodayTab(),
                _buildTrendsTab(),
                _buildOpportunitiesTab(),
              ],
            ),
    );
  }

  Widget _buildTodayTab() {
    return SingleChildScrollView(
      padding: AppSpacing.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTodayStatsCards(),
          const SizedBox(height: 24),
          _buildRecentCalculations(),
          const SizedBox(height: 24),
          _buildPricingBreakdown(),
        ],
      ),
    );
  }

  Widget _buildTodayStatsCards() {
    final deliveries = _todayStats['deliveries'] ?? 0;
    final earnings = (_todayStats['earnings'] as num?)?.toDouble() ?? 0;
    final averagePrice = (_todayStats['averagePrice'] as num?)?.toDouble() ?? 0;
    final totalBonuses = (_todayStats['totalBonuses'] as num?)?.toDouble() ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Performance Aujourd\'hui', style: AppTypography.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard(
              '🚚', '$deliveries', 'Livraisons', AppColors.livreurPrimary
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard(
              '💰', '${earnings.toStringAsFixed(0)} DA', 'Gains Total', AppColors.success
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard(
              '📊', '${averagePrice.toStringAsFixed(0)} DA', 'Prix Moyen', AppColors.info
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard(
              '🎁', '+${totalBonuses.toStringAsFixed(0)} DA', 'Bonus Total', AppColors.warning
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String emoji, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusMd,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentCalculations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Calculs Récents', style: AppTypography.titleMedium),
            TextButton(
              onPressed: () {}, // TODO: Voir tout l'historique
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._recentCalculations.take(5).map((calc) => _buildCalculationItem(calc)),
      ],
    );
  }

  Widget _buildCalculationItem(Map<String, dynamic> calc) {
    final finalPrice = (calc['finalPrice'] as num).toDouble();
    final basePrice = (calc['basePrice'] as num).toDouble();
    final distance = (calc['distance'] as num).toDouble();
    final warnings = calc['warnings'] as List;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusSm,
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.livreurSurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${finalPrice.toStringAsFixed(0)}',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.livreurPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${finalPrice.toStringAsFixed(0)} DA',
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (finalPrice > basePrice)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.successSurface,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '+${((finalPrice - basePrice) / basePrice * 100).toStringAsFixed(0)}%',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  '${distance.toStringAsFixed(1)} km • Base: ${basePrice.toStringAsFixed(0)} DA',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                ),
                if (warnings.isNotEmpty)
                  Text(
                    warnings.first,
                    style: AppTypography.labelSmall.copyWith(color: AppColors.warning),
                  ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.textTertiary),
        ],
      ),
    );
  }

  Widget _buildPricingBreakdown() {
    // Analyse des multiplicateurs moyens d'aujourd'hui
    final avgMultipliers = {
      'Zone': 1.15,
      'Heure': 1.25,
      'Météo': 1.10,
      'Demande': 1.35,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusMd,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Analyse des Prix', style: AppTypography.titleMedium),
          const SizedBox(height: 16),
          ...avgMultipliers.entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(entry.key, style: AppTypography.bodyMedium),
                ),
                Expanded(
                  child: LinearProgressIndicator(
                    value: (entry.value - 1.0).clamp(0.0, 1.0),
                    backgroundColor: AppColors.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation(_getMultiplierColor(entry.value)),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'x${entry.value.toStringAsFixed(2)}',
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getMultiplierColor(entry.value),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Color _getMultiplierColor(double multiplier) {
    if (multiplier >= 1.4) return AppColors.success;
    if (multiplier >= 1.2) return AppColors.warning;
    if (multiplier >= 1.1) return AppColors.info;
    return AppColors.textSecondary;
  }

  Widget _buildTrendsTab() {
    return SingleChildScrollView(
      padding: AppSpacing.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHourlyPredictionsChart(),
          const SizedBox(height: 24),
          _buildWeeklyTrends(),
          const SizedBox(height: 24),
          _buildBestPerformanceTips(),
        ],
      ),
    );
  }

  Widget _buildHourlyPredictionsChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusMd,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Prédictions Gains par Heure', style: AppTypography.titleMedium),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 50),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text('${value.toInt()}h');
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: _hourlyPredictions.map<FlSpot>((data) => FlSpot(
                      (data['hour'] as int).toDouble(),
                      (data['predictedEarnings'] as int).toDouble(),
                    )).toList(),
                    isCurved: true,
                    color: AppColors.livreurPrimary,
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.livreurPrimary.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyTrends() {
    final weekDays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    final weeklyEarnings = [2400, 2100, 2300, 2800, 3200, 3500, 2900];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusMd,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tendances Hebdomadaires', style: AppTypography.titleMedium),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 4000,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(weekDays[value.toInt()]);
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 50),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: weeklyEarnings.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.toDouble(),
                        color: AppColors.livreurPrimary,
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBestPerformanceTips() {
    final tips = [
      {
        'icon': Icons.access_time,
        'title': 'Créneaux Optimaux',
        'description': '19h-22h et 12h-14h sont les plus rentables',
        'color': AppColors.info,
      },
      {
        'icon': Icons.cloud,
        'title': 'Bonus Météo',
        'description': 'Activez-vous par mauvais temps pour +30% de gains',
        'color': AppColors.warning,
      },
      {
        'icon': Icons.location_on,
        'title': 'Zones Premium',
        'description': 'Centre-ville et zones universitaires paient mieux',
        'color': AppColors.success,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Conseils Performance', style: AppTypography.titleMedium),
        const SizedBox(height: 12),
        ...tips.map((tip) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppSpacing.borderRadiusSm,
            border: Border.all(color: AppColors.outline),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (tip['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  tip['icon'] as IconData,
                  color: tip['color'] as Color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tip['title'] as String,
                      style: AppTypography.titleSmall,
                    ),
                    Text(
                      tip['description'] as String,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildOpportunitiesTab() {
    return SingleChildScrollView(
      padding: AppSpacing.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCurrentOpportunityCard(),
          const SizedBox(height: 24),
          _buildRecommendations(),
          const SizedBox(height: 24),
          _buildDemandMap(),
        ],
      ),
    );
  }

  Widget _buildCurrentOpportunityCard() {
    final currentDemand = (_currentOpportunities['currentDemand'] as num?)?.toDouble() ?? 1.0;
    final availableOrders = _currentOpportunities['availableOrders'] ?? 0;
    final averagePrice = (_currentOpportunities['averagePrice'] as num?)?.toDouble() ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.livreurGradient,
        borderRadius: AppSpacing.borderRadiusLg,
        boxShadow: AppShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flash_on, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Text(
                'Opportunité Actuelle',
                style: AppTypography.titleLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$availableOrders commandes',
                      style: AppTypography.headlineSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'disponibles maintenant',
                      style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${averagePrice.toStringAsFixed(0)} DA moy.',
                  style: AppTypography.titleSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (currentDemand - 1.0).clamp(0.0, 1.0),
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation(Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Demande: ${_getDemandLabel(currentDemand)}',
            style: AppTypography.bodyMedium.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }

  String _getDemandLabel(double demand) {
    if (demand >= 1.8) return 'Très élevée 🔥';
    if (demand >= 1.4) return 'Élevée 📈';
    if (demand >= 1.1) return 'Modérée 📊';
    return 'Normale 📉';
  }

  Widget _buildRecommendations() {
    final recommendations = _currentOpportunities['recommendations'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recommandations', style: AppTypography.titleMedium),
        const SizedBox(height: 12),
        if (recommendations.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppSpacing.borderRadiusMd,
            ),
            child: Center(
              child: Text(
                'Aucune recommandation spéciale pour le moment',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
              ),
            ),
          )
        else
          ...recommendations.map((rec) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppSpacing.borderRadiusSm,
              border: Border.all(color: AppColors.outline),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    rec as String,
                    style: AppTypography.bodyMedium,
                  ),
                ),
              ],
            ),
          )),
      ],
    );
  }

  Widget _buildDemandMap() {
    // Simulation d'une carte de demande par zone
    final zones = [
      {'name': 'Centre-ville', 'demand': 1.6, 'orders': 12},
      {'name': 'Cité Universitaire', 'demand': 1.8, 'orders': 8},
      {'name': 'Nouvelle Ville', 'demand': 1.2, 'orders': 5},
      {'name': 'Périphérie', 'demand': 0.9, 'orders': 3},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Demande par Zone', style: AppTypography.titleMedium),
        const SizedBox(height: 12),
        ...zones.map((zone) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppSpacing.borderRadiusSm,
            border: Border.all(color: AppColors.outline),
          ),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getDemandColor(zone['demand'] as double),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  zone['name'] as String,
                  style: AppTypography.bodyMedium,
                ),
              ),
              Text(
                '${zone['orders']} commandes',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getDemandColor(zone['demand'] as double).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'x${(zone['demand'] as double).toStringAsFixed(1)}',
                  style: AppTypography.labelSmall.copyWith(
                    color: _getDemandColor(zone['demand'] as double),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Color _getDemandColor(double demand) {
    if (demand >= 1.6) return AppColors.error;
    if (demand >= 1.3) return AppColors.warning;
    if (demand >= 1.1) return AppColors.success;
    return AppColors.textTertiary;
  }
}