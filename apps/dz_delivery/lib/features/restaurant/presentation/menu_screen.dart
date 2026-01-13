import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    setState(() => _isLoading = true);
    try {
      final items = await SupabaseService.getMenuItems();
      final categories = await SupabaseService.getMenuCategories();
      setState(() {
        _items = items;
        _categories = categories;
      });
    } catch (e) {
      debugPrint('Erreur: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAddItemDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un plat'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nom du plat')),
              const SizedBox(height: 12),
              TextField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Prix (DA)')),
              const SizedBox(height: 12),
              TextField(controller: descController, maxLines: 2, decoration: const InputDecoration(labelText: 'Description')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && priceController.text.isNotEmpty) {
                await SupabaseService.addMenuItem(
                  name: nameController.text,
                  price: double.parse(priceController.text),
                  description: descController.text.isEmpty ? null : descController.text,
                );
                Navigator.pop(context);
                _loadMenu();
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mon menu')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.restaurant_menu, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('Aucun plat dans le menu', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _showAddItemDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter un plat'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadMenu,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    itemBuilder: (context, index) => _buildMenuItem(_items[index]),
                  ),
                ),
      floatingActionButton: _items.isNotEmpty
          ? FloatingActionButton(
              onPressed: _showAddItemDialog,
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildMenuItem(Map<String, dynamic> item) {
    final isAvailable = item['is_available'] ?? true;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                if (item['description'] != null)
                  Text(item['description'], style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                const SizedBox(height: 4),
                Text('${item['price']} DA', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Switch(
            value: isAvailable,
            onChanged: (value) {
              // TODO: Update availability
            },
            activeColor: Colors.green,
          ),
        ],
      ),
    );
  }
}
