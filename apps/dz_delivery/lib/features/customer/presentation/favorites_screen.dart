import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../providers/favorites_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    // Charger les favoris au démarrage
    Future.microtask(() {
      ref.read(favoritesProvider.notifier).loadFavorites();
    });
  }

  Future<void> _removeFavorite(String restaurantId) async {
    try {
      await ref.read(favoritesProvider.notifier).toggleRestaurantFavorite(restaurantId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Retiré des favoris'), duration: Duration(seconds: 1)),
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

  @override
  Widget build(BuildContext context) {
    final favoritesState = ref.watch(favoritesProvider);
    final favorites = favoritesState.favoriteRestaurants;
    final isLoading = favoritesState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Favoris ❤️'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : favorites.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('Aucun favori', style: TextStyle(color: Colors.grey[600], fontSize: 18)),
                      const SizedBox(height: 8),
                      Text(
                        'Ajoutez des restaurants à vos favoris\npour les retrouver facilement',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => ref.read(favoritesProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: favorites.length,
                    itemBuilder: (context, index) {
                      final fav = favorites[index];
                      final restaurant = fav['restaurant'] as Map<String, dynamic>?;
                      if (restaurant == null) return const SizedBox();
                      
                      return Dismissible(
                        key: Key(fav['id']?.toString() ?? index.toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => _removeFavorite(restaurant['id']),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRouter.restaurantDetail,
                              arguments: restaurant['id'],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  // Logo
                                  Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                      image: restaurant['logo_url'] != null
                                          ? DecorationImage(
                                              image: CachedNetworkImageProvider(restaurant['logo_url']),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: restaurant['logo_url'] == null
                                        ? Center(
                                            child: Text(
                                              (restaurant['name'] ?? 'R')[0].toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 28,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.primaryColor,
                                              ),
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  
                                  // Infos
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          restaurant['name'] ?? '',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          restaurant['cuisine_type'] ?? 'Restaurant',
                                          style: TextStyle(color: Colors.grey[600]),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.star, color: Colors.amber, size: 16),
                                            Text(
                                              ' ${(restaurant['rating'] ?? 0).toStringAsFixed(1)}',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              ' (${restaurant['total_reviews'] ?? 0})',
                                              style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Bouton favori
                                  IconButton(
                                    icon: const Icon(Icons.favorite, color: Colors.red),
                                    onPressed: () => _removeFavorite(restaurant['id']),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
