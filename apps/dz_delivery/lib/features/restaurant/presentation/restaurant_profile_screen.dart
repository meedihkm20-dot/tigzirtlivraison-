import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/router/app_router.dart';

class RestaurantProfileScreen extends StatefulWidget {
  const RestaurantProfileScreen({super.key});

  @override
  State<RestaurantProfileScreen> createState() => _RestaurantProfileScreenState();
}

class _RestaurantProfileScreenState extends State<RestaurantProfileScreen> {
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
      setState(() {
        _restaurant = restaurant;
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
                    child: const Icon(Icons.restaurant, size: 50, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Text(_restaurant?['name'] ?? 'Restaurant', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text(_restaurant?['address'] ?? '', style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 32),
                  _buildInfoTile(Icons.phone, 'Téléphone', _restaurant?['phone'] ?? 'Non défini'),
                  _buildInfoTile(Icons.access_time, 'Horaires', '${_restaurant?['opening_time'] ?? '08:00'} - ${_restaurant?['closing_time'] ?? '23:00'}'),
                  _buildInfoTile(Icons.star, 'Note', '${(_restaurant?['rating'] ?? 0).toStringAsFixed(1)}/5'),
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
