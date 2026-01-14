import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/design_system/theme/app_colors.dart';
import '../../../../core/design_system/theme/app_typography.dart';
import '../../../../core/design_system/theme/app_spacing.dart';
import '../../../../core/design_system/theme/app_shadows.dart';
import '../../../../core/services/preferences_service.dart';
import '../../../../main.dart';

/// Écran des paramètres restaurant
/// Mode sombre, notifications, sons, langue
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = PreferencesService.isDarkMode;
  bool _notificationsEnabled = PreferencesService.notificationsEnabled;
  bool _soundEnabled = PreferencesService.soundEnabled;
  bool _hapticEnabled = PreferencesService.hapticEnabled;
  String _language = PreferencesService.language;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('⚙️ Paramètres'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Appearance
            _buildSectionTitle('🎨 Apparence'),
            _buildSettingsCard([
              _buildSwitchTile(
                icon: Icons.dark_mode,
                title: 'Mode sombre',
                subtitle: 'Réduire la fatigue oculaire',
                value: _isDarkMode,
                onChanged: _toggleDarkMode,
              ),
            ]),
            AppSpacing.vLg,

            // Notifications
            _buildSectionTitle('🔔 Notifications'),
            _buildSettingsCard([
              _buildSwitchTile(
                icon: Icons.notifications,
                title: 'Notifications push',
                subtitle: 'Recevoir les alertes de commandes',
                value: _notificationsEnabled,
                onChanged: (value) async {
                  setState(() => _notificationsEnabled = value);
                  await PreferencesService.setNotificationsEnabled(value);
                },
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                icon: Icons.volume_up,
                title: 'Sons',
                subtitle: 'Jouer un son pour les nouvelles commandes',
                value: _soundEnabled,
                onChanged: (value) async {
                  setState(() => _soundEnabled = value);
                  await PreferencesService.setSoundEnabled(value);
                },
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                icon: Icons.vibration,
                title: 'Vibrations',
                subtitle: 'Retour haptique sur les actions',
                value: _hapticEnabled,
                onChanged: (value) async {
                  setState(() => _hapticEnabled = value);
                  await PreferencesService.setHapticEnabled(value);
                  if (value) HapticFeedback.mediumImpact();
                },
              ),
            ]),
            AppSpacing.vLg,

            // Language
            _buildSectionTitle('🌍 Langue'),
            _buildSettingsCard([
              _buildLanguageTile(),
            ]),
            AppSpacing.vLg,

            // About
            _buildSectionTitle('ℹ️ À propos'),
            _buildSettingsCard([
              _buildInfoTile(
                icon: Icons.info,
                title: 'Version',
                value: '2.0.0',
              ),
              const Divider(height: 1),
              _buildActionTile(
                icon: Icons.description,
                title: 'Conditions d\'utilisation',
                onTap: () {},
              ),
              const Divider(height: 1),
              _buildActionTile(
                icon: Icons.privacy_tip,
                title: 'Politique de confidentialité',
                onTap: () {},
              ),
              const Divider(height: 1),
              _buildActionTile(
                icon: Icons.help,
                title: 'Centre d\'aide',
                onTap: () {},
              ),
            ]),
            AppSpacing.vLg,

            // Danger zone
            _buildSectionTitle('⚠️ Zone de danger'),
            _buildSettingsCard([
              _buildActionTile(
                icon: Icons.delete_forever,
                title: 'Supprimer le compte',
                color: AppColors.error,
                onTap: _showDeleteAccountDialog,
              ),
            ]),
            AppSpacing.vXxl,
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: AppTypography.titleMedium),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        boxShadow: AppShadows.sm,
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title, style: AppTypography.bodyMedium),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }

  Widget _buildLanguageTile() {
    final languages = {
      'fr': '🇫🇷 Français',
      'ar': '🇩🇿 العربية',
      'en': '🇬🇧 English',
    };

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.language, color: AppColors.primary, size: 20),
      ),
      title: const Text('Langue de l\'application'),
      subtitle: Text(
        languages[_language] ?? 'Français',
        style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showLanguageDialog(languages),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title, style: AppTypography.bodyMedium),
      trailing: Text(
        value,
        style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    Color? color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (color ?? AppColors.primary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color ?? AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: AppTypography.bodyMedium.copyWith(color: color),
      ),
      trailing: Icon(Icons.chevron_right, color: color ?? AppColors.textTertiary),
      onTap: onTap,
    );
  }

  Future<void> _toggleDarkMode(bool value) async {
    HapticFeedback.selectionClick();
    setState(() => _isDarkMode = value);
    await PreferencesService.setDarkMode(value);
    
    // Update app theme
    DZDeliveryApp.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
  }

  void _showLanguageDialog(Map<String, String> languages) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir la langue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.entries.map((entry) => RadioListTile<String>(
            title: Text(entry.value),
            value: entry.key,
            groupValue: _language,
            onChanged: (value) async {
              if (value != null) {
                Navigator.pop(context);
                setState(() => _language = value);
                await PreferencesService.setLanguage(value);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Langue mise à jour. Redémarrez l\'app pour appliquer.'),
                      backgroundColor: AppColors.info,
                    ),
                  );
                }
              }
            },
            activeColor: AppColors.primary,
          )).toList(),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le compte?'),
        content: const Text(
          'Cette action est irréversible. Toutes vos données seront supprimées définitivement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Delete account logic
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
