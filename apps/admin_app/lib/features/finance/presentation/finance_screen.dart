import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  Map<String, dynamic> _globalReport = {};
  List<Map<String, dynamic>> _restaurantsWithStats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFinanceData();
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
    }
  }

  String _formatCurrency(dynamic value) {
    final amount = (value ?? 0).toDouble();
    return NumberFormat.currency(locale: 'fr_DZ', symbol: 'DA', decimalDigits: 0).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance & Comptabilité'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadFinanceData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadFinanceData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Rapport global
                    const Text('Rapport Global', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppTheme.primaryColor, Color(0xFF2E5A8E)]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          const Text('Chiffre d\'affaires total', style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 8),
                          Text(_formatCurrency(_globalReport['total_revenue']), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 8),
                          Text('${_globalReport['total_orders'] ?? 0} commandes livrées', style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard('Commission (10%)', _formatCurrency(_globalReport['total_commission']), Colors.green),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard('Ce mois', _formatCurrency(_globalReport['month_revenue']), Colors.blue),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard('Frais livraison', _formatCurrency(_globalReport['total_delivery_fees']), Colors.orange),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard('Frais service', _formatCurrency(_globalReport['total_service_fees']), Colors.purple),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Par restaurant
                    const Text('Par Restaurant', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    if (_restaurantsWithStats.isEmpty)
                      Center(child: Text('Aucun restaurant', style: TextStyle(color: Colors.grey[600])))
                    else
                      ..._restaurantsWithStats.map((restaurant) => _buildRestaurantCard(restaurant)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildRestaurantCard(Map<String, dynamic> restaurant) {
    final stats = restaurant['stats'] as Map<String, dynamic>? ?? {};
    final isVerified = restaurant['is_verified'] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: isVerified ? AppTheme.successColor : Colors.grey,
          child: const Icon(Icons.restaurant, color: Colors.white),
        ),
        title: Text(restaurant['name'] ?? 'Restaurant', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${stats['total_orders'] ?? 0} commandes', style: TextStyle(color: Colors.grey[600])),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Chiffre d\'affaires'),
                    Text(_formatCurrency(stats['total_revenue']), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Commission (10%)'),
                    Text(_formatCurrency(stats['total_commission']), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.successColor)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Net restaurant'),
                    Text(_formatCurrency(stats['net_revenue']), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
