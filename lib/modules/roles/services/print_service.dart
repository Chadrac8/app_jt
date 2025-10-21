import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';
import '../models/role.dart';
import '../models/permission.dart';
import '../models/user_role.dart';
import '../../../../theme.dart';

class PrintService {
  /// Imprimer la liste des rôles
  static Future<void> printRoles(List<Role> roles) async {
    // Génération d'un contenu texte pour l'impression
    final content = _generateRolesText(roles);
    await _showPrintPreview(content, 'Liste des Rôles');
  }

  /// Imprimer la liste des permissions
  static Future<void> printPermissions(List<Permission> permissions) async {
    final content = _generatePermissionsText(permissions);
    await _showPrintPreview(content, 'Liste des Permissions');
  }

  /// Imprimer les assignations d'utilisateurs
  static Future<void> printUserRoles(List<UserRole> userRoles, List<Role> roles) async {
    final content = _generateUserRolesText(userRoles, roles);
    await _showPrintPreview(content, 'Assignations des Rôles');
  }

  /// Imprimer la matrice des permissions
  static Future<void> printPermissionMatrix(List<Role> roles, List<Permission> permissions) async {
    final content = _generatePermissionMatrixText(roles, permissions);
    await _showPrintPreview(content, 'Matrice des Permissions');
  }

  /// Imprimer un rapport complet
  static Future<void> printFullReport(
    List<Role> roles,
    List<Permission> permissions,
    List<UserRole> userRoles,
  ) async {
    final content = _generateFullReportText(roles, permissions, userRoles);
    await _showPrintPreview(content, 'Rapport Complet');
  }

  /// Générer le texte pour les rôles
  static String _generateRolesText(List<Role> roles) {
    final buffer = StringBuffer();
    buffer.writeln('LISTE DES RÔLES');
    buffer.writeln('=' * 50);
    buffer.writeln('Généré le: ${_formatDateTime(DateTime.now())}');
    buffer.writeln();
    
    for (final role in roles) {
      buffer.writeln('Nom: ${role.name}');
      buffer.writeln('Description: ${role.description}');
      buffer.writeln('Statut: ${role.isActive ? 'Actif' : 'Inactif'}');
      buffer.writeln('Permissions: ${role.permissions.length}');
      buffer.writeln('Créé le: ${_formatDateTime(role.createdAt)}');
      buffer.writeln('-' * 30);
    }
    
    return buffer.toString();
  }

  /// Générer le texte pour les permissions
  static String _generatePermissionsText(List<Permission> permissions) {
    final buffer = StringBuffer();
    buffer.writeln('LISTE DES PERMISSIONS');
    buffer.writeln('=' * 50);
    buffer.writeln('Généré le: ${_formatDateTime(DateTime.now())}');
    buffer.writeln();
    
    // Grouper par module
    final permissionsByModule = <String, List<Permission>>{};
    for (final permission in permissions) {
      if (!permissionsByModule.containsKey(permission.module)) {
        permissionsByModule[permission.module] = [];
      }
      permissionsByModule[permission.module]!.add(permission);
    }
    
    for (final entry in permissionsByModule.entries) {
      buffer.writeln('MODULE: ${entry.key.toUpperCase()}');
      buffer.writeln('-' * 30);
      
      for (final permission in entry.value) {
        buffer.writeln('  Nom: ${permission.name}');
        buffer.writeln('  Description: ${permission.description}');
        buffer.writeln('  Action: ${permission.action}');
        buffer.writeln();
      }
      buffer.writeln();
    }
    
    return buffer.toString();
  }

  /// Générer le texte pour les assignations utilisateurs
  static String _generateUserRolesText(List<UserRole> userRoles, List<Role> roles) {
    final buffer = StringBuffer();
    buffer.writeln('ASSIGNATIONS DES RÔLES');
    buffer.writeln('=' * 50);
    buffer.writeln('Généré le: ${_formatDateTime(DateTime.now())}');
    buffer.writeln();
    
    for (final userRole in userRoles) {
      buffer.writeln('Email: ${userRole.userEmail}');
      buffer.writeln('Nom: ${userRole.userName}');
      buffer.writeln('Rôles: ${_getRoleNames(userRole.roleIds, roles)}');
      buffer.writeln('Statut: ${userRole.isActive ? 'Actif' : 'Inactif'}');
      buffer.writeln('Assigné le: ${_formatDateTime(userRole.assignedAt)}');
      if (userRole.expiresAt != null) {
        buffer.writeln('Expire le: ${_formatDateTime(userRole.expiresAt)}');
      }
      buffer.writeln('-' * 30);
    }
    
    return buffer.toString();
  }

  /// Générer le texte pour la matrice des permissions
  static String _generatePermissionMatrixText(List<Role> roles, List<Permission> permissions) {
    final buffer = StringBuffer();
    buffer.writeln('MATRICE DES PERMISSIONS');
    buffer.writeln('=' * 50);
    buffer.writeln('Généré le: ${_formatDateTime(DateTime.now())}');
    buffer.writeln();
    
    // En-tête
    buffer.write('Rôle'.padRight(20));
    for (final permission in permissions.take(10)) { // Limiter pour l'affichage
      buffer.write(permission.name.substring(0, permission.name.length > 8 ? 8 : permission.name.length).padRight(10));
    }
    buffer.writeln();
    buffer.writeln('-' * (20 + (10 * 10)));
    
    // Données
    for (final role in roles) {
      buffer.write(role.name.substring(0, role.name.length > 18 ? 18 : role.name.length).padRight(20));
      for (final permission in permissions.take(10)) {
        buffer.write((role.hasPermission(permission.id) ? 'X' : '').padRight(10));
      }
      buffer.writeln();
    }
    
    return buffer.toString();
  }

