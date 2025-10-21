import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/role.dart';
import '../models/permission.dart';
import '../models/user_role.dart';
import '../services/export_service.dart';
import '../../../../theme.dart';

class ExportOptionsDialog extends StatelessWidget {
  final List<Role> roles;
  final List<String> permissions;
  final List<UserRole> userRoles;

  const ExportOptionsDialog({
    super.key,
    required this.roles,
    required this.permissions,
    required this.userRoles,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.file_download, color: theme.primaryColor),
          const SizedBox(width: AppTheme.spaceSmall),
          const Text('Options d\'export'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Choisissez le type de données à exporter :',
            style: TextStyle(fontSize: AppTheme.fontSize16),
          ),
          const SizedBox(height: AppTheme.space20),
          _buildExportOption(
            context,
            'Rôles',
            'Exporter tous les rôles (JSON/CSV)',
            Icons.admin_panel_settings,
            () => _exportRoles(context),
          ),
          const SizedBox(height: AppTheme.space12),
          _buildExportOption(
            context,
            'Permissions',
            'Exporter toutes les permissions (JSON/CSV)',
            Icons.security,
            () => _exportPermissions(context),
          ),
          const SizedBox(height: AppTheme.space12),
          _buildExportOption(
            context,
            'Affectations',
            'Exporter les affectations de rôles (JSON/CSV)',
            Icons.assignment_ind,
            () => _exportUserRoles(context),
          ),
          const SizedBox(height: AppTheme.space12),
          _buildExportOption(
            context,
            'Matrice des permissions',
            'Exporter la matrice complète (JSON/CSV)',
            Icons.grid_on,
            () => _exportPermissionMatrix(context),
          ),
          const SizedBox(height: AppTheme.space12),
          _buildExportOption(
            context,
            'Rapport complet',
            'Exporter un rapport détaillé (JSON/CSV)',
            Icons.description,
            () => _exportFullReport(context),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
      ],
    );
  }

  Widget _buildExportOption(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: AppTheme.fontBold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.of(context).pop();
          onTap();
        },
      ),
    );
  }

  void _exportRoles(BuildContext context) async {
    await _showFormatDialog(context, 'rôles', () async {
      try {
        // JSON
        final content = await ExportService.exportRolesToJson(roles);
        await Clipboard.setData(ClipboardData(text: content));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rôles (JSON) copiés dans le presse-papiers')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }, () async {
      try {
        // CSV
        final content = await ExportService.exportRolesToCsv(roles);
        await Clipboard.setData(ClipboardData(text: content));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rôles (CSV) copiés dans le presse-papiers')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    });
  }

  void _exportPermissions(BuildContext context) async {
    // Convertir les permissions string en objets Permission avec champ action par défaut
    final permissionObjects = permissions.map((p) => Permission(
      id: p,
      name: p,
      description: 'Permission $p',
      module: p.split('_').first,
      action: p.split('_').last,
    )).toList();
    
    await _showFormatDialog(context, 'permissions', () async {
      try {
        // JSON
        final content = await ExportService.exportPermissionsToJson(permissionObjects);
        await Clipboard.setData(ClipboardData(text: content));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permissions (JSON) copiées dans le presse-papiers')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }, () async {
      try {
        // CSV
        final content = await ExportService.exportPermissionsToCsv(permissionObjects);
        await Clipboard.setData(ClipboardData(text: content));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permissions (CSV) copiées dans le presse-papiers')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    });
  }

  void _exportUserRoles(BuildContext context) async {
    await _showFormatDialog(context, 'affectations', () async {
      try {
        // JSON - Fournir la liste des rôles comme second paramètre
        final content = await ExportService.exportUserRolesToJson(userRoles, roles);
        await Clipboard.setData(ClipboardData(text: content));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Affectations (JSON) copiées dans le presse-papiers')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }, () async {
      try {
        // CSV - Fournir la liste des rôles comme second paramètre
        final content = await ExportService.exportUserRolesToCsv(userRoles, roles);
        await Clipboard.setData(ClipboardData(text: content));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Affectations (CSV) copiées dans le presse-papiers')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    });
  }

  void _exportPermissionMatrix(BuildContext context) async {
    await _showFormatDialog(context, 'matrice des permissions', () async {
      try {
        // Pour la matrice, on export les rôles avec leurs permissions
        final content = await ExportService.exportRolesToJson(roles);
        await Clipboard.setData(ClipboardData(text: content));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Matrice des permissions (JSON) copiée dans le presse-papiers')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }, () async {
      try {
        // CSV
        final content = await ExportService.exportRolesToCsv(roles);
        await Clipboard.setData(ClipboardData(text: content));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Matrice des permissions (CSV) copiée dans le presse-papiers')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    });
  }

  void _exportFullReport(BuildContext context) async {
    await _showFormatDialog(context, 'rapport complet', () async {
      try {
        // JSON - Combiner tous les exports
        final rolesContent = await ExportService.exportRolesToJson(roles);
        final userRolesContent = await ExportService.exportUserRolesToJson(userRoles, roles);
        
        final fullReport = '''
{
  "export_date": "${DateTime.now().toIso8601String()}",
  "export_type": "complete_report",
  "roles": $rolesContent,
  "user_roles": $userRolesContent
}''';
        
        await Clipboard.setData(ClipboardData(text: fullReport));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rapport complet (JSON) copié dans le presse-papiers')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }, () async {
      try {
        // CSV - Combiner toutes les sections
        final rolesContent = await ExportService.exportRolesToCsv(roles);
        final userRolesContent = await ExportService.exportUserRolesToCsv(userRoles, roles);
        
        final combinedContent = '''ROLES
$rolesContent

USER ROLES
$userRolesContent''';
        
        await Clipboard.setData(ClipboardData(text: combinedContent));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rapport complet (CSV) copié dans le presse-papiers')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    });
  }

  Future<void> _showFormatDialog(
    BuildContext context,
    String dataType,
    VoidCallback onJsonTap,
    VoidCallback onCsvTap,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Format d\'export pour $dataType'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('JSON'),
              subtitle: const Text('Format structuré pour développeurs'),
              onTap: () {
                Navigator.of(context).pop();
                onJsonTap();
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('CSV'),
              subtitle: const Text('Format tableur pour Excel/Google Sheets'),
              onTap: () {
                Navigator.of(context).pop();
                onCsvTap();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }
}
