import 'package:flutter/material.dart';
import '../../../core/router/app_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isOpen = true;
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Restaurant'),
        actions: [
          Switch(value: _isOpen, onChanged: (v) => setState(() => _isOpen = v), activeColor: Colors.green),
          Text(_isOpen ? 'Ouvert' : 'Fermé', style: TextStyle(color: _isOpen ? Colors.green : Colors.red)),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _buildStatCard('Aujourd\'hui', '12', 'commandes', Icons.receipt_long, Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Revenus', '15,600', 'DA', Icons.attach_money, Colors.green)),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Commandes en cours', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(onPressed: () {}, child: const Text('Voir tout')),
              ],
            ),
            const SizedBox(height: 12),
            ...List.generate(3, (i) => _buildOrderCard(context, i)),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (i) {
          setState(() => _currentIndex = i);
          if (i == 1) Navigator.pushNamed(context, AppRouter.menu);
          if (i == 2) Navigator.pushNamed(context, AppRouter.stats);
          if (i == 3) Navigator.pushNamed(context, AppRouter.profile);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Menu'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String unit, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(color: Colors.grey[600])),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)), const SizedBox(width: 4), Text(unit, style: TextStyle(color: Colors.grey[600]))]),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, int index) {
    final statuses = ['Nouvelle', 'En préparation', 'Prête'];
    final colors = [Colors.orange, Colors.blue, Colors.green];
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRouter.orderDetail, arguments: 'order_$index'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Commande #${1000 + index}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: colors[index].withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(statuses[index], style: TextStyle(color: colors[index], fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('2 articles • 1,500 DA', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text('Il y a ${5 + index * 3} min', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
