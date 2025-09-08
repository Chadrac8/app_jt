import 'package:flutter/material.dart';
import '../models/role.dart';
import '../dialogs/create_edit_role_dialog.dart';

class RoleDetailsDialog extends StatelessWidget {
  final Role role;

  const RoleDetailsDialog({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRoleInfo(context),
                    const SizedBox(height: 24),
                    _buildPermissionsInfo(context),
                    const SizedBox(height: 24),
                    _buildStatistics(context),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _parseColor(role.color).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _parseIcon(role.icon),
            color: _parseColor(role.color),
            size: 32,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      role.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (role.isSystemRole)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'SYSTÈME',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[800],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                role.description,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: role.isActive ? Colors.green[100] : Colors.red[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          role.isActive ? Icons.check_circle : Icons.cancel,
                          size: 16,
                          color: role.isActive ? Colors.green[700] : Colors.red[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          role.isActive ? 'Actif' : 'Inactif',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: role.isActive ? Colors.green[700] : Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildRoleInfo(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations générales',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.access_time,
              'Créé le',
              _formatDate(role.createdAt),
            ),
            if (role.createdBy != null)
              _buildInfoRow(
                Icons.person,
                'Créé par',
                role.createdBy!,
              ),
            if (role.updatedAt != role.createdAt)
              _buildInfoRow(
                Icons.update,
                'Modifié le',
                _formatDate(role.updatedAt),
              ),
            if (role.lastModifiedBy != null)
              _buildInfoRow(
                Icons.edit,
                'Modifié par',
                role.lastModifiedBy!,
              ),
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
                  border: Border.all(color: Colors.grey[300]!),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsInfo(BuildContext context) {
    return Consumer<PermissionProvider>(
      builder: (context, provider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Permissions par module',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${role.allPermissions.length} permissions',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                if (role.modulePermissions.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange[600]),
                        const SizedBox(width: 8),
                        const Text('Aucune permission assignée à ce rôle'),
                      ],
                    ),
                  )
                else
                  ...role.modulePermissions.entries.map((entry) {
                    final moduleId = entry.key;
                    final permissionIds = entry.value;
                    final module = AppModule.findById(moduleId);
                    final permissions = permissionIds
                        .map((id) => provider.getPermissionById(id))
                        .where((p) => p != null)
                        .cast<Permission>()
                        .toList();
                    
                    return _buildModulePermissionCard(module, permissions);
                  }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModulePermissionCard(AppModule? module, List<Permission> permissions) {
    if (module == null) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        leading: Icon(_getModuleIcon(module.icon)),
        title: Text(module.name),
        subtitle: Text('${permissions.length} permissions'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: permissions.map((permission) {
                return ListTile(
                  dense: true,
                  leading: Icon(
                    _getPermissionLevelIcon(permission.level),
                    color: _getPermissionLevelColor(permission.level),
                    size: 20,
                  ),
                  title: Text(permission.name),
                  subtitle: Text(permission.description),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPermissionLevelColor(permission.level).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      permission.level.displayName,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getPermissionLevelColor(permission.level),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics(BuildContext context) {
    final permissionsByLevel = <PermissionLevel, int>{};
    
    return Consumer<PermissionProvider>(
      builder: (context, provider, child) {
        // Calculer les statistiques
        for (final permissionId in role.allPermissions) {
          final permission = provider.getPermissionById(permissionId);
          if (permission != null) {
            permissionsByLevel[permission.level] = 
                (permissionsByLevel[permission.level] ?? 0) + 1;
          }
        }
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statistiques des permissions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Modules',
                        '${role.modulePermissions.length}',
                        Icons.widgets,
                        Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Total permissions',
                        '${role.allPermissions.length}',
                        Icons.security,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (permissionsByLevel.isNotEmpty) ...[
                  Text(
                    'Répartition par niveau',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...PermissionLevel.values.map((level) {
                    final count = permissionsByLevel[level] ?? 0;
                    if (count == 0) return const SizedBox.shrink();
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            _getPermissionLevelIcon(level),
                            size: 16,
                            color: _getPermissionLevelColor(level),
                          ),
                          const SizedBox(width: 8),
                          Text(level.displayName),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getPermissionLevelColor(level).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _getPermissionLevelColor(level),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
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
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500),
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

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ),
        if (!role.isSystemRole) ...[
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
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
          ),
        ],
      ],
    );
  }

  Color _parseColor(String colorString) {
    try {
      final hexColor = colorString.replaceAll('#', '');
      return Color(int.parse('FF$hexColor', radix: 16));
    } catch (e) {
      return Colors.blue;
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

  IconData _getModuleIcon(String iconName) {
    switch (iconName) {
      case 'dashboard': return Icons.dashboard;
      case 'people': return Icons.people;
      case 'group': return Icons.group;
      case 'event': return Icons.event;
      case 'church': return Icons.church;
      case 'task': return Icons.task;
      case 'article': return Icons.article;
      case 'monetization_on': return Icons.monetization_on;
      case 'music_note': return Icons.music_note;
      case 'menu_book': return Icons.menu_book;
      case 'description': return Icons.description;
      case 'web': return Icons.web;
      case 'favorite': return Icons.favorite;
      case 'settings': return Icons.settings;
      case 'admin_panel_settings': return Icons.admin_panel_settings;
      default: return Icons.extension;
    }
  }

  IconData _getPermissionLevelIcon(PermissionLevel level) {
    switch (level) {
      case PermissionLevel.read: return Icons.visibility;
      case PermissionLevel.write: return Icons.edit;
      case PermissionLevel.create: return Icons.add;
      case PermissionLevel.delete: return Icons.delete;
      case PermissionLevel.admin: return Icons.admin_panel_settings;
    }
  }

  Color _getPermissionLevelColor(PermissionLevel level) {
    switch (level) {
      case PermissionLevel.read: return Colors.blue;
      case PermissionLevel.write: return Colors.green;
      case PermissionLevel.create: return Colors.orange;
      case PermissionLevel.delete: return Colors.red;
      case PermissionLevel.admin: return Colors.purple;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
