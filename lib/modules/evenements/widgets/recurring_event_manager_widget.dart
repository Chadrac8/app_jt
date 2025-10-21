import 'package:flutter/material.dart';
import '../../../models/event_recurrence_model.dart';
import '../../../theme.dart';

/// Widget pour gérer et afficher les occurrences d'un événement récurrent
class RecurringEventManagerWidget extends StatefulWidget {
  final String eventId;
  final EventRecurrenceModel recurrence;
  final Function(EventInstanceModel) onEditInstance;
  final Function(EventInstanceModel) onCancelInstance;

  const RecurringEventManagerWidget({
    Key? key,
    required this.eventId,
    required this.recurrence,
    required this.onEditInstance,
    required this.onCancelInstance,
  }) : super(key: key);

  @override
  State<RecurringEventManagerWidget> createState() => _RecurringEventManagerWidgetState();
}

class _RecurringEventManagerWidgetState extends State<RecurringEventManagerWidget> {
  late List<EventInstanceModel> _instances;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInstances();
  }

  Future<void> _loadInstances() async {
    setState(() => _loading = true);
    // Générer les occurrences à partir du modèle de récurrence
    final dates = widget.recurrence.generateOccurrences(
      startDate: widget.recurrence.createdAt,
      until: widget.recurrence.endDate,
      maxCount: widget.recurrence.occurrenceCount,
    );
    // Simuler la récupération des instances (à adapter selon Firestore)
    _instances = dates.map((date) => EventInstanceModel(
      id: '',
      parentEventId: widget.eventId,
      recurrenceId: widget.recurrence.id,
      originalDate: date,
      actualDate: date,
      createdAt: date,
    )).toList();
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Occurrences générées',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: AppTheme.fontBold),
            ),
          ),
          if (_instances.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Text('Aucune occurrence générée.'),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _instances.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final instance = _instances[index];
                return ListTile(
                  title: Text('Occurrence du ${instance.actualDate.day}/${instance.actualDate.month}/${instance.actualDate.year}'),
                  subtitle: instance.isCancelled ? const Text('Annulée', style: TextStyle(color: Colors.red)) : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        tooltip: 'Modifier cette occurrence',
                        onPressed: () => widget.onEditInstance(instance),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel),
                        tooltip: 'Annuler cette occurrence',
                        onPressed: () => widget.onCancelInstance(instance),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
