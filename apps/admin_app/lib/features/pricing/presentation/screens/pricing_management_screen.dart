import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/design_system/theme/app_colors.dart';
import '../../../../core/design_system/theme/app_typography.dart';
import '../../../../core/design_system/theme/app_spacing.dart';
import '../../../../core/services/supabase_service.dart';

/// Écran de gestion du système de pricing dynamique - Admin
class PricingManagementScreen extends ConsumerStatefulWidget {
  const PricingManagementScreen({super.key});

  @override
  ConsumerState<PricingManagementScreen> createState() => _PricingManagementScreenState();
}

class _PricingManagementScreenState extends ConsumerState<PricingManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  
  Map<String, dynamic> _analytics = {};
  List<Map<String, dynamic>> _pricingConfig = [];
  List<Map<String, dynamic>> _deliveryZones = [];
  List<Map<String, dynamic>> _pricingRules = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        _loadPricingAnalytics(),
        _loadPricingConfig(),
        _loadDeliveryZones(),
        _loadPricingRules(),
      ]);
      
      if (mounted) {
        setState(() {
          _analytics = results[0] as Map<String, dynamic>;
          _pricingConfig = results[1] as List<Map<String, dynamic>>;
          _deliveryZones = results[2] as List<Map<String, dynamic>>;
          _pricingRules = results[3] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement pricing: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>> _loadPricingAnalytics() async {
    // Simuler des analytics - À remplacer par vraie API
    return {
      'totalCalculations': 1250,
      'averagePrice': 420,
      'totalRevenue': 525000,
      'averageMultipliers': {
        'zone': 1.15,
        'time': 1.25,
        'weather': 1.10,
        'demand': 1.35,
      },
      'hourlyTrends': List.generate(24, (hour) => {
        'hour': hour,
        'averageDemand': 1.0 + (hour >= 19 && hour <= 23 ? 0.8 : 0.0) + 
                       (hour >= 11 && hour <= 14 ? 0.4 : 0.0),
      }),
      'weeklyTrends': List.generate(7, (day) => {
        'dayOfWeek': day + 1,
        'averageDemand': 1.0 + (day >= 4 ? 0.6 : 0.0), // Weekend plus demandé
      }),
    };
  }

  Future<List<Map<String, dynamic>>> _loadPricingConfig() async {
    final response = await SupabaseService.client
        .from('pricing_config')
        .select('*')
        .order('name');
    return List<Map<String, dynamic>>.from(response.data ?? []);
  }

  Future<List<Map<String, dynamic>>> _loadDeliveryZones() async {
    final response = await SupabaseService.client
        .from('delivery_zones')
        .select('*')
        .order('name');
    return List<Map<String, dynamic>>.from(response.data ?? []);
  }

  Future<List<Map<String, dynamic>>> _loadPricingRules() async {
    final response = await SupabaseService.client
        .from('pricing_rules')
        .select('*')
        .order('priority');
    return List<Map<String, dynamic>>.from(response.data ?? []);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gestion du Pricing'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
            Tab(icon: Icon(Icons.settings), text: 'Configuration'),
            Tab(icon: Icon(Icons.map), text: 'Zones'),
            Tab(icon: Icon(Icons.rule), text: 'Règles'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAnalyticsTab(),
                _buildConfigurationTab(),
                _buildZonesTab(),
                _buildRulesTab(),
              ],
            ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: AppSpacing.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnalyticsCards(),
          const SizedBox(height: 24),
          _buildDemandChart(),
          const SizedBox(height: 24),
          _buildMultipliersChart(),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCards() {
    return Row(
      children: [
        Expanded(child: _buildAnalyticsCard(
          'Calculs Total',
          '${_analytics['totalCalculations'] ?? 0}',
          Icons.calculate,
          AppColors.primary,
        )),
        const SizedBox(width: 12),
        Expanded(child: _buildAnalyticsCard(
          'Prix Moyen',
          '${_analytics['averagePrice'] ?? 0} DA',
          Icons.attach_money,
          AppColors.success,
        )),
        const SizedBox(width: 12),
        Expanded(child: _buildAnalyticsCard(
          'Revenus Total',
          '${(_analytics['totalRevenue'] ?? 0) ~/ 1000}k DA',
          Icons.trending_up,
          AppColors.warning,
        )),
      ],
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemandChart() {
    final hourlyData = _analytics['hourlyTrends'] as List? ?? [];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Demande par Heure', style: AppTypography.titleMedium),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 40),
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
                    spots: hourlyData.map<FlSpot>((data) => FlSpot(
                      (data['hour'] as int).toDouble(),
                      (data['averageDemand'] as double),
                    )).toList(),
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultipliersChart() {
    final multipliers = _analytics['averageMultipliers'] as Map? ?? {};
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Multiplicateurs Moyens', style: AppTypography.titleMedium),
          const SizedBox(height: 16),
          ...multipliers.entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    entry.key,
                    style: AppTypography.bodyMedium,
                  ),
                ),
                Expanded(
                  child: LinearProgressIndicator(
                    value: (entry.value as double - 1.0).clamp(0.0, 1.0),
                    backgroundColor: AppColors.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'x${(entry.value as double).toStringAsFixed(2)}',
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildConfigurationTab() {
    return ListView(
      padding: AppSpacing.screen,
      children: [
        Text('Configuration des Prix', style: AppTypography.titleLarge),
        const SizedBox(height: 16),
        ..._pricingConfig.map((config) => _buildConfigItem(config)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _addNewConfig,
          icon: const Icon(Icons.add),
          label: const Text('Ajouter Configuration'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildConfigItem(Map<String, dynamic> config) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(config['name'] ?? ''),
        subtitle: Text(config['description'] ?? ''),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${config['value']} DA',
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editConfig(config),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZonesTab() {
    return ListView(
      padding: AppSpacing.screen,
      children: [
        Text('Zones de Livraison', style: AppTypography.titleLarge),
        const SizedBox(height: 16),
        ..._deliveryZones.map((zone) => _buildZoneItem(zone)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _addNewZone,
          icon: const Icon(Icons.add_location),
          label: const Text('Ajouter Zone'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildZoneItem(Map<String, dynamic> zone) {
    final multiplier = (zone['multiplier'] as num?)?.toDouble() ?? 1.0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getZoneColor(multiplier).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.location_on,
            color: _getZoneColor(multiplier),
          ),
        ),
        title: Text(zone['name'] ?? ''),
        subtitle: Text(zone['description'] ?? ''),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'x${multiplier.toStringAsFixed(2)}',
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: _getZoneColor(multiplier),
              ),
            ),
            Text(
              _getZoneLabel(multiplier),
              style: AppTypography.labelSmall,
            ),
          ],
        ),
        onTap: () => _editZone(zone),
      ),
    );
  }

  Color _getZoneColor(double multiplier) {
    if (multiplier >= 1.5) return AppColors.error;
    if (multiplier >= 1.3) return AppColors.warning;
    if (multiplier >= 1.1) return AppColors.info;
    return AppColors.success;
  }

  String _getZoneLabel(double multiplier) {
    if (multiplier >= 1.5) return 'Très cher';
    if (multiplier >= 1.3) return 'Cher';
    if (multiplier >= 1.1) return 'Modéré';
    return 'Standard';
  }

  Widget _buildRulesTab() {
    return ListView(
      padding: AppSpacing.screen,
      children: [
        Text('Règles de Pricing', style: AppTypography.titleLarge),
        const SizedBox(height: 16),
        ..._pricingRules.map((rule) => _buildRuleItem(rule)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _addNewRule,
          icon: const Icon(Icons.add_rule),
          label: const Text('Ajouter Règle'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildRuleItem(Map<String, dynamic> rule) {
    final multiplier = (rule['multiplier'] as num?)?.toDouble() ?? 1.0;
    final ruleType = rule['rule_type'] ?? '';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getRuleTypeColor(ruleType).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getRuleTypeIcon(ruleType),
            color: _getRuleTypeColor(ruleType),
          ),
        ),
        title: Text(rule['name'] ?? ''),
        subtitle: Text('Type: $ruleType • Priorité: ${rule['priority'] ?? 0}'),
        trailing: Text(
          'x${multiplier.toStringAsFixed(2)}',
          style: AppTypography.titleSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Condition: ${rule['condition_key'] ?? ''} ${rule['condition_operator'] ?? ''} ${rule['condition_value'] ?? ''}'),
                const SizedBox(height: 8),
                Text('Multiplicateur: x${multiplier.toStringAsFixed(2)}'),
                if (rule['bonus_amount'] != null && rule['bonus_amount'] > 0)
                  Text('Bonus: +${rule['bonus_amount']} DA'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => _editRule(rule),
                      child: const Text('Modifier'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => _toggleRule(rule),
                      child: Text(rule['is_active'] == true ? 'Désactiver' : 'Activer'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRuleTypeColor(String ruleType) {
    switch (ruleType) {
      case 'time': return AppColors.info;
      case 'weather': return AppColors.warning;
      case 'demand': return AppColors.error;
      case 'zone': return AppColors.success;
      default: return AppColors.textSecondary;
    }
  }

  IconData _getRuleTypeIcon(String ruleType) {
    switch (ruleType) {
      case 'time': return Icons.access_time;
      case 'weather': return Icons.cloud;
      case 'demand': return Icons.trending_up;
      case 'zone': return Icons.location_on;
      default: return Icons.rule;
    }
  }

  // Actions
  void _addNewConfig() {
    // TODO: Implémenter l'ajout de configuration
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonctionnalité en développement')),
    );
  }

  void _editConfig(Map<String, dynamic> config) {
    // TODO: Implémenter l'édition de configuration
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Édition de ${config['name']}')),
    );
  }

  void _addNewZone() {
    // TODO: Implémenter l'ajout de zone
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonctionnalité en développement')),
    );
  }

  void _editZone(Map<String, dynamic> zone) {
    // TODO: Implémenter l'édition de zone
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Édition de ${zone['name']}')),
    );
  }

  void _addNewRule() {
    // TODO: Implémenter l'ajout de règle
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonctionnalité en développement')),
    );
  }

  void _editRule(Map<String, dynamic> rule) {
    // TODO: Implémenter l'édition de règle
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Édition de ${rule['name']}')),
    );
  }

  void _toggleRule(Map<String, dynamic> rule) {
    // TODO: Implémenter l'activation/désactivation de règle
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Règle ${rule['name']} ${rule['is_active'] ? 'désactivée' : 'activée'}')),
    );
  }
}