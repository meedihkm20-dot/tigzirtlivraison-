import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    try {
      if (!SupabaseService.isLoggedIn) {
        Navigator.pushReplacementNamed(context, AppRouter.login);
        return;
      }

      // Récupérer le rôle et rediriger
      final role = await SupabaseService.getUserRole();
      
      if (role == null) {
        // Profil introuvable → déconnecter et retourner au login
        await SupabaseService.signOut();
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, AppRouter.login);
        return;
      }
      
      switch (role) {
        case 'customer':
          Navigator.pushReplacementNamed(context, AppRouter.customerHome);
          break;
        case 'restaurant':
          final isVerified = await SupabaseService.isRestaurantVerified();
          if (isVerified) {
            Navigator.pushReplacementNamed(context, AppRouter.restaurantHome);
          } else {
            Navigator.pushReplacementNamed(context, AppRouter.pendingApproval, arguments: 'restaurant');
          }
          break;
        case 'livreur':
          final isVerified = await SupabaseService.isLivreurVerified();
          if (isVerified) {
            Navigator.pushReplacementNamed(context, AppRouter.livreurHome);
          } else {
            Navigator.pushReplacementNamed(context, AppRouter.pendingApproval, arguments: 'livreur');
          }
          break;
        default:
          // Rôle inconnu → déconnecter
          await SupabaseService.signOut();
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, AppRouter.login);
      }
    } catch (e) {
      // En cas d'erreur → déconnecter et retourner au login
      debugPrint('Erreur splash: $e');
      await SupabaseService.signOut();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRouter.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.delivery_dining, size: 80, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 24),
            const Text(
              'DZ Delivery',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              'Livraison rapide à Tigzirt',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
