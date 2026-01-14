import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/design_system/theme/app_colors.dart';
import '../../../../core/design_system/theme/app_typography.dart';
import '../../../../core/design_system/theme/app_spacing.dart';
import '../../../../core/design_system/theme/app_shadows.dart';
import '../../../../core/services/supabase_service.dart';

/// Écran Progression Niveau Livreur V2 - Premium
/// Gamification complète: tiers, badges, défis, classement
class TierProgressScreenV2 extends StatefulWidget {
  const TierProgressScreenV2({super.key});

  @override
  State<TierProgressScreenV2> createState() => _TierProgressScreenV2State();
}

class _TierProgressScreenV2State extends State<TierProgressScreenV2>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  
  Map<String, dynamic>? _tierInfo;
  List<Map<String, dynamic>> _badges = [];
  List<Map<String, dynamic>> _challenges = [];
  List<Map<String, dynamic>> _leaderboard = [];
  
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  final _tiers = [
    {'name': 'Bronze', 'color': AppColors.tierBronze, 'gradient': AppColors.bronzeGradient, 'minDeliveries': 0, 'bonus': '0%'},
    {'name': 'Silver', 'color': AppColors.tierSilver, 'gradient': AppColors.silverGradient, 'minDeliveries': 50, 'bonus': '+5%'},
    {'name': 'Gold', 'color': AppColors.tierGold, 'gradient': AppColors.goldGradient, 'minDeliveries': 150, 'bonus': '+10%'},
    {'name': 'Diamond', 'color': AppColors.tierDiamond, 'gradient': AppColors.diamondGradient, 'minDeliveries': 500, 'bonus': '+20%'},
  ];

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );
    _loadData();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }


  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _safeCall(() => SupabaseService.getLivreurTierInfo(), <String, dynamic>{}),
        _safeCall(() => SupabaseService.getLivreurBadges(), <Map<String, dynamic>>[]),
        _safeCall(() => SupabaseService.getLivreurChallenges(), <Map<String, dynamic>>[]),
        _safeCall(() => SupabaseService.getLivreurLeaderboard(), <Map<String, dynamic>>[]),
      ]);

      if (mounted) {
        setState(() {
          _tierInfo = results[0] as Map<String, dynamic>;
          _badges = results[1] as List<Map<String, dynamic>>;
          _challenges = results[2] as List<Map<String, dynamic>>;
          _leaderboard = results[3] as List<Map<String, dynamic>>;
          
          // Default data if empty
          if (_tierInfo!.isEmpty) {
            _tierInfo = {'tier': 'Bronze', 'deliveries': 25, 'points': 250};
          }
          if (_badges.isEmpty) {
            _badges = [
              {'id': '1', 'name': 'Première livraison', 'icon': '🎉', 'unlocked': true},
              {'id': '2', 'name': 'Rapide', 'icon': '⚡', 'unlocked': true},
              {'id': '3', 'name': '5 étoiles', 'icon': '⭐', 'unlocked': false},
              {'id': '4', 'name': 'Marathon', 'icon': '🏃', 'unlocked': false},
            ];
          }
          if (_challenges.isEmpty) {
            _challenges = [
              {'id': '1', 'name': '5 livraisons aujourd\'hui', 'progress': 3, 'target': 5, 'reward': 100},
              {'id': '2', 'name': '20 livraisons cette semaine', 'progress': 12, 'target': 20, 'reward': 500},
              {'id': '3', 'name': 'Note moyenne 4.8+', 'progress': 4.6, 'target': 4.8, 'reward': 200},
            ];
          }
          if (_leaderboard.isEmpty) {
            _leaderboard = [
              {'rank': 1, 'name': 'Ahmed K.', 'deliveries': 156, 'tier': 'Gold'},
              {'rank': 2, 'name': 'Karim M.', 'deliveries': 142, 'tier': 'Gold'},
              {'rank': 3, 'name': 'Yacine B.', 'deliveries': 128, 'tier': 'Silver'},
              {'rank': 4, 'name': 'Vous', 'deliveries': 25, 'tier': 'Bronze', 'isMe': true},
            ];
          }
          
          _isLoading = false;
        });
        _progressController.forward();
      }
    } catch (e) {
      debugPrint('Erreur: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<T> _safeCall<T>(Future<T> Function() call, T defaultValue) async {
    try {
      return await call();
    } catch (e) {
      return defaultValue;
    }
  }

  int get _currentTierIndex {
    final tier = _tierInfo?['tier'] ?? 'Bronze';
    return _tiers.indexWhere((t) => t['name'] == tier);
  }

  Map<String, dynamic> get _currentTier => _tiers[_currentTierIndex];
  Map<String, dynamic>? get _nextTier => _currentTierIndex < _tiers.length - 1 ? _tiers[_currentTierIndex + 1] : null;

  double get _tierProgress {
    if (_nextTier == null) return 1.0;
    final current = _tierInfo?['deliveries'] ?? 0;
    final min = _currentTier['minDeliveries'] as int;
    final max = _nextTier!['minDeliveries'] as int;
    return ((current - min) / (max - min)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.livreurPrimary))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.livreurPrimary,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  _buildHeader(),
                  SliverToBoxAdapter(child: _buildTierProgress()),
                  SliverToBoxAdapter(child: _buildTierBenefits()),
                  SliverToBoxAdapter(child: _buildChallenges()),
                  SliverToBoxAdapter(child: _buildBadges()),
                  SliverToBoxAdapter(child: _buildLeaderboard()),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    final deliveries = _tierInfo?['deliveries'] ?? 0;
    final points = _tierInfo?['points'] ?? 0;

    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: _currentTier['color'] as Color,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(gradient: _currentTier['gradient'] as LinearGradient),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                // Tier badge
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.workspace_premium,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _currentTier['name'] as String,
                  style: AppTypography.headlineMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildHeaderStat('🚚', '$deliveries', 'livraisons'),
                    const SizedBox(width: 24),
                    _buildHeaderStat('⭐', '$points', 'points'),
                    const SizedBox(width: 24),
                    _buildHeaderStat('💰', _currentTier['bonus'] as String, 'bonus'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderStat(String emoji, String value, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
            Text(value, style: AppTypography.titleSmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        Text(label, style: AppTypography.labelSmall.copyWith(color: Colors.white70)),
      ],
    );
  }

  Widget _buildTierProgress() {
    final deliveries = _tierInfo?['deliveries'] ?? 0;
    final nextMin = _nextTier?['minDeliveries'] ?? deliveries;
    final remaining = nextMin - deliveries;

    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Progression', style: AppTypography.titleSmall),
              if (_nextTier != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: _nextTier!['gradient'] as LinearGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Prochain: ${_nextTier!['name']}',
                    style: AppTypography.labelSmall.copyWith(color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          Stack(
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) => FractionallySizedBox(
                  widthFactor: _tierProgress * _progressAnimation.value,
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      gradient: _currentTier['gradient'] as LinearGradient,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_nextTier != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$deliveries livraisons',
                  style: AppTypography.labelMedium,
                ),
                Text(
                  '$remaining restantes',
                  style: AppTypography.labelMedium.copyWith(color: AppColors.textTertiary),
                ),
              ],
            )
          else
            Center(
              child: Text(
                '🎉 Niveau maximum atteint!',
                style: AppTypography.labelMedium.copyWith(color: AppColors.success),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTierBenefits() {
    return Container(
      margin: AppSpacing.screenHorizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Avantages par niveau', style: AppTypography.titleSmall),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _tiers.length,
              itemBuilder: (context, index) => _buildTierCard(_tiers[index], index <= _currentTierIndex),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierCard(Map<String, dynamic> tier, bool isUnlocked) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isUnlocked ? tier['gradient'] as LinearGradient : null,
        color: isUnlocked ? null : AppColors.surfaceVariant,
        borderRadius: AppSpacing.borderRadiusMd,
        boxShadow: isUnlocked ? AppShadows.sm : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.workspace_premium,
                color: isUnlocked ? Colors.white : AppColors.textTertiary,
                size: 24,
              ),
              const Spacer(),
              if (isUnlocked)
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
            ],
          ),
          const Spacer(),
          Text(
            tier['name'] as String,
            style: AppTypography.titleSmall.copyWith(
              color: isUnlocked ? Colors.white : AppColors.textTertiary,
            ),
          ),
          Text(
            tier['bonus'] as String,
            style: AppTypography.labelSmall.copyWith(
              color: isUnlocked ? Colors.white70 : AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallenges() {
    return Padding(
      padding: AppSpacing.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Défis actifs', style: AppTypography.titleSmall),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warningSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_challenges.length} en cours',
                  style: AppTypography.labelSmall.copyWith(color: AppColors.warning),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._challenges.map((c) => _buildChallengeCard(c)),
        ],
      ),
    );
  }

  Widget _buildChallengeCard(Map<String, dynamic> challenge) {
    final progress = (challenge['progress'] as num).toDouble();
    final target = (challenge['target'] as num).toDouble();
    final percentage = (progress / target).clamp(0.0, 1.0);
    final reward = challenge['reward'] ?? 0;

    return Container(
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
              Expanded(
                child: Text(challenge['name'] ?? '', style: AppTypography.labelMedium),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.successSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+$reward DA',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: AppColors.livreurGradient,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${progress.toStringAsFixed(progress.truncateToDouble() == progress ? 0 : 1)} / ${target.toStringAsFixed(target.truncateToDouble() == target ? 0 : 1)}',
            style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildBadges() {
    return Padding(
      padding: AppSpacing.screenHorizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Badges', style: AppTypography.titleSmall),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _badges.length,
              itemBuilder: (context, index) => _buildBadgeItem(_badges[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeItem(Map<String, dynamic> badge) {
    final unlocked = badge['unlocked'] == true;
    
    return GestureDetector(
      onTap: () => _showBadgeDetails(badge),
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: unlocked ? AppColors.livreurSurface : AppColors.surfaceVariant,
                shape: BoxShape.circle,
                border: unlocked ? Border.all(color: AppColors.livreurPrimary, width: 2) : null,
              ),
              child: Center(
                child: Opacity(
                  opacity: unlocked ? 1 : 0.3,
                  child: Text(badge['icon'] ?? '🏆', style: const TextStyle(fontSize: 28)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              badge['name'] ?? '',
              style: AppTypography.labelSmall.copyWith(
                color: unlocked ? AppColors.textPrimary : AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboard() {
    return Padding(
      padding: AppSpacing.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Classement', style: AppTypography.titleSmall),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppSpacing.borderRadiusMd,
              boxShadow: AppShadows.sm,
            ),
            child: Column(
              children: _leaderboard.map((l) => _buildLeaderboardItem(l)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem(Map<String, dynamic> item) {
    final rank = item['rank'] ?? 0;
    final isMe = item['isMe'] == true;
    
    Color? rankColor;
    if (rank == 1) rankColor = AppColors.tierGold;
    else if (rank == 2) rankColor = AppColors.tierSilver;
    else if (rank == 3) rankColor = AppColors.tierBronze;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe ? AppColors.livreurSurface : null,
        border: Border(
          bottom: BorderSide(color: AppColors.outline.withOpacity(0.5)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rankColor ?? AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: rank <= 3
                  ? Icon(Icons.emoji_events, color: Colors.white, size: 18)
                  : Text(
                      '$rank',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] ?? '',
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                Text(
                  '${item['deliveries']} livraisons',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getTierColor(item['tier']).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              item['tier'] ?? '',
              style: AppTypography.labelSmall.copyWith(
                color: _getTierColor(item['tier']),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTierColor(String? tier) {
    switch (tier?.toLowerCase()) {
      case 'diamond': return AppColors.tierDiamond;
      case 'gold': return AppColors.tierGold;
      case 'silver': return AppColors.tierSilver;
      default: return AppColors.tierBronze;
    }
  }

  void _showBadgeDetails(Map<String, dynamic> badge) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(badge['icon'] ?? '🏆', style: const TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            Text(badge['name'] ?? '', style: AppTypography.titleMedium),
            const SizedBox(height: 8),
            Text(
              badge['unlocked'] == true ? 'Badge débloqué! 🎉' : 'Continuez pour débloquer',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
        ],
      ),
    );
  }
}
