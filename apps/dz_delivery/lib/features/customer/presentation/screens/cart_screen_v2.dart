import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/design_system/theme/app_colors.dart';
import '../../../../core/design_system/theme/app_typography.dart';
import '../../../../core/design_system/theme/app_spacing.dart';
import '../../../../core/design_system/theme/app_shadows.dart';
import '../../../../core/design_system/components/loaders/skeleton_loader.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/router/app_router.dart';

/// Écran Panier V2 - Premium
/// Panier intelligent avec suggestions, promos, pourboire, multi-adresses
class CartScreenV2 extends StatefulWidget {
  const CartScreenV2({super.key});

  @override
  State<CartScreenV2> createState() => _CartScreenV2State();
}

class _CartScreenV2State extends State<CartScreenV2> with TickerProviderStateMixin {
  bool _isLoading = true;
  bool _isProcessing = false;
  
  List<Map<String, dynamic>> _cartItems = [];
  List<Map<String, dynamic>> _suggestions = [];
  Map<String, dynamic>? _restaurant;
  Map<String, dynamic>? _selectedAddress;
  List<Map<String, dynamic>> _addresses = [];
  
  String? _promoCode;
  double _promoDiscount = 0;
  bool _promoApplied = false;
  String _promoError = '';
  
  int _tipIndex = 0; // 0=0%, 1=5%, 2=10%, 3=15%, 4=custom
  double _customTip = 0;
  final _tipOptions = [0.0, 0.05, 0.10, 0.15];
  
