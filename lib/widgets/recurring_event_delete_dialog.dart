import 'package:flutter/material.dart';
import '../models/event_model.dart';

/// Options pour supprimer un événement récurrent
enum RecurringDeleteOption {
  thisOnly,        // Cet événement uniquement
  thisAndFuture,   // Cet événement et les suivants
  all,             // Tous les événements de la série
}

/// Dialog pour choisir comment supprimer un événement récurrent
/// (Style Google Calendar / Outlook)
class RecurringEventDeleteDialog extends StatefulWidget {
  final EventModel event;
  
  const RecurringEventDeleteDialog({super.key, required this.event});
  
  /// Affiche le dialog et retourne l'option choisie
  static Future<RecurringDeleteOption?> show(
    BuildContext context,
    EventModel event,
  ) {
    return showDialog<RecurringDeleteOption>(
      context: context,
      builder: (context) => RecurringEventDeleteDialog(event: event),
    );
  }

  @override
  State<RecurringEventDeleteDialog> createState() => _RecurringEventDeleteDialogState();
}

class _RecurringEventDeleteDialogState extends State<RecurringEventDeleteDialog> {
  RecurringDeleteOption? _selectedOption;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            Icons.delete_outline,
            color: Colors.red[700],
            size: 28,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Supprimer un événement récurrent',
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.red[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cet événement fait partie d\'une série récurrente.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red[900],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Comment souhaitez-vous le supprimer ?',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            
            // Option 1 : Cet événement uniquement
            _buildOption(
              option: RecurringDeleteOption.thisOnly,
              icon: Icons.event,
              title: 'Cet événement uniquement',
              description: 'Supprimer seulement cette occurrence',
            ),
            
            const SizedBox(height: 16),
            
            // Option 2 : Cet événement et les suivants
            _buildOption(
              option: RecurringDeleteOption.thisAndFuture,
              icon: Icons.event_repeat,
              title: 'Cet événement et les suivants',
              description: 'Supprimer cette occurrence et toutes les futures',
            ),
            
            const SizedBox(height: 16),
            
            // Option 3 : Tous les événements
            _buildOption(
              option: RecurringDeleteOption.all,
              icon: Icons.calendar_month,
              title: 'Tous les événements de la série',
              description: 'Supprimer toutes les occurrences de cette série',
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
            backgroundColor: Colors.red[700],
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey[300],
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Supprimer',
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
    required RecurringDeleteOption option,
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
            color: isSelected ? Colors.red[700]! : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Colors.red[50] : null,
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
                  color: isSelected ? Colors.red[700]! : Colors.grey[400]!,
                  width: 2,
                ),
                color: isSelected ? Colors.red[700] : Colors.transparent,
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
                    ? Colors.red[100]
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.red[700] : Colors.grey[600],
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
                      color: isSelected ? Colors.red[900] : Colors.black87,
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
