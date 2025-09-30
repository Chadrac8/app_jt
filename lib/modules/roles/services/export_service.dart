import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/role.dart';
import '../models/permission.dart';
import '../models/user_role.dart';
import '../../../../theme.dart';

class ExportService {
  static const String _csvSeparator = ',';
  static const String _lineBreak = '\n';

  /// Exporter les rôles au format JSON
  static Future<String> exportRolesToJson(List<Role> roles) async {
    final data = {
      'export_date': DateTime.now().toIso8601String(),
      'export_type': 'roles',
      'version': '1.0',
      'data': roles.map((role) => {
        'id': role.id,
        'name': role.name,
        'description': role.description,
        'permissions': role.permissions,
        'is_active': role.isActive,
        'created_at': role.createdAt?.toIso8601String(),
        'updated_at': role.updatedAt?.toIso8601String(),
      }).toList(),
    };
    
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Exporter les rôles au format CSV
  static Future<String> exportRolesToCsv(List<Role> roles) async {
    final buffer = StringBuffer();
    
    // En-têtes
    buffer.write('ID${_csvSeparator}Nom${_csvSeparator}Description${_csvSeparator}');
    buffer.write('Permissions${_csvSeparator}Actif${_csvSeparator}');
    buffer.write('Date de création${_csvSeparator}Dernière modification$_lineBreak');
    
    // Données
    for (final role in roles) {
      buffer.write('${_escapeCSV(role.id)}$_csvSeparator');
      buffer.write('${_escapeCSV(role.name)}$_csvSeparator');
      buffer.write('${_escapeCSV(role.description)}$_csvSeparator');
      buffer.write('${_escapeCSV(role.permissions.join('; '))}$_csvSeparator');
      buffer.write('${role.isActive ? 'Oui' : 'Non'}$_csvSeparator');
      buffer.write('${_formatDate(role.createdAt)}$_csvSeparator');
      buffer.write('${_formatDate(role.updatedAt)}$_lineBreak');
    }
    
    return buffer.toString();
  }

  /// Exporter les permissions au format JSON
  static Future<String> exportPermissionsToJson(List<Permission> permissions) async {
    final data = {
      'export_date': DateTime.now().toIso8601String(),
      'export_type': 'permissions',
      'version': '1.0',
      'data': permissions.map((permission) => {
        'id': permission.id,
        'name': permission.name,
        'description': permission.description,
        'module': permission.module,
        'action': permission.action,
      }).toList(),
    };
    
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Exporter les permissions au format CSV
  static Future<String> exportPermissionsToCsv(List<Permission> permissions) async {
    final buffer = StringBuffer();
    
    // En-têtes
    buffer.write('ID${_csvSeparator}Nom${_csvSeparator}Description${_csvSeparator}');
    buffer.write('Module${_csvSeparator}Action$_lineBreak');
    
    // Données
    for (final permission in permissions) {
      buffer.write('${_escapeCSV(permission.id)}$_csvSeparator');
      buffer.write('${_escapeCSV(permission.name)}$_csvSeparator');
      buffer.write('${_escapeCSV(permission.description)}$_csvSeparator');
      buffer.write('${_escapeCSV(permission.module)}$_csvSeparator');
      buffer.write('${_escapeCSV(permission.action)}$_lineBreak');
    }
    
    return buffer.toString();
  }

  /// Exporter les assignations d'utilisateurs au format JSON
  static Future<String> exportUserRolesToJson(List<UserRole> userRoles, List<Role> roles) async {
    final data = {
      'export_date': DateTime.now().toIso8601String(),
      'export_type': 'user_roles',
      'version': '1.0',
      'data': userRoles.map((userRole) => {
        'user_id': userRole.userId,
        'user_email': userRole.userEmail,
        'user_name': userRole.userName,
        'role_ids': userRole.roleIds,
        'role_names': userRole.roleIds.map((roleId) {
          final role = roles.firstWhere(
            (r) => r.id == roleId,
            orElse: () => Role(id: roleId, name: 'Rôle inconnu', description: ''),
          );
          return role.name;
        }).toList(),
        'is_active': userRole.isActive,
        'assigned_by': userRole.assignedBy,
        'assigned_at': userRole.assignedAt?.toIso8601String(),
        'expires_at': userRole.expiresAt?.toIso8601String(),
      }).toList(),
    };
    
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Exporter les assignations d'utilisateurs au format CSV
  static Future<String> exportUserRolesToCsv(List<UserRole> userRoles, List<Role> roles) async {
    final buffer = StringBuffer();
    
    // En-têtes
    buffer.write('Email utilisateur${_csvSeparator}Nom utilisateur${_csvSeparator}');
    buffer.write('Rôles${_csvSeparator}Actif${_csvSeparator}');
    buffer.write('Assigné par${_csvSeparator}Date d\'assignation${_csvSeparator}');
    buffer.write('Date d\'expiration$_lineBreak');
    
    // Données
    for (final userRole in userRoles) {
      final roleNames = userRole.roleIds.map((roleId) {
        final role = roles.firstWhere(
          (r) => r.id == roleId,
          orElse: () => Role(id: roleId, name: 'Rôle inconnu', description: ''),
        );
        return role.name;
      }).join('; ');
      
      buffer.write('${_escapeCSV(userRole.userEmail)}$_csvSeparator');
      buffer.write('${_escapeCSV(userRole.userName)}$_csvSeparator');
      buffer.write('${_escapeCSV(roleNames)}$_csvSeparator');
      buffer.write('${userRole.isActive ? 'Oui' : 'Non'}$_csvSeparator');
      buffer.write('${_escapeCSV(userRole.assignedBy ?? '')}$_csvSeparator');
      buffer.write('${_formatDate(userRole.assignedAt)}$_csvSeparator');
      buffer.write('${_formatDate(userRole.expiresAt)}$_lineBreak');
    }
    
    return buffer.toString();
  }

  /// Exporter une matrice des permissions
  static Future<String> exportPermissionMatrix(
    List<Role> roles, 
    List<Permission> permissions,
  ) async {
    final buffer = StringBuffer();
    
    // En-têtes
    buffer.write('Rôle / Permission$_csvSeparator');
    for (final permission in permissions) {
      buffer.write('${_escapeCSV(permission.name)}$_csvSeparator');
    }
    buffer.write(_lineBreak);
    
    // Données
    for (final role in roles) {
      buffer.write('${_escapeCSV(role.name)}$_csvSeparator');
      for (final permission in permissions) {
        final hasPermission = role.hasPermission(permission.id);
        buffer.write('${hasPermission ? 'X' : ''}$_csvSeparator');
      }
      buffer.write(_lineBreak);
    }
    
    return buffer.toString();
  }

  /// Générer un rapport complet
  static Future<String> generateFullReport(
    List<Role> roles,
    List<Permission> permissions,
    List<UserRole> userRoles,
  ) async {
    final buffer = StringBuffer();
    final now = DateTime.now();
    
    buffer.write('RAPPORT COMPLET DES RÔLES ET PERMISSIONS$_lineBreak');
    buffer.write('Généré le: ${_formatDate(now)}$_lineBreak');
    buffer.write('$_lineBreak');
    
    // Statistiques générales
    buffer.write('=== STATISTIQUES GÉNÉRALES ===$_lineBreak');
    buffer.write('Nombre total de rôles: ${roles.length}$_lineBreak');
    buffer.write('Rôles actifs: ${roles.where((r) => r.isActive).length}$_lineBreak');
    buffer.write('Nombre total de permissions: ${permissions.length}$_lineBreak');
    buffer.write('Utilisateurs avec des rôles: ${userRoles.where((ur) => ur.isActive).length}$_lineBreak');
    buffer.write('$_lineBreak');
    
    // Répartition par module
    buffer.write('=== RÉPARTITION DES PERMISSIONS PAR MODULE ===$_lineBreak');
    final permissionsByModule = <String, int>{};
    for (final permission in permissions) {
      permissionsByModule[permission.module] = 
          (permissionsByModule[permission.module] ?? 0) + 1;
    }
    
    for (final entry in permissionsByModule.entries) {
      buffer.write('${entry.key}: ${entry.value} permissions$_lineBreak');
    }
    buffer.write('$_lineBreak');
    
    // Rôles les plus utilisés
    buffer.write('=== RÔLES LES PLUS UTILISÉS ===$_lineBreak');
    final roleUsage = <String, int>{};
    for (final userRole in userRoles.where((ur) => ur.isActive)) {
      for (final roleId in userRole.roleIds) {
        roleUsage[roleId] = (roleUsage[roleId] ?? 0) + 1;
      }
    }
    
    final sortedRoleUsage = roleUsage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    for (final entry in sortedRoleUsage.take(10)) {
      final role = roles.firstWhere(
        (r) => r.id == entry.key,
        orElse: () => Role(id: entry.key, name: 'Rôle inconnu', description: ''),
      );
      buffer.write('${role.name}: ${entry.value} utilisateur(s)$_lineBreak');
    }
    
    return buffer.toString();
  }

  /// Sauvegarder et partager un fichier
  static Future<void> saveAndShareFile(
    String content,
    String fileName,
    String mimeType,
  ) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(content);
      
      await Share.shareXFiles([XFile(file.path)], text: 'Export des données');
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde: $e');
    }
  }

  /// Copier dans le presse-papiers
  static Future<void> copyToClipboard(String content) async {
    await Clipboard.setData(ClipboardData(text: content));
  }

  /// Formater une date
  static String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/'
           '${date.month.toString().padLeft(2, '0')}/'
           '${date.year} '
           '${date.hour.toString().padLeft(2, '0')}:'
           '${date.minute.toString().padLeft(2, '0')}';
  }

