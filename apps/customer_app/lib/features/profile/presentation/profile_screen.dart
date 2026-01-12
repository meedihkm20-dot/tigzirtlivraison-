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
            const CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFFFF6B35),
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text('Ahmed Benali', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Text('+213 555 123 456', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            _buildMenuItem(context, Icons.person_outline, 'Informations personnelles', () {}),
            _buildMenuItem(context, Icons.location_on_outlined, 'Mes adresses', () {}),
            _buildMenuItem(context, Icons.payment_outlined, 'Moyens de paiement', () {}),
            _buildMenuItem(context, Icons.receipt_long_outlined, 'Historique des commandes', () {
              Navigator.pushNamed(context, AppRouter.orders);
            }),
            _buildMenuItem(context, Icons.notifications_outlined, 'Notifications', () {}),
            _buildMenuItem(context, Icons.help_outline, 'Aide & Support', () {}),
            _buildMenuItem(context, Icons.info_outline, 'À propos', () {}),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Déconnexion'),
                      content: const Text('Voulez-vous vraiment vous déconnecter?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushNamedAndRemoveUntil(context, AppRouter.login, (route) => false);
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('Déconnexion'),
                        ),
                      ],
                    ),
                  );
                },
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

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFFF6B35)),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
