import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../modules/roles/roles_module.dart';
import '../../theme.dart';

/// Page de démonstration pour tester le système de permissions
class PermissionsTestPage extends StatelessWidget {
  const PermissionsTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test des Permissions'),
        actions: [
          IconButton(
            onPressed: () => _openRolesManagement(context),
            icon: const Icon(Icons.admin_panel_settings),
            tooltip: 'Gestion des rôles',
          ),
        ],
      ),
      body: Consumer<PermissionProvider>(
        builder: (context, provider, child) {
          final currentUserId = provider.currentUserId ?? '';
          
          if (currentUserId.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: AppTheme.spaceMedium),
                  Text('Initialisation des permissions...'),
                ],
              ),
            );
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUserInfo(provider),
                const SizedBox(height: AppTheme.spaceLarge),
                _buildPermissionTests(provider),
                const SizedBox(height: AppTheme.spaceLarge),
                _buildProtectedWidgets(context, currentUserId),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserInfo(PermissionProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations utilisateur',
              style: TextStyle(fontSize: AppTheme.fontSize18, fontWeight: AppTheme.fontBold),
            ),
            const SizedBox(height: AppTheme.space12),
            Text('ID Utilisateur: ${provider.currentUserId ?? "Non défini"}'),
            Text('Rôles: ${provider.userRoles.length}'),
            Text('Permissions: ${provider.userPermissions.length}'),
            const SizedBox(height: AppTheme.space12),
            if (provider.userRoles.isNotEmpty) ...[
              const Text('Rôles attribués:', style: TextStyle(fontWeight: AppTheme.fontMedium)),
              ...provider.userRoles.map((role) => 
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 4),
                  child: Text('• ${role.roleId}'),
                )
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionTests(PermissionProvider provider) {
    final testPermissions = [
      'dashboard_visualisation_read',
      'personnes_membres_write',
      'cantiques_bibliothèque_admin',
      'roles_rôles_admin',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Test des permissions',
              style: TextStyle(fontSize: AppTheme.fontSize18, fontWeight: AppTheme.fontBold),
            ),
            const SizedBox(height: AppTheme.space12),
            ...testPermissions.map((permission) => 
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      provider.hasPermission(permission) 
                        ? Icons.check_circle 
                        : Icons.cancel,
                      color: provider.hasPermission(permission) 
                        ? AppTheme.greenStandard 
                        : AppTheme.redStandard,
                      size: 20,
                    ),
                    const SizedBox(width: AppTheme.spaceSmall),
                    Expanded(child: Text(permission)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProtectedWidgets(BuildContext context, String currentUserId) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Widgets protégés',
              style: TextStyle(fontSize: AppTheme.fontSize18, fontWeight: AppTheme.fontBold),
            ),
            const SizedBox(height: AppTheme.space12),
            
            // Test PermissionGuard
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
                    Icon(Icons.dashboard, color: AppTheme.greenStandard),
                    SizedBox(width: AppTheme.spaceSmall),
                    Text('Dashboard accessible'),
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
                    Text('Dashboard non accessible'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: AppTheme.space12),
            
            // Test ModuleGuard
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
                    Text('Module Personnes accessible'),
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
                    Text('Module Personnes non accessible'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: AppTheme.spaceMedium),
            
            // Boutons d'action protégés
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                PermissionGuard(
                  permission: 'personnes_membres_write',
                  userId: currentUserId,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.edit),
                    label: const Text('Modifier membres'),
                  ),
                  fallback: ElevatedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.edit),
                    label: const Text('Modifier membres'),
                  ),
                ),
                PermissionGuard(
                  permission: 'roles_rôles_admin',
                  userId: currentUserId,
                  child: ElevatedButton.icon(
                    onPressed: () => _openRolesManagement(context),
                    icon: const Icon(Icons.admin_panel_settings),
                    label: const Text('Gérer rôles'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: AppTheme.white100,
                    ),
                  ),
                  fallback: const SizedBox.shrink(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openRolesManagement(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RolesManagementScreen(),
      ),
    );
  }
}
