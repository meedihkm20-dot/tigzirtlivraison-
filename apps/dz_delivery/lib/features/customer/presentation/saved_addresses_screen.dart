import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/theme/app_theme.dart';

class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  List<Map<String, dynamic>> _addresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() => _isLoading = true);
    try {
      final addresses = await SupabaseService.getSavedAddresses();
      setState(() {
        _addresses = addresses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddAddressDialog() {
    final labelController = TextEditingController();
    final addressController = TextEditingController();
    final instructionsController = TextEditingController();
    double? lat, lng;
    bool isDefault = _addresses.isEmpty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Nouvelle adresse', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Labels prédéfinis
                Wrap(
                  spacing: 8,
                  children: ['🏠 Maison', '🏢 Travail', '👨‍👩‍👧 Famille', '🏋️ Sport'].map((label) {
                    final isSelected = labelController.text == label;
                    return ChoiceChip(
                      label: Text(label),
                      selected: isSelected,
                      onSelected: (selected) {
                        setModalState(() => labelController.text = selected ? label : '');
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                
                TextField(
                  controller: labelController,
                  decoration: const InputDecoration(
                    labelText: 'Nom de l\'adresse',
                    hintText: 'Ex: Maison, Bureau...',
                    prefixIcon: Icon(Icons.label),
                  ),
                ),
                const SizedBox(height: 12),
                
                TextField(
                  controller: addressController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Adresse complète',
                    hintText: 'Rue, numéro, quartier, ville...',
                    prefixIcon: const Icon(Icons.location_on),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.my_location, color: AppTheme.primaryColor),
                      onPressed: () async {
                        final position = await LocationService.getCurrentLocation();
                        if (position != null) {
                          setModalState(() {
                            lat = position.latitude;
                            lng = position.longitude;
                            addressController.text = 'Position actuelle (${lat!.toStringAsFixed(4)}, ${lng!.toStringAsFixed(4)})';
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                TextField(
                  controller: instructionsController,
                  decoration: const InputDecoration(
                    labelText: 'Instructions (optionnel)',
                    hintText: 'Ex: 2ème étage, code porte 1234...',
                    prefixIcon: Icon(Icons.info_outline),
                  ),
                ),
                const SizedBox(height: 12),
                
                CheckboxListTile(
                  value: isDefault,
                  onChanged: (v) => setModalState(() => isDefault = v ?? false),
                  title: const Text('Définir comme adresse par défaut'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (labelController.text.isEmpty || addressController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Veuillez remplir tous les champs'), backgroundColor: Colors.red),
                        );
                        return;
                      }
                      
                      // Si pas de coordonnées, utiliser position actuelle
                      if (lat == null || lng == null) {
                        final position = await LocationService.getCurrentLocation();
                        lat = position?.latitude ?? 36.7538;
                        lng = position?.longitude ?? 3.0588;
                      }
                      
                      await SupabaseService.addSavedAddress(
                        label: labelController.text,
                        address: addressController.text,
                        latitude: lat!,
                        longitude: lng!,
                        instructions: instructionsController.text.isEmpty ? null : instructionsController.text,
                        isDefault: isDefault,
                      );
                      
                      Navigator.pop(context);
                      _loadAddresses();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Adresse ajoutée!'), backgroundColor: Colors.green),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                    child: const Text('Enregistrer'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getLabelIcon(String label) {
    if (label.contains('Maison') || label.contains('🏠')) return Icons.home;
    if (label.contains('Travail') || label.contains('🏢')) return Icons.work;
    if (label.contains('Famille') || label.contains('👨')) return Icons.family_restroom;
    if (label.contains('Sport') || label.contains('🏋')) return Icons.fitness_center;
    return Icons.location_on;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Adresses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddAddressDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _addresses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('Aucune adresse enregistrée', style: TextStyle(color: Colors.grey[600], fontSize: 18)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _showAddAddressDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter une adresse'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAddresses,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _addresses.length,
                    itemBuilder: (context, index) {
                      final address = _addresses[index];
                      final isDefault = address['is_default'] == true;
                      
                      return Dismissible(
                        key: Key(address['id']),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) async {
                          await SupabaseService.deleteSavedAddress(address['id']);
                          _loadAddresses();
                        },
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isDefault 
                                  ? AppTheme.primaryColor.withOpacity(0.1)
                                  : Colors.grey[100],
                              child: Icon(
                                _getLabelIcon(address['label'] ?? ''),
                                color: isDefault ? AppTheme.primaryColor : Colors.grey,
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  address['label'] ?? 'Adresse',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                if (isDefault) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Par défaut',
                                      style: TextStyle(color: Colors.white, fontSize: 10),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(address['address'] ?? ''),
                                if (address['instructions'] != null)
                                  Text(
                                    address['instructions'],
                                    style: TextStyle(color: Colors.grey[500], fontSize: 12, fontStyle: FontStyle.italic),
                                  ),
                              ],
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              // Retourner l'adresse sélectionnée
                              Navigator.pop(context, address);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: _addresses.isNotEmpty
          ? FloatingActionButton(
              onPressed: _showAddAddressDialog,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
