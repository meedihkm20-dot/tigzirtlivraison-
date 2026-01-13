import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/supabase_service.dart';

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  static const String adminPhone = '0556248038';
  static const String adminWhatsApp = '213556248038';
  static const String adminFacebook = 'mee.di.hkm';
  static const String adminInstagram = 'mee.di.hkm';

  Future<void> _callAdmin() async {
    final uri = Uri.parse('tel:$adminPhone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _whatsAppAdmin() async {
    final uri = Uri.parse('https://wa.me/$adminWhatsApp?text=Bonjour,%20je%20souhaite%20devenir%20livreur%20sur%20DZ%20Delivery');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openFacebook() async {
    final uri = Uri.parse('https://www.facebook.com/$adminFacebook');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openInstagram() async {
    final uri = Uri.parse('https://www.instagram.com/$adminInstagram');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _checkStatus(BuildContext context) async {
    try {
      final livreur = await SupabaseService.getLivreurProfile();
      if (livreur != null && livreur['is_verified'] == true) {
        Navigator.pushReplacementNamed(context, AppRouter.home);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Votre compte est toujours en attente de validation'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Votre demande est en cours de traitement'), backgroundColor: Colors.orange),
      );
    }
  }

  Future<void> _logout(BuildContext context) async {
    await SupabaseService.signOut();
    Navigator.pushReplacementNamed(context, AppRouter.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.hourglass_empty, size: 80, color: Colors.orange),
              ),
              const SizedBox(height: 32),
              const Text('Demande en attente', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Text(
                'Votre demande pour devenir livreur a été enregistrée.\n\nContactez-nous pour finaliser votre inscription.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              const Text('Contactez-nous :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildContactButton(Icons.phone, 'Appeler', Colors.blue, _callAdmin),
                  _buildContactButton(Icons.message, 'WhatsApp', Colors.green, _whatsAppAdmin),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildContactButton(Icons.facebook, 'Facebook', const Color(0xFF1877F2), _openFacebook),
                  _buildContactButton(Icons.camera_alt, 'Instagram', const Color(0xFFE4405F), _openInstagram),
                ],
              ),
              const SizedBox(height: 40),
              OutlinedButton.icon(
                onPressed: () => _checkStatus(context),
                icon: const Icon(Icons.refresh),
                label: const Text('Vérifier le statut'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => _logout(context),
                child: const Text('Se déconnecter', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
