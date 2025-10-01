import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../roles_module.dart';
import '../../../../theme.dart';
import '../../../theme.dart';

/// Exemple d'utilisation du module Rôles et Permissions
class RolesModuleExample extends StatefulWidget {
  const RolesModuleExample({super.key});

  @override
  State<RolesModuleExample> createState() => _RolesModuleExampleState();
}

class _RolesModuleExampleState extends State<RolesModuleExample> {
  final String currentUserId = 'example_user_id';
  
  @override
  void initState() {
    super.initState();
    _initializeModule();
  }

  Future<void> _initializeModule() async {
    try {
      // Initialiser le module
      await RolesModule.initialize();
      
      // Initialiser le provider avec l'utilisateur courant
      if (mounted) {
        Provider.of<PermissionProvider>(context, listen: false)
            .initialize(currentUserId);
      }
    } catch (e) {
      print('Erreur lors de l\'initialisation du module: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Module Rôles et Permissions'),
        actions: [
          IconButton(
            onPressed: () => _openRolesManagement(),
            icon: const Icon(Icons.admin_panel_settings),
            tooltip: 'Gestion des rôles',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildModuleInfo(),
            const SizedBox(height: AppTheme.spaceLarge),
            _buildPermissionExamples(),
            const SizedBox(height: AppTheme.spaceLarge),
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.grey600),
                const SizedBox(width: AppTheme.spaceSmall),
                Text(
                  'Informations du module',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: AppTheme.fontBold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space12),
            Text('Nom: ${RolesModule.moduleName}'),
            Text('ID: ${RolesModule.moduleId}'),
            Text('Version: ${RolesModule.moduleVersion}'),
            const SizedBox(height: AppTheme.space12),
            const Text(
              'Ce module fournit un système complet de gestion des rôles et permissions '
              'pour contrôler l\'accès aux différentes fonctionnalités de l\'application.',
              style: TextStyle(color: AppTheme.grey500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionExamples() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: AppTheme.grey600),
                const SizedBox(width: AppTheme.spaceSmall),
                Text(
                  'Exemples de vérifications de permissions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: AppTheme.fontBold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            
            // Garde de permission
            PermissionGuard(
              permission: 'dashboard_visualisation_read',
              userId: currentUserId,
              child: Container(
                padding: const EdgeInsets.all(AppTheme.space12),
                decoration: BoxDecoration(
                  color: AppTheme.grey100,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: AppTheme.greenStandard),
                    SizedBox(width: AppTheme.spaceSmall),
                    Expanded(
                      child: Text('Accès autorisé au dashboard (lecture)'),
                    ),
                  ],
                ),
              ),
              fallback: Container(
                padding: const EdgeInsets.all(AppTheme.space12),
                decoration: BoxDecoration(
                  color: AppTheme.grey100,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.block, color: AppTheme.redStandard),
                    SizedBox(width: AppTheme.spaceSmall),
                    Expanded(
                      child: Text('Accès refusé au dashboard'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: AppTheme.space12),
            
            // Garde de module
            ModuleGuard(
              moduleId: 'personnes',
              userId: currentUserId,
              child: Container(
                padding: const EdgeInsets.all(AppTheme.space12),
                decoration: BoxDecoration(
                  color: AppTheme.grey100,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.people, color: AppTheme.blueStandard),
                    SizedBox(width: AppTheme.spaceSmall),
                    Expanded(
                      child: Text('Accès au module Personnes'),
                    ),
                  ],
                ),
              ),
              fallback: Container(
                padding: const EdgeInsets.all(AppTheme.space12),
                decoration: BoxDecoration(
                  color: AppTheme.grey100,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: AppTheme.orangeStandard),
                    SizedBox(width: AppTheme.spaceSmall),
                    Expanded(
                      child: Text('Pas d\'accès au module Personnes'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flash_on, color: AppTheme.grey600),
                const SizedBox(width: AppTheme.spaceSmall),
                Text(
                  'Actions rapides',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: AppTheme.fontBold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: _openRolesManagement,
                  icon: const Icon(Icons.admin_panel_settings),
                  label: const Text('Gestion des rôles'),
                ),
                ElevatedButton.icon(
                  onPressed: _showPermissionMatrix,
                  icon: const Icon(Icons.grid_view),
                  label: const Text('Matrice des permissions'),
                ),
                ElevatedButton.icon(
                  onPressed: _checkUserPermissions,
                  icon: const Icon(Icons.person_search),
                  label: const Text('Vérifier permissions'),
                ),
                ElevatedButton.icon(
                  onPressed: _exportConfiguration,
                  icon: const Icon(Icons.download),
                  label: const Text('Exporter config'),
                ),
                ElevatedButton.icon(
                  onPressed: _testPermissions,
                  icon: const Icon(Icons.science),
                  label: const Text('Tester permissions'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openRolesManagement() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RolesManagementScreen(),
      ),
    );
  }

  void _showPermissionMatrix() {
    showDialog(
      context: context,
      builder: (context) => const PermissionMatrixDialog(),
    );
  }

  Future<void> _checkUserPermissions() async {
    try {
      // Vérifier quelques permissions spécifiques
      final hasReadDashboard = await RolesModule.checkPermission(
        currentUserId, 
        'dashboard_visualisation_read'
      );
      
      final hasModuleAccess = await RolesModule.checkModuleAccess(
        currentUserId, 
        'personnes'
      );
      
      final userPermissions = await RolesModule.getUserPermissions(currentUserId);
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permissions utilisateur'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dashboard (lecture): ${hasReadDashboard ? "✓" : "✗"}'),
                Text('Module Personnes: ${hasModuleAccess ? "✓" : "✗"}'),
                const SizedBox(height: AppTheme.space12),
                Text('Total permissions: ${userPermissions.length}'),
                if (userPermissions.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spaceSmall),
                  const Text('Quelques permissions:'),
                  ...userPermissions.take(5).map((perm) => Text('• $perm')),
                  if (userPermissions.length > 5)
                    Text('... et ${userPermissions.length - 5} autres'),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fermer'),
              ),
            ],
          ),
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

  Future<void> _exportConfiguration() async {
    try {
      final provider = Provider.of<PermissionProvider>(context, listen: false);
      final config = await provider.exportConfiguration();
      
      if (config != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Configuration exportée (${config.keys.length} clés)'),
            action: SnackBarAction(
              label: 'Voir',
              onPressed: () => _showConfigurationDialog(config),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur d\'export: $e')),
        );
      }
    }
  }

  void _showConfigurationDialog(Map<String, dynamic> config) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configuration exportée'),
        content: SizedBox(
          width: 400,
          height: 300,
          child: SingleChildScrollView(
            child: Text(
              config.toString(),
              style: const TextStyle(fontFamily: 'monospace', fontSize: AppTheme.fontSize12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Future<void> _testPermissions() async {
    // Test des différents niveaux de permissions
    final testCases = [
      {'permission': 'dashboard_visualisation_read', 'description': 'Lecture dashboard'},
      {'permission': 'personnes_membres_write', 'description': 'Modification membres'},
      {'permission': 'roles_rôles_admin', 'description': 'Administration rôles'},
      {'permission': 'configuration_sécurité_admin', 'description': 'Admin sécurité'},
    ];
    
    final results = <Map<String, dynamic>>[];
    
    for (final testCase in testCases) {
      final hasPermission = await RolesModule.checkPermission(
        currentUserId, 
        testCase['permission'] as String
      );
      
      results.add({
        ...testCase,
        'result': hasPermission,
      });
    }
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Test des permissions'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: results.map((result) {
              return ListTile(
                leading: Icon(
                  result['result'] ? Icons.check_circle : Icons.cancel,
                  color: result['result'] ? AppTheme.greenStandard : AppTheme.redStandard,
                ),
                title: Text(result['description']),
                subtitle: Text(result['permission']),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        ),
      );
    }
  }
}
