import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/firebase_auth_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import 'phone_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedRole = 'customer';
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _phoneVerified = false;

  // Champs communs
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();

  // Champs restaurant
  final _restaurantNameController = TextEditingController();
  final _addressController = TextEditingController();

  // Champs livreur
  String _vehicleType = 'moto';

  Future<void> _verifyPhone() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _errorMessage = 'Entrez votre numéro de téléphone');
      return;
    }

    if (!FirebaseAuthService.isValidAlgerianPhone(phone)) {
      setState(() => _errorMessage = 'Numéro algérien invalide (ex: 0555123456)');
      return;
    }

    setState(() => _errorMessage = null);

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PhoneVerificationScreen(
          phoneNumber: phone,
          onVerified: () => Navigator.pop(context, true),
        ),
      ),
    );

    if (result == true) {
      setState(() => _phoneVerified = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Numéro vérifié avec succès!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    // Pour les clients, vérifier que le téléphone est vérifié
    if (_selectedRole == 'customer' && !_phoneVerified) {
      setState(() => _errorMessage = 'Veuillez d\'abord vérifier votre numéro de téléphone');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      switch (_selectedRole) {
        case 'customer':
          await SupabaseService.signUpCustomer(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _fullNameController.text.trim(),
            phone: _phoneController.text.trim(),
            phoneVerified: true, // Téléphone vérifié via Firebase
          );
          if (mounted) {
            // Afficher message de vérification email
            _showEmailVerificationDialog();
          }
          break;

        case 'restaurant':
          await SupabaseService.signUpRestaurant(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            ownerName: _fullNameController.text.trim(),
            restaurantName: _restaurantNameController.text.trim(),
            phone: _phoneController.text.trim(),
            address: _addressController.text.trim(),
          );
          if (mounted) Navigator.pushReplacementNamed(context, AppRouter.pendingApproval, arguments: 'restaurant');
          break;

        case 'livreur':
          await SupabaseService.signUpLivreur(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _fullNameController.text.trim(),
            phone: _phoneController.text.trim(),
            vehicleType: _vehicleType,
          );
          if (mounted) Navigator.pushReplacementNamed(context, AppRouter.pendingApproval, arguments: 'livreur');
          break;
      }
    } catch (e) {
      setState(() => _errorMessage = 'Erreur lors de l\'inscription: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showEmailVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.email_outlined, color: AppTheme.primaryColor),
            SizedBox(width: 12),
            Text('Vérifiez votre email'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Un email de confirmation a été envoyé à:'),
            const SizedBox(height: 8),
            Text(
              _emailController.text.trim(),
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 16),
            const Text('Cliquez sur le lien dans l\'email pour activer votre compte.'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacementNamed(context, AppRouter.login);
            },
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inscription')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Je suis un...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildRoleChip('customer', 'Client', Icons.person),
                  const SizedBox(width: 8),
                  _buildRoleChip('restaurant', 'Restaurant', Icons.restaurant),
                  const SizedBox(width: 8),
                  _buildRoleChip('livreur', 'Livreur', Icons.delivery_dining),
                ],
              ),
              const SizedBox(height: 24),
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_errorMessage!, style: const TextStyle(color: AppTheme.errorColor)),
                ),
              // Champs communs
              TextFormField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  labelText: _selectedRole == 'restaurant' ? 'Nom du propriétaire' : 'Nom complet',
                  prefixIcon: const Icon(Icons.person_outlined),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Champ requis';
                  if (!v.contains('@')) return 'Email invalide';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Téléphone avec bouton de vérification (pour clients)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      enabled: !_phoneVerified,
                      decoration: InputDecoration(
                        labelText: 'Téléphone',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        hintText: '0555123456',
                        suffixIcon: _phoneVerified
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : null,
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                      onChanged: (_) {
                        if (_phoneVerified) {
                          setState(() => _phoneVerified = false);
                        }
                      },
                    ),
                  ),
                  if (_selectedRole == 'customer' && !_phoneVerified) ...[
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: ElevatedButton(
                        onPressed: _verifyPhone,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        child: const Text('Vérifier'),
                      ),
                    ),
                  ],
                ],
              ),
              // Info vérification pour clients
              if (_selectedRole == 'customer') ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _phoneVerified 
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _phoneVerified ? Icons.verified : Icons.info_outline,
                        color: _phoneVerified ? Colors.green : Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _phoneVerified
                              ? 'Numéro vérifié ✓'
                              : 'Vérification SMS requise pour les clients',
                          style: TextStyle(
                            color: _phoneVerified ? Colors.green[700] : Colors.orange[700],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) => v == null || v.length < 6 ? 'Minimum 6 caractères' : null,
              ),
              // Champs restaurant
              if (_selectedRole == 'restaurant') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _restaurantNameController,
                  decoration: const InputDecoration(labelText: 'Nom du restaurant', prefixIcon: Icon(Icons.store_outlined)),
                  validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Adresse', prefixIcon: Icon(Icons.location_on_outlined)),
                  validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                ),
              ],
              // Champs livreur
              if (_selectedRole == 'livreur') ...[
                const SizedBox(height: 16),
                const Text('Type de véhicule', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildVehicleChip('moto', 'Moto', Icons.two_wheeler),
                    const SizedBox(width: 8),
                    _buildVehicleChip('velo', 'Vélo', Icons.pedal_bike),
                    const SizedBox(width: 8),
                    _buildVehicleChip('voiture', 'Voiture', Icons.directions_car),
                  ],
                ),
              ],
              const SizedBox(height: 32),
              // Info validation
              if (_selectedRole != 'customer')
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Votre compte sera validé par l\'administrateur avant activation.',
                          style: TextStyle(color: Colors.blue[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('S\'inscrire', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Déjà un compte ?', style: TextStyle(color: Colors.grey[600])),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Se connecter'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleChip(String role, String label, IconData icon) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedRole = role;
          _phoneVerified = false; // Reset phone verification when changing role
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.grey[600], size: 28),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleChip(String type, String label, IconData icon) {
    final isSelected = _vehicleType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _vehicleType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.secondaryColor : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.grey[600]),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[600], fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _restaurantNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
