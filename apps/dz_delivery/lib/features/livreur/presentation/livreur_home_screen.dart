import 'package:flutter/material.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';

class LivreurHomeScreen extends StatefulWidget {
  const LivreurHomeScreen({super.key});

  @override
  State<LivreurHomeScreen> createState() => _LivreurHomeScreenState();
}

class _LivreurHomeScreenState extends State<LivreurHomeScreen> {
  bool _isOnline = false;
  int _currentIndex = 0;
  List<Map<String, dynamic>> _availableOrders = [];
  List<Map<String, dynamic>> _activeOrders = [];
  bool _isLoading = false;
  Map<String, dynamic>? _livreurProfile;
  Map<String, dynamic>? _tierInfo;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await SupabaseService.getLivreurProfile();
      Map<String, dynamic>? tierInfo;
      try {
        tierInfo = await SupabaseService.getLivreurTierInfo();
      } catch (e) {
        debugPrint('Erreur tier info: $e');
      }
      
      if (profile != null && mounted) {
        setState(() {
          _livreurProfile = profile;
          _tierInfo = tierInfo;
          _isOnline = profile['is_online'] ?? false;
        });
        if (_isOnline) _loadOrders();
      }
    } catch (e) {
      debugPrint('Erreur profil livreur: $e');
    }
  }

  Future<void> _toggleOnline(bool value) async {
    setState(() => _isOnline = value);
    try {
      await SupabaseService.setOnlineStatus(value);
      if (value) {
        _loadOrders();
      } else {
        setState(() => _availableOrders = []);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isOnline = !value);
      }
    }
  }

  Future<void> _loadOrders() async {
    if (!_isOnline) return;
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        SupabaseService.getAvailableOrders(),
        SupabaseService.getLivreurActiveOrders(),
      ]);
      if (mounted) {
        setState(() {
          _availableOrders = results[0];
          _activeOrders = results[1];
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement commandes: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptOrder(String orderId) async {
    try {
      await SupabaseService.acceptOrder(orderId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Commande acceptée! 🎉'), backgroundColor: Colors.green),
        );
        Navigator.pushNamed(context, AppRouter.delivery, arguments: orderId);
        _loadOrders();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString().replaceAll('Exception:', '')}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
    if (index == 1) Navigator.pushNamed(context, AppRouter.earnings);
    if (index == 2) Navigator.pushNamed(context, AppRouter.tierProgress);
    if (index == 3) Navigator.pushNamed(context, AppRouter.livreurProfile);
  }

  String _getTierEmoji(String? tier) {
    switch (tier) {
      case 'diamond': return '💎';
      case 'gold': return '🥇';
      case 'silver': return '🥈';
      default: return '🥉';
    }
  }

  Color _getTierColor(String? tier) {
    switch (tier) {
      case 'diamond': return Colors.cyan;
      case 'gold': return Colors.amber;
      case 'silver': return Colors.grey;
      default: return Colors.brown;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTier = _tierInfo?['current_tier'] ?? 'bronze';
    final commissionRate = (_tierInfo?['commission_rate'] as num?)?.toDouble() ?? 10.0;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('DZ Delivery Livreur'),
        actions: [
          // Tier badge
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRouter.tierProgress),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _getTierColor(currentTier).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_getTierEmoji(currentTier), style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Text('${commissionRate.toStringAsFixed(0)}%', style: TextStyle(fontWeight: FontWeight.bold, color: _getTierColor(currentTier))),
                ],
              ),
            ),
          ),
          Switch(value: _isOnline, onChanged: _toggleOnline, activeColor: Colors.green),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrders,
        child: _isOnline ? _buildContent() : _buildOfflineMessage(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: _onNavTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Gains'),
          BottomNavigationBarItem(icon: Icon(Icons.trending_up), label: 'Niveau'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildOfflineMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('Vous êtes hors ligne', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Activez le mode en ligne pour recevoir des commandes', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_activeOrders.isNotEmpty) ...[
            const Text('Livraison en cours', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ..._activeOrders.map((order) => _buildActiveOrderCard(order)),
            const SizedBox(height: 24),
          ],
          const Text('Commandes disponibles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (_availableOrders.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text('Aucune commande disponible', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
            )
          else
            ..._availableOrders.map((order) => _buildOrderCard(order)),
        ],
      ),
    );
  }

  Widget _buildActiveOrderCard(Map<String, dynamic> order) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRouter.delivery, arguments: order['id']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('#${order['order_number'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(20)),
                  child: Text(_getStatusText(order['status']), style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.restaurant, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(order['restaurant']?['name'] ?? 'Restaurant', style: TextStyle(color: Colors.grey[600])),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(child: Text(order['delivery_address'] ?? '', style: TextStyle(color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, AppRouter.delivery, arguments: order['id']),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Continuer la livraison'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('#${order['order_number'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: const Text('Nouvelle', style: TextStyle(color: Colors.orange, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.restaurant, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Text(order['restaurant']?['name'] ?? 'Restaurant', style: TextStyle(color: Colors.grey[600])),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.location_on, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(child: Text(order['delivery_address'] ?? '', style: TextStyle(color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.attach_money, size: 16, color: Colors.green),
            const SizedBox(width: 8),
            Text('${order['delivery_fee'] ?? 0} DA', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: () {}, child: const Text('Refuser'))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(onPressed: () => _acceptOrder(order['id']), child: const Text('Accepter'))),
            ],
          ),
        ],
      ),
    );
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'picked_up': return 'Récupérée';
      case 'delivering': return 'En livraison';
      default: return status ?? '';
    }
  }
}