  /// Générer le rapport complet
  static String _generateFullReportText(
    List<Role> roles,
    List<Permission> permissions,
    List<UserRole> userRoles,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('RAPPORT COMPLET DES RÔLES ET PERMISSIONS');
    buffer.writeln('=' * 60);
    buffer.writeln('Généré le: ${_formatDateTime(DateTime.now())}');
    buffer.writeln();
    
    // Statistiques générales
    buffer.writeln('STATISTIQUES GÉNÉRALES');
    buffer.writeln('-' * 30);
    buffer.writeln('Nombre total de rôles: ${roles.length}');
    buffer.writeln('Rôles actifs: ${roles.where((r) => r.isActive).length}');
    buffer.writeln('Nombre total de permissions: ${permissions.length}');
    buffer.writeln('Utilisateurs avec des rôles: ${userRoles.where((ur) => ur.isActive).length}');
    buffer.writeln();
    
    // Répartition par module
    buffer.writeln('RÉPARTITION DES PERMISSIONS PAR MODULE');
    buffer.writeln('-' * 40);
    final permissionsByModule = <String, int>{};
    for (final permission in permissions) {
      permissionsByModule[permission.module] = 
          (permissionsByModule[permission.module] ?? 0) + 1;
    }
    
    for (final entry in permissionsByModule.entries) {
      buffer.writeln('${entry.key}: ${entry.value} permissions');
    }
    buffer.writeln();
    
    // Rôles les plus utilisés
    buffer.writeln('RÔLES LES PLUS UTILISÉS');
    buffer.writeln('-' * 30);
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
      buffer.writeln('${role.name}: ${entry.value} utilisateur(s)');
    }
    
    return buffer.toString();
  }

  /// Afficher un aperçu avant impression
  static Future<void> _showPrintPreview(String content, String title) async {
    // Implémentation d'un aperçu simple avec copie dans le presse-papiers
    await Clipboard.setData(ClipboardData(text: content));
  }

  /// Obtenir les noms des rôles
  static String _getRoleNames(List<String> roleIds, List<Role> roles) {
    return roleIds
        .map((roleId) {
          final role = roles.firstWhere(
            (r) => r.id == roleId,
            orElse: () => Role(id: roleId, name: 'Inconnu', description: ''),
          );
          return role.name;
        })
        .join(', ');
  }

  /// Formater la date et l'heure
  static String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Non défini';
    return '${dateTime.day.toString().padLeft(2, '0')}/'
           '${dateTime.month.toString().padLeft(2, '0')}/'
           '${dateTime.year} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

/// Widget pour afficher les options d'impression
class PrintOptionsDialog extends StatefulWidget {
  final List<Role> roles;
  final List<Permission> permissions;
  final List<UserRole> userRoles;

  const PrintOptionsDialog({
    super.key,
    required this.roles,
    required this.permissions,
    required this.userRoles,
  });

  @override
  State<PrintOptionsDialog> createState() => _PrintOptionsDialogState();
}

class _PrintOptionsDialogState extends State<PrintOptionsDialog> {
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
        padding: const EdgeInsets.all(AppTheme.spaceLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: AppTheme.spaceLarge),
            _buildDataSelection(),
            const SizedBox(height: AppTheme.spaceLarge),
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
          padding: const EdgeInsets.all(AppTheme.space12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Icon(
            Icons.print,
            color: Theme.of(context).primaryColor,
            size: 28,
          ),
        ),
        const SizedBox(width: AppTheme.spaceMedium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Imprimer les données',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: AppTheme.fontBold,
                ),
              ),
              Text(
                'Choisissez le type de données à imprimer',
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
          'Données à imprimer',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: AppTheme.fontBold,
          ),
        ),
        const SizedBox(height: AppTheme.spaceSmall),
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

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
        ),
        const SizedBox(width: AppTheme.spaceMedium),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _performPrint,
            icon: _isLoading 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.print),
            label: const Text('Imprimer'),
          ),
        ),
      ],
    );
  }

  Future<void> _performPrint() async {
    setState(() {
      _isLoading = true;
    });

    try {
      switch (_selectedData) {
        case 'roles':
          await PrintService.printRoles(widget.roles);
          break;
        case 'permissions':
          await PrintService.printPermissions(widget.permissions);
          break;
        case 'user_roles':
          await PrintService.printUserRoles(widget.userRoles, widget.roles);
          break;
        case 'matrix':
          await PrintService.printPermissionMatrix(widget.roles, widget.permissions);
          break;
        case 'report':
          await PrintService.printFullReport(widget.roles, widget.permissions, widget.userRoles);
          break;
        default:
          throw Exception('Type de données non supporté');
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impression lancée'),
            backgroundColor: AppTheme.greenStandard,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'impression: $e'),
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
