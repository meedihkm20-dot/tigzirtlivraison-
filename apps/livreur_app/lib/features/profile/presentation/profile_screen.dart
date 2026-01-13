import 'package:flutter/material.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/supabase_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
      setState(() => _livreur = livreur);
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
    final profile = _livreur?['profile'];
    
    return Scaffold(
      appBar: AppBar(title: const Text('Mon Profil')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: const Color(0xFF2E7D32),
                      backgroundImage: profile?['avatar_url'] != null ? NetworkImage(profile['avatar_url']) : null,
                      child: profile?['avatar_url'] == null ? const Icon(Icons.person, size: 50, color: Colors.white) : null,
                    ),
                    const SizedBox(height: 16),
                    Text(profile?['full_name'] ?? 'Livreur', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    Text(profile?['phone'] ?? '', style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        Text(' ${(_livreur?['rating'] ?? 5.0).toStringAsFixed(1)} ', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('(${_livreur?['total_deliveries'] ?? 0} livraisons)', style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildStatCard(),
                    const SizedBox(height: 16),
                    _buildMenuItem(Icons.person_outline, 'Informations personnelles', () {}),
                    _buildMenuItem(Icons.directions_bike, 'Mon véhicule (${_getVehicleType(_livreur?['vehicle_type'])})', () {}),
                    _buildMenuItem(Icons.map_outlined, 'Zones de livraison', () {}),
                    _buildMenuItem(Icons.history, 'Historique', () {}),
                    _buildMenuItem(Icons.help_outline, 'Aide', () {}),
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
          _buildStat('${_livreur?['total_deliveries'] ?? 0}', 'Livraisons'),
          _buildStat('${(_livreur?['total_earnings'] ?? 0).toStringAsFixed(0)}', 'DA gagnés'),
          _buildStat('${(_livreur?['rating'] ?? 5.0).toStringAsFixed(1)}', 'Note'),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(leading: Icon(icon, color: const Color(0xFF2E7D32)), title: Text(title), trailing: const Icon(Icons.chevron_right), onTap: onTap);
  }

  String _getVehicleType(String? type) {
    switch (type) {
      case 'moto': return 'Moto';
      case 'velo': return 'Vélo';
      case 'voiture': return 'Voiture';
      default: return 'Non défini';
    }
  }
}
