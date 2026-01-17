import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/supabase_service.dart';

/// Écran Gestion Restaurants Admin Amélioré
/// - Liste complète avec stats
/// - Activer/Désactiver
/// - Fiche détaillée
/// - Appel téléphone
class RestaurantsManagementScreen extends StatefulWidget {
  const RestaurantsManagementScreen({super.key});

  @override
  State<RestaurantsManagementScreen> createState() => _RestaurantsManagementScreenState();
}

class _RestaurantsManagementScreenState extends State<RestaurantsManagementScreen> {
  List<Map<String, dynamic>> _restaurants = [];
  bool _isLoading = true;
  String _filter = 'all'; // all, active, inactive

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  Future<void> _loadRestaurants() async {
    setState(() => _isLoading = true);
    try {
      final restaurants = await SupabaseService.getAllRestaurants();
      setState(() {
        _restaurants = restaurants;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredRestaurants {
    switch (_filter) {
      case 'active':
        return _restaurants.where((r) => r['is_verified'] == true).toList();
      case 'inactive':
        return _restaurants.where((r) => r['is_verified'] != true).toList();
      default:
        return _restaurants;
    }
  }

  Future<void> _toggleStatus(String restaurantId, bool currentStatus) async {
    try {
      await SupabaseService.toggleRestaurantStatus(restaurantId, !currentStatus);
      await _loadRestaurants();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(currentStatus ? 'Restaurant désactivé' : 'Restaurant activé'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showRestaurantDetails(String restaurantId) async {
    showDialog(
      context: context,
      builder: (context) => _RestaurantDetailsDialog(restaurantId: restaurantId),
    );
  }

  Future<void> _callRestaurant(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        title: const Text('Gestion Restaurants', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRestaurants,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtres
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Tous (${_restaurants.length})',
                  isSelected: _filter == 'all',
                  onTap: () => setState(() => _filter = 'all'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Actifs',
                  isSelected: _filter == 'active',
                  onTap: () => setState(() => _filter = 'active'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Inactifs',
                  isSelected: _filter == 'inactive',
                  onTap: () => setState(() => _filter = 'inactive'),
                ),
              ],
            ),
          ),

          // Liste
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : _filteredRestaurants.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucun restaurant',
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadRestaurants,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredRestaurants.length,
                          itemBuilder: (context, index) {
                            final restaurant = _filteredRestaurants[index];
                            return _RestaurantCard(
                              restaurant: restaurant,
                              onToggle: () => _toggleStatus(
                                restaurant['id'],
                                restaurant['is_verified'] ?? false,
                              ),
                              onDetails: () => _showRestaurantDetails(restaurant['id']),
                              onCall: () => _callRestaurant(restaurant['phone'] ?? ''),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange : const Color(0xFF1B2838),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white54,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  final Map<String, dynamic> restaurant;
  final VoidCallback onToggle;
  final VoidCallback onDetails;
  final VoidCallback onCall;

  const _RestaurantCard({
    required this.restaurant,
    required this.onToggle,
    required this.onDetails,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = restaurant['is_verified'] ?? false;
    final isOpen = restaurant['is_open'] ?? false;
    final name = restaurant['name'] ?? 'Restaurant';
    final phone = restaurant['phone'] ?? '';
    final address = restaurant['address'] ?? '';
    final rating = (restaurant['rating'] as num?)?.toDouble() ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2838),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.orange.withOpacity(0.2),
                    child: const Icon(Icons.restaurant, color: Colors.orange),
                  ),
                  if (isOpen)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF1B2838), width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      phone,
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    Text(
                      address,
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.orange, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isActive ? 'Actif' : 'Inactif',
                  style: TextStyle(
                    color: isActive ? Colors.green : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCall,
                  icon: const Icon(Icons.phone, size: 16),
                  label: const Text('Appeler'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDetails,
                  icon: const Icon(Icons.info, size: 16),
                  label: const Text('Détails'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white54,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onToggle,
                  icon: Icon(isActive ? Icons.block : Icons.check, size: 16),
                  label: Text(isActive ? 'Désactiver' : 'Activer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActive ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                    foregroundColor: isActive ? Colors.red : Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RestaurantDetailsDialog extends StatefulWidget {
  final String restaurantId;

  const _RestaurantDetailsDialog({required this.restaurantId});

  @override
  State<_RestaurantDetailsDialog> createState() => _RestaurantDetailsDialogState();
}

class _RestaurantDetailsDialogState extends State<_RestaurantDetailsDialog> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await SupabaseService.getRestaurantStats(widget.restaurantId);
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1B2838),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _stats == null
                ? const Center(child: Text('Erreur', style: TextStyle(color: Colors.white)))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _stats!['name'] ?? 'Restaurant',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white54),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _StatRow('Total Commandes', '${_stats!['total_orders']}'),
                      _StatRow('Commandes Livrées', '${_stats!['delivered_orders']}'),
                      _StatRow('Revenus Totaux', '${(_stats!['total_revenue'] as num).toStringAsFixed(0)} DA'),
                      _StatRow('Commission Admin', '${(_stats!['total_commission'] as num).toStringAsFixed(0)} DA'),
                      _StatRow('Revenus Nets', '${(_stats!['net_revenue'] as num).toStringAsFixed(0)} DA'),
                      _StatRow('Note Moyenne', '${(_stats!['rating'] as num?)?.toStringAsFixed(1) ?? '0.0'} ⭐'),
                      _StatRow('Adresse', _stats!['address'] ?? 'N/A'),
                      _StatRow('Téléphone', _stats!['phone'] ?? 'N/A'),
                      _StatRow('Statut', _stats!['is_verified'] ? 'Vérifié' : 'Non vérifié'),
                      _StatRow('Ouvert', _stats!['is_open'] ? 'Oui' : 'Non'),
                    ],
                  ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
