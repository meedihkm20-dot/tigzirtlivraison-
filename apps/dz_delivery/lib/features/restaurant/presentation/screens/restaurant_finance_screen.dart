import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../../../core/design_system/theme/app_colors.dart';
import '../../../../core/design_system/theme/app_typography.dart';
import '../../../../core/design_system/theme/app_spacing.dart';
import '../../../../core/design_system/theme/app_shadows.dart';
import '../../../../core/services/supabase_service.dart';

/// Écran Finance Restaurant - COMPLET
/// Revenus, Commission admin, Transactions, Rapports PDF
class RestaurantFinanceScreen extends ConsumerStatefulWidget {
  const RestaurantFinanceScreen({super.key});

  @override
  ConsumerState<RestaurantFinanceScreen> createState() => _RestaurantFinanceScreenState();
}

class _RestaurantFinanceScreenState extends ConsumerState<RestaurantFinanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String _selectedPeriod = 'today'; // 'today', 'week', 'month'
  
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
      // Charger données financières
      final finance = await SupabaseService.getRestaurantFinance(_selectedPeriod);
      final transactions = await SupabaseService.getRestaurantTransactions(_selectedPeriod);
      
      if (mounted) {
        setState(() {
          _financeData = finance;
          _transactions = transactions;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement finance: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('💰 Finance'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _generateFinanceReport,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textTertiary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Tableau de bord'),
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

  // ============================================
  // TAB 1: TABLEAU DE BORD
  // ============================================
  Widget _buildDashboardTab() {
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
            
            // Commission breakdown
            _buildCommissionBreakdown(),
            AppSpacing.vLg,
            
            // Revenue chart
            _buildRevenueChart(),
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
          _buildPeriodChip('week', 'Cette semaine'),
          _buildPeriodChip('month', 'Ce mois'),
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
          _loadData();
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
    final totalRevenue = (_financeData['total_revenue'] ?? 0).toDouble();
    final adminCommission = (_financeData['admin_commission'] ?? 0).toDouble();
    final netEarnings = (_financeData['net_earnings'] ?? 0).toDouble();
    final orderCount = _financeData['order_count'] ?? 0;

    return Column(
      children: [
        // Total revenue
        Container(
          padding: AppSpacing.card,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: AppSpacing.borderRadiusLg,
            boxShadow: AppShadows.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_balance_wallet, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Revenus totaux',
                    style: AppTypography.titleMedium.copyWith(color: Colors.white),
                  ),
                ],
              ),
              AppSpacing.vMd,
              Text(
                '${totalRevenue.toStringAsFixed(0)} DA',
                style: AppTypography.displaySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppSpacing.vSm,
              Text(
                '$orderCount commande${orderCount > 1 ? 's' : ''}',
                style: AppTypography.bodySmall.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
        AppSpacing.vMd,
        
        // Commission & Net
        Row(
          children: [
            Expanded(
              child: Container(
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
                      children: [
                        Icon(Icons.remove_circle, size: 20, color: AppColors.error),
                        const SizedBox(width: 6),
                        Text('Commission', style: AppTypography.labelMedium),
                      ],
                    ),
                    AppSpacing.vSm,
                    Text(
                      '${adminCommission.toStringAsFixed(0)} DA',
                      style: AppTypography.headlineSmall.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${(_financeData['commission_rate'] ?? 10)}%',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.hMd,
            Expanded(
              child: Container(
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
                      children: [
                        Icon(Icons.check_circle, size: 20, color: AppColors.success),
                        const SizedBox(width: 6),
                        Text('Gains nets', style: AppTypography.labelMedium),
                      ],
                    ),
                    AppSpacing.vSm,
                    Text(
                      '${netEarnings.toStringAsFixed(0)} DA',
                      style: AppTypography.headlineSmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Après commission',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCommissionBreakdown() {
    final totalRevenue = (_financeData['total_revenue'] ?? 0).toDouble();
    final adminCommission = (_financeData['admin_commission'] ?? 0).toDouble();
    final netEarnings = (_financeData['net_earnings'] ?? 0).toDouble();
    
    final commissionPercent = totalRevenue > 0 ? (adminCommission / totalRevenue) : 0.0;
    final netPercent = totalRevenue > 0 ? (netEarnings / totalRevenue) : 0.0;

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
          Text('📊 Répartition des revenus', style: AppTypography.titleMedium),
          AppSpacing.vMd,
          
          // Commission bar
          _buildBreakdownRow(
            'Commission admin',
            adminCommission,
            commissionPercent,
            AppColors.error,
          ),
          AppSpacing.vMd,
          
          // Net earnings bar
          _buildBreakdownRow(
            'Vos gains',
            netEarnings,
            netPercent,
            AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, double amount, double percent, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.bodyMedium),
            Text(
              '${amount.toStringAsFixed(0)} DA (${(percent * 100).toStringAsFixed(0)}%)',
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
            value: percent,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueChart() {
    final dailyRevenue = _financeData['daily_revenue'] as List? ?? [];
    
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
          Text('📈 Évolution des revenus', style: AppTypography.titleMedium),
          AppSpacing.vMd,
          SizedBox(
            height: 150,
            child: dailyRevenue.isEmpty
                ? Center(
                    child: Text(
                      'Pas de données',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  )
                : _buildSimpleBarChart(dailyRevenue),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleBarChart(List dailyRevenue) {
    final maxValue = dailyRevenue.fold<double>(
      0,
      (max, item) => (item['revenue'] as num).toDouble() > max ? (item['revenue'] as num).toDouble() : max,
    );
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: dailyRevenue.map((item) {
        final revenue = (item['revenue'] as num).toDouble();
        final height = maxValue > 0 ? (revenue / maxValue) * 130 : 0.0;
        
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (revenue > 0)
                  Text(
                    '${(revenue / 1000).toStringAsFixed(1)}k',
                    style: AppTypography.labelSmall.copyWith(
                      fontSize: 10,
                      color: AppColors.textTertiary,
                    ),
                  ),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  height: height,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ============================================
  // TAB 2: TRANSACTIONS
  // ============================================
  Widget _buildTransactionsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: _transactions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: AppColors.textTertiary),
                  AppSpacing.vMd,
                  Text(
                    'Aucune transaction',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: AppSpacing.screen,
              itemCount: _transactions.length,
              itemBuilder: (context, index) => _buildTransactionCard(_transactions[index]),
            ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final amount = (transaction['amount'] ?? 0).toDouble();
    final commission = (transaction['admin_commission'] ?? 0).toDouble();
    final net = (transaction['net_amount'] ?? 0).toDouble();
    final createdAt = DateTime.tryParse(transaction['created_at'] ?? '') ?? DateTime.now();
    final orderNumber = transaction['order']?['order_number'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        boxShadow: AppShadows.sm,
      ),
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Commande #$orderNumber',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(createdAt),
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
            AppSpacing.vSm,
            Divider(height: 1, color: AppColors.outline),
            AppSpacing.vSm,
            _buildTransactionRow('Montant total', amount, AppColors.textPrimary),
            _buildTransactionRow('Commission admin', -commission, AppColors.error),
            Divider(height: 1, color: AppColors.outline),
            _buildTransactionRow('Gain net', net, AppColors.success, isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionRow(String label, double amount, Color color, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${amount >= 0 ? '+' : ''}${amount.toStringAsFixed(0)} DA',
            style: AppTypography.bodyMedium.copyWith(
              color: color,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // TAB 3: RAPPORTS
  // ============================================
  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: AppSpacing.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📄 Génération de rapports', style: AppTypography.titleMedium),
          AppSpacing.vMd,
          
          _buildReportButton(
            icon: Icons.picture_as_pdf,
            title: 'Rapport financier PDF',
            subtitle: 'Revenus, commissions, transactions',
            color: AppColors.error,
            onTap: _generateFinanceReport,
          ),
          
          _buildReportButton(
            icon: Icons.receipt,
            title: 'Factures',
            subtitle: 'Générer les factures des commandes',
            color: AppColors.info,
            onTap: _generateInvoices,
          ),
          
          _buildReportButton(
            icon: Icons.local_shipping,
            title: 'Bons de livraison',
            subtitle: 'Imprimer les bons de livraison',
            color: AppColors.success,
            onTap: _generateDeliveryNotes,
          ),
          
          _buildReportButton(
            icon: Icons.table_chart,
            title: 'Export Excel',
            subtitle: 'Exporter les données en Excel',
            color: AppColors.secondary,
            onTap: _exportToExcel,
          ),
        ],
      ),
    );
  }

  Widget _buildReportButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        boxShadow: AppShadows.sm,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppSpacing.borderRadiusLg,
          child: Padding(
            padding: AppSpacing.card,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTypography.titleSmall),
                      Text(
                        subtitle,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================
  // PDF GENERATION
  // ============================================
  Future<void> _generateFinanceReport() async {
    try {
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'RAPPORT FINANCIER',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Période: ${_getPeriodLabel()}',
                  style: const pw.TextStyle(fontSize: 14),
                ),
                pw.Text(
                  'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.Divider(),
                pw.SizedBox(height: 20),
                
                // Stats
                pw.Text('RÉSUMÉ', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                _buildPdfRow('Revenus totaux', '${(_financeData['total_revenue'] ?? 0).toStringAsFixed(0)} DA'),
                _buildPdfRow('Commission admin', '${(_financeData['admin_commission'] ?? 0).toStringAsFixed(0)} DA'),
                _buildPdfRow('Gains nets', '${(_financeData['net_earnings'] ?? 0).toStringAsFixed(0)} DA'),
                _buildPdfRow('Nombre de commandes', '${_financeData['order_count'] ?? 0}'),
                
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.SizedBox(height: 20),
                
                // Transactions
                pw.Text('TRANSACTIONS', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                ..._transactions.take(10).map((t) => pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Commande #${t['order']?['order_number'] ?? ''}'),
                      pw.Text('Montant: ${(t['amount'] ?? 0).toStringAsFixed(0)} DA'),
                      pw.Text('Commission: ${(t['admin_commission'] ?? 0).toStringAsFixed(0)} DA'),
                      pw.Text('Net: ${(t['net_amount'] ?? 0).toStringAsFixed(0)} DA'),
                    ],
                  ),
                )),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📄 Rapport généré avec succès'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  pw.Widget _buildPdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label),
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  String _getPeriodLabel() {
    switch (_selectedPeriod) {
      case 'today':
        return 'Aujourd\'hui';
      case 'week':
        return 'Cette semaine';
      case 'month':
        return 'Ce mois';
      default:
        return _selectedPeriod;
    }
  }

  Future<void> _generateInvoices() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🧾 Génération des factures en cours...'),
        backgroundColor: AppColors.info,
      ),
    );
    // TODO: Implémenter génération factures
  }

  Future<void> _generateDeliveryNotes() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📦 Génération des bons de livraison en cours...'),
        backgroundColor: AppColors.success,
      ),
    );
    // TODO: Implémenter génération bons de livraison
  }

  Future<void> _exportToExcel() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📊 Export Excel en cours...'),
        backgroundColor: AppColors.secondary,
      ),
    );
    // TODO: Implémenter export Excel
  }
}
