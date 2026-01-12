import 'package:flutter/material.dart';
import '../../../core/router/app_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isOnline = false;
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DZ Delivery Livreur'),
        actions: [
          Switch(
            value: _isOnline,
            onChanged: (v) => setState(() => _isOnline = v),
            activeColor: Colors.green,
          ),
          Text(_isOnline ? 'En ligne' : 'Hors ligne', style: TextStyle(color: _isOnline ? Colors.green : Colors.grey)),
          const SizedBox(width: 8),
        ],
      ),
      body: _isOnline ? _buildOrdersList() : _buildOfflineMessage(),
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

  Widget _buildOrdersList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) => _buildOrderCard(context, index),
    );
  }

  Widget _buildOrderCard(BuildContext context, int index) {
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
              Text('Commande #${1000 + index}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: const Text('Nouvelle', style: TextStyle(color: Colors.orange, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(children: [const Icon(Icons.restaurant, size: 16, color: Colors.grey), const SizedBox(width: 8), Text('Restaurant ${index + 1}', style: TextStyle(color: Colors.grey[600]))]),
          const SizedBox(height: 4),
          Row(children: [const Icon(Icons.location_on, size: 16, color: Colors.grey), const SizedBox(width: 8), Text('2.${index + 1} km', style: TextStyle(color: Colors.grey[600]))]),
          const SizedBox(height: 4),
          Row(children: [const Icon(Icons.attach_money, size: 16, color: Colors.green), const SizedBox(width: 8), Text('${150 + index * 50} DA', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))]),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: () {}, child: const Text('Refuser'))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(onPressed: () => Navigator.pushNamed(context, AppRouter.orderDetail, arguments: 'order_$index'), child: const Text('Accepter'))),
            ],
          ),
        ],
      ),
    );
  }
}
