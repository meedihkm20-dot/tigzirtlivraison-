import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';

class DashboardScreenV2 extends StatefulWidget {
  const DashboardScreenV2({super.key});

  @override
  State<DashboardScreenV2> createState() => _DashboardScreenV2State();
}

class _DashboardScreenV2State extends State<DashboardScreenV2> {
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  int _selectedIndex = 0;
  RealtimeChannel? _realtimeChannel;
  String? _adminRole;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupRealtime();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final stats = await SupabaseService.getDashboardStats();
      final role = await SupabaseService.getAdminRole();
      setState(() {
        _stats = stats;
        _adminRole = role;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _setupRealtime() {
    _realtimeChannel = SupabaseService.subscribeToDashboard(() {
      _loadData();
    });
  }

  @override
  void dispose() {
    if (_realtimeChannel != null) {
      SupabaseService.unsubscribe(_realtimeChannel!);
    }
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    switch (index) {
      case 1:
        Navigator.pushNamed(context, AppRouter.restaurants);
        break;
      case 2:
        Navigator.pushNamed(context, AppRouter.livreurs);
        break;
      case 3:
        Navigator.pushNamed(context, AppRouter.orders);
        break;
      case 4:
        Navigator.pushNamed(context, AppRouter.finance);
        break;
    }
  }

  String _formatCurrency(dynamic value) {
    final amount = (value ?? 0).toDouble();
    return NumberFormat.currency(locale: 'fr_DZ', symbol: 'DA', decimalDigits: 0).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('LIVE', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Text('Admin Dashboard', style: TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) async {
              if (value == 'logout') {
                await SupabaseService.signOut();
                if (mounted) Navigator.pushReplacementNamed(context, AppRouter.login);
              } else if (value == 'settings') {
                Navigator.pushNamed(context, AppRouter.settings);
              } else if (value == 'audit') {
                Navigator.pushNamed(context, AppRouter.auditLogs);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'settings', child: Row(children: [Icon(Icons.settings, size: 20), SizedBox(width: 8), Text('Paramètres')])),
              const PopupMenuItem(value: 'audit', child: Row(children: [Icon(Icons.history, size: 20), SizedBox(width: 8), Text('Audit Logs')])),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'logout', child: Row(children: [Icon(Icons.logout, size: 20, color: Colors.red), SizedBox(width: 8), Text('Déconnexion', style: TextStyle(color: Colors.red))])),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Rôle admin
                    if (_adminRole != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getRoleColor(_adminRole!).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getRoleLabel(_adminRole!),
                          style: TextStyle(color: _getRoleColor(_adminRole!), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Commandes en temps réel
                    const Text('Commandes en cours', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _LiveStatCard(
                          label: 'En attente',
                          value: '${_stats['pending_orders'] ?? 0}',
                          color: Colors.orange,
                          icon: Icons.hourglass_empty,
                        ),
                        const SizedBox(width: 8),
                        _LiveStatCard(
                          label: 'Préparation',
                          value: '${_stats['preparing_orders'] ?? 0}',
                          color: Colors.blue,
                          icon: Icons.restaurant,
                        ),
                        const SizedBox(width: 8),
                        _LiveStatCard(
                          label: 'Livraison',
                          value: '${_stats['delivering_orders'] ?? 0}',
                          color: Colors.green,
                          icon: Icons.delivery_dining,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Stats aujourd'hui
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green.shade700, Colors.green.shade900],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Aujourd'hui", style: TextStyle(color: Colors.white70, fontSize: 14)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_stats['today_delivered'] ?? 0} livrées',
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatCurrency(_stats['today_revenue']),
                            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Commission: ${_formatCurrency(_stats['today_commission'])}',
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Restaurants & Livreurs
                    Row(
                      children: [
                        Expanded(
                          child: _StatusCard(
                            title: 'Restaurants',
                            online: _stats['online_restaurants'] ?? 0,
                            total: _stats['total_restaurants'] ?? 0,
                            pending: _stats['pending_restaurants'] ?? 0,
                            icon: Icons.restaurant,
                            color: Colors.orange,
                            onTap: () => Navigator.pushNamed(context, AppRouter.restaurants),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatusCard(
                            title: 'Livreurs',
                            online: _stats['online_livreurs'] ?? 0,
                            total: _stats['total_livreurs'] ?? 0,
                            pending: _stats['pending_livreurs'] ?? 0,
                            available: _stats['available_livreurs'] ?? 0,
                            icon: Icons.delivery_dining,
                            color: Colors.blue,
                            onTap: () => Navigator.pushNamed(context, AppRouter.livreurs),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Alertes
                    if ((_stats['pending_restaurants'] ?? 0) > 0 || (_stats['pending_livreurs'] ?? 0) > 0 || (_stats['critical_incidents'] ?? 0) > 0)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('⚠️ Alertes', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          if ((_stats['critical_incidents'] ?? 0) > 0)
                            _AlertCard(
                              title: 'Incidents critiques',
                              subtitle: '${_stats['critical_incidents']} incidents à traiter',
                              icon: Icons.error,
                              color: Colors.red,
                              onTap: () => Navigator.pushNamed(context, AppRouter.incidents),
                            ),
                          if ((_stats['pending_restaurants'] ?? 0) > 0)
                            _AlertCard(
                              title: 'Restaurants en attente',
                              subtitle: '${_stats['pending_restaurants']} demandes à valider',
                              icon: Icons.restaurant,
                              color: Colors.orange,
                              onTap: () => Navigator.pushNamed(context, AppRouter.restaurants),
                            ),
                          if ((_stats['pending_livreurs'] ?? 0) > 0)
                            _AlertCard(
                              title: 'Livreurs en attente',
                              subtitle: '${_stats['pending_livreurs']} demandes à valider',
                              icon: Icons.delivery_dining,
                              color: Colors.orange,
                              onTap: () => Navigator.pushNamed(context, AppRouter.livreurs),
                            ),
                        ],
                      ),
                    const SizedBox(height: 24),

                    // Actions rapides
                    const Text('Actions rapides', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _QuickAction(icon: Icons.search, label: 'Rechercher', onTap: () => Navigator.pushNamed(context, AppRouter.orders)),
                        _QuickAction(icon: Icons.report_problem, label: 'Incidents', onTap: () => Navigator.pushNamed(context, AppRouter.incidents)),
                        _QuickAction(icon: Icons.account_balance_wallet, label: 'Finance', onTap: () => Navigator.pushNamed(context, AppRouter.finance)),
                        _QuickAction(icon: Icons.trending_up, label: 'Pricing', onTap: () => Navigator.pushNamed(context, AppRouter.pricing)),
                        _QuickAction(icon: Icons.settings, label: 'Paramètres', onTap: () => Navigator.pushNamed(context, AppRouter.settings)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1B2838),
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Restaurants'),
          BottomNavigationBarItem(icon: Icon(Icons.delivery_dining), label: 'Livreurs'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Commandes'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance), label: 'Finance'),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'super_admin': return Colors.red;
      case 'ops_admin': return Colors.blue;
      case 'support_admin': return Colors.green;
      case 'finance_admin': return Colors.purple;
      default: return Colors.grey;
    }
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'super_admin': return '👑 Super Admin';
      case 'ops_admin': return '⚙️ Ops Admin';
      case 'support_admin': return '💬 Support Admin';
      case 'finance_admin': return '💰 Finance Admin';
      default: return '👁️ Lecture seule';
    }
  }
}

class _LiveStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _LiveStatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
            Text(label, style: TextStyle(color: color.withOpacity(0.8), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String title;
  final int online;
  final int total;
  final int pending;
  final int? available;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StatusCard({
    required this.title,
    required this.online,
    required this.total,
    required this.pending,
    this.available,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1B2838),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text('$online', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                Text(' / $total', style: const TextStyle(color: Colors.white54, fontSize: 14)),
              ],
            ),
            if (available != null)
              Text('$available disponibles', style: const TextStyle(color: Colors.green, fontSize: 12)),
            if (pending > 0)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('$pending en attente', style: const TextStyle(color: Colors.orange, fontSize: 11)),
              ),
          ],
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AlertCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: TextStyle(color: color.withOpacity(0.8), fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1B2838),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 18),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
