import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/design_system/theme/app_colors.dart';
import '../../../../core/design_system/theme/app_typography.dart';
import '../../../../core/design_system/theme/app_spacing.dart';
import '../../../../core/design_system/theme/app_shadows.dart';

/// Écran de gestion d'équipe
/// Membres, rôles, permissions, planning
class TeamManagementScreen extends StatefulWidget {
  const TeamManagementScreen({super.key});

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<_TeamMember> _members = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      final members = [
        _TeamMember(
          id: '1',
          name: 'Mohamed Amrani',
          email: 'mohamed@restaurant.dz',
          phone: '+213 555 000 001',
          role: _TeamRole.owner,
          avatar: null,
          isActive: true,
          joinedAt: DateTime(2024, 1, 15),
          lastActive: DateTime.now(),
        ),
        _TeamMember(
          id: '2',
          name: 'Karim Benali',
          email: 'karim@restaurant.dz',
          phone: '+213 555 000 002',
          role: _TeamRole.manager,
          avatar: null,
          isActive: true,
          joinedAt: DateTime(2024, 3, 1),
          lastActive: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        _TeamMember(
          id: '3',
          name: 'Fatima Hadj',
          email: 'fatima@restaurant.dz',
          phone: '+213 555 000 003',
          role: _TeamRole.chef,
          avatar: null,
          isActive: true,
          joinedAt: DateTime(2024, 5, 10),
          lastActive: DateTime.now().subtract(const Duration(minutes: 30)),
        ),
        _TeamMember(
          id: '4',
          name: 'Ahmed Kaci',
          email: 'ahmed@restaurant.dz',
          phone: '+213 555 000 004',
          role: _TeamRole.staff,
          avatar: null,
          isActive: false,
          joinedAt: DateTime(2024, 8, 20),
          lastActive: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ];

      if (mounted) {
        setState(() => _members = members);
      }
    } catch (e) {
      debugPrint('Erreur chargement équipe: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('👥 Mon équipe'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _showInviteMemberDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textTertiary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Membres'),
            Tab(text: 'Rôles'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMembersTab(),
                _buildRolesTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showInviteMemberDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Inviter'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  // ============================================
  // TAB 1: MEMBRES
  // ============================================
  Widget _buildMembersTab() {
    final activeMembers = _members.where((m) => m.isActive).toList();
    final inactiveMembers = _members.where((m) => !m.isActive).toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.screen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats
            _buildTeamStats(),
            AppSpacing.vLg,
            
            // Active members
            Text(
              '🟢 Membres actifs (${activeMembers.length})',
              style: AppTypography.titleMedium,
            ),
            AppSpacing.vMd,
            ...activeMembers.map((m) => _buildMemberCard(m)),
            
            if (inactiveMembers.isNotEmpty) ...[
              AppSpacing.vLg,
              Text(
                '⚪ Membres inactifs (${inactiveMembers.length})',
                style: AppTypography.titleMedium,
              ),
              AppSpacing.vMd,
              ...inactiveMembers.map((m) => _buildMemberCard(m)),
            ],
            
            AppSpacing.vXxl,
          ],
        ),
      ),
    );
  }

  Widget _buildTeamStats() {
    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: AppSpacing.borderRadiusLg,
        boxShadow: AppShadows.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('${_members.length}', 'Total'),
          Container(width: 1, height: 40, color: Colors.white24),
          _buildStatItem('${_members.where((m) => m.isActive).length}', 'Actifs'),
          Container(width: 1, height: 40, color: Colors.white24),
          _buildStatItem('${_members.where((m) => m.role == _TeamRole.chef).length}', 'Cuisiniers'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.headlineMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildMemberCard(_TeamMember member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        boxShadow: AppShadows.sm,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showMemberDetails(member),
          borderRadius: AppSpacing.borderRadiusLg,
          child: Padding(
            padding: AppSpacing.card,
            child: Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: member.role.color.withOpacity(0.2),
                      backgroundImage: member.avatar != null
                          ? NetworkImage(member.avatar!)
                          : null,
                      child: member.avatar == null
                          ? Text(
                              member.initials,
                              style: AppTypography.titleMedium.copyWith(
                                color: member.role.color,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: member.isActive ? AppColors.success : AppColors.textTertiary,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.surface, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            member.name,
                            style: AppTypography.titleSmall,
                          ),
                          if (member.role == _TeamRole.owner) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.warningSurface,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '👑 Propriétaire',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.warning,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: member.role.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              member.role.label,
                              style: AppTypography.labelSmall.copyWith(
                                color: member.role.color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            member.lastActiveText,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Actions
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppColors.textTertiary),
                  onSelected: (value) => _handleMemberAction(value, member),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, size: 18),
                          SizedBox(width: 8),
                          Text('Voir le profil'),
                        ],
                      ),
                    ),
                    if (member.role != _TeamRole.owner) ...[
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Modifier le rôle'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: member.isActive ? 'deactivate' : 'activate',
                        child: Row(
                          children: [
                            Icon(
                              member.isActive ? Icons.block : Icons.check_circle,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(member.isActive ? 'Désactiver' : 'Activer'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'remove',
                        child: Row(
                          children: [
                            Icon(Icons.person_remove, size: 18, color: AppColors.error),
                            SizedBox(width: 8),
                            Text('Retirer', style: TextStyle(color: AppColors.error)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  // ============================================
  // TAB 2: RÔLES & PERMISSIONS
  // ============================================
  Widget _buildRolesTab() {
    return SingleChildScrollView(
      padding: AppSpacing.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rôles disponibles',
            style: AppTypography.titleMedium,
          ),
          AppSpacing.vMd,
          ..._TeamRole.values.map((role) => _buildRoleCard(role)),
          AppSpacing.vXxl,
        ],
      ),
    );
  }

  Widget _buildRoleCard(_TeamRole role) {
    final membersWithRole = _members.where((m) => m.role == role).length;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        boxShadow: AppShadows.sm,
        border: Border.all(color: role.color.withOpacity(0.3)),
      ),
      child: ExpansionTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: role.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(role.icon, color: role.color),
        ),
        title: Row(
          children: [
            Text(role.label, style: AppTypography.titleSmall),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$membersWithRole',
                style: AppTypography.labelSmall,
              ),
            ),
          ],
        ),
        subtitle: Text(
          role.description,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Permissions',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                AppSpacing.vSm,
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: role.permissions.map((p) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.successSurface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check, size: 14, color: AppColors.success),
                        const SizedBox(width: 4),
                        Text(
                          p,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // DIALOGS & ACTIONS
  // ============================================
  void _showInviteMemberDialog() {
    final emailController = TextEditingController();
    _TeamRole selectedRole = _TeamRole.staff;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppSpacing.borderRadiusTopXl,
          ),
          child: Padding(
            padding: AppSpacing.screen,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.outline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                AppSpacing.vLg,
                Text(
                  'Inviter un membre',
                  style: AppTypography.headlineSmall,
                ),
                AppSpacing.vSm,
                Text(
                  'Envoyez une invitation par email',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                AppSpacing.vLg,
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Adresse email',
                    prefixIcon: Icon(Icons.email),
                    hintText: 'exemple@email.com',
                  ),
                ),
                AppSpacing.vMd,
                Text(
                  'Rôle',
                  style: AppTypography.labelMedium,
                ),
                AppSpacing.vSm,
                Wrap(
                  spacing: 8,
                  children: _TeamRole.values
                      .where((r) => r != _TeamRole.owner)
                      .map((role) => ChoiceChip(
                            label: Text(role.label),
                            selected: selectedRole == role,
                            onSelected: (selected) {
                              if (selected) {
                                setModalState(() => selectedRole = role);
                              }
                            },
                            selectedColor: role.color.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: selectedRole == role ? role.color : AppColors.textSecondary,
                            ),
                          ))
                      .toList(),
                ),
                AppSpacing.vLg,
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('📧 Invitation envoyée!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        },
                        child: const Text('Envoyer'),
                      ),
                    ),
                  ],
                ),
                AppSpacing.vLg,
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMemberDetails(_TeamMember member) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.borderRadiusTopXl,
        ),
        child: Padding(
          padding: AppSpacing.screen,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              AppSpacing.vLg,
              CircleAvatar(
                radius: 40,
                backgroundColor: member.role.color.withOpacity(0.2),
                child: Text(
                  member.initials,
                  style: AppTypography.headlineMedium.copyWith(
                    color: member.role.color,
                  ),
                ),
              ),
              AppSpacing.vMd,
              Text(member.name, style: AppTypography.headlineSmall),
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: member.role.color.withOpacity(0.1),
                  borderRadius: AppSpacing.borderRadiusRound,
                ),
                child: Text(
                  member.role.label,
                  style: AppTypography.labelMedium.copyWith(
                    color: member.role.color,
                  ),
                ),
              ),
              AppSpacing.vLg,
              _buildDetailRow(Icons.email, member.email),
              _buildDetailRow(Icons.phone, member.phone),
              _buildDetailRow(Icons.calendar_today, 'Membre depuis ${_formatDate(member.joinedAt)}'),
              _buildDetailRow(
                Icons.access_time,
                'Dernière activité: ${member.lastActiveText}',
              ),
              AppSpacing.vLg,
              if (member.role != _TeamRole.owner)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showEditRoleDialog(member);
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Modifier'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          // Call member
                        },
                        icon: const Icon(Icons.phone),
                        label: const Text('Appeler'),
                      ),
                    ),
                  ],
                ),
              AppSpacing.vLg,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textTertiary),
          const SizedBox(width: 12),
          Text(text, style: AppTypography.bodyMedium),
        ],
      ),
    );
  }

  void _showEditRoleDialog(_TeamMember member) {
    _TeamRole selectedRole = member.role;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Modifier le rôle de ${member.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _TeamRole.values
                .where((r) => r != _TeamRole.owner)
                .map((role) => RadioListTile<_TeamRole>(
                      title: Text(role.label),
                      subtitle: Text(role.description),
                      value: role,
                      groupValue: selectedRole,
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedRole = value);
                        }
                      },
                      activeColor: role.color,
                    ))
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Rôle mis à jour'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMemberAction(String action, _TeamMember member) {
    switch (action) {
      case 'view':
        _showMemberDetails(member);
        break;
      case 'edit':
        _showEditRoleDialog(member);
        break;
      case 'activate':
      case 'deactivate':
        setState(() {
          final index = _members.indexWhere((m) => m.id == member.id);
          if (index != -1) {
            _members[index] = _TeamMember(
              id: member.id,
              name: member.name,
              email: member.email,
              phone: member.phone,
              role: member.role,
              avatar: member.avatar,
              isActive: !member.isActive,
              joinedAt: member.joinedAt,
              lastActive: member.lastActive,
            );
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(member.isActive ? 'Membre désactivé' : 'Membre activé'),
            backgroundColor: AppColors.success,
          ),
        );
        break;
      case 'remove':
        _confirmRemoveMember(member);
        break;
    }
  }

  void _confirmRemoveMember(_TeamMember member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer ce membre?'),
        content: Text('Voulez-vous vraiment retirer ${member.name} de l\'équipe?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _members.removeWhere((m) => m.id == member.id);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Membre retiré'),
                  backgroundColor: AppColors.warning,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
    return '${months[date.month - 1]} ${date.year}';
  }
}

