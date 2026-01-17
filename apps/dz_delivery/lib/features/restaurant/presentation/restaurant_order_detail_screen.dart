import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/design_system/theme/app_colors.dart';
import '../../../core/design_system/theme/app_typography.dart';

class RestaurantOrderDetailScreen extends StatefulWidget {
  final String orderId;
  const RestaurantOrderDetailScreen({super.key, required this.orderId});

  @override
  State<RestaurantOrderDetailScreen> createState() => _RestaurantOrderDetailScreenState();
}

class _RestaurantOrderDetailScreenState extends State<RestaurantOrderDetailScreen> {
  Map<String, dynamic>? _order;
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    try {
      final order = await SupabaseService.getOrder(widget.orderId);
      setState(() {
        _order = order;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmOrder() async {
    // Demander le temps de préparation
    final prepTime = await showDialog<int>(
      context: context,
      builder: (context) => _PrepTimeDialog(),
    );
    
    if (prepTime == null) return;
    
    setState(() => _isProcessing = true);
    try {
      await SupabaseService.confirmOrder(widget.orderId, prepTime);
      await _loadOrder();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Commande confirmée'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _startPreparing() async {
    setState(() => _isProcessing = true);
    try {
      await SupabaseService.startPreparing(widget.orderId);
      await _loadOrder();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Préparation démarrée'), backgroundColor: AppColors.info),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _markAsReady() async {
    setState(() => _isProcessing = true);
    try {
      await SupabaseService.markAsReady(widget.orderId);
      await _loadOrder();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Commande prête pour livraison'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _cancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la commande'),
        content: const Text('Êtes-vous sûr de vouloir annuler cette commande ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Oui', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    setState(() => _isProcessing = true);
    try {
      await SupabaseService.cancelOrder(widget.orderId, 'Annulée par le restaurant');
      await _loadOrder();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Commande annulée'), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_order == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('Commande non trouvée')));

    final items = _order!['order_items'] as List? ?? [];
    final status = _order!['status'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: Text('Commande #${_order!['order_number'] ?? ''}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Statut de la commande
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _getStatusColor(status).withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_getStatusIcon(status), color: _getStatusColor(status)),
                const SizedBox(width: 8),
                Text(
                  _getStatusLabel(status),
                  style: AppTypography.titleMedium.copyWith(
                    color: _getStatusColor(status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Articles', style: AppTypography.titleLarge),
                  const SizedBox(height: 12),
                  ...items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${item['quantity']}',
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['name'] ?? '', style: AppTypography.bodyLarge),
                              if (item['notes'] != null && item['notes'].toString().isNotEmpty)
                                Text(
                                  item['notes'],
                                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          '${((item['price'] ?? 0) * (item['quantity'] ?? 1)).toStringAsFixed(0)} DA',
                          style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total', style: AppTypography.titleLarge),
                      Text(
                        '${_order!['total']?.toStringAsFixed(0) ?? 0} DA',
                        style: AppTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Client', style: AppTypography.titleLarge),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: const Icon(Icons.person, color: AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _order!['customer']?['full_name'] ?? 'Client',
                                style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                _order!['customer']?['phone'] ?? '',
                                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Adresse de livraison', style: AppTypography.titleLarge),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: AppColors.error),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _order!['delivery_address'] ?? '',
                            style: AppTypography.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_order!['notes'] != null && _order!['notes'].toString().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text('Notes', style: AppTypography.titleLarge),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _order!['notes'],
                        style: AppTypography.bodyMedium,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Boutons d'action
          if (_canShowActions(status))
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: _isProcessing
                  ? const Center(child: CircularProgressIndicator())
                  : _buildActionButtons(status),
            ),
        ],
      ),
    );
  }

  bool _canShowActions(String? status) {
    return status == 'pending' || status == 'confirmed' || status == 'preparing';
  }

  Widget _buildActionButtons(String? status) {
    switch (status) {
      case 'pending':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _cancelOrder,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Refuser'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _confirmOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Accepter'),
              ),
            ),
          ],
        );
      
      case 'confirmed':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _startPreparing,
            icon: const Icon(Icons.restaurant),
            label: const Text('Commencer la préparation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        );
      
      case 'preparing':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _markAsReady,
            icon: const Icon(Icons.check_circle),
            label: const Text('Marquer comme prête'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        );
      
      default:
        return const SizedBox.shrink();
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending': return AppColors.warning;
      case 'confirmed': return AppColors.info;
      case 'preparing': return Colors.purple;
      case 'ready': return Colors.teal;
      case 'picked_up': return Colors.indigo;
      case 'delivering': return Colors.blue;
      case 'delivered': return AppColors.success;
      case 'cancelled': return AppColors.error;
      default: return AppColors.textSecondary;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'pending': return Icons.schedule;
      case 'confirmed': return Icons.check;
      case 'preparing': return Icons.restaurant;
      case 'ready': return Icons.done_all;
      case 'picked_up': return Icons.delivery_dining;
      case 'delivering': return Icons.local_shipping;
      case 'delivered': return Icons.check_circle;
      case 'cancelled': return Icons.cancel;
      default: return Icons.info;
    }
  }

  String _getStatusLabel(String? status) {
    switch (status) {
      case 'pending': return 'En attente';
      case 'confirmed': return 'Confirmée';
      case 'preparing': return 'En préparation';
      case 'ready': return 'Prête';
      case 'picked_up': return 'Récupérée';
      case 'delivering': return 'En livraison';
      case 'delivered': return 'Livrée';
      case 'cancelled': return 'Annulée';
      default: return status ?? '';
    }
  }
}

class _PrepTimeDialog extends StatefulWidget {
  @override
  State<_PrepTimeDialog> createState() => _PrepTimeDialogState();
}

class _PrepTimeDialogState extends State<_PrepTimeDialog> {
  int _selectedTime = 15;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Temps de préparation'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Combien de temps pour préparer cette commande ?'),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [10, 15, 20, 30, 45, 60].map((time) {
              return ChoiceChip(
                label: Text('$time min'),
                selected: _selectedTime == time,
                onSelected: (selected) {
                  if (selected) setState(() => _selectedTime = time);
                },
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedTime),
          child: const Text('Confirmer'),
        ),
      ],
    );
  }
}
