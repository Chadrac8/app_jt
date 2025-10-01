import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../modules/roles/roles_module.dart';
import '../../theme.dart';

/// Page de test pour vérifier l'intégration du module de rôles
class RoleModuleTestPage extends StatelessWidget {
  const RoleModuleTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PermissionProvider(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Test - Module Rôles'),
          backgroundColor: AppTheme.blueStandard,
          foregroundColor: AppTheme.white100,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Module d\'Assignation des Rôles',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: AppTheme.fontBold,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceSmall),
                      Text(
                        'Interface complète pour gérer l\'assignation des rôles aux utilisateurs de l\'application.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              ElevatedButton.icon(
                onPressed: () => _navigateToAssignment(context),
                icon: const Icon(Icons.people),
                label: const Text('Assignation par Utilisateur'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.blueStandard,
                  foregroundColor: AppTheme.white100,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: AppTheme.space12),
              ElevatedButton.icon(
                onPressed: () => _navigateToRoleManagement(context),
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text('Gestion des Rôles'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.greenStandard,
                  foregroundColor: AppTheme.white100,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: AppTheme.space12),
              ElevatedButton.icon(
                onPressed: () => _navigateToModuleMenu(context),
                icon: const Icon(Icons.dashboard),
                label: const Text('Menu Complet du Module'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.orangeStandard,
                  foregroundColor: AppTheme.white100,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: AppTheme.spaceLarge),
              Card(
                color: AppTheme.grey50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: AppTheme.grey600),
                          const SizedBox(width: AppTheme.spaceSmall),
                          Text(
                            'Intégration Réussie',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.grey700,
                              fontWeight: AppTheme.fontBold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spaceSmall),
                      Text(
                        'Le module d\'assignation des rôles est maintenant intégré dans l\'application et accessible depuis :',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppTheme.spaceSmall),
                      Text(
                        '• Navigation Admin → Rôles → Onglet "Assignations"',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '• Bouton "Interface complète" dans l\'AppBar',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '• Accès direct via les boutons ci-dessus',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToAssignment(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (_) => PermissionProvider(),
          child: const RoleAssignmentScreen(),
        ),
      ),
    );
  }

  void _navigateToRoleManagement(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (_) => PermissionProvider(),
          child: const RolesManagementScreen(),
        ),
      ),
    );
  }

  void _navigateToModuleMenu(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RoleModuleMenuWidget(),
      ),
    );
  }
}
