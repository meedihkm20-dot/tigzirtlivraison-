import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../../core/services/supabase_service.dart';

/// Écran Gestion Livreurs Admin Amélioré
/// - Liste complète avec stats
/// - Activer/Désactiver
/// - Fiche détaillée
/// - Appel téléphone
class LivreursManagementScreen extends StatefulWidget {
  const LivreursManagementScreen({super.key});

  @override
  State<LivreursManagementScreen> createState() => _LivreursManagementScreenState();
}

class _LivreursManagementScreenState extends State<LivreursManagementScreen> {
  List<Map<String, dynamic>> _livreurs = [];
  bool _isLoading = true;
  String _filter = 'all'; // all, active, inactive

  @override
  void initState() {
    super.initState();
    _loadLivreurs();
  }

  Future<void> _loadLivreurs() async {
    setState(() => _isLoading = true);
    try {
      final livreurs = await SupabaseService.getAllLivreurs();
      setState(() {
        _livreurs = livreurs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredLivreurs {
    switch (_filter) {
      case 'active':
        return _livreurs.where((l) => l['is_verified'] == true).toList();
      case 'inactive':
        return _livreurs.where((l) => l['is_verified'] != true).toList();
      default:
        return _livreurs;
    }
  }

  Future<void> _toggleStatus(String livreurId, bool currentStatus) async {
    try {
      await SupabaseService.toggleLivreurStatus(livreurId, !currentStatus);
      await _loadLivreurs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(currentStatus ? 'Livreur désactivé' : 'Livreur activé'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showLivreurDetails(String livreurId) async {
    showDialog(
      context: context,
      builder: (context) => _LivreurDetailsDialog(livreurId: livreurId),
    );
  }

  Future<void> _callLivreur(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        title: const Text('Gestion Livreurs', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLivreurs,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtres
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Tous (${_livreurs.length})',
                  isSelected: _filter == 'all',
                  onTap: () => setState(() => _filter = 'all'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Actifs',
                  isSelected: _filter == 'active',
                  onTap: () => setState(() => _filter = 'active'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Inactifs',
                  isSelected: _filter == 'inactive',
                  onTap: () => setState(() => _filter = 'inactive'),
                ),
              ],
            ),
          ),

          // Liste
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : _filteredLivreurs.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucun livreur',
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadLivreurs,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredLivreurs.length,
                          itemBuilder: (context, index) {
                            final livreur = _filteredLivreurs[index];
                            return _LivreurCard(
                              livreur: livreur,
                              onToggle: () => _toggleStatus(
                                livreur['id'],
                                livreur['is_verified'] ?? false,
                              ),
                              onDetails: () => _showLivreurDetails(livreur['id']),
                              onCall: () => _callLivreur(livreur['user']?['phone'] ?? ''),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : const Color(0xFF1B2838),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white54,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _LivreurCard extends StatelessWidget {
  final Map<String, dynamic> livreur;
  final VoidCallback onToggle;
  final VoidCallback onDetails;
  final VoidCallback onCall;

  const _LivreurCard({
    required this.livreur,
    required this.onToggle,
    required this.onDetails,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = livreur['is_verified'] ?? false;
    final isOnline = livreur['is_online'] ?? false;
    final name = livreur['user']?['full_name'] ?? 'Livreur';
    final phone = livreur['user']?['phone'] ?? '';
    final totalDeliveries = livreur['total_deliveries'] ?? 0;
    final rating = (livreur['rating'] as num?)?.toDouble() ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2838),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.blue.withOpacity(0.2),
                    child: const Icon(Icons.delivery_dining, color: Colors.blue),
                  ),
                  if (isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF1B2838), width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      phone,
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.orange, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${rating.toStringAsFixed(1)} • $totalDeliveries livraisons',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isActive ? 'Actif' : 'Inactif',
                  style: TextStyle(
                    color: isActive ? Colors.green : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCall,
                  icon: const Icon(Icons.phone, size: 16),
                  label: const Text('Appeler'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDetails,
                  icon: const Icon(Icons.info, size: 16),
                  label: const Text('Détails'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white54,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onToggle,
                  icon: Icon(isActive ? Icons.block : Icons.check, size: 16),
                  label: Text(isActive ? 'Désactiver' : 'Activer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActive ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                    foregroundColor: isActive ? Colors.red : Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LivreurDetailsDialog extends StatefulWidget {
  final String livreurId;

  const _LivreurDetailsDialog({required this.livreurId});

  @override
  State<_LivreurDetailsDialog> createState() => _LivreurDetailsDialogState();
}

class _LivreurDetailsDialogState extends State<_LivreurDetailsDialog> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await SupabaseService.getLivreurStats(widget.livreurId);
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1B2838),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _stats == null
                ? const Center(child: Text('Erreur', style: TextStyle(color: Colors.white)))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _stats!['user']?['full_name'] ?? 'Livreur',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white54),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _StatRow('Total Livraisons', '${_stats!['total_deliveries']}'),
                      _StatRow('Gains Totaux', '${(_stats!['total_earnings'] as num).toStringAsFixed(0)} DA'),
                      _StatRow('Note Moyenne', '${(_stats!['rating'] as num?)?.toStringAsFixed(1) ?? '0.0'} ⭐'),
                      _StatRow('Véhicule', _stats!['vehicle_type'] ?? 'N/A'),
                      _StatRow('Statut', _stats!['is_verified'] ? 'Vérifié' : 'Non vérifié'),
                      const SizedBox(height: 24),
                      const Text(
                        'Dernières Livraisons',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          itemCount: (_stats!['deliveries'] as List).take(10).length,
                          itemBuilder: (context, index) {
                            final delivery = (_stats!['deliveries'] as List)[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D1B2A),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat('dd/MM HH:mm').format(DateTime.parse(delivery['delivered_at'])),
                                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                                  ),
                                  Text(
                                    '${(delivery['livreur_commission'] as num).toStringAsFixed(0)} DA',
                                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
