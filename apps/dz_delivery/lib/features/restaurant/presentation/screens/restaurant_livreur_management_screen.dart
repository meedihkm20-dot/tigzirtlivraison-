import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/design_system/theme/app_colors.dart';
import '../../../../core/design_system/theme/app_typography.dart';
import '../../../../core/design_system/theme/app_spacing.dart';
import '../../../../core/services/supabase_service.dart';

/// Écran Gestion Livreurs Restaurant
/// - Liste des livreurs avec qui le restaurant a travaillé
/// - Dette totale par livreur (argent collecté non encore payé)
/// - Historique des paiements
/// - Filtres par livreur, date, statut
class RestaurantLivreurManagementScreen extends StatefulWidget {
  const RestaurantLivreurManagementScreen({super.key});

  @override
  State<RestaurantLivreurManagementScreen> createState() => _RestaurantLivreurManagementScreenState();
}

class _RestaurantLivreurManagementScreenState extends State<RestaurantLivreurManagementScreen> {
  List<Map<String, dynamic>> _livreurDebts = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // all, unpaid, partial, paid

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final restaurant = await SupabaseService.getMyRestaurant();
      if (restaurant == null) return;

      // Récupérer toutes les commandes livrées avec livreur
      final orders = await SupabaseService.client.from('orders')
          .select('''
            id,
            order_number,
            total,
            delivery_fee,
            livreur_commission,
            delivered_at,
            payment_method,
            livreur:livreurs!orders_livreur_id_fkey(
              id,
              user:profiles(full_name, phone)
            )
          ''')
          .eq('restaurant_id', restaurant['id'])
          .eq('status', 'delivered')
          .eq('payment_method', 'cash')
          .order('delivered_at', ascending: false);

      // Grouper par livreur et calculer les dettes
      final Map<String, Map<String, dynamic>> livreurMap = {};
      
      for (final order in orders) {
        final livreur = order['livreur'];
        if (livreur == null) continue;
        
        final livreurId = livreur['id'] as String;
        final total = (order['total'] as num?)?.toDouble() ?? 0;
        final commission = (order['livreur_commission'] as num?)?.toDouble() ?? 0;
        final amountCollected = total; // Le livreur a collecté le total
        final amountOwed = amountCollected - commission; // Ce que le restaurant doit récupérer
        
        if (!livreurMap.containsKey(livreurId)) {
          livreurMap[livreurId] = {
            'livreur_id': livreurId,
            'livreur_name': livreur['user']?['full_name'] ?? 'Livreur',
            'livreur_phone': livreur['user']?['phone'] ?? '',
            'total_collected': 0.0,
            'total_owed': 0.0,
            'total_commission': 0.0,
            'order_count': 0,
            'orders': <Map<String, dynamic>>[],
          };
        }
        
        livreurMap[livreurId]!['total_collected'] = 
            (livreurMap[livreurId]!['total_collected'] as double) + amountCollected;
        livreurMap[livreurId]!['total_owed'] = 
            (livreurMap[livreurId]!['total_owed'] as double) + amountOwed;
        livreurMap[livreurId]!['total_commission'] = 
            (livreurMap[livreurId]!['total_commission'] as double) + commission;
        livreurMap[livreurId]!['order_count'] = 
            (livreurMap[livreurId]!['order_count'] as int) + 1;
        (livreurMap[livreurId]!['orders'] as List).add(order);
      }

      setState(() {
        _livreurDebts = livreurMap.values.toList()
          ..sort((a, b) => (b['total_owed'] as double).compareTo(a['total_owed'] as double));
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _showLivreurDetails(Map<String, dynamic> livreurDebt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LivreurDetailsSheet(livreurDebt: livreurDebt),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gestion Livreurs'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filtres
                Padding(
                  padding: AppSpacing.screen,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'Tous',
                        isSelected: _selectedFilter == 'all',
                        onTap: () => setState(() => _selectedFilter = 'all'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Dette',
                        isSelected: _selectedFilter == 'unpaid',
                        onTap: () => setState(() => _selectedFilter = 'unpaid'),
                      ),
                    ],
                  ),
                ),

                // Résumé total
                Container(
                  margin: AppSpacing.screen,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, Color(0xFF1565C0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Dette Totale',
                        style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_livreurDebts.fold<double>(0, (sum, l) => sum + (l['total_owed'] as double)).toStringAsFixed(0)} DA',
                        style: AppTypography.headlineLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_livreurDebts.length} livreur${_livreurDebts.length > 1 ? 's' : ''}',
                        style: AppTypography.bodySmall.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),

                // Liste des livreurs
                Expanded(
                  child: _livreurDebts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.delivery_dining, size: 64, color: AppColors.textSecondary.withOpacity(0.3)),
                              const SizedBox(height: 16),
                              Text(
                                'Aucune dette livreur',
                                style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView.builder(
                            padding: AppSpacing.screen,
                            itemCount: _livreurDebts.length,
                            itemBuilder: (context, index) {
                              final livreurDebt = _livreurDebts[index];
                              return _LivreurDebtCard(
                                livreurDebt: livreurDebt,
                                onTap: () => _showLivreurDetails(livreurDebt),
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
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _LivreurDebtCard extends StatelessWidget {
  final Map<String, dynamic> livreurDebt;
  final VoidCallback onTap;

  const _LivreurDebtCard({
    required this.livreurDebt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final totalOwed = (livreurDebt['total_owed'] as double);
    final orderCount = livreurDebt['order_count'] as int;
    final livreurName = livreurDebt['livreur_name'] as String;
    final livreurPhone = livreurDebt['livreur_phone'] as String;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delivery_dining, color: AppColors.warning),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    livreurName,
                    style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    livreurPhone,
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  Text(
                    '$orderCount commande${orderCount > 1 ? 's' : ''}',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${totalOwed.toStringAsFixed(0)} DA',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
                Text(
                  'À récupérer',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LivreurDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> livreurDebt;

  const _LivreurDetailsSheet({required this.livreurDebt});

  @override
  Widget build(BuildContext context) {
    final orders = livreurDebt['orders'] as List<Map<String, dynamic>>;
    final totalOwed = (livreurDebt['total_owed'] as double);
    final totalCollected = (livreurDebt['total_collected'] as double);
    final totalCommission = (livreurDebt['total_commission'] as double);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      livreurDebt['livreur_name'],
                      style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      livreurDebt['livreur_phone'],
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),
          
          // Résumé
          Padding(
            padding: AppSpacing.screen,
            child: Column(
              children: [
                _SummaryRow('Total collecté', '${totalCollected.toStringAsFixed(0)} DA'),
                _SummaryRow('Commission livreur', '- ${totalCommission.toStringAsFixed(0)} DA', color: AppColors.success),
                const Divider(),
                _SummaryRow('À récupérer', '${totalOwed.toStringAsFixed(0)} DA', bold: true, color: AppColors.error),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Liste des commandes
          Expanded(
            child: ListView.builder(
              padding: AppSpacing.screen,
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final total = (order['total'] as num?)?.toDouble() ?? 0;
                final commission = (order['livreur_commission'] as num?)?.toDouble() ?? 0;
                final owed = total - commission;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '#${order['order_number']}',
                            style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${owed.toStringAsFixed(0)} DA',
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDate(order['delivered_at']),
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total: ${total.toStringAsFixed(0)} DA • Commission: ${commission.toStringAsFixed(0)} DA',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.parse(dateStr);
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final bool bold;

  const _SummaryRow(this.label, this.value, {this.color, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: color ?? AppColors.textSecondary,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: color ?? AppColors.textPrimary,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
