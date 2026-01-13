import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';

class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  List<Map<String, dynamic>> _promotions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }

  Future<void> _loadPromotions() async {
    setState(() => _isLoading = true);
    try {
      final promos = await SupabaseService.getMyPromotions();
      setState(() => _promotions = promos);
    } catch (e) {
      debugPrint('Erreur: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showCreatePromoDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final valueController = TextEditingController();
    final codeController = TextEditingController();
    final minOrderController = TextEditingController(text: '0');
    String discountType = 'percentage';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nouvelle Promotion'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nom de la promo', hintText: 'Ex: -20% Weekend'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description (optionnel)'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('%'),
                        value: 'percentage',
                        groupValue: discountType,
                        onChanged: (v) => setDialogState(() => discountType = v!),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('DA'),
                        value: 'fixed',
                        groupValue: discountType,
                        onChanged: (v) => setDialogState(() => discountType = v!),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                TextField(
                  controller: valueController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Valeur',
                    suffixText: discountType == 'percentage' ? '%' : 'DA',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Code promo (optionnel)', hintText: 'Ex: WEEKEND20'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: minOrderController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Commande minimum (DA)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || valueController.text.isEmpty) return;
                
                await SupabaseService.createPromotion(
                  name: nameController.text,
                  description: descController.text.isEmpty ? null : descController.text,
                  discountType: discountType,
                  discountValue: double.tryParse(valueController.text) ?? 0,
                  code: codeController.text.isEmpty ? null : codeController.text.toUpperCase(),
                  minOrderAmount: double.tryParse(minOrderController.text) ?? 0,
                );
                
                Navigator.pop(context);
                _loadPromotions();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Promotion créée!'), backgroundColor: Colors.green),
                );
              },
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _togglePromo(String id, bool currentState) async {
    await SupabaseService.togglePromotion(id, !currentState);
    _loadPromotions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Promotions'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showCreatePromoDialog),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _promotions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_offer, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text('Aucune promotion', style: TextStyle(fontSize: 18, color: Colors.grey)),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _showCreatePromoDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Créer une promo'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPromotions,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _promotions.length,
                    itemBuilder: (context, index) => _buildPromoCard(_promotions[index]),
                  ),
                ),
      floatingActionButton: _promotions.isNotEmpty
          ? FloatingActionButton(
              onPressed: _showCreatePromoDialog,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildPromoCard(Map<String, dynamic> promo) {
    final isActive = promo['is_active'] == true;
    final discountType = promo['discount_type'] as String?;
    final discountValue = (promo['discount_value'] as num?)?.toDouble() ?? 0;
    final code = promo['code'] as String?;
    final usageCount = promo['usage_count'] as int? ?? 0;
    final usageLimit = promo['usage_limit'] as int?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.local_offer,
                    color: isActive ? AppTheme.primaryColor : Colors.grey,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(promo['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(
                        discountType == 'percentage' ? '-${discountValue.toInt()}%' : '-${discountValue.toInt()} DA',
                        style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isActive,
                  onChanged: (_) => _togglePromo(promo['id'], isActive),
                  activeColor: AppTheme.primaryColor,
                ),
              ],
            ),
            if (promo['description'] != null) ...[
              const SizedBox(height: 8),
              Text(promo['description'], style: TextStyle(color: Colors.grey[600])),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (code != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.code, size: 16, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(code, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      ],
                    ),
                  ),
                const Spacer(),
                Text(
                  usageLimit != null ? '$usageCount / $usageLimit utilisations' : '$usageCount utilisations',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
