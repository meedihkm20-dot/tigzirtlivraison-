import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/widgets/osm_map.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  List<Map<String, dynamic>> _restaurants = [];
  bool _isLoading = true;
  String _userAddress = 'Chargement...';
  
  // Position utilisateur
  LatLng? _userPosition;
  bool _isMapView = false;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    setState(() => _isLoading = true);
    
    try {
      // Demander permission GPS
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        // Obtenir position actuelle
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
        
        setState(() {
          _userPosition = LatLng(position.latitude, position.longitude);
        });
        
        // Mettre à jour le profil avec la position
        await SupabaseService.updateProfile({
          'latitude': position.latitude,
          'longitude': position.longitude,
        });
      } else {
        // Position par défaut: Tigzirt
        setState(() {
          _userPosition = const LatLng(36.8869, 4.1260);
        });
      }
      
      // Charger le profil pour l'adresse
      final profile = await SupabaseService.getProfile();
      if (profile != null && profile['address'] != null) {
        _userAddress = profile['address'];
      } else {
        _userAddress = 'Tigzirt, Algérie';
      }
      
      // Charger les restaurants
      await _loadRestaurants();
      
    } catch (e) {
      debugPrint('Erreur localisation: $e');
      // Position par défaut
      setState(() {
        _userPosition = const LatLng(36.8869, 4.1260);
        _userAddress = 'Tigzirt, Algérie';
      });
      await _loadRestaurants();
    }
  }

  Future<void> _loadRestaurants() async {
    if (_userPosition == null) return;
    
    try {
      final restaurants = await SupabaseService.getNearbyRestaurants(
        latitude: _userPosition!.latitude,
        longitude: _userPosition!.longitude,
        radiusKm: 15,
      );
      setState(() {
        _restaurants = restaurants;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erreur chargement restaurants: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchRestaurants(String query) async {
    if (query.isEmpty) {
      _loadRestaurants();
      return;
    }
    try {
      final results = await SupabaseService.searchRestaurants(query);
      setState(() => _restaurants = results);
    } catch (e) {
      debugPrint('Erreur recherche: $e');
    }
  }

  void _goToRestaurant(String restaurantId) {
    Navigator.pushNamed(context, AppRouter.restaurantDetail, arguments: restaurantId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => _showAddressSelector(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Livrer à', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, size: 16, color: Color(0xFFFF6B35)),
                  const SizedBox(width: 4),
                  Text(_userAddress, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const Icon(Icons.keyboard_arrow_down, size: 16),
                ],
              ),
            ],
          ),
        ),
        actions: [
          // Toggle carte/liste
          IconButton(
            icon: Icon(_isMapView ? Icons.list : Icons.map),
            onPressed: () => setState(() => _isMapView = !_isMapView),
            tooltip: _isMapView ? 'Vue liste' : 'Vue carte',
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => Navigator.pushNamed(context, AppRouter.cart),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35)))
          : _isMapView ? _buildMapView() : _buildListView(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFFFF6B35),
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 1) Navigator.pushNamed(context, AppRouter.orders);
          if (index == 2) Navigator.pushNamed(context, AppRouter.profile);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Commandes'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  /// Vue carte avec restaurants
  Widget _buildMapView() {
    if (_userPosition == null) {
      return const Center(child: Text('Position non disponible'));
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _userPosition!,
            initialZoom: 14,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.dzdelivery.customer',
            ),
            MarkerLayer(
              markers: [
                // Position utilisateur
                Marker(
                  point: _userPosition!,
                  width: 40,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.3),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blue, width: 3),
                    ),
                    child: const Icon(Icons.person, color: Colors.blue, size: 20),
                  ),
                ),
                // Restaurants
                ..._restaurants.map((r) => _buildRestaurantMarker(r)),
              ],
            ),
          ],
        ),
        // Bouton recentrer
        Positioned(
          bottom: 100,
          right: 16,
          child: FloatingActionButton.small(
            heroTag: 'center',
            backgroundColor: Colors.white,
            onPressed: () {
              if (_userPosition != null) {
                _mapController.move(_userPosition!, 14);
              }
            },
            child: const Icon(Icons.my_location, color: Color(0xFFFF6B35)),
          ),
        ),
        // Liste en bas
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    '${_restaurants.length} restaurants à proximité',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _restaurants.length,
                    itemBuilder: (context, index) => _buildRestaurantChip(_restaurants[index]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Marker _buildRestaurantMarker(Map<String, dynamic> restaurant) {
    final lat = (restaurant['latitude'] as num?)?.toDouble() ?? 36.8869;
    final lng = (restaurant['longitude'] as num?)?.toDouble() ?? 4.1260;
    final isOpen = restaurant['is_open'] ?? false;
    
    return Marker(
      point: LatLng(lat, lng),
      width: 50,
      height: 60,
      child: GestureDetector(
        onTap: () => _goToRestaurant(restaurant['id']),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isOpen ? const Color(0xFFFF6B35) : Colors.grey,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)],
              ),
              child: const Icon(Icons.restaurant, color: Colors.white, size: 20),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 2)],
              ),
              child: Text(
                restaurant['name'] ?? '',
                style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantChip(Map<String, dynamic> restaurant) {
    final isOpen = restaurant['is_open'] ?? false;
    
    return GestureDetector(
      onTap: () => _goToRestaurant(restaurant['id']),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12, bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                image: restaurant['logo_url'] != null
                    ? DecorationImage(image: NetworkImage(restaurant['logo_url']), fit: BoxFit.cover)
                    : null,
              ),
              child: restaurant['logo_url'] == null
                  ? const Center(child: Icon(Icons.restaurant, color: Colors.grey))
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          restaurant['name'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isOpen ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 12, color: Colors.amber),
                      Text(' ${(restaurant['rating'] ?? 0).toStringAsFixed(1)}', style: const TextStyle(fontSize: 10)),
                      if (restaurant['distance_km'] != null) ...[
                        const Text(' • ', style: TextStyle(fontSize: 10)),
                        Text('${(restaurant['distance_km'] as num).toStringAsFixed(1)} km', style: const TextStyle(fontSize: 10)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Vue liste classique
  Widget _buildListView() {
    return RefreshIndicator(
      onRefresh: _loadRestaurants,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                onChanged: (v) => _searchRestaurants(v),
                decoration: InputDecoration(
                  hintText: 'Rechercher un restaurant...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Catégories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildCategoryItem(Icons.fastfood, 'Fast Food'),
                  _buildCategoryItem(Icons.local_pizza, 'Pizza'),
                  _buildCategoryItem(Icons.restaurant, 'Traditionnel'),
                  _buildCategoryItem(Icons.cake, 'Desserts'),
                  _buildCategoryItem(Icons.local_cafe, 'Café'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Restaurants populaires', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: () => setState(() => _isMapView = true),
                    icon: const Icon(Icons.map, size: 16),
                    label: const Text('Carte'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_restaurants.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.restaurant, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('Aucun restaurant trouvé', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _restaurants.length,
                itemBuilder: (context, index) => _buildRestaurantCard(context, _restaurants[index]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(IconData icon, String label) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(color: const Color(0xFFFF6B35).withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: const Color(0xFFFF6B35), size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildRestaurantCard(BuildContext context, Map<String, dynamic> restaurant) {
    final isOpen = restaurant['is_open'] ?? false;
    
    return GestureDetector(
      onTap: () => _goToRestaurant(restaurant['id']),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    image: restaurant['logo_url'] != null
                        ? DecorationImage(image: NetworkImage(restaurant['logo_url']), fit: BoxFit.cover)
                        : null,
                  ),
                  child: restaurant['logo_url'] == null
                      ? const Center(child: Icon(Icons.restaurant, size: 50, color: Colors.grey))
                      : null,
                ),
                if (!isOpen)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: const Center(
                        child: Text('FERMÉ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(restaurant['name'] ?? 'Restaurant', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isOpen ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isOpen ? 'Ouvert' : 'Fermé',
                          style: TextStyle(color: isOpen ? Colors.green : Colors.red, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  if (restaurant['cuisine_type'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(restaurant['cuisine_type'], style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      Text(' ${(restaurant['rating'] ?? 0).toStringAsFixed(1)} ', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      const Icon(Icons.access_time, size: 16, color: Colors.grey),
                      Text(' ${restaurant['avg_prep_time'] ?? 30} min', style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(width: 12),
                      if (restaurant['distance_km'] != null)
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16, color: Colors.grey),
                            Text(' ${(restaurant['distance_km'] as num).toStringAsFixed(1)} km', style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddressSelector() {
    // TODO: Implémenter sélecteur d'adresse
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sélecteur d\'adresse à venir')),
    );
  }
}
