import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/design_system/theme/app_colors.dart';
import '../../../../core/design_system/theme/app_typography.dart';
import '../../../../core/design_system/theme/app_spacing.dart';
import '../../../../core/design_system/theme/app_shadows.dart';

/// Écran des rapports automatiques
/// Génération de rapports PDF, export Excel
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isLoading = false;
  final List<_Report> _reports = [];
  bool _autoReportsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    
    final reports = [
      _Report(
        id: '1',
        title: 'Rapport journalier',
        subtitle: 'Lundi 13 Janvier 2026',
        type: _ReportType.daily,
        generatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        fileSize: '245 KB',
        status: _ReportStatus.ready,
      ),
      _Report(
        id: '2',
        title: 'Rapport hebdomadaire',
        subtitle: 'Semaine 2 - 2026',
        type: _ReportType.weekly,
        generatedAt: DateTime.now().subtract(const Duration(days: 1)),
        fileSize: '1.2 MB',
        status: _ReportStatus.ready,
      ),
      _Report(
        id: '3',
        title: 'Rapport mensuel',
        subtitle: 'Décembre 2025',
        type: _ReportType.monthly,
        generatedAt: DateTime.now().subtract(const Duration(days: 14)),
        fileSize: '3.8 MB',
        status: _ReportStatus.ready,
      ),
      _Report(
        id: '4',
        title: 'Rapport personnalisé',
        subtitle: '01/01/2026 - 13/01/2026',
        type: _ReportType.custom,
        generatedAt: DateTime.now().subtract(const Duration(hours: 5)),
        fileSize: '890 KB',
        status: _ReportStatus.ready,
      ),
    ];

    if (mounted) {
      setState(() {
        _reports.clear();
        _reports.addAll(reports);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('📄 Rapports'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReports,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: AppSpacing.screen,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick generate
                    _buildQuickGenerate(),
                    AppSpacing.vLg,
                    
                    // Auto reports toggle
                    _buildAutoReportsToggle(),
                    AppSpacing.vLg,
                    
                    // Recent reports
                    _buildRecentReports(),
                    AppSpacing.vXxl,
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showGenerateDialog,
        icon: const Icon(Icons.add),
        label: const Text('Nouveau rapport'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildQuickGenerate() {
    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: AppSpacing.borderRadiusLg,
        boxShadow: AppShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flash_on, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Génération rapide',
                style: AppTypography.titleMedium.copyWith(color: Colors.white),
              ),
            ],
          ),
          AppSpacing.vMd,
          Row(
            children: [
              Expanded(
                child: _buildQuickButton(
                  icon: Icons.today,
                  label: 'Aujourd\'hui',
                  onTap: () => _generateReport(_ReportType.daily),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickButton(
                  icon: Icons.date_range,
                  label: 'Cette semaine',
                  onTap: () => _generateReport(_ReportType.weekly),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickButton(
                  icon: Icons.calendar_month,
                  label: 'Ce mois',
                  onTap: () => _generateReport(_ReportType.monthly),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoReportsToggle() {
    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.infoSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.schedule_send, color: AppColors.info),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rapports automatiques', style: AppTypography.titleSmall),
                Text(
                  'Recevoir les rapports par email',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _autoReportsEnabled,
            onChanged: (value) {
              HapticFeedback.selectionClick();
              setState(() => _autoReportsEnabled = value);
            },
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentReports() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('📋 Rapports récents', style: AppTypography.titleMedium),
            TextButton(
              onPressed: () {
                // Show all reports
              },
              child: const Text('Voir tout'),
            ),
          ],
        ),
        AppSpacing.vMd,
        if (_reports.isEmpty)
          _buildEmptyState()
        else
          ..._reports.map((report) => _buildReportCard(report)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusLg,
      ),
      child: Column(
        children: [
          Icon(
            Icons.description_outlined,
            size: 64,
            color: AppColors.textTertiary,
          ),
          AppSpacing.vMd,
          Text(
            'Aucun rapport',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          AppSpacing.vSm,
          Text(
            'Générez votre premier rapport',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(_Report report) {
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
          onTap: () => _showReportOptions(report),
          borderRadius: AppSpacing.borderRadiusLg,
          child: Padding(
            padding: AppSpacing.card,
            child: Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: report.type.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    report.type.icon,
                    color: report.type.color,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(report.title, style: AppTypography.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        report.subtitle,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            report.generatedAtText,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.storage,
                            size: 12,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            report.fileSize,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Status & Actions
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: report.status.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        report.status.label,
                        style: AppTypography.labelSmall.copyWith(
                          color: report.status.color,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.download, size: 20),
                          onPressed: () => _downloadReport(report),
                          color: AppColors.primary,
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                        ),
                        IconButton(
                          icon: const Icon(Icons.share, size: 20),
                          onPressed: () => _shareReport(report),
                          color: AppColors.textTertiary,
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                        ),
                      ],
                    ),
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
  // DIALOGS & ACTIONS
  // ============================================
  void _showGenerateDialog() {
    _ReportType selectedType = _ReportType.daily;
    DateTime startDate = DateTime.now().subtract(const Duration(days: 7));
    DateTime endDate = DateTime.now();
    final List<String> selectedSections = ['revenue', 'orders', 'items'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppSpacing.borderRadiusTopXl,
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              // Header
              Padding(
                padding: AppSpacing.screenHorizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Générer un rapport', style: AppTypography.headlineSmall),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: AppSpacing.screen,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type selection
                      Text('Type de rapport', style: AppTypography.labelMedium),
                      AppSpacing.vSm,
                      Wrap(
                        spacing: 8,
                        children: _ReportType.values.map((type) => ChoiceChip(
                          label: Text(type.label),
                          selected: selectedType == type,
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() => selectedType = type);
                            }
                          },
                          selectedColor: type.color.withOpacity(0.2),
                        )).toList(),
                      ),
                      AppSpacing.vLg,
                      
                      // Date range (for custom)
                      if (selectedType == _ReportType.custom) ...[
                        Text('Période', style: AppTypography.labelMedium),
                        AppSpacing.vSm,
                        Row(
                          children: [
                            Expanded(
                              child: _buildDateButton(
                                label: 'Du',
                                date: startDate,
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: startDate,
                                    firstDate: DateTime(2024),
                                    lastDate: DateTime.now(),
                                  );
                                  if (date != null) {
                                    setModalState(() => startDate = date);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDateButton(
                                label: 'Au',
                                date: endDate,
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: endDate,
                                    firstDate: startDate,
                                    lastDate: DateTime.now(),
                                  );
                                  if (date != null) {
                                    setModalState(() => endDate = date);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.vLg,
                      ],
                      
                      // Sections
                      Text('Sections à inclure', style: AppTypography.labelMedium),
                      AppSpacing.vSm,
                      _buildSectionCheckbox(
                        'revenue',
                        'Revenus et chiffre d\'affaires',
                        Icons.attach_money,
                        selectedSections,
                        setModalState,
                      ),
                      _buildSectionCheckbox(
                        'orders',
                        'Détail des commandes',
                        Icons.receipt_long,
                        selectedSections,
                        setModalState,
                      ),
                      _buildSectionCheckbox(
                        'items',
                        'Performance des plats',
                        Icons.restaurant_menu,
                        selectedSections,
                        setModalState,
                      ),
                      _buildSectionCheckbox(
                        'customers',
                        'Analyse clients',
                        Icons.people,
                        selectedSections,
                        setModalState,
                      ),
                      _buildSectionCheckbox(
                        'reviews',
                        'Avis et notes',
                        Icons.star,
                        selectedSections,
                        setModalState,
                      ),
                      AppSpacing.vLg,
                      
                      // Format
                      Text('Format d\'export', style: AppTypography.labelMedium),
                      AppSpacing.vSm,
                      Row(
                        children: [
                          _buildFormatChip('PDF', Icons.picture_as_pdf, true),
                          const SizedBox(width: 8),
                          _buildFormatChip('Excel', Icons.table_chart, false),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Generate button
              Padding(
                padding: AppSpacing.screen,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _generateReport(selectedType);
                    },
                    icon: const Icon(Icons.description),
                    label: const Text('Générer le rapport'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateButton({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: AppTypography.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCheckbox(
    String key,
    String label,
    IconData icon,
    List<String> selected,
    StateSetter setModalState,
  ) {
    final isSelected = selected.contains(key);
    return CheckboxListTile(
      value: isSelected,
      onChanged: (value) {
        setModalState(() {
          if (value == true) {
            selected.add(key);
          } else {
            selected.remove(key);
          }
        });
      },
      title: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Text(label, style: AppTypography.bodyMedium),
        ],
      ),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      activeColor: AppColors.primary,
    );
  }

  Widget _buildFormatChip(String label, IconData icon, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primarySurface : AppColors.surfaceVariant,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
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
              Text('Paramètres des rapports', style: AppTypography.headlineSmall),
              AppSpacing.vLg,
              ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Email de réception'),
                subtitle: const Text('restaurant@test.com'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.schedule),
                title: const Text('Fréquence automatique'),
                subtitle: const Text('Quotidien à 23h00'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Langue du rapport'),
                subtitle: const Text('Français'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              AppSpacing.vLg,
            ],
          ),
        ),
      ),
    );
  }

  void _showReportOptions(_Report report) {
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
              Text(report.title, style: AppTypography.headlineSmall),
              Text(
                report.subtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              AppSpacing.vLg,
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text('Aperçu'),
                onTap: () {
                  Navigator.pop(context);
                  // Preview report
                },
              ),
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Télécharger'),
                onTap: () {
                  Navigator.pop(context);
                  _downloadReport(report);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Partager'),
                onTap: () {
                  Navigator.pop(context);
                  _shareReport(report);
                },
              ),
              ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Envoyer par email'),
                onTap: () {
                  Navigator.pop(context);
                  _emailReport(report);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.error),
                title: const Text('Supprimer', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteReport(report);
                },
              ),
              AppSpacing.vLg,
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generateReport(_ReportType type) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text('Génération du rapport ${type.label}...'),
          ],
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Rapport généré avec succès!'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadReports();
    }
  }

  void _downloadReport(_Report report) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📥 Téléchargement de ${report.title}...'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _shareReport(_Report report) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📤 Partage du rapport...'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _emailReport(_Report report) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📧 Rapport envoyé par email!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _deleteReport(_Report report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce rapport?'),
        content: Text('Voulez-vous vraiment supprimer "${report.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _reports.removeWhere((r) => r.id == report.id);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Rapport supprimé'),
                  backgroundColor: AppColors.warning,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

// ============================================
// DATA MODELS
// ============================================
enum _ReportType {
  daily,
  weekly,
  monthly,
  custom;

  String get label {
    switch (this) {
      case _ReportType.daily: return 'Journalier';
      case _ReportType.weekly: return 'Hebdomadaire';
      case _ReportType.monthly: return 'Mensuel';
      case _ReportType.custom: return 'Personnalisé';
    }
  }

  Color get color {
    switch (this) {
      case _ReportType.daily: return AppColors.info;
      case _ReportType.weekly: return AppColors.success;
      case _ReportType.monthly: return AppColors.warning;
      case _ReportType.custom: return AppColors.secondary;
    }
  }

  IconData get icon {
    switch (this) {
      case _ReportType.daily: return Icons.today;
      case _ReportType.weekly: return Icons.date_range;
      case _ReportType.monthly: return Icons.calendar_month;
      case _ReportType.custom: return Icons.tune;
    }
  }
}

enum _ReportStatus {
  generating,
  ready,
  error;

  String get label {
    switch (this) {
      case _ReportStatus.generating: return 'En cours...';
      case _ReportStatus.ready: return 'Prêt';
      case _ReportStatus.error: return 'Erreur';
    }
  }

  Color get color {
    switch (this) {
      case _ReportStatus.generating: return AppColors.info;
      case _ReportStatus.ready: return AppColors.success;
      case _ReportStatus.error: return AppColors.error;
    }
  }
}

class _Report {
  final String id;
  final String title;
  final String subtitle;
  final _ReportType type;
  final DateTime generatedAt;
  final String fileSize;
  final _ReportStatus status;

  _Report({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.generatedAt,
    required this.fileSize,
    required this.status,
  });

  String get generatedAtText {
    final diff = DateTime.now().difference(generatedAt);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return 'Il y a ${diff.inDays} jour${diff.inDays > 1 ? 's' : ''}';
  }
}
