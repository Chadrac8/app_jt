import 'package:flutter/material.dart';
import '../models/permission_model.dart';
import '../../../../theme.dart';

class RoleCard extends StatelessWidget {
  final Role role;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const RoleCard({
    super.key,
    required this.role,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _parseColor(role.color).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Icon(
                      _parseIcon(role.icon),
                      color: _parseColor(role.color),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                role.name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: AppTheme.fontBold,
                                ),
                              ),
                            ),
                            if (role.isSystemRole)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.grey100,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                ),
                                child: Text(
                                  'SYSTÈME',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: AppTheme.fontBold,
                                    color: AppTheme.grey800,
                                  ),
                                ),
                              ),
                            if (!role.isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.grey100,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                ),
                                child: Text(
                                  'INACTIF',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: AppTheme.fontBold,
                                    color: AppTheme.grey800,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          role.description,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.grey600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (onEdit != null || onDelete != null)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            onEdit?.call();
                            break;
                          case 'delete':
                            onDelete?.call();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        if (onEdit != null)
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 8),
                                Text('Modifier'),
                              ],
                            ),
                          ),
                        if (onDelete != null)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: AppTheme.redStandard),
                                SizedBox(width: 8),
                                Text('Supprimer', style: TextStyle(color: AppTheme.redStandard)),
                              ],
                            ),
                          ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Statistiques du rôle
              Row(
                children: [
                  _buildStatChip(
                    Icons.security,
                    '${role.allPermissions.length} permissions',
                    AppTheme.blueStandard,
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    Icons.widgets,
                    '${role.modulePermissions.length} modules',
                    AppTheme.greenStandard,
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Modules avec accès
              if (role.modulePermissions.isNotEmpty) ...[
                Text(
                  'Modules avec accès:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: AppTheme.fontMedium,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: role.modulePermissions.keys.take(5).map((moduleId) {
                    final module = AppModule.findById(moduleId);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      child: Text(
                        module?.name ?? moduleId,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    );
                  }).toList()
                    ..addAll(role.modulePermissions.length > 5 ? [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.grey200,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                        child: Text(
                          '+${role.modulePermissions.length - 5}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.grey500,
                          ),
                        ),
                      ),
                    ] : []),
                ),
              ],
              
              // Informations de création
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: AppTheme.grey600),
                  const SizedBox(width: 4),
                  Text(
                    'Créé le ${_formatDate(role.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.grey600,
                    ),
                  ),
                  if (role.createdBy != null) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.person, size: 14, color: AppTheme.grey600),
                    const SizedBox(width: 4),
                    Text(
                      'par ${role.createdBy}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.grey600,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: AppTheme.fontMedium,
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      // Supprime le # si présent et convertit en couleur
      final hexColor = colorString.replaceAll('#', '');
      return Color(int.parse('FF$hexColor', radix: 16));
    } catch (e) {
      return AppTheme.blueStandard; // Couleur par défaut
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
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
