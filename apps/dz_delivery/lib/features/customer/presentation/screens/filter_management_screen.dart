import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/design_system/theme/app_colors.dart';
import '../../../../core/design_system/theme/app_typography.dart';
import '../../../../core/design_system/theme/app_spacing.dart';
import '../../../../core/design_system/theme/app_shadows.dart';
import '../../../../core/services/filter_preferences_service.dart';

/// Écran de gestion des filtres de catégories
class FilterManagementScreen extends StatefulWidget {
  const FilterManagementScreen({super.key});

  @override
  State<FilterManagementScreen> createState() => _FilterManagementScreenState();
}

class _FilterManagementScreenState extends State<FilterManagementScreen> {
  List<Map<String, dynamic>> _allCategories = [];
  List<String> _hiddenCategories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() {
    setState(() {
      _allCategories = FilterPreferencesService.getAllCategoriesForManagement();
      _hiddenCategories = FilterPreferencesService.getHiddenCategories();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gérer les filtres'),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddCategoryDialog,
            tooltip: 'Ajouter une catégorie',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'reset':
                  _resetToDefaults();
                  break;
                case 'reorder':
                  _showReorderDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reorder',
                child: Row(
                  children: [
                    Icon(Icons.reorder),
                    SizedBox(width: 8),
                    Text('Réorganiser'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.restore, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Réinitialiser', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.clientPrimary))
          : Column(
              children: [
                // Info section
                Container(
                  margin: AppSpacing.screen,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.clientSurface,
                    borderRadius: AppSpacing.borderRadiusMd,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.clientPrimary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Personnalisez vos filtres de recherche. Vous pouvez masquer, modifier ou ajouter des catégories.',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.clientPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Categories list
                Expanded(
                  child: ListView.builder(
                    padding: AppSpacing.screen,
                    itemCount: _allCategories.length,
                    itemBuilder: (context, index) => _buildCategoryItem(_allCategories[index]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCategoryItem(Map<String, dynamic> category) {
    final isHidden = _hiddenCategories.contains(category['id']);
    final isDefault = category['isDefault'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusMd,
        boxShadow: AppShadows.sm,
        border: isHidden ? Border.all(color: AppColors.outline, width: 1) : null,
      ),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isHidden 
                ? AppColors.surfaceVariant 
                : AppColors.clientSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Opacity(
              opacity: isHidden ? 0.5 : 1.0,
              child: Text(
                category['icon'] ?? '📂',
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
        ),
        title: Text(
          category['name'] ?? 'Sans nom',
          style: AppTypography.titleSmall.copyWith(
            color: isHidden ? AppColors.textTertiary : AppColors.textPrimary,
            decoration: isHidden ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Row(
          children: [
            if (isDefault) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.clientPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Par défaut',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.clientPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              isHidden ? 'Masquée' : 'Visible',
              style: AppTypography.bodySmall.copyWith(
                color: isHidden ? AppColors.error : AppColors.success,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleCategoryAction(category, value),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: isHidden ? 'show' : 'hide',
              child: Row(
                children: [
                  Icon(isHidden ? Icons.visibility : Icons.visibility_off),
                  const SizedBox(width: 8),
                  Text(isHidden ? 'Afficher' : 'Masquer'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Modifier'),
                ],
              ),
            ),
            if (!isDefault)
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Supprimer', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handleCategoryAction(Map<String, dynamic> category, String action) async {
    switch (action) {
      case 'show':
        await FilterPreferencesService.showCategory(category['id']);
        break;
      case 'hide':
        await FilterPreferencesService.hideCategory(category['id']);
        break;
      case 'edit':
        _showEditCategoryDialog(category);
        return;
      case 'delete':
        _showDeleteConfirmation(category);
        return;
    }
    
    _loadCategories();
    _showSnackBar('Catégorie mise à jour');
  }

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    String selectedIcon = '📂';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajouter une catégorie'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nom de la catégorie',
                hintText: 'Ex: Cuisine italienne',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Icône: '),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showIconPicker((icon) {
                    selectedIcon = icon;
                    (ctx as Element).markNeedsBuild();
                  }),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.outline),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(selectedIcon, style: const TextStyle(fontSize: 24)),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                await FilterPreferencesService.addCustomCategory(
                  name: nameController.text.trim(),
                  icon: selectedIcon,
                );
                Navigator.pop(ctx);
                _loadCategories();
                _showSnackBar('Catégorie ajoutée');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.clientPrimary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(Map<String, dynamic> category) {
    final nameController = TextEditingController(text: category['name']);
    String selectedIcon = category['icon'] ?? '📂';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Modifier la catégorie'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom de la catégorie',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Icône: '),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showIconPicker((icon) {
                      setState(() => selectedIcon = icon);
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.outline),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(selectedIcon, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isNotEmpty) {
                  await FilterPreferencesService.updateCategory(
                    categoryId: category['id'],
                    name: nameController.text.trim(),
                    icon: selectedIcon,
                  );
                  Navigator.pop(ctx);
                  _loadCategories();
                  _showSnackBar('Catégorie modifiée');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.clientPrimary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sauvegarder'),
            ),
          ],
        ),
      ),
    );
  }

  void _showIconPicker(Function(String) onIconSelected) {
    final icons = [
      '🍕', '🍔', '🍜', '🥗', '🍰', '☕', '🌮', '🍣',
      '🍝', '🍖', '🍗', '🥘', '🍲', '🥙', '🌯', '🥪',
      '🍱', '🍙', '🍘', '🍚', '🍛', '🍤', '🍢', '🍡',
      '🧆', '🥟', '🥠', '🥡', '🍦', '🍧', '🍨', '🍩',
      '🍪', '🎂', '🧁', '🥧', '🍫', '🍬', '🍭', '🍮',
      '🍯', '🥛', '🧃', '🧉', '🍵', '🍶', '🍾', '🍷',
      '🍸', '🍹', '🍺', '🍻', '🥂', '🥃', '🧊', '📂',
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choisir une icône'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              childAspectRatio: 1,
            ),
            itemCount: icons.length,
            itemBuilder: (context, index) => GestureDetector(
              onTap: () {
                onIconSelected(icons[index]);
                Navigator.pop(ctx);
              },
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.outline),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(icons[index], style: const TextStyle(fontSize: 24)),
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> category) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la catégorie'),
        content: Text('Voulez-vous vraiment supprimer "${category['name']}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FilterPreferencesService.deleteCustomCategory(category['id']);
              Navigator.pop(ctx);
              _loadCategories();
              _showSnackBar('Catégorie supprimée');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showReorderDialog() {
    List<Map<String, dynamic>> reorderableCategories = List.from(_allCategories);
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Réorganiser les catégories'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ReorderableListView.builder(
              itemCount: reorderableCategories.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = reorderableCategories.removeAt(oldIndex);
                  reorderableCategories.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                final category = reorderableCategories[index];
                return ListTile(
                  key: ValueKey(category['id']),
                  leading: Text(category['icon'] ?? '📂', style: const TextStyle(fontSize: 20)),
                  title: Text(category['name'] ?? 'Sans nom'),
                  trailing: const Icon(Icons.drag_handle),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final categoryIds = reorderableCategories.map((cat) => cat['id'] as String).toList();
                await FilterPreferencesService.reorderCategories(categoryIds);
                Navigator.pop(ctx);
                _loadCategories();
                _showSnackBar('Ordre des catégories mis à jour');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.clientPrimary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sauvegarder'),
            ),
          ],
        ),
      ),
    );
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Réinitialiser'),
        content: const Text('Voulez-vous vraiment réinitialiser tous les filtres aux paramètres par défaut ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FilterPreferencesService.resetToDefaults();
              Navigator.pop(ctx);
              _loadCategories();
              _showSnackBar('Filtres réinitialisés');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}