/// ============================================================
/// USER PROVIDER - Gestion globale du profil utilisateur
/// ============================================================
/// 
/// Synchronisé avec SOURCE_DE_VERITE.sql
/// Table: profiles
/// 
/// Colonnes utilisées:
/// - id, role, phone, full_name, avatar_url, address
/// - latitude, longitude, is_active, loyalty_points
/// - total_orders, total_spent, referral_code
/// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/supabase_service.dart';
import '../core/models/database_models.dart';

/// État du profil utilisateur
class UserState {
  final ProfileModel? profile;
  final bool isLoading;
  final String? error;

  const UserState({
    this.profile,
    this.isLoading = false,
    this.error,
  });

  bool get isLoggedIn => profile != null;
  String? get userId => profile?.id;
  UserRole? get role => profile?.role;
  String? get fullName => profile?.fullName;
  String? get phone => profile?.phone;
  String? get avatarUrl => profile?.avatarUrl;

  UserState copyWith({
    ProfileModel? profile,
    bool? isLoading,
    String? error,
  }) {
    return UserState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier pour gérer le profil utilisateur
class UserNotifier extends StateNotifier<UserState> {
  UserNotifier() : super(const UserState());

  /// Charger le profil depuis Supabase
  Future<void> loadProfile() async {
    if (SupabaseService.currentUser == null) {
      state = const UserState();
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final profileData = await SupabaseService.getProfile();
      if (profileData != null) {
        state = UserState(
          profile: ProfileModel.fromJson(profileData),
          isLoading: false,
        );
      } else {
        state = const UserState(isLoading: false);
      }
    } catch (e) {
      state = UserState(isLoading: false, error: e.toString());
    }
  }

  /// Mettre à jour le profil localement (après modification)
  void updateProfile(ProfileModel profile) {
    state = state.copyWith(profile: profile);
  }

  /// Déconnecter l'utilisateur
  Future<void> logout() async {
    await SupabaseService.signOut();
    state = const UserState();
  }

  /// Rafraîchir le profil
  Future<void> refresh() async {
    await loadProfile();
  }
}

/// Provider global du profil utilisateur
final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier();
});

/// Provider pour vérifier si l'utilisateur est connecté
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(userProvider).isLoggedIn;
});

/// Provider pour le rôle de l'utilisateur
final userRoleProvider = Provider<UserRole?>((ref) {
  return ref.watch(userProvider).role;
});
