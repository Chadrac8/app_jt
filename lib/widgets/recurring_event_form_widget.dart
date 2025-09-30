import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../services/events_firebase_service.dart';
import '../../theme.dart';

/// Widget pour créer des événements récurrents avec une interface complète
class RecurringEventFormWidget extends StatefulWidget {
  final EventModel? existingEvent;
  final Function(EventModel)? onEventCreated;
  final Function(EventModel)? onEventUpdated;

  const RecurringEventFormWidget({
    Key? key,
    this.existingEvent,
    this.onEventCreated,
    this.onEventUpdated,
  }) : super(key: key);

  @override
  State<RecurringEventFormWidget> createState() => _RecurringEventFormWidgetState();
}

class _RecurringEventFormWidgetState extends State<RecurringEventFormWidget>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  
  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  
  // Event properties
  String? _selectedType;
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  DateTime? _endDate;
  TimeOfDay? _endTime;
  String _visibility = 'publique';
  String _status = 'publie';
  bool _isRegistrationEnabled = false;
  int? _maxParticipants;
  bool _hasWaitingList = false;
  
  // Récurrence properties
  bool _isRecurring = false;
  EventRecurrence? _recurrence;
  
  bool _isLoading = false;

  final List<Map<String, String>> _eventTypes = [
    {'value': 'celebration', 'label': 'Célébration', 'icon': '🎉'},
    {'value': 'bapteme', 'label': 'Baptême', 'icon': '💧'},
    {'value': 'formation', 'label': 'Formation', 'icon': '📚'},
    {'value': 'sortie', 'label': 'Sortie', 'icon': '🚌'},
    {'value': 'conference', 'label': 'Conférence', 'icon': '🎤'},
    {'value': 'reunion', 'label': 'Réunion', 'icon': '👥'},
    {'value': 'priere', 'label': 'Prière', 'icon': '🙏'},
    {'value': 'culte', 'label': 'Culte', 'icon': '⛪'},
    {'value': 'autre', 'label': 'Autre', 'icon': '📅'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    if (widget.existingEvent != null) {
      _loadExistingEvent();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _loadExistingEvent() {
    final event = widget.existingEvent!;
    _titleController.text = event.title;
    _descriptionController.text = event.description;
    _locationController.text = event.location;
    _selectedType = event.type;
    _startDate = event.startDate;
    _startTime = TimeOfDay.fromDateTime(event.startDate);
    _endDate = event.endDate;
    _endTime = event.endDate != null ? TimeOfDay.fromDateTime(event.endDate!) : null;
    _visibility = event.visibility;
    _status = event.status;
    _isRegistrationEnabled = event.isRegistrationEnabled;
    _maxParticipants = event.maxParticipants;
    _hasWaitingList = event.hasWaitingList;
    _isRecurring = event.isRecurring;
    _recurrence = event.recurrence;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingEvent != null 
            ? 'Modifier l\'événement' 
            : 'Créer un événement récurrent'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Détails', icon: Icon(Icons.info_outline)),
            Tab(text: 'Récurrence', icon: Icon(Icons.repeat)),
            Tab(text: 'Options', icon: Icon(Icons.settings)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveEvent,
            child: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enregistrer'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildDetailsTab(),
            _buildRecurrenceTab(),
            _buildOptionsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Titre de l\'événement *',
              hintText: 'Ex: Culte dominical',
              prefixIcon: Icon(Icons.title),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Le titre est obligatoire';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Type d'événement
          DropdownButtonFormField<String>(
            value: _selectedType,
            decoration: const InputDecoration(
              labelText: 'Type d\'événement *',
              prefixIcon: Icon(Icons.category),
            ),
            items: _eventTypes.map((type) {
              return DropdownMenuItem<String>(
                value: type['value'],
                child: Row(
                  children: [
                    Text(type['icon']!, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(type['label']!),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedType = value),
            validator: (value) {
              if (value == null) return 'Veuillez sélectionner un type';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Description
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Décrivez l\'événement...',
              prefixIcon: Icon(Icons.description),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),

          // Lieu
          TextFormField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: 'Lieu',
              hintText: 'Ex: Église, Salle principale',
              prefixIcon: Icon(Icons.location_on),
            ),
          ),
          const SizedBox(height: 24),

          // Dates et heures
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Horaires',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Date et heure de début
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          title: const Text('Date de début'),
                          subtitle: Text(DateFormat('dd/MM/yyyy').format(_startDate)),
                          leading: const Icon(Icons.calendar_today),
                          onTap: _selectStartDate,
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          title: const Text('Heure de début'),
                          subtitle: Text(_startTime.format(context)),
                          leading: const Icon(Icons.access_time),
                          onTap: _selectStartTime,
                        ),
                      ),
                    ],
                  ),
                  
                  // Date et heure de fin (optionnelles)
                  const Divider(),
                  CheckboxListTile(
                    title: const Text('Définir une heure de fin'),
                    value: _endDate != null || _endTime != null,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _endDate = _startDate;
                          _endTime = TimeOfDay(
                            hour: _startTime.hour + 2,
                            minute: _startTime.minute,
                          );
                        } else {
                          _endDate = null;
                          _endTime = null;
                        }
                      });
                    },
                  ),
                  
                  if (_endDate != null || _endTime != null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            title: const Text('Date de fin'),
                            subtitle: Text(DateFormat('dd/MM/yyyy').format(_endDate!)),
                            leading: const Icon(Icons.calendar_today),
                            onTap: _selectEndDate,
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            title: const Text('Heure de fin'),
                            subtitle: Text(_endTime!.format(context)),
                            leading: const Icon(Icons.access_time),
                            onTap: _selectEndTime,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecurrenceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            title: const Text('Événement récurrent'),
            subtitle: const Text('Créer des occurrences répétitives'),
            value: _isRecurring,
            onChanged: (value) {
              setState(() {
                _isRecurring = value;
                if (!value) {
                  _recurrence = null;
                }
              });
            },
          ),
          
          if (_isRecurring) ...[
            const SizedBox(height: 16),
            _buildRecurrenceConfiguration(),
          ] else ...[
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.event_note,
                    size: 64,
                    color: AppTheme.grey400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Activez la récurrence pour configurer\\ndes événements répétitifs',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.grey600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecurrenceConfiguration() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuration de la récurrence',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            
            // Fréquence
            _buildFrequencySelector(),
            const SizedBox(height: 16),
            
            // Configuration spécifique selon la fréquence
            if (_recurrence != null) _buildFrequencySpecificConfig(),
            const SizedBox(height: 16),
            
            // Fin de récurrence
            _buildRecurrenceEndConfig(),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Fréquence'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Quotidien'),
              selected: _recurrence?.frequency == RecurrenceFrequency.daily,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _recurrence = EventRecurrence.daily();
                  });
                }
              },
            ),
            ChoiceChip(
              label: const Text('Hebdomadaire'),
              selected: _recurrence?.frequency == RecurrenceFrequency.weekly,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _recurrence = EventRecurrence.weekly(
                      daysOfWeek: [WeekDay.values[_startDate.weekday - 1]],
                    );
                  });
                }
              },
            ),
            ChoiceChip(
              label: const Text('Mensuel'),
              selected: _recurrence?.frequency == RecurrenceFrequency.monthly,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _recurrence = EventRecurrence.monthly(
                      dayOfMonth: _startDate.day,
                    );
                  });
                }
              },
            ),
            ChoiceChip(
              label: const Text('Annuel'),
              selected: _recurrence?.frequency == RecurrenceFrequency.yearly,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _recurrence = EventRecurrence.yearly(
                      monthOfYear: _startDate.month,
                      dayOfMonth: _startDate.day,
                    );
                  });
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFrequencySpecificConfig() {
    if (_recurrence == null) return const SizedBox.shrink();

    switch (_recurrence!.frequency) {
      case RecurrenceFrequency.daily:
        return _buildDailyConfig();
      case RecurrenceFrequency.weekly:
        return _buildWeeklyConfig();
      case RecurrenceFrequency.monthly:
        return _buildMonthlyConfig();
      case RecurrenceFrequency.yearly:
        return _buildYearlyConfig();
    }
  }

  Widget _buildDailyConfig() {
    return Column(
      children: [
        Row(
          children: [
            const Text('Répéter tous les'),
            const SizedBox(width: 8),
            SizedBox(
              width: 60,
              child: TextFormField(
                initialValue: _recurrence!.interval.toString(),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                onChanged: (value) {
                  final interval = int.tryParse(value) ?? 1;
                  setState(() {
                    _recurrence = _recurrence!.copyWith(interval: interval);
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            const Text('jour(s)'),
          ],
        ),
      ],
    );
  }

  Widget _buildWeeklyConfig() {
    const weekDays = [
      (WeekDay.monday, 'Lun'),
      (WeekDay.tuesday, 'Mar'),
      (WeekDay.wednesday, 'Mer'),
      (WeekDay.thursday, 'Jeu'),
      (WeekDay.friday, 'Ven'),
      (WeekDay.saturday, 'Sam'),
      (WeekDay.sunday, 'Dim'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Répéter toutes les'),
            const SizedBox(width: 8),
            SizedBox(
              width: 60,
              child: TextFormField(
                initialValue: _recurrence!.interval.toString(),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                onChanged: (value) {
                  final interval = int.tryParse(value) ?? 1;
                  setState(() {
                    _recurrence = _recurrence!.copyWith(interval: interval);
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            const Text('semaine(s)'),
          ],
        ),
        const SizedBox(height: 12),
        const Text('Jours de la semaine:'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: weekDays.map((dayData) {
            final day = dayData.$1;
            final label = dayData.$2;
            final isSelected = _recurrence!.daysOfWeek?.contains(day) ?? false;
            
            return FilterChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  final currentDays = List<WeekDay>.from(_recurrence!.daysOfWeek ?? []);
                  if (selected) {
                    currentDays.add(day);
                  } else {
                    currentDays.remove(day);
                  }
                  _recurrence = _recurrence!.copyWith(daysOfWeek: currentDays);
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMonthlyConfig() {
    return Column(
      children: [
        Row(
          children: [
            const Text('Répéter tous les'),
            const SizedBox(width: 8),
            SizedBox(
              width: 60,
              child: TextFormField(
                initialValue: _recurrence!.interval.toString(),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                onChanged: (value) {
                  final interval = int.tryParse(value) ?? 1;
                  setState(() {
                    _recurrence = _recurrence!.copyWith(interval: interval);
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            const Text('mois'),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('Le'),
            const SizedBox(width: 8),
            SizedBox(
              width: 60,
              child: TextFormField(
                initialValue: _recurrence!.dayOfMonth?.toString() ?? _startDate.day.toString(),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                onChanged: (value) {
                  final day = int.tryParse(value);
                  if (day != null && day >= 1 && day <= 31) {
                    setState(() {
                      _recurrence = _recurrence!.copyWith(dayOfMonth: day);
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            const Text('de chaque mois'),
          ],
        ),
      ],
    );
  }

  Widget _buildYearlyConfig() {
    return Column(
      children: [
        Row(
          children: [
            const Text('Répéter tous les'),
            const SizedBox(width: 8),
            SizedBox(
              width: 60,
              child: TextFormField(
                initialValue: _recurrence!.interval.toString(),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                onChanged: (value) {
                  final interval = int.tryParse(value) ?? 1;
                  setState(() {
                    _recurrence = _recurrence!.copyWith(interval: interval);
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            const Text('an(s)'),
          ],
        ),
        const SizedBox(height: 12),
        Text('Le ${_startDate.day}/${_startDate.month} de chaque année'),
      ],
    );
  }

  Widget _buildRecurrenceEndConfig() {
    return Card(
      color: AppTheme.grey50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Fin de récurrence'),
            const SizedBox(height: 8),
            
            RadioListTile<RecurrenceEndType>(
              title: const Text('Jamais'),
              value: RecurrenceEndType.never,
              groupValue: _recurrence?.endType ?? RecurrenceEndType.never,
              onChanged: (value) {
                setState(() {
                  _recurrence = _recurrence?.copyWith(
                    endType: value!,
                    occurrences: null,
                    endDate: null,
                  );
                });
              },
            ),
            
            RadioListTile<RecurrenceEndType>(
              title: const Text('Après un nombre d\'occurrences'),
              value: RecurrenceEndType.afterOccurrences,
              groupValue: _recurrence?.endType ?? RecurrenceEndType.never,
              onChanged: (value) {
                setState(() {
                  _recurrence = _recurrence?.copyWith(
                    endType: value!,
                    occurrences: 10,
                    endDate: null,
                  );
                });
              },
            ),
            
            if (_recurrence?.endType == RecurrenceEndType.afterOccurrences)
              Padding(
                padding: const EdgeInsets.only(left: 32),
                child: Row(
                  children: [
                    const Text('Nombre d\'occurrences:'),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 80,
                      child: TextFormField(
                        initialValue: _recurrence!.occurrences?.toString() ?? '10',
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        onChanged: (value) {
                          final count = int.tryParse(value);
                          if (count != null && count > 0) {
                            setState(() {
                              _recurrence = _recurrence!.copyWith(occurrences: count);
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            
            RadioListTile<RecurrenceEndType>(
              title: const Text('À une date'),
              value: RecurrenceEndType.onDate,
              groupValue: _recurrence?.endType ?? RecurrenceEndType.never,
              onChanged: (value) {
                setState(() {
                  _recurrence = _recurrence?.copyWith(
                    endType: value!,
                    occurrences: null,
                    endDate: DateTime.now().add(const Duration(days: 365)),
                  );
                });
              },
            ),
            
            if (_recurrence?.endType == RecurrenceEndType.onDate)
              Padding(
                padding: const EdgeInsets.only(left: 32),
                child: ListTile(
                  title: const Text('Date de fin'),
                  subtitle: Text(_recurrence!.endDate != null 
                      ? DateFormat('dd/MM/yyyy').format(_recurrence!.endDate!)
                      : 'Sélectionner une date'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _selectRecurrenceEndDate,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Visibilité
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Visibilité',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _visibility,
                    items: const [
                      DropdownMenuItem(value: 'publique', child: Text('Publique')),
                      DropdownMenuItem(value: 'privee', child: Text('Privée')),
                      DropdownMenuItem(value: 'groupe', child: Text('Réservée aux groupes')),
                      DropdownMenuItem(value: 'role', child: Text('Réservée aux rôles')),
                    ],
                    onChanged: (value) => setState(() => _visibility = value!),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Inscription
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    title: const Text('Inscription requise'),
                    subtitle: const Text('Les participants doivent s\'inscrire'),
                    value: _isRegistrationEnabled,
                    onChanged: (value) => setState(() => _isRegistrationEnabled = value),
                  ),
                  
                  if (_isRegistrationEnabled) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Nombre maximum de participants',
                        hintText: 'Laisser vide pour illimité',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        _maxParticipants = int.tryParse(value);
                      },
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Liste d\'attente'),
                      subtitle: const Text('Autoriser les inscriptions en attente'),
                      value: _hasWaitingList,
                      onChanged: (value) => setState(() => _hasWaitingList = value),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Méthodes de sélection de date/heure
  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? _startTime,
    );
    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  Future<void> _selectRecurrenceEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _recurrence?.endDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null && _recurrence != null) {
      setState(() {
        _recurrence = _recurrence!.copyWith(endDate: picked);
      });
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Construire la date/heure de début
      final startDateTime = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        _startTime.hour,
        _startTime.minute,
      );

      // Construire la date/heure de fin (optionnelle)
      DateTime? endDateTime;
      if (_endDate != null && _endTime != null) {
        endDateTime = DateTime(
          _endDate!.year,
          _endDate!.month,
          _endDate!.day,
          _endTime!.hour,
          _endTime!.minute,
        );
      }

      // Valider la récurrence si activée
      if (_isRecurring && _recurrence != null) {
        // Validation de base de la récurrence
        if (_recurrence!.interval <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('L\'intervalle doit être supérieur à 0')),
          );
          return;
        }
      }

      // Créer l'événement
      final event = EventModel(
        id: widget.existingEvent?.id ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        startDate: startDateTime,
        endDate: endDateTime,
        location: _locationController.text.trim(),
        type: _selectedType!,
        visibility: _visibility,
        status: _status,
        isRegistrationEnabled: _isRegistrationEnabled,
        maxParticipants: _maxParticipants,
        hasWaitingList: _hasWaitingList,
        isRecurring: _isRecurring,
        recurrence: _isRecurring ? _recurrence : null,
        createdAt: widget.existingEvent?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.existingEvent != null) {
        await EventsFirebaseService.updateEvent(event);
        widget.onEventUpdated?.call(event);
      } else {
        await EventsFirebaseService.createEvent(event);
        widget.onEventCreated?.call(event);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.existingEvent != null 
              ? 'Événement modifié avec succès!' 
              : 'Événement créé avec succès!'),
          backgroundColor: AppTheme.greenStandard,
        ),
      );

      Navigator.of(context).pop();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: AppTheme.redStandard,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}