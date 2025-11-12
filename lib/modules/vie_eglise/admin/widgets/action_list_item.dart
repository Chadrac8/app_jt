import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../theme.dart';
import '../../models/pour_vous_action.dart';
import '../../models/action_group.dart';

class ActionListItem extends StatelessWidget {
  final PourVousAction action;
  final List<ActionGroup> groups;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;

  const ActionListItem({
    Key? key,
    required this.action,
    required this.groups,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final group = groups.where((g) => g.id == action.groupId).firstOrNull;
    
    return Card(
      elevation: 1,
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getColorFromString(action.color)?.withValues(alpha: 0.1) ?? AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Icon(
            action.icon,
            color: _getColorFromString(action.color) ?? AppTheme.primaryColor,
            size: 24,
          ),
        ),
        title: Text(
          action.title,
          style: GoogleFonts.inter(
            fontSize: AppTheme.fontSize16,
            fontWeight: AppTheme.fontSemiBold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              action.description,
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize14,
                color: AppTheme.textSecondaryColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppTheme.spaceXSmall),
            Row(
              children: [
                // Type d'action
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceXSmall,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getActionTypeColor(action.actionType).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(
                      color: _getActionTypeColor(action.actionType).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _getActionTypeLabel(action.actionType),
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize10,
                      fontWeight: AppTheme.fontMedium,
                      color: _getActionTypeColor(action.actionType),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceXSmall),
                
                // Catégorie
                if (action.category != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spaceXSmall,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.grey100,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Text(
                      _getCategoryLabel(action.category!),
                      style: GoogleFonts.inter(
                        fontSize: AppTheme.fontSize10,
                        fontWeight: AppTheme.fontMedium,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceXSmall),
                ],
                
                // Groupe
                if (group != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spaceXSmall,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Text(
                      group.name,
                      style: GoogleFonts.inter(
                        fontSize: AppTheme.fontSize10,
                        fontWeight: AppTheme.fontMedium,
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                  ),
                ],
                
                const Spacer(),
                
                // Ordre
                Text(
                  'Ordre: ${action.order}',
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize10,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Statut
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceXSmall,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: action.isActive ? AppTheme.successColor : AppTheme.grey400,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Text(
                action.isActive ? 'Actif' : 'Inactif',
                style: GoogleFonts.inter(
                  fontSize: AppTheme.fontSize10,
                  fontWeight: AppTheme.fontMedium,
                  color: Colors.white,
                ),
              ),
            ),
            
            // Menu des actions
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    onEdit();
                    break;
                  case 'toggle':
                    onToggleStatus();
                    break;
                  case 'delete':
                    onDelete();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Modifier'),
                    dense: true,
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: ListTile(
                    leading: Icon(action.isActive ? Icons.visibility_off : Icons.visibility),
                    title: Text(action.isActive ? 'Désactiver' : 'Activer'),
                    dense: true,
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Supprimer', style: TextStyle(color: Colors.red)),
                    dense: true,
                  ),
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
        onTap: onEdit,
      ),
    );
  }

  Color? _getColorFromString(String? colorString) {
    if (colorString == null) return null;
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return null;
    }
  }

  Color _getActionTypeColor(String actionType) {
    switch (actionType) {
      case 'navigation':
        return AppTheme.primaryColor;
      case 'form':
        return AppTheme.secondaryColor;
      case 'external':
        return AppTheme.warningColor;
      case 'contact':
        return AppTheme.tertiaryColor;
      case 'info':
        return AppTheme.infoColor;
      default:
        return AppTheme.grey600;
    }
  }

  String _getActionTypeLabel(String actionType) {
    switch (actionType) {
      case 'navigation':
        return 'Navigation';
      case 'form':
        return 'Formulaire';
      case 'external':
        return 'Externe';
      case 'contact':
        return 'Contact';
      case 'info':
        return 'Info';
      default:
        return actionType;
    }
  }

  String _getCategoryLabel(String category) {
    const categoryLabels = {
      'seigneur': 'Seigneur',
      'pasteur': 'Pasteur',
      'culte': 'Culte',
      'formation': 'Formation',
      'communaute': 'Communauté',
      'general': 'Général',
    };
    return categoryLabels[category] ?? category;
  }
}