import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/supabase_service.dart';

class IncidentsScreen extends StatefulWidget {
  const IncidentsScreen({super.key});

  @override
  State<IncidentsScreen> createState() => _IncidentsScreenState();
}

class _IncidentsScreenState extends State<IncidentsScreen> {
  List<Map<String, dynamic>> _incidents = [];
  bool _isLoading = true;
  String _selectedStatus = 'open';

  @override
  void initState() {
    super.initState();
    _loadIncidents();
  }

  Future<void> _loadIncidents() async {
    setState(() => _isLoading = true);
    try {
      final incidents = await SupabaseService.getIncidents(
        status: _selectedStatus.isEmpty ? null : _selectedStatus,
      );
      setState(() {
        _incidents = incidents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showCreateIncidentDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreateIncidentSheet(onCreated: _loadIncidents),
    );
  }

  void _showIncidentDetails(Map<String, dynamic> incident) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _IncidentDetailsSheet(
        incident: incident,
        onUpdated: _loadIncidents,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        title: const Text('Gestion Incidents', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateIncidentDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtres
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _FilterChip(label: 'Ouverts', value: 'open', selected: _selectedStatus, onSelected: (v) { setState(() => _selectedStatus = v); _loadIncidents(); }),
                _FilterChip(label: 'En cours', value: 'in_progress', selected: _selectedStatus, onSelected: (v) { setState(() => _selectedStatus = v); _loadIncidents(); }),
                _FilterChip(label: 'Résolus', value: 'resolved', selected: _selectedStatus, onSelected: (v) { setState(() => _selectedStatus = v); _loadIncidents(); }),
                _FilterChip(label: 'Tous', value: '', selected: _selectedStatus, onSelected: (v) { setState(() => _selectedStatus = v); _loadIncidents(); }),
              ],
            ),
          ),
          // Liste
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : _incidents.isEmpty
                    ? _EmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadIncidents,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _incidents.length,
                          itemBuilder: (context, index) => _IncidentCard(
                            incident: _incidents[index],
                            onTap: () => _showIncidentDetails(_incidents[index]),
                          ),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateIncidentDialog,
        backgroundColor: Colors.red,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final Function(String) onSelected;

  const _FilterChip({required this.label, required this.value, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onSelected(value),
        backgroundColor: const Color(0xFF1B2838),
        selectedColor: Colors.red.withOpacity(0.3),
        labelStyle: TextStyle(color: isSelected ? Colors.red : Colors.white70, fontSize: 12),
        side: BorderSide(color: isSelected ? Colors.red : Colors.transparent),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 64, color: Colors.green.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('Aucun incident', style: TextStyle(color: Colors.white54, fontSize: 16)),
        ],
      ),
    );
  }
}

class _IncidentCard extends StatelessWidget {
  final Map<String, dynamic> incident;
  final VoidCallback onTap;

