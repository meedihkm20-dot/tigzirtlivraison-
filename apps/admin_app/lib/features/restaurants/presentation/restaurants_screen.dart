import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';

class RestaurantsScreen extends StatefulWidget {
  const RestaurantsScreen({super.key});

  @override
  State<RestaurantsScreen> createState() => _RestaurantsScreenState();
}

class _RestaurantsScreenState extends State<RestaurantsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _allRestaurants = [];
  List<Map<String, dynamic>> _pendingRestaurants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRestaurants();
  }

  Future<void> _loadRestaurants() async {
    setState(() => _isLoading = true);
    try {
      final all = await SupabaseService.getAllRestaurants();
      final pending = await SupabaseService.getPendingRestaurants();
      setState(() {
        _allRestaurants = all;
        _pendingRestaurants = pending;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  Future<void> _verifyRestaurant(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Valider le restaurant'),
        content: Text('Voulez-vous valider "$name" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Valider')),
        ],
      ),
    );
    if (confirm == true) {
      await SupabaseService.verifyRestaurant(id);
      _loadRestaurants();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Restaurant validé'), backgroundColor: AppTheme.successColor),
        );
      }
    }
  }

  Future<void> _toggleStatus(String id, String name, bool currentStatus) async {
    await SupabaseService.toggleRestaurantStatus(id, !currentStatus);
    _loadRestaurants();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(currentStatus ? 'Restaurant désactivé' : 'Restaurant activé'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  Future<void> _deleteRestaurant(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le restaurant'),
        content: Text('Êtes-vous sûr de vouloir supprimer "$name" ? Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await SupabaseService.deleteRestaurant(id);
      _loadRestaurants();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Restaurant supprimé'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion Restaurants'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Tous (${_allRestaurants.length})'),
            Tab(text: 'En attente (${_pendingRestaurants.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRestaurantList(_allRestaurants, showVerifyButton: false),
                _buildRestaurantList(_pendingRestaurants, showVerifyButton: true),
              ],
            ),
    );
  }

  Widget _buildRestaurantList(List<Map<String, dynamic>> restaurants, {required bool showVerifyButton}) {
    if (restaurants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              showVerifyButton ? 'Aucune demande en attente' : 'Aucun restaurant',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRestaurants,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: restaurants.length,
        itemBuilder: (context, index) {
          final restaurant = restaurants[index];
          final isVerified = restaurant['is_verified'] ?? false;
          final isOpen = restaurant['is_open'] ?? false;
          final owner = restaurant['owner'] as Map<String, dynamic>?;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: isVerified ? AppTheme.successColor : AppTheme.warningColor,
                child: Icon(
                  isVerified ? Icons.verified : Icons.pending,
                  color: Colors.white,
                ),
              ),
              title: Text(
                restaurant['name'] ?? 'Sans nom',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(restaurant['address'] ?? ''),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isOpen ? AppTheme.successColor : Colors.grey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isOpen ? 'Ouvert' : 'Fermé',
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!isVerified)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.warningColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Non vérifié',
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow(icon: Icons.person, label: 'Propriétaire', value: owner?['full_name'] ?? 'N/A'),
                      _InfoRow(icon: Icons.phone, label: 'Téléphone', value: restaurant['phone'] ?? 'N/A'),
                      _InfoRow(icon: Icons.star, label: 'Note', value: '${restaurant['rating'] ?? 0}/5'),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (showVerifyButton || !isVerified)
                            TextButton.icon(
                              onPressed: () => _verifyRestaurant(restaurant['id'], restaurant['name']),
                              icon: const Icon(Icons.verified, color: AppTheme.successColor),
                              label: const Text('Valider', style: TextStyle(color: AppTheme.successColor)),
                            ),
                          TextButton.icon(
                            onPressed: () => _toggleStatus(restaurant['id'], restaurant['name'], isOpen),
                            icon: Icon(
                              isOpen ? Icons.block : Icons.check_circle,
                              color: isOpen ? AppTheme.warningColor : AppTheme.successColor,
                            ),
                            label: Text(
                              isOpen ? 'Désactiver' : 'Activer',
                              style: TextStyle(color: isOpen ? AppTheme.warningColor : AppTheme.successColor),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _deleteRestaurant(restaurant['id'], restaurant['name']),
                            icon: const Icon(Icons.delete, color: AppTheme.errorColor),
                            label: const Text('Supprimer', style: TextStyle(color: AppTheme.errorColor)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: Colors.grey)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
