import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, dynamic> _settings = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final settings = await SupabaseService.getPlatformSettings();
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSetting(String key, dynamic value, String label) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B2838),
        title: const Text('Confirmer la modification', style: TextStyle(color: Colors.white)),
        content: Text(
          'Voulez-vous modifier "$label" ?\n\nNouvelle valeur: $value',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await SupabaseService.updatePlatformSetting(key, value, reason: 'Modification manuelle');
        _loadSettings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Paramètre mis à jour'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showEditDialog(String key, String label, String currentValue, {bool isNumber = false, bool isBoolean = false}) {
    if (isBoolean) {
      final newValue = currentValue != 'true';
      _updateSetting(key, newValue.toString(), label);
      return;
    }

    final controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B2838),
        title: Text('Modifier $label', style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: 'Nouvelle valeur',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF0D1B2A),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _updateSetting(key, controller.text, label);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        title: const Text('Paramètres Plateforme', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : RefreshIndicator(
              onRefresh: _loadSettings,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Système
                  _SectionHeader(title: '⚙️ Système', color: Colors.blue),
                  _SettingTile(
                    icon: Icons.build,
                    label: 'Mode maintenance',
                    value: _settings['maintenance_mode'] ?? 'false',
                    isBoolean: true,
                    onTap: () => _showEditDialog('maintenance_mode', 'Mode maintenance', _settings['maintenance_mode'] ?? 'false', isBoolean: true),
                  ),
                  _SettingTile(
                    icon: Icons.person_add,
                    label: 'Inscriptions activées',
                    value: _settings['new_registrations_enabled'] ?? 'true',
                    isBoolean: true,
                    onTap: () => _showEditDialog('new_registrations_enabled', 'Inscriptions', _settings['new_registrations_enabled'] ?? 'true', isBoolean: true),
                  ),
                  const SizedBox(height: 24),

                  // Finance
                  _SectionHeader(title: '💰 Finance', color: Colors.green),
                  _SettingTile(
                    icon: Icons.percent,
                    label: 'Commission admin',
                    value: '${_settings['admin_commission_percent'] ?? '5'}%',
                    onTap: () => _showEditDialog('admin_commission_percent', 'Commission admin (%)', _settings['admin_commission_percent'] ?? '5', isNumber: true),
                  ),
                  _SettingTile(
                    icon: Icons.local_shipping,
                    label: 'Frais livraison minimum',
                    value: '${_settings['min_delivery_fee'] ?? '100'} DA',
                    onTap: () => _showEditDialog('min_delivery_fee', 'Frais livraison min (DA)', _settings['min_delivery_fee'] ?? '100', isNumber: true),
                  ),
                  _SettingTile(
                    icon: Icons.shopping_cart,
                    label: 'Montant minimum commande',
                    value: '${_settings['min_order_amount'] ?? '200'} DA',
                    onTap: () => _showEditDialog('min_order_amount', 'Montant min commande (DA)', _settings['min_order_amount'] ?? '200', isNumber: true),
                  ),
                  const SizedBox(height: 24),

                  // Livraison
                  _SectionHeader(title: '🚚 Livraison', color: Colors.orange),
                  _SettingTile(
                    icon: Icons.map,
                    label: 'Rayon de livraison max',
                    value: '${_settings['max_delivery_radius_km'] ?? '15'} km',
                    onTap: () => _showEditDialog('max_delivery_radius_km', 'Rayon max (km)', _settings['max_delivery_radius_km'] ?? '15', isNumber: true),
                  ),
                  _SettingTile(
                    icon: Icons.timer,
                    label: 'Timeout commande',
                    value: '${_settings['order_timeout_minutes'] ?? '30'} min',
                    onTap: () => _showEditDialog('order_timeout_minutes', 'Timeout (min)', _settings['order_timeout_minutes'] ?? '30', isNumber: true),
                  ),
                  const SizedBox(height: 24),

                  // Limites
                  _SectionHeader(title: '🛡️ Limites', color: Colors.red),
                  _SettingTile(
                    icon: Icons.speed,
                    label: 'Max commandes/heure/client',
                    value: _settings['max_orders_per_hour'] ?? '5',
                    onTap: () => _showEditDialog('max_orders_per_hour', 'Max commandes/heure', _settings['max_orders_per_hour'] ?? '5', isNumber: true),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;

  const _SectionHeader({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isBoolean;
  final VoidCallback onTap;

  const _SettingTile({
    required this.icon,
    required this.label,
    required this.value,
    this.isBoolean = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final boolValue = value == 'true';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2838),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white54),
        title: Text(label, style: const TextStyle(color: Colors.white)),
        trailing: isBoolean
            ? Switch(
                value: boolValue,
                onChanged: (_) => onTap(),
                activeColor: Colors.green,
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(value, style: const TextStyle(color: Colors.white70)),
                  const SizedBox(width: 8),
                  const Icon(Icons.edit, color: Colors.white38, size: 18),
                ],
              ),
        onTap: isBoolean ? null : onTap,
      ),
    );
  }
}
