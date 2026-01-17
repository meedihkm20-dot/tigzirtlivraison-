import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service pour gérer les préférences de filtres personnalisables
class FilterPreferencesService {
  static const String _categoriesKey = 'custom_categories';
  static const String _hiddenCategoriesKey = 'hidden_categories';
  static const String _categoryOrderKey = 'category_order';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Catégories par défaut du système
  static const List<Map<String, dynamic>> defaultCategories = [
    {'id': 'pizza', 'name': 'Pizza', 'icon': '🍕', 'isDefault': true},
    {'id': 'burger', 'name': 'Burger', 'icon': '🍔', 'isDefault': true},
    {'id': 'asiatique', 'name': 'Asiatique', 'icon': '🍜', 'isDefault': true},
    {'id': 'salades', 'name': 'Salades', 'icon': '🥗', 'isDefault': true},
    {'id': 'desserts', 'name': 'Desserts', 'icon': '🍰', 'isDefault': true},
    {'id': 'cafe', 'name': 'Café', 'icon': '☕', 'isDefault': true},
    {'id': 'tacos', 'name': 'Tacos', 'icon': '🌮', 'isDefault': true},
    {'id': 'sushi', 'name': 'Sushi', 'icon': '🍣', 'isDefault': true},
  ];

  /// Obtenir toutes les catégories (par défaut + personnalisées)
  static List<Map<String, dynamic>> getAllCategories() {
    final customCategoriesJson = _prefs?.getString(_categoriesKey);
    final hiddenCategories = getHiddenCategories();
    final categoryOrder = getCategoryOrder();

    List<Map<String, dynamic>> allCategories = List.from(defaultCategories);

    // Ajouter les catégories personnalisées
    if (customCategoriesJson != null) {
      final customCategories = (jsonDecode(customCategoriesJson) as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      allCategories.addAll(customCategories);
    }

    // Filtrer les catégories masquées
    allCategories = allCategories
        .where((category) => !hiddenCategories.contains(category['id']))
        .toList();

    // Appliquer l'ordre personnalisé
    if (categoryOrder.isNotEmpty) {
      allCategories.sort((a, b) {
        final indexA = categoryOrder.indexOf(a['id']);
        final indexB = categoryOrder.indexOf(b['id']);
        
        if (indexA == -1 && indexB == -1) return 0;
        if (indexA == -1) return 1;
        if (indexB == -1) return -1;
        
        return indexA.compareTo(indexB);
      });
    }

    return allCategories;
  }

  /// Obtenir les catégories visibles seulement
  static List<Map<String, dynamic>> getVisibleCategories() {
    return getAllCategories();
  }

  /// Ajouter une catégorie personnalisée
  static Future<void> addCustomCategory({
    required String name,
    required String icon,
  }) async {
    final customCategoriesJson = _prefs?.getString(_categoriesKey);
    List<Map<String, dynamic>> customCategories = [];

    if (customCategoriesJson != null) {
      customCategories = (jsonDecode(customCategoriesJson) as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    final newCategory = {
      'id': 'custom_${DateTime.now().millisecondsSinceEpoch}',
      'name': name,
      'icon': icon,
      'isDefault': false,
    };

    customCategories.add(newCategory);
    await _prefs?.setString(_categoriesKey, jsonEncode(customCategories));
  }

  /// Modifier une catégorie
  static Future<void> updateCategory({
    required String categoryId,
    String? name,
    String? icon,
  }) async {
    if (isDefaultCategory(categoryId)) {
      // Pour les catégories par défaut, on crée une version personnalisée
      final defaultCategory = defaultCategories.firstWhere(
        (cat) => cat['id'] == categoryId,
      );
      
      await addCustomCategory(
        name: name ?? defaultCategory['name'],
        icon: icon ?? defaultCategory['icon'],
      );
      
      // Masquer l'originale
      await hideCategory(categoryId);
    } else {
      // Modifier la catégorie personnalisée
      final customCategoriesJson = _prefs?.getString(_categoriesKey);
      if (customCategoriesJson != null) {
        List<Map<String, dynamic>> customCategories = 
            (jsonDecode(customCategoriesJson) as List)
                .map((e) => Map<String, dynamic>.from(e))
                .toList();

        final index = customCategories.indexWhere((cat) => cat['id'] == categoryId);
        if (index != -1) {
          if (name != null) customCategories[index]['name'] = name;
          if (icon != null) customCategories[index]['icon'] = icon;
          
          await _prefs?.setString(_categoriesKey, jsonEncode(customCategories));
        }
      }
    }
  }

  /// Supprimer une catégorie personnalisée
  static Future<void> deleteCustomCategory(String categoryId) async {
    if (isDefaultCategory(categoryId)) return; // Ne peut pas supprimer les catégories par défaut

    final customCategoriesJson = _prefs?.getString(_categoriesKey);
    if (customCategoriesJson != null) {
      List<Map<String, dynamic>> customCategories = 
          (jsonDecode(customCategoriesJson) as List)
              .map((e) => Map<String, dynamic>.from(e))
              .toList();

      customCategories.removeWhere((cat) => cat['id'] == categoryId);
      await _prefs?.setString(_categoriesKey, jsonEncode(customCategories));
    }
  }

  /// Masquer/Afficher une catégorie
  static Future<void> hideCategory(String categoryId) async {
    final hiddenCategories = getHiddenCategories();
    if (!hiddenCategories.contains(categoryId)) {
      hiddenCategories.add(categoryId);
      await _prefs?.setStringList(_hiddenCategoriesKey, hiddenCategories);
    }
  }

  static Future<void> showCategory(String categoryId) async {
    final hiddenCategories = getHiddenCategories();
    hiddenCategories.remove(categoryId);
    await _prefs?.setStringList(_hiddenCategoriesKey, hiddenCategories);
  }

  /// Obtenir les catégories masquées
  static List<String> getHiddenCategories() {
    return _prefs?.getStringList(_hiddenCategoriesKey) ?? [];
  }

  /// Réorganiser les catégories
  static Future<void> reorderCategories(List<String> categoryIds) async {
    await _prefs?.setStringList(_categoryOrderKey, categoryIds);
  }

  /// Obtenir l'ordre des catégories
  static List<String> getCategoryOrder() {
    return _prefs?.getStringList(_categoryOrderKey) ?? [];
  }

  /// Vérifier si c'est une catégorie par défaut
  static bool isDefaultCategory(String categoryId) {
    return defaultCategories.any((cat) => cat['id'] == categoryId);
  }

  /// Réinitialiser aux paramètres par défaut
  static Future<void> resetToDefaults() async {
    await _prefs?.remove(_categoriesKey);
    await _prefs?.remove(_hiddenCategoriesKey);
    await _prefs?.remove(_categoryOrderKey);
  }

  /// Obtenir toutes les catégories (y compris masquées) pour la gestion
  static List<Map<String, dynamic>> getAllCategoriesForManagement() {
    final customCategoriesJson = _prefs?.getString(_categoriesKey);
    List<Map<String, dynamic>> allCategories = List.from(defaultCategories);

    if (customCategoriesJson != null) {
      final customCategories = (jsonDecode(customCategoriesJson) as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      allCategories.addAll(customCategories);
    }

    return allCategories;
  }
}