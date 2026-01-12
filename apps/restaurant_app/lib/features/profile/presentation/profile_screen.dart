import 'package:flutter/material.dart';
import '../../../core/router/app_router.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mon Restaurant')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(color: const Color(0xFFE65100).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.restaurant, size: 50, color: Color(0xFFE65100)),
            ),
            const SizedBox(height: 16),
            const Text('Pizza House', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Text('Pizza • Fast Food', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.star, color: Colors.amber, size: 20), Text(' 4.7 ', style: TextStyle(fontWeight: FontWeight.bold)), Text('(89 avis)', style: TextStyle(color: Colors.grey))]),
            const SizedBox(height: 32),
            _buildMenuItem(Icons.store, 'Informations du restaurant', () {}),
            _buildMenuItem(Icons.access_time, 'Horaires d\'ouverture', () {}),
            _buildMenuItem(Icons.location_on, 'Adresse', () {}),
            _buildMenuItem(Icons.account_balance_wallet, 'Paiements', () {}),
            _buildMenuItem(Icons.notifications, 'Notifications', () {}),
            _buildMenuItem(Icons.help, 'Aide & Support', () {}),
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

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(leading: Icon(icon, color: const Color(0xFFE65100)), title: Text(title), trailing: const Icon(Icons.chevron_right), onTap: onTap);
  }
}
