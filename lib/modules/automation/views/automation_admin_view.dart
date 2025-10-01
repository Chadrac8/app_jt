import 'package:flutter/material.dart';
import '../models/automation.dart';
import '../models/automation_execution.dart';
import '../models/automation_template.dart';
import '../services/automation_service.dart';
import '../../../../theme.dart';
import '../../../widgets/custom_card.dart';
import '../../../theme.dart';

/// Vue admin pour la gestion des automatisations
class AutomationAdminView extends StatefulWidget {
  const AutomationAdminView({Key? key}) : super(key: key);

  @override
  State<AutomationAdminView> createState() => _AutomationAdminViewState();
}

class _AutomationAdminViewState extends State<AutomationAdminView> with TickerProviderStateMixin {
  final AutomationService _automationService = AutomationService();
  late TabController _tabController;
  
  List<Automation> _automations = [];
  List<AutomationExecution> _executions = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  String _searchQuery = '';
  AutomationStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
      final futures = await Future.wait([
        _automationService.getAll(),
        _automationService.executionService.getRecentExecutions(limit: 100),
        _automationService.getAutomationStats(),
      ]);
      
      setState(() {
        _automations = futures[0] as List<Automation>;
        _executions = futures[1] as List<AutomationExecution>;
        _stats = futures[2] as Map<String, dynamic>;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: AppTheme.redStandard,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Automation> get _filteredAutomations {
    var filtered = _automations;
    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((automation) =>
        automation.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        automation.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        automation.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()))
      ).toList();
    }
    