  String _paymentMethod = 'cash'; // cash, card
  String? _orderNote;
  DateTime? _scheduledTime;
  
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  
  final _promoController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );
    _loadData();
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _promoController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _safeCall(() => SupabaseService.getCartItems(), <Map<String, dynamic>>[]),
        _safeCall(() => SupabaseService.getSavedAddresses(), <Map<String, dynamic>>[]),
      ]);

      final items = results[0] as List<Map<String, dynamic>>;
      final addresses = results[1] as List<Map<String, dynamic>>;

      // Load suggestions if we have items
      List<Map<String, dynamic>> suggestions = [];
      if (items.isNotEmpty) {
        final restaurantId = items.first['restaurant_id'];
        suggestions = await _safeCall(
          () => SupabaseService.getMenuSuggestions(restaurantId, limit: 4),
          <Map<String, dynamic>>[],
        );
      }

      if (mounted) {
        setState(() {
          _cartItems = items;
          _addresses = addresses;
          _selectedAddress = addresses.isNotEmpty ? addresses.first : null;
          _suggestions = suggestions;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement panier: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<T> _safeCall<T>(Future<T> Function() call, T defaultValue) async {
    try {
      return await call();
    } catch (e) {
      debugPrint('Erreur: $e');
      return defaultValue;
    }
  }

  double get _subtotal => _cartItems.fold(0.0, (sum, item) {
    final price = (item['price'] as num?)?.toDouble() ?? 0;
    final qty = (item['quantity'] as num?)?.toInt() ?? 1;
    return sum + (price * qty);
  });

  double get _deliveryFee => _subtotal >= 2000 ? 0 : 200;
  
  double get _tipAmount {
    if (_tipIndex < _tipOptions.length) {
      return _subtotal * _tipOptions[_tipIndex];
    }
    return _customTip;
  }
  
  double get _total => _subtotal + _deliveryFee + _tipAmount - _promoDiscount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.clientPrimary))
          : _cartItems.isEmpty
              ? _buildEmptyCart()
              : _buildCartContent(),
      bottomNavigationBar: _cartItems.isNotEmpty ? _buildCheckoutBar() : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mon panier', style: AppTypography.titleMedium),
          if (_cartItems.isNotEmpty)
            Text(
              '${_cartItems.length} article${_cartItems.length > 1 ? 's' : ''}',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
            ),
        ],
      ),
      actions: [
        if (_cartItems.isNotEmpty)
          TextButton(
            onPressed: _clearCart,
            child: Text(
              'Vider',
              style: AppTypography.labelMedium.copyWith(color: AppColors.error),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: AppSpacing.screen,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.clientSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                size: 60,
                color: AppColors.clientPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Votre panier est vide',
              style: AppTypography.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Explorez nos restaurants et ajoutez\nvos plats préférés',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, AppRouter.customerHome),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.clientPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: AppSpacing.borderRadiusLg,
                ),
              ),
              child: const Text('Explorer les restaurants'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartContent() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Restaurant info
          _buildRestaurantHeader(),
          
          // Cart items
          _buildCartItems(),
          
          // Add more items
          _buildAddMoreButton(),
          
          // Suggestions
          if (_suggestions.isNotEmpty) _buildSuggestions(),
          
          // Delivery address
          _buildDeliverySection(),
          
          // Schedule order
          _buildScheduleSection(),
          
          // Promo code
          _buildPromoSection(),
          
          // Tip section
          _buildTipSection(),
          
          // Payment method
          _buildPaymentSection(),
          
          // Order note
          _buildNoteSection(),
          
          // Order summary
          _buildOrderSummary(),
          
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildRestaurantHeader() {
    if (_cartItems.isEmpty) return const SizedBox.shrink();
    final item = _cartItems.first;
    final restaurantName = item['restaurant_name'] ?? 'Restaurant';

    return Container(
      margin: AppSpacing.screen,
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
              gradient: AppColors.clientGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                restaurantName[0].toUpperCase(),
                style: AppTypography.titleLarge.copyWith(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(restaurantName, style: AppTypography.titleSmall),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      '25-35 min',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Free delivery badge
          if (_subtotal >= 2000)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.successSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_shipping, size: 14, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text(
                    'Gratuit',
                    style: AppTypography.labelSmall.copyWith(color: AppColors.success),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCartItems() {
    return Padding(
      padding: AppSpacing.screenHorizontal,
      child: Column(
        children: _cartItems.map((item) => _buildCartItem(item)).toList(),
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item) {
    final price = (item['price'] as num?)?.toDouble() ?? 0;
    final qty = (item['quantity'] as num?)?.toInt() ?? 1;

    return Dismissible(
      key: Key(item['id'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _removeItem(item['id']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.borderRadiusMd,
          boxShadow: AppShadows.sm,
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item['image_url'] != null
                  ? CachedNetworkImage(
                      imageUrl: item['image_url'],
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const SkeletonLoader(width: 70, height: 70),
                      errorWidget: (_, __, ___) => _buildItemPlaceholder(),
                    )
                  : _buildItemPlaceholder(),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'] ?? '',
                    style: AppTypography.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item['options'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      item['options'],
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    '${(price * qty).toStringAsFixed(0)} DA',
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.clientPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Quantity controls
            _buildQuantityControls(item, qty),
          ],
        ),
      ),
    );
  }

  Widget _buildItemPlaceholder() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.restaurant, color: AppColors.textTertiary),
    );
  }

  Widget _buildQuantityControls(Map<String, dynamic> item, int qty) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              qty > 1 ? Icons.remove : Icons.delete_outline,
              size: 18,
              color: qty > 1 ? AppColors.textPrimary : AppColors.error,
            ),
            onPressed: () => _updateQuantity(item['id'], qty - 1),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          AnimatedBuilder(
            animation: _bounceAnimation,
            builder: (context, child) => Transform.scale(
              scale: _bounceAnimation.value,
              child: Text(
                '$qty',
                style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: () => _updateQuantity(item['id'], qty + 1),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildAddMoreButton() {
    return Padding(
      padding: AppSpacing.screen,
      child: OutlinedButton.icon(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.add, color: AppColors.clientPrimary),
        label: Text(
          'Ajouter d\'autres articles',
          style: AppTypography.labelMedium.copyWith(color: AppColors.clientPrimary),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.clientPrimary),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusMd),
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text('💡 Vous aimerez aussi', style: AppTypography.titleMedium),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: AppSpacing.screenHorizontal,
            itemCount: _suggestions.length,
            itemBuilder: (context, index) => _buildSuggestionCard(_suggestions[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionCard(Map<String, dynamic> item) {
    final price = (item['price'] as num?)?.toDouble() ?? 0;

    return GestureDetector(
      onTap: () => _addSuggestion(item),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(color: AppColors.outline),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item['image_url'] != null
                  ? CachedNetworkImage(
                      imageUrl: item['image_url'],
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 50,
                      height: 50,
                      color: AppColors.surfaceVariant,
                      child: const Icon(Icons.restaurant, size: 24),
                    ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item['name'] ?? '',
                    style: AppTypography.labelMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${price.toStringAsFixed(0)} DA',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.clientPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.clientSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, size: 16, color: AppColors.clientPrimary),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildDeliverySection() {
    return Container(
      margin: AppSpacing.screen,
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.clientSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.location_on, color: AppColors.clientPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Adresse de livraison', style: AppTypography.titleSmall),
            ],
          ),
          const SizedBox(height: 16),
          if (_selectedAddress != null)
            GestureDetector(
              onTap: _showAddressSelector,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.clientPrimary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _selectedAddress!['type'] == 'home' ? Icons.home : Icons.work,
                                size: 16,
                                color: AppColors.clientPrimary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _selectedAddress!['label'] ?? 'Adresse',
                                style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedAddress!['address'] ?? '',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                  ],
                ),
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRouter.savedAddresses),
              icon: const Icon(Icons.add_location_alt, color: AppColors.clientPrimary),
              label: Text(
                'Ajouter une adresse',
                style: AppTypography.labelMedium.copyWith(color: AppColors.clientPrimary),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.clientPrimary),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScheduleSection() {
    return Container(
      margin: AppSpacing.screenHorizontal,
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.infoSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.schedule, color: AppColors.info, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Heure de livraison', style: AppTypography.titleSmall),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildScheduleOption(
                  'Dès que possible',
                  '25-35 min',
                  _scheduledTime == null,
                  () => setState(() => _scheduledTime = null),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildScheduleOption(
                  'Planifier',
                  _scheduledTime != null 
                      ? '${_scheduledTime!.hour}:${_scheduledTime!.minute.toString().padLeft(2, '0')}'
                      : 'Choisir',
                  _scheduledTime != null,
                  _showTimePicker,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleOption(String title, String subtitle, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.clientSurface : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.clientPrimary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected ? AppColors.clientPrimary : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: isSelected ? AppColors.clientPrimary : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoSection() {
    return Container(
      margin: AppSpacing.screen,
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warningSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.local_offer, color: AppColors.warning, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Code promo', style: AppTypography.titleSmall),
            ],
          ),
          const SizedBox(height: 16),
          if (_promoApplied)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.successSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Code $_promoCode appliqué',
                          style: AppTypography.labelMedium.copyWith(color: AppColors.success),
                        ),
                        Text(
                          '-${_promoDiscount.toStringAsFixed(0)} DA',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.success),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.success),
                    onPressed: _removePromo,
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promoController,
                    decoration: InputDecoration(
                      hintText: 'Entrez votre code',
                      hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      errorText: _promoError.isNotEmpty ? _promoError : null,
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _applyPromo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.clientPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Appliquer'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTipSection() {
    return Container(
      margin: AppSpacing.screenHorizontal,
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.successSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.volunteer_activism, color: AppColors.success, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pourboire livreur', style: AppTypography.titleSmall),
                    Text(
                      '100% va au livreur',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildTipOption(0, '0%', 0),
              const SizedBox(width: 8),
              _buildTipOption(1, '5%', (_subtotal * 0.05).round()),
              const SizedBox(width: 8),
              _buildTipOption(2, '10%', (_subtotal * 0.10).round()),
              const SizedBox(width: 8),
              _buildTipOption(3, '15%', (_subtotal * 0.15).round()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTipOption(int index, String label, int amount) {
    final isSelected = _tipIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _tipIndex = index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.clientPrimary : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (amount > 0)
                Text(
                  '${amount} DA',
                  style: AppTypography.labelSmall.copyWith(
                    color: isSelected ? Colors.white70 : AppColors.textTertiary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Container(
      margin: AppSpacing.screen,
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondarySurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.payment, color: AppColors.secondary, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Mode de paiement', style: AppTypography.titleSmall),
            ],
          ),
          const SizedBox(height: 16),
          _buildPaymentOption('cash', Icons.money, 'Espèces', 'Payer à la livraison'),
          const SizedBox(height: 8),
          _buildPaymentOption('card', Icons.credit_card, 'Carte bancaire', 'Bientôt disponible', disabled: true),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String value, IconData icon, String title, String subtitle, {bool disabled = false}) {
    final isSelected = _paymentMethod == value;
    return GestureDetector(
      onTap: disabled ? null : () {
        HapticFeedback.selectionClick();
        setState(() => _paymentMethod = value);
      },
      child: Opacity(
        opacity: disabled ? 0.5 : 1,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.clientSurface : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.clientPrimary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: isSelected ? AppColors.clientPrimary : AppColors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.labelMedium),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: AppColors.clientPrimary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoteSection() {
    return Container(
      margin: AppSpacing.screenHorizontal,
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.note_alt, color: AppColors.textSecondary, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Note pour le livreur', style: AppTypography.titleSmall),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Ex: Sonner 2 fois, code porte 1234...',
              hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (v) => _orderNote = v,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      margin: AppSpacing.screen,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusMd,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Récapitulatif', style: AppTypography.titleSmall),
          const SizedBox(height: 16),
          _buildSummaryRow('Sous-total', '${_subtotal.toStringAsFixed(0)} DA'),
          _buildSummaryRow(
            'Livraison',
            _deliveryFee == 0 ? 'Gratuit' : '${_deliveryFee.toStringAsFixed(0)} DA',
            valueColor: _deliveryFee == 0 ? AppColors.success : null,
          ),
          if (_tipAmount > 0)
            _buildSummaryRow('Pourboire', '${_tipAmount.toStringAsFixed(0)} DA'),
          if (_promoDiscount > 0)
            _buildSummaryRow(
              'Réduction',
              '-${_promoDiscount.toStringAsFixed(0)} DA',
              valueColor: AppColors.success,
            ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: AppTypography.titleMedium),
              Text(
                '${_total.toStringAsFixed(0)} DA',
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.clientPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (_subtotal < 2000) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.infoSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.info, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ajoutez ${(2000 - _subtotal).toStringAsFixed(0)} DA pour la livraison gratuite',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.info),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppShadows.lg,
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                  ),
                  Text(
                    '${_total.toStringAsFixed(0)} DA',
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.clientPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.clientPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusLg),
                  elevation: 0,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shopping_bag),
                          const SizedBox(width: 8),
                          Text('Commander', style: AppTypography.titleSmall.copyWith(color: Colors.white)),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // ACTIONS
  // ============================================
  
  void _updateQuantity(String itemId, int newQty) async {
    HapticFeedback.lightImpact();
    _bounceController.forward().then((_) => _bounceController.reverse());
    
    if (newQty <= 0) {
      _removeItem(itemId);
      return;
    }
    
    setState(() {
      final index = _cartItems.indexWhere((i) => i['id'] == itemId);
      if (index != -1) {
        _cartItems[index]['quantity'] = newQty;
      }
    });
    
    // Update in backend
    await SupabaseService.updateCartItemQuantity(itemId, newQty);
  }

  void _removeItem(String itemId) async {
    HapticFeedback.mediumImpact();
    setState(() {
      _cartItems.removeWhere((i) => i['id'] == itemId);
    });
    await SupabaseService.removeFromCart(itemId);
  }

  void _clearCart() async {
    HapticFeedback.heavyImpact();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vider le panier?'),
        content: const Text('Tous les articles seront supprimés.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Vider', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      setState(() => _cartItems.clear());
      await SupabaseService.clearCart();
    }
  }

  void _addSuggestion(Map<String, dynamic> item) async {
    HapticFeedback.lightImpact();
    await SupabaseService.addToCart(item['id'], 1);
    _loadData();
  }

  void _showAddressSelector() {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choisir une adresse', style: AppTypography.titleMedium),
            const SizedBox(height: 16),
            ..._addresses.map((addr) => ListTile(
              leading: Icon(
                addr['type'] == 'home' ? Icons.home : Icons.work,
                color: AppColors.clientPrimary,
              ),
              title: Text(addr['label'] ?? 'Adresse'),
              subtitle: Text(addr['address'] ?? ''),
              trailing: _selectedAddress?['id'] == addr['id']
                  ? const Icon(Icons.check_circle, color: AppColors.clientPrimary)
                  : null,
              onTap: () {
                setState(() => _selectedAddress = addr);
                Navigator.pop(ctx);
              },
            )),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, AppRouter.savedAddresses);
              },
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une nouvelle adresse'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTimePicker() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      final now = DateTime.now();
      setState(() {
        _scheduledTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
      });
    }
  }

  void _applyPromo() async {
    final code = _promoController.text.trim().toUpperCase();
    if (code.isEmpty) return;
    
    HapticFeedback.lightImpact();
    
    // Simulate promo validation
    if (code == 'BIENVENUE30') {
      setState(() {
        _promoCode = code;
        _promoDiscount = _subtotal * 0.30;
        _promoApplied = true;
        _promoError = '';
      });
    } else if (code == 'LIVRAISON') {
      setState(() {
        _promoCode = code;
        _promoDiscount = _deliveryFee;
        _promoApplied = true;
        _promoError = '';
      });
    } else {
      setState(() => _promoError = 'Code invalide');
    }
  }

  void _removePromo() {
    HapticFeedback.lightImpact();
    setState(() {
      _promoCode = null;
      _promoDiscount = 0;
      _promoApplied = false;
      _promoController.clear();
    });
  }

  void _placeOrder() async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une adresse de livraison')),
      );
      return;
    }

    setState(() => _isProcessing = true);
    HapticFeedback.heavyImpact();

    try {
      // Calculate totals
      final subtotal = _cartItems.fold<double>(0, (sum, item) => 
        sum + ((item['price'] as num).toDouble() * (item['quantity'] as int)));
      final deliveryFee = _deliveryFee - _promoDiscount;
      final tip = _tipAmount;
      final total = subtotal + deliveryFee + tip;
      
      final restaurantId = _cartItems.isNotEmpty ? _cartItems.first['restaurant_id'] : '';
      
      final orderResponse = await SupabaseService.createOrder(
        restaurantId: restaurantId,
        items: _cartItems,
        deliveryAddress: _selectedAddress!['address'] ?? '',
        deliveryLat: (_selectedAddress!['lat'] as num?)?.toDouble() ?? 0,
        deliveryLng: (_selectedAddress!['lng'] as num?)?.toDouble() ?? 0,
        deliveryInstructions: _orderNote,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        total: total,
        paymentMethod: _paymentMethod,
      );

      if (mounted) {
        // Clear cart and navigate to tracking
        await SupabaseService.clearCart();
        Navigator.pushReplacementNamed(
          context,
          AppRouter.orderTracking,
          arguments: orderResponse['id'],
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
