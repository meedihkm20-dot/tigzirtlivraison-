import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await SupabaseService.getDashboardStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        break;
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
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await SupabaseService.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, AppRouter.login);
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vue d\'ensemble',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Restaurants',
                            value: '${_stats['total_restaurants'] ?? 0}',
                            subtitle: '${_stats['pending_restaurants'] ?? 0} en attente',
                            icon: Icons.restaurant,
                            color: AppTheme.accentColor,
                            onTap: () => Navigator.pushNamed(context, AppRouter.restaurants),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'Livreurs',
                            value: '${_stats['total_livreurs'] ?? 0}',
                            subtitle: '${_stats['pending_livreurs'] ?? 0} en attente',
                            icon: Icons.delivery_dining,
                            color: AppTheme.secondaryColor,
                            onTap: () => Navigator.pushNamed(context, AppRouter.livreurs),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Commandes (Aujourd\'hui)',
                            value: '${_stats['today_orders'] ?? 0}',
                            subtitle: _formatCurrency(_stats['today_revenue']),
                            icon: Icons.shopping_bag,
                            color: AppTheme.primaryColor,
                            onTap: () => Navigator.pushNamed(context, AppRouter.orders),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'Ce mois',
                            value: '${_stats['month_orders'] ?? 0}',
                            subtitle: _formatCurrency(_stats['month_revenue']),
                            icon: Icons.calendar_month,
                            color: Colors.purple,
                            onTap: () => Navigator.pushNamed(context, AppRouter.finance),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Actions rapides',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ActionCard(
                      title: 'Restaurants en attente',
                      subtitle: '${_stats['pending_restaurants'] ?? 0} demandes à valider',
                      icon: Icons.pending_actions,
                      color: AppTheme.warningColor,
                      onTap: () => Navigator.pushNamed(context, AppRouter.restaurants),
                    ),
                    const SizedBox(height: 12),
                    _ActionCard(
                      title: 'Livreurs en attente',
                      subtitle: '${_stats['pending_livreurs'] ?? 0} demandes à valider',
                      icon: Icons.person_add,
                      color: AppTheme.warningColor,
                      onTap: () => Navigator.pushNamed(context, AppRouter.livreurs),
                    ),
                    const SizedBox(height: 12),
                    _ActionCard(
                      title: 'Rapport financier',
                      subtitle: 'Voir les transactions et commissions',
                      icon: Icons.account_balance_wallet,
                      color: AppTheme.secondaryColor,
                      onTap: () => Navigator.pushNamed(context, AppRouter.finance),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Restaurants'),
          BottomNavigationBarItem(icon: Icon(Icons.delivery_dining), label: 'Livreurs'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Commandes'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance), label: 'Finance'),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
