import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/design_system/theme/app_colors.dart';
import '../../../../core/services/supabase_service.dart';

/// Mixin pour la gestion de l'avatar/photo de profil
/// Utilisable par Customer, Livreur et Restaurant
mixin AvatarMixin<T extends StatefulWidget> on State<T> {
  final ImagePicker _picker = ImagePicker();

  /// Affiche le bottom sheet pour choisir la source de l'image
  void showAvatarPicker({
    required String? currentAvatarUrl,
    required Future<void> Function(String imagePath) onImagePicked,
    required Future<void> Function() onRemove,
    Color primaryColor = AppColors.primary,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Changer la photo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAvatarOption(
                  icon: Icons.camera_alt,
                  label: 'Caméra',
                  color: primaryColor,
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera, onImagePicked);
                  },
                ),
                _buildAvatarOption(
                  icon: Icons.photo_library,
                  label: 'Galerie',
                  color: primaryColor,
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery, onImagePicked);
                  },
                ),
                if (currentAvatarUrl != null)
                  _buildAvatarOption(
                    icon: Icons.delete,
                    label: 'Supprimer',
                    color: AppColors.error,
                    onTap: () {
                      Navigator.pop(ctx);
                      onRemove();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(
    ImageSource source,
    Future<void> Function(String imagePath) onImagePicked,
  ) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (image != null) {
        await onImagePicked(image.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Upload une image vers Supabase et retourne l'URL
  Future<String?> uploadAvatarImage({
    required String imagePath,
    required String bucket,
    required String folder,
    Color loadingColor = AppColors.primary,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: CircularProgressIndicator(color: loadingColor),
      ),
    );

    try {
      final bytes = await XFile(imagePath).readAsBytes();
      final userId = SupabaseService.currentUserId;
      final fileName = '${folder}_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      final avatarUrl = await SupabaseService.uploadAvatar(fileName, bytes);
      
      if (mounted) Navigator.pop(context);
      return avatarUrl;
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur upload: $e'), backgroundColor: AppColors.error),
        );
      }
      return null;
    }
  }
}
