import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';

/// Écran de monitoring temps réel pour gérer les crises
class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({super.key});

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  List<Map<String, dynamic>> _stuckOrders = [];
  List<Map<String, dynamic>> _inactiveLivreurs = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Rafraîchir toutes les 30 secondes
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadData());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final stuck = await SupabaseService.getStuckOrders();
      final inactive = await SupabaseService.getInactiveLivreurs();
      
      if (mounted) {
        setState(() {
          _stuckOrders = stuck;
          _inactiveLivreurs = inactive;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🚨 Monitoring Temps Réel'),
        backgroundColor: Colors.red.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Alertes
                  if (_stuckOrders.isNotEmpty || _inactiveLivreurs.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(
                            '${_stuckOrders.length} commande(s) bloquée(s), ${_inactiveLivreurs.length} livreur(s) inactif(s)',
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  
                  // Commandes bloquées
                  const Text('Commandes bloquées (> 1h)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (_stuckOrders.isEmpty)
                    const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('✅ Aucune commande bloquée')))
                  else
                    ..._stuckOrders.map((order) => _buildStuckOrderCard(order)),
                  
                  const SizedBox(height: 24),
                  
                  // Livreurs inactifs
                  const Text('Livreurs inactifs (occupés > 30min)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (_inactiveLivreurs.isEmpty)
                    const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('✅ Tous les livreurs sont actifs')))
                  else
                    ..._inactiveLivreurs.map((livreur) => _buildInactiveLivreurCard(livreur)),
                ],
              ),
            ),
    );
  }

  Widget _buildStuckOrderCard(Map<String, dynamic> order) {
    final createdAt = DateTime.parse(order['created_at']);
    final duration = DateTime.now().difference(createdAt);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('#${order['order_number']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(order['status'], style: TextStyle(color: Colors.orange.shade800, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Restaurant: ${order['restaurant']?['name'] ?? 'N/A'}'),
            Text('Durée: ${duration.inMinutes} minutes', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _forceCancel(order['id']),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _forceDeliver(order['id']),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Forcer livré'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInactiveLivreurCard(Map<String, dynamic> livreur) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(livreur['user']?['full_name'] ?? 'Livreur'),
        subtitle: Text(livreur['user']?['phone'] ?? ''),
        trailing: ElevatedButton(
          onPressed: () => _releaseLivreur(livreur['id']),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          child: const Text('Libérer'),
        ),
      ),
    );
  }

  Future<void> _forceCancel(String orderId) async {
    final reason = await _showReasonDialog('Raison de l\'annulation');
    if (reason == null) return;
    
    await SupabaseService.adminCancelOrder(orderId, reason);
    _loadData();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Commande annulée')));
  }

  Future<void> _forceDeliver(String orderId) async {
    final reason = await _showReasonDialog('Raison du forçage');
    if (reason == null) return;
    
    await SupabaseService.forceDelivered(orderId, reason);
    _loadData();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Commande marquée livrée')));
  }

  Future<void> _releaseLivreur(String livreurId) async {
    await SupabaseService.forceReleaseLivreur(livreurId, 'Libération manuelle - inactivité');
    _loadData();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Livreur libéré')));
  }

  Future<String?> _showReasonDialog(String title) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Entrez la raison...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.isEmpty ? 'Action admin' : controller.text),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }
}
