import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  Map<String, dynamic> _earnings = {};
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final earnings = await SupabaseService.getEarnings();
      final history = await SupabaseService.getDeliveryHistory();
      setState(() {
        _earnings = earnings;
        _history = history;
      });
    } catch (e) {
      debugPrint('Erreur chargement gains: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes Gains')),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Text('Solde total', style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 8),
                          Text(
                            '${(_earnings['total'] ?? 0).toStringAsFixed(0)} DA',
                            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_earnings['deliveries'] ?? 0} livraisons',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: _buildStatCard('Aujourd\'hui', '${(_earnings['today'] ?? 0).toStringAsFixed(0)} DA', Icons.today)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatCard('Cette semaine', '${(_earnings['week'] ?? 0).toStringAsFixed(0)} DA', Icons.date_range)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text('Historique des livraisons', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (_history.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.history, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text('Aucune livraison', style: TextStyle(color: Colors.grey[600])),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._history.map((order) => _buildTransactionItem(order)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF2E7D32)),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: const Color(0xFF2E7D32).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.delivery_dining, color: Color(0xFF2E7D32)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Commande #${order['order_number'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(order['restaurant']?['name'] ?? '', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                Text(_formatDate(order['delivered_at']), style: TextStyle(color: Colors.grey[400], fontSize: 11)),
              ],
            ),
          ),
          Text('+${(order['delivery_fee'] ?? 0).toStringAsFixed(0)} DA', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.parse(dateStr);
    return '${date.day}/${date.month}/${date.year}';
  }
}
