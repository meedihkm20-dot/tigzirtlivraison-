import 'package:flutter/material.dart';

/// Bannière affichée quand l'app est hors ligne
class OfflineBanner extends StatelessWidget {
  final bool isOffline;
  final VoidCallback? onRetry;
  
  const OfflineBanner({
    super.key,
    required this.isOffline,
    this.onRetry,
  });
  
  @override
  Widget build(BuildContext context) {
    if (!isOffline) return const SizedBox.shrink();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.orange.shade800,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const Icon(Icons.wifi_off, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Pas de connexion internet',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('Réessayer'),
              ),
          ],
        ),
      ),
    );
  }
}

/// Wrapper qui affiche automatiquement la bannière offline
class NetworkAwareScaffold extends StatelessWidget {
  final bool isOffline;
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final VoidCallback? onRetry;
  
  const NetworkAwareScaffold({
    super.key,
    required this.isOffline,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.onRetry,
  });
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: Column(
        children: [
          OfflineBanner(isOffline: isOffline, onRetry: onRetry),
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
