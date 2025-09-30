import 'package:flutter/material.dart';
import '../models/permission_model.dart';

/// Widget Card pour afficher un rôle avec Material Design 3
class RoleCardWidget extends StatelessWidget {
  final Role role;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const RoleCardWidget({
    super.key,
    required this.role,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Convertir la couleur du rôle en Color
    final roleColor = _getRoleColor();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                roleColor.withOpacity(0.05),
                roleColor.withOpacity(0.02),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, theme, roleColor),
                const SizedBox(height: 12),
                _buildDescription(context, theme),
                const SizedBox(height: 16),
                _buildPermissionsInfo(context, theme),
                if (onEdit != null || onDelete != null) ...[
                  const SizedBox(height: 16),
                  _buildActionButtons(context, theme),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme, Color roleColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: roleColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getRoleIcon(),
            color: roleColor,
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
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (role.isSystemRole)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'SYSTÈME',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    role.isActive ? Icons.check_circle : Icons.pause_circle,
                    size: 14,
                    color: role.isActive
                        ? theme.colorScheme.primary
                        : theme.colorScheme.error,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    role.isActive ? 'Actif' : 'Inactif',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: role.isActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(BuildContext context, ThemeData theme) {
    return Text(
      role.description,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface.withOpacity(0.7),
        height: 1.4,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildPermissionsInfo(BuildContext context, ThemeData theme) {
    final totalPermissions = role.allPermissions.length;
    final moduleCount = role.modulePermissions.length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              context,
              theme,
              Icons.security,
              'Permissions',
              totalPermissions.toString(),
            ),
          ),
          Container(
            width: 1,
            height: 24,
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
          Expanded(
            child: _buildStatItem(
              context,
              theme,
              Icons.apps,
              'Modules',
              moduleCount.toString(),
            ),
          ),
          Container(
            width: 1,
            height: 24,
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
          Expanded(
            child: _buildStatItem(
              context,
              theme,
              Icons.schedule,
              'Créé',
              _formatDate(role.createdAt),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    ThemeData theme,
    IconData icon,
    String label,
    String value,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (onEdit != null)
          IconButton.filledTonal(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            iconSize: 18,
            tooltip: 'Modifier le rôle',
            style: IconButton.styleFrom(
              minimumSize: const Size(36, 36),
            ),
          ),
        if (onEdit != null && onDelete != null)
          const SizedBox(width: 8),
        if (onDelete != null)
          IconButton.filled(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
            iconSize: 18,
            tooltip: 'Supprimer le rôle',
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.errorContainer,
              foregroundColor: theme.colorScheme.onErrorContainer,
              minimumSize: const Size(36, 36),
            ),
          ),
      ],
    );
  }

  Color _getRoleColor() {
    try {
      // Convertir la couleur hexadécimale en Color
      final hexColor = role.color.replaceAll('#', '');
      return Color(int.parse('FF$hexColor', radix: 16));
    } catch (e) {
      // Couleur par défaut si la conversion échoue
      return Colors.blue;
    }
  }

  IconData _getRoleIcon() {
    switch (role.icon) {
      case 'admin_panel_settings':
        return Icons.admin_panel_settings;
      case 'person':
        return Icons.person;
      case 'group':
        return Icons.group;
      case 'verified_user':
        return Icons.verified_user;
      case 'supervisor_account':
        return Icons.supervisor_account;
      case 'manage_accounts':
        return Icons.manage_accounts;
      case 'security':
        return Icons.security;
      case 'shield':
        return Icons.shield;
      default:
        return Icons.account_circle;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 1) {
      if (difference.inHours < 1) {
        return '${difference.inMinutes}min';
      }
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}j';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}sem';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}mois';
    } else {
      return '${(difference.inDays / 365).floor()}ans';
    }
  }
}