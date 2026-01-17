import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/design_system/theme/app_colors.dart';
import '../../../../core/design_system/theme/app_typography.dart';
import '../../../../core/design_system/theme/app_spacing.dart';
import '../../../../core/design_system/theme/app_shadows.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/router/app_router.dart';
import '../../../../providers/providers.dart';

/// Écran Historique Livreur V2 - Premium
/// Liste des livraisons terminées avec filtres, stats et analytics
class LivreurHistoryScreenV2 extends ConsumerStatefulWidget {
  const LivreurHistoryScreenV2({super.key});

  @override
  ConsumerState<LivreurHistoryScreenV2> createState() => _LivreurHistoryScreenV2State();
}

class _LivreurHistoryScreenV2State extends ConsumerState<LivreurHistoryScreenV2>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  List<Map<String, dynamic>> _deliveries = [];
  String _selectedFilter = 'all'; // all, today, week, month
  bool _showAnalytics = false;
  bool _showCalendar = false;
  
  // Calendrier
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  
  late AnimationController _analyticsController;
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _analyticsController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _loadHistory();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _analyticsController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      _loadHistory();
    });
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final history = await SupabaseService.getLivreurDeliveryHistory();
      if (mounted) {
        setState(() {
          _deliveries = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement historique: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredDeliveries {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'today':
        return _deliveries.where((d) {
          final date = DateTime.parse(d['delivered_at'] ?? d['created_at']);
          return date.year == now.year && 
                 date.month == now.month && 
                 date.day == now.day;
        }).toList();
      case 'week':
        final weekAgo = now.subtract(const Duration(days: 7));
        return _deliveries.where((d) {
          final date = DateTime.parse(d['delivered_at'] ?? d['created_at']);
          return date.isAfter(weekAgo);
        }).toList();
      case 'month':
        return _deliveries.where((d) {
          final date = DateTime.parse(d['delivered_at'] ?? d['created_at']);
          return date.year == now.year && date.month == now.month;
        }).toList();
      case 'custom':
        if (_selectedDay != null) {
          return _deliveries.where((d) {
            final date = DateTime.parse(d['delivered_at'] ?? d['created_at']);
            return isSameDay(date, _selectedDay!);
          }).toList();
        }
        return _deliveries;
      default:
        return _deliveries;
    }
  }

  List<Map<String, dynamic>> _getFilteredDeliveries() => _filteredDeliveries;

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredDeliveries;
    final totalEarnings = filtered.fold<double>(
      0, 
      (sum, d) => sum + ((d['delivery_fee'] as num?)?.toDouble() ?? 0),
    );
    final totalTips = filtered.fold<double>(
      0, 
      (sum, d) => sum + ((d['tip_amount'] as num?)?.toDouble() ?? 0),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Historique'),
        backgroundColor: AppColors.livreurPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showCalendar ? Icons.calendar_today : Icons.calendar_month),
            onPressed: () => setState(() => _showCalendar = !_showCalendar),
            tooltip: 'Calendrier',
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _showExportOptions,
            tooltip: 'Exporter',
          ),
          IconButton(
            icon: Icon(_showAnalytics ? Icons.analytics_outlined : Icons.analytics),
            onPressed: _toggleAnalytics,
            tooltip: 'Analytics',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.livreurPrimary))
          : Column(
              children: [
                _buildStatsCard(filtered.length, totalEarnings, totalTips),
                if (_showCalendar) _buildCalendar(),
                if (_showAnalytics) _buildAnalyticsCard(filtered),
                _buildFilters(),
                Expanded(
                  child: filtered.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadHistory,
                          color: AppColors.livreurPrimary,
                          child: ListView.builder(
                            padding: AppSpacing.screen,
                            itemCount: filtered.length,
                            itemBuilder: (ctx, i) => _buildDeliveryCard(filtered[i]),
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatsCard(int count, double earnings, double tips) {
    return Container(
      margin: AppSpacing.screen,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.livreurGradient,
        borderRadius: AppSpacing.borderRadiusLg,
        boxShadow: AppShadows.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem('🚚', '$count', 'Livraisons'),
          ),
          Container(width: 1, height: 40, color: Colors.white30),
          Expanded(
            child: _buildStatItem('💰', '${earnings.toStringAsFixed(0)}', 'DA gagnés'),
          ),
          Container(width: 1, height: 40, color: Colors.white30),
          Expanded(
            child: _buildStatItem('💝', '${tips.toStringAsFixed(0)}', 'DA tips'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTypography.titleLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      margin: AppSpacing.screenHorizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Tout', 'all'),
            const SizedBox(width: 8),
            _buildFilterChip('Aujourd\'hui', 'today'),
            const SizedBox(width: 8),
            _buildFilterChip('7 jours', 'week'),
            const SizedBox(width: 8),
            _buildFilterChip('Ce mois', 'month'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedFilter = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.livreurPrimary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.livreurPrimary : AppColors.outline,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: AppSpacing.screen,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 80, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              'Aucune livraison',
              style: AppTypography.titleMedium.copyWith(color: AppColors.textTertiary),
            ),
            const SizedBox(height: 8),
            Text(
              'Vos livraisons terminées apparaîtront ici',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryCard(Map<String, dynamic> delivery) {
    final restaurantName = delivery['restaurant_name'] ?? 'Restaurant';
    final deliveryAddress = delivery['delivery_address'] ?? 'Adresse';
    final deliveryFee = (delivery['delivery_fee'] as num?)?.toDouble() ?? 0;
    final tipAmount = (delivery['tip_amount'] as num?)?.toDouble() ?? 0;
    final distance = (delivery['distance'] as num?)?.toDouble() ?? 0;
    final deliveredAt = delivery['delivered_at'] ?? delivery['created_at'];
    final rating = delivery['livreur_rating'] as int?;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        AppRouter.orderTracking,
        arguments: delivery['id'],
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.borderRadiusMd,
          boxShadow: AppShadows.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      restaurantName[0].toUpperCase(),
                      style: AppTypography.titleLarge.copyWith(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(restaurantName, style: AppTypography.titleSmall),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: AppColors.textTertiary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              deliveryAddress,
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${(deliveryFee + tipAmount).toStringAsFixed(0)} DA',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (tipAmount > 0)
                      Text(
                        '+${tipAmount.toStringAsFixed(0)} DA tip',
                        style: AppTypography.labelSmall.copyWith(color: AppColors.warning),
                      ),
                  ],
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.straighten, size: 14, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      '${distance.toStringAsFixed(1)} km',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.access_time, size: 14, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      _dateFormat.format(DateTime.parse(deliveredAt)),
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                    ),
                  ],
                ),
                if (rating != null)
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '$rating/5',
                        style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  void _toggleAnalytics() {
    setState(() => _showAnalytics = !_showAnalytics);
    if (_showAnalytics) {
      _analyticsController.forward();
    } else {
      _analyticsController.reverse();
    }
  }

  Widget _buildCalendar() {
    return Container(
      margin: AppSpacing.screen,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        boxShadow: AppShadows.md,
      ),
      child: TableCalendar<Map<String, dynamic>>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        eventLoader: _getEventsForDay,
        startingDayOfWeek: StartingDayOfWeek.monday,
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          selectedDecoration: BoxDecoration(
            color: AppColors.livreurPrimary,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: AppColors.livreurPrimary.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          markerDecoration: BoxDecoration(
            color: AppColors.success,
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
          formatButtonShowsNext: false,
          formatButtonDecoration: BoxDecoration(
            color: AppColors.livreurPrimary,
            borderRadius: BorderRadius.circular(12.0),
          ),
          formatButtonTextStyle: const TextStyle(
            color: Colors.white,
          ),
        ),
        onDaySelected: _onDaySelected,
        onFormatChanged: (format) {
          if (_calendarFormat != format) {
            setState(() => _calendarFormat = format);
          }
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        selectedDayPredicate: (day) {
          return isSameDay(_selectedDay, day);
        },
      ),
    );
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _deliveries.where((delivery) {
      final deliveryDate = DateTime.parse(delivery['delivered_at'] ?? delivery['created_at']);
      return isSameDay(deliveryDate, day);
    }).toList();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _selectedFilter = 'custom';
      });
    }
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Exporter les données', style: AppTypography.titleMedium),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: AppColors.error),
              title: const Text('Rapport PDF'),
              subtitle: const Text('Générer un rapport détaillé'),
              onTap: () {
                Navigator.pop(ctx);
                _exportToPDF();
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt, color: AppColors.info),
              title: const Text('Bon de livraison'),
              subtitle: const Text('Imprimer les bons de livraison'),
              onTap: () {
                Navigator.pop(ctx);
                _generateDeliveryReceipts();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: AppColors.success),
              title: const Text('Partager les données'),
              subtitle: const Text('Exporter au format CSV'),
              onTap: () {
                Navigator.pop(ctx);
                _shareData();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportToPDF() async {
    try {
      final pdf = pw.Document();
      final filtered = _getFilteredDeliveries();
      final totalEarnings = filtered.fold<double>(0, (sum, d) => 
        sum + ((d['delivery_fee'] as num?)?.toDouble() ?? 0));

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text('Rapport de Livraisons - DZ Delivery'),
                ),
                pw.SizedBox(height: 20),
                pw.Text('Période: ${_getFilterLabel()}'),
                pw.Text('Total livraisons: ${filtered.length}'),
                pw.Text('Gains totaux: ${totalEarnings.toStringAsFixed(0)} DA'),
                pw.SizedBox(height: 20),
                pw.Table.fromTextArray(
                  headers: ['Date', 'Restaurant', 'Montant', 'Statut'],
                  data: filtered.map((delivery) => [
                    _dateFormat.format(DateTime.parse(delivery['created_at'])),
                    delivery['restaurant_name'] ?? 'N/A',
                    '${delivery['delivery_fee'] ?? 0} DA',
                    delivery['status'] ?? 'N/A',
                  ]).toList(),
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur génération PDF: $e')),
      );
    }
  }

  Future<void> _generateDeliveryReceipts() async {
    try {
      final filtered = _getFilteredDeliveries();
      final pdf = pw.Document();

      for (final delivery in filtered) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('BON DE LIVRAISON', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 20),
                  pw.Text('Commande #${delivery['id']?.toString().substring(0, 8) ?? 'N/A'}'),
                  pw.Text('Date: ${_dateFormat.format(DateTime.parse(delivery['created_at']))}'),
                  pw.Text('Restaurant: ${delivery['restaurant_name'] ?? 'N/A'}'),
                  pw.Text('Client: ${delivery['customer_name'] ?? 'N/A'}'),
                  pw.Text('Adresse: ${delivery['delivery_address'] ?? 'N/A'}'),
                  pw.Text('Montant: ${delivery['total'] ?? 0} DA'),
                  pw.Text('Frais livraison: ${delivery['delivery_fee'] ?? 0} DA'),
                  pw.SizedBox(height: 40),
                  pw.Text('Signature livreur: ___________________'),
                  pw.SizedBox(height: 20),
                  pw.Text('Signature client: ___________________'),
                ],
              );
            },
          ),
        );
      }

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur génération bons: $e')),
      );
    }
  }

  Future<void> _shareData() async {
    try {
      final filtered = _getFilteredDeliveries();
      final csvData = StringBuffer();
      
      // En-têtes CSV
      csvData.writeln('Date,Restaurant,Client,Montant,Frais Livraison,Statut');
      
      // Données
      for (final delivery in filtered) {
        csvData.writeln([
          _dateFormat.format(DateTime.parse(delivery['created_at'])),
          delivery['restaurant_name'] ?? 'N/A',
          delivery['customer_name'] ?? 'N/A',
          delivery['total'] ?? 0,
          delivery['delivery_fee'] ?? 0,
          delivery['status'] ?? 'N/A',
        ].join(','));
      }

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/livraisons_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csvData.toString());

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Données de livraisons - ${_getFilterLabel()}',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur partage: $e')),
      );
    }
  }

  String _getFilterLabel() {
    switch (_selectedFilter) {
      case 'today': return 'Aujourd\'hui';
      case 'week': return '7 derniers jours';
      case 'month': return 'Ce mois';
      case 'custom': return _selectedDay != null ? 
        DateFormat('dd/MM/yyyy').format(_selectedDay!) : 'Personnalisé';
      default: return 'Toutes les livraisons';
    }
  }

  Widget _buildAnalyticsCard(List<Map<String, dynamic>> deliveries) {
    if (deliveries.isEmpty) return const SizedBox.shrink();

    final avgEarnings = deliveries.fold<double>(0, (sum, d) => 
      sum + ((d['delivery_fee'] as num?)?.toDouble() ?? 0)) / deliveries.length;
    
    final avgDistance = deliveries.fold<double>(0, (sum, d) => 
      sum + ((d['distance'] as num?)?.toDouble() ?? 0)) / deliveries.length;
    
    final avgRating = deliveries.where((d) => d['livreur_rating'] != null)
        .fold<double>(0, (sum, d) => sum + (d['livreur_rating'] as int)) / 
        deliveries.where((d) => d['livreur_rating'] != null).length;

    final topRestaurants = _getTopRestaurants(deliveries);
    final hourlyStats = _getHourlyStats(deliveries);

    return AnimatedBuilder(
      animation: _analyticsController,
      child: Container(
        margin: AppSpacing.screen,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.borderRadiusLg,
          boxShadow: AppShadows.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Analytics détaillées', style: AppTypography.titleMedium),
            const SizedBox(height: 16),
            
            // Moyennes
            Row(
              children: [
                Expanded(child: _buildAnalyticItem('💰', '${avgEarnings.toStringAsFixed(0)} DA', 'Gain moyen')),
                Expanded(child: _buildAnalyticItem('📍', '${avgDistance.toStringAsFixed(1)} km', 'Distance moy.')),
                Expanded(child: _buildAnalyticItem('⭐', avgRating.isNaN ? 'N/A' : avgRating.toStringAsFixed(1), 'Note moyenne')),
              ],
            ),
            
            const Divider(height: 24),
            
            // Top restaurants
            Text('Top Restaurants', style: AppTypography.titleSmall),
            const SizedBox(height: 8),
            ...topRestaurants.take(3).map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(r['name'], style: AppTypography.bodyMedium),
                  Text('${r['count']} livraisons', style: AppTypography.labelMedium.copyWith(color: AppColors.textTertiary)),
                ],
              ),
            )),
            
            const Divider(height: 24),
            
            // Heures de pointe
            Text('Heures de pointe', style: AppTypography.titleSmall),
            const SizedBox(height: 8),
            ...hourlyStats.take(3).map((h) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${h['hour']}h - ${h['hour'] + 1}h', style: AppTypography.bodyMedium),
                  Text('${h['count']} livraisons', style: AppTypography.labelMedium.copyWith(color: AppColors.textTertiary)),
                ],
              ),
            )),
          ],
        ),
      ),
      builder: (context, child) => Transform.scale(
        scale: 0.8 + (_analyticsController.value * 0.2),
        child: Opacity(
          opacity: _analyticsController.value,
          child: child,
        ),
      ),
    );
  }

  Widget _buildAnalyticItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(value, style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary)),
      ],
    );
  }

  List<Map<String, dynamic>> _getTopRestaurants(List<Map<String, dynamic>> deliveries) {
    final Map<String, int> restaurantCounts = {};
    
    for (final delivery in deliveries) {
      final name = delivery['restaurant_name'] as String? ?? 'Restaurant';
      restaurantCounts[name] = (restaurantCounts[name] ?? 0) + 1;
    }
    
    final sorted = restaurantCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.map((e) => {'name': e.key, 'count': e.value}).toList();
  }

  List<Map<String, dynamic>> _getHourlyStats(List<Map<String, dynamic>> deliveries) {
    final Map<int, int> hourlyCounts = {};
    
    for (final delivery in deliveries) {
      final date = DateTime.parse(delivery['delivered_at'] ?? delivery['created_at']);
      final hour = date.hour;
      hourlyCounts[hour] = (hourlyCounts[hour] ?? 0) + 1;
    }
    
    final sorted = hourlyCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.map((e) => {'hour': e.key, 'count': e.value}).toList();
  }
}
