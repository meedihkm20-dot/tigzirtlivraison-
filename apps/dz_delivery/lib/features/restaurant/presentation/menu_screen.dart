import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  late TabController _tabController;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    setState(() => _isLoading = true);
    try {
      final categories = await SupabaseService.getMenuCategories();
      final items = await SupabaseService.getMenuItems();
      setState(() {
        _categories = categories;
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddItemDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final priceController = TextEditingController();
    final prepTimeController = TextEditingController(text: '15');
    String? selectedCategoryId;
    Uint8List? imageBytes;
    bool isVegetarian = false;
    bool isSpicy = false;
    List<String> ingredients = [];
    final ingredientController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Nouveau plat', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Image picker
                GestureDetector(
                  onTap: () async {
                    final XFile? image = await _picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 500,
                      maxHeight: 500,
                      imageQuality: 85,
                    );
                    if (image != null) {
                      final bytes = await image.readAsBytes();
                      setModalState(() => imageBytes = bytes);
                    }
                  },
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                      image: imageBytes != null
                          ? DecorationImage(image: MemoryImage(imageBytes!), fit: BoxFit.cover)
                          : null,
                    ),
                    child: imageBytes == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text('Ajouter une photo (500x500)', style: TextStyle(color: Colors.grey[600])),
                            ],
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nom du plat *', prefixIcon: Icon(Icons.restaurant_menu)),
                ),
                const SizedBox(height: 12),
                
                TextField(
                  controller: descController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description)),
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Prix (DA) *', prefixIcon: Icon(Icons.attach_money)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: prepTimeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Temps prép. (min)', prefixIcon: Icon(Icons.timer)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Catégorie
                DropdownButtonFormField<String>(
                  value: selectedCategoryId,
                  decoration: const InputDecoration(labelText: 'Catégorie', prefixIcon: Icon(Icons.category)),
                  items: _categories.map((cat) => DropdownMenuItem(
                    value: cat['id'] as String,
                    child: Text(cat['name'] ?? ''),
                  )).toList(),
                  onChanged: (value) => setModalState(() => selectedCategoryId = value),
                ),
                const SizedBox(height: 12),
                
                // Ingrédients
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: ingredientController,
                        decoration: const InputDecoration(labelText: 'Ajouter un ingrédient', prefixIcon: Icon(Icons.egg)),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: AppTheme.primaryColor),
                      onPressed: () {
                        if (ingredientController.text.isNotEmpty) {
                          setModalState(() {
                            ingredients.add(ingredientController.text);
                            ingredientController.clear();
                          });
                        }
                      },
                    ),
                  ],
                ),
                if (ingredients.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    children: ingredients.map((ing) => Chip(
                      label: Text(ing),
                      onDeleted: () => setModalState(() => ingredients.remove(ing)),
                    )).toList(),
                  ),
                const SizedBox(height: 12),
                
                // Options
                Row(
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        value: isVegetarian,
                        onChanged: (v) => setModalState(() => isVegetarian = v ?? false),
                        title: const Row(children: [Icon(Icons.eco, color: Colors.green, size: 20), SizedBox(width: 8), Text('Végétarien')]),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: CheckboxListTile(
                        value: isSpicy,
                        onChanged: (v) => setModalState(() => isSpicy = v ?? false),
                        title: const Row(children: [Icon(Icons.local_fire_department, color: Colors.red, size: 20), SizedBox(width: 8), Text('Épicé')]),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isEmpty || priceController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Nom et prix requis'), backgroundColor: Colors.red),
                        );
                        return;
                      }
                      
                      // Upload image si présente
                      String? imageUrl;
                      if (imageBytes != null) {
                        final itemId = DateTime.now().millisecondsSinceEpoch.toString();
                        imageUrl = await SupabaseService.uploadMenuItemImage(itemId, imageBytes!);
                      }
                      
                      // Ajouter le plat
                      await SupabaseService.addMenuItem(
                        name: nameController.text,
                        price: double.parse(priceController.text),
                        description: descController.text.isEmpty ? null : descController.text,
                        categoryId: selectedCategoryId,
                        prepTime: int.tryParse(prepTimeController.text) ?? 15,
                        imageUrl: imageUrl,
                      );
                      
                      Navigator.pop(context);
                      _loadMenu();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Plat ajouté!'), backgroundColor: Colors.green),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                    child: const Text('Ajouter le plat'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle catégorie'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nom de la catégorie'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description (optionnel)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              await SupabaseService.addMenuCategory(
                name: nameController.text,
                description: descController.text.isEmpty ? null : descController.text,
              );
              Navigator.pop(context);
              _loadMenu();
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _showItemOptions(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                item['is_daily_special'] == true ? Icons.star : Icons.star_border,
                color: Colors.amber,
              ),
              title: Text(item['is_daily_special'] == true ? 'Retirer du plat du jour' : 'Définir comme plat du jour'),
              onTap: () async {
                Navigator.pop(context);
                if (item['is_daily_special'] == true) {
                  await SupabaseService.removeDailySpecial(item['id']);
                } else {
                  _showDailySpecialDialog(item);
                }
                _loadMenu();
              },
            ),
            ListTile(
              leading: Icon(
                item['is_available'] == true ? Icons.visibility_off : Icons.visibility,
                color: Colors.blue,
              ),
              title: Text(item['is_available'] == true ? 'Marquer indisponible' : 'Marquer disponible'),
              onTap: () async {
                Navigator.pop(context);
                await SupabaseService.updateMenuItem(
                  itemId: item['id'],
                  isAvailable: !(item['is_available'] ?? true),
                );
                _loadMenu();
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.orange),
              title: const Text('Modifier'),
              onTap: () {
                Navigator.pop(context);
                _showEditItemDialog(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart, color: Colors.purple),
              title: const Text('Voir les statistiques'),
              onTap: () {
                Navigator.pop(context);
                _showItemStats(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Supprimer'),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Supprimer ce plat?'),
                    content: Text('Voulez-vous vraiment supprimer "${item['name']}"?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Supprimer'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await SupabaseService.deleteMenuItem(item['id']);
                  _loadMenu();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDailySpecialDialog(Map<String, dynamic> item) {
    final priceController = TextEditingController(text: (item['price'] as num).toStringAsFixed(0));
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔥 Plat du jour'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Définir "${item['name']}" comme plat du jour'),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Prix spécial (DA)',
                hintText: 'Prix original: ${item['price']} DA',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              final specialPrice = double.tryParse(priceController.text);
              await SupabaseService.setDailySpecial(item['id'], specialPrice: specialPrice);
              Navigator.pop(context);
              _loadMenu();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Plat du jour défini!'), backgroundColor: Colors.green),
              );
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _showEditItemDialog(Map<String, dynamic> item) {
    final nameController = TextEditingController(text: item['name']);
    final descController = TextEditingController(text: item['description'] ?? '');
    final priceController = TextEditingController(text: (item['price'] as num).toStringAsFixed(0));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Modifier le plat', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nom')),
            const SizedBox(height: 12),
            TextField(controller: descController, maxLines: 2, decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 12),
            TextField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Prix (DA)')),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await SupabaseService.updateMenuItem(
                    itemId: item['id'],
                    name: nameController.text,
                    description: descController.text,
                    price: double.tryParse(priceController.text),
                  );
                  Navigator.pop(context);
                  _loadMenu();
                },
                child: const Text('Enregistrer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showItemStats(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item['name'] ?? 'Statistiques'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatRow(Icons.shopping_cart, 'Commandes', '${item['order_count'] ?? 0}'),
            _buildStatRow(Icons.star, 'Note moyenne', '${(item['avg_rating'] ?? 0).toStringAsFixed(1)}/5'),
            _buildStatRow(Icons.reviews, 'Avis', '${item['total_reviews'] ?? 0}'),
            if (item['last_ordered_at'] != null)
              _buildStatRow(Icons.access_time, 'Dernière commande', _formatDate(item['last_ordered_at'])),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '-';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Menu'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Plats'),
            Tab(text: 'Catégories'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              if (_tabController.index == 0) {
                _showAddItemDialog();
              } else {
                _showAddCategoryDialog();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Plats
                _items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            const Text('Aucun plat'),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _showAddItemDialog,
                              icon: const Icon(Icons.add),
                              label: const Text('Ajouter un plat'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        itemBuilder: (context, index) => _buildItemCard(_items[index]),
                      ),
                
                // Catégories
                _categories.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.category, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            const Text('Aucune catégorie'),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _showAddCategoryDialog,
                              icon: const Icon(Icons.add),
                              label: const Text('Ajouter une catégorie'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) => _buildCategoryCard(_categories[index]),
                      ),
              ],
            ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final isAvailable = item['is_available'] ?? true;
    final isDailySpecial = item['is_daily_special'] ?? false;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showItemOptions(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                  image: item['image_url'] != null
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(item['image_url']),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: item['image_url'] == null
                    ? const Icon(Icons.fastfood, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 12),
              
              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item['name'] ?? '',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isAvailable ? Colors.black : Colors.grey,
                            ),
                          ),
                        ),
                        if (isDailySpecial)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('🔥 PROMO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    if (item['description'] != null)
                      Text(
                        item['description'],
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${(item['price'] as num).toStringAsFixed(0)} DA',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.shopping_cart, size: 14, color: Colors.grey[500]),
                        Text(' ${item['order_count'] ?? 0}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                        const SizedBox(width: 8),
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        Text(' ${(item['avg_rating'] ?? 0).toStringAsFixed(1)}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      ],
                    ),
                    if (!isAvailable)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Indisponible', style: TextStyle(color: Colors.red, fontSize: 10)),
                      ),
                  ],
                ),
              ),
              
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    final itemCount = _items.where((i) => i['category_id'] == category['id']).length;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
          child: const Icon(Icons.category, color: AppTheme.primaryColor),
        ),
        title: Text(category['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$itemCount plat(s)'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
