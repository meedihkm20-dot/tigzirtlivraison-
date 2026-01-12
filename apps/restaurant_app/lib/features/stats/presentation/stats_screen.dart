import 'package:flutter/material.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistiques')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _buildStatCard('Commandes', '156', 'ce mois', Icons.receipt_long, Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Revenus', '234K', 'DA', Icons.attach_money, Colors.green)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildStatCard('Note', '4.7', '/5', Icons.star, Colors.amber)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Avis', '89', 'total', Icons.comment, Colors.purple)),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Revenus cette semaine', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildBar('Lun', 0.6),
                  _buildBar('Mar', 0.8),
                  _buildBar('Mer', 0.5),
                  _buildBar('Jeu', 0.9),
                  _buildBar('Ven', 1.0),
                  _buildBar('Sam', 0.7),
                  _buildBar('Dim', 0.4),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Plats populaires', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildPopularItem('Pizza Margherita', 45, 1),
            _buildPopularItem('Burger Classic', 38, 2),
            _buildPopularItem('Pizza 4 Fromages', 32, 3),
          ],
        ),
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

  Widget _buildBar(String day, double height) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(width: 30, height: 120 * height, decoration: BoxDecoration(color: const Color(0xFFE65100), borderRadius: BorderRadius.circular(4))),
        const SizedBox(height: 8),
        Text(day, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  Widget _buildPopularItem(String name, int orders, int rank) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(width: 30, height: 30, decoration: BoxDecoration(color: rank == 1 ? Colors.amber : (rank == 2 ? Colors.grey[400] : Colors.brown[300]), shape: BoxShape.circle), child: Center(child: Text('$rank', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w500))),
          Text('$orders commandes', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }
}
