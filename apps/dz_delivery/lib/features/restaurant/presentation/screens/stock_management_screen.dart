import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/design_system/theme/app_colors.dart';
import '../../../../core/design_system/theme/app_typography.dart';
import '../../../../core/design_system/theme/app_spacing.dart';
import '../../../../core/design_system/theme/app_shadows.dart';
import '../../../../core/services/supabase_service.dart';

/// Écran de gestion des stocks
/// Inventaire, alertes, historique
class StockManagementScreen extends StatefulWidget {
  const StockManagementScreen({super.key});

  @override
  State<StockManagementScreen> createState() => _StockManagementScreenState();
}

class _StockManagementScreenState extends State<StockManagementScreen> {
  bool _isLoading = true;
  String _filter = 'all';
  List<_StockItem> _items = [];
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Simuler les données (à remplacer par vraies données)
      await Future.delayed(const Duration(milliseconds: 500));
      
      final items = [
        _StockItem('Mozzarella', 'Fromages', 15, 20, 'kg', DateTime.now().add(const Duration(days: 5))),
        _StockItem('Tomates', 'Légumes', 8, 10, 'kg', DateTime.now().add(const Duration(days: 3))),
        _StockItem('Farine', 'Base', 25, 15, 'kg', DateTime.now().add(const Duration(days: 30))),
        _StockItem('Huile d\'olive', 'Huiles', 5, 8, 'L', DateTime.now().add(const Duration(days: 60))),
        _StockItem('Jambon', 'Viandes', 3, 5, 'kg', DateTime.now().add(const Duration(days: 7))),
        _StockItem('Champignons', 'Légumes', 2, 5, 'kg', DateTime.now().add(const Duration(days: 2))),
        _StockItem('Olives', 'Condiments', 4, 3, 'kg', DateTime.now().add(const Duration(days: 45))),
        _StockItem('Basilic', 'Herbes', 1, 2, 'botte', DateTime.now().add(const Duration(days: 1))),
      ];

