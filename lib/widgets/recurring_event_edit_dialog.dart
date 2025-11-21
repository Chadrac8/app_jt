import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../theme.dart';

/// Options pour modifier un événement récurrent
enum RecurringEditOption {
  thisOnly,        // Cet événement uniquement
  thisAndFuture,   // Cet événement et les suivants
  all,             // Tous les événements de la série
}

/// Dialog pour choisir comment modifier un événement récurrent
/// (Style Google Calendar / Outlook)
class RecurringEventEditDialog extends StatefulWidget {
  final EventModel event;
  
  const RecurringEventEditDialog({super.key, required this.event});
  
  /// Affiche le dialog et retourne l'option choisie
  static Future<RecurringEditOption?> show(
    BuildContext context,
    EventModel event,
  ) {
    return showDialog<RecurringEditOption>(
      context: context,
      builder: (context) => RecurringEventEditDialog(event: event),
    );
  }

  @override
  State<RecurringEventEditDialog> createState() => _RecurringEventEditDialogState();
}

class _RecurringEventEditDialogState extends State<RecurringEventEditDialog> {
  RecurringEditOption? _selectedOption;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            Icons.edit_calendar,
            color: AppTheme.blueStandard,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Modifier un événement récurrent',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cet événement fait partie d\'une série récurrente.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Comment souhaitez-vous le modifier ?',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            
            // Option 1 : Cet événement uniquement
            _buildOption(
              option: RecurringEditOption.thisOnly,
              icon: Icons.event,
              title: 'Cet événement uniquement',
              description: 'Modifier seulement cette occurrence sans affecter les autres',
            ),
            
            const SizedBox(height: 16),
            
            // Option 2 : Cet événement et les suivants
            _buildOption(
              option: RecurringEditOption.thisAndFuture,
              icon: Icons.event_repeat,
              title: 'Cet événement et les suivants',
              description: 'Modifier cette occurrence et toutes les futures occurrences',
            ),
            
            const SizedBox(height: 16),
            
            // Option 3 : Tous les événements
            _buildOption(
              option: RecurringEditOption.all,
              icon: Icons.calendar_month,
              title: 'Tous les événements de la série',
              description: 'Modifier toutes les occurrences (passées et futures)',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Annuler',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 16,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _selectedOption == null
              ? null
              : () => Navigator.of(context).pop(_selectedOption),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.blueStandard,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey[300],
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Continuer',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOption({
    required RecurringEditOption option,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final isSelected = _selectedOption == option;
    
    return InkWell(
      onTap: () => setState(() => _selectedOption = option),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppTheme.blueStandard : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? AppTheme.blueStandard.withOpacity(0.05) : null,
        ),
        child: Row(
          children: [
            // Radio button
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppTheme.blueStandard : Colors.grey[400]!,
                  width: 2,
                ),
                color: isSelected ? AppTheme.blueStandard : Colors.transparent,
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : null,
            ),
            
            const SizedBox(width: 16),
            
            // Icône
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppTheme.blueStandard.withOpacity(0.1)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppTheme.blueStandard : Colors.grey[600],
                size: 24,
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
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? AppTheme.blueStandard : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
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
}
