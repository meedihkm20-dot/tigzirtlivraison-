import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/supabase_service.dart';


/// Écran Gestion Restaurants Admin Amélioré
/// - Liste complète avec stats
/// - Filtrage (tous, actifs, inactifs) et Recherche (nom, tel)
/// - Activer/Désactiver/Suspendre
/// - Fiche détaillée complète
class RestaurantsManagementScreen extends StatefulWidget {
  const RestaurantsManagementScreen({super.key});

  @override
  State<RestaurantsManagementScreen> createState() => _RestaurantsManagementScreenState();
}

class _RestaurantsManagementScreenState extends State<RestaurantsManagementScreen> {
  List<Map<String, dynamic>> _restaurants = [];
  bool _isLoading = true;
  String _filter = 'all'; // all, active, red_flag
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRestaurants() async {
    setState(() => _isLoading = true);
    try {
      final restaurants = await SupabaseService.getAllRestaurantsWithStats();
      setState(() {
        _restaurants = restaurants;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
      }
    }
  }

  List<Map<String, dynamic>> get _filteredRestaurants {
    var list = _restaurants;
    
    // Filtrage statut
    if (_filter == 'active') {
      list = list.where((r) => r['is_verified'] == true).toList();
    } else if (_filter == 'red_flag') {
       list = list.where((r) => 
        (r['stats']?['net_revenue'] ?? 0) > 100000 || // Gros revenus
        (r['rating'] as num?) != null && (r['rating'] as num) < 3.0 // Mauvaise note
       ).toList();
    }

    // Recherche
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list.where((r) {
        final name = (r['name'] ?? '').toString().toLowerCase();
        final phone = (r['phone'] ?? '').toString().toLowerCase();
        return name.contains(query) || phone.contains(query);
      }).toList();
    }
    
    return list;
  }

  Future<void> _toggleStatus(String restaurantId, bool currentStatus) async {
    try {
      if (currentStatus) {
        // Dialogue suspension
        final reason = await showDialog<String>(context: context, builder: (ctx) => _SuspensionDialog());
        if (reason == null) return;
        await SupabaseService.suspendRestaurant(restaurantId, reason);
      } else {
        await SupabaseService.verifyRestaurant(restaurantId);
      }
      
      await _loadRestaurants();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Statut mis à jour'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _callRestaurant(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        title: const Text('Restaurants', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRestaurants,
          ),
        ],
      ),
      body: Column(
        children: [
          // Recherche
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Rechercher (nom, téléphone)...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF1B2838),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          // Filtres
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip('Tous', _filter == 'all', () => setState(() => _filter = 'all')),
                const SizedBox(width: 8),
                _FilterChip('Actifs', _filter == 'active', () => setState(() => _filter = 'active')),
                const SizedBox(width: 8),
                _FilterChip('⚠️ À surveiller', _filter == 'red_flag', () => setState(() => _filter = 'red_flag')),
              ],
            ),
          ),

          // Liste
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : _filteredRestaurants.isEmpty
                    ? const Center(child: Text('Aucun restaurant trouvé', style: TextStyle(color: Colors.white54)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredRestaurants.length,
                        itemBuilder: (context, index) {
                          final restaurant = _filteredRestaurants[index];
                          return _RestaurantCard(
                            restaurant: restaurant,
                            onToggle: () => _toggleStatus(restaurant['id'], restaurant['is_verified'] ?? false),
                            onCall: () => _callRestaurant(restaurant['phone'] ?? ''),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _SuspensionDialog extends StatelessWidget {
  final TextEditingController _reasonController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1B2838),
      title: const Text('Suspendre le restaurant', style: TextStyle(color: Colors.white)),
      content: TextField(
        controller: _reasonController,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'Motif de la suspension...',
          hintStyle: TextStyle(color: Colors.white38),
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(context, _reasonController.text),
          child: const Text('Suspendre'),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip(this.label, this.isSelected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange : const Color(0xFF1B2838),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.orange : Colors.white12),
        ),
        child: Text(
          label,
          style: TextStyle(color: isSelected ? Colors.white : Colors.white54, fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
        ),
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  final Map<String, dynamic> restaurant;
  final VoidCallback onToggle;
  final VoidCallback onCall;

  const _RestaurantCard({required this.restaurant, required this.onToggle, required this.onCall});

  @override
  Widget build(BuildContext context) {
    final isActive = restaurant['is_verified'] ?? false;
    final stats = restaurant['stats'] ?? {};
    final rating = (restaurant['rating'] as num?)?.toDouble() ?? 0.0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2838),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ExpansionTile(
        shape: const Border(),
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        tilePadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: isActive ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
          child: Icon(Icons.restaurant, color: isActive ? Colors.green : Colors.red),
        ),
        title: Text(restaurant['name'] ?? 'Inconnu', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(restaurant['phone'] ?? '', style: const TextStyle(color: Colors.white54, fontSize: 12)),
             Row(
                children: [
                  Icon(Icons.star, size: 14, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text('$rating', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(width: 12),
                  Text('${stats['total_orders'] ?? 0} commandes', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                ],
             ),
          ],
        ),
        trailing: Switch(
          value: isActive,
          activeColor: Colors.green,
          onChanged: (v) => onToggle(),
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black12,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _StatBox(' Revenus', '${stats['total_revenue'] ?? 0} DA', Colors.green)),
                    const SizedBox(width: 8),
                    Expanded(child: _StatBox('Commission', '${stats['total_commission'] ?? 0} DA', Colors.blue)),
                    const SizedBox(width: 8),
                     Expanded(child: _StatBox('Commandes', '${stats['total_orders'] ?? 0}', Colors.orange)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      onPressed: onCall,
                      icon: const Icon(Icons.phone, color: Colors.white70),
                      label: const Text('Appeler', style: TextStyle(color: Colors.white70)),
                    ),
                    TextButton.icon(
                      onPressed: () { /* TODO: Historique */ },
                      icon: const Icon(Icons.history, color: Colors.white70),
                      label: const Text('Historique', style: TextStyle(color: Colors.white70)),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color.withOpacity(0.8), fontSize: 10)),
        ],
      ),
    );
  }
}