      if (mounted) {
        setState(() => _items = items);
      }
    } catch (e) {
      debugPrint('Erreur chargement stocks: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<_StockItem> get _filteredItems {
    var items = _items;
    
    // Filter by search
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      items = items.where((i) => 
        i.name.toLowerCase().contains(query) ||
        i.category.toLowerCase().contains(query)
      ).toList();
    }
    
    // Filter by status
    switch (_filter) {
      case 'low':
        items = items.where((i) => i.isLowStock).toList();
        break;
      case 'expiring':
        items = items.where((i) => i.isExpiringSoon).toList();
        break;
      case 'ok':
        items = items.where((i) => !i.isLowStock && !i.isExpiringSoon).toList();
        break;
    }
    
    return items;
  }

  int get _lowStockCount => _items.where((i) => i.isLowStock).length;
  int get _expiringCount => _items.where((i) => i.isExpiringSoon).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('📦 Gestion des stocks'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddItemDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  // Alerts
                  SliverToBoxAdapter(child: _buildAlerts()),
                  
                  // Search & Filter
                  SliverToBoxAdapter(child: _buildSearchAndFilter()),
                  
                  // Stock list
                  SliverPadding(
                    padding: AppSpacing.screenHorizontal,
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildStockItem(_filteredItems[index]),
                        childCount: _filteredItems.length,
                      ),
                    ),
                  ),
                  
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddItemDialog,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildAlerts() {
    if (_lowStockCount == 0 && _expiringCount == 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: AppSpacing.screen,
      child: Column(
        children: [
          if (_lowStockCount > 0)
            _buildAlertCard(
              icon: Icons.warning_amber,
              title: 'Stock faible',
              message: '$_lowStockCount article${_lowStockCount > 1 ? 's' : ''} en rupture imminente',
              color: AppColors.warning,
              onTap: () => setState(() => _filter = 'low'),
            ),
          if (_expiringCount > 0) ...[
            if (_lowStockCount > 0) AppSpacing.vSm,
            _buildAlertCard(
              icon: Icons.schedule,
              title: 'Expiration proche',
              message: '$_expiringCount article${_expiringCount > 1 ? 's' : ''} expire${_expiringCount > 1 ? 'nt' : ''} bientôt',
              color: AppColors.error,
              onTap: () => setState(() => _filter = 'expiring'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAlertCard({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.labelMedium.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    message,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: AppSpacing.screen,
      child: Column(
        children: [
          // Search
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Rechercher un article...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
            ),
          ),
          AppSpacing.vMd,
          
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'Tous', _items.length),
                const SizedBox(width: 8),
                _buildFilterChip('low', '⚠️ Stock faible', _lowStockCount),
                const SizedBox(width: 8),
                _buildFilterChip('expiring', '⏰ Expire bientôt', _expiringCount),
                const SizedBox(width: 8),
                _buildFilterChip('ok', '✅ OK', _items.length - _lowStockCount - _expiringCount),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, int count) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _filter = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: AppSpacing.borderRadiusRound,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outline,
          ),
          boxShadow: isSelected ? AppShadows.sm : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.2) : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: AppTypography.labelSmall.copyWith(
                  color: isSelected ? Colors.white : AppColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildStockItem(_StockItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        boxShadow: AppShadows.sm,
        border: item.isLowStock || item.isExpiringSoon
            ? Border.all(
                color: item.isExpiringSoon ? AppColors.error : AppColors.warning,
                width: 1.5,
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showEditItemDialog(item),
          borderRadius: AppSpacing.borderRadiusLg,
          child: Padding(
            padding: AppSpacing.card,
            child: Row(
              children: [
                // Status indicator
                Container(
                  width: 4,
                  height: 60,
                  decoration: BoxDecoration(
                    color: item.statusColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Item info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            item.name,
                            style: AppTypography.titleSmall,
                          ),
                          if (item.isLowStock) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.warningSurface,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Stock faible',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.warning,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                          if (item.isExpiringSoon) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.errorSurface,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Expire bientôt',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.error,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.category,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.schedule, size: 12, color: AppColors.textTertiary),
                          const SizedBox(width: 4),
                          Text(
                            'Expire ${item.expirationText}',
                            style: AppTypography.labelSmall.copyWith(
                              color: item.isExpiringSoon ? AppColors.error : AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Quantity
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${item.quantity}',
                      style: AppTypography.headlineSmall.copyWith(
                        color: item.isLowStock ? AppColors.warning : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      item.unit,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Progress bar
                    SizedBox(
                      width: 60,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: item.stockPercentage,
                          backgroundColor: AppColors.surfaceVariant,
                          valueColor: AlwaysStoppedAnimation(item.statusColor),
                          minHeight: 4,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(width: 8),
                
                // Actions
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppColors.textTertiary),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditItemDialog(item);
                        break;
                      case 'restock':
                        _showRestockDialog(item);
                        break;
                      case 'delete':
                        _confirmDelete(item);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Modifier'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'restock',
                      child: Row(
                        children: [
                          Icon(Icons.add_shopping_cart, size: 18),
                          SizedBox(width: 8),
                          Text('Réapprovisionner'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: AppColors.error),
                          SizedBox(width: 8),
                          Text('Supprimer', style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddItemDialog() {
    _showItemDialog(null);
  }

  void _showEditItemDialog(_StockItem item) {
    _showItemDialog(item);
  }

  void _showItemDialog(_StockItem? item) {
    final nameController = TextEditingController(text: item?.name ?? '');
    final categoryController = TextEditingController(text: item?.category ?? '');
    final quantityController = TextEditingController(text: item?.quantity.toString() ?? '');
    final thresholdController = TextEditingController(text: item?.threshold.toString() ?? '');
    final unitController = TextEditingController(text: item?.unit ?? 'kg');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.borderRadiusTopXl,
        ),
        child: Padding(
          padding: AppSpacing.screen,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              AppSpacing.vLg,
              Text(
                item == null ? 'Ajouter un article' : 'Modifier l\'article',
                style: AppTypography.headlineSmall,
              ),
              AppSpacing.vLg,
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom de l\'article',
                  prefixIcon: Icon(Icons.inventory_2),
                ),
              ),
              AppSpacing.vMd,
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Catégorie',
                  prefixIcon: Icon(Icons.category),
                ),
              ),
              AppSpacing.vMd,
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Quantité',
                        prefixIcon: Icon(Icons.numbers),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: unitController,
                      decoration: const InputDecoration(
                        labelText: 'Unité',
                      ),
                    ),
                  ),
                ],
              ),
              AppSpacing.vMd,
              TextField(
                controller: thresholdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Seuil d\'alerte',
                  prefixIcon: Icon(Icons.warning_amber),
                  helperText: 'Alerte si stock inférieur à ce seuil',
                ),
              ),
              AppSpacing.vLg,
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Save logic here
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(item == null ? 'Article ajouté' : 'Article modifié'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                      child: Text(item == null ? 'Ajouter' : 'Enregistrer'),
                    ),
                  ),
                ],
              ),
              AppSpacing.vLg,
            ],
          ),
        ),
      ),
    );
  }

  void _showRestockDialog(_StockItem item) {
    final quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Réapprovisionner ${item.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Stock actuel: ${item.quantity} ${item.unit}',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            AppSpacing.vMd,
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Quantité à ajouter',
                suffix: Text(item.unit),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Stock mis à jour'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(_StockItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'article?'),
        content: Text('Voulez-vous vraiment supprimer "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _items.removeWhere((i) => i.name == item.name);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Article supprimé'),
                  backgroundColor: AppColors.warning,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

// ============================================
// DATA MODEL
// ============================================
class _StockItem {
  final String name;
  final String category;
  final int quantity;
  final int threshold;
  final String unit;
  final DateTime expirationDate;

  _StockItem(this.name, this.category, this.quantity, this.threshold, this.unit, this.expirationDate);

  bool get isLowStock => quantity <= threshold;
  
  bool get isExpiringSoon {
    final daysUntilExpiration = expirationDate.difference(DateTime.now()).inDays;
    return daysUntilExpiration <= 3;
  }

  double get stockPercentage {
    if (threshold == 0) return 1.0;
    return (quantity / (threshold * 2)).clamp(0.0, 1.0);
  }

  Color get statusColor {
    if (isExpiringSoon) return AppColors.error;
    if (isLowStock) return AppColors.warning;
    return AppColors.success;
  }

  String get expirationText {
    final days = expirationDate.difference(DateTime.now()).inDays;
    if (days < 0) return 'Expiré';
    if (days == 0) return 'Aujourd\'hui';
    if (days == 1) return 'Demain';
    return 'dans $days jours';
  }
}