  const _IncidentCard({required this.incident, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final priority = incident['priority'] as String? ?? 'medium';
    final status = incident['status'] as String? ?? 'open';
    final priorityColor = _getPriorityColor(priority);
    final statusInfo = _getStatusInfo(status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1B2838),
          borderRadius: BorderRadius.circular(16),
          border: Border.left(color: priorityColor, width: 4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    priority.toUpperCase(),
                    style: TextStyle(color: priorityColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusInfo['color'].withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusInfo['label'],
                    style: TextStyle(color: statusInfo['color'], fontSize: 10),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(incident['created_at']),
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              incident['title'] ?? 'Sans titre',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
            if (incident['description'] != null) ...[
              const SizedBox(height: 6),
              Text(
                incident['description'],
                style: const TextStyle(color: Colors.white54, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (incident['order'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.receipt, size: 14, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(
                    'Commande #${incident['order']['order_number']}',
                    style: const TextStyle(color: Colors.blue, fontSize: 12),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'critical': return Colors.red;
      case 'high': return Colors.orange;
      case 'medium': return Colors.yellow;
      default: return Colors.green;
    }
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'open': return {'label': 'Ouvert', 'color': Colors.orange};
      case 'in_progress': return {'label': 'En cours', 'color': Colors.blue};
      case 'resolved': return {'label': 'Résolu', 'color': Colors.green};
      case 'closed': return {'label': 'Fermé', 'color': Colors.grey};
      default: return {'label': status, 'color': Colors.grey};
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.parse(dateStr);
    return DateFormat('dd/MM HH:mm').format(date);
  }
}

class _CreateIncidentSheet extends StatefulWidget {
  final VoidCallback onCreated;

  const _CreateIncidentSheet({required this.onCreated});

  @override
  State<_CreateIncidentSheet> createState() => _CreateIncidentSheetState();
}

class _CreateIncidentSheetState extends State<_CreateIncidentSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _type = 'order_issue';
  String _priority = 'medium';
  bool _isLoading = false;

  Future<void> _create() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Titre obligatoire')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await SupabaseService.createIncident(
        title: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        incidentType: _type,
        priority: _priority,
      );
      widget.onCreated();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFF0D1B2A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Créer un incident', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextField(
            controller: _titleController,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Titre *'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Description'),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _type,
                  dropdownColor: const Color(0xFF1B2838),
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Type'),
                  items: const [
                    DropdownMenuItem(value: 'order_issue', child: Text('Problème commande')),
                    DropdownMenuItem(value: 'payment', child: Text('Paiement')),
                    DropdownMenuItem(value: 'livreur_complaint', child: Text('Plainte livreur')),
                    DropdownMenuItem(value: 'restaurant_complaint', child: Text('Plainte restaurant')),
                    DropdownMenuItem(value: 'system', child: Text('Système')),
                  ],
                  onChanged: (v) => setState(() => _type = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _priority,
                  dropdownColor: const Color(0xFF1B2838),
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Priorité'),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Basse')),
                    DropdownMenuItem(value: 'medium', child: Text('Moyenne')),
                    DropdownMenuItem(value: 'high', child: Text('Haute')),
                    DropdownMenuItem(value: 'critical', child: Text('Critique')),
                  ],
                  onChanged: (v) => setState(() => _priority = v!),
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _create,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Créer l\'incident'),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: const Color(0xFF1B2838),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }
}

class _IncidentDetailsSheet extends StatefulWidget {
  final Map<String, dynamic> incident;
  final VoidCallback onUpdated;

  const _IncidentDetailsSheet({required this.incident, required this.onUpdated});

  @override
  State<_IncidentDetailsSheet> createState() => _IncidentDetailsSheetState();
}

class _IncidentDetailsSheetState extends State<_IncidentDetailsSheet> {
  bool _isLoading = false;

  Future<void> _updateStatus(String status, {String? resolution}) async {
    setState(() => _isLoading = true);
    try {
      await SupabaseService.updateIncidentStatus(
        widget.incident['id'],
        status,
        resolution: resolution,
      );
      widget.onUpdated();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> _resolveWithReason() async {
    final controller = TextEditingController();
    final resolution = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B2838),
        title: const Text('Résolution', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'Décrivez la résolution', hintStyle: TextStyle(color: Colors.white38)),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Résoudre'),
          ),
        ],
      ),
    );
    if (resolution != null && resolution.isNotEmpty) {
      _updateStatus('resolved', resolution: resolution);
    }
  }

  @override
  Widget build(BuildContext context) {
    final incident = widget.incident;
    final status = incident['status'] as String? ?? 'open';

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFF0D1B2A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(incident['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (incident['description'] != null)
                  Text(incident['description'], style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 24),
                const Text('Actions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (status == 'open')
                  _ActionButton(label: 'Prendre en charge', icon: Icons.play_arrow, color: Colors.blue, onTap: () => _updateStatus('in_progress')),
                if (status == 'in_progress')
                  _ActionButton(label: 'Marquer résolu', icon: Icons.check, color: Colors.green, onTap: _resolveWithReason),
                if (status == 'resolved')
                  _ActionButton(label: 'Fermer', icon: Icons.close, color: Colors.grey, onTap: () => _updateStatus('closed')),
              ],
            ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: color.withOpacity(0.2),
            foregroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }
}
