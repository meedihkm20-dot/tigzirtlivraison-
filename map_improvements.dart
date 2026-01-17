  /// Afficher les informations d'un marqueur et options de navigation
  void _showMarkerInfo(String markerType) {
    HapticFeedback.lightImpact();
    
    String title = '';
    String subtitle = '';
    LatLng? position;
    IconData icon = Icons.place;
    Color color = AppColors.primary;
    
    switch (markerType) {
      case 'restaurant':
        title = _order?['restaurant_name'] ?? 'Restaurant';
        subtitle = 'Point de récupération';
        position = _restaurantPosition;
        icon = Icons.restaurant;
        color = AppColors.primary;
        break;
      case 'delivery':
        title = 'Adresse de livraison';
        subtitle = _order?['delivery_address'] ?? 'Votre adresse';
        position = _deliveryPosition;
        icon = Icons.home;
        color = AppColors.success;
        break;
      case 'livreur':
        title = _livreur?['full_name'] ?? 'Livreur';
        subtitle = 'Position en temps réel';
        position = _livreurPosition;
        icon = Icons.delivery_dining;
        color = AppColors.livreurPrimary;
        break;
    }
    
    if (position == null) return;
    
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTypography.titleMedium),
                      Text(subtitle, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _openExternalNavigation(position!, 'google');
                    },
                    icon: const Icon(Icons.map),
                    label: const Text('Google Maps'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.clientPrimary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _openExternalNavigation(position!, 'waze');
                    },
                    icon: const Icon(Icons.navigation),
                    label: const Text('Waze'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF33CCFF),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _centerMapOn(position!);
              },
              child: const Text('Centrer sur la carte'),
            ),
          ],
        ),
      ),
    );
  }

  /// Ouvrir la navigation externe (Google Maps ou Waze)
  void _openExternalNavigation(LatLng destination, String app) async {
    final lat = destination.latitude;
    final lng = destination.longitude;
    
    String url = '';
    String appName = '';
    
    switch (app) {
      case 'google':
        url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving';
        appName = 'Google Maps';
        break;
      case 'waze':
        url = 'https://waze.com/ul?ll=$lat,$lng&navigate=yes';
        appName = 'Waze';
        break;
    }
    
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$appName n\'est pas installé'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ouverture de $appName'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Centrer la carte sur une position
  void _centerMapOn(LatLng position) {
    _mapController.move(position, 16);
  }