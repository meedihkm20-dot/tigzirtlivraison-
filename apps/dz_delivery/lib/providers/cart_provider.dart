/// ============================================================
/// CART PROVIDER - Gestion globale du panier
/// ============================================================
/// 
/// Synchronisé avec SOURCE_DE_VERITE.sql
/// Tables utilisées: menu_items, restaurants
/// 
/// ⚠️ Le panier n'est PAS stocké en base de données
/// Il est géré uniquement en mémoire Flutter
/// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/database_models.dart';

/// Item du panier (correspond à order_items lors de la création de commande)
class CartItem {
  final String menuItemId;
  final String restaurantId;
  final String restaurantName;
  final String name;
  final double price;
  final String? imageUrl;
  final int quantity;
  final String? specialInstructions;

  const CartItem({
    required this.menuItemId,
    required this.restaurantId,
    required this.restaurantName,
    required this.name,
    required this.price,
    this.imageUrl,
    this.quantity = 1,
    this.specialInstructions,
  });

  double get totalPrice => price * quantity;

  CartItem copyWith({
    String? menuItemId,
    String? restaurantId,
    String? restaurantName,
    String? name,
    double? price,
    String? imageUrl,
    int? quantity,
    String? specialInstructions,
  }) {
    return CartItem(
      menuItemId: menuItemId ?? this.menuItemId,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      name: name ?? this.name,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      quantity: quantity ?? this.quantity,
      specialInstructions: specialInstructions ?? this.specialInstructions,
    );
  }

  /// Convertir en format pour order_items (création commande)
  Map<String, dynamic> toOrderItem() => {
    'menu_item_id': menuItemId,
    'name': name,
    'price': price,
    'quantity': quantity,
    'special_instructions': specialInstructions,
  };

  /// Créer depuis un menu_item JSON (source de vérité)
  factory CartItem.fromMenuItem(Map<String, dynamic> menuItem, String restaurantId, String restaurantName) {
    return CartItem(
      menuItemId: menuItem['id'] as String,
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      name: menuItem['name'] as String,
      price: (menuItem['price'] as num).toDouble(),
      imageUrl: menuItem['image_url'] as String?,
    );
  }
}

/// État du panier
class CartState {
  final List<CartItem> items;
  final String? currentRestaurantId;
  final String? currentRestaurantName;

  const CartState({
    this.items = const [],
    this.currentRestaurantId,
    this.currentRestaurantName,
  });

  /// Nombre total d'articles
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  /// Sous-total (avant frais de livraison)
  double get subtotal => items.fold(0.0, (sum, item) => sum + item.totalPrice);

  /// Vérifier si le panier est vide
  bool get isEmpty => items.isEmpty;

  /// Vérifier si le panier contient des articles d'un restaurant différent
  bool hasItemsFromDifferentRestaurant(String restaurantId) {
    return currentRestaurantId != null && currentRestaurantId != restaurantId;
  }

  CartState copyWith({
    List<CartItem>? items,
    String? currentRestaurantId,
    String? currentRestaurantName,
  }) {
    return CartState(
      items: items ?? this.items,
      currentRestaurantId: currentRestaurantId ?? this.currentRestaurantId,
      currentRestaurantName: currentRestaurantName ?? this.currentRestaurantName,
    );
  }
}

/// Notifier pour gérer le panier (Riverpod 3.x)
class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() => const CartState();

  /// Ajouter un article au panier
  void addItem(CartItem item) {
    // Vérifier si c'est un restaurant différent
    if (state.currentRestaurantId != null && 
        state.currentRestaurantId != item.restaurantId) {
      // Vider le panier si restaurant différent
      state = CartState(
        items: [item],
        currentRestaurantId: item.restaurantId,
        currentRestaurantName: item.restaurantName,
      );
      return;
    }

    // Chercher si l'article existe déjà
    final existingIndex = state.items.indexWhere(
      (i) => i.menuItemId == item.menuItemId,
    );

    if (existingIndex != -1) {
      // Incrémenter la quantité
      final updatedItems = [...state.items];
      updatedItems[existingIndex] = updatedItems[existingIndex].copyWith(
        quantity: updatedItems[existingIndex].quantity + item.quantity,
      );
      state = state.copyWith(items: updatedItems);
    } else {
      // Ajouter nouvel article
      state = state.copyWith(
        items: [...state.items, item],
        currentRestaurantId: item.restaurantId,
        currentRestaurantName: item.restaurantName,
      );
    }
  }

  /// Ajouter depuis un menu_item JSON
  void addFromMenuItem(Map<String, dynamic> menuItem, String restaurantId, String restaurantName) {
    addItem(CartItem.fromMenuItem(menuItem, restaurantId, restaurantName));
  }

  /// Mettre à jour la quantité d'un article
  void updateQuantity(String menuItemId, int quantity) {
    if (quantity <= 0) {
      removeItem(menuItemId);
      return;
    }

    final updatedItems = state.items.map((item) {
      if (item.menuItemId == menuItemId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();

    state = state.copyWith(items: updatedItems);
  }

  /// Incrémenter la quantité
  void incrementQuantity(String menuItemId) {
    final item = state.items.firstWhere(
      (i) => i.menuItemId == menuItemId,
      orElse: () => throw Exception('Item not found'),
    );
    updateQuantity(menuItemId, item.quantity + 1);
  }

  /// Décrémenter la quantité
  void decrementQuantity(String menuItemId) {
    final item = state.items.firstWhere(
      (i) => i.menuItemId == menuItemId,
      orElse: () => throw Exception('Item not found'),
    );
    updateQuantity(menuItemId, item.quantity - 1);
  }

  /// Supprimer un article
  void removeItem(String menuItemId) {
    final updatedItems = state.items.where(
      (item) => item.menuItemId != menuItemId,
    ).toList();

    if (updatedItems.isEmpty) {
      state = const CartState();
    } else {
      state = state.copyWith(items: updatedItems);
    }
  }

  /// Mettre à jour les instructions spéciales
  void updateInstructions(String menuItemId, String? instructions) {
    final updatedItems = state.items.map((item) {
      if (item.menuItemId == menuItemId) {
        return item.copyWith(specialInstructions: instructions);
      }
      return item;
    }).toList();

    state = state.copyWith(items: updatedItems);
  }

  /// Vider le panier
  void clear() {
    state = const CartState();
  }

  /// Vider et remplacer par un nouveau restaurant
  void clearAndAddItem(CartItem item) {
    state = CartState(
      items: [item],
      currentRestaurantId: item.restaurantId,
      currentRestaurantName: item.restaurantName,
    );
  }

  /// Obtenir les items au format order_items pour la création de commande
  List<Map<String, dynamic>> toOrderItems() {
    return state.items.map((item) => item.toOrderItem()).toList();
  }
}

/// Provider global du panier (Riverpod 3.x)
final cartProvider = NotifierProvider<CartNotifier, CartState>(CartNotifier.new);

/// Provider pour le nombre total d'articles
final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).totalItems;
});

/// Provider pour le sous-total
final cartSubtotalProvider = Provider<double>((ref) {
  return ref.watch(cartProvider).subtotal;
});

/// Provider pour vérifier si le panier est vide
final cartIsEmptyProvider = Provider<bool>((ref) {
  return ref.watch(cartProvider).isEmpty;
});
