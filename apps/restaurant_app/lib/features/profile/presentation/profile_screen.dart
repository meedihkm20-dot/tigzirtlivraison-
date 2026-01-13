import 'package:flutter/material.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/supabase_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _restaurant;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final restaurant = await SupabaseService.getMyRestaurant();
      setState(() => _restaurant = restaurant);
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
      appBar: AppBar(title: const Text('Mon Restaurant')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE65100).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        image: _restaurant?['logo_url'] != null
                            ? DecorationImage(image: NetworkImage(_restaurant!['logo_url']), fit: BoxFit.cover)
                            : null,
                      ),
                      child: _restaurant?['logo_url'] == null
                          ? const Icon(Icons.restaurant, size: 50, color: Color(0xFFE65100))
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(_restaurant?['name'] ?? 'Mon Restaurant', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    Text(_restaurant?['cuisine_type'] ?? '', style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        Text(' ${(_restaurant?['rating'] ?? 0).toStringAsFixed(1)} ', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('(${_restaurant?['total_reviews'] ?? 0} avis)', style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: (_restaurant?['is_verified'] ?? false) ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        (_restaurant?['is_verified'] ?? false) ? '✓ Vérifié' : 'En attente de vérification',
                        style: TextStyle(
                          color: (_restaurant?['is_verified'] ?? false) ? Colors.green : Colors.orange,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildMenuItem(Icons.store, 'Informations du restaurant', () {}),
                    _buildMenuItem(Icons.access_time, 'Horaires (${_restaurant?['opening_time'] ?? '08:00'} - ${_restaurant?['closing_time'] ?? '23:00'})', () {}),
                    _buildMenuItem(Icons.location_on, _restaurant?['address'] ?? 'Adresse', () {}),
                    _buildMenuItem(Icons.delivery_dining, 'Frais de livraison: ${_restaurant?['delivery_fee'] ?? 0} DA', () {}),
                    _buildMenuItem(Icons.account_balance_wallet, 'Paiements', () {}),
                    _buildMenuItem(Icons.notifications, 'Notifications', () {}),
                    _buildMenuItem(Icons.help, 'Aide & Support', () {}),
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

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(leading: Icon(icon, color: const Color(0xFFE65100)), title: Text(title), trailing: const Icon(Icons.chevron_right), onTap: onTap);
  }
}
