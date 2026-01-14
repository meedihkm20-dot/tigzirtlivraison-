import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/supabase_service.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;
  String _selectedEntity = '';

  final List<Map<String, String>> _entityFilters = [
    {'value': '', 'label': 'Tous'},
    {'value': 'restaurant', 'label': 'Restaurants'},
    {'value': 'livreur', 'label': 'Livreurs'},
    {'value': 'order', 'label': 'Commandes'},
    {'value': 'incident', 'label': 'Incidents'},
    {'value': 'settings', 'label': 'Paramètres'},
  ];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    try {
      final logs = await SupabaseService.getAuditLogs(
        entityType: _selectedEntity.isEmpty ? null : _selectedEntity,
      );
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        title: const Text('Audit Logs', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Filtres
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _entityFilters.length,
              itemBuilder: (context, index) {
                final filter = _entityFilters[index];
                final isSelected = _selectedEntity == filter['value'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter['label']!),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedEntity = filter['value']!);
                      _loadLogs();
                    },
                    backgroundColor: const Color(0xFF1B2838),
                    selectedColor: Colors.blue.withOpacity(0.3),
                    labelStyle: TextStyle(color: isSelected ? Colors.blue : Colors.white70, fontSize: 12),
                    side: BorderSide(color: isSelected ? Colors.blue : Colors.transparent),
                  ),
                );
              },
            ),
          ),
          // Liste
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : _logs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, size: 64, color: Colors.white24),
                            const SizedBox(height: 16),
                            const Text('Aucun log', style: TextStyle(color: Colors.white54)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadLogs,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _logs.length,
                          itemBuilder: (context, index) => _LogCard(log: _logs[index]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  final Map<String, dynamic> log;

  const _LogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final action = log['action'] as String? ?? '';
    final entityType = log['entity_type'] as String? ?? '';
    final adminName = log['admin']?['full_name'] ?? 'Admin';
    final actionInfo = _getActionInfo(action);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2838),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: actionInfo['color'].withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(actionInfo['icon'], color: actionInfo['color'], size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  actionInfo['label'],
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Par $adminName • ${_getEntityLabel(entityType)}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                if (log['reason'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Raison: ${log['reason']}',
                    style: const TextStyle(color: Colors.white38, fontSize: 11, fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
          Text(
            _formatDate(log['created_at']),
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getActionInfo(String action) {
    switch (action) {
      case 'verify_restaurant':
        return {'label': 'Restaurant validé', 'icon': Icons.verified, 'color': Colors.green};
      case 'verify_livreur':
        return {'label': 'Livreur validé', 'icon': Icons.verified, 'color': Colors.green};
      case 'suspend_restaurant':
        return {'label': 'Restaurant suspendu', 'icon': Icons.block, 'color': Colors.red};
      case 'suspend_livreur':
        return {'label': 'Livreur suspendu', 'icon': Icons.block, 'color': Colors.red};
      case 'enable_restaurant':
        return {'label': 'Restaurant activé', 'icon': Icons.check_circle, 'color': Colors.green};
      case 'disable_restaurant':
        return {'label': 'Restaurant désactivé', 'icon': Icons.cancel, 'color': Colors.orange};
      case 'force_order_status':
        return {'label': 'Statut forcé', 'icon': Icons.edit, 'color': Colors.blue};
      case 'admin_cancel_order':
        return {'label': 'Commande annulée', 'icon': Icons.cancel, 'color': Colors.red};
      case 'reassign_livreur':
        return {'label': 'Livreur réassigné', 'icon': Icons.swap_horiz, 'color': Colors.purple};
      case 'create_incident':
        return {'label': 'Incident créé', 'icon': Icons.report_problem, 'color': Colors.orange};
      case 'update_incident':
        return {'label': 'Incident mis à jour', 'icon': Icons.update, 'color': Colors.blue};
      case 'update_setting':
        return {'label': 'Paramètre modifié', 'icon': Icons.settings, 'color': Colors.purple};
      default:
        return {'label': action, 'icon': Icons.info, 'color': Colors.grey};
    }
  }

  String _getEntityLabel(String entityType) {
    switch (entityType) {
      case 'restaurant': return 'Restaurant';
      case 'livreur': return 'Livreur';
      case 'order': return 'Commande';
      case 'incident': return 'Incident';
      case 'settings': return 'Paramètres';
      default: return entityType;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.parse(dateStr);
    return DateFormat('dd/MM HH:mm').format(date);
  }
}
