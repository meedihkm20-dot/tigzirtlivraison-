import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';

class LivreursScreen extends StatefulWidget {
  const LivreursScreen({super.key});

  @override
  State<LivreursScreen> createState() => _LivreursScreenState();
}

class _LivreursScreenState extends State<LivreursScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _allLivreurs = [];
  List<Map<String, dynamic>> _pendingLivreurs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLivreurs();
  }

  Future<void> _loadLivreurs() async {
    setState(() => _isLoading = true);
    try {
      final all = await SupabaseService.getAllLivreurs();
      final pending = await SupabaseService.getPendingLivreurs();
      setState(() {
        _allLivreurs = all;
        _pendingLivreurs = pending;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyLivreur(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Valider le livreur'),
        content: Text('Voulez-vous valider "$name" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Valider')),
        ],
      ),
    );
    if (confirm == true) {
      await SupabaseService.verifyLivreur(id);
      _loadLivreurs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Livreur validé'), backgroundColor: AppTheme.successColor),
        );
      }
    }
  }

  Future<void> _deleteLivreur(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le livreur'),
        content: Text('Êtes-vous sûr de vouloir supprimer "$name" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await SupabaseService.deleteLivreur(id);
      _loadLivreurs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion Livreurs'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Tous (${_allLivreurs.length})'),
            Tab(text: 'En attente (${_pendingLivreurs.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLivreurList(_allLivreurs, showVerifyButton: false),
                _buildLivreurList(_pendingLivreurs, showVerifyButton: true),
              ],
            ),
    );
  }

  Widget _buildLivreurList(List<Map<String, dynamic>> livreurs, {required bool showVerifyButton}) {
    if (livreurs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delivery_dining, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(showVerifyButton ? 'Aucune demande en attente' : 'Aucun livreur', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLivreurs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: livreurs.length,
        itemBuilder: (context, index) {
          final livreur = livreurs[index];
          final isVerified = livreur['is_verified'] ?? false;
          final user = livreur['user'] as Map<String, dynamic>?;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: isVerified ? AppTheme.successColor : AppTheme.warningColor,
                child: Icon(isVerified ? Icons.verified : Icons.pending, color: Colors.white),
              ),
              title: Text(user?['full_name'] ?? 'Livreur', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user?['phone'] ?? ''),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: (livreur['is_online'] ?? false) ? AppTheme.successColor : Colors.grey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          (livreur['is_online'] ?? false) ? 'En ligne' : 'Hors ligne',
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${livreur['vehicle_type'] ?? 'moto'}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          Text(' ${(livreur['rating'] ?? 5.0).toStringAsFixed(1)}'),
                          const SizedBox(width: 16),
                          const Icon(Icons.delivery_dining, size: 18, color: Colors.grey),
                          Text(' ${livreur['total_deliveries'] ?? 0} livraisons'),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (showVerifyButton || !isVerified)
                            TextButton.icon(
                              onPressed: () => _verifyLivreur(livreur['id'], user?['full_name'] ?? ''),
                              icon: const Icon(Icons.verified, color: AppTheme.successColor),
                              label: const Text('Valider', style: TextStyle(color: AppTheme.successColor)),
                            ),
                          TextButton.icon(
                            onPressed: () => _deleteLivreur(livreur['id'], user?['full_name'] ?? ''),
                            icon: const Icon(Icons.delete, color: AppTheme.errorColor),
                            label: const Text('Supprimer', style: TextStyle(color: AppTheme.errorColor)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
