/// ============================================================
/// LIVREUR PROVIDER - Gestion globale de l'état livreur
/// ============================================================
/// 
/// Synchronisé avec SOURCE_DE_VERITE.sql
/// Tables: livreurs, orders, profiles
/// 
/// livreurs:
/// - id, user_id, vehicle_type, is_available, is_online, is_verified
/// - rating, total_deliveries, total_earnings, tier, tier_progress
/// - current_latitude, current_longitude
/// 
/// orders (pour currentDelivery):
/// - livreur_id (⚠️ PAS driver_id)
/// - status IN ('confirmed', 'preparing', 'ready', 'picked_up', 'delivering')
/// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/supabase_service.dart';
import '../core/models/database_models.dart';

/// État du livreur
class LivreurState {
  final LivreurModel? profile;
  final ProfileModel? userProfile;
  final Map<String, dynamic>? currentDelivery;
  final List<Map<String, dynamic>> availableOrders;
  final Map<String, dynamic>? todayStats;
  final Map<String, dynamic>? tierInfo;
  final bool isOnline;
  final bool isLoading;
  final String? error;

  const LivreurState({
    this.profile,
    this.userProfile,
    this.currentDelivery,
    this.availableOrders = const [],
    this.todayStats,
    this.tierInfo,
    this.isOnline = false,
    this.isLoading = false,
    this.error,
  });

  bool get hasCurrentDelivery => currentDelivery != null;
  String? get livreurId => profile?.id;
  double get rating => profile?.rating ?? 5.0;
  int get totalDeliveries => profile?.totalDeliveries ?? 0;
  double get totalEarnings => profile?.totalEarnings ?? 0;
  LivreurTier get tier => profile?.tier ?? LivreurTier.bronze;

  LivreurState copyWith({
    LivreurModel? profile,
    ProfileModel? userProfile,
    Map<String, dynamic>? currentDelivery,
    List<Map<String, dynamic>>? availableOrders,
    Map<String, dynamic>? todayStats,
    Map<String, dynamic>? tierInfo,
    bool? isOnline,
    bool? isLoading,
    String? error,
  }) {
    return LivreurState(
      profile: profile ?? this.profile,
      userProfile: userProfile ?? this.userProfile,
      currentDelivery: currentDelivery ?? this.currentDelivery,
      availableOrders: availableOrders ?? this.availableOrders,
      todayStats: todayStats ?? this.todayStats,
      tierInfo: tierInfo ?? this.tierInfo,
      isOnline: isOnline ?? this.isOnline,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier pour gérer l'état livreur
class LivreurNotifier extends StateNotifier<LivreurState> {
  LivreurNotifier() : super(const LivreurState());

  /// Charger toutes les données livreur
  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final results = await Future.wait([
        SupabaseService.getLivreurProfile(),
        SupabaseService.getProfile(),
        _safeCall(() => SupabaseService.getCurrentDelivery(), null),
        _safeCall(() => SupabaseService.getAvailableOrders(), <Map<String, dynamic>>[]),
        _safeCall(() => SupabaseService.getLivreurTodayStats(), <String, dynamic>{}),
        _safeCall(() => SupabaseService.getLivreurTierInfo(), <String, dynamic>{}),
      ]);

      final livreurData = results[0] as Map<String, dynamic>?;
      final profileData = results[1] as Map<String, dynamic>?;

      state = LivreurState(
        profile: livreurData != null ? LivreurModel.fromJson(livreurData) : null,
        userProfile: profileData != null ? ProfileModel.fromJson(profileData) : null,
        currentDelivery: results[2] as Map<String, dynamic>?,
        availableOrders: results[3] as List<Map<String, dynamic>>,
        todayStats: results[4] as Map<String, dynamic>,
        tierInfo: results[5] as Map<String, dynamic>,
        isOnline: livreurData?['is_online'] ?? false,
        isLoading: false,
      );
    } catch (e) {
      state = LivreurState(isLoading: false, error: e.toString());
    }
  }

  Future<T> _safeCall<T>(Future<T> Function() call, T defaultValue) async {
    try {
      return await call();
    } catch (e) {
      return defaultValue;
    }
  }

  /// Toggle statut online/offline
  Future<void> toggleOnline(bool value) async {
    final previousValue = state.isOnline;
    state = state.copyWith(isOnline: value);

    try {
      await SupabaseService.setOnlineStatus(value);
      
      // Recharger les commandes disponibles si online
      if (value) {
        final orders = await SupabaseService.getAvailableOrders();
        state = state.copyWith(availableOrders: orders);
      }
    } catch (e) {
      // Rollback
      state = state.copyWith(isOnline: previousValue, error: e.toString());
    }
  }

  /// Mettre à jour la livraison en cours
  void setCurrentDelivery(Map<String, dynamic>? delivery) {
    state = state.copyWith(currentDelivery: delivery);
  }

  /// Mettre à jour les commandes disponibles
  void setAvailableOrders(List<Map<String, dynamic>> orders) {
    state = state.copyWith(availableOrders: orders);
  }

  /// Accepter une commande
  Future<void> acceptOrder(String orderId) async {
    try {
      await SupabaseService.acceptOrder(orderId);
      
      // Recharger les données
      await loadAll();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Rafraîchir les données
  Future<void> refresh() async {
    await loadAll();
  }

  /// Rafraîchir seulement les commandes disponibles
  Future<void> refreshAvailableOrders() async {
    try {
      final orders = await SupabaseService.getAvailableOrders();
      state = state.copyWith(availableOrders: orders);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

/// Provider global de l'état livreur
final livreurProvider = StateNotifierProvider<LivreurNotifier, LivreurState>((ref) {
  return LivreurNotifier();
});

/// Provider pour le statut online
final livreurIsOnlineProvider = Provider<bool>((ref) {
  return ref.watch(livreurProvider).isOnline;
});

/// Provider pour la livraison en cours
final currentDeliveryProvider = Provider<Map<String, dynamic>?>((ref) {
  return ref.watch(livreurProvider).currentDelivery;
});

/// Provider pour les commandes disponibles
final availableOrdersProvider = Provider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(livreurProvider).availableOrders;
});