// ============================================
// DATA MODELS
// ============================================
enum _TeamRole {
  owner,
  manager,
  chef,
  staff;

  String get label {
    switch (this) {
      case _TeamRole.owner: return 'Propriétaire';
      case _TeamRole.manager: return 'Manager';
      case _TeamRole.chef: return 'Cuisinier';
      case _TeamRole.staff: return 'Employé';
    }
  }

  String get description {
    switch (this) {
      case _TeamRole.owner: return 'Accès complet à toutes les fonctionnalités';
      case _TeamRole.manager: return 'Gestion des commandes, menu et équipe';
      case _TeamRole.chef: return 'Gestion de la cuisine et des commandes';
      case _TeamRole.staff: return 'Accès limité aux commandes';
    }
  }

  Color get color {
    switch (this) {
      case _TeamRole.owner: return AppColors.warning;
      case _TeamRole.manager: return AppColors.info;
      case _TeamRole.chef: return AppColors.success;
      case _TeamRole.staff: return AppColors.secondary;
    }
  }

  IconData get icon {
    switch (this) {
      case _TeamRole.owner: return Icons.star;
      case _TeamRole.manager: return Icons.manage_accounts;
      case _TeamRole.chef: return Icons.restaurant;
      case _TeamRole.staff: return Icons.person;
    }
  }

  List<String> get permissions {
    switch (this) {
      case _TeamRole.owner:
        return ['Tout', 'Facturation', 'Équipe', 'Paramètres', 'Rapports'];
      case _TeamRole.manager:
        return ['Commandes', 'Menu', 'Promos', 'Équipe', 'Stats'];
      case _TeamRole.chef:
        return ['Cuisine', 'Commandes', 'Menu', 'Stocks'];
      case _TeamRole.staff:
        return ['Commandes', 'Cuisine'];
    }
  }
}

class _TeamMember {
  final String id;
  final String name;
  final String email;
  final String phone;
  final _TeamRole role;
  final String? avatar;
  final bool isActive;
  final DateTime joinedAt;
  final DateTime lastActive;

  _TeamMember({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.avatar,
    required this.isActive,
    required this.joinedAt,
    required this.lastActive,
  });

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }

  String get lastActiveText {
    final diff = DateTime.now().difference(lastActive);
    if (diff.inMinutes < 5) return 'En ligne';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return 'Il y a ${diff.inDays} jour${diff.inDays > 1 ? 's' : ''}';
  }
}
