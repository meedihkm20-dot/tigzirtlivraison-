import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/design_system/theme/app_colors.dart';
import '../../../../core/design_system/theme/app_typography.dart';
import '../../../../core/design_system/theme/app_spacing.dart';
import '../../../../core/design_system/theme/app_shadows.dart';
import '../../../../core/design_system/components/loaders/skeleton_loader.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/router/app_router.dart';
import '../../../../providers/providers.dart';

/// Écran de recherche V2 - Recherche restaurants et plats avec filtres
class SearchScreenV2 extends ConsumerStatefulWidget {
  final String? initialQuery;
  final String? categoryFilter;

  const SearchScreenV2({
    super.key,
    this.initialQuery,
    this.categoryFilter,
  });

  @override
  ConsumerState<SearchScreenV2> createState() => _SearchScreenV2State();
}

class _SearchScreenV2State extends ConsumerState<SearchScreenV2> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  
  bool _isLoading = false;
  bool _showFilters = false;
  String _searchQuery = '';
  
  // Résultats
  List<Map<String, dynamic>> _restaurants = [];
  List<Map<String, dynamic>> _menuItems = [];
  List<String> _recentSearches = [];
  
  // Filtres
  String? _selectedCategory;
  double _minRating = 0;
  int _maxDeliveryTime = 60;
  bool _freeDeliveryOnly = false;
  String _sortBy = 'rating'; // rating, distance, delivery_time, price
  
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Pizza', 'icon': '🍕'},
    {'name': 'Burger', 'icon': '🍔'},
    {'name': 'Asiatique', 'icon': '🍜'},
    {'name': 'Salades', 'icon': '🥗'},
    {'name': 'Desserts', 'icon': '🍰'},
    {'name': 'Café', 'icon': '☕'},
    {'name': 'Tacos', 'icon': '🌮'},
    {'name': 'Sushi', 'icon': '🍣'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
      _searchQuery = widget.initialQuery!;
      _performSearch();
    }
    if (widget.categoryFilter != null) {
      _selectedCategory = widget.categoryFilter;
    }
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user != null) {
        final response = await SupabaseService.client
            .from('search_history')
            .select('query')
            .eq('customer_id', user.id)
            .order('searched_at', ascending: false)
            .limit(10);
        
        setState(() {
          _recentSearches = (response as List).map((e) => e['query'] as String).toList();
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement historique: $e');
    }
  }

  Future<void> _saveSearch(String query) async {
    if (query.trim().isEmpty) return;
    
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user != null) {
        await SupabaseService.client.from('search_history').upsert({
          'customer_id': user.id,
          'query': query.trim(),
          'searched_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Erreur sauvegarde recherche: $e');
    }
  }

  Future<void> _performSearch() async {
    if (_searchQuery.trim().isEmpty && _selectedCategory == null) {
      setState(() {
        _restaurants = [];
        _menuItems = [];
      });
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      // Sauvegarder la recherche
      if (_searchQuery.trim().isNotEmpty) {
        await _saveSearch(_searchQuery);
      }

      // Recherche restaurants
      var restaurantQuery = SupabaseService.client
          .from('restaurants')
          .select('*, menu_items!inner(*)')
          .eq('is_open', true)
          .eq('is_verified', true);

      // Filtres restaurants
      if (_searchQuery.trim().isNotEmpty) {
        restaurantQuery = restaurantQuery.or(
          'name.ilike.%${_searchQuery}%,cuisine_type.ilike.%${_searchQuery}%,description.ilike.%${_searchQuery}%'
        );
      }
      
      if (_selectedCategory != null) {
        restaurantQuery = restaurantQuery.eq('cuisine_type', _selectedCategory);
      }
      
      if (_minRating > 0) {
        restaurantQuery = restaurantQuery.gte('rating', _minRating);
      }
      
      if (_maxDeliveryTime < 60) {
        restaurantQuery = restaurantQuery.lte('avg_prep_time', _maxDeliveryTime);
      }
      
      if (_freeDeliveryOnly) {
        restaurantQuery = restaurantQuery.eq('delivery_fee', 0);
      }

      // Recherche plats
      var menuQuery = SupabaseService.client
          .from('menu_items')
          .select('*, restaurants!inner(*)')
          .eq('is_available', true)
          .eq('restaurants.is_open', true);

      if (_searchQuery.trim().isNotEmpty) {
        menuQuery = menuQuery.or(
          'name.ilike.%${_searchQuery}%,description.ilike.%${_searchQuery}%'
        );
      }

      final results = await Future.wait([
        restaurantQuery.limit(20),
        menuQuery.limit(30),
      ]);

      if (mounted) {
        setState(() {
          _restaurants = (results[0] as List).cast<Map<String, dynamic>>();
          _menuItems = (results[1] as List).cast<Map<String, dynamic>>();
          _isLoading = false;
        });
        
        // Trier les résultats
        _sortResults();
      }
    } catch (e) {
      debugPrint('Erreur recherche: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _sortResults() {
    switch (_sortBy) {
      case 'rating':
        _restaurants.sort((a, b) => (b['rating'] ?? 0).compareTo(a['rating'] ?? 0));
        break;
      case 'delivery_time':
        _restaurants.sort((a, b) => (a['avg_prep_time'] ?? 30).compareTo(b['avg_prep_time'] ?? 30));
        break;
      case 'price':
        _menuItems.sort((a, b) => (a['price'] ?? 0).compareTo(b['price'] ?? 0));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Filtres
          if (_showFilters) _buildFiltersSection(),
          
          // Contenu
          Expanded(
            child: _searchQuery.isEmpty && _selectedCategory == null
                ? _buildEmptyState()
                : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: TextField(
        controller: _searchController,
        focusNode: _searchFocus,
        autofocus: widget.initialQuery == null,
        decoration: InputDecoration(
          hintText: 'Rechercher restaurants, plats...',
          hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
          border: InputBorder.none,
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.textTertiary),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _restaurants = [];
                      _menuItems = [];
                    });
                  },
                )
              : null,
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
          if (value.length >= 2) {
            _performSearch();
          } else if (value.isEmpty) {
            setState(() {
              _restaurants = [];
              _menuItems = [];
            });
          }
        },
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) {
            _performSearch();
          }
        },
      ),
      actions: [
        IconButton(
          icon: Icon(
            _showFilters ? Icons.filter_list : Icons.tune,
            color: _showFilters ? AppColors.clientPrimary : AppColors.textTertiary,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            setState(() => _showFilters = !_showFilters);
          },
        ),
      ],
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Catégories
          Text('Catégories', style: AppTypography.titleSmall),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildCategoryChip(null, 'Toutes', '🍽️');
                }
                final category = _categories[index - 1];
                return _buildCategoryChip(
                  category['name'],
                  category['name'],
                  category['icon'],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          
          // Note minimale
          Text('Note minimale', style: AppTypography.titleSmall),
          Slider(
            value: _minRating,
            min: 0,
            max: 5,
            divisions: 10,
            activeColor: AppColors.clientPrimary,
            label: _minRating == 0 ? 'Toutes' : '${_minRating.toStringAsFixed(1)}⭐',
            onChanged: (value) {
              setState(() => _minRating = value);
              _performSearch();
            },
          ),
          
          // Temps de livraison max
          Text('Temps de livraison max', style: AppTypography.titleSmall),
          Slider(
            value: _maxDeliveryTime.toDouble(),
            min: 15,
            max: 60,
            divisions: 9,
            activeColor: AppColors.clientPrimary,
            label: '${_maxDeliveryTime} min',
            onChanged: (value) {
              setState(() => _maxDeliveryTime = value.round());
              _performSearch();
            },
          ),
          
          // Options
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  title: Text('Livraison gratuite', style: AppTypography.bodyMedium),
                  value: _freeDeliveryOnly,
                  activeColor: AppColors.clientPrimary,
                  onChanged: (value) {
                    setState(() => _freeDeliveryOnly = value ?? false);
                    _performSearch();
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          
          // Tri
          Row(
            children: [
              Text('Trier par: ', style: AppTypography.bodyMedium),
              DropdownButton<String>(
                value: _sortBy,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 'rating', child: Text('Note')),
                  DropdownMenuItem(value: 'delivery_time', child: Text('Temps')),
                  DropdownMenuItem(value: 'price', child: Text('Prix')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _sortBy = value);
                    _sortResults();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String? value, String label, String icon) {
    final isSelected = _selectedCategory == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedCategory = isSelected ? null : value;
        });
        _performSearch();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.clientPrimary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.clientPrimary : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: AppSpacing.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recherches récentes
          if (_recentSearches.isNotEmpty) ...[
            Text('Recherches récentes', style: AppTypography.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recentSearches.map((search) => GestureDetector(
                onTap: () {
                  _searchController.text = search;
                  setState(() => _searchQuery = search);
                  _performSearch();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.history, size: 16, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Text(search, style: AppTypography.bodyMedium),
                    ],
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 24),
          ],
          
          // Catégories populaires
          Text('Catégories populaires', style: AppTypography.titleMedium),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedCategory = category['name']);
                  _performSearch();
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppSpacing.borderRadiusMd,
                    boxShadow: AppShadows.sm,
                  ),
                  child: Row(
                    children: [
                      Text(category['icon'], style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          category['name'],
                          style: AppTypography.titleSmall,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.clientPrimary),
      );
    }

    if (_restaurants.isEmpty && _menuItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              'Aucun résultat trouvé',
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez avec d\'autres mots-clés',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: AppSpacing.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Restaurants
          if (_restaurants.isNotEmpty) ...[
            Text(
              'Restaurants (${_restaurants.length})',
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: 12),
            ..._restaurants.map((restaurant) => _buildRestaurantTile(restaurant)),
            const SizedBox(height: 24),
          ],
          
          // Plats
          if (_menuItems.isNotEmpty) ...[
            Text(
              'Plats (${_menuItems.length})',
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: 12),
            ..._menuItems.map((item) => _buildMenuItemTile(item)),
          ],
        ],
      ),
    );
  }

  Widget _buildRestaurantTile(Map<String, dynamic> restaurant) {
    final rating = (restaurant['rating'] as num?)?.toDouble() ?? 0;
    final prepTime = restaurant['avg_prep_time'] ?? 30;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pushNamed(context, AppRouter.restaurantDetail, arguments: restaurant['id']);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.borderRadiusMd,
          boxShadow: AppShadows.sm,
        ),
        child: Row(
          children: [
            // Logo
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: restaurant['logo_url'] != null
                  ? CachedNetworkImage(
                      imageUrl: restaurant['logo_url'],
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const SkeletonLoader(width: 60, height: 60),
                      errorWidget: (_, __, ___) => _buildPlaceholder(restaurant),
                    )
                  : _buildPlaceholder(restaurant),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant['name'] ?? '',
                    style: AppTypography.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    restaurant['cuisine_type'] ?? 'Restaurant',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 2),
                      Text(
                        rating.toStringAsFixed(1),
                        style: AppTypography.labelSmall,
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.access_time, size: 14, color: AppColors.textTertiary),
                      const SizedBox(width: 2),
                      Text(
                        '$prepTime min',
                        style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Badge livraison
            if (restaurant['delivery_fee'] == 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.successSurface,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Gratuit',
                  style: AppTypography.labelSmall.copyWith(color: AppColors.success),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItemTile(Map<String, dynamic> item) {
    final restaurant = item['restaurants'] as Map<String, dynamic>?;
    final price = (item['price'] as num?)?.toDouble() ?? 0;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pushNamed(context, AppRouter.restaurantDetail, arguments: item['restaurant_id']);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.borderRadiusMd,
          boxShadow: AppShadows.sm,
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item['image_url'] != null
                  ? CachedNetworkImage(
                      imageUrl: item['image_url'],
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const SkeletonLoader(width: 60, height: 60),
                      errorWidget: (_, __, ___) => Container(
                        width: 60,
                        height: 60,
                        color: AppColors.surfaceVariant,
                        child: const Icon(Icons.restaurant, color: AppColors.textTertiary),
                      ),
                    )
                  : Container(
                      width: 60,
                      height: 60,
                      color: AppColors.surfaceVariant,
                      child: const Icon(Icons.restaurant, color: AppColors.textTertiary),
                    ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'] ?? '',
                    style: AppTypography.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    restaurant?['name'] ?? '',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                  ),
                  const SizedBox(height: 4),
                  if (item['description'] != null)
                    Text(
                      item['description'],
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            // Prix
            Text(
              '${price.toStringAsFixed(0)} DA',
              style: AppTypography.titleSmall.copyWith(
                color: AppColors.clientPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(Map<String, dynamic> restaurant) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: AppColors.clientGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          (restaurant['name'] ?? 'R')[0].toUpperCase(),
          style: AppTypography.titleLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}