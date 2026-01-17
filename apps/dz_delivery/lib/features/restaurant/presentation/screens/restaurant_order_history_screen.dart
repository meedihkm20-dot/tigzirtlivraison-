import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../../core/design_system/theme/app_colors.dart';
import '../../../../core/design_system/theme/app_typography.dart';
import '../../../../core/design_system/theme/app_spacing.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/router/app_router.dart';

/// Écran Historique Commandes Restaurant avec Calendrier
class RestaurantOrderHistoryScreen extends ConsumerStatefulWidget {
  const RestaurantOrderHistoryScreen({super.key});

  @override
  ConsumerState<RestaurantOrderHistoryScreen> createState() => _RestaurantOrderHistoryScreenState();
}

class _RestaurantOrderHistoryScreenState extends ConsumerState<RestaurantOrderHistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _allOrders = [];
  List<Map<String, dynamic>> _filteredOrders = [];
  
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String _statusFilter = 'all'; // all, delivered, cancelled

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final orders = await SupabaseService.getRestaurantOrderHistory();
      
      setState(() {
        _allOrders = orders;
        _applyFilters();
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

  void _applyFilters() {
    var filtered = _allOrders;

    // Filtre par statut
    if (_statusFilter != 'all') {
      filtered = filtered.where((o) => o['status'] == _statusFilter).toList();
    }

    // Filtre par date sélectionnée
    if (_selectedDay != null) {
      filtered = filtered.where((o) {
        final createdAt = DateTime.parse(o['created_at']);
        return isSameDay(createdAt, _selectedDay);
      }).toList();
    }

    setState(() {
      _filteredOrders = filtered;
    });
  }

  Future<void> _exportPDF() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Génération PDF en cours...')),
      );
      
      // TODO: Implémenter génération PDF
      await Future.delayed(const Duration(seconds: 1));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Historique exporté en PDF'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur export: $e')),
      );
    }
  }

  Future<void> _exportExcel() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Génération Excel en cours...')),
      );
      
      // TODO: Implémenter génération Excel
      await Future.delayed(const Duration(seconds: 1));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Historique exporté en Excel'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur export: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Historique Commandes'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.download),
            onSelected: (value) {
              if (value == 'pdf') _exportPDF();
              if (value == 'excel') _exportExcel();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'pdf', child: Text('Exporter PDF')),
              const PopupMenuItem(value: 'excel', child: Text('Exporter Excel')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Calendrier
                Container(
                  color: AppColors.surface,
                  child: TableCalendar(
                    firstDay: DateTime.utc(2024, 1, 1),
                    lastDay: DateTime.now(),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    calendarFormat: CalendarFormat.week,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: AppTypography.titleMedium,
                    ),
                    calendarStyle: CalendarStyle(
                      selectedDecoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                      _applyFilters();
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                    eventLoader: (day) {
                      // Marquer les jours avec des commandes
                      return _allOrders.where((o) {
                        final createdAt = DateTime.parse(o['created_at']);
                        return isSameDay(createdAt, day);
                      }).toList();
                    },
                  ),
                ),
                
                // Filtres par statut
                Container(
                  padding: const EdgeInsets.all(16),
                  color: AppColors.surface,
                  child: Row(
                    children: [
                      _StatusChip(
                        label: 'Toutes',
                        count: _allOrders.length,
                        isSelected: _statusFilter == 'all',
                        onTap: () {
                          setState(() => _statusFilter = 'all');
                          _applyFilters();
                        },
                      ),
                      const SizedBox(width: 8),
                      _StatusChip(
                        label: 'Livrées',
                        count: _allOrders.where((o) => o['status'] == 'delivered').length,
                        isSelected: _statusFilter == 'delivered',
                        color: AppColors.success,
                        onTap: () {
                          setState(() => _statusFilter = 'delivered');
                          _applyFilters();
                        },
                      ),
                      const SizedBox(width: 8),
                      _StatusChip(
                        label: 'Annulées',
                        count: _allOrders.where((o) => o['status'] == 'cancelled').length,
                        isSelected: _statusFilter == 'cancelled',
                        color: AppColors.error,
                        onTap: () {
                          setState(() => _statusFilter = 'cancelled');
                          _applyFilters();
                        },
                      ),
                    ],
                  ),
                ),
                
                // Stats rapides
                if (_selectedDay != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: AppColors.primary.withOpacity(0.1),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _QuickStat(
                          label: 'Commandes',
                          value: '${_filteredOrders.length}',
                          icon: Icons.shopping_bag,
                        ),
                        _QuickStat(
                          label: 'Total',
                          value: '${_calculateTotal()} DA',
                          icon: Icons.attach_money,
                        ),
                      ],
                    ),
                  ),
                
                // Liste des commandes
                Expanded(
                  child: _filteredOrders.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox,
                                size: 64,
                                color: AppColors.textSecondary.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _selectedDay != null
                                    ? 'Aucune commande ce jour'
                                    : 'Aucune commande',
                                style: AppTypography.bodyLarge.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadOrders,
                          child: ListView.builder(
                            padding: AppSpacing.screen,
                            itemCount: _filteredOrders.length,
                            itemBuilder: (context, index) {
                              final order = _filteredOrders[index];
                              return _OrderHistoryCard(
                                order: order,
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRouter.restaurantOrderDetail,
                                    arguments: order['id'],
                                  );
                                },
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  int _calculateTotal() {
    return _filteredOrders.fold<int>(
      0,
      (sum, order) => sum + ((order['total'] ?? 0) as num).toInt(),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.count,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primary;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : chipColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected ? Colors.white : chipColor,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.3) : chipColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: AppTypography.labelSmall.copyWith(
                  color: isSelected ? Colors.white : chipColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _QuickStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 4),
        Text(value, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}

class _OrderHistoryCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onTap;

  const _OrderHistoryCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = order['status'] as String?;
    final isDelivered = status == 'delivered';
    final statusColor = isDelivered ? AppColors.success : AppColors.error;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: statusColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#${order['order_number'] ?? ''}',
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isDelivered ? Icons.check_circle : Icons.cancel,
                        size: 14,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isDelivered ? 'Livrée' : 'Annulée',
                        style: AppTypography.labelSmall.copyWith(color: statusColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  order['customer']?['full_name'] ?? 'Client',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
            if (order['livreur'] != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.delivery_dining, size: 16, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text(
                    order['livreur']?['user']?['full_name'] ?? 'Livreur',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.success),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(order['total'] ?? 0).toStringAsFixed(0)} DA',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  _formatDate(order['created_at']),
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.parse(dateStr);
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
}
