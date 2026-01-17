import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../../../core/design_system/theme/app_colors.dart';
import '../../../../core/design_system/theme/app_typography.dart';
import '../../../../core/design_system/theme/app_spacing.dart';
import '../../../../core/services/supabase_service.dart';

/// Écran Profil Restaurant Complet
/// - Photo de couverture
/// - Logo restaurant
/// - Informations modifiables
/// - Plat du jour
/// - Avis clients
/// - Déconnexion
class RestaurantProfileScreenV2 extends ConsumerStatefulWidget {
  const RestaurantProfileScreenV2({super.key});

  @override
  ConsumerState<RestaurantProfileScreenV2> createState() => _RestaurantProfileScreenV2State();
}

class _RestaurantProfileScreenV2State extends ConsumerState<RestaurantProfileScreenV2> {
  Map<String, dynamic>? _restaurant;
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;
  bool _isUploading = false;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final restaurant = await SupabaseService.getMyRestaurant();
      if (restaurant != null) {
        final reviews = await SupabaseService.getRestaurantReviews(restaurant['id']);
        setState(() {
          _restaurant = restaurant;
          _reviews = reviews;
          _nameController.text = restaurant['name'] ?? '';
          _phoneController.text = restaurant['phone'] ?? '';
          _addressController.text = restaurant['address'] ?? '';
          _descriptionController.text = restaurant['description'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _uploadCoverImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _isUploading = true);
    try {
      final bytes = await image.readAsBytes();
      final url = await SupabaseService.uploadRestaurantCover(bytes);
      if (url != null) {
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo de couverture mise à jour'), backgroundColor: AppColors.success),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _uploadLogo() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _isUploading = true);
    try {
      final bytes = await image.readAsBytes();
      final url = await SupabaseService.uploadRestaurantLogo(bytes);
      if (url != null) {
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Logo mis à jour'), backgroundColor: AppColors.success),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _saveProfile() async {
    try {
      await SupabaseService.updateRestaurant({
        'name': _nameController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'description': _descriptionController.text,
      });
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SupabaseService.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/auth');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_restaurant == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil')),
        body: const Center(child: Text('Restaurant non trouvé')),
      );
    }

    final rating = (_restaurant!['rating'] as num?)?.toDouble() ?? 0.0;
    final totalReviews = _restaurant!['total_reviews'] ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Header avec photo de couverture
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (_restaurant!['cover_url'] != null)
                    Image.network(
                      _restaurant!['cover_url'],
                      fit: BoxFit.cover,
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: FloatingActionButton.small(
                      onPressed: _isUploading ? null : _uploadCoverImage,
                      backgroundColor: Colors.white,
                      child: _isUploading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.camera_alt, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                // Logo et infos principales
                Transform.translate(
                  offset: const Offset(0, -40),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              color: AppColors.surface,
                            ),
                            child: _restaurant!['logo_url'] != null
                                ? ClipOval(
                                    child: Image.network(
                                      _restaurant!['logo_url'],
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(Icons.restaurant, size: 50, color: AppColors.primary),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: GestureDetector(
                              onTap: _isUploading ? null : _uploadLogo,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: _isUploading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.edit, size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _restaurant!['name'] ?? '',
                        style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star, color: AppColors.warning, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            '${rating.toStringAsFixed(1)} ($totalReviews avis)',
                            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Formulaire d'édition
                Padding(
                  padding: AppSpacing.screen,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Informations', style: AppTypography.titleLarge),
                      const SizedBox(height: 16),
                      
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nom du restaurant',
                          prefixIcon: Icon(Icons.restaurant),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      TextField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Téléphone',
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      
                      TextField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Adresse',
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      
                      TextField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),
                      
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _saveProfile,
                          icon: const Icon(Icons.save),
                          label: const Text('Enregistrer les modifications'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Avis clients
                      Text('Avis clients', style: AppTypography.titleLarge),
                      const SizedBox(height: 16),
                      
                      if (_reviews.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              'Aucun avis pour le moment',
                              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                        )
                      else
                        ..._reviews.take(5).map((review) => _ReviewCard(review: review)),
                      
                      const SizedBox(height: 32),

                      // Déconnexion
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout),
                          label: const Text('Déconnexion'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final rating = (review['restaurant_rating'] as num?)?.toInt() ?? 0;
    final comment = review['comment'] as String?;
    final customerName = review['customer']?['full_name'] ?? 'Client';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(
                  customerName[0].toUpperCase(),
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customerName, style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          size: 16,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (comment != null && comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(comment, style: AppTypography.bodyMedium),
          ],
        ],
      ),
    );
  }
}
