import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/design_system/theme/app_colors.dart';
import '../../../../core/design_system/theme/app_typography.dart';
import '../../../../core/design_system/theme/app_spacing.dart';
import '../../../../core/design_system/theme/app_shadows.dart';

/// Écran Support Client V2
class SupportScreenV2 extends StatelessWidget {
  const SupportScreenV2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Support & Aide', style: AppTypography.titleMedium),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.clientGradient,
                borderRadius: AppSpacing.borderRadiusLg,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.support_agent, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Besoin d\'aide?',
                          style: AppTypography.titleLarge.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Notre équipe est là pour vous aider',
                          style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Contact rapide
            Text('Contact rapide', style: AppTypography.titleMedium),
            const SizedBox(height: 12),
            _buildContactCard(
              icon: Icons.phone,
              title: 'Appeler le support',
              subtitle: '+213 555 123 456',
              color: AppColors.success,
              onTap: () => _makePhoneCall(context, '+213555123456'),
            ),
            const SizedBox(height: 12),
            _buildContactCard(
              icon: Icons.email,
              title: 'Envoyer un email',
              subtitle: 'support@dzdelivery.com',
              color: AppColors.info,
              onTap: () => _sendEmail(context, 'support@dzdelivery.com'),
            ),
            const SizedBox(height: 12),
            _buildContactCard(
              icon: Icons.chat_bubble,
              title: 'Chat en direct',
              subtitle: 'Disponible 24h/7j',
              color: AppColors.clientPrimary,
              onTap: () => _openLiveChat(context),
            ),
            const SizedBox(height: 24),
            
            // FAQ
            Text('Questions fréquentes', style: AppTypography.titleMedium),
            const SizedBox(height: 12),
            _buildFAQItem(
              'Comment suivre ma commande?',
              'Vous pouvez suivre votre commande en temps réel depuis l\'écran "Mes commandes".',
            ),
            _buildFAQItem(
              'Comment annuler une commande?',
              'Vous pouvez annuler votre commande avant qu\'elle ne soit préparée depuis l\'écran de suivi.',
            ),
            _buildFAQItem(
              'Problème avec ma livraison?',
              'Contactez directement votre livreur via le chat ou appelez le support.',
            ),
            _buildFAQItem(
              'Comment utiliser un code promo?',
              'Entrez votre code promo dans le panier avant de finaliser votre commande.',
            ),
            const SizedBox(height: 24),
            
            // Signaler un problème
            Text('Signaler un problème', style: AppTypography.titleMedium),
            const SizedBox(height: 12),
            _buildProblemCard(
              icon: Icons.restaurant,
              title: 'Problème avec le restaurant',
              subtitle: 'Commande incorrecte, retard...',
              onTap: () => _reportProblem(context, 'restaurant'),
            ),
            const SizedBox(height: 12),
            _buildProblemCard(
              icon: Icons.delivery_dining,
              title: 'Problème avec la livraison',
              subtitle: 'Livreur introuvable, retard...',
              onTap: () => _reportProblem(context, 'delivery'),
            ),
            const SizedBox(height: 12),
            _buildProblemCard(
              icon: Icons.payment,
              title: 'Problème de paiement',
              subtitle: 'Facturation, remboursement...',
              onTap: () => _reportProblem(context, 'payment'),
            ),
            const SizedBox(height: 24),
            
            // Informations
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.infoSurface,
                borderRadius: AppSpacing.borderRadiusMd,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.info),
                      const SizedBox(width: 8),
                      Text(
                        'Informations utiles',
                        style: AppTypography.titleSmall.copyWith(color: AppColors.info),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• Support disponible 24h/7j\n'
                    '• Temps de réponse moyen: 2 minutes\n'
                    '• Remboursement sous 24h si problème\n'
                    '• Satisfaction garantie à 100%',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.borderRadiusMd,
          boxShadow: AppShadows.sm,
        ),
        child: Row(
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
                  Text(title, style: AppTypography.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusMd,
        boxShadow: AppShadows.sm,
      ),
      child: ExpansionTile(
        title: Text(question, style: AppTypography.titleSmall),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProblemCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.borderRadiusMd,
          boxShadow: AppShadows.sm,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warningSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.warning, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    HapticFeedback.lightImpact();
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossible de lancer l\'appel')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _sendEmail(BuildContext context, String email) async {
    HapticFeedback.lightImpact();
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Support DZ Delivery&body=Bonjour,\n\nJ\'ai besoin d\'aide concernant...',
    );
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossible d\'ouvrir l\'email')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _openLiveChat(BuildContext context) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chat en direct bientôt disponible'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _reportProblem(BuildContext context, String type) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Signaler un problème'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Décrivez votre problème et nous vous contacterons rapidement.',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Décrivez votre problème...',
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Problème signalé. Nous vous contacterons bientôt.'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.clientPrimary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }
}