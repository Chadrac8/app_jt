import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/service_model.dart';
import '../models/event_model.dart';
import '../services/events_firebase_service.dart';
import '../modules/services/views/service_detail_page.dart';
import '../modules/services/views/services_planning_view.dart';
import '../theme.dart';

/// Modal affichant toutes les occurrences d'un service récurrent
/// 
/// Fonctionnalités:
/// - Liste chronologique des occurrences
/// - Statut visuel (publié/brouillon/annulé)
/// - Indicateur d'assignations (complet/incomplet)
/// - Clic sur occurrence → Détail de l'événement
/// - Bouton "Voir dans Planning" → Navigation vers ServicesPlanningView
class ServiceOccurrencesDialog extends StatefulWidget {
  final ServiceModel service;

  const ServiceOccurrencesDialog({
    super.key,
    required this.service,
  });

  @override
  State<ServiceOccurrencesDialog> createState() => _ServiceOccurrencesDialogState();
}

class _ServiceOccurrencesDialogState extends State<ServiceOccurrencesDialog> {
  bool _isLoading = true;
  List<EventModel> _occurrences = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOccurrences();
  }

  Future<void> _loadOccurrences() async {
    try {
      final events = await EventsFirebaseService.getEventsByService(
        widget.service.id,
      );
      
      if (mounted) {
        setState(() {
          _occurrences = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'publie':
        return AppTheme.greenStandard;
      case 'brouillon':
        return AppTheme.orangeStandard;
      case 'annule':
        return AppTheme.redStandard;
      case 'archive':
        return AppTheme.grey500;
      default:
        return AppTheme.grey500;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'publie':
        return 'PUBLIÉ';
      case 'brouillon':
        return 'BROUILLON';
      case 'annule':
        return 'ANNULÉ';
      case 'archive':
        return 'ARCHIVÉ';
      default:
        return status.toUpperCase();
    }
  }

  bool _isOccurrenceComplete(EventModel event) {
    // Considéré comme complet si au moins 3 personnes assignées
    return event.responsibleIds.length >= 3;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(date.year, date.month, date.day);
    
    final difference = eventDate.difference(today).inDays;
    
    String dateStr = DateFormat('EEEE d MMM', 'fr_FR').format(date);
    
    if (difference == 0) {
      dateStr += ' (Aujourd\'hui)';
    } else if (difference == 1) {
      dateStr += ' (Demain)';
    } else if (difference == -1) {
      dateStr += ' (Hier)';
    } else if (difference > 0 && difference <= 7) {
      dateStr += ' (Dans $difference jours)';
    } else if (difference < 0 && difference >= -7) {
      dateStr += ' (Il y a ${-difference} jours)';
    }
    
    return dateStr;
  }

  String _formatTime(DateTime date) {
    return DateFormat('HH:mm', 'fr_FR').format(date);
  }

  void _openOccurrenceDetail(EventModel event) {
    Navigator.of(context).pop(); // Fermer le dialog
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ServiceDetailPage(service: widget.service),
      ),
    );
  }

  void _openPlanningView() {
    Navigator.of(context).pop(); // Fermer le dialog
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ServicesPlanningView(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Container(
        width: 600,
        height: 700,
        padding: const EdgeInsets.all(AppTheme.spaceLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Icon(
                    Icons.repeat,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Occurrences du service',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: AppTheme.fontBold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.service.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spaceLarge),

            // Stats
            if (!_isLoading && _error == null) ...[
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceMedium),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        context,
                        Icons.event,
                        'Total',
                        '${_occurrences.length}',
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        context,
                        Icons.check_circle,
                        'Complet',
                        '${_occurrences.where(_isOccurrenceComplete).length}',
                        color: AppTheme.greenStandard,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        context,
                        Icons.warning_amber,
                        'Incomplet',
                        '${_occurrences.where((e) => !_isOccurrenceComplete(e)).length}',
                        color: AppTheme.orangeStandard,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spaceMedium),
            ],

            // Content
            Expanded(
              child: _buildContent(),
            ),

            // Footer actions
            if (!_isLoading && _error == null) ...[
              const Divider(),
              const SizedBox(height: AppTheme.spaceMedium),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Fermer'),
                  ),
                  const SizedBox(width: AppTheme.spaceSmall),
                  FilledButton.icon(
                    onPressed: _openPlanningView,
                    icon: const Icon(Icons.view_week),
                    label: const Text('Voir dans Planning'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    Color? color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: color ?? Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: AppTheme.fontBold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppTheme.spaceMedium),
            Text('Chargement des occurrences...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            Text(
              'Erreur',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: AppTheme.spaceSmall),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            FilledButton(
              onPressed: _loadOccurrences,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_occurrences.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            Text(
              'Aucune occurrence',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spaceSmall),
            Text(
              'Ce service n\'a pas encore d\'occurrences créées',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _occurrences.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final occurrence = _occurrences[index];
        return _buildOccurrenceItem(occurrence, index);
      },
    );
  }

  Widget _buildOccurrenceItem(EventModel occurrence, int index) {
    final isComplete = _isOccurrenceComplete(occurrence);
    final isPast = occurrence.startDate.isBefore(DateTime.now());
    
    return InkWell(
      onTap: () => _openOccurrenceDetail(occurrence),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceMedium,
          vertical: AppTheme.spaceSmall,
        ),
        child: Row(
          children: [
            // Index
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: AppTheme.fontBold,
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: AppTheme.spaceMedium),
            
            // Date and time
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDate(occurrence.startDate),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: AppTheme.fontMedium,
                      color: isPast
                          ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_formatTime(occurrence.startDate)} - ${_formatTime(occurrence.endDate ?? occurrence.startDate)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(occurrence.status),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Text(
                _getStatusLabel(occurrence.status),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: AppTheme.fontSemiBold,
                ),
              ),
            ),
            
            const SizedBox(width: AppTheme.spaceSmall),
            
            // Assignment indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isComplete
                    ? AppTheme.greenStandard.withOpacity(0.1)
                    : AppTheme.orangeStandard.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(
                  color: isComplete ? AppTheme.greenStandard : AppTheme.orangeStandard,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isComplete ? Icons.check_circle : Icons.warning_amber,
                    size: 14,
                    color: isComplete ? AppTheme.greenStandard : AppTheme.orangeStandard,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${occurrence.responsibleIds.length}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isComplete ? AppTheme.greenStandard : AppTheme.orangeStandard,
                      fontWeight: AppTheme.fontBold,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: AppTheme.spaceSmall),
            
            // Arrow
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }
}
