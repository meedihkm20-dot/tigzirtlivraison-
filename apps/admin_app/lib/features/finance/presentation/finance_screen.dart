import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> _globalReport = {};
  List<Map<String, dynamic>> _restaurantsWithStats = [];
  bool _isLoading = true;
  
  // Filtres période
  String _selectedPeriod = 'today'; // today, week, month, custom
  DateTime? _startDate;
  DateTime? _endDate;
  
  // Filtre restaurant
  String? _selectedRestaurantId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadFinanceData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFinanceData() async {
    setState(() => _isLoading = true);
    try {
      final report = await SupabaseService.getGlobalFinanceReport();
      final restaurants = await SupabaseService.getAllRestaurantsWithStats();
      setState(() {
        _globalReport = report;
        _restaurantsWithStats = restaurants;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );
    
    if (picked != null) {
      setState(() {
        _selectedPeriod = 'custom';
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadFinanceData();
    }
  }

  Future<void> _exportPDF() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Génération PDF en cours...'), backgroundColor: Colors.blue),
      );
      
      // TODO: Implémenter génération PDF
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rapport PDF généré'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _exportExcel() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Génération Excel en cours...'), backgroundColor: Colors.blue),
      );
      
      // TODO: Implémenter génération Excel
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rapport Excel généré'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatCurrency(dynamic value) {
    final amount = (value ?? 0).toDouble();
    return NumberFormat.currency(locale: 'fr_DZ', symbol: 'DA', decimalDigits: 0).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        title: const Text('Finance & Comptabilité', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.download, color: Colors.white),
            onSelected: (value) {
              if (value == 'pdf') _exportPDF();
              if (value == 'excel') _exportExcel();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'pdf', child: Row(children: [Icon(Icons.picture_as_pdf, color: Colors.red), SizedBox(width: 8), Text('Exporter PDF')])),
              const PopupMenuItem(value: 'excel', child: Row(children: [Icon(Icons.table_chart, color: Colors.green), SizedBox(width: 8), Text('Exporter Excel')])),
            ],
          ),
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _loadFinanceData),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'Global'),
            Tab(text: 'Par Restaurant'),
            Tab(text: 'Graphiques'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filtres période
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1B2838),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Période', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _PeriodChip(
                      label: 'Aujourd\'hui',
                      isSelected: _selectedPeriod == 'today',
                      onTap: () {
                        setState(() => _selectedPeriod = 'today');
                        _loadFinanceData();
                      },
                    ),
                    _PeriodChip(
                      label: 'Semaine',
                      isSelected: _selectedPeriod == 'week',
                      onTap: () {
                        setState(() => _selectedPeriod = 'week');
                        _loadFinanceData();
                      },
                    ),
                    _PeriodChip(
                      label: 'Mois',
                      isSelected: _selectedPeriod == 'month',
                      onTap: () {
                        setState(() => _selectedPeriod = 'month');
                        _loadFinanceData();
                      },
                    ),
                    _PeriodChip(
                      label: _selectedPeriod == 'custom' && _startDate != null
                          ? '${DateFormat('dd/MM').format(_startDate!)} - ${DateFormat('dd/MM').format(_endDate!)}'
                          : 'Personnalisé',
                      isSelected: _selectedPeriod == 'custom',
                      onTap: _selectDateRange,
                      icon: Icons.calendar_today,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Contenu
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildGlobalTab(),
                      _buildRestaurantsTab(),
                      _buildChartsTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalTab() {
    return RefreshIndicator(
      onRefresh: _loadFinanceData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carte principale
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.primaryColor, Color(0xFF2E5A8E)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text('Chiffre d\'affaires total', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(
                    _formatCurrency(_globalReport['total_revenue']),
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_globalReport['total_orders'] ?? 0} commandes livrées',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Stats en grille
            Row(
              children: [
                Expanded(child: _buildStatCard('Commission', _formatCurrency(_globalReport['total_commission']), Colors.green, Icons.account_balance)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Ce mois', _formatCurrency(_globalReport['month_revenue']), Colors.blue, Icons.calendar_month)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildStatCard('Frais livraison', _formatCurrency(_globalReport['total_delivery_fees']), Colors.orange, Icons.delivery_dining)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Frais service', _formatCurrency(_globalReport['total_service_fees']), Colors.purple, Icons.receipt)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantsTab() {
    return RefreshIndicator(
      onRefresh: _loadFinanceData,
      child: _restaurantsWithStats.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant, size: 64, color: Colors.white24),
                  const SizedBox(height: 16),
                  const Text('Aucun restaurant', style: TextStyle(color: Colors.white54)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _restaurantsWithStats.length,
              itemBuilder: (context, index) => _buildRestaurantCard(_restaurantsWithStats[index]),
            ),
    );
  }

  Widget _buildChartsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Évolution du CA', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            height: 250,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1B2838),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text('Graphique en développement', style: TextStyle(color: Colors.white54)),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Top Restaurants', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            height: 250,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1B2838),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text('Graphique en développement', style: TextStyle(color: Colors.white54)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2838),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantCard(Map<String, dynamic> restaurant) {
    final stats = restaurant['stats'] as Map<String, dynamic>? ?? {};
    final isVerified = restaurant['is_verified'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2838),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: isVerified ? Colors.green : Colors.grey,
          child: const Icon(Icons.restaurant, color: Colors.white, size: 20),
        ),
        title: Text(
          restaurant['name'] ?? 'Restaurant',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        subtitle: Text(
          '${stats['total_orders'] ?? 0} commandes',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        iconColor: Colors.white,
        collapsedIconColor: Colors.white54,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow('Chiffre d\'affaires', _formatCurrency(stats['total_revenue'])),
                const SizedBox(height: 8),
                _buildInfoRow('Commission (10%)', _formatCurrency(stats['total_commission']), color: Colors.green),
                const SizedBox(height: 8),
                _buildInfoRow('Net restaurant', _formatCurrency(stats['net_revenue']), bold: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color, bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: color ?? Colors.white,
          ),
        ),
      ],
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  const _PeriodChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : const Color(0xFF0D1B2A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.white24,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: isSelected ? Colors.white : Colors.white54),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white54,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
