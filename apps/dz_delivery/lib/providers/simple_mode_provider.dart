import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider pour gérer le Mode Simple
/// Active une interface simplifiée pour les utilisateurs non-tech
final simpleModeProvider = NotifierProvider<SimpleModeNotifier, SimpleModeState>(
  SimpleModeNotifier.new,
);

class SimpleModeState {
  final bool clientSimpleMode;
  final bool restaurantSimpleMode;
  final bool isLoaded;

  const SimpleModeState({
    this.clientSimpleMode = false,
    this.restaurantSimpleMode = false,
    this.isLoaded = false,
  });

  SimpleModeState copyWith({
    bool? clientSimpleMode,
    bool? restaurantSimpleMode,
    bool? isLoaded,
  }) {
    return SimpleModeState(
      clientSimpleMode: clientSimpleMode ?? this.clientSimpleMode,
      restaurantSimpleMode: restaurantSimpleMode ?? this.restaurantSimpleMode,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

class SimpleModeNotifier extends Notifier<SimpleModeState> {
  static const _clientKey = 'simple_mode_client';
  static const _restaurantKey = 'simple_mode_restaurant';

  @override
  SimpleModeState build() {
    _load();
    return const SimpleModeState();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = SimpleModeState(
      clientSimpleMode: prefs.getBool(_clientKey) ?? false,
      restaurantSimpleMode: prefs.getBool(_restaurantKey) ?? false,
      isLoaded: true,
    );
  }

  Future<void> toggleClientMode() async {
    final newValue = !state.clientSimpleMode;
    state = state.copyWith(clientSimpleMode: newValue);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_clientKey, newValue);
  }

  Future<void> toggleRestaurantMode() async {
    final newValue = !state.restaurantSimpleMode;
    state = state.copyWith(restaurantSimpleMode: newValue);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_restaurantKey, newValue);
  }
}
