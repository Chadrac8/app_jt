import 'package:flutter/material.dart';

/// Énumération des options de modification pour un service récurrent
enum RecurringEditScope {
  /// Modifier uniquement cette occurrence
  thisOnly,
  
  /// Modifier toutes les occurrences de la série
  all,
}

/// Dialog permettant à l'utilisateur de choisir la portée de modification
/// d'un service récurrent (style Google Calendar)
/// 
/// Utilisé avant d'ouvrir la page de modification pour déterminer si on modifie :
/// - Une seule occurrence (EventDetailPage)
/// - Toutes les occurrences (ServiceDetailPage)
class RecurringServiceEditDialog extends StatefulWidget {
  /// Titre du service récurrent
  final String serviceTitle;
  
  /// Date de l'occurrence sélectionnée (optionnel)
  final DateTime? occurrenceDate;
  
  /// Afficher l'option "Cette occurrence et les suivantes" (future feature)
  final bool showFutureOption;

  const RecurringServiceEditDialog({
    super.key,
    required this.serviceTitle,
    this.occurrenceDate,
    this.showFutureOption = false,
  });

  @override
  State<RecurringServiceEditDialog> createState() => _RecurringServiceEditDialogState();
  
  /// Affiche le dialog et retourne le choix de l'utilisateur
  /// 
  /// Returns:
  /// - RecurringEditScope.thisOnly si l'utilisateur veut modifier une seule occurrence
  /// - RecurringEditScope.all si l'utilisateur veut modifier toutes les occurrences
  /// - null si l'utilisateur annule
  static Future<RecurringEditScope?> show(
    BuildContext context, {
    required String serviceTitle,
    DateTime? occurrenceDate,
    bool showFutureOption = false,
  }) {
    return showDialog<RecurringEditScope>(
      context: context,
      barrierDismissible: true,
      builder: (context) => RecurringServiceEditDialog(
        serviceTitle: serviceTitle,
        occurrenceDate: occurrenceDate,
        showFutureOption: showFutureOption,
      ),
    );
  }
}

class _RecurringServiceEditDialogState extends State<RecurringServiceEditDialog> {
  RecurringEditScope? _selectedScope;

  @override
  void initState() {
    super.initState();
    // Sélectionner par défaut "Cette occurrence uniquement" pour être safe
    _selectedScope = RecurringEditScope.thisOnly;
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
              'Modifier un service récurrent',
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
            // Message d'information
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ce service se répète. Que souhaitez-vous modifier ?',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Titre du service
            Text(
              widget.serviceTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            
            if (widget.occurrenceDate != null) ...[
              const SizedBox(height: 4),
              Text(
                _formatDate(widget.occurrenceDate!),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Options de modification
            _buildOption(
              context: context,
              scope: RecurringEditScope.thisOnly,
              icon: Icons.event,
              title: 'Cette occurrence uniquement',
              description: 'Personnaliser cette occurrence sans affecter les autres',
            ),
            
            const SizedBox(height: 12),
            
            _buildOption(
              context: context,
              scope: RecurringEditScope.all,
              icon: Icons.event_repeat,
              title: 'Toutes les occurrences',
              description: 'Modifier toutes les occurrences de cette série',
            ),
            
            // Future feature: "Cette occurrence et les suivantes"
            if (widget.showFutureOption) ...[
              const SizedBox(height: 12),
              Opacity(
                opacity: 0.5,
                child: _buildOption(
                  context: context,
                  scope: null, // Désactivé pour l'instant
                  icon: Icons.event_available,
                  title: 'Cette occurrence et les suivantes',
                  description: 'Modifier cette occurrence et toutes celles à venir',
                  enabled: false,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        // Bouton Annuler
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(
            'Annuler',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        
        // Bouton Continuer
        FilledButton.icon(
          onPressed: _selectedScope != null
              ? () => Navigator.of(context).pop(_selectedScope)
              : null,
          icon: const Icon(Icons.arrow_forward, size: 18),
          label: const Text('Continuer'),
        ),
      ],
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required RecurringEditScope? scope,
    required IconData icon,
    required String title,
    required String description,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _selectedScope == scope;

    return InkWell(
      onTap: enabled
          ? () {
              setState(() {
                _selectedScope = scope;
              });
            }
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withOpacity(0.5)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Radio button
            Radio<RecurringEditScope?>(
              value: scope,
              groupValue: _selectedScope,
              onChanged: enabled
                  ? (value) {
                      setState(() {
                        _selectedScope = value;
                      });
                    }
                  : null,
              activeColor: colorScheme.primary,
            ),
            
            const SizedBox(width: 8),
            
            // Icon
            Container(
              padding: const EdgeInsets.all(8),
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
            
            const SizedBox(width: 12),
            
            // Textes
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: enabled
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: enabled
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.onSurfaceVariant.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final difference = dateOnly.difference(today).inDays;

    final months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];

    final weekdays = [
      'lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'
    ];

    String baseDate = '${weekdays[date.weekday - 1]} ${date.day} ${months[date.month - 1]} ${date.year}';

    if (difference == 0) {
      return '📍 Aujourd\'hui · $baseDate';
    } else if (difference == 1) {
      return '📅 Demain · $baseDate';
    } else if (difference > 1 && difference <= 7) {
      return '📅 Dans $difference jours · $baseDate';
    } else if (difference < 0 && difference >= -7) {
      return '📅 Il y a ${-difference} jours · $baseDate';
    }

    return baseDate;
  }
}
