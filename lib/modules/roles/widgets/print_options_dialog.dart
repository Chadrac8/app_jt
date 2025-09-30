import 'package:flutter/material.dart';
import '../models/role.dart';
import '../models/permission.dart';
import '../models/user_role.dart';
import '../services/print_service.dart';
import '../../../../theme.dart';

class PrintOptionsDialog extends StatelessWidget {
  final List<Role> roles;
  final List<String> permissions;
  final List<UserRole> userRoles;

  const PrintOptionsDialog({
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
          Icon(Icons.print, color: theme.primaryColor),
          const SizedBox(width: 8),
          const Text('Options d\'impression'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Choisissez le type de données à imprimer :',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          _buildPrintOption(
            context,
            'Rôles',
            'Imprimer tous les rôles',
            Icons.admin_panel_settings,
            () => _printRoles(context),
          ),
          const SizedBox(height: 12),
          _buildPrintOption(
            context,
            'Permissions',
            'Imprimer toutes les permissions',
            Icons.security,
            () => _printPermissions(context),
          ),
          const SizedBox(height: 12),
          _buildPrintOption(
            context,
            'Affectations',
            'Imprimer les affectations de rôles',
            Icons.assignment_ind,
            () => _printUserRoles(context),
          ),
          const SizedBox(height: 12),
          _buildPrintOption(
            context,
            'Rapport complet',
            'Imprimer un rapport détaillé',
            Icons.description,
            () => _printFullReport(context),
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

  Widget _buildPrintOption(
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

  void _printRoles(BuildContext context) async {
    try {
      await PrintService.printRoles(roles);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impression des rôles lancée')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur d\'impression: $e')),
        );
      }
    }
  }

  void _printPermissions(BuildContext context) async {
    try {
      // Convertir les permissions string en objets Permission
      final permissionObjects = permissions.map((p) => Permission(
        id: p,
        name: p,
        description: 'Permission $p',
        module: p.split('_').first,
        action: p.split('_').last,
      )).toList();
      
      await PrintService.printPermissions(permissionObjects);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impression des permissions lancée')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur d\'impression: $e')),
        );
      }
    }
  }

  void _printUserRoles(BuildContext context) async {
    try {
      await PrintService.printUserRoles(userRoles, roles);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impression des affectations lancée')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur d\'impression: $e')),
        );
      }
    }
  }

  void _printFullReport(BuildContext context) async {
    try {
      // Convertir les permissions string en objets Permission
      final permissionObjects = permissions.map((p) => Permission(
        id: p,
        name: p,
        description: 'Permission $p',
        module: p.split('_').first,
        action: p.split('_').last,
      )).toList();
      
      await PrintService.printFullReport(roles, permissionObjects, userRoles);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impression du rapport complet lancée')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur d\'impression: $e')),
        );
      }
    }
  }
}