    if (_filterStatus != null) {
      filtered = filtered.where((automation) => automation.status == _filterStatus).toList();
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(),
              _buildAutomationsTab(),
              _buildExecutionsTab(),
              _buildTemplatesTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppTheme.white100,
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Vue d\'ensemble', icon: Icon(Icons.dashboard)),
          Tab(text: 'Automatisations', icon: Icon(Icons.auto_awesome)),
          Tab(text: 'Exécutions', icon: Icon(Icons.history)),
          Tab(text: 'Templates', icon: Icon(Icons.folder_copy_outlined)),
        ],
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: AppTheme.grey500,
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsGrid(),
          const SizedBox(height: AppTheme.space20),
          _buildRecentActivity(),
          const SizedBox(height: AppTheme.space20),
          _buildPopularTemplates(),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Total Automatisations',
          '${_stats['total'] ?? 0}',
          Icons.auto_awesome,
          AppTheme.blueStandard,
        ),
        _buildStatCard(
          'Automatisations Actives',
          '${_stats['active'] ?? 0}',
          Icons.play_circle_filled,
          AppTheme.greenStandard,
        ),
        _buildStatCard(
          'Exécutions Totales',
          '${_stats['totalExecutions'] ?? 0}',
          Icons.play_arrow,
          AppTheme.orangeStandard,
        ),
        _buildStatCard(
          'Taux de Succès Moyen',
          '${(_stats['averageSuccessRate'] ?? 0.0).toStringAsFixed(1)}%',
          Icons.trending_up,
          AppTheme.primaryColor,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: AppTheme.spaceSmall),
            Text(
              value,
              style: const TextStyle(
                fontSize: AppTheme.fontSize24,
                fontWeight: AppTheme.fontBold,
              ),
            ),
            const SizedBox(height: AppTheme.spaceXSmall),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.grey600,
                fontSize: AppTheme.fontSize12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    final recentFailures = _executions
        .where((e) => e.status == ExecutionStatus.failed)
        .take(5)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Activité Récente',
          style: TextStyle(fontSize: AppTheme.fontSize18, fontWeight: AppTheme.fontBold),
        ),
        const SizedBox(height: AppTheme.space12),
        if (recentFailures.isNotEmpty) ...[
          const Text(
            'Échecs Récents à Examiner:',
            style: TextStyle(fontSize: AppTheme.fontSize14, fontWeight: AppTheme.fontMedium, color: AppTheme.redStandard),
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          ...recentFailures.map((execution) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.error, color: AppTheme.redStandard),
              title: Text(execution.automationName),
              subtitle: Text(execution.error ?? 'Erreur inconnue'),
              trailing: Text(_formatDateTime(execution.triggeredAt)),
              onTap: () => _showExecutionDetails(execution),
            ),
          )),
        ] else ...[
          const Card(
            child: ListTile(
              leading: Icon(Icons.check_circle, color: AppTheme.greenStandard),
              title: Text('Aucun échec récent'),
              subtitle: Text('Toutes les automatisations fonctionnent correctement'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPopularTemplates() {
    final popularTemplates = AutomationTemplates.popular.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Templates Populaires',
              style: TextStyle(fontSize: AppTheme.fontSize18, fontWeight: AppTheme.fontBold),
            ),
            TextButton(
              onPressed: () => _tabController.animateTo(3),
              child: const Text('Voir tous'),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space12),
        ...popularTemplates.map((template) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Icon(
                Icons.auto_awesome,
                color: Theme.of(context).primaryColor,
              ),
            ),
            title: Text(template.name),
            subtitle: Text('${template.usageCount} utilisations'),
            trailing: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _createFromTemplate(template),
              tooltip: 'Créer à partir de ce template',
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildAutomationsTab() {
    return Column(
      children: [
        _buildAutomationsHeader(),
        Expanded(
          child: _filteredAutomations.isEmpty
              ? _buildEmptyAutomations()
              : ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.spaceMedium),
                  itemCount: _filteredAutomations.length,
                  itemBuilder: (context, index) {
                    final automation = _filteredAutomations[index];
                    return _buildAutomationCard(automation);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAutomationsHeader() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      color: AppTheme.grey50,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher une automatisation...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              DropdownButtonHideUnderline(
                child: DropdownButton<AutomationStatus?>(
                  value: _filterStatus,
                  hint: const Text('Statut'),
                  items: [
                    const DropdownMenuItem<AutomationStatus?>(
                      value: null,
                      child: Text('Tous'),
                    ),
                    ...AutomationStatus.values.map((status) => 
                      DropdownMenuItem<AutomationStatus?>(
                        value: status,
                        child: Text(status.label),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _filterStatus = value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Text(
            '${_filteredAutomations.length} automatisation(s) trouvée(s)',
            style: TextStyle(color: AppTheme.grey600),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAutomations() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 64,
            color: AppTheme.grey400,
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          Text(
            _searchQuery.isEmpty 
                ? 'Aucune automatisation créée'
                : 'Aucun résultat pour "$_searchQuery"',
            style: TextStyle(
              color: AppTheme.grey600,
              fontSize: AppTheme.fontSize16,
            ),
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          ElevatedButton.icon(
            onPressed: _showCreateAutomationDialog,
            icon: const Icon(Icons.add),
            label: const Text('Créer une automatisation'),
          ),
        ],
      ),
    );
  }

  Widget _buildAutomationCard(Automation automation) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        automation.name,
                        style: const TextStyle(
                          fontWeight: AppTheme.fontBold,
                          fontSize: AppTheme.fontSize16,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceXSmall),
                      Text(
                        automation.description,
                        style: TextStyle(
                          color: AppTheme.grey600,
                          fontSize: AppTheme.fontSize14,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(automation.status),
                PopupMenuButton<String>(
                  onSelected: (action) => _handleAutomationAction(action, automation),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: const [
                          Icon(Icons.visibility),
                          SizedBox(width: AppTheme.spaceSmall),
                          Text('Voir détails'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: const [
                          Icon(Icons.edit),
                          SizedBox(width: AppTheme.spaceSmall),
                          Text('Modifier'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: automation.isActive ? 'deactivate' : 'activate',
                      child: Row(
                        children: [
                          Icon(automation.isActive ? Icons.pause : Icons.play_arrow),
                          const SizedBox(width: AppTheme.spaceSmall),
                          Text(automation.isActive ? 'Désactiver' : 'Activer'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'trigger',
                      child: Row(
                        children: const [
                          Icon(Icons.play_circle_filled),
                          SizedBox(width: AppTheme.spaceSmall),
                          Text('Déclencher'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: const [
                          Icon(Icons.delete, color: AppTheme.redStandard),
                          SizedBox(width: AppTheme.spaceSmall),
                          Text('Supprimer', style: TextStyle(color: AppTheme.redStandard)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space12),
            Row(
              children: [
                _buildInfoChip(
                  Icons.flash_on,
                  automation.trigger.label,
                  AppTheme.blueStandard,
                ),
                const SizedBox(width: AppTheme.spaceSmall),
                _buildInfoChip(
                  Icons.settings,
                  '${automation.actions.length} actions',
                  AppTheme.greenStandard,
                ),
                const SizedBox(width: AppTheme.spaceSmall),
                _buildInfoChip(
                  Icons.bar_chart,
                  '${automation.successRate.toStringAsFixed(0)}% succès',
                  AppTheme.orangeStandard,
                ),
              ],
            ),
            if (automation.tags.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spaceSmall),
              Wrap(
                spacing: 6,
                children: automation.tags.take(3).map((tag) =>
                  Chip(
                    label: Text(tag, style: const TextStyle(fontSize: AppTheme.fontSize10)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ).toList(),
              ),
            ],
            const SizedBox(height: AppTheme.spaceSmall),
            Row(
              children: [
                Text(
                  '${automation.executionCount} exécutions',
                  style: TextStyle(color: AppTheme.grey600, fontSize: AppTheme.fontSize12),
                ),
                const SizedBox(width: AppTheme.spaceMedium),
                if (automation.lastExecutedAt != null)
                  Text(
                    'Dernière: ${_formatDateTime(automation.lastExecutedAt!)}',
                    style: TextStyle(color: AppTheme.grey600, fontSize: AppTheme.fontSize12),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(AutomationStatus status) {
    Color color;
    switch (status) {
      case AutomationStatus.active:
        color = AppTheme.greenStandard;
        break;
      case AutomationStatus.inactive:
        color = AppTheme.grey500;
        break;
      case AutomationStatus.draft:
        color = AppTheme.orangeStandard;
        break;
      case AutomationStatus.error:
        color = AppTheme.redStandard;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Text(
        status.label,
        style: const TextStyle(
          color: AppTheme.white100,
          fontSize: AppTheme.fontSize12,
          fontWeight: AppTheme.fontMedium,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: AppTheme.spaceXSmall),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: AppTheme.fontSize11,
              fontWeight: AppTheme.fontMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutionsTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
          color: AppTheme.grey50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_executions.length} exécutions',
                style: const TextStyle(fontWeight: AppTheme.fontMedium),
              ),
              TextButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Actualiser'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            itemCount: _executions.length,
            itemBuilder: (context, index) {
              final execution = _executions[index];
              return _buildExecutionCard(execution);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExecutionCard(AutomationExecution execution) {
    final statusColor = _getExecutionStatusColor(execution.status);
    
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: statusColor,
            shape: BoxShape.circle,
          ),
        ),
        title: Text(execution.automationName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(execution.statusMessage),
            Text(
              'Déclenchée: ${_formatDateTime(execution.triggeredAt)}',
              style: const TextStyle(fontSize: AppTheme.fontSize11),
            ),
          ],
        ),
        trailing: Text(
          execution.isManual ? 'Manuel' : 'Auto',
          style: TextStyle(
            fontSize: AppTheme.fontSize11,
            color: AppTheme.grey600,
          ),
        ),
        onTap: () => _showExecutionDetails(execution),
      ),
    );
  }

  Widget _buildTemplatesTab() {
    final categories = AutomationTemplates.categories;

    return DefaultTabController(
      length: categories.length,
      child: Column(
        children: [
          Container(
            color: AppTheme.grey50,
            child: TabBar(
              isScrollable: true,
              tabs: categories.map((category) => 
                Tab(text: category.label)
              ).toList(),
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: AppTheme.grey500,
            ),
          ),
          Expanded(
            child: TabBarView(
              children: categories.map((category) => 
                _buildTemplateCategory(category)
              ).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCategory(TemplateCategory category) {
    final templates = AutomationTemplates.getByCategory(category);

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return _buildTemplateCard(template);
      },
    );
  }

  Widget _buildTemplateCard(AutomationTemplate template) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: AppTheme.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.name,
                        style: const TextStyle(
                          fontWeight: AppTheme.fontBold,
                          fontSize: AppTheme.fontSize16,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceXSmall),
                      Text(
                        template.description,
                        style: TextStyle(
                          color: AppTheme.grey600,
                          fontSize: AppTheme.fontSize14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (template.isPopular)
                  const Icon(Icons.star, color: AppTheme.orangeStandard, size: 20),
                const SizedBox(width: AppTheme.spaceSmall),
                ElevatedButton(
                  onPressed: () => _createFromTemplate(template),
                  child: const Text('Utiliser'),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space12),
            Wrap(
              spacing: 6,
              children: [
                Chip(
                  label: Text(template.trigger.label),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                Chip(
                  label: Text('${template.actions.length} actions'),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                Chip(
                  label: Text('${template.usageCount} utilisations'),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getExecutionStatusColor(ExecutionStatus status) {
    switch (status) {
      case ExecutionStatus.completed:
        return AppTheme.greenStandard;
      case ExecutionStatus.failed:
        return AppTheme.redStandard;
      case ExecutionStatus.running:
        return AppTheme.blueStandard;
      case ExecutionStatus.pending:
        return AppTheme.orangeStandard;
      case ExecutionStatus.cancelled:
        return AppTheme.grey500;
      case ExecutionStatus.skipped:
        return Colors.yellow[700]!;
    }
  }

  void _showCreateAutomationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Créer une Automatisation'),
        content: const Text('Choisissez votre méthode de création:'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushNamed(context, '/automation/form');
            },
            child: const Text('Créer manuellement'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _tabController.animateTo(3); // Aller aux templates
            },
            child: const Text('Utiliser un template'),
          ),
        ],
      ),
    );
  }

  void _createFromTemplate(AutomationTemplate template) async {
    try {
      final automationId = await _automationService.createFromTemplate(
        template.id, 
        'admin_user' // TODO: Remplacer par l'ID utilisateur actuel
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Automatisation "${template.name}" créée avec succès!'),
            backgroundColor: AppTheme.greenStandard,
          ),
        );
        _loadData();
        _tabController.animateTo(1); // Retourner aux automatisations
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la création: $e'),
            backgroundColor: AppTheme.redStandard,
          ),
        );
      }
    }
  }

  void _handleAutomationAction(String action, Automation automation) async {
    try {
      switch (action) {
        case 'view':
          _showAutomationDetails(automation);
          break;
        case 'edit':
          Navigator.pushNamed(
            context, 
            '/automation/edit', 
            arguments: automation
          );
          break;
        case 'activate':
          await _automationService.activateAutomation(automation.id!);
          _showSuccess('Automatisation activée');
          _loadData();
          break;
        case 'deactivate':
          await _automationService.deactivateAutomation(automation.id!);
          _showSuccess('Automatisation désactivée');
          _loadData();
          break;
        case 'trigger':
          await _automationService.triggerAutomation(
            automation.id!,
            {'trigger_type': 'manual', 'timestamp': DateTime.now().toIso8601String()},
            triggeredBy: 'admin_user'
          );
          _showSuccess('Automatisation déclenchée manuellement');
          _loadData();
          break;
        case 'delete':
          _confirmDeleteAutomation(automation);
          break;
      }
    } catch (e) {
      _showError('Erreur: $e');
    }
  }

  void _confirmDeleteAutomation(Automation automation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer l\'automatisation "${automation.name}" ?\n\n'
          'Cette action est irréversible.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _automationService.delete(automation.id!);
                _showSuccess('Automatisation supprimée');
                _loadData();
              } catch (e) {
                _showError('Erreur lors de la suppression: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.redStandard),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showAutomationDetails(Automation automation) {
    Navigator.pushNamed(
      context, 
      '/automation/detail', 
      arguments: automation
    );
  }

  void _showExecutionDetails(AutomationExecution execution) {
    Navigator.pushNamed(
      context, 
      '/automation/execution', 
      arguments: execution
    );
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.greenStandard,
        ),
      );
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.redStandard,
        ),
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}min';
    } else {
      return 'À l\'instant';
    }
  }
}