/// ============================================================
/// ADDRESSES PROVIDER - Gestion globale des adresses sauvegardées
/// ============================================================
/// 
/// Synchronisé avec SOURCE_DE_VERITE.sql
/// Table: saved_addresses
/// 
/// Colonnes:
/// - id, customer_id, label, address
/// - latitude, longitude (⚠️ DECIMAL(10,7) dans SQL)
/// - instructions, is_default, created_at
/// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/supabase_service.dart';

/// Modèle d'adresse sauvegardée (aligné sur saved_addresses SQL)
class SavedAddress {
  final String id;
  final String customerId;
  final String label;
  final String address;
  final double latitude;   // ⚠️ SQL: latitude DECIMAL(10,7)
  final double longitude;  // ⚠️ SQL: longitude DECIMAL(10,7)
  final String? instructions;
  final bool isDefault;
  final DateTime createdAt;

  const SavedAddress({
    required this.id,
    required this.customerId,
    required this.label,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.instructions,
    this.isDefault = false,
    required this.createdAt,
  });

  factory SavedAddress.fromJson(Map<String, dynamic> json) {
    return SavedAddress(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      label: json['label'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      instructions: json['instructions'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'customer_id': customerId,
    'label': label,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'instructions': instructions,
    'is_default': isDefault,
    'created_at': createdAt.toIso8601String(),
  };

  /// Pour l'affichage du type d'adresse
  String get typeIcon {
    final lowerLabel = label.toLowerCase();
    if (lowerLabel.contains('maison') || lowerLabel.contains('home')) return 'home';
    if (lowerLabel.contains('travail') || lowerLabel.contains('work')) return 'work';
    return 'location';
  }
}

/// État des adresses
class AddressesState {
  final List<SavedAddress> addresses;
  final SavedAddress? selectedAddress;
  final bool isLoading;
  final String? error;

  const AddressesState({
    this.addresses = const [],
    this.selectedAddress,
    this.isLoading = false,
    this.error,
  });

  bool get isEmpty => addresses.isEmpty;
  bool get hasDefault => addresses.any((a) => a.isDefault);

  AddressesState copyWith({
    List<SavedAddress>? addresses,
    SavedAddress? selectedAddress,
    bool? isLoading,
    String? error,
  }) {
    return AddressesState(
      addresses: addresses ?? this.addresses,
      selectedAddress: selectedAddress ?? this.selectedAddress,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier pour gérer les adresses (Riverpod 3.x)
class AddressesNotifier extends Notifier<AddressesState> {
  @override
  AddressesState build() => const AddressesState();

  /// Charger les adresses depuis Supabase
  Future<void> loadAddresses() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final addressesData = await SupabaseService.getSavedAddresses();
      final addresses = addressesData
          .map((json) => SavedAddress.fromJson(json))
          .toList();

      // Sélectionner l'adresse par défaut ou la première
      SavedAddress? selected;
      if (addresses.isNotEmpty) {
        selected = addresses.firstWhere(
          (a) => a.isDefault,
          orElse: () => addresses.first,
        );
      }

      state = AddressesState(
        addresses: addresses,
        selectedAddress: selected,
        isLoading: false,
      );
    } catch (e) {
      state = AddressesState(isLoading: false, error: e.toString());
    }
  }

  /// Sélectionner une adresse
  void selectAddress(SavedAddress address) {
    state = state.copyWith(selectedAddress: address);
  }

  /// Sélectionner par ID
  void selectAddressById(String addressId) {
    final address = state.addresses.firstWhere(
      (a) => a.id == addressId,
      orElse: () => state.addresses.first,
    );
    selectAddress(address);
  }

  /// Ajouter une adresse (après création en base)
  void addAddress(SavedAddress address) {
    state = state.copyWith(
      addresses: [...state.addresses, address],
      selectedAddress: state.selectedAddress ?? address,
    );
  }

  /// Supprimer une adresse
  void removeAddress(String addressId) {
    final updatedAddresses = state.addresses
        .where((a) => a.id != addressId)
        .toList();

    SavedAddress? newSelected = state.selectedAddress;
    if (state.selectedAddress?.id == addressId) {
      newSelected = updatedAddresses.isNotEmpty ? updatedAddresses.first : null;
    }

    state = state.copyWith(
      addresses: updatedAddresses,
      selectedAddress: newSelected,
    );
  }

  /// Rafraîchir les adresses
  Future<void> refresh() async {
    await loadAddresses();
  }
}

/// Provider global des adresses (Riverpod 3.x)
final addressesProvider = NotifierProvider<AddressesNotifier, AddressesState>(AddressesNotifier.new);

/// Provider pour l'adresse sélectionnée
final selectedAddressProvider = Provider<SavedAddress?>((ref) {
  return ref.watch(addressesProvider).selectedAddress;
});

/// Provider pour vérifier si des adresses existent
final hasAddressesProvider = Provider<bool>((ref) {
  return !ref.watch(addressesProvider).isEmpty;
});
