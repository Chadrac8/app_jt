import 'package:flutter/material.dart';
import '../models/event_recurrence_model.dart';

/// Widget pour configurer la récurrence d'événements
/// Interface inspirée de Planning Center Online
class EventRecurrenceWidget extends StatefulWidget {
  final EventRecurrenceModel? initialRecurrence;
  final Function(EventRecurrenceModel) onRecurrenceChanged;

  const EventRecurrenceWidget({
    Key? key,
    this.initialRecurrence,
    required this.onRecurrenceChanged,
  }) : super(key: key);

  @override
  State<EventRecurrenceWidget> createState() => _EventRecurrenceWidgetState();
}

class _EventRecurrenceWidgetState extends State<EventRecurrenceWidget> {
  RecurrenceType _type = RecurrenceType.weekly;
  int _interval = 1;
  List<int> _selectedDaysOfWeek = [];
  int? _dayOfMonth;
  List<int> _selectedMonths = [];
  DateTime? _endDate;
  int? _occurrenceCount;
  bool _hasEndDate = false;
  bool _hasOccurrenceLimit = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialRecurrence != null) {
      _loadFromExisting(widget.initialRecurrence!);
    }
  }

  void _loadFromExisting(EventRecurrenceModel recurrence) {
    setState(() {
      _type = recurrence.type;
      _interval = recurrence.interval;
      _selectedDaysOfWeek = recurrence.daysOfWeek ?? [];
      _dayOfMonth = recurrence.dayOfMonth;
      _selectedMonths = recurrence.monthsOfYear ?? [];
      _endDate = recurrence.endDate;
      _occurrenceCount = recurrence.occurrenceCount;
      _hasEndDate = recurrence.endDate != null;
      _hasOccurrenceLimit = recurrence.occurrenceCount != null;
    });
  }

  void _updateRecurrence() {
    final recurrence = EventRecurrenceModel(
      id: widget.initialRecurrence?.id ?? '',
      parentEventId: widget.initialRecurrence?.parentEventId ?? '',
      type: _type,
      interval: _interval,
      daysOfWeek: _type == RecurrenceType.weekly ? _selectedDaysOfWeek : null,
      dayOfMonth: _type == RecurrenceType.monthly ? _dayOfMonth : null,
      monthsOfYear: _type == RecurrenceType.yearly ? _selectedMonths : null,
      endDate: _hasEndDate ? _endDate : null,
      occurrenceCount: _hasOccurrenceLimit ? _occurrenceCount : null,
      exceptions: widget.initialRecurrence?.exceptions ?? [],
      overrides: widget.initialRecurrence?.overrides ?? [],
      isActive: true, // Forcé à true pour nouvelles récurrences
      createdAt: widget.initialRecurrence?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    print('🔄 Récurrence créée avec isActive: ${recurrence.isActive}');
    widget.onRecurrenceChanged(recurrence);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuration de la récurrence',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Type de récurrence
            _buildRecurrenceTypeSelector(),
            const SizedBox(height: 16),
            
            // Intervalle
            _buildIntervalSelector(),
            const SizedBox(height: 16),
            
            // Options spécifiques selon le type
            if (_type == RecurrenceType.weekly) _buildWeeklyOptions(),
            if (_type == RecurrenceType.monthly) _buildMonthlyOptions(),
            if (_type == RecurrenceType.yearly) _buildYearlyOptions(),
            
            const SizedBox(height: 16),
            
            // Fin de récurrence
            _buildEndOptions(),
            
            const SizedBox(height: 16),
            
            // Aperçu
            _buildPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurrenceTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Se répète',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<RecurrenceType>(
          value: _type,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: const [
            DropdownMenuItem(
              value: RecurrenceType.daily,
              child: Text('Quotidiennement'),
            ),
            DropdownMenuItem(
              value: RecurrenceType.weekly,
              child: Text('Hebdomadairement'),
            ),
            DropdownMenuItem(
              value: RecurrenceType.monthly,
              child: Text('Mensuellement'),
            ),
            DropdownMenuItem(
              value: RecurrenceType.yearly,
              child: Text('Annuellement'),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _type = value!;
              _updateRecurrence();
            });
          },
        ),
      ],
    );
  }

  Widget _buildIntervalSelector() {
    String label;
    switch (_type) {
      case RecurrenceType.daily:
        label = 'Tous les $_interval jour(s)';
        break;
      case RecurrenceType.weekly:
        label = 'Toutes les $_interval semaine(s)';
        break;
      case RecurrenceType.monthly:
        label = 'Tous les $_interval mois';
        break;
      case RecurrenceType.yearly:
        label = 'Tous les $_interval an(s)';
        break;
      case RecurrenceType.custom:
        label = 'Intervalle personnalisé';
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fréquence',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _interval.toDouble(),
                min: 1,
                max: 12,
                divisions: 11,
                label: label,
                onChanged: (value) {
                  setState(() {
                    _interval = value.round();
                    _updateRecurrence();
                  });
                },
              ),
            ),
            SizedBox(
              width: 60,
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeeklyOptions() {
    final days = [
      {'label': 'L', 'value': 1},
      {'label': 'M', 'value': 2},
      {'label': 'M', 'value': 3},
      {'label': 'J', 'value': 4},
      {'label': 'V', 'value': 5},
      {'label': 'S', 'value': 6},
      {'label': 'D', 'value': 7},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jours de la semaine',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: days.map((day) {
            final isSelected = _selectedDaysOfWeek.contains(day['value']);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedDaysOfWeek.remove(day['value']);
                  } else {
                    _selectedDaysOfWeek.add(day['value'] as int);
                  }
                  _updateRecurrence();
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected 
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade200,
                ),
                child: Center(
                  child: Text(
                    day['label'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMonthlyOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jour du mois',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: _dayOfMonth,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          hint: const Text('Sélectionner un jour'),
          items: List.generate(31, (index) => index + 1)
              .map((day) => DropdownMenuItem(
                    value: day,
                    child: Text('Le $day'),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _dayOfMonth = value;
              _updateRecurrence();
            });
          },
        ),
      ],
    );
  }

  Widget _buildYearlyOptions() {
    final months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mois de l\'année',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: months.asMap().entries.map((entry) {
            final index = entry.key + 1;
            final month = entry.value;
            final isSelected = _selectedMonths.contains(index);
            
            return FilterChip(
              label: Text(month),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedMonths.add(index);
                  } else {
                    _selectedMonths.remove(index);
                  }
                  _updateRecurrence();
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEndOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fin de la récurrence',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        
        // Option: Jamais
        RadioListTile<String>(
          title: const Text('Jamais'),
          value: 'never',
          groupValue: _hasEndDate 
              ? 'date' 
              : _hasOccurrenceLimit 
                  ? 'count' 
                  : 'never',
          onChanged: (value) {
            setState(() {
              _hasEndDate = false;
              _hasOccurrenceLimit = false;
              _updateRecurrence();
            });
          },
        ),
        
        // Option: À une date
        RadioListTile<String>(
          title: Row(
            children: [
              const Text('Le '),
              if (_hasEndDate && _endDate != null)
                Text(
                  '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              const Spacer(),
              if (_hasEndDate)
                TextButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                    );
                    if (date != null) {
                      setState(() {
                        _endDate = date;
                        _updateRecurrence();
                      });
                    }
                  },
                  child: const Text('Choisir'),
                ),
            ],
          ),
          value: 'date',
          groupValue: _hasEndDate 
              ? 'date' 
              : _hasOccurrenceLimit 
                  ? 'count' 
                  : 'never',
          onChanged: (value) {
            setState(() {
              _hasEndDate = true;
              _hasOccurrenceLimit = false;
              if (_endDate == null) {
                _endDate = DateTime.now().add(const Duration(days: 30));
              }
              _updateRecurrence();
            });
          },
        ),
        
        // Option: Après X occurrences
        RadioListTile<String>(
          title: Row(
            children: [
              const Text('Après '),
              if (_hasOccurrenceLimit)
                SizedBox(
                  width: 60,
                  child: TextFormField(
                    initialValue: _occurrenceCount?.toString() ?? '10',
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _occurrenceCount = int.tryParse(value) ?? 10;
                        _updateRecurrence();
                      });
                    },
                  ),
                ),
              const Text(' occurrences'),
            ],
          ),
          value: 'count',
          groupValue: _hasEndDate 
              ? 'date' 
              : _hasOccurrenceLimit 
                  ? 'count' 
                  : 'never',
          onChanged: (value) {
            setState(() {
              _hasEndDate = false;
              _hasOccurrenceLimit = true;
              if (_occurrenceCount == null) {
                _occurrenceCount = 10;
              }
              _updateRecurrence();
            });
          },
        ),
      ],
    );
  }

  Widget _buildPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Aperçu de la récurrence',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getRecurrenceDescription(),
            style: TextStyle(color: Colors.blue.shade800),
          ),
        ],
      ),
    );
  }

  String _getRecurrenceDescription() {
    String description = '';
    
    switch (_type) {
      case RecurrenceType.daily:
        description = _interval == 1 
            ? 'Tous les jours'
            : 'Tous les $_interval jours';
        break;
      case RecurrenceType.weekly:
        description = _interval == 1 
            ? 'Toutes les semaines'
            : 'Toutes les $_interval semaines';
        
        if (_selectedDaysOfWeek.isNotEmpty) {
          final dayNames = ['', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
          final selectedDayNames = _selectedDaysOfWeek
              .map((day) => dayNames[day])
              .join(', ');
          description += ' le $selectedDayNames';
        }
        break;
      case RecurrenceType.monthly:
        description = _interval == 1 
            ? 'Tous les mois'
            : 'Tous les $_interval mois';
        
        if (_dayOfMonth != null) {
          description += ' le $_dayOfMonth';
        }
        break;
      case RecurrenceType.yearly:
        description = _interval == 1 
            ? 'Tous les ans'
            : 'Tous les $_interval ans';
        
        if (_selectedMonths.isNotEmpty) {
          final monthNames = ['', 'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
                             'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
          final selectedMonthNames = _selectedMonths
              .map((month) => monthNames[month])
              .join(', ');
          description += ' en $selectedMonthNames';
        }
        break;
      case RecurrenceType.custom:
        description = 'Récurrence personnalisée';
        break;
    }
    
    if (_hasEndDate && _endDate != null) {
      description += ' jusqu\'au ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}';
    } else if (_hasOccurrenceLimit && _occurrenceCount != null) {
      description += ' pour $_occurrenceCount occurrences';
    }
    
    return description;
  }
}
