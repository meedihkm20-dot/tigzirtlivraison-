import 'package:flutter/material.dart';
import '../../../core/router/app_router.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mon Profil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircleAvatar(radius: 50, backgroundColor: Color(0xFF2E7D32), child: Icon(Icons.person, size: 50, color: Colors.white)),
            const SizedBox(height: 16),
            const Text('Karim M.', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Text('+213 555 987 654', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.star, color: Colors.amber, size: 20), Text(' 4.8 ', style: TextStyle(fontWeight: FontWeight.bold)), Text('(245 livraisons)', style: TextStyle(color: Colors.grey))]),
            const SizedBox(height: 32),
            _buildStatCard(),
            const SizedBox(height: 16),
            _buildMenuItem(Icons.person_outline, 'Informations personnelles', () {}),
            _buildMenuItem(Icons.directions_bike, 'Mon véhicule', () {}),
            _buildMenuItem(Icons.map_outlined, 'Zones de livraison', () {}),
            _buildMenuItem(Icons.history, 'Historique', () {}),
            _buildMenuItem(Icons.help_outline, 'Aide', () {}),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(context, AppRouter.login, (route) => false),
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Se déconnecter', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF2E7D32).withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat('245', 'Livraisons'),
          _buildStat('98%', 'Taux'),
          _buildStat('4.8', 'Note'),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(children: [Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))), Text(label, style: const TextStyle(color: Colors.grey))]);
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(leading: Icon(icon, color: const Color(0xFF2E7D32)), title: Text(title), trailing: const Icon(Icons.chevron_right), onTap: onTap);
  }
}