  /// Échapper les caractères spéciaux pour CSV
  static String _escapeCSV(String value) {
    if (value.contains(_csvSeparator) || 
        value.contains('"') || 
        value.contains(_lineBreak)) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}

/// Widget pour afficher les options d'export
class ExportOptionsDialog extends StatefulWidget {
  final List<Role> roles;
  final List<Permission> permissions;
  final List<UserRole> userRoles;

  const ExportOptionsDialog({
    super.key,
    required this.roles,
    required this.permissions,
    required this.userRoles,
  });

  @override
  State<ExportOptionsDialog> createState() => _ExportOptionsDialogState();
}

class _ExportOptionsDialogState extends State<ExportOptionsDialog> {
  String _selectedFormat = 'json';
  String _selectedData = 'roles';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildDataSelection(),
            const SizedBox(height: 16),
            _buildFormatSelection(),
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Icon(
            Icons.file_download,
            color: Theme.of(context).primaryColor,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Exporter les données',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: AppTheme.fontBold,
                ),
              ),
              Text(
                'Choisissez le type de données et le format',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.grey600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDataSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Données à exporter',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: AppTheme.fontBold,
          ),
        ),
        const SizedBox(height: 8),
        ...{
          'roles': 'Rôles (${widget.roles.length})',
          'permissions': 'Permissions (${widget.permissions.length})',
          'user_roles': 'Assignations (${widget.userRoles.length})',
          'matrix': 'Matrice des permissions',
          'report': 'Rapport complet',
        }.entries.map((entry) => RadioListTile<String>(
          title: Text(entry.value),
          value: entry.key,
          groupValue: _selectedData,
          onChanged: (value) {
            setState(() {
              _selectedData = value!;
            });
          },
          dense: true,
        )),
      ],
    );
  }

  Widget _buildFormatSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Format de fichier',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: AppTheme.fontBold,
          ),
        ),
        const SizedBox(height: 8),
        ...{
          'json': 'JSON',
          'csv': 'CSV',
          'txt': 'Texte',
        }.entries.map((entry) => RadioListTile<String>(
          title: Text(entry.value),
          value: entry.key,
          groupValue: _selectedFormat,
          onChanged: (value) {
            setState(() {
              _selectedFormat = value!;
            });
          },
          dense: true,
        )),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _performExport,
            icon: _isLoading 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download),
            label: const Text('Exporter'),
          ),
        ),
      ],
    );
  }

  Future<void> _performExport() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String content;
      String fileName;
      String mimeType;

      switch (_selectedData) {
        case 'roles':
          if (_selectedFormat == 'json') {
            content = await ExportService.exportRolesToJson(widget.roles);
            fileName = 'roles_${DateTime.now().millisecondsSinceEpoch}.json';
            mimeType = 'application/json';
          } else {
            content = await ExportService.exportRolesToCsv(widget.roles);
            fileName = 'roles_${DateTime.now().millisecondsSinceEpoch}.csv';
            mimeType = 'text/csv';
          }
          break;

        case 'permissions':
          if (_selectedFormat == 'json') {
            content = await ExportService.exportPermissionsToJson(widget.permissions);
            fileName = 'permissions_${DateTime.now().millisecondsSinceEpoch}.json';
            mimeType = 'application/json';
          } else {
            content = await ExportService.exportPermissionsToCsv(widget.permissions);
            fileName = 'permissions_${DateTime.now().millisecondsSinceEpoch}.csv';
            mimeType = 'text/csv';
          }
          break;

        case 'user_roles':
          if (_selectedFormat == 'json') {
            content = await ExportService.exportUserRolesToJson(widget.userRoles, widget.roles);
            fileName = 'user_roles_${DateTime.now().millisecondsSinceEpoch}.json';
            mimeType = 'application/json';
          } else {
            content = await ExportService.exportUserRolesToCsv(widget.userRoles, widget.roles);
            fileName = 'user_roles_${DateTime.now().millisecondsSinceEpoch}.csv';
            mimeType = 'text/csv';
          }
          break;

        case 'matrix':
          content = await ExportService.exportPermissionMatrix(widget.roles, widget.permissions);
          fileName = 'permission_matrix_${DateTime.now().millisecondsSinceEpoch}.csv';
          mimeType = 'text/csv';
          break;

        case 'report':
          content = await ExportService.generateFullReport(widget.roles, widget.permissions, widget.userRoles);
          fileName = 'rapport_complet_${DateTime.now().millisecondsSinceEpoch}.txt';
          mimeType = 'text/plain';
          break;

        default:
          throw Exception('Type de données non supporté');
      }

      await ExportService.saveAndShareFile(content, fileName, mimeType);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export réussi'),
            backgroundColor: AppTheme.greenStandard,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'export: $e'),
            backgroundColor: AppTheme.redStandard,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
