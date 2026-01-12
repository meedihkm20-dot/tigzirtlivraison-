import 'package:flutter/material.dart';
import '../../../core/router/app_router.dart';

class OrderDetailScreen extends StatelessWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Commande #$orderId')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(16)),
              child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.map, size: 60, color: Colors.grey), Text('Carte', style: TextStyle(color: Colors.grey))])),
            ),
            const SizedBox(height: 24),
            _buildSection('Restaurant', Icons.restaurant, 'Restaurant Exemple', 'Rue Didouche Mourad, Alger'),
            const SizedBox(height: 16),
            _buildSection('Client', Icons.person, 'Ahmed B.', 'Rue des Frères Bouadou, Bir Mourad Raïs'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Articles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  _buildItem('Pizza Margherita', 1),
                  _buildItem('Burger Classic', 2),
                  const Divider(),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [Text('Gain livraison', style: TextStyle(fontWeight: FontWeight.bold)), Text('200 DA', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)))]),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pushNamed(context, AppRouter.delivery, arguments: orderId), child: const Text('Commencer la livraison'))),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, String name, String address) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Row(
        children: [
          Container(width: 50, height: 50, decoration: BoxDecoration(color: const Color(0xFF2E7D32).withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: const Color(0xFF2E7D32))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)), Text(name, style: const TextStyle(fontWeight: FontWeight.bold)), Text(address, style: TextStyle(color: Colors.grey[600], fontSize: 12))])),
          IconButton(icon: const Icon(Icons.navigation, color: Color(0xFF2E7D32)), onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildItem(String name, int qty) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('$qty x $name'), const Icon(Icons.check_circle, color: Colors.green, size: 20)]));
  }
}
