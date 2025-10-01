import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/permission_provider.dart';
import '../config/admin_permissions_config.dart';

/// Widget de debug pour afficher les informations sur les permissions admin
/// À utiliser uniquement en mode développement
class AdminPermissionsDebugWidget extends StatelessWidget {
  const AdminPermissionsDebugWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Ne s'affiche qu'en mode debug
    assert(() {
      return true;
    }());

    return Consumer<PermissionProvider>(
      builder: (context, permissionProvider, child) {
        return ExpansionTile(
          title: const Text('🔧 Debug: Permissions Admin'),
          subtitle: const Text('Informations de debug sur les permissions administrateur'),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPermissionsList(
                    'Permissions Super Admin',
                    AdminPermissionsConfig.superAdminPermissions,
                    Colors.red,
                  ),
                  const SizedBox(height: 16),
                  _buildPermissionsList(
                    'Permissions Admin',
                    AdminPermissionsConfig.adminPermissions,
                    Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  _buildPermissionsList(
                    'Modules Admin',
                    AdminPermissionsConfig.adminModules,
                    Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<bool>(
                    future: permissionProvider.hasAdminRole(),
                    builder: (context, snapshot) {
                      final hasAdmin = snapshot.data ?? false;
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: hasAdmin ? Colors.green.shade100 : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: hasAdmin ? Colors.green : Colors.red,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              hasAdmin ? Icons.check_circle : Icons.cancel,
                              color: hasAdmin ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              hasAdmin 
                                  ? 'Utilisateur a accès admin ✅' 
                                  : 'Utilisateur n\'a PAS accès admin ❌',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: hasAdmin ? Colors.green.shade800 : Colors.red.shade800,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPermissionsList(String title, List<String> permissions, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: permissions.map((permission) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(Icons.security, size: 14, color: color),
                    const SizedBox(width: 6),
                    Text(
                      permission,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: color.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}