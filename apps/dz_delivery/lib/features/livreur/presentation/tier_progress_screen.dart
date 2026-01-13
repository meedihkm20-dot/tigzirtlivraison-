import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';

class TierProgressScreen extends StatefulWidget {
  const TierProgressScreen({super.key});

  @override
  State<TierProgressScreen> createState() => _TierProgressScreenState();
}

class _TierProgressScreenState extends State<TierProgressScreen> {
  Map<String, dynamic>? _tierInfo;
  Map<String, dynamic>? _nextTierReq;
  List<Map<String, dynamic>> _bonusHistory = [];
  List<Map<String, dynamic>> _targets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Charger avec gestion d'erreur individuelle
      Map<String, dynamic>? tierInfo;
      Map<String, dynamic>? nextTierReq;
      List<Map<String, dynamic>> bonusHistory = [];
      List<Map<String, dynamic>> targets = [];
      
      try {
        tierInfo = await SupabaseService.getLivreurTierInfo();
      } catch (e) {
        debugPrint('Erreur tier info: $e');
      }
      
      try {
        nextTierReq = await SupabaseService.getNextTierRequirements();
      } catch (e) {
        debugPrint('Erreur next tier: $e');
      }
      
      try {
        bonusHistory = await SupabaseService.getLivreurBonusHistory(limit: 20);
      } catch (e) {
        debugPrint('Erreur bonus history: $e');
      }
      
      try {
        targets = await SupabaseService.getDailyTargets();
      } catch (e) {
        debugPrint('Erreur targets: $e');
      }
      
