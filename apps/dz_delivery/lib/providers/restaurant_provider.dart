/// ============================================================
/// RESTAURANT PROVIDER - Gestion globale de l'état restaurant
/// ============================================================
/// 
/// Synchronisé avec SOURCE_DE_VERITE.sql
/// Tables: restaurants, orders, profiles
/// 
/// restaurants:
/// - id, owner_id, name, is_open, is_verified
/// - rating, total_reviews, avg_prep_time
/// 
/// orders (pour pendingOrders):
/// - restaurant_id
/// - status IN ('pending', 'confirmed', 'preparing', 'ready')
/// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/supabase_service.dart';
import '../core/models/database_models.dart';

/// État du restaurant
class RestaurantState {
  final RestaurantModel? restaurant;
  final List<Map<String, dynamic>> pendingOrders;
  final Map<String, dynamic> stats;
  final bool isOpen;
  final bool isLoading;
  final String? error;

  const RestaurantState({
    this.restaurant,
    this.pendingOrders = const [],
    this.stats = const {},
    this.isOpen = false,
    this.isLoading = false,
    this.error,
  });

  String? get restaurantId => restaurant?.id;
  String? get restaurantName => restaurant?.name;
  int get pendingOrdersCount => pendingOrders.length;

  RestaurantState copyWith({
    RestaurantModel? restaurant,
    List<Map<String, dynamic>>? pendingOrders,
    Map<String, dynamic>? stats,
    bool? isOpen,
    bool? isLoading,
    String? error,
  }) {
    return RestaurantState(
      restaurant: restaurant ?? this.restaurant,
      pendingOrders: pendingOrders ?? this.pendingOrders,
      stats: stats ?? this.stats,
      isOpen: isOpen ?? this.isOpen,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier pour gérer l'état restaurant
class RestaurantNotifier extends StateNotifier<RestaurantState> {
  RestaurantNotifier() : super(const RestaurantState());

  /// Charger toutes les données restaurant
  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final restaurantData = await SupabaseService.getMyRestaurant();
      
      if (restaurantData == null) {
        state = const RestaurantState(isLoading: false, error: 'Restaurant non trouvé');
        return;
      }

      final pendingOrders = await SupabaseService.getRestaurantPendingOrders();
      final stats = await SupabaseService.getRestaurantStats();

      state = RestaurantState(
        restaurant: RestaurantModel.fromJson(restaurantData),
        pendingOrders: pendingOrders,
        stats: stats,
        isOpen: restaurantData['is_open'] ?? false,
        isLoading: false,
      );
    } catch (e) {
      state = RestaurantState(isLoading: false, error: e.toString());
    }
  }

  /// Toggle statut ouvert/fermé
  Future<void> toggleOpen(bool value) async {
    final previousValue = state.isOpen;
    state = state.copyWith(isOpen: value);

    try {
      await SupabaseService.setRestaurantOpen(value);
    } catch (e) {
      // Rollback
      state = state.copyWith(isOpen: previousValue, error: e.toString());
    }
  }

  /// Mettre à jour les commandes en attente
  void setPendingOrders(List<Map<String, dynamic>> orders) {
    state = state.copyWith(pendingOrders: orders);
  }

  /// Ajouter une nouvelle commande (depuis realtime)
  void addPendingOrder(Map<String, dynamic> order) {
    state = state.copyWith(
      pendingOrders: [order, ...state.pendingOrders],
    );
  }

  /// Supprimer une commande (après traitement)
  void removePendingOrder(String orderId) {
    state = state.copyWith(
      pendingOrders: state.pendingOrders.where((o) => o['id'] != orderId).toList(),
    );
  }

  /// Mettre à jour une commande
  void updatePendingOrder(Map<String, dynamic> updatedOrder) {
    final orderId = updatedOrder['id'];
    state = state.copyWith(
      pendingOrders: state.pendingOrders.map((o) {
        if (o['id'] == orderId) return updatedOrder;
        return o;
      }).toList(),
    );
  }

  /// Rafraîchir les données
  Future<void> refresh() async {
    await loadAll();
  }

  /// Rafraîchir seulement les commandes
  Future<void> refreshPendingOrders() async {
    try {
      final orders = await SupabaseService.getRestaurantPendingOrders();
      state = state.copyWith(pendingOrders: orders);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Rafraîchir seulement les stats
  Future<void> refreshStats() async {
    try {
      final stats = await SupabaseService.getRestaurantStats();
      state = state.copyWith(stats: stats);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

/// Provider global de l'état restaurant
final restaurantProvider = StateNotifierProvider<RestaurantNotifier, RestaurantState>((ref) {
  return RestaurantNotifier();
});

/// Provider pour le statut ouvert/fermé
final restaurantIsOpenProvider = Provider<bool>((ref) {
  return ref.watch(restaurantProvider).isOpen;
});

/// Provider pour les commandes en attente
final pendingOrdersProvider = Provider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(restaurantProvider).pendingOrders;
});

/// Provider pour le nombre de commandes en attente
final pendingOrdersCountProvider = Provider<int>((ref) {
  return ref.watch(restaurantProvider).pendingOrdersCount;
});

/// Provider pour les stats
final restaurantStatsProvider = Provider<Map<String, dynamic>>((ref) {
  return ref.watch(restaurantProvider).stats;
});
