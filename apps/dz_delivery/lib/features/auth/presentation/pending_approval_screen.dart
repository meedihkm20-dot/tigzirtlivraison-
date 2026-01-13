import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';

class PendingApprovalScreen extends StatelessWidget {
  final String role;
  
  const PendingApprovalScreen({super.key, required this.role});

  static const String adminPhone = '+213556248038';
  static const String adminFacebook = 'mee.di.hkm';
  static const String adminInstagram = 'mee.di.hkm';

  Future<void> _launchWhatsApp() async {
    final url = Uri.parse('https://wa.me/213556248038');
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _launchPhone() async {
    final url = Uri.parse('tel:$adminPhone');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  Future<void> _launchFacebook() async {
    final url = Uri.parse('https://facebook.com/$adminFacebook');
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _launchInstagram() async {
    final url = Uri.parse('https://instagram.com/$adminInstagram');
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final isRestaurant = role == 'restaurant';
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: const Icon(Icons.hourglass_empty, size: 60, color: Colors.orange),
              ),
              const SizedBox(height: 32),
              Text(
                'Inscription en attente',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                isRestaurant
                    ? 'Votre restaurant a été enregistré avec succès. Un administrateur va vérifier vos informations et activer votre compte.'
                    : 'Votre profil livreur a été enregistré avec succès. Un administrateur va vérifier vos informations et activer votre compte.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text('Contactez l\'administrateur', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildContactButton(Icons.phone, 'Appeler', _launchPhone, Colors.blue),
                        _buildContactButton(Icons.message, 'WhatsApp', _launchWhatsApp, Colors.green),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildContactButton(Icons.facebook, 'Facebook', _launchFacebook, const Color(0xFF1877F2)),
                        _buildContactButton(Icons.camera_alt, 'Instagram', _launchInstagram, const Color(0xFFE4405F)),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () async {
                  await SupabaseService.signOut();
                  if (context.mounted) Navigator.pushReplacementNamed(context, AppRouter.login);
                },
                icon: const Icon(Icons.logout),
                label: const Text('Se déconnecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactButton(IconData icon, String label, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }
}
