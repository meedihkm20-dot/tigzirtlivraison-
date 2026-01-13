import 'package:flutter/material.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/supabase_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await SupabaseService.getProfile();
      setState(() => _profile = profile);
    } catch (e) {
      debugPrint('Erreur chargement profil: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await SupabaseService.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, AppRouter.login, (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mon Profil')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFFFF6B35),
                    backgroundImage: _profile?['avatar_url'] != null ? NetworkImage(_profile!['avatar_url']) : null,
                    child: _profile?['avatar_url'] == null ? const Icon(Icons.person, size: 50, color: Colors.white) : null,
                  ),
                  const SizedBox(height: 16),
                  Text(_profile?['full_name'] ?? 'Utilisateur', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text(_profile?['phone'] ?? SupabaseService.currentUser?.email ?? '', style: const TextStyle(color: Colors.grey)),
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
                      onPressed: _logout,
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
