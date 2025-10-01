import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/permission_provider.dart';
import '../config/admin_permissions_config.dart';
import '../../../theme.dart';

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
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPermissionsList(
                    'Permissions Super Admin',
                    AdminPermissionsConfig.superAdminPermissions,
                    AppTheme.errorColor,
                  ),
                  const SizedBox(height: AppTheme.spaceMedium),
                  _buildPermissionsList(
                    'Permissions Admin',
                    AdminPermissionsConfig.adminPermissions,
                    AppTheme.warning,
                  ),
                  const SizedBox(height: AppTheme.spaceMedium),
                  _buildPermissionsList(
                    'Modules Admin',
                    AdminPermissionsConfig.adminModules,
                    AppTheme.infoColor,
                  ),
                  const SizedBox(height: AppTheme.spaceMedium),
                  FutureBuilder<bool>(
                    future: permissionProvider.hasAdminRole(),
                    builder: (context, snapshot) {
                      final hasAdmin = snapshot.data ?? false;
                      return Container(
                        padding: const EdgeInsets.all(AppTheme.space12),
                        decoration: BoxDecoration(
                          color: hasAdmin ? AppTheme.successContainer : AppTheme.errorContainer,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          border: Border.all(
                            color: hasAdmin ? AppTheme.successColor : AppTheme.errorColor,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              hasAdmin ? Icons.check_circle : Icons.cancel,
                              color: hasAdmin ? AppTheme.successColor : AppTheme.errorColor,
                            ),
                            const SizedBox(width: AppTheme.spaceSmall),
                            Text(
                              hasAdmin 
                                  ? 'Utilisateur a accès admin ✅' 
                                  : 'Utilisateur n\'a PAS accès admin ❌',
                              style: TextStyle(
                                fontWeight: AppTheme.fontBold,
                                color: hasAdmin ? AppTheme.successColor : AppTheme.errorColor,
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
            const SizedBox(width: AppTheme.spaceSmall),
            Text(
              title,
              style: const TextStyle(
                fontWeight: AppTheme.fontBold,
                fontSize: AppTheme.fontSize16,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceSmall),
        Container(
          padding: const EdgeInsets.all(AppTheme.space12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
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
                    const SizedBox(width: AppTheme.space6),
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