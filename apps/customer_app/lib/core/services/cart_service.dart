import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Service de gestion du panier avec persistance locale
class CartService {
  static const String _boxName = 'cart';
  static const String _itemsKey = 'items';
  static const String _restaurantKey = 'restaurant';
  static Box? _box;
  
  /// Initialiser le service (appeler dans main.dart)
  static Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }
  
  /// Récupérer tous les items du panier
  static List<Map<String, dynamic>> getItems() {
    if (_box == null) return [];
    final data = _box!.get(_itemsKey);
    if (data == null) return [];
    
    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      debugPrint('Erreur lecture panier: $e');
      return [];
    }
  }
  
  /// Récupérer le restaurant actuel du panier
  static Map<String, dynamic>? getRestaurant() {
    if (_box == null) return null;
    final data = _box!.get(_restaurantKey);
    if (data == null) return null;
    
    try {
      return Map<String, dynamic>.from(jsonDecode(data));
    } catch (e) {
      return null;
    }
  }
  
  /// Ajouter un item au panier
  static Future<bool> addItem({
    required Map<String, dynamic> restaurant,
    required Map<String, dynamic> item,
    int quantity = 1,
    String? instructions,
  }) async {
    if (_box == null) return false;
    
    final currentRestaurant = getRestaurant();
    
    // Vérifier si on change de restaurant
    if (currentRestaurant != null && currentRestaurant['id'] != restaurant['id']) {
      // Retourner false pour demander confirmation à l'utilisateur
      return false;
    }
    
    // Sauvegarder le restaurant
    await _box!.put(_restaurantKey, jsonEncode(restaurant));
    
    // Récupérer les items existants
    final items = getItems();
    
    // Chercher si l'item existe déjà
    final existingIndex = items.indexWhere((e) => e['id'] == item['id']);
    
    if (existingIndex >= 0) {
      // Incrémenter la quantité
      items[existingIndex]['quantity'] = (items[existingIndex]['quantity'] ?? 1) + quantity;
      if (instructions != null) {
        items[existingIndex]['instructions'] = instructions;
      }
    } else {
      // Ajouter nouvel item
      items.add({
        'id': item['id'],
        'name': item['name'],
        'price': item['price'],
        'image_url': item['image_url'],
        'quantity': quantity,
        'instructions': instructions,
      });
    }
    
    await _box!.put(_itemsKey, jsonEncode(items));
    return true;
  }
  
  /// Mettre à jour la quantité d'un item
  static Future<void> updateQuantity(String itemId, int quantity) async {
    if (_box == null) return;
    
    final items = getItems();
    final index = items.indexWhere((e) => e['id'] == itemId);
    
    if (index >= 0) {
      if (quantity <= 0) {
        items.removeAt(index);
      } else {
        items[index]['quantity'] = quantity;
      }
      
      await _box!.put(_itemsKey, jsonEncode(items));
      
      // Si le panier est vide, supprimer le restaurant
      if (items.isEmpty) {
        await _box!.delete(_restaurantKey);
      }
    }
  }
  
  /// Supprimer un item
  static Future<void> removeItem(String itemId) async {
    await updateQuantity(itemId, 0);
  }
  
  /// Vider le panier
  static Future<void> clear() async {
    if (_box == null) return;
    await _box!.delete(_itemsKey);
    await _box!.delete(_restaurantKey);
  }
  
  /// Forcer le changement de restaurant (vide le panier actuel)
  static Future<void> forceChangeRestaurant(Map<String, dynamic> newRestaurant) async {
    await clear();
    await _box!.put(_restaurantKey, jsonEncode(newRestaurant));
  }
  
  /// Calculer le sous-total
  static double getSubtotal() {
    final items = getItems();
    double total = 0;
    for (final item in items) {
      total += (item['price'] as num).toDouble() * (item['quantity'] as int);
    }
    return total;
  }
  
  /// Nombre total d'items
  static int getTotalItems() {
    final items = getItems();
    int count = 0;
    for (final item in items) {
      count += item['quantity'] as int;
    }
    return count;
  }
  
  /// Vérifier si le panier est vide
  static bool isEmpty() {
    return getItems().isEmpty;
  }
}
