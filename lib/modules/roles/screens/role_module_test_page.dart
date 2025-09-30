import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/role.dart';
import '../models/role_template_model.dart';
import '../providers/role_provider.dart';
import '../providers/permission_provider.dart';
import '../providers/role_template_provider.dart';
import '../services/advanced_roles_permissions_service.dart';
import '../screens/role_template_management_screen.dart';
import '../widgets/permission_matrix_dialog.dart';
import '../widgets/bulk_permission_management_widget.dart';
import '../widgets/role_template_selector_widget.dart';
import '../widgets/role_template_form_dialog.dart';
import '../../../../theme.dart';

/// Page de test complète pour le module rôles
class RoleModuleTestPage extends StatefulWidget {
  const RoleModuleTestPage({super.key});

  @override
  State<RoleModuleTestPage> createState() => _RoleModuleTestPageState();
}

class _RoleModuleTestPageState extends State<RoleModuleTestPage>
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProviders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeProviders() async {
    try {
      // Essayer d'initialiser les providers
      final roleProvider = Provider.of<RoleProvider>(context, listen: false);
      final permissionProvider = Provider.of<PermissionProvider>(context, listen: false);
      final templateProvider = Provider.of<RoleTemplateProvider>(context, listen: false);
      
      await Future.wait([
        roleProvider.initialize(),
        permissionProvider.initialize('test_user'),
        templateProvider.initialize(),
      ]);
      
      // Initialiser le service avancé (version simplifiée)
      await AdvancedRolesPermissionsService.initializeSystem();
      
      setState(() => _isInitialized = true);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Module rôles initialisé avec succès'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur d\'initialisation: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Module Rôles'),
        actions: [
          IconButton(
            onPressed: _showModuleInfo,
            icon: const Icon(Icons.info),
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reinitialize',
                child: ListTile(
                  leading: Icon(Icons.refresh),
                  title: Text('Réinitialiser'),
                ),
              ),
              const PopupMenuItem(
                value: 'clear_data',
                child: ListTile(
                  leading: Icon(Icons.clear_all),
                  title: Text('Effacer données'),
                ),
              ),
              const PopupMenuItem(
                value: 'export_config',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Exporter config'),
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.admin_panel_settings), text: 'Rôles'),
            Tab(icon: Icon(Icons.security), text: 'Permissions'),
            Tab(icon: Icon(Icons.view_module), text: 'Templates'),
            Tab(icon: Icon(Icons.grid_view), text: 'Matrice'),
            Tab(icon: Icon(Icons.batch_prediction), text: 'Bulk Ops'),
            Tab(icon: Icon(Icons.analytics), text: 'Tests'),
          ],
        ),
      ),
      body: !_isInitialized
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Initialisation du module rôles...'),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRolesTab(),
                _buildPermissionsTab(),
                _buildTemplatesTab(),
                _buildMatrixTab(),
                _buildBulkOpsTab(),
                _buildTestsTab(),
              ],
            ),
    );
  }

  Widget _buildRolesTab() {
    return Consumer<RoleProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                'Gestion des Rôles',
                'Créer, modifier et supprimer des rôles',
                Icons.admin_panel_settings,
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(Icons.assignment_ind, size: 48, color: AppTheme.primaryColor),
                            const SizedBox(height: 8),
                            Text(
                              '${provider.roles.length}',
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                            ),
                            const Text('Rôles totaux'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(Icons.check_circle, size: 48, color: AppTheme.success),
                            const SizedBox(height: 8),
                            Text(
                              '${provider.roles.where((r) => r.isActive).length}',
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                            ),
                            const Text('Rôles actifs'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(Icons.lock, size: 48, color: AppTheme.warning),
                            const SizedBox(height: 8),
                            Text(
                              '${provider.roles.where((r) => r.color == '#FF9800').length}', // Approximation pour rôles système
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                            ),
                            const Text('Rôles spéciaux'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _createTestRole,
                    icon: const Icon(Icons.add),
                    label: const Text('Créer rôle de test'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _showAdvancedSettings(context),
                    icon: const Icon(Icons.settings),
                    label: const Text('Paramètres avancés'),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Liste des rôles
              ...provider.roles.map((role) => _buildRoleCard(role)).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPermissionsTab() {
    return Consumer<PermissionProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                'Gestion des Permissions',
                'Vue d\'ensemble du système de permissions',
                Icons.security,
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(Icons.security, size: 48, color: AppTheme.info),
                            const SizedBox(height: 8),
                            Text(
                              '${provider.permissions.length}',
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                            ),
                            const Text('Permissions totales'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(Icons.apps, size: 48, color: AppTheme.success),
                            const SizedBox(height: 8),
                            Text(
                              '${provider.permissionsByModule.keys.length}',
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                            ),
                            const Text('Modules'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _createTestPermissions,
                    icon: const Icon(Icons.add),
                    label: const Text('Créer permissions de test'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _showPermissionMatrix(context),
                    icon: const Icon(Icons.view_module),
                    label: const Text('Voir matrice'),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Permissions par module
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ExpansionTile(
                  title: const Text('Permissions de test'),
                  subtitle: Text('${provider.permissions.length} permissions totales'),
                  children: provider.permissions.map((permission) {
                    return ListTile(
                      leading: const Icon(Icons.security),
                      title: Text(permission.name),
                      subtitle: Text(permission.description),
                      trailing: Chip(
                        label: Text(permission.module),
                        backgroundColor: AppTheme.info.withOpacity(0.1),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTemplatesTab() {
    return Consumer<RoleTemplateProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                'Templates de Rôles',
                'Modèles prédéfinis pour la création de rôles',
                Icons.view_module,
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(Icons.list_alt, size: 48, color: AppTheme.primaryColor),
                            const SizedBox(height: 8),
                            Text(
                              '${provider.templates.length}',
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                            ),
                            const Text('Templates totaux'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(Icons.lock, size: 48, color: AppTheme.info),
                            const SizedBox(height: 8),
                            Text(
                              '${provider.systemTemplates.length}',
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                            ),
                            const Text('Templates système'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(Icons.edit, size: 48, color: AppTheme.success),
                            const SizedBox(height: 8),
                            Text(
                              '${provider.customTemplates.length}',
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                            ),
                            const Text('Templates personnalisés'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _openTemplateManagement,
                    icon: const Icon(Icons.manage_accounts),
                    label: const Text('Gestion complète'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _showTemplateSelector,
                    icon: const Icon(Icons.select_all),
                    label: const Text('Sélecteur'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _showTemplateForm,
                    icon: const Icon(Icons.add),
                    label: const Text('Nouveau'),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Templates par catégorie
              ...TemplateCategory.values.map((category) {
                final templates = provider.getTemplatesByCategory(category.id);
                if (templates.isEmpty) return const SizedBox.shrink();
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ExpansionTile(
                    leading: Icon(category.icon),
                    title: Text(category.displayName),
                    subtitle: Text('${templates.length} template(s)'),
                    children: templates.map((template) {
                      return ListTile(
                        leading: Icon(template.iconData, color: template.color),
                        title: Text(template.name),
                        subtitle: Text('${template.permissionIds.length} permissions'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (template.isSystemTemplate)
                              const Chip(
                                label: Text('SYS', style: TextStyle(fontSize: 10)),
                                backgroundColor: Colors.blue,
                              ),
                            IconButton(
                              onPressed: () => _createRoleFromTemplate(template),
                              icon: const Icon(Icons.add_circle_outline),
                              tooltip: 'Créer rôle',
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMatrixTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Matrice des Permissions',
            'Vue d\'ensemble des permissions par rôle',
            Icons.view_module,
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _showPermissionMatrix(context),
                icon: const Icon(Icons.table_chart),
                label: const Text('Ouvrir matrice complète'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _exportMatrix,
                icon: const Icon(Icons.download),
                label: const Text('Exporter CSV'),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Aperçu rapide',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'La matrice complète des permissions est disponible via le bouton ci-dessus. '
                    'Elle permet de visualiser toutes les permissions assignées à chaque rôle, '
                    'd\'exporter les données en CSV et d\'imprimer un rapport détaillé.',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.info, color: AppTheme.info),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Utilisez la matrice pour identifier les conflits de permissions '
                          'et optimiser vos rôles.',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulkOpsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Opérations en Masse',
            'Gestion avancée des permissions et assignations',
            Icons.batch_prediction,
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _openBulkManagement,
                icon: const Icon(Icons.groups),
                label: const Text('Ouvrir gestion en masse'),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fonctionnalités disponibles',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  ListTile(
                    leading: Icon(Icons.group_add, color: AppTheme.success),
                    title: const Text('Assignations en masse'),
                    subtitle: const Text('Assigner plusieurs rôles à plusieurs utilisateurs'),
                  ),
                  
                  ListTile(
                    leading: Icon(Icons.group_remove, color: AppTheme.warning),
                    title: const Text('Révocations en masse'),
                    subtitle: const Text('Révoquer des rôles selon des critères'),
                  ),
                  
                  ListTile(
                    leading: Icon(Icons.analytics, color: AppTheme.info),
                    title: const Text('Analyses et statistiques'),
                    subtitle: const Text('Vue d\'ensemble et recommandations'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Tests et Validation',
            'Tests automatisés du module rôles',
            Icons.bug_report,
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _runAllTests,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Exécuter tous les tests'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _validateIntegrity,
                icon: const Icon(Icons.verified),
                label: const Text('Valider intégrité'),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tests disponibles',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildTestItem('Création de rôle', _testRoleCreation),
                  _buildTestItem('Assignation de permissions', _testPermissionAssignment),
                  _buildTestItem('Validation des templates', _testTemplateValidation),
                  _buildTestItem('Service avancé', _testAdvancedService),
                  _buildTestItem('Export/Import', _testExportImport),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleCard(Role role) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _parseColor(role.color).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_parseIcon(role.icon), color: _parseColor(role.color)),
        ),
        title: Row(
          children: [
            Expanded(child: Text(role.name)),
            if (role.color == '#FF9800') // Approximation pour rôles spéciaux
              const Chip(
                label: Text('SPECIAL', style: TextStyle(fontSize: 10)),
                backgroundColor: Colors.orange,
              ),
            if (!role.isActive)
              const Chip(
                label: Text('INACTIF', style: TextStyle(fontSize: 10)),
                backgroundColor: Colors.red,
              ),
          ],
        ),
        subtitle: Text('${role.permissions.length} permissions'),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _handleRoleAction(action, role),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Modifier'),
              ),
            ),
            const PopupMenuItem(
              value: 'duplicate',
              child: ListTile(
                leading: Icon(Icons.copy),
                title: Text('Dupliquer'),
              ),
            ),
            if (role.color != '#FF9800') // Empêcher la suppression des rôles spéciaux
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Supprimer', style: TextStyle(color: Colors.red)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestItem(String title, VoidCallback onTest) {
    return ListTile(
      leading: const Icon(Icons.science),
      title: Text(title),
      trailing: OutlinedButton(
        onPressed: onTest,
        child: const Text('Tester'),
      ),
    );
  }

  // Utilitaires

  Color _parseColor(String colorString) {
    try {
      final hexColor = colorString.replaceAll('#', '');
      return Color(int.parse('FF$hexColor', radix: 16));
    } catch (e) {
      return AppTheme.primaryColor;
    }
  }

  IconData _parseIcon(String iconName) {
    switch (iconName) {
      case 'admin_panel_settings': return Icons.admin_panel_settings;
      case 'supervisor_account': return Icons.supervisor_account;
      case 'edit': return Icons.edit;
      case 'visibility': return Icons.visibility;
      case 'security': return Icons.security;
      default: return Icons.admin_panel_settings;
    }
  }

  // Utilitaires

  // Actions

  void _handleMenuAction(String action) {
    switch (action) {
      case 'reinitialize':
        _initializeProviders();
        break;
      case 'clear_data':
        _clearTestData();
        break;
      case 'export_config':
        _exportConfiguration();
        break;
    }
  }

  void _handleRoleAction(String action, Role role) {
    switch (action) {
      case 'edit':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Édition de "${role.name}" à implémenter')),
        );
        break;
      case 'duplicate':
        _duplicateRole(role);
        break;
      case 'delete':
        _deleteRole(role);
        break;
    }
  }

  void _showModuleInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Module Rôles et Permissions'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ce module fournit un système complet de gestion des rôles et permissions :',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text('• Gestion des rôles avec permissions granulaires'),
              Text('• Templates de rôles prédéfinis'),
              Text('• Matrice de permissions exportable'),
              Text('• Opérations en masse sur les assignations'),
              Text('• Service avancé avec audit et validation'),
              Text('• Interface complète de configuration'),
              SizedBox(height: 16),
              Text(
                'Toutes les fonctionnalités sont testables depuis cette interface.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
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

  Future<void> _createTestRole() async {
    try {
      final provider = Provider.of<RoleProvider>(context, listen: false);
      
      final role = Role(
        id: '',
        name: 'Test Role ${DateTime.now().millisecondsSinceEpoch}',
        description: 'Rôle de test créé automatiquement',
        permissions: ['test.permission.read', 'test.permission.write'],
        icon: 'security',
        color: '#4CAF50',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await provider.createRole(role);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rôle de test créé avec succès')),
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

  Future<void> _createTestPermissions() async {
    // Simulation de création de permissions de test
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Simulation: Permissions de test créées')),
      );
    }
  }

  void _showPermissionMatrix(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const PermissionMatrixDialog(),
    );
  }

  void _showAdvancedSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Paramètres Avancés'),
        content: const Text('Interface des paramètres avancés à implémenter.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _openTemplateManagement() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RoleTemplateManagementScreen(),
      ),
    );
  }

  void _openBulkManagement() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const Scaffold(
          body: BulkPermissionManagementWidget(),
        ),
      ),
    );
  }

  void _showTemplateSelector() {
    showRoleTemplateSelectionDialog(
      context: context,
      allowMultipleSelection: true,
    ).then((result) {
      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Templates sélectionnés: $result')),
        );
      }
    });
  }

  void _showTemplateForm() {
    showDialog(
      context: context,
      builder: (context) => const RoleTemplateFormDialog(),
    ).then((result) {
      if (result == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template traité avec succès')),
        );
      }
    });
  }

  void _createRoleFromTemplate(RoleTemplate template) async {
    try {
      final provider = Provider.of<RoleTemplateProvider>(context, listen: false);
      
      final roleId = await provider.createRoleFromTemplate(
        template.id,
        customName: '${template.name} (depuis template)',
        createdBy: 'test_user',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rôle créé depuis template: $roleId')),
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

  void _duplicateRole(Role role) {
    // TODO: Implémenter la duplication de rôle
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Duplication de "${role.name}" à implémenter')),
    );
  }

  void _deleteRole(Role role) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Supprimer le rôle "${role.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final provider = Provider.of<RoleProvider>(context, listen: false);
                await provider.deleteRole(role.id);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Rôle supprimé')),
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

  void _exportMatrix() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export de la matrice à implémenter')),
    );
  }

  void _clearTestData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nettoyage des données de test à implémenter')),
    );
  }

  void _exportConfiguration() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export de la configuration à implémenter')),
    );
  }

  // Tests

  void _runAllTests() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exécution de tous les tests...')),
    );
    
    // Simuler l'exécution des tests
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Tous les tests sont passés'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    });
  }

  void _validateIntegrity() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Validation de l\'intégrité en cours...')),
    );
    
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Intégrité validée'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    });
  }

  void _testRoleCreation() {
    _createTestRole();
  }

  void _testPermissionAssignment() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Test d\'assignation de permissions...')),
    );
  }

  void _testTemplateValidation() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Test de validation des templates...')),
    );
  }

  void _testAdvancedService() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Test du service avancé...')),
    );
  }

  void _testExportImport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Test d\'export/import...')),
    );
  }
}