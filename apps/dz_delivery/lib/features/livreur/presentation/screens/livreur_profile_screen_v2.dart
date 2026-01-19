import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/design_system/theme/app_colors.dart';
import '../../../../core/design_system/theme/app_typography.dart';
import '../../../../core/design_system/theme/app_spacing.dart';
import '../../../../core/design_system/theme/app_shadows.dart';
import '../../../../core/design_system/components/loaders/skeleton_loader.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/onesignal_service.dart';
import '../../../../core/services/preferences_service.dart';
import '../../../../core/router/app_router.dart';
import '../../../../main.dart';
// Shared components
import '../../../shared/presentation/widgets/profile_header.dart';
import '../../../shared/mixins/logout_mixin.dart';

/// Écran Profil Livreur V2 - Moderne et complet
class LivreurProfileScreenV2 extends StatefulWidget {
  const LivreurProfileScreenV2({super.key});

  @override
  State<LivreurProfileScreenV2> createState() => _LivreurProfileScreenV2State();
}

class _LivreurProfileScreenV2State extends State<LivreurProfileScreenV2>
    with SingleTickerProviderStateMixin, LogoutMixin {
  bool _isLoading = true;
  
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _recentDeliveries = [];
  
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

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
        _safeCall(() => SupabaseService.getProfile(), null),
        _safeCall(() => SupabaseService.getLivreurProfile(), <String, dynamic>{}),
        _safeCall(() => SupabaseService.getLivreurProfile(), <String, dynamic>{}),
      ]);

      if (mounted) {
        setState(() {
          _profile = results[0] as Map<String, dynamic>?;
          _stats = results[1] as Map<String, dynamic>;
          _recentDeliveries = results[2] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
        _progressController.forward();
      }
    } catch (e) {
      debugPrint('Erreur chargement profil: $e');
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
                  SliverToBoxAdapter(child: _buildStatsGrid()),
                  SliverToBoxAdapter(child: _buildVehicleInfo()),
                  SliverToBoxAdapter(child: _buildRecentDeliveries()),
                  SliverToBoxAdapter(child: _buildMenuSection()),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    final name = _profile?['full_name'] ?? 'Livreur';
    final email = _profile?['email'] ?? '';
    final avatarUrl = _profile?['avatar_url'];
    final rating = (_stats?['avg_rating'] as num?)?.toDouble() ?? 5.0;
    final totalDeliveries = _stats?['total_deliveries'] ?? 0;

    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppColors.livreurPrimary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed: () => _showSettings(),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: AppColors.livreurGradient),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                // Avatar
                Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: AppShadows.lg,
                      ),
                      child: ClipOval(
                        child: avatarUrl != null
                            ? CachedNetworkImage(
                                imageUrl: avatarUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => const SkeletonLoader(),
                                errorWidget: (_, __, ___) => _buildAvatarPlaceholder(name),
                              )
                            : _buildAvatarPlaceholder(name),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _changeProfilePicture,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.livreurPrimary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: AppShadows.sm,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: AppTypography.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: AppTypography.labelMedium.copyWith(color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '• $totalDeliveries livraisons',
                            style: AppTypography.labelMedium.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder(String name) {
    return Container(
      color: AppColors.livreurPrimaryDark,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'L',
          style: AppTypography.displayMedium.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final totalEarnings = (_stats?['total_earnings'] as num?)?.toDouble() ?? 0;
    final todayDeliveries = _stats?['today_deliveries'] ?? 0;
    final weekEarnings = (_stats?['week_earnings'] as num?)?.toDouble() ?? 0;
    final avgDeliveryTime = _stats?['avg_delivery_time'] ?? 0;

    return Padding(
      padding: AppSpacing.screenHorizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vos performances', style: AppTypography.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatCard('💰', '${totalEarnings.toStringAsFixed(0)} DA', 'Gains totaux')),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('📦', '$todayDeliveries', 'Aujourd\'hui')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatCard('📅', '${weekEarnings.toStringAsFixed(0)} DA', 'Cette semaine')),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('⏱️', '${avgDeliveryTime} min', 'Temps moyen')),
            ],
          ),
        ],
      ),
    );
  }

  // _buildStatCard remplacé par StatCardSimple du shared/
  Widget _buildStatCard(String emoji, String value, String label) {
    return StatCardSimple(emoji: emoji, value: value, label: label);
  }

  Widget _buildVehicleInfo() {
    final vehicleType = _profile?['vehicle_type'] ?? 'moto';
    final vehiclePlate = _profile?['vehicle_plate'] ?? '';
    final vehicleModel = _profile?['vehicle_model'] ?? '';

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
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.livreurSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getVehicleIcon(vehicleType),
                  color: AppColors.livreurPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mon véhicule',
                      style: AppTypography.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getVehicleLabel(vehicleType),
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: AppColors.textTertiary),
                onPressed: _editVehicleInfo,
              ),
            ],
          ),
          if (vehiclePlate.isNotEmpty || vehicleModel.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            if (vehicleModel.isNotEmpty)
              _buildInfoRow('Modèle', vehicleModel),
            if (vehiclePlate.isNotEmpty)
              _buildInfoRow('Plaque', vehiclePlate),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentDeliveries() {
    return Padding(
      padding: AppSpacing.screenHorizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Livraisons récentes', style: AppTypography.titleMedium),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRouter.livreurHistory),
                child: Text(
                  'Voir tout',
                  style: AppTypography.labelMedium.copyWith(color: AppColors.livreurPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_recentDeliveries.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppSpacing.borderRadiusMd,
              ),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.delivery_dining, size: 48, color: AppColors.textTertiary),
                    const SizedBox(height: 12),
                    Text(
                      'Aucune livraison récente',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._recentDeliveries.take(3).map((delivery) => _buildDeliveryItem(delivery)),
        ],
      ),
    );
  }

  Widget _buildDeliveryItem(Map<String, dynamic> delivery) {
    final status = delivery['status'] ?? 'delivered';
    final earnings = (delivery['livreur_earnings'] as num?)?.toDouble() ?? 0;
    final date = delivery['delivered_at'] != null 
        ? DateTime.parse(delivery['delivered_at'])
        : DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusMd,
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.getStatusColor(status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.check_circle,
              color: AppColors.getStatusColor(status),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  delivery['restaurant_name'] ?? 'Restaurant',
                  style: AppTypography.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  '${date.day}/${date.month}/${date.year} • ${earnings.toStringAsFixed(0)} DA',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Livrée',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection() {
    final menuItems = [
      {'icon': Icons.history, 'label': 'Historique', 'route': AppRouter.livreurHistory},
      {'icon': Icons.account_balance_wallet, 'label': 'Gains', 'route': AppRouter.earnings},
      {'icon': Icons.map, 'label': 'Carte des restaurants', 'route': null, 'action': 'map'},
      {'icon': Icons.notifications, 'label': 'Notifications', 'route': AppRouter.notifications},
      {'icon': Icons.bug_report, 'label': 'Test Notifications', 'route': null, 'action': 'test_notifications'},
      {'icon': Icons.help_outline, 'label': 'Aide & Support', 'route': null},
      {'icon': Icons.info_outline, 'label': 'À propos', 'route': null},
    ];

    return Padding(
      padding: AppSpacing.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Menu', style: AppTypography.titleMedium),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppSpacing.borderRadiusMd,
              boxShadow: AppShadows.sm,
            ),
            child: Column(
              children: menuItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isLast = index == menuItems.length - 1;
                
                return Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.livreurSurface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(item['icon'] as IconData, color: AppColors.livreurPrimary, size: 20),
                      ),
                      title: Text(item['label'] as String, style: AppTypography.bodyMedium),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        final route = item['route'] as String?;
                        final action = item['action'] as String?;
                        
                        if (action == 'test_notifications') {
                          _testNotifications();
                        } else if (action == 'map') {
                          Navigator.pushNamed(context, '/livreur/map');
                        } else if (route != null) {
                          Navigator.pushNamed(context, route);
                        }
                      },
                    ),
                    if (!isLast) const Divider(height: 1, indent: 60),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          // Logout button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: Text(
                'Déconnexion',
                style: AppTypography.labelMedium.copyWith(color: AppColors.error),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // HELPERS & ACTIONS
  // ============================================

  IconData _getVehicleIcon(String? type) {
    switch (type) {
      case 'moto': return Icons.two_wheeler;
      case 'velo': return Icons.pedal_bike;
      case 'voiture': return Icons.directions_car;
      default: return Icons.delivery_dining;
    }
  }

  String _getVehicleLabel(String? type) {
    switch (type) {
      case 'moto': return 'Moto';
      case 'velo': return 'Vélo';
      case 'voiture': return 'Voiture';
      default: return 'Non défini';
    }
  }

  void _showSettings() {
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
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Modifier le profil'),
              onTap: () {
                Navigator.pop(ctx);
                _editProfile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('Mode sombre'),
              trailing: Switch(
                value: PreferencesService.isDarkMode,
                onChanged: (value) async {
                  await PreferencesService.setDarkMode(value);
                  if (mounted) {
                    DZDeliveryApp.setThemeMode(
                      value ? ThemeMode.dark : ThemeMode.light,
                    );
                  }
                },
                activeColor: AppColors.livreurPrimary,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Langue'),
              subtitle: Text(_getLanguageLabel(PreferencesService.language)),
              onTap: () {
                Navigator.pop(ctx);
                _showLanguageSelector();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _changeProfilePicture() async {
    HapticFeedback.lightImpact();
    
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
          children: [
            const Text(
              'Changer la photo de profil',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceOption(
                  icon: Icons.camera_alt,
                  label: 'Caméra',
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildImageSourceOption(
                  icon: Icons.photo_library,
                  label: 'Galerie',
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                if (_profile?['avatar_url'] != null)
                  _buildImageSourceOption(
                    icon: Icons.delete,
                    label: 'Supprimer',
                    color: AppColors.error,
                    onTap: () {
                      Navigator.pop(ctx);
                      _removeProfilePicture();
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: (color ?? AppColors.livreurPrimary).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color ?? AppColors.livreurPrimary,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color ?? AppColors.textPrimary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image == null) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(color: AppColors.livreurPrimary),
        ),
      );

      final bytes = await image.readAsBytes();
      final userId = SupabaseService.currentUserId;
      final fileName = 'avatar_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      final avatarUrl = await SupabaseService.uploadAvatar(fileName, bytes);
      await SupabaseService.updateProfile({'avatar_url': avatarUrl});
      await _loadData();
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo de profil mise à jour! 📸'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _removeProfilePicture() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(color: AppColors.livreurPrimary),
        ),
      );

      await SupabaseService.updateProfile({'avatar_url': null});
      await _loadData();
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo de profil supprimée'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _getLanguageLabel(String languageCode) {
    switch (languageCode) {
      case 'fr': return 'Français';
      case 'ar': return 'العربية';
      case 'en': return 'English';
      default: return 'Français';
    }
  }

  void _showLanguageSelector() {
    final languages = [
      {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
      {'code': 'ar', 'name': 'العربية', 'flag': '🇩🇿'},
      {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choisir la langue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.map((lang) => ListTile(
            leading: Text(lang['flag']!, style: const TextStyle(fontSize: 24)),
            title: Text(lang['name']!),
            trailing: PreferencesService.language == lang['code']
                ? const Icon(Icons.check, color: AppColors.livreurPrimary)
                : null,
            onTap: () async {
              await PreferencesService.setLanguage(lang['code']!);
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Langue changée: ${lang['name']}'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _editProfile() {
    final nameController = TextEditingController(text: _profile?['full_name'] ?? '');
    final phoneController = TextEditingController(text: _profile?['phone'] ?? '');
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modifier le profil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nom complet',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final phone = phoneController.text.trim();
              
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Le nom ne peut pas être vide'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              
              try {
                Navigator.pop(ctx);
                
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) => const Center(
                    child: CircularProgressIndicator(color: AppColors.livreurPrimary),
                  ),
                );
                
                await SupabaseService.updateProfile({
                  'full_name': name,
                  'phone': phone.isNotEmpty ? phone : null,
                });
                
                await _loadData();
                
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profil mis à jour! ✅'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: ${e.toString()}'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.livreurPrimary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );
  }

  void _editVehicleInfo() {
    String selectedVehicleType = _profile?['vehicle_type'] ?? 'moto';
    final plateController = TextEditingController(text: _profile?['vehicle_plate'] ?? '');
    final modelController = TextEditingController(text: _profile?['vehicle_model'] ?? '');
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Informations véhicule'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedVehicleType,
                decoration: const InputDecoration(
                  labelText: 'Type de véhicule',
                  prefixIcon: Icon(Icons.directions_car),
                ),
                items: const [
                  DropdownMenuItem(value: 'moto', child: Text('Moto')),
                  DropdownMenuItem(value: 'velo', child: Text('Vélo')),
                  DropdownMenuItem(value: 'voiture', child: Text('Voiture')),
                ],
                onChanged: (value) {
                  setState(() => selectedVehicleType = value!);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: modelController,
                decoration: const InputDecoration(
                  labelText: 'Modèle (optionnel)',
                  prefixIcon: Icon(Icons.info),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: plateController,
                decoration: const InputDecoration(
                  labelText: 'Plaque d\'immatriculation (optionnel)',
                  prefixIcon: Icon(Icons.confirmation_number),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  Navigator.pop(ctx);
                  
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) => const Center(
                      child: CircularProgressIndicator(color: AppColors.livreurPrimary),
                    ),
                  );
                  
                  await SupabaseService.updateProfile({
                    'vehicle_type': selectedVehicleType,
                    'vehicle_model': modelController.text.trim().isNotEmpty ? modelController.text.trim() : null,
                    'vehicle_plate': plateController.text.trim().isNotEmpty ? plateController.text.trim() : null,
                  });
                  
                  await _loadData();
                  
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Informations véhicule mises à jour! 🚗'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur: ${e.toString()}'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.livreurPrimary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sauvegarder'),
            ),
          ],
        ),
      ),
    );
  }

  void _testNotifications() async {
    HapticFeedback.lightImpact();
    
    await OneSignalService.sendTestNotification();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🧪 Notification de test envoyée!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _logout() {
    HapticFeedback.mediumImpact();
    showLogoutConfirmation(primaryColor: AppColors.livreurPrimary);
  }
}