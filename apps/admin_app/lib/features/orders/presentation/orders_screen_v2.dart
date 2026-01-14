import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';

class OrdersScreenV2 extends StatefulWidget {
  const OrdersScreenV2({super.key});

  @override
  State<OrdersScreenV2> createState() => _OrdersScreenV2State();
}

class _OrdersScreenV2State extends State<OrdersScreenV2> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String _selectedStatus = '';
  final _searchController = TextEditingController();

  final List<Map<String, dynamic>> _statusFilters = [
    {'value': '', 'label': 'Toutes', 'color': Colors.grey},
    {'value': 'pending', 'label': 'En attente', 'color': Colors.orange},
    {'value': 'confirmed', 'label': 'Confirmées', 'color': Colors.blue},
    {'value': 'preparing', 'label': 'Préparation', 'color': Colors.purple},
    {'value': 'ready', 'label': 'Prêtes', 'color': Colors.teal},
    {'value': 'picked_up', 'label': 'Récupérées', 'color': Colors.indigo},
    {'value': 'delivered', 'label': 'Livrées', 'color': Colors.green},
    {'value': 'cancelled', 'label': 'Annulées', 'color': Colors.red},
  ];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final orders = await SupabaseService.getAllOrders(
        status: _selectedStatus.isEmpty ? null : _selectedStatus,
        search: _searchController.text.isEmpty ? null : _searchController.text,
      );
      setState(() {
        _orders = orders;
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

  void _showOrderDetails(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _OrderDetailsSheet(order: order, onRefresh: _loadOrders),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        title: const Text('Gestion Commandes', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Rechercher (N° commande, client, téléphone...)',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54),
                        onPressed: () {
                          _searchController.clear();
                          _loadOrders();
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF1B2838),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _loadOrders(),
            ),
          ),

          // Filtres par statut
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _statusFilters.length,
              itemBuilder: (context, index) {
                final filter = _statusFilters[index];
                final isSelected = _selectedStatus == filter['value'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter['label']),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedStatus = selected ? filter['value'] : '');
                      _loadOrders();
                    },
                    backgroundColor: const Color(0xFF1B2838),
                    selectedColor: (filter['color'] as Color).withOpacity(0.3),
                    labelStyle: TextStyle(
                      color: isSelected ? filter['color'] : Colors.white70,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color: isSelected ? filter['color'] : Colors.transparent,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Compteur
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${_orders.length} commande${_orders.length > 1 ? 's' : ''}',
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white54, size: 20),
                  onPressed: _loadOrders,
                ),
              ],
            ),
          ),

          // Liste des commandes
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : _orders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox, size: 64, color: Colors.white24),
                            const SizedBox(height: 16),
                            Text('Aucune commande', style: TextStyle(color: Colors.white54)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadOrders,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _orders.length,
                          itemBuilder: (context, index) => _OrderCard(
                            order: _orders[index],
                            onTap: () => _showOrderDetails(_orders[index]),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = order['status'] as String?;
    final statusInfo = _getStatusInfo(status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1B2838),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#${order['order_number'] ?? ''}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusInfo['color'].withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusInfo['text'],
                    style: TextStyle(color: statusInfo['color'], fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.restaurant, size: 16, color: Colors.orange),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order['restaurant']?['name'] ?? 'Restaurant',
                    style: const TextStyle(color: Colors.white70),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.blue),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${order['customer']?['full_name'] ?? 'Client'} • ${order['customer']?['phone'] ?? ''}',
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (order['livreur'] != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.delivery_dining, size: 16, color: Colors.green),
                  const SizedBox(width: 6),
                  Text(
                    order['livreur']?['user']?['full_name'] ?? 'Livreur',
                    style: const TextStyle(color: Colors.green, fontSize: 13),
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
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  _formatDate(order['created_at']),
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(String? status) {
    switch (status) {
      case 'pending': return {'text': 'En attente', 'color': Colors.orange};
      case 'confirmed': return {'text': 'Confirmée', 'color': Colors.blue};
      case 'preparing': return {'text': 'Préparation', 'color': Colors.purple};
      case 'ready': return {'text': 'Prête', 'color': Colors.teal};
      case 'picked_up': return {'text': 'Récupérée', 'color': Colors.indigo};
      case 'delivering': return {'text': 'En livraison', 'color': Colors.blue};
      case 'delivered': return {'text': 'Livrée', 'color': Colors.green};
      case 'cancelled': return {'text': 'Annulée', 'color': Colors.red};
      default: return {'text': status ?? '', 'color': Colors.grey};
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.parse(dateStr);
    return DateFormat('dd/MM HH:mm').format(date);
  }
}

class _OrderDetailsSheet extends StatefulWidget {
  final Map<String, dynamic> order;
  final VoidCallback onRefresh;

  const _OrderDetailsSheet({required this.order, required this.onRefresh});

  @override
  State<_OrderDetailsSheet> createState() => _OrderDetailsSheetState();
}

class _OrderDetailsSheetState extends State<_OrderDetailsSheet> {
  bool _isLoading = false;

  Future<void> _forceStatus(String newStatus) async {
    final reason = await _showReasonDialog('Changer le statut en "$newStatus"');
    if (reason == null) return;

    setState(() => _isLoading = true);
    try {
      await SupabaseService.forceOrderStatus(widget.order['id'], newStatus, reason);
      widget.onRefresh();
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Statut modifié'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> _cancelOrder() async {
    final reason = await _showReasonDialog('Annuler cette commande');
    if (reason == null) return;

    setState(() => _isLoading = true);
    try {
      await SupabaseService.adminCancelOrder(widget.order['id'], reason);
      widget.onRefresh();
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Commande annulée'), backgroundColor: Colors.orange),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
    setState(() => _isLoading = false);
  }

  Future<String?> _showReasonDialog(String action) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B2838),
        title: Text(action, style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Raison (obligatoire)',
            hintStyle: TextStyle(color: Colors.white38),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Raison obligatoire')),
                );
                return;
              }
              Navigator.pop(ctx, controller.text.trim());
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final status = order['status'] as String?;
    final canCancel = !['delivered', 'cancelled'].contains(status);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF0D1B2A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Commande #${order['order_number']}',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12),
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Infos principales
                        _InfoSection(
                          title: 'Client',
                          icon: Icons.person,
                          color: Colors.blue,
                          children: [
                            _InfoRow('Nom', order['customer']?['full_name'] ?? 'N/A'),
                            _InfoRow('Téléphone', order['customer']?['phone'] ?? 'N/A'),
                            _InfoRow('Adresse', order['delivery_address'] ?? 'N/A'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _InfoSection(
                          title: 'Restaurant',
                          icon: Icons.restaurant,
                          color: Colors.orange,
                          children: [
                            _InfoRow('Nom', order['restaurant']?['name'] ?? 'N/A'),
                            _InfoRow('Téléphone', order['restaurant']?['phone'] ?? 'N/A'),
                          ],
                        ),
                        if (order['livreur'] != null) ...[
                          const SizedBox(height: 16),
                          _InfoSection(
                            title: 'Livreur',
                            icon: Icons.delivery_dining,
                            color: Colors.green,
                            children: [
                              _InfoRow('Nom', order['livreur']?['user']?['full_name'] ?? 'N/A'),
                              _InfoRow('Téléphone', order['livreur']?['user']?['phone'] ?? 'N/A'),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        _InfoSection(
                          title: 'Montants',
                          icon: Icons.attach_money,
                          color: Colors.green,
                          children: [
                            _InfoRow('Sous-total', '${order['subtotal']?.toStringAsFixed(0) ?? 0} DA'),
                            _InfoRow('Livraison', '${order['delivery_fee']?.toStringAsFixed(0) ?? 0} DA'),
                            _InfoRow('Total', '${order['total']?.toStringAsFixed(0) ?? 0} DA', bold: true),
                            if (order['admin_commission'] != null)
                              _InfoRow('Commission', '${order['admin_commission']?.toStringAsFixed(0) ?? 0} DA'),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Actions admin
                        const Text('Actions Admin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (status == 'pending')
                              _ActionButton(
                                label: 'Forcer Confirmée',
                                icon: Icons.check,
                                color: Colors.blue,
                                onTap: () => _forceStatus('confirmed'),
                              ),
                            if (status == 'ready')
                              _ActionButton(
                                label: 'Forcer Récupérée',
                                icon: Icons.local_shipping,
                                color: Colors.indigo,
                                onTap: () => _forceStatus('picked_up'),
                              ),
                            if (['picked_up', 'delivering'].contains(status))
                              _ActionButton(
                                label: 'Forcer Livrée',
                                icon: Icons.done_all,
                                color: Colors.green,
                                onTap: () => _forceStatus('delivered'),
                              ),
                            if (canCancel)
                              _ActionButton(
                                label: 'Annuler',
                                icon: Icons.cancel,
                                color: Colors.red,
                                onTap: _cancelOrder,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const _InfoSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _InfoRow(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.2),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
