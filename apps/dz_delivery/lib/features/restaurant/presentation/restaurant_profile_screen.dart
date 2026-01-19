import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
// Shared components
import '../../shared/mixins/logout_mixin.dart';

class RestaurantProfileScreen extends StatefulWidget {
  const RestaurantProfileScreen({super.key});

  @override
  State<RestaurantProfileScreen> createState() => _RestaurantProfileScreenState();
}

class _RestaurantProfileScreenState extends State<RestaurantProfileScreen>
    with LogoutMixin {
  Map<String, dynamic>? _restaurant;
  bool _isLoading = true;
  bool _isUploading = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final restaurant = await SupabaseService.getMyRestaurant();
      setState(() {
        _restaurant = restaurant;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadLogo() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 500, imageQuality: 80);
    if (image == null) return;

    setState(() => _isUploading = true);
    try {
      final bytes = await image.readAsBytes();
      final url = await SupabaseService.uploadRestaurantLogo(bytes);
      if (url != null) {
        await _loadProfile();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logo mis à jour!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _pickAndUploadCover() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
    if (image == null) return;

    setState(() => _isUploading = true);
    try {
      final bytes = await image.readAsBytes();
      final url = await SupabaseService.uploadRestaurantCover(bytes);
      if (url != null) {
        await _loadProfile();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo de couverture mise à jour!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _showEditDialog() {
    final nameController = TextEditingController(text: _restaurant?['name'] ?? '');
    final descController = TextEditingController(text: _restaurant?['description'] ?? '');
    final phoneController = TextEditingController(text: _restaurant?['phone'] ?? '');
    final addressController = TextEditingController(text: _restaurant?['address'] ?? '');
    final cuisineController = TextEditingController(text: _restaurant?['cuisine_type'] ?? '');
    final openingController = TextEditingController(text: _restaurant?['opening_time']?.toString().substring(0, 5) ?? '08:00');
    final closingController = TextEditingController(text: _restaurant?['closing_time']?.toString().substring(0, 5) ?? '23:00');
    final deliveryFeeController = TextEditingController(text: (_restaurant?['delivery_fee'] ?? 0).toString());
    final minOrderController = TextEditingController(text: (_restaurant?['min_order_amount'] ?? 0).toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Modifier le profil', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nom du restaurant', prefixIcon: Icon(Icons.restaurant)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Décrivez votre restaurant, spécialités, ambiance...',
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cuisineController,
                decoration: const InputDecoration(labelText: 'Type de cuisine', prefixIcon: Icon(Icons.local_dining), hintText: 'Ex: Algérien, Pizza, Fast-food'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Téléphone', prefixIcon: Icon(Icons.phone)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Adresse', prefixIcon: Icon(Icons.location_on)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: openingController,
                      decoration: const InputDecoration(labelText: 'Ouverture', prefixIcon: Icon(Icons.access_time)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: closingController,
                      decoration: const InputDecoration(labelText: 'Fermeture', prefixIcon: Icon(Icons.access_time)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: deliveryFeeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Frais livraison (DA)', prefixIcon: Icon(Icons.delivery_dining)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: minOrderController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Commande min (DA)', prefixIcon: Icon(Icons.shopping_cart)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    await SupabaseService.updateRestaurant({
                      'name': nameController.text,
                      'description': descController.text,
                      'cuisine_type': cuisineController.text,
                      'phone': phoneController.text,
                      'address': addressController.text,
                      'opening_time': openingController.text,
                      'closing_time': closingController.text,
                      'delivery_fee': double.tryParse(deliveryFeeController.text) ?? 0,
                      'min_order_amount': double.tryParse(minOrderController.text) ?? 0,
                    });
                    Navigator.pop(context);
                    _loadProfile();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profil mis à jour!'), backgroundColor: Colors.green),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                  child: const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // _logout() remplacé par showLogoutConfirmation() du LogoutMixin

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // Cover image with logo
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Cover image
                        _restaurant?['cover_url'] != null
                            ? Image.network(_restaurant!['cover_url'], fit: BoxFit.cover)
                            : Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.7)],
                                  ),
                                ),
                              ),
                        // Gradient overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                            ),
                          ),
                        ),
                        // Edit cover button
                        Positioned(
                          right: 16,
                          bottom: 60,
                          child: GestureDetector(
                            onTap: _isUploading ? null : _pickAndUploadCover,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: _isUploading
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.camera_alt, size: 18),
                                        SizedBox(width: 4),
                                        Text('Couverture', style: TextStyle(fontSize: 12)),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    IconButton(icon: const Icon(Icons.edit), onPressed: _showEditDialog),
                  ],
                ),
                
                SliverToBoxAdapter(
                  child: Transform.translate(
                    offset: const Offset(0, -40),
                    child: Column(
                      children: [
                        // Logo
                        GestureDetector(
                          onTap: _isUploading ? null : _pickAndUploadLogo,
                          child: Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 4),
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10)],
                                  image: _restaurant?['logo_url'] != null
                                      ? DecorationImage(image: NetworkImage(_restaurant!['logo_url']), fit: BoxFit.cover)
                                      : null,
                                ),
                                child: _restaurant?['logo_url'] == null
                                    ? const Icon(Icons.restaurant, size: 40, color: Colors.grey)
                                    : null,
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                                  child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Name and rating
                        Text(
                          _restaurant?['name'] ?? 'Restaurant',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 20),
                            Text(
                              ' ${(_restaurant?['rating'] ?? 0).toStringAsFixed(1)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(' (${_restaurant?['total_reviews'] ?? 0} avis)', style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                        if (_restaurant?['cuisine_type'] != null) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(_restaurant!['cuisine_type'], style: TextStyle(color: AppTheme.primaryColor)),
                          ),
                        ],
                        
                        // Description
                        if (_restaurant?['description'] != null && _restaurant!['description'].toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              _restaurant!['description'],
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[600], fontSize: 14),
                            ),
                          ),
                        
                        const Divider(height: 32),
                        
                        // Info cards
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              _buildInfoCard(Icons.location_on, 'Adresse', _restaurant?['address'] ?? 'Non définie'),
                              _buildInfoCard(Icons.phone, 'Téléphone', _restaurant?['phone'] ?? 'Non défini'),
                              _buildInfoCard(
                                Icons.access_time,
                                'Horaires',
                                '${_restaurant?['opening_time']?.toString().substring(0, 5) ?? '08:00'} - ${_restaurant?['closing_time']?.toString().substring(0, 5) ?? '23:00'}',
                              ),
                              _buildInfoCard(
                                Icons.delivery_dining,
                                'Frais de livraison',
                                '${(_restaurant?['delivery_fee'] ?? 0).toStringAsFixed(0)} DA',
                              ),
                              _buildInfoCard(
                                Icons.shopping_cart,
                                'Commande minimum',
                                '${(_restaurant?['min_order_amount'] ?? 0).toStringAsFixed(0)} DA',
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Logout button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: showLogoutConfirmation,
                              icon: const Icon(Icons.logout, color: Colors.red),
                              label: const Text('Se déconnecter', style: TextStyle(color: Colors.red)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
