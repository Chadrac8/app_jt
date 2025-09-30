import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../../theme.dart';

/// Widget pour afficher une carte d'événement avec support des récurrences
class RecurringEventCard extends StatelessWidget {
  final EventModel event;
  final Map<String, dynamic>? instanceData; // Données spécifiques à l'instance récurrente
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelectionMode;
  final bool isSelected;
  final ValueChanged<bool>? onSelectionChanged;

  const RecurringEventCard({
    Key? key,
    required this.event,
    this.instanceData,
    this.onTap,
    this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelectionChanged,
  }) : super(key: key);

  bool get isRecurringInstance => instanceData?['isRecurringInstance'] == true;
  String? get recurrenceDescription => instanceData?['recurrenceDescription'];
  DateTime? get instanceDate => instanceData?['instanceDate'];

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 8 : 2,
      color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
      child: InkWell(
        onTap: isSelectionMode ? _toggleSelection : onTap,
        onLongPress: isSelectionMode ? null : onLongPress,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 8),
              _buildContent(context),
              const SizedBox(height: 12),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        // Icône de type d'événement
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getTypeColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Icon(
            _getTypeIcon(),
            color: _getTypeColor(),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        
        // Titre et indicateur de récurrence
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: AppTheme.fontSemiBold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isRecurringInstance) _buildRecurrenceChip(context),
                ],
              ),
              if (isRecurringInstance && recurrenceDescription != null) ...[
                const SizedBox(height: 4),
                Text(
                  recurrenceDescription!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.grey700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
        
        // Checkbox de sélection
        if (isSelectionMode)
          Checkbox(
            value: isSelected,
            onChanged: (value) => _toggleSelection(),
          ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date et heure
        Row(
          children: [
            Icon(
              Icons.schedule,
              size: 16,
              color: AppTheme.grey600,
            ),
            const SizedBox(width: 4),
            Text(
              _formatDateTime(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.grey700,
              ),
            ),
          ],
        ),
        
        // Lieu
        if (event.location.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 16,
                color: AppTheme.grey600,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  event.location,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.grey700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
        
        // Description
        if (event.description.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            event.description,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Row(
      children: [
        // Statut
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Text(
            event.statusLabel,
            style: TextStyle(
              color: _getStatusColor(),
              fontSize: 12,
              fontWeight: AppTheme.fontMedium,
            ),
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Type
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.grey200,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Text(
            event.typeLabel,
            style: TextStyle(
              color: AppTheme.grey700,
              fontSize: 12,
            ),
          ),
        ),
        
        const Spacer(),
        
        // Inscription
        if (event.isRegistrationEnabled)
          Icon(
            Icons.how_to_reg,
            size: 16,
            color: AppTheme.grey600,
          ),
        
        // Récurrence originale
        if (event.isRecurring && !isRecurringInstance)
          Icon(
            Icons.repeat,
            size: 16,
            color: AppTheme.grey600,
          ),
      ],
    );
  }

  Widget _buildRecurrenceChip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.grey100,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.repeat,
            size: 12,
            color: AppTheme.grey700,
          ),
          const SizedBox(width: 2),
          Text(
            'Instance',
            style: TextStyle(
              color: AppTheme.grey700,
              fontSize: 10,
              fontWeight: AppTheme.fontMedium,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime() {
    final dateTime = instanceDate ?? event.startDate;
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');
    
    String result = dateFormat.format(dateTime);
    result += ' à ${timeFormat.format(dateTime)}';
    
    if (event.endDate != null) {
      if (event.isMultiDay) {
        result += ' - ${dateFormat.format(event.endDate!)} à ${timeFormat.format(event.endDate!)}';
      } else {
        result += ' - ${timeFormat.format(event.endDate!)}';
      }
    }
    
    return result;
  }

  IconData _getTypeIcon() {
    switch (event.type) {
      case 'celebration': return Icons.celebration;
      case 'bapteme': return Icons.water_drop;
      case 'formation': return Icons.school;
      case 'sortie': return Icons.directions_bus;
      case 'conference': return Icons.mic;
      case 'reunion': return Icons.people;
      case 'priere': return Icons.favorite;
      case 'culte': return Icons.church;
      default: return Icons.event;
    }
  }

  Color _getTypeColor() {
    switch (event.type) {
      case 'celebration': return AppTheme.orangeStandard;
      case 'bapteme': return AppTheme.blueStandard;
      case 'formation': return AppTheme.greenStandard;
      case 'sortie': return Colors.purple;
      case 'conference': return AppTheme.redStandard;
      case 'reunion': return Colors.indigo;
      case 'priere': return AppTheme.pinkStandard;
      case 'culte': return Colors.amber;
      default: return AppTheme.grey500;
    }
  }

  Color _getStatusColor() {
    switch (event.status) {
      case 'publie': return AppTheme.greenStandard;
      case 'brouillon': return AppTheme.orangeStandard;
      case 'archive': return AppTheme.grey500;
      case 'annule': return AppTheme.redStandard;
      default: return AppTheme.grey500;
    }
  }

  void _toggleSelection() {
    onSelectionChanged?.call(!isSelected);
  }
}

/// Widget pour afficher une liste d'événements récurrents avec gestion des instances
class RecurringEventsList extends StatelessWidget {
  final List<EventModel> events;
  final List<Map<String, dynamic>>? eventsData; // Données d'instances récurrentes
  final Function(EventModel, Map<String, dynamic>?)? onEventTap;
  final Function(EventModel, Map<String, dynamic>?)? onEventLongPress;
  final bool isSelectionMode;
  final List<EventModel> selectedEvents;
  final Function(EventModel, bool)? onSelectionChanged;

  const RecurringEventsList({
    Key? key,
    required this.events,
    this.eventsData,
    this.onEventTap,
    this.onEventLongPress,
    this.isSelectionMode = false,
    this.selectedEvents = const [],
    this.onSelectionChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: AppTheme.grey400,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun événement trouvé',
              style: TextStyle(
                color: AppTheme.grey600,
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final eventData = eventsData?[index];
        final isSelected = selectedEvents.any((e) => e.id == event.id);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: RecurringEventCard(
            event: event,
            instanceData: eventData,
            onTap: () => onEventTap?.call(event, eventData),
            onLongPress: () => onEventLongPress?.call(event, eventData),
            isSelectionMode: isSelectionMode,
            isSelected: isSelected,
            onSelectionChanged: (selected) => onSelectionChanged?.call(event, selected),
          ),
        );
      },
    );
  }
}

/// Widget pour afficher les statistiques des événements récurrents
class RecurrenceStatisticsWidget extends StatelessWidget {
  final Map<String, dynamic> statistics;

  const RecurrenceStatisticsWidget({
    Key? key,
    required this.statistics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final totalEvents = statistics['totalEvents'] as int? ?? 0;
    final recurringInstances = statistics['recurringInstances'] as int? ?? 0;
    final simpleEvents = statistics['simpleEvents'] as int? ?? 0;
    final frequencyBreakdown = statistics['frequencyBreakdown'] as Map<String, int>? ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistiques des événements',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: AppTheme.fontSemiBold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Statistiques générales
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Total',
                    totalEvents.toString(),
                    Icons.event,
                    AppTheme.blueStandard,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Instances récurrentes',
                    recurringInstances.toString(),
                    Icons.repeat,
                    AppTheme.greenStandard,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Événements simples',
                    simpleEvents.toString(),
                    Icons.event_note,
                    AppTheme.orangeStandard,
                  ),
                ),
              ],
            ),
            
            // Répartition par fréquence
            if (frequencyBreakdown.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Répartition par fréquence',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: AppTheme.fontSemiBold,
                ),
              ),
              const SizedBox(height: 8),
              ...frequencyBreakdown.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.grey200,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                        child: Text(
                          entry.value.toString(),
                          style: const TextStyle(fontWeight: AppTheme.fontMedium),
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
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: AppTheme.fontBold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}