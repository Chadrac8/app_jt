import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/event_model.dart';
import '../../../services/services_firebase_service.dart';
import '../../../services/events_firebase_service.dart';
import '../../../widgets/quick_assign_dialog.dart';
import 'service_detail_page.dart';
import 'service_form_page.dart';

/// Vue Planning Center Style pour les services récurrents
/// 
/// Affiche les occurrences futures des services avec:
/// - Groupement par semaine
/// - Statut visuel (complet/incomplet)
/// - Sélection multiple
/// - Actions en masse
class ServicesPlanningView extends StatefulWidget {
  const ServicesPlanningView({super.key});

  @override
  State<ServicesPlanningView> createState() => _ServicesPlanningViewState();
}

class _ServicesPlanningViewState extends State<ServicesPlanningView> {
  final ScrollController _scrollController = ScrollController();
  
  // Mode sélection
  bool _isSelectionMode = false;
  final Set<String> _selectedEventIds = {};
  
  // Filtres
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 90)); // 3 mois
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Active/désactive le mode sélection
  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedEventIds.clear();
      }
    });
  }

  /// Toggle sélection d'un événement
  void _toggleEventSelection(String eventId) {
    setState(() {
      if (_selectedEventIds.contains(eventId)) {
        _selectedEventIds.remove(eventId);
      } else {
        _selectedEventIds.add(eventId);
      }
    });
  }

  /// Désélectionner tous
  void _clearSelection() {
    setState(() {
      _selectedEventIds.clear();
    });
  }

  /// Select all visible events in the current view
  Future<void> _selectAllVisibleEvents() async {
    try {
      final eventsSnapshot = await FirebaseFirestore.instance
          .collection('events')
          .where('date', isGreaterThanOrEqualTo: _startDate)
          .where('date', isLessThanOrEqualTo: _endDate)
          .get();
      
      setState(() {
        _selectedEventIds.clear();
        _selectedEventIds.addAll(eventsSnapshot.docs.map((doc) => doc.id));
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  /// Actions en masse: Supprimer les événements sélectionnés
  Future<void> _deleteSelected() async {
    if (_selectedEventIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer les occurrences'),
        content: Text(
          'Voulez-vous supprimer ${_selectedEventIds.length} occurrence(s) sélectionnée(s) ?\n\n'
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Afficher loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Suppression de ${_selectedEventIds.length} occurrence(s)...'),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Supprimer chaque événement
      for (final eventId in _selectedEventIds) {
        await EventsFirebaseService.deleteEvent(eventId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${_selectedEventIds.length} occurrence(s) supprimée(s)'),
            backgroundColor: Colors.green,
          ),
        );
        
        setState(() {
          _selectedEventIds.clear();
          _isSelectionMode = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Actions en masse: Changer le statut
  Future<void> _changeStatusSelected(String newStatus) async {
    if (_selectedEventIds.isEmpty) return;

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Modification de ${_selectedEventIds.length} occurrence(s)...'),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Mettre à jour chaque événement
      for (final eventId in _selectedEventIds) {
        final event = await EventsFirebaseService.getEvent(eventId);
        if (event != null) {
          final updated = event.copyWith(
            status: newStatus,
            updatedAt: DateTime.now(),
          );
          await EventsFirebaseService.updateEvent(updated);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${_selectedEventIds.length} occurrence(s) modifiée(s)'),
            backgroundColor: Colors.green,
          ),
        );
        
        setState(() {
          _selectedEventIds.clear();
          _isSelectionMode = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _isSelectionMode ? null : _buildFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: _isSelectionMode
          ? Text('${_selectedEventIds.length} sélectionné(s)')
          : const Text('Planning des Services'),
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      leading: _isSelectionMode
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: _toggleSelectionMode,
            )
          : null,
      actions: [
        if (_isSelectionMode) ...[
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _selectedEventIds.isEmpty ? null : _deleteSelected,
            tooltip: 'Supprimer',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            enabled: _selectedEventIds.isNotEmpty,
            onSelected: (value) {
              if (value == 'publish') {
                _changeStatusSelected('publie');
              } else if (value == 'draft') {
                _changeStatusSelected('brouillon');
              } else if (value == 'cancel') {
                _changeStatusSelected('annule');
              } else if (value == 'select_all') {
                _selectAllVisibleEvents();
              } else if (value == 'clear') {
                _clearSelection();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'publish',
                child: ListTile(
                  leading: Icon(Icons.publish),
                  title: Text('Publier'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'draft',
                child: ListTile(
                  leading: Icon(Icons.drafts),
                  title: Text('Mettre en brouillon'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'cancel',
                child: ListTile(
                  leading: Icon(Icons.cancel),
                  title: Text('Annuler'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'clear',
                child: ListTile(
                  leading: Icon(Icons.clear_all),
                  title: Text('Tout désélectionner'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ] else ...[
          IconButton(
            icon: const Icon(Icons.checklist),
            onPressed: _toggleSelectionMode,
            tooltip: 'Mode sélection',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filtres',
          ),
        ],
      ],
    );
  }

  Widget _buildBody() {
    return StreamBuilder<List<EventModel>>(
      stream: EventsFirebaseService.getEventsStream(
        startDate: _startDate,
        endDate: _endDate,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text('Erreur: ${snapshot.error}'),
              ],
            ),
          );
        }

        final allEvents = snapshot.data ?? [];
        
        // Filtrer les événements liés à des services
        final serviceEvents = allEvents.where((event) {
          return event.linkedServiceId != null && 
                 event.deletedAt == null;
        }).toList();

        // Grouper par semaine
        final groupedByWeek = _groupEventsByWeek(serviceEvents);

        if (groupedByWeek.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: groupedByWeek.length,
          itemBuilder: (context, index) {
            final week = groupedByWeek.keys.elementAt(index);
            final events = groupedByWeek[week]!;
            return _buildWeekSection(week, events);
          },
        );
      },
    );
  }

  /// Groupe les événements par semaine
  Map<String, List<EventModel>> _groupEventsByWeek(List<EventModel> events) {
    final Map<String, List<EventModel>> grouped = {};
    
    for (final event in events) {
      final weekStart = _getWeekStart(event.startDate);
      final weekKey = DateFormat('d MMM yyyy', 'fr_FR').format(weekStart);
      
      if (!grouped.containsKey(weekKey)) {
        grouped[weekKey] = [];
      }
      grouped[weekKey]!.add(event);
    }

    // Trier chaque semaine par date
    for (final key in grouped.keys) {
      grouped[key]!.sort((a, b) => a.startDate.compareTo(b.startDate));
    }

    return grouped;
  }

  /// Obtenir le début de la semaine (lundi)
  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  Widget _buildWeekSection(String weekLabel, List<EventModel> events) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête de semaine
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Semaine du $weekLabel',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${events.length} service(s)',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        
        // Cartes des événements
        ...events.map((event) => _buildEventCard(event)),
        
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildEventCard(EventModel event) {
    final isSelected = _selectedEventIds.contains(event.id);
    
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        print('👆 Tap détecté sur event: ${event.title}');
        if (_isSelectionMode) {
          print('   Mode sélection actif');
          _toggleEventSelection(event.id);
        } else {
          print('   Mode normal - Navigation vers détails');
          // Naviguer vers détails
          _navigateToEventDetail(event);
        }
      },
      onLongPress: () {
        if (!_isSelectionMode) {
          setState(() {
            _isSelectionMode = true;
            _selectedEventIds.add(event.id);
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Checkbox (mode sélection)
              if (_isSelectionMode) ...[
                Checkbox(
                  value: isSelected,
                  onChanged: (value) => _toggleEventSelection(event.id),
                ),
                const SizedBox(width: 12),
              ],
              
              // Icône repeat
              if (event.seriesId != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.repeat,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              
              // Contenu principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // Date et heure
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatEventDateTime(event),
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Lieu
                    if (event.location.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.location,
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    const SizedBox(height: 8),
                    
                    // Assignations avec bouton d'action
                    FutureBuilder<int>(
                      future: _getAssignmentCount(event),
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;
                        final isComplete = count >= 3; // Example: 3 minimum
                        
                        return Row(
                          children: [
                            Icon(
                              isComplete ? Icons.check_circle : Icons.warning_amber,
                              size: 16,
                              color: isComplete ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$count bénévole(s) assigné(s)',
                              style: TextStyle(
                                fontSize: 12,
                                color: isComplete ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            if (!_isSelectionMode) ...[
                              GestureDetector(
                                onTap: () {
                                  print('👆 Bouton assigner cliqué');
                                  _showQuickAssignDialog(event);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.person_add,
                                    size: 18,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              // Statut badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(event.status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusLabel(event.status),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<int> _getAssignmentCount(EventModel event) async {
    // Compter les responsibles assignés
    return event.responsibleIds.length;
  }

  /// Afficher le dialog d'assignation rapide
  Future<void> _showQuickAssignDialog(EventModel event) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => QuickAssignDialog(event: event),
    );
    
    if (result == true && mounted) {
      setState(() {}); // Rafraîchir pour voir les changements
    }
  }

  String _formatEventDateTime(EventModel event) {
    final date = DateFormat('EEEE d MMM', 'fr_FR').format(event.startDate);
    final time = DateFormat('HH:mm').format(event.startDate);
    final endTime = event.endDate != null 
        ? DateFormat('HH:mm').format(event.endDate!)
        : '';
    return endTime.isNotEmpty 
        ? '$date • $time - $endTime'
        : '$date • $time';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'publie':
        return Colors.green;
      case 'brouillon':
        return Colors.orange;
      case 'annule':
        return Colors.red;
      case 'archive':
        return Colors.grey;
      default:
        return Colors.blue;
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun service planifié',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Créez votre premier service récurrent',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ServiceFormPage(),
          ),
        );
        if (result == true && mounted) {
          setState(() {}); // Rafraîchir
        }
      },
      icon: const Icon(Icons.add),
      label: const Text('Nouveau Service'),
    );
  }

  Future<void> _navigateToEventDetail(EventModel event) async {
    print('🔍 Navigation vers détail du service - Event ID: ${event.id}');
    print('   Event title: ${event.title}');
    print('   linkedServiceId: ${event.linkedServiceId}');
    
    // Récupérer le service lié
    if (event.linkedServiceId != null) {
      print('   Récupération du service ${event.linkedServiceId}...');
      final service = await ServicesFirebaseService.getService(
        event.linkedServiceId!,
      );
      
      if (service == null) {
        print('   ⚠️ Service non trouvé !');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Service non trouvé'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      print('   ✅ Service trouvé: ${service.name}');
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceDetailPage(service: service),
          ),
        );
        setState(() {}); // Rafraîchir après retour
      }
    } else {
      print('   ⚠️ Aucun linkedServiceId sur cet événement !');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cet événement n\'est pas lié à un service'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _showFilterDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtres'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Période'),
              subtitle: Text(
                '${DateFormat('d MMM yyyy', 'fr_FR').format(_startDate)} - '
                '${DateFormat('d MMM yyyy', 'fr_FR').format(_endDate)}',
              ),
              trailing: const Icon(Icons.edit),
              onTap: () async {
                Navigator.pop(context);
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                  initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
                  locale: const Locale('fr', 'FR'),
                );
                if (picked != null) {
                  setState(() {
                    _startDate = picked.start;
                    _endDate = picked.end;
                  });
                  // Trigger rebuild with new date range
                }
              },
            ),
            const Divider(),
            ListTile(
              title: const Text('Type de service'),
              trailing: DropdownButton<String>(
                value: 'all',
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Tous')),
                  DropdownMenuItem(value: 'culte', child: Text('Culte')),
                  DropdownMenuItem(value: 'reunion', child: Text('Réunion')),
                  DropdownMenuItem(value: 'conference', child: Text('Conférence')),
                ],
                onChanged: (value) {
                  // Filter by service type
                  Navigator.pop(context);
                },
              ),
            ),
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
