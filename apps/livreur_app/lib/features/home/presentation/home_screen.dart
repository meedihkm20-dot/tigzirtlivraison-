import 'package:flutter/material.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/supabase_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isOnline = false;
  int _currentIndex = 0;
  List<Map<String, dynamic>> _availableOrders = [];
  List<Map<String, dynamic>> _activeOrders = [];
  bool _isLoading = false;
  Map<String, dynamic>? _livreurProfile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await SupabaseService.getLivreurProfile();
    if (profile != null) {
      setState(() {
        _livreurProfile = profile;
        _isOnline = profile['is_online'] ?? false;
      });
      if (_isOnline) _loadOrders();
    }
  }

  Future<void> _toggleOnline(bool value) async {
    setState(() => _isOnline = value);
    await SupabaseService.setOnlineStatus(value);
    if (value) {
      _loadOrders();
    } else {
      setState(() => _availableOrders = []);
    }
  }

  Future<void> _loadOrders() async {
    if (!_isOnline) return;
    setState(() => _isLoading = true);
    try {
      final available = await SupabaseService.getAvailableOrders(
        lat: _livreurProfile?['current_latitude'] ?? 36.7538,
        lng: _livreurProfile?['current_longitude'] ?? 3.0588,
      );
      final active = await SupabaseService.getMyActiveOrders();
      setState(() {
        _availableOrders = available;
        _activeOrders = active;
      });
    } catch (e) {
      debugPrint('Erreur chargement commandes: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptOrder(String orderId) async {
    // Afficher un loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
    
    final result = await SupabaseService.acceptOrder(orderId);
    
    // Fermer le loader
    if (mounted) Navigator.of(context).pop();
    
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${result['message'] ?? 'Commande acceptée!'}'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushNamed(context, AppRouter.orderDetail, arguments: orderId);
      _loadOrders();
    } else {
      // Gérer les différents cas d'erreur
      String message = result['message'] ?? 'Erreur inconnue';
      Color bgColor = Colors.red;
      
      if (result['error'] == 'ORDER_ALREADY_TAKEN') {
        message = '⚠️ Trop tard! Un autre livreur a pris cette commande';
        bgColor = Colors.orange;
        _loadOrders(); // Rafraîchir la liste
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: bgColor, duration: const Duration(seconds: 4)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DZ Delivery Livreur'),
        actions: [
          Switch(value: _isOnline, onChanged: _toggleOnline, activeColor: Colors.green),
          Text(_isOnline ? 'En ligne' : 'Hors ligne', style: TextStyle(color: _isOnline ? Colors.green : Colors.grey)),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrders,
        child: _isOnline ? _buildContent() : _buildOfflineMessage(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() => _currentIndex = i);
          if (i == 1) Navigator.pushNamed(context, AppRouter.earnings);
          if (i == 2) Navigator.pushNamed(context, AppRouter.profile);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Gains'),
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Commandes actives
          if (_activeOrders.isNotEmpty) ...[
            const Text('Livraison en cours', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ..._activeOrders.map((order) => _buildActiveOrderCard(order)),
            const SizedBox(height: 24),
          ],
          
          // Commandes disponibles
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
                    const SizedBox(height: 8),
                    Text('Tirez vers le bas pour actualiser', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
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
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Commande #${order['order_number'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Commande #${order['order_number'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
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
