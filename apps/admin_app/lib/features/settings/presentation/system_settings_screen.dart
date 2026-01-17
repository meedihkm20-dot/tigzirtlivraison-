import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';

/// Écran Paramètres Système Admin
/// - Finance (commission, frais)
/// - Livraison (zones, tarifs)
/// - Limites (commandes max, distance)
class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _isSaving = false;

  // Finance
  final _commissionController = TextEditingController(text: '10');
  final _serviceFeeController = TextEditingController(text: '50');
  final _minOrderController = TextEditingController(text: '500');

  // Livraison
  final _baseDeliveryFeeController = TextEditingController(text: '150');
  final _perKmFeeController = TextEditingController(text: '30');
  final _maxDeliveryDistanceController = TextEditingController(text: '10');

  // Limites
  final _maxActiveOrdersController = TextEditingController(text: '5');
  final _maxDailyOrdersController = TextEditingController(text: '100');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commissionController.dispose();
    _serviceFeeController.dispose();
    _minOrderController.dispose();
    _baseDeliveryFeeController.dispose();
    _perKmFeeController.dispose();
    _maxDeliveryDistanceController.dispose();
    _maxActiveOrdersController.dispose();
    _maxDailyOrdersController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final settings = await SupabaseService.getSystemSettings();
      if (settings != null) {
        setState(() {
          _commissionController.text = (settings['commission_rate'] ?? 10).toString();
          _serviceFeeController.text = (settings['service_fee'] ?? 50).toString();
          _minOrderController.text = (settings['min_order_amount'] ?? 500).toString();
          _baseDeliveryFeeController.text = (settings['base_delivery_fee'] ?? 150).toString();
          _perKmFeeController.text = (settings['per_km_fee'] ?? 30).toString();
          _maxDeliveryDistanceController.text = (settings['max_delivery_distance'] ?? 10).toString();
          _maxActiveOrdersController.text = (settings['max_active_orders'] ?? 5).toString();
          _maxDailyOrdersController.text = (settings['max_daily_orders'] ?? 100).toString();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      await SupabaseService.updateSystemSettings({
        'commission_rate': double.tryParse(_commissionController.text) ?? 10,
        'service_fee': double.tryParse(_serviceFeeController.text) ?? 50,
        'min_order_amount': double.tryParse(_minOrderController.text) ?? 500,
        'base_delivery_fee': double.tryParse(_baseDeliveryFeeController.text) ?? 150,
        'per_km_fee': double.tryParse(_perKmFeeController.text) ?? 30,
        'max_delivery_distance': double.tryParse(_maxDeliveryDistanceController.text) ?? 10,
        'max_active_orders': int.tryParse(_maxActiveOrdersController.text) ?? 5,
        'max_daily_orders': int.tryParse(_maxDailyOrdersController.text) ?? 100,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paramètres enregistrés'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        title: const Text('Paramètres Système', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveSettings,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Finance'),
            Tab(text: 'Livraison'),
            Tab(text: 'Limites'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFinanceTab(),
                _buildDeliveryTab(),
                _buildLimitsTab(),
              ],
            ),
    );
  }

  Widget _buildFinanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configuration Financière',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          
          _buildTextField(
            controller: _commissionController,
            label: 'Commission Restaurant (%)',
            hint: 'Ex: 10',
            icon: Icons.percent,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _serviceFeeController,
            label: 'Frais de Service (DA)',
            hint: 'Ex: 50',
            icon: Icons.attach_money,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _minOrderController,
            label: 'Montant Minimum Commande (DA)',
            hint: 'Ex: 500',
            icon: Icons.shopping_cart,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1B2838),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Text('Informations', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '• Commission: Pourcentage prélevé sur chaque commande restaurant',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                const Text(
                  '• Frais de service: Montant fixe ajouté à chaque commande',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                const Text(
                  '• Montant minimum: Valeur minimale pour passer une commande',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configuration Livraison',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          
          _buildTextField(
            controller: _baseDeliveryFeeController,
            label: 'Frais de Livraison de Base (DA)',
            hint: 'Ex: 150',
            icon: Icons.local_shipping,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _perKmFeeController,
            label: 'Frais par Kilomètre (DA)',
            hint: 'Ex: 30',
            icon: Icons.route,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _maxDeliveryDistanceController,
            label: 'Distance Maximum Livraison (km)',
            hint: 'Ex: 10',
            icon: Icons.social_distance,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1B2838),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.calculate, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Text('Calcul des Frais', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Frais Total = Base + (Distance × Par Km)',
                  style: TextStyle(color: Colors.green[300], fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Exemple: ${_baseDeliveryFeeController.text} DA + (5 km × ${_perKmFeeController.text} DA) = ${(double.tryParse(_baseDeliveryFeeController.text) ?? 0) + (5 * (double.tryParse(_perKmFeeController.text) ?? 0))} DA',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Limites Système',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          
          _buildTextField(
            controller: _maxActiveOrdersController,
            label: 'Commandes Actives Max par Livreur',
            hint: 'Ex: 5',
            icon: Icons.assignment,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _maxDailyOrdersController,
            label: 'Commandes Max par Jour (Restaurant)',
            hint: 'Ex: 100',
            icon: Icons.today,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1B2838),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Text('Limites de Sécurité', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  '• Commandes actives: Empêche la surcharge des livreurs',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                SizedBox(height: 4),
                Text(
                  '• Commandes journalières: Protège contre les abus',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF1B2838),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
      ),
    );
  }
}
