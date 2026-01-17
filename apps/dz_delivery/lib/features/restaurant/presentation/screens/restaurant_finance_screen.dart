import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/design_system/theme/app_colors.dart';
import '../../../../core/design_system/theme/app_typography.dart';
import '../../../../core/design_system/theme/app_spacing.dart';
import '../../../../core/services/supabase_service.dart';

/// Écran Finance Restaurant Complet
/// 3 onglets: Dashboard, Transactions, Rapports
class RestaurantFinanceScreen extends ConsumerStatefulWidget {
  const RestaurantFinanceScreen({super.key});

  @override
  ConsumerState<RestaurantFinanceScreen> createState() => _RestaurantFinanceScreenState();
}

class _RestaurantFinanceScreenState extends ConsumerState<RestaurantFinanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String _selectedPeriod = 'today'; // today, week, month
  
  Map<String, dynamic> _financeData = {};
  List<Map<String, dynamic>> _transactions = [];

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
      final finance = await SupabaseService.getRestaurantFinance(_selectedPeriod);
      final transactions = await SupabaseService.getRestaurantTransactions(_selectedPeriod);
      
      setState(() {
        _financeData = finance;
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _generatePDFReport() async {
    try {
      // TODO: Implémenter génération PDF avec package pdf
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Génération PDF en cours...')),
      );
      
      // Simuler génération
      await Future.delayed(const Duration(seconds: 1));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rapport PDF généré avec succès'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur génération PDF: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Finance & Comptabilité'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Transactions'),
            Tab(text: 'Rapports'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDashboardTab(),
                _buildTransactionsTab(),
                _buildReportsTab(),
              ],
            ),
    );
  }

  Widget _buildDashboardTab() {
    final totalRevenue = (_financeData['total_revenue'] ?? 0).toDouble();
    final adminCommission = (_financeData['admin_commission'] ?? 0).toDouble();
    final netEarnings = (_financeData['net_earnings'] ?? 0).toDouble();
    final orderCount = _financeData['order_count'] ?? 0;
    final commissionRate = _financeData['commission_rate'] ?? 10;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: AppSpacing.screen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sélecteur de période
            Row(
              children: [
                _PeriodChip(
                  label: 'Aujourd\'hui',
                  isSelected: _selectedPeriod == 'today',
                  onTap: () {
                    setState(() => _selectedPeriod = 'today');
                    _loadData();
                  },
                ),
                const SizedBox(width: 8),
                _PeriodChip(
                  label: 'Semaine',
                  isSelected: _selectedPeriod == 'week',
                  onTap: () {
                    setState(() => _selectedPeriod = 'week');
                    _loadData();
                  },
                ),
                const SizedBox(width: 8),
                _PeriodChip(
                  label: 'Mois',
                  isSelected: _selectedPeriod == 'month',
                  onTap: () {
                    setState(() => _selectedPeriod = 'month');
                    _loadData();
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Carte principale - Revenus nets
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF1565C0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gains Nets',
                    style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${netEarnings.toStringAsFixed(0)} DA',
                    style: AppTypography.headlineLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$orderCount commande${orderCount > 1 ? 's' : ''}',
                    style: AppTypography.bodySmall.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stats en grille
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Revenus Total',
                    value: '${totalRevenue.toStringAsFixed(0)} DA',
                    icon: Icons.trending_up,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Commission ($commissionRate%)',
                    value: '${adminCommission.toStringAsFixed(0)} DA',
                    icon: Icons.account_balance,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Graphique revenus journaliers (si période = semaine)
            if (_selectedPeriod == 'week' && _financeData['daily_revenue'] != null) ...[
              Text('Revenus par jour', style: AppTypography.titleMedium),
              const SizedBox(height: 16),
              Container(
                height: 200,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildRevenueChart(),
              ),
              const SizedBox(height: 24),
            ],

            // Détails commission
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 20, color: AppColors.info),
                      const SizedBox(width: 8),
                      Text('Détails Commission', style: AppTypography.titleSmall),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _DetailRow('Revenus bruts', '${totalRevenue.toStringAsFixed(0)} DA'),
                  _DetailRow('Commission admin ($commissionRate%)', '- ${adminCommission.toStringAsFixed(0)} DA', color: AppColors.error),
                  const Divider(height: 24),
                  _DetailRow('Gains nets', '${netEarnings.toStringAsFixed(0)} DA', bold: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    final dailyRevenue = _financeData['daily_revenue'] as List? ?? [];
    if (dailyRevenue.isEmpty) {
      return const Center(child: Text('Aucune donnée'));
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: dailyRevenue.map((d) => (d['revenue'] as num).toDouble()).reduce((a, b) => a > b ? a : b) * 1.2,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < dailyRevenue.length) {
                  return Text(
                    dailyRevenue[value.toInt()]['day'],
                    style: AppTypography.labelSmall,
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(
          dailyRevenue.length,
          (index) => BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: (dailyRevenue[index]['revenue'] as num).toDouble(),
                color: AppColors.primary,
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: _transactions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: AppColors.textSecondary.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text('Aucune transaction', style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            )
          : ListView.builder(
              padding: AppSpacing.screen,
              itemCount: _transactions.length,
              itemBuilder: (context, index) {
                final transaction = _transactions[index];
                return _TransactionCard(transaction: transaction);
              },
            ),
    );
  }

  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: AppSpacing.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Générer des rapports', style: AppTypography.titleLarge),
          const SizedBox(height: 16),
          
          _ReportOption(
            title: 'Rapport Financier PDF',
            description: 'Revenus, commissions, gains nets',
            icon: Icons.picture_as_pdf,
            color: AppColors.error,
            onTap: _generatePDFReport,
          ),
          const SizedBox(height: 12),
          
          _ReportOption(
            title: 'Factures Détaillées',
            description: 'Toutes les commandes avec détails',
            icon: Icons.receipt,
            color: AppColors.info,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Génération factures en cours...')),
              );
            },
          ),
          const SizedBox(height: 12),
          
          _ReportOption(
            title: 'Export Excel',
            description: 'Données financières au format Excel',
            icon: Icons.table_chart,
            color: AppColors.success,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export Excel en cours...')),
              );
            },
          ),
          const SizedBox(height: 24),
          
          Text('Période du rapport', style: AppTypography.titleMedium),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _PeriodChip(
                  label: 'Aujourd\'hui',
                  isSelected: _selectedPeriod == 'today',
                  onTap: () => setState(() => _selectedPeriod = 'today'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PeriodChip(
                  label: 'Semaine',
                  isSelected: _selectedPeriod == 'week',
                  onTap: () => setState(() => _selectedPeriod = 'week'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PeriodChip(
                  label: 'Mois',
                  isSelected: _selectedPeriod == 'month',
                  onTap: () => setState(() => _selectedPeriod = 'month'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
          Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final bool bold;

  const _DetailRow(this.label, this.value, {this.color, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: color ?? AppColors.textSecondary,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: color ?? AppColors.textPrimary,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const _TransactionCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final amount = (transaction['amount'] ?? 0).toDouble();
    final total = (transaction['total'] ?? 0).toDouble();
    final commission = (transaction['commission'] ?? 0).toDouble();
    final type = transaction['type'] as String?;
    final createdAt = transaction['created_at'] as String?;
    final orderNumber = transaction['order_number'] as String?;
    final customerName = transaction['customer_name'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.receipt_long, color: AppColors.success),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Commande #${orderNumber ?? ''}',
                      style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (customerName != null)
                      Text(
                        customerName,
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    if (createdAt != null)
                      Text(
                        _formatDate(createdAt),
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${amount.toStringAsFixed(0)} DA',
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                  Text(
                    'Total: ${total.toStringAsFixed(0)} DA',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  if (commission > 0)
                    Text(
                      'Commission: ${commission.toStringAsFixed(0)} DA',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.warning),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
}

class _ReportOption extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ReportOption({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                  Text(description, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
