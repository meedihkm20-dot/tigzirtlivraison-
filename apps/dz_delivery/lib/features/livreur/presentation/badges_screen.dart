import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  List<Map<String, dynamic>> _badges = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final badges = await SupabaseService.getLivreurBadges();
      final stats = await SupabaseService.getLivreurDetailedStats();
      setState(() {
        _badges = badges;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes Performances')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats cards
                    _buildStatsGrid(),
                    const SizedBox(height: 24),
                    
                    // Badges section
                    const Text('Mes Badges', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildBadgesGrid(),
                    
                    const SizedBox(height: 24),
                    
                    // All badges (locked + unlocked)
                    const Text('Tous les badges', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildAllBadges(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          icon: Icons.delivery_dining,
          value: '${_stats['total_deliveries'] ?? 0}',
          label: 'Livraisons',
          color: Colors.blue,
        ),
        _buildStatCard(
          icon: Icons.star,
          value: '${(_stats['rating'] ?? 5.0).toStringAsFixed(1)}',
          label: 'Note moyenne',
          color: Colors.amber,
        ),
        _buildStatCard(
          icon: Icons.timer,
          value: '${_stats['avg_delivery_time'] ?? 0} min',
          label: 'Temps moyen',
          color: Colors.green,
        ),
        _buildStatCard(
          icon: Icons.check_circle,
          value: '${(_stats['acceptance_rate'] ?? 100).toStringAsFixed(0)}%',
          label: 'Taux acceptation',
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildBadgesGrid() {
    if (_badges.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.emoji_events, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text('Pas encore de badges', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text('Continuez à livrer pour en débloquer!', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _badges.map((badge) => _buildBadgeChip(badge['badge_type'], true)).toList(),
    );
  }

  Widget _buildAllBadges() {
    final allBadgeTypes = [
      {'type': 'first_delivery', 'name': 'Première livraison', 'icon': Icons.rocket_launch, 'desc': 'Effectuer votre première livraison'},
      {'type': '50_deliveries', 'name': '50 Livraisons', 'icon': Icons.local_shipping, 'desc': 'Atteindre 50 livraisons'},
      {'type': '100_deliveries', 'name': '100 Livraisons', 'icon': Icons.emoji_events, 'desc': 'Atteindre 100 livraisons'},
      {'type': '5_stars', 'name': '5 Étoiles', 'icon': Icons.star, 'desc': 'Maintenir une note de 4.8+'},
      {'type': 'speed_demon', 'name': 'Rapide', 'icon': Icons.flash_on, 'desc': 'Temps moyen < 20 min'},
    ];

    final earnedTypes = _badges.map((b) => b['badge_type']).toSet();

    return Column(
      children: allBadgeTypes.map((badge) {
        final isEarned = earnedTypes.contains(badge['type']);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isEarned ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: isEarned ? Border.all(color: AppTheme.primaryColor, width: 2) : null,
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isEarned ? AppTheme.primaryColor : Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  badge['icon'] as IconData,
                  color: isEarned ? Colors.white : Colors.grey[500],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      badge['name'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isEarned ? Colors.black : Colors.grey[500],
                      ),
                    ),
                    Text(
                      badge['desc'] as String,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (isEarned)
                const Icon(Icons.check_circle, color: Colors.green)
              else
                Icon(Icons.lock, color: Colors.grey[400]),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBadgeChip(String type, bool earned) {
    final badgeInfo = _getBadgeInfo(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeInfo['icon'] as IconData, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(badgeInfo['name'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Map<String, dynamic> _getBadgeInfo(String type) {
    switch (type) {
      case 'first_delivery': return {'name': 'Première livraison', 'icon': Icons.rocket_launch};
      case '50_deliveries': return {'name': '50 Livraisons', 'icon': Icons.local_shipping};
      case '100_deliveries': return {'name': '100 Livraisons', 'icon': Icons.emoji_events};
      case '5_stars': return {'name': '5 Étoiles', 'icon': Icons.star};
      case 'speed_demon': return {'name': 'Rapide', 'icon': Icons.flash_on};
      default: return {'name': type, 'icon': Icons.emoji_events};
    }
  }
}
