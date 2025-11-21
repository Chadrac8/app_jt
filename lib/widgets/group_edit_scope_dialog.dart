import 'package:flutter/material.dart';
import '../models/recurrence_config.dart';

/// Dialog permettant à l'utilisateur de choisir la portée de modification
/// d'une réunion de groupe récurrente (style Google Calendar)
/// 
/// Utilisé avant modification pour déterminer si on modifie :
/// - Une seule occurrence (GroupEditScope.thisOccurrenceOnly)
/// - Cette occurrence et les suivantes (GroupEditScope.thisAndFutureOccurrences)
/// - Toutes les occurrences (GroupEditScope.allOccurrences)
/// 
/// Usage:
/// ```dart
/// final scope = await GroupEditScopeDialog.show(
///   context,
///   groupName: 'Jeunes Adultes',
///   occurrenceDate: DateTime.now(),
/// );
/// 
/// if (scope != null) {
///   // Appliquer modification selon scope
///   await GroupsEventsFacade.updateGroupWithScope(
///     groupId: groupId,
///     updates: {...},
///     scope: scope,
///     occurrenceDate: occurrenceDate,
///   );
/// }
/// ```
class GroupEditScopeDialog extends StatefulWidget {
  /// Nom du groupe récurrent
  final String groupName;
  
  /// Date de l'occurrence sélectionnée (pour "cette occurrence uniquement")
  final DateTime? occurrenceDate;
  
  /// Afficher l'option "Cette occurrence et les suivantes"
  final bool showFutureOption;

  const GroupEditScopeDialog({
    Key? key,
    required this.groupName,
    this.occurrenceDate,
    this.showFutureOption = true,
  }) : super(key: key);

  @override
  State<GroupEditScopeDialog> createState() => _GroupEditScopeDialogState();
  
  /// Affiche le dialog et retourne le choix de l'utilisateur
  /// 
  /// Returns:
  /// - GroupEditScope.thisOccurrenceOnly : Modifier une seule occurrence
  /// - GroupEditScope.thisAndFutureOccurrences : Cette occurrence et suivantes
  /// - GroupEditScope.allOccurrences : Toutes les occurrences
  /// - null : Utilisateur a annulé
  static Future<GroupEditScope?> show(
    BuildContext context, {
    required String groupName,
    DateTime? occurrenceDate,
    bool showFutureOption = true,
  }) {
    return showDialog<GroupEditScope>(
      context: context,
      barrierDismissible: true,
      builder: (context) => GroupEditScopeDialog(
        groupName: groupName,
        occurrenceDate: occurrenceDate,
        showFutureOption: showFutureOption,
      ),
    );
  }
}

class _GroupEditScopeDialogState extends State<GroupEditScopeDialog> {
  GroupEditScope? _selectedScope;

  @override
  void initState() {
    super.initState();
    // Sélectionner par défaut "Cette occurrence uniquement" pour être safe
    _selectedScope = GroupEditScope.thisOccurrenceOnly;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.event_repeat,
            color: colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Modifier une réunion récurrente',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Message explicatif
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cette réunion fait partie d\'une série récurrente.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Comment souhaitez-vous modifier ce groupe ?',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Option 1: Cette occurrence uniquement
            _buildOption(
              scope: GroupEditScope.thisOccurrenceOnly,
              icon: Icons.event,
              title: 'Cette occurrence uniquement',
              subtitle: widget.occurrenceDate != null
                  ? 'Modifier uniquement la réunion du ${_formatDate(widget.occurrenceDate!)}'
                  : 'Modifier uniquement cette réunion',
              theme: theme,
            ),
            
            const SizedBox(height: 12),
            
            // Option 2: Cette occurrence et les suivantes (si activé)
            if (widget.showFutureOption) ...[
              _buildOption(
                scope: GroupEditScope.thisAndFutureOccurrences,
                icon: Icons.arrow_forward,
                title: 'Cette occurrence et les suivantes',
                subtitle: 'Modifier cette réunion et toutes les réunions futures',
                theme: theme,
              ),
              const SizedBox(height: 12),
            ],
            
            // Option 3: Toutes les occurrences
            _buildOption(
              scope: GroupEditScope.allOccurrences,
              icon: Icons.event_repeat,
              title: 'Toutes les occurrences',
              subtitle: 'Modifier toutes les réunions (passées et futures)',
              theme: theme,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _selectedScope != null
              ? () => Navigator.of(context).pop(_selectedScope)
              : null,
          child: const Text('Continuer'),
        ),
      ],
    );
  }

  Widget _buildOption({
    required GroupEditScope scope,
    required IconData icon,
    required String title,
    required String subtitle,
    required ThemeData theme,
  }) {
    final isSelected = _selectedScope == scope;
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedScope = scope;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? colorScheme.primary.withOpacity(0.05)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            // Icône
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary.withOpacity(0.1)
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Texte
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? colorScheme.primary : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            
            // Radio
            Radio<GroupEditScope>(
              value: scope,
              groupValue: _selectedScope,
              onChanged: (value) {
                setState(() {
                  _selectedScope = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
