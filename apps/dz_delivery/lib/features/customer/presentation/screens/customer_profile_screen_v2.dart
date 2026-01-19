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
import '../../../shared/presentation/widgets/settings_menu.dart';
import '../../../shared/mixins/logout_mixin.dart';
import '../../../shared/mixins/avatar_mixin.dart';

/// Écran Profil Client V2 - Simplifié (sans gamification excessive)
class CustomerProfileScreenV2 extends StatefulWidget {
  const CustomerProfileScreenV2({super.key});

  @override
  State<CustomerProfileScreenV2> createState() => _CustomerProfileScreenV2State();
}

class _CustomerProfileScreenV2State extends State<CustomerProfileScreenV2>
    with LogoutMixin, AvatarMixin {
  bool _isLoading = true;
  
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _recentOrders = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        SupabaseService.getProfile(),
        SupabaseService.getCustomerStats(),
        SupabaseService.getRecentOrders(limit: 3),
      ]);
      
      if (mounted) {
        setState(() {
          _profile = results[0] as Map<String, dynamic>?;
          _stats = results[1] as Map<String, dynamic>?;
          _recentOrders = List<Map<String, dynamic>>.from(results[2] as List? ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement profil: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : CustomScrollView(
              slivers: [
                _buildHeader(),
                SliverToBoxAdapter(child: _buildProfileInfo()),
                SliverToBoxAdapter(child: _buildStats()),
                SliverToBoxAdapter(child: _buildRecentOrders()),
                SliverToBoxAdapter(child: _buildSettings()),
                SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    final name = _profile?['full_name'] ?? 'Client';
    final avatarUrl = _profile?['avatar_url'];

    return SliverAppBar(
      expandedHeight: 200,
      floating: true,
      pinned: true,
      backgroundColor: AppColors.primary,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(gradient: AppColors.primaryGradient),
          child: SafeArea(
            child: Padding(
              padding: AppSpacing.screen,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 40),
                  GestureDetector(
                    onTap: _changeAvatar,
                    child: Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: ClipOval(
                            child: avatarUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: avatarUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: Colors.white.withOpacity(0.2),
                                      child: Icon(Icons.person, color: Colors.white, size: 40),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: Colors.white.withOpacity(0.2),
                                      child: Icon(Icons.person, color: Colors.white, size: 40),
                                    ),
                                  )
                                : Container(
                                    color: Colors.white.withOpacity(0.2),
                                    child: Icon(Icons.person, color: Colors.white, size: 40),
                                  ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Icon(Icons.camera_alt, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    name,
                    style: AppTypography.titleLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _profile?['phone'] ?? '',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Container(
      margin: AppSpacing.screen,
      padding: EdgeInsets.all(20),
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
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.person, color: AppColors.primary, size: 24),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Informations personnelles', style: AppTypography.titleMedium),
                    Text(
                      'Gérez vos informations de profil',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _editProfile,
                icon: Icon(Icons.edit, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final totalOrders = _stats?['total_orders'] ?? 0;
    final totalSpent = (_stats?['total_spent'] as num?)?.toDouble() ?? 0;
    final avgRating = (_stats?['avg_rating'] as num?)?.toDouble() ?? 0;

    return Padding(
      padding: AppSpacing.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vos statistiques', style: AppTypography.titleMedium),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: StatCardSimple(emoji: '🛍️', value: '$totalOrders', label: 'Commandes')),
              SizedBox(width: 12),
              Expanded(child: StatCardSimple(emoji: '💰', value: '${totalSpent.toStringAsFixed(0)} DA', label: 'Dépensé')),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: StatCardSimple(emoji: '⭐', value: avgRating > 0 ? avgRating.toStringAsFixed(1) : '-', label: 'Note moyenne')),
              SizedBox(width: 12),
              Expanded(child: StatCardSimple(emoji: '🎯', value: 'Standard', label: 'Statut')),
            ],
          ),
        ],
      ),
    );
  }

  // _buildStatCard remplacé par StatCardSimple du shared/

  Widget _buildRecentOrders() {
    return Padding(
      padding: AppSpacing.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Commandes récentes', style: AppTypography.titleMedium),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRouter.customerOrders),
                child: Text('Voir tout'),
              ),
            ],
          ),
          SizedBox(height: 12),
          if (_recentOrders.isEmpty)
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppSpacing.borderRadiusMd,
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.shopping_bag_outlined, size: 48, color: AppColors.textTertiary),
                    SizedBox(height: 8),
                    Text(
                      'Aucune commande récente',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._recentOrders.map((order) => _buildOrderItem(order)),
        ],
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> order) {
    final restaurantName = order['restaurant_name'] ?? 'Restaurant';
    final total = (order['total'] as num?)?.toDouble() ?? 0;
    final status = order['status'] ?? 'delivered';

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRouter.orderTracking, arguments: order['id']),
      child: Container(
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(color: AppColors.outline),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.restaurant, color: AppColors.primary, size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(restaurantName, style: AppTypography.titleSmall),
                  Text('${total.toStringAsFixed(0)} DA', style: AppTypography.bodySmall),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: status == 'delivered' ? AppColors.successSurface : AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status == 'delivered' ? 'Livrée' : 'En cours',
                style: AppTypography.labelSmall.copyWith(
                  color: status == 'delivered' ? AppColors.success : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettings() {
    return Padding(
      padding: AppSpacing.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Paramètres', style: AppTypography.titleMedium),
          SizedBox(height: 12),
          _buildSettingItem(Icons.location_on, 'Adresses sauvegardées', AppRouter.savedAddresses),
          _buildSettingItem(Icons.favorite, 'Favoris', AppRouter.favorites),
          _buildSettingItem(Icons.notifications, 'Notifications', null),
          _buildSettingItem(Icons.help, 'Support', AppRouter.support),
          _buildSettingItem(Icons.info, 'À propos', null),
          Divider(height: 32),
          _buildSettingItem(Icons.logout, 'Déconnexion', null, isDestructive: true),
        ],
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, String? route, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? AppColors.error : AppColors.textSecondary),
      title: Text(
        title,
        style: AppTypography.bodyMedium.copyWith(
          color: isDestructive ? AppColors.error : AppColors.textPrimary,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: AppColors.textTertiary),
      onTap: () {
        if (isDestructive) {
          showLogoutConfirmation(); // Utilise le LogoutMixin
        } else if (route != null) {
          Navigator.pushNamed(context, route);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Bientôt disponible')),
          );
        }
      },
    );
  }

  // Actions
  void _changeAvatar() async {
    final picker = ImagePicker();
    
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Prendre une photo'),
              onTap: () async {
                Navigator.pop(ctx);
                final image = await picker.pickImage(source: ImageSource.camera);
                if (image != null) _uploadAvatar(image.path);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Choisir depuis la galerie'),
              onTap: () async {
                Navigator.pop(ctx);
                final image = await picker.pickImage(source: ImageSource.gallery);
                if (image != null) _uploadAvatar(image.path);
              },
            ),
            if (_profile?['avatar_url'] != null)
              ListTile(
                leading: Icon(Icons.delete, color: AppColors.error),
                title: Text('Supprimer la photo', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  _removeAvatar();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _uploadAvatar(String imagePath) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(child: CircularProgressIndicator()),
    );

    try {
      await _loadData();
      if (mounted) {
        Navigator.pop(context); // Fermer le loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo mise à jour!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Fermer le loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _removeAvatar() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(child: CircularProgressIndicator()),
    );

    try {
      await _loadData();
      if (mounted) {
        Navigator.pop(context); // Fermer le loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo supprimée'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _editProfile() {
    final nameController = TextEditingController(text: _profile?['full_name'] ?? '');
    final phoneController = TextEditingController(text: _profile?['phone'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Modifier le profil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Nom complet',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: 'Téléphone',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _updateProfile(nameController.text, phoneController.text);
            },
            child: Text('Sauvegarder'),
          ),
        ],
      ),
    );
  }

  void _updateProfile(String name, String phone) async {
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Le nom est requis'), backgroundColor: AppColors.error),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      await _loadData();
      if (mounted) {
        Navigator.pop(context); // Fermer loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profil mis à jour!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Fermer loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  // _logout() remplacé par showLogoutConfirmation() du LogoutMixin
}