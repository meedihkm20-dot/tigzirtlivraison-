/// ============================================================
/// FAVORITES PROVIDER - Gestion globale des favoris
/// ============================================================
/// 
/// Synchronisé avec SOURCE_DE_VERITE.sql
/// Tables: favorites, favorite_items
/// 
/// favorites:
/// - id, customer_id, restaurant_id, created_at
/// - UNIQUE(customer_id, restaurant_id)
/// 
/// favorite_items:
/// - id, customer_id, menu_item_id, created_at
/// - UNIQUE(customer_id, menu_item_id)
/// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/supabase_service.dart';

/// État des favoris
class FavoritesState {
  final Set<String> favoriteRestaurantIds;
  final Set<String> favoriteItemIds;
  final List<Map<String, dynamic>> favoriteRestaurants; // Données complètes
  final bool isLoading;
  final String? error;

  const FavoritesState({
    this.favoriteRestaurantIds = const {},
    this.favoriteItemIds = const {},
    this.favoriteRestaurants = const [],
    this.isLoading = false,
    this.error,
  });

  bool isRestaurantFavorite(String restaurantId) {
    return favoriteRestaurantIds.contains(restaurantId);
  }

  bool isItemFavorite(String menuItemId) {
    return favoriteItemIds.contains(menuItemId);
  }

  FavoritesState copyWith({
    Set<String>? favoriteRestaurantIds,
    Set<String>? favoriteItemIds,
    List<Map<String, dynamic>>? favoriteRestaurants,
    bool? isLoading,
    String? error,
  }) {
    return FavoritesState(
      favoriteRestaurantIds: favoriteRestaurantIds ?? this.favoriteRestaurantIds,
      favoriteItemIds: favoriteItemIds ?? this.favoriteItemIds,
      favoriteRestaurants: favoriteRestaurants ?? this.favoriteRestaurants,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier pour gérer les favoris (Riverpod 3.x)
class FavoritesNotifier extends Notifier<FavoritesState> {
  @override
  FavoritesState build() => const FavoritesState();

  /// Charger les favoris depuis Supabase
  Future<void> loadFavorites() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final favoritesData = await SupabaseService.getFavoriteRestaurants();
      final restaurantIds = favoritesData
          .map((f) => f['restaurant_id'] as String? ?? (f['restaurant'] as Map?)?['id'] as String?)
          .whereType<String>()
          .toSet();

      state = FavoritesState(
        favoriteRestaurantIds: restaurantIds,
        favoriteRestaurants: favoritesData,
        favoriteItemIds: const {},
        isLoading: false,
      );
    } catch (e) {
      state = FavoritesState(isLoading: false, error: e.toString());
    }
  }

  /// Toggle favori restaurant
  Future<void> toggleRestaurantFavorite(String restaurantId) async {
    final isFavorite = state.isRestaurantFavorite(restaurantId);
    
    // Mise à jour optimiste
    final updatedIds = Set<String>.from(state.favoriteRestaurantIds);
    final updatedRestaurants = List<Map<String, dynamic>>.from(state.favoriteRestaurants);
    
    if (isFavorite) {
      updatedIds.remove(restaurantId);
      updatedRestaurants.removeWhere((f) {
        final restId = f['restaurant_id'] as String? ?? (f['restaurant'] as Map?)?['id'] as String?;
        return restId == restaurantId;
      });
    } else {
      updatedIds.add(restaurantId);
    }
    state = state.copyWith(
      favoriteRestaurantIds: updatedIds,
      favoriteRestaurants: updatedRestaurants,
    );

    try {
      await SupabaseService.toggleFavoriteRestaurant(restaurantId);
      // Recharger pour avoir les données complètes si ajout
      if (!isFavorite) {
        await loadFavorites();
      }
    } catch (e) {
      // Rollback en cas d'erreur
      await loadFavorites();
      state = state.copyWith(error: e.toString());
    }
  }

  /// Vérifier si un restaurant est favori (synchrone, depuis le cache)
  bool isRestaurantFavorite(String restaurantId) {
    return state.isRestaurantFavorite(restaurantId);
  }

  /// Rafraîchir les favoris
  Future<void> refresh() async {
    await loadFavorites();
  }
}

/// Provider global des favoris (Riverpod 3.x)
final favoritesProvider = NotifierProvider<FavoritesNotifier, FavoritesState>(FavoritesNotifier.new);

/// Provider pour vérifier si un restaurant est favori
final isRestaurantFavoriteProvider = Provider.family<bool, String>((ref, restaurantId) {
  return ref.watch(favoritesProvider).isRestaurantFavorite(restaurantId);
});

/// Provider pour le nombre de favoris
final favoritesCountProvider = Provider<int>((ref) {
  return ref.watch(favoritesProvider).favoriteRestaurantIds.length;
});
