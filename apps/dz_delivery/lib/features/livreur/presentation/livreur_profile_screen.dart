import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/router/app_router.dart';

class LivreurProfileScreen extends StatefulWidget {
  const LivreurProfileScreen({super.key});

  @override
  State<LivreurProfileScreen> createState() => _LivreurProfileScreenState();
}

class _LivreurProfileScreenState extends State<LivreurProfileScreen> {
  Map<String, dynamic>? _livreur;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final livreur = await SupabaseService.getLivreurProfile();
      setState(() {
        _livreur = livreur;
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

  String _getVehicleText(String? type) {
    switch (type) {
      case 'moto': return 'Moto';
      case 'velo': return 'Vélo';
      case 'voiture': return 'Voiture';
      default: return type ?? 'Non défini';
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _livreur?['profile'] as Map<String, dynamic>?;
    
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
                    child: const Icon(Icons.delivery_dining, size: 50, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Text(profile?['full_name'] ?? 'Livreur', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text(profile?['phone'] ?? '', style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      Text(' ${(_livreur?['rating'] ?? 5.0).toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(' • ${_livreur?['total_deliveries'] ?? 0} livraisons', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildInfoTile(Icons.two_wheeler, 'Véhicule', _getVehicleText(_livreur?['vehicle_type'])),
                  _buildInfoTile(Icons.account_balance_wallet, 'Gains totaux', '${(_livreur?['total_earnings'] ?? 0).toStringAsFixed(0)} DA'),
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

  Widget _buildInfoTile(IconData icon, String title, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey),
      title: Text(title),
      subtitle: Text(value),
    );
  }
}
