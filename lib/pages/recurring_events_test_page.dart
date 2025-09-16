import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../services/recurring_calendar_service.dart';
import '../widgets/recurring_event_form_widget.dart';
import '../widgets/recurring_event_card.dart';

/// Page de démonstration et test des événements récurrents
class RecurringEventsTestPage extends StatefulWidget {
  const RecurringEventsTestPage({Key? key}) : super(key: key);

  @override
  State<RecurringEventsTestPage> createState() => _RecurringEventsTestPageState();
}

class _RecurringEventsTestPageState extends State<RecurringEventsTestPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final RecurringCalendarService _calendarService = RecurringCalendarService();
  
  List<EventModel> _testEvents = [];
  List<EventModel> _expandedEvents = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _createTestEvents();
    _loadEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test - Événements Récurrents'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Créer', icon: Icon(Icons.add)),
            Tab(text: 'Liste', icon: Icon(Icons.list)),
            Tab(text: 'Calendrier', icon: Icon(Icons.calendar_month)),
            Tab(text: 'Stats', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCreateTab(),
          _buildListTab(),
          _buildCalendarTab(),
          _buildStatsTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 0 ? null : FloatingActionButton(
        onPressed: _createTestEvents,
        child: const Icon(Icons.refresh),
        tooltip: 'Créer événements de test',
      ),
    );
  }

  Widget _buildCreateTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Test de création d\'événements récurrents',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Cette section permet de tester la création d\'événements récurrents avec différentes configurations.',
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _createTestEvents,
                    icon: const Icon(Icons.add_circle),
                    label: const Text('Créer événements de test'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: RecurringEventFormWidget(
              onEventCreated: (event) {
                setState(() {
                  _testEvents.add(event);
                });
                _loadEvents();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Événement récurrent créé avec succès !'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Événements expandus: ${_expandedEvents.length}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                onPressed: _loadEvents,
                icon: const Icon(Icons.refresh),
                tooltip: 'Actualiser',
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RecurringEventsList(
                  events: _expandedEvents,
                  onEventTap: (event, data) {
                    _showEventDetails(event, data);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCalendarTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Calendrier des événements',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _selectDate(context),
                    icon: const Icon(Icons.date_range),
                    tooltip: 'Sélectionner une date',
                  ),
                ],
              ),
              Text(
                'Date sélectionnée: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildCalendarView(),
        ),
      ],
    );
  }

  Widget _buildStatsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistiques des événements récurrents',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (_statistics.isNotEmpty)
            RecurrenceStatisticsWidget(statistics: _statistics),
          const SizedBox(height: 16),
          _buildTestResults(),
        ],
      ),
    );
  }

  Widget _buildCalendarView() {
    return FutureBuilder<List<EventModel>>(
      future: _calendarService.getEventsForDay(_selectedDate),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text(
                  'Erreur: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }
        
        final dayEvents = snapshot.data ?? [];
        return RecurringEventsList(
          events: dayEvents,
          onEventTap: (event, data) {
            _showEventDetails(event, data);
          },
        );
      },
    );
  }

  Widget _buildTestResults() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Résultats des tests',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildTestResult('Création d\'événements de base', true),
            _buildTestResult('Récurrence quotidienne', _testEvents.any((e) => e.recurrence?.frequency == RecurrenceFrequency.daily)),
            _buildTestResult('Récurrence hebdomadaire', _testEvents.any((e) => e.recurrence?.frequency == RecurrenceFrequency.weekly)),
            _buildTestResult('Récurrence mensuelle', _testEvents.any((e) => e.recurrence?.frequency == RecurrenceFrequency.monthly)),
            _buildTestResult('Récurrence annuelle', _testEvents.any((e) => e.recurrence?.frequency == RecurrenceFrequency.yearly)),
            _buildTestResult('Expansion des instances', _expandedEvents.isNotEmpty),
            _buildTestResult('Calcul des statistiques', _statistics.isNotEmpty),
          ],
        ),
      ),
    );
  }

  Widget _buildTestResult(String testName, bool passed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            passed ? Icons.check_circle : Icons.cancel,
            color: passed ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(testName),
          ),
          Text(
            passed ? 'PASS' : 'FAIL',
            style: TextStyle(
              color: passed ? Colors.green : Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _createTestEvents() {
    setState(() {
      _testEvents.clear();
      _isLoading = true;
    });

    // Événement quotidien
    _testEvents.add(EventModel(
      id: 'test_daily',
      title: 'Prière matinale',
      description: 'Temps de prière quotidien',
      startDate: DateTime.now().add(const Duration(days: 1)),
      location: 'Salle de prière',
      type: 'priere',
      status: 'publie',
      createdBy: 'test_user',
      isRecurring: true,
      isRegistrationEnabled: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      recurrence: EventRecurrence.daily(
        endType: RecurrenceEndType.afterOccurrences,
        occurrences: 30,
      ),
    ));

    // Événement hebdomadaire
    _testEvents.add(EventModel(
      id: 'test_weekly',
      title: 'Culte dominical',
      description: 'Service de culte hebdomadaire',
      startDate: _getNextSunday(),
      endDate: _getNextSunday().add(const Duration(hours: 2)),
      location: 'Sanctuaire principal',
      type: 'culte',
      status: 'publie',
      createdBy: 'test_user',
      isRecurring: true,
      isRegistrationEnabled: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      recurrence: EventRecurrence.weekly(
        daysOfWeek: [WeekDay.sunday],
        endType: RecurrenceEndType.afterOccurrences,
        occurrences: 52,
      ),
    ));

    // Événement mensuel
    _testEvents.add(EventModel(
      id: 'test_monthly',
      title: 'Réunion mensuelle',
      description: 'Réunion de planification mensuelle',
      startDate: DateTime(DateTime.now().year, DateTime.now().month + 1, 1, 19, 0),
      location: 'Salle de conférence',
      type: 'reunion',
      status: 'publie',
      createdBy: 'test_user',
      isRecurring: true,
      isRegistrationEnabled: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      recurrence: EventRecurrence.monthly(
        dayOfMonth: 1,
        endType: RecurrenceEndType.afterOccurrences,
        occurrences: 12,
      ),
    ));

    // Événement annuel
    _testEvents.add(EventModel(
      id: 'test_yearly',
      title: 'Jubilé annuel',
      description: 'Célébration annuelle du jubilé',
      startDate: DateTime(DateTime.now().year + 1, 6, 15, 10, 0),
      endDate: DateTime(DateTime.now().year + 1, 6, 15, 18, 0),
      location: 'Auditorium principal',
      type: 'celebration',
      status: 'publie',
      createdBy: 'test_user',
      isRecurring: true,
      isRegistrationEnabled: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      recurrence: EventRecurrence.yearly(
        monthOfYear: 6,
        dayOfMonth: 15,
        endType: RecurrenceEndType.afterOccurrences,
        occurrences: 10,
      ),
    ));

    _loadEvents();
  }

  DateTime _getNextSunday() {
    final now = DateTime.now();
    final daysUntilSunday = 7 - now.weekday;
    return DateTime(now.year, now.month, now.day + daysUntilSunday, 10, 0);
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Simuler l'expansion des événements pour les 3 prochains mois
      final startDate = DateTime.now();
      final endDate = DateTime.now().add(const Duration(days: 90));
      
      final allExpanded = <EventModel>[];
      
      for (final event in _testEvents) {
        if (event.isRecurring && event.recurrence != null) {
          final instances = event.recurrence!.generateOccurrences(
            event.startDate,
            startDate,
            endDate,
          );
          
          for (final instanceDate in instances) {
            allExpanded.add(EventModel(
              id: '${event.id}_${instanceDate.millisecondsSinceEpoch}',
              title: event.title,
              description: event.description,
              startDate: instanceDate,
              endDate: event.endDate != null 
                ? instanceDate.add(event.endDate!.difference(event.startDate))
                : null,
              location: event.location,
              type: event.type,
              status: event.status,
              createdBy: event.createdBy,
              isRecurring: false, // Les instances ne sont pas récurrentes
              isRegistrationEnabled: event.isRegistrationEnabled,
              createdAt: event.createdAt,
              updatedAt: event.updatedAt,
            ));
          }
        } else {
          allExpanded.add(event);
        }
      }
      
      allExpanded.sort((a, b) => a.startDate.compareTo(b.startDate));
      
      // Calculer les statistiques
      final stats = await _calendarService.getRecurrenceStatistics(startDate, endDate);
      
      setState(() {
        _expandedEvents = allExpanded;
        _statistics = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showEventDetails(EventModel event, Map<String, dynamic>? data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(event.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Description: ${event.description}'),
              const SizedBox(height: 8),
              Text('Date: ${DateFormat('dd/MM/yyyy HH:mm').format(event.startDate)}'),
              if (event.endDate != null)
                Text('Fin: ${DateFormat('dd/MM/yyyy HH:mm').format(event.endDate!)}'),
              const SizedBox(height: 8),
              Text('Lieu: ${event.location}'),
              Text('Type: ${event.typeLabel}'),
              Text('Statut: ${event.statusLabel}'),
              const SizedBox(height: 8),
              Text('Récurrent: ${event.isRecurring ? 'Oui' : 'Non'}'),
              if (event.recurrence != null) ...[
                Text('Fréquence: ${event.recurrence!.frequency.toString().split('.').last}'),
                if (event.recurrence!.interval > 1)
                  Text('Intervalle: ${event.recurrence!.interval}'),
              ],
              if (data != null) ...[
                const SizedBox(height: 8),
                const Text('Données d\'instance:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...data.entries.map((entry) => Text('${entry.key}: ${entry.value}')),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}