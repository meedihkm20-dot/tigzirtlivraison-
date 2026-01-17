import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../../core/design_system/theme/app_colors.dart';
import '../../../../core/design_system/theme/app_typography.dart';
import '../../../../core/design_system/theme/app_spacing.dart';
import '../../../../core/design_system/theme/app_shadows.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/router/app_router.dart';

/// Écran historique complet des commandes restaurant
/// Calendrier + Filtres + Export
class RestaurantOrderHistoryScreen extends StatefulWidget {
  const RestaurantOrderHistoryScreen({super.key});

  @override
  State<RestaurantOrderHistoryScreen> createState() => _RestaurantOrderHistoryScreenState();
}

class _RestaurantOrderHistoryScreenState extends State<RestaurantOrderHistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = [];
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String _statusFilter = 'all'; // 'all', 'delivered', 'cancelled'
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final orders = await SupabaseService.getRestaurantOrderHistory();
      if (mounted) {
        setState(() => _orders = orders);
      }
    } catch (e) {
      debugPrint('Erreur chargement historique: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredOrders {
    var orders = _orders;
    
    // Filter by selected day
    if (_selectedDay != null) {
      orders = orders.where((o) {
        final createdAt = DateTime.tryParse(o['created_at'] ?? '');
        if (createdAt == null) return false;
        return createdAt.year == _selectedDay!.year &&
            createdAt.month == _selectedDay!.month &&
            createdAt.day == _selectedDay!.day;
      }).toList();
    }
    
    // Filter by status
    if (_statusFilter != 'all') {
      orders = orders.where((o) => o['status'] == _statusFilter).toList();
    }
    
    // Filter by search
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      orders = orders.where((o) {
        final orderNumber = (o['order_number'] ?? '').toString().toLowerCase();
        final customerName = (o['customer']?['full_name'] ?? '').toString().toLowerCase();
        return orderNumber.contains(query) || customerName.contains(query);
      }).toList();
    }
    
    return orders;
  }

  Map<DateTime, int> get _ordersByDay {
    final map = <DateTime, int>{};
    for (final order in _orders) {
      final createdAt = DateTime.tryParse(order['created_at'] ?? '');
      if (createdAt != null) {
        final day = DateTime(createdAt.year, createdAt.month, createdAt.day);
        map[day] = (map[day] ?? 0) + 1;
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final filteredOrders = _filteredOrders;
    final ordersByDay = _ordersByDay;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('📅 Historique'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _showExportDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Calendar
                Container(
                  color: AppColors.surface,
                  child: TableCalendar(
                    firstDay: DateTime.now().subtract(const Duration(days: 365)),
                    lastDay: DateTime.now(),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    calendarFormat: CalendarFormat.month,
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: AppTypography.titleMedium,
                    ),
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    eventLoader: (day) {
                      final count = ordersByDay[DateTime(day.year, day.month, day.day)] ?? 0;
                      return List.generate(count > 3 ? 3 : count, (index) => 'order');
                    },
                  ),
                ),
                
                // Filters
                Container(
                  color: AppColors.surface,
                  padding: AppSpacing.screen,
                  child: Column(
                    children: [
                      // Search
                      TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Rechercher...',
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
                      
                      // Status filters
                      Row(
                        children: [
                          _buildFilterChip('all', 'Toutes', Icons.list),
                          const SizedBox(width: 8),
                          _buildFilterChip('delivered', 'Livrées', Icons.check_circle),
                          const SizedBox(width: 8),
                          _buildFilterChip('cancelled', 'Annulées', Icons.cancel),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Stats bar
                if (_selectedDay != null)
                  Container(
                    padding: AppSpacing.card,
                    color: AppColors.primarySurface,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          '${filteredOrders.length} commande${filteredOrders.length > 1 ? 's' : ''} le ${DateFormat('dd/MM/yyyy').format(_selectedDay!)}',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_selectedDay != null)
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => setState(() => _selectedDay = null),
                            color: AppColors.primary,
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                      ],
                    ),
                  ),
                
                // Orders list
                Expanded(
                  child: filteredOrders.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadOrders,
                          child: ListView.builder(
                            padding: AppSpacing.screen,
                            itemCount: filteredOrders.length,
                            itemBuilder: (context, index) => _buildOrderCard(filteredOrders[index]),
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = _statusFilter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _statusFilter = value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
            borderRadius: AppSpacing.borderRadiusRound,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox,
            size: 64,
            color: AppColors.textTertiary,
          ),
          AppSpacing.vMd,
          Text(
            'Aucune commande',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          AppSpacing.vSm,
          Text(
            _selectedDay != null
                ? 'Aucune commande ce jour'
                : 'Aucune commande dans l\'historique',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] as String? ?? '';
    final items = order['order_items'] as List? ?? [];
    final itemCount = items.fold<int>(0, (sum, item) => sum + ((item['quantity'] as int?) ?? 1));
    final total = (order['total'] ?? 0).toDouble();
    final createdAt = DateTime.tryParse(order['created_at'] ?? '') ?? DateTime.now();
    final customerName = order['customer']?['full_name'] ?? 'Client';
    
    final isDelivered = status == 'delivered';
    final statusColor = isDelivered ? AppColors.success : AppColors.error;
    final statusLabel = isDelivered ? 'Livrée' : 'Annulée';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        boxShadow: AppShadows.sm,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pushNamed(
            context,
            AppRouter.restaurantOrderDetail,
            arguments: order['id'],
          ),
          borderRadius: AppSpacing.borderRadiusLg,
          child: Padding(
            padding: AppSpacing.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            '#${order['order_number']}',
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: AppSpacing.borderRadiusRound,
                            ),
                            child: Text(
                              statusLabel,
                              style: AppTypography.labelSmall.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      DateFormat('dd/MM HH:mm').format(createdAt),
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
                AppSpacing.vSm,
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: AppColors.textTertiary),
                    const SizedBox(width: 6),
                    Text(
                      customerName,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                AppSpacing.vSm,
                Row(
                  children: [
                    Icon(Icons.shopping_bag, size: 16, color: AppColors.textTertiary),
                    const SizedBox(width: 6),
                    Text(
                      '$itemCount article${itemCount > 1 ? 's' : ''}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.attach_money, size: 16, color: AppColors.success),
                    Text(
                      '${total.toStringAsFixed(0)} DA',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right, color: AppColors.textTertiary),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showExportDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.borderRadiusTopXl,
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: AppSpacing.screen,
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.outline,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    AppSpacing.vLg,
                    Text('Exporter l\'historique', style: AppTypography.headlineSmall),
                    AppSpacing.vLg,
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: AppColors.error),
                title: const Text('Export PDF'),
                onTap: () {
                  Navigator.pop(context);
                  _exportPDF();
                },
              ),
              ListTile(
                leading: const Icon(Icons.table_chart, color: AppColors.success),
                title: const Text('Export Excel'),
                onTap: () {
                  Navigator.pop(context);
                  _exportExcel();
                },
              ),
              AppSpacing.vLg,
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportPDF() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📄 Export PDF en cours...'),
        backgroundColor: AppColors.info,
      ),
    );
    // TODO: Implémenter export PDF
  }

  Future<void> _exportExcel() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📊 Export Excel en cours...'),
        backgroundColor: AppColors.success,
      ),
    );
    // TODO: Implémenter export Excel
  }
}
