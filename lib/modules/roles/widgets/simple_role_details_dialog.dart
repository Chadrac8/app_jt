import 'package:flutter/material.dart';
import '../models/role.dart';
import '../dialogs/create_edit_role_dialog.dart';
import '../../../../theme.dart';

class SimpleRoleDetailsDialog extends StatelessWidget {
  final Role role;

  const SimpleRoleDetailsDialog({
    super.key,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // En-tête
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _parseColor(role.color).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Icon(
                    _parseIcon(role.icon),
                    color: _parseColor(role.color),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: AppTheme.fontBold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        role.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Informations générales
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informations générales',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: AppTheme.fontBold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      Icons.palette,
                      'Couleur',
                      role.color,
                      trailing: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _parseColor(role.color),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.grey300!),
                        ),
                      ),
                    ),
                    _buildInfoRow(
                      Icons.security,
                      'Permissions',
                      '${role.permissions.length} permission(s)',
                    ),
                    _buildInfoRow(
                      Icons.toggle_on,
                      'État',
                      role.isActive ? 'Actif' : 'Inactif',
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: role.isActive ? AppTheme.grey100 : AppTheme.grey100,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                        child: Text(
                          role.isActive ? 'Actif' : 'Inactif',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: AppTheme.fontBold,
                            color: role.isActive ? AppTheme.grey700 : AppTheme.grey700,
                          ),
                        ),
                      ),
                    ),
                    if (role.createdAt != null)
                      _buildInfoRow(
                        Icons.access_time,
                        'Créé le',
                        _formatDate(role.createdAt!),
                      ),
                    if (role.createdBy != null)
                      _buildInfoRow(
                        Icons.person,
                        'Créé par',
                        role.createdBy!,
                      ),
                  ],
                ),
              ),
            ),
            
            // Permissions
            if (role.permissions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Permissions (${role.permissions.length})',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: AppTheme.fontBold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: role.permissions.take(10).map((permission) {
                          return Chip(
                            label: Text(
                              permission,
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          );
                        }).toList(),
                      ),
                      if (role.permissions.length > 10)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '... et ${role.permissions.length - 10} autres',
                            style: TextStyle(
                              color: AppTheme.grey600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            
            // Actions
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fermer'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Ouvrir le dialogue d'édition
                    showDialog(
                      context: context,
                      builder: (context) => CreateEditRoleDialog(existingRole: role),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Modifier'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.grey600),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: const TextStyle(fontWeight: AppTheme.fontMedium),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      final hexColor = colorString.replaceAll('#', '');
      return Color(int.parse('FF$hexColor', radix: 16));
    } catch (e) {
      return AppTheme.blueStandard;
    }
  }

  IconData _parseIcon(String iconName) {
    switch (iconName) {
      case 'admin_panel_settings': return Icons.admin_panel_settings;
      case 'supervisor_account': return Icons.supervisor_account;
      case 'security': return Icons.security;
      case 'person': return Icons.person;
      case 'group': return Icons.group;
      case 'manage_accounts': return Icons.manage_accounts;
      case 'verified_user': return Icons.verified_user;
      case 'shield': return Icons.shield;
      default: return Icons.person;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
