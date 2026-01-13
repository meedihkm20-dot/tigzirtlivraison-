import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/router/app_router.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
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
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await SupabaseService.signOut();
    if (mounted) Navigator.pushReplacementNamed(context, AppRouter.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[200],
                    child: Text(
                      (_profile?['full_name'] ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(_profile?['full_name'] ?? 'Utilisateur', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text(_profile?['phone'] ?? '', style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 32),
                  _buildMenuItem(Icons.person_outline, 'Modifier le profil', () {}),
                  _buildMenuItem(Icons.location_on_outlined, 'Mes adresses', () {}),
                  _buildMenuItem(Icons.payment_outlined, 'Paiement', () {}),
                  _buildMenuItem(Icons.help_outline, 'Aide', () {}),
                  const SizedBox(height: 24),
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

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
