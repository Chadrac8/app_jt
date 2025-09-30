import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../models/event_recurrence_model.dart';
import '../services/event_recurrence_service.dart';
import '../../theme.dart';

/// Widget pour gérer les événements récurrents existants
/// Permet de voir, modifier ou supprimer des occurrences
class RecurringEventManagerWidget extends StatefulWidget {
  final String eventId;
  final EventModel parentEvent;

  const RecurringEventManagerWidget({
    Key? key,
    required this.eventId,
    required this.parentEvent,
  }) : super(key: key);

  @override
  State<RecurringEventManagerWidget> createState() => _RecurringEventManagerWidgetState();
}

class _RecurringEventManagerWidgetState extends State<RecurringEventManagerWidget> {
  List<EventRecurrenceModel> _recurrences = [];
  List<EventInstanceModel> _instances = [];
  bool _isLoading = true;
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final recurrences = await EventRecurrenceService.getEventRecurrences(widget.eventId);
      final instances = await EventRecurrenceService.getEventInstances(
        eventId: widget.eventId,
        startDate: DateTime(_selectedMonth.year, _selectedMonth.month, 1),
        endDate: DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0),
      );
      
      setState(() {
        _recurrences = recurrences;
        _instances = instances;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_recurrences.isEmpty)
          _buildNoRecurrenceMessage()
        else ...[
          _buildMonthNavigator(),
          const SizedBox(height: 16),
          _buildRecurrencesList(),
          const SizedBox(height: 16),
          _buildInstancesCalendar(),
        ],
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(Icons.repeat, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Text(
          'Gestion des récurrences',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: AppTheme.fontBold,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadData,
          tooltip: 'Actualiser',
        ),
      ],
    );
  }

  Widget _buildNoRecurrenceMessage() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              Icons.event_busy,
              size: 48,
              color: AppTheme.grey500,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune récurrence configurée',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Cet événement n\'a pas de récurrence définie.',
              style: TextStyle(color: AppTheme.grey500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthNavigator() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () {
                setState(() {
                  _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
                });
                _loadData();
              },
            ),
            Expanded(
              child: Text(
                _getMonthYearText(_selectedMonth),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: AppTheme.fontBold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: () {
                setState(() {
                  _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                });
                _loadData();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurrencesList() {
    return Card(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Icon(Icons.settings, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Règles de récurrence (${_recurrences.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: AppTheme.fontBold,
                  ),
                ),
              ],
            ),
          ),
          ...(_recurrences.map((recurrence) => _buildRecurrenceItem(recurrence))),
        ],
      ),
    );
  }

  Widget _buildRecurrenceItem(EventRecurrenceModel recurrence) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: recurrence.isActive ? AppTheme.greenStandard : AppTheme.grey500,
          shape: BoxShape.circle,
        ),
        child: Icon(
          _getRecurrenceIcon(recurrence.type),
          color: AppTheme.white100,
          size: 20,
        ),
      ),
      title: Text(
        _getRecurrenceDescription(recurrence),
        style: TextStyle(
          decoration: recurrence.isActive ? null : TextDecoration.lineThrough,
          color: recurrence.isActive ? null : AppTheme.grey500,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Type: ${_getTypeLabel(recurrence.type)}',
            style: TextStyle(
              color: recurrence.isActive ? null : AppTheme.grey500,
            ),
          ),
          if (recurrence.endDate != null)
            Text(
              'Fin: ${recurrence.endDate!.day}/${recurrence.endDate!.month}/${recurrence.endDate!.year}',
              style: TextStyle(
                color: recurrence.isActive ? null : AppTheme.grey500,
              ),
            ),
          if (recurrence.occurrenceCount != null)
            Text(
              'Occurrences: ${recurrence.occurrenceCount}',
              style: TextStyle(
                color: recurrence.isActive ? null : AppTheme.grey500,
              ),
            ),
          if (!recurrence.isActive)
            Text(
              'Récurrence désactivée',
              style: TextStyle(
                color: AppTheme.orangeStandard,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: recurrence.isActive,
            onChanged: (value) => _toggleRecurrence(recurrence, value),
          ),
          PopupMenuButton<String>(
            onSelected: (action) => _handleRecurrenceAction(recurrence, action),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Modifier')),
              const PopupMenuItem(value: 'exceptions', child: Text('Exceptions')),
              const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstancesCalendar() {
    return Card(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_month, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Occurrences du mois (${_instances.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: AppTheme.fontBold,
                  ),
                ),
              ],
            ),
          ),
          if (_instances.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'Aucune occurrence ce mois-ci',
                style: TextStyle(color: AppTheme.grey500),
              ),
            )
          else
            ...(_instances.map((instance) => _buildInstanceItem(instance))),
        ],
      ),
    );
  }

  Widget _buildInstanceItem(EventInstanceModel instance) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: instance.isCancelled 
              ? AppTheme.redStandard 
              : instance.isOverride 
                  ? AppTheme.orangeStandard 
                  : AppTheme.blueStandard,
          shape: BoxShape.circle,
        ),
        child: Icon(
          instance.isCancelled 
              ? Icons.cancel
              : instance.isOverride 
                  ? Icons.edit
                  : Icons.event,
          color: AppTheme.white100,
          size: 20,
        ),
      ),
      title: Text(
        '${instance.actualDate.day}/${instance.actualDate.month}/${instance.actualDate.year}',
        style: TextStyle(
          decoration: instance.isCancelled ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text(
        instance.isCancelled 
            ? 'Occurrence annulée'
            : instance.isOverride 
                ? 'Occurrence modifiée'
                : 'Occurrence normale',
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (action) => _handleInstanceAction(instance, action),
        itemBuilder: (context) => [
          if (!instance.isCancelled) ...[
            const PopupMenuItem(value: 'modify', child: Text('Modifier')),
            const PopupMenuItem(value: 'cancel', child: Text('Annuler')),
          ],
          if (instance.isCancelled)
            const PopupMenuItem(value: 'restore', child: Text('Restaurer')),
          const PopupMenuItem(value: 'details', child: Text('Détails')),
        ],
      ),
    );
  }

  IconData _getRecurrenceIcon(RecurrenceType type) {
    switch (type) {
      case RecurrenceType.daily:
        return Icons.today;
      case RecurrenceType.weekly:
        return Icons.date_range;
      case RecurrenceType.monthly:
        return Icons.calendar_today;
      case RecurrenceType.yearly:
        return Icons.event_note;
      case RecurrenceType.custom:
        return Icons.settings;
    }
  }

  String _getTypeLabel(RecurrenceType type) {
    switch (type) {
      case RecurrenceType.daily:
        return 'Quotidien';
      case RecurrenceType.weekly:
        return 'Hebdomadaire';
      case RecurrenceType.monthly:
        return 'Mensuel';
      case RecurrenceType.yearly:
        return 'Annuel';
      case RecurrenceType.custom:
        return 'Personnalisé';
    }
  }

  String _getRecurrenceDescription(EventRecurrenceModel recurrence) {
    String description = '';
    
    switch (recurrence.type) {
      case RecurrenceType.daily:
        description = recurrence.interval == 1 
            ? 'Tous les jours'
            : 'Tous les ${recurrence.interval} jours';
        break;
      case RecurrenceType.weekly:
        description = recurrence.interval == 1 
            ? 'Toutes les semaines'
            : 'Toutes les ${recurrence.interval} semaines';
        break;
      case RecurrenceType.monthly:
        description = recurrence.interval == 1 
            ? 'Tous les mois'
            : 'Tous les ${recurrence.interval} mois';
        break;
      case RecurrenceType.yearly:
        description = recurrence.interval == 1 
            ? 'Tous les ans'
            : 'Tous les ${recurrence.interval} ans';
        break;
      case RecurrenceType.custom:
        description = 'Récurrence personnalisée';
        break;
    }
    
    return description;
  }

  String _getMonthYearText(DateTime date) {
    const months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  Future<void> _toggleRecurrence(EventRecurrenceModel recurrence, bool isActive) async {
    try {
      await EventRecurrenceService.updateRecurrence(
        recurrence.copyWith(isActive: isActive),
      );
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _handleRecurrenceAction(EventRecurrenceModel recurrence, String action) {
    switch (action) {
      case 'edit':
        _showEditRecurrenceDialog(recurrence);
        break;
      case 'exceptions':
        _showExceptionsDialog(recurrence);
        break;
      case 'delete':
        _showDeleteRecurrenceDialog(recurrence);
        break;
    }
  }

  void _handleInstanceAction(EventInstanceModel instance, String action) {
    switch (action) {
      case 'modify':
        _showModifyInstanceDialog(instance);
        break;
      case 'cancel':
        _cancelInstance(instance);
        break;
      case 'restore':
        _restoreInstance(instance);
        break;
      case 'details':
        _showInstanceDetails(instance);
        break;
    }
  }

  void _showEditRecurrenceDialog(EventRecurrenceModel recurrence) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier la récurrence'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Modification de récurrence'),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Récurrence active: '),
                Switch(
                  value: recurrence.isActive,
                  onChanged: (value) {
                    Navigator.pop(context);
                    _toggleRecurrence(recurrence, value);
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Pour l'instant, on propose juste l'activation/désactivation
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Utilisez l\'interrupteur pour activer/désactiver')),
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showExceptionsDialog(EventRecurrenceModel recurrence) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gestion des exceptions'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Column(
            children: [
              const Text('Dates d\'exception (événement annulé ces jours-là):'),
              const SizedBox(height: 16),
              Expanded(
                child: recurrence.exceptions.isEmpty
                    ? const Center(child: Text('Aucune exception définie'))
                    : ListView.builder(
                        itemCount: recurrence.exceptions.length,
                        itemBuilder: (context, index) {
                          final exception = recurrence.exceptions[index];
                          return ListTile(
                            title: Text('${exception.day}/${exception.month}/${exception.year}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                final updatedExceptions = List<DateTime>.from(recurrence.exceptions);
                                updatedExceptions.removeAt(index);
                                final updatedRecurrence = recurrence.copyWith(exceptions: updatedExceptions);
                                EventRecurrenceService.updateRecurrence(updatedRecurrence).then((_) {
                                  _loadData();
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Exception supprimée')),
                                  );
                                });
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                final updatedExceptions = List<DateTime>.from(recurrence.exceptions);
                updatedExceptions.add(date);
                final updatedRecurrence = recurrence.copyWith(exceptions: updatedExceptions);
                EventRecurrenceService.updateRecurrence(updatedRecurrence).then((_) {
                  _loadData();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Exception ajoutée')),
                  );
                });
              }
            },
            child: const Text('Ajouter exception'),
          ),
        ],
      ),
    );
  }

  void _showDeleteRecurrenceDialog(EventRecurrenceModel recurrence) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la récurrence'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer cette récurrence ? '
          'Toutes les occurrences futures seront supprimées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await EventRecurrenceService.deleteRecurrence(recurrence.id);
                _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Récurrence supprimée')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.redStandard),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showModifyInstanceDialog(EventInstanceModel instance) {
    // TODO: Implémenter la modification d'instance
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier l\'occurrence'),
        content: const Text('Fonctionnalité en cours de développement'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _cancelInstance(EventInstanceModel instance) {
    // TODO: Implémenter l'annulation d'instance
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonctionnalité en cours de développement')),
    );
  }

  void _restoreInstance(EventInstanceModel instance) {
    // TODO: Implémenter la restauration d'instance
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonctionnalité en cours de développement')),
    );
  }

  void _showInstanceDetails(EventInstanceModel instance) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détails de l\'occurrence'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date originale: ${instance.originalDate.day}/${instance.originalDate.month}/${instance.originalDate.year}'),
            Text('Date effective: ${instance.actualDate.day}/${instance.actualDate.month}/${instance.actualDate.year}'),
            Text('Statut: ${instance.isCancelled ? "Annulée" : instance.isOverride ? "Modifiée" : "Normale"}'),
            if (instance.overrideData.isNotEmpty)
              Text('Modifications: ${instance.overrideData.length} champ(s)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