      if (mounted) {
        setState(() {
          _tierInfo = tierInfo;
          _nextTierReq = nextTierReq;
          _bonusHistory = bonusHistory;
          _targets = targets;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('Erreur générale: $e');
    }
  }

  Color _getTierColor(String tier) {
    switch (tier) {
      case 'diamond': return Colors.cyan;
      case 'gold': return Colors.amber;
      case 'silver': return Colors.grey;
      default: return Colors.brown;
    }
  }

  String _getTierEmoji(String tier) {
    switch (tier) {
      case 'diamond': return '💎';
      case 'gold': return '🥇';
      case 'silver': return '🥈';
      default: return '🥉';
    }
  }

  String _getTierName(String tier) {
    switch (tier) {
      case 'diamond': return 'DIAMANT';
      case 'gold': return 'OR';
      case 'silver': return 'ARGENT';
      default: return 'BRONZE';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentTier = _tierInfo?['current_tier'] ?? 'bronze';
    final commissionRate = (_tierInfo?['commission_rate'] as num?)?.toDouble() ?? 10.0;
    final totalDeliveries = _tierInfo?['total_deliveries'] ?? 0;
    final rating = (_tierInfo?['rating'] as num?)?.toDouble() ?? 5.0;
    final streakDays = _tierInfo?['streak_days'] ?? 0;
    final bonusEarned = (_tierInfo?['bonus_earned'] as num?)?.toDouble() ?? 0;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header avec tier actuel
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: _getTierColor(currentTier),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _getTierColor(currentTier),
                      _getTierColor(currentTier).withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Text(
                        _getTierEmoji(currentTier),
                        style: const TextStyle(fontSize: 60),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Niveau ${_getTierName(currentTier)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Commission: ${commissionRate.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildMiniStat('🚚', '$totalDeliveries', 'Livraisons'),
                          const SizedBox(width: 24),
                          _buildMiniStat('⭐', rating.toStringAsFixed(1), 'Note'),
                          const SizedBox(width: 24),
                          _buildMiniStat('🔥', '$streakDays', 'Jours'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Progression vers prochain niveau
          if (_nextTierReq != null)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${_getTierEmoji(_nextTierReq!['tier'])} Prochain niveau: ${_getTierName(_nextTierReq!['tier'])}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const Spacer(),
                        Text(
                          '${_nextTierReq!['commission_rate']}%',
                          style: TextStyle(
                            color: _getTierColor(_nextTierReq!['tier']),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildProgressItem(
                      'Livraisons',
                      _nextTierReq!['current_deliveries'],
                      _nextTierReq!['min_deliveries'],
                      Icons.delivery_dining,
                    ),
                    const SizedBox(height: 12),
                    _buildProgressItem(
                      'Note minimum',
                      (_nextTierReq!['current_rating'] * 10).round(),
                      (_nextTierReq!['min_rating'] * 10).round(),
                      Icons.star,
                      suffix: '/5',
                      displayValue: '${(_nextTierReq!['current_rating'] as num).toStringAsFixed(1)}',
                      displayTarget: '${_nextTierReq!['min_rating']}',
                    ),
                    const SizedBox(height: 12),
                    _buildProgressItem(
                      'Taux annulation max',
                      (100 - (_nextTierReq!['current_cancellation_rate'] as num)).round(),
                      (100 - (_nextTierReq!['max_cancellation_rate'] as num)).round(),
                      Icons.cancel,
                      suffix: '%',
                      displayValue: '${(_nextTierReq!['current_cancellation_rate'] as num).toStringAsFixed(0)}%',
                      displayTarget: '<${_nextTierReq!['max_cancellation_rate']}%',
                      inverted: true,
                    ),
                  ],
                ),
              ),
            ),

          // Objectifs journaliers
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🎯 Objectifs & Bonus',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  ..._targets.map((target) => _buildTargetCard(target)),
                ],
              ),
            ),
          ),

          // Bonus total
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green, Colors.green.shade700],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet, color: Colors.white, size: 40),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total bonus gagnés',
                        style: TextStyle(color: Colors.white70),
                      ),
                      Text(
                        '${bonusEarned.toStringAsFixed(0)} DA',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Historique des bonus
          if (_bonusHistory.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '📜 Historique des bonus',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildBonusHistoryItem(_bonusHistory[index]),
                childCount: _bonusHistory.length,
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildProgressItem(
    String label,
    int current,
    int target,
    IconData icon, {
    String suffix = '',
    String? displayValue,
    String? displayTarget,
    bool inverted = false,
  }) {
    final progress = (current / target).clamp(0.0, 1.0);
    final isComplete = inverted ? current <= target : current >= target;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: Colors.grey[600])),
            const Spacer(),
            Text(
              '${displayValue ?? current}$suffix / ${displayTarget ?? target}$suffix',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isComplete ? Colors.green : Colors.grey[800],
              ),
            ),
            if (isComplete) ...[
              const SizedBox(width: 4),
              const Icon(Icons.check_circle, color: Colors.green, size: 16),
            ],
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation(isComplete ? Colors.green : AppTheme.primaryColor),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildTargetCard(Map<String, dynamic> target) {
    final type = target['target_type'] as String;
    final required = target['deliveries_required'] as int;
    final bonus = (target['bonus_amount'] as num).toDouble();
    
    String typeLabel;
    IconData icon;
    Color color;
    
    switch (type) {
      case 'daily':
        typeLabel = 'Journalier';
        icon = Icons.today;
        color = Colors.blue;
        break;
      case 'weekly':
        typeLabel = 'Hebdomadaire';
        icon = Icons.date_range;
        color = Colors.purple;
        break;
      default:
        typeLabel = 'Mensuel';
        icon = Icons.calendar_month;
        color = Colors.orange;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(typeLabel, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                Text('$required livraisons', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '+${bonus.toStringAsFixed(0)} DA',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBonusHistoryItem(Map<String, dynamic> bonus) {
    final amount = (bonus['amount'] as num).toDouble();
    final type = bonus['bonus_type'] as String;
    final description = bonus['description'] as String?;
    final earnedAt = DateTime.tryParse(bonus['earned_at'] ?? '');
    
    IconData icon;
    Color color;
    
    switch (type) {
      case 'daily_target':
        icon = Icons.flag;
        color = Colors.blue;
        break;
      case 'weekly_target':
        icon = Icons.emoji_events;
        color = Colors.purple;
        break;
      case 'streak':
        icon = Icons.local_fire_department;
        color = Colors.orange;
        break;
      case 'five_star':
        icon = Icons.star;
        color = Colors.amber;
        break;
      default:
        icon = Icons.card_giftcard;
        color = Colors.green;
    }
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.1),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(description ?? type, style: const TextStyle(fontSize: 14)),
      subtitle: earnedAt != null
          ? Text('${earnedAt.day}/${earnedAt.month}/${earnedAt.year}', style: TextStyle(color: Colors.grey[500], fontSize: 12))
          : null,
      trailing: Text(
        '+${amount.toStringAsFixed(0)} DA',
        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
      ),
    );
  }
}
