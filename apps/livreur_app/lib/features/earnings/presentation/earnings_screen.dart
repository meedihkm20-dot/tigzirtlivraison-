import 'package:flutter/material.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes Gains')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)]), borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: const [
                  Text('Solde disponible', style: TextStyle(color: Colors.white70)),
                  SizedBox(height: 8),
                  Text('12,500 DA', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(height: 16),
                  ElevatedButton(onPressed: null, style: ButtonStyle(backgroundColor: MaterialStatePropertyAll(Colors.white)), child: Text('Retirer', style: TextStyle(color: Color(0xFF2E7D32)))),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildStatCard('Aujourd\'hui', '1,200 DA', Icons.today)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Cette semaine', '8,500 DA', Icons.date_range)),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Historique', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...List.generate(5, (i) => _buildTransactionItem(i)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: const Color(0xFF2E7D32)), const SizedBox(height: 8), Text(title, style: const TextStyle(color: Colors.grey)), Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
    );
  }

  Widget _buildTransactionItem(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFF2E7D32).withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.delivery_dining, color: Color(0xFF2E7D32))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Commande #${1000 + index}', style: const TextStyle(fontWeight: FontWeight.w500)), Text('12 Jan 2026', style: TextStyle(color: Colors.grey[600], fontSize: 12))])),
          Text('+${150 + index * 25} DA', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
        ],
      ),
    );
  }
}
