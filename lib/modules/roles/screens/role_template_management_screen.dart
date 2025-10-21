import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/role_template_model.dart';
import '../providers/role_template_provider.dart';
import '../../../../theme.dart';

/// Écran de gestion des templates de rôles
class RoleTemplateManagementScreen extends StatefulWidget {
  const RoleTemplateManagementScreen({super.key});

  @override
  State<RoleTemplateManagementScreen> createState() => _RoleTemplateManagementScreenState();
}

class _RoleTemplateManagementScreenState extends State<RoleTemplateManagementScreen>
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RoleTemplateProvider>(context, listen: false).initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllTemplatesTab(),
          _buildCategoriesTab(),
          _buildUsageStatsTab(),
          _buildSettingsTab(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Gestion des Templates'),
      actions: [
        IconButton(
          onPressed: _showSearchDialog,
          icon: const Icon(Icons.search),
          tooltip: 'Rechercher',
        ),
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'refresh',
              child: ListTile(
                leading: Icon(Icons.refresh),
                title: Text('Actualiser'),
              ),
            ),
            const PopupMenuItem(
              value: 'export',
              child: ListTile(
                leading: Icon(Icons.download),
                title: Text('Exporter'),
              ),
            ),
            const PopupMenuItem(
              value: 'import',
              child: ListTile(
                leading: Icon(Icons.upload),
                title: Text('Importer'),
              ),
            ),
            const PopupMenuItem(
              value: 'cleanup',
              child: ListTile(
                leading: Icon(Icons.cleaning_services),
                title: Text('Nettoyage'),
              ),
            ),
          ],
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(icon: Icon(Icons.list), text: 'Templates'),
          Tab(icon: Icon(Icons.category), text: 'Catégories'),
          Tab(icon: Icon(Icons.analytics), text: 'Statistiques'),
          Tab(icon: Icon(Icons.settings), text: 'Paramètres'),
        ],
      ),
    );
  }

  Widget _buildAllTemplatesTab() {
    return Consumer<RoleTemplateProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && !provider.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            _buildFilterSection(provider),
            Expanded(
              child: _buildTemplatesList(provider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterSection(RoleTemplateProvider provider) {
    return Card(
      margin: const EdgeInsets.all(AppTheme.spaceMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Rechercher des templates...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: provider.setSearchQuery,
                  ),
                ),
                const SizedBox(width: AppTheme.space12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: provider.selectedCategory.isEmpty ? null : provider.selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Catégorie',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text('Toutes les catégories'),
                      ),
                      ...TemplateCategory.values.map((category) {
                        return DropdownMenuItem(
                          value: category.id,
                          child: Row(
                            children: [
                              Icon(category.icon, size: 16),
                              const SizedBox(width: AppTheme.spaceSmall),
                              Text(category.displayName),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) => provider.setSelectedCategory(value ?? ''),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space12),
            Row(
              children: [
                FilterChip(
                  label: const Text('Inclure inactifs'),
                  selected: provider.showInactive,
                  onSelected: (_) => provider.toggleShowInactive(),
                ),
                const SizedBox(width: AppTheme.spaceSmall),
                ActionChip(
                  label: const Text('Réinitialiser'),
                  avatar: const Icon(Icons.clear, size: 16),
                  onPressed: () {
                    _searchController.clear();
                    provider.resetFilters();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplatesList(RoleTemplateProvider provider) {
    final templates = provider.templates;

    if (templates.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: AppTheme.grey500),
            SizedBox(height: AppTheme.spaceMedium),
            Text(
              'Aucun template trouvé',
              style: TextStyle(fontSize: AppTheme.fontSize18, color: AppTheme.grey500),
            ),
            Text(
              'Modifiez vos critères de recherche ou créez un nouveau template',
              style: TextStyle(color: AppTheme.grey500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return _buildTemplateCard(template, provider);
      },
    );
  }

  Widget _buildTemplateCard(RoleTemplate template, RoleTemplateProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(AppTheme.spaceSmall),
          decoration: BoxDecoration(
            color: template.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: template.color.withOpacity(0.3)),
          ),
          child: Icon(template.iconData, color: template.color),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                template.name,
                style: const TextStyle(fontWeight: AppTheme.fontBold),
              ),
            ),
            if (template.isSystemTemplate)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.infoColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  border: Border.all(color: AppTheme.infoColor.withOpacity(0.3)),
                ),
                child: const Text(
                  'SYSTÈME',
                  style: TextStyle(fontSize: AppTheme.fontSize10, color: AppTheme.infoColor),
                ),
              ),
            if (!template.isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
                ),
                child: const Text(
                  'INACTIF',
                  style: TextStyle(fontSize: AppTheme.fontSize10, color: AppTheme.errorColor),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(template.description),
            const SizedBox(height: AppTheme.spaceXSmall),
            Row(
              children: [
                Icon(
                  TemplateCategory.fromId(template.category).icon,
                  size: 14,
                  color: AppTheme.grey600,
                ),
                const SizedBox(width: AppTheme.spaceXSmall),
                Text(
                  TemplateCategory.fromId(template.category).displayName,
                  style: TextStyle(
                    fontSize: AppTheme.fontSize12,
                    color: AppTheme.grey600,
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMedium),
                Icon(
                  Icons.security,
                  size: 14,
                  color: AppTheme.grey600,
                ),
                const SizedBox(width: AppTheme.spaceXSmall),
                Text(
                  '${template.permissionIds.length} permissions',
                  style: TextStyle(
                    fontSize: AppTheme.fontSize12,
                    color: AppTheme.grey600,
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informations détaillées
                _buildTemplateDetails(template),
                
                const SizedBox(height: AppTheme.spaceMedium),
                
                // Actions
                _buildTemplateActions(template, provider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateDetails(RoleTemplate template) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Détails',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: AppTheme.fontBold,
          ),
        ),
        const SizedBox(height: AppTheme.spaceSmall),
        
        // Permissions
        if (template.permissionIds.isNotEmpty) ...[
          Text(
            'Permissions (${template.permissionIds.length}):',
            style: const TextStyle(fontWeight: AppTheme.fontMedium),
          ),
          const SizedBox(height: AppTheme.spaceXSmall),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: template.permissionIds.take(10).map((permission) {
              return Chip(
                label: Text(permission),
                labelStyle: const TextStyle(fontSize: AppTheme.fontSize12),
              );
            }).toList(),
          ),
          if (template.permissionIds.length > 10)
            Text(
              '... et ${template.permissionIds.length - 10} autres',
              style: TextStyle(
                fontSize: AppTheme.fontSize12,
                color: AppTheme.grey600,
              ),
            ),
        ],
        
        const SizedBox(height: AppTheme.space12),
        
        // Configuration
        if (template.configuration.isNotEmpty) ...[
          Text(
            'Configuration:',
            style: const TextStyle(fontWeight: AppTheme.fontMedium),
          ),
          const SizedBox(height: AppTheme.spaceXSmall),
          ...template.configuration.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                '• ${entry.key}: ${entry.value}',
                style: const TextStyle(fontSize: AppTheme.fontSize12),
              ),
            );
          }).toList(),
        ],
      ],
    );
  }

  Widget _buildTemplateActions(RoleTemplate template, RoleTemplateProvider provider) {
    return Row(
      children: [
        // Créer un rôle
        ElevatedButton.icon(
          onPressed: () => _createRoleFromTemplate(template, provider),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Créer rôle'),
        ),
        
        const SizedBox(width: AppTheme.spaceSmall),
        
        // Dupliquer
        OutlinedButton.icon(
          onPressed: () => _duplicateTemplate(template, provider),
          icon: const Icon(Icons.content_copy, size: 16),
          label: const Text('Dupliquer'),
        ),
        
        const Spacer(),
        
        // Actions avancées
        PopupMenuButton<String>(
          onSelected: (action) => _handleTemplateAction(action, template, provider),
          itemBuilder: (context) => [
            if (template.isEditable) ...[
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Modifier'),
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: AppTheme.errorColor),
                  title: Text('Supprimer', style: TextStyle(color: AppTheme.errorColor)),
                ),
              ),
            ],
            const PopupMenuItem(
              value: 'export',
              child: ListTile(
                leading: Icon(Icons.download),
                title: Text('Exporter'),
              ),
            ),
            const PopupMenuItem(
              value: 'validate',
              child: ListTile(
                leading: Icon(Icons.check_circle),
                title: Text('Valider'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoriesTab() {
    return Consumer<RoleTemplateProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && !provider.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = provider.categoryStats;
        
        return ListView(
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
          children: TemplateCategory.values.map((category) {
            final count = stats[category.id] ?? 0;
            final templates = provider.getTemplatesByCategory(category.id);
            
            return Card(
              child: ExpansionTile(
                leading: Icon(category.icon, color: AppTheme.blueStandard),
                title: Text(category.displayName),
                subtitle: Text('$count template(s)'),
                children: [
                  if (templates.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(AppTheme.spaceMedium),
                      child: Text(
                        'Aucun template dans cette catégorie',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    )
                  else
                    ...templates.map((template) {
                      return ListTile(
                        leading: Icon(template.iconData, color: template.color),
                        title: Text(template.name),
                        subtitle: Text('${template.permissionIds.length} permissions'),
                        trailing: template.isSystemTemplate 
                            ? const Icon(Icons.lock, size: 16)
                            : null,
                        onTap: () => _showTemplateDetails(template),
                      );
                    }).toList(),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildUsageStatsTab() {
    return Consumer<RoleTemplateProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && !provider.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vue d'ensemble
              _buildStatsOverview(provider),
              
              const SizedBox(height: AppTheme.spaceMedium),
              
              // Templates les plus utilisés
              _buildMostUsedTemplates(provider),
              
              const SizedBox(height: AppTheme.spaceMedium),
              
              // Recommandations
              _buildRecommendations(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsOverview(RoleTemplateProvider provider) {
    final stats = provider.usageStats;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vue d\'Ensemble',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: AppTheme.fontBold,
              ),
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Templates',
                    '${stats['totalTemplates'] ?? 0}',
                    Icons.list_alt,
                    AppTheme.blueStandard,
                  ),
                ),
                const SizedBox(width: AppTheme.space12),
                Expanded(
                  child: _buildStatCard(
                    'Actifs',
                    '${stats['activeTemplates'] ?? 0}',
                    Icons.check_circle,
                    AppTheme.greenStandard,
                  ),
                ),
                const SizedBox(width: AppTheme.space12),
                Expanded(
                  child: _buildStatCard(
                    'Système',
                    '${stats['systemTemplates'] ?? 0}',
                    Icons.lock,
                    AppTheme.orangeStandard,
                  ),
                ),
                const SizedBox(width: AppTheme.space12),
                Expanded(
                  child: _buildStatCard(
                    'Personnalisés',
                    '${stats['customTemplates'] ?? 0}',
                    Icons.edit,
                    AppTheme.pinkStandard,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: AppTheme.spaceSmall),
          Text(
            value,
            style: TextStyle(
              fontSize: AppTheme.fontSize24,
              fontWeight: AppTheme.fontBold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: AppTheme.fontSize12,
              color: AppTheme.grey500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMostUsedTemplates(RoleTemplateProvider provider) {
    final mostUsed = provider.mostUsedTemplates;
    
    if (mostUsed.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppTheme.spaceMedium),
          child: Text('Aucune donnée d\'utilisation disponible'),
        ),
      );
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Templates les Plus Utilisés',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: AppTheme.fontBold,
              ),
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            
            ...mostUsed.map((entry) {
              final template = provider.getTemplate(entry.key);
              if (template == null) return const SizedBox.shrink();
              
              return ListTile(
                leading: Icon(template.iconData, color: template.color),
                title: Text(template.name),
                subtitle: Text(template.description),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.blueStandard.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  ),
                  child: Text(
                    '${entry.value} rôles',
                    style: TextStyle(
                      color: AppTheme.blueStandard,
                      fontWeight: AppTheme.fontBold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations(RoleTemplateProvider provider) {
    final recommendations = provider.optimizationRecommendations;
    
    if (recommendations.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
          child: Column(
            children: [
              Icon(Icons.check_circle, color: AppTheme.greenStandard, size: 48),
              const SizedBox(height: AppTheme.spaceSmall),
              const Text(
                'Aucune recommandation',
                style: TextStyle(fontWeight: AppTheme.fontBold),
              ),
              const Text('Vos templates sont bien optimisés !'),
            ],
          ),
        ),
      );
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recommandations',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: AppTheme.fontBold,
              ),
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            
            ...recommendations.map((rec) {
              Color color;
              IconData icon;
              
              switch (rec['severity']) {
                case 'error':
                  color = AppTheme.errorColor;
                  icon = Icons.error;
                  break;
                case 'warning':
                  color = AppTheme.warning;
                  icon = Icons.warning;
                  break;
                default:
                  color = AppTheme.infoColor;
                  icon = Icons.info;
              }
              
              return ListTile(
                leading: Icon(icon, color: color),
                title: Text(rec['title']),
                subtitle: Text(rec['description']),
                trailing: rec['count'] != null 
                    ? Chip(
                        label: Text('${rec['count']}'),
                        backgroundColor: color.withOpacity(0.1),
                      )
                    : null,
                onTap: () => _handleRecommendation(rec),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTab() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Paramètres des Templates',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: AppTheme.fontBold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceMedium),
                  
                  ListTile(
                    title: const Text('Initialiser les templates système'),
                    subtitle: const Text('Recréer tous les templates système par défaut'),
                    trailing: const Icon(Icons.refresh),
                    onTap: _initializeSystemTemplates,
                  ),
                  
                  const Divider(),
                  
                  ListTile(
                    title: const Text('Nettoyer les templates obsolètes'),
                    subtitle: const Text('Supprimer les templates inactifs et inutilisés'),
                    trailing: const Icon(Icons.cleaning_services),
                    onTap: _cleanupObsoleteTemplates,
                  ),
                  
                  const Divider(),
                  
                  ListTile(
                    title: const Text('Exporter tous les templates'),
                    subtitle: const Text('Télécharger un fichier JSON avec tous les templates'),
                    trailing: const Icon(Icons.download),
                    onTap: _exportAllTemplates,
                  ),
                  
                  const Divider(),
                  
                  ListTile(
                    title: const Text('Importer des templates'),
                    subtitle: const Text('Charger des templates depuis un fichier JSON'),
                    trailing: const Icon(Icons.upload),
                    onTap: _importTemplates,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    if (_tabController.index == 0) {
      return FloatingActionButton.extended(
        onPressed: _createNewTemplate,
        icon: const Icon(Icons.add),
        label: const Text('Nouveau Template'),
      );
    }
    return null;
  }

  // Actions et méthodes

  void _handleMenuAction(String action) {
    switch (action) {
      case 'refresh':
        _refresh();
        break;
      case 'export':
        _exportAllTemplates();
        break;
      case 'import':
        _importTemplates();
        break;
      case 'cleanup':
        _cleanupObsoleteTemplates();
        break;
    }
  }

  void _handleTemplateAction(String action, RoleTemplate template, RoleTemplateProvider provider) {
    switch (action) {
      case 'edit':
        _editTemplate(template);
        break;
      case 'delete':
        _deleteTemplate(template, provider);
        break;
      case 'export':
        _exportTemplate(template);
        break;
      case 'validate':
        _validateTemplate(template, provider);
        break;
    }
  }

  Future<void> _refresh() async {
    final provider = Provider.of<RoleTemplateProvider>(context, listen: false);
    try {
      await provider.refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Données actualisées')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recherche Avancée'),
        content: const Text('Fonctionnalité de recherche avancée à implémenter'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _createNewTemplate() {
    // TODO: Implémenter la création de template
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Création de template à implémenter')),
    );
  }

  void _createRoleFromTemplate(RoleTemplate template, RoleTemplateProvider provider) {
    // TODO: Implémenter la création de rôle à partir du template
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Création de rôle à partir de "${template.name}" à implémenter')),
    );
  }

  void _duplicateTemplate(RoleTemplate template, RoleTemplateProvider provider) {
    // TODO: Implémenter la duplication de template
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Duplication de "${template.name}" à implémenter')),
    );
  }

  void _editTemplate(RoleTemplate template) {
    // TODO: Implémenter l'édition de template
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Édition de "${template.name}" à implémenter')),
    );
  }

  void _deleteTemplate(RoleTemplate template, RoleTemplateProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer le template "${template.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await provider.deleteTemplate(template.id, 'current_user_id');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Template supprimé')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e')),
                  );
                }
              }
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _exportTemplate(RoleTemplate template) {
    // TODO: Implémenter l'export d'un template
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Export de "${template.name}" à implémenter')),
    );
  }

  void _validateTemplate(RoleTemplate template, RoleTemplateProvider provider) async {
    try {
      final validation = await provider.validateTemplate(template.id);
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Résultat de la Validation'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        validation['isValid'] ? Icons.check_circle : Icons.error,
                        color: validation['isValid'] ? AppTheme.successColor : AppTheme.errorColor,
                      ),
                      const SizedBox(width: AppTheme.spaceSmall),
                      Text(
                        validation['isValid'] ? 'Valide' : 'Invalide',
                        style: TextStyle(
                          fontWeight: AppTheme.fontBold,
                          color: validation['isValid'] ? AppTheme.successColor : AppTheme.errorColor,
                        ),
                      ),
                    ],
                  ),
                  
                  if (validation['errors']?.isNotEmpty == true) ...[
                    const SizedBox(height: AppTheme.spaceMedium),
                    const Text('Erreurs:', style: TextStyle(fontWeight: AppTheme.fontBold)),
                    ...validation['errors'].map<Widget>((error) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text('• $error', style: const TextStyle(color: AppTheme.errorColor)),
                      );
                    }).toList(),
                  ],
                  
                  if (validation['warnings']?.isNotEmpty == true) ...[
                    const SizedBox(height: AppTheme.spaceMedium),
                    const Text('Avertissements:', style: TextStyle(fontWeight: AppTheme.fontBold)),
                    ...validation['warnings'].map<Widget>((warning) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text('• $warning', style: const TextStyle(color: AppTheme.warning)),
                      );
                    }).toList(),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la validation: $e')),
        );
      }
    }
  }

  void _showTemplateDetails(RoleTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(template.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(template.description),
              const SizedBox(height: AppTheme.spaceMedium),
              Text('Catégorie: ${TemplateCategory.fromId(template.category).displayName}'),
              Text('Permissions: ${template.permissionIds.length}'),
              Text('Type: ${template.isSystemTemplate ? 'Système' : 'Personnalisé'}'),
              Text('Statut: ${template.isActive ? 'Actif' : 'Inactif'}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _handleRecommendation(Map<String, dynamic> recommendation) {
    // TODO: Implémenter le traitement des recommandations
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Traitement de "${recommendation['title']}" à implémenter')),
    );
  }

  void _initializeSystemTemplates() async {
    try {
      final provider = Provider.of<RoleTemplateProvider>(context, listen: false);
      await provider.initialize();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Templates système initialisés')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _cleanupObsoleteTemplates() async {
    try {
      final provider = Provider.of<RoleTemplateProvider>(context, listen: false);
      final count = await provider.cleanupObsoleteTemplates();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$count templates nettoyés')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _exportAllTemplates() {
    // TODO: Implémenter l'export de tous les templates
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export de tous les templates à implémenter')),
    );
  }

  void _importTemplates() {
    // TODO: Implémenter l'import de templates
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Import de templates à implémenter')),
    );
  }
}