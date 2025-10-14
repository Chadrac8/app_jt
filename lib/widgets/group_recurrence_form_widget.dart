import 'package:flutter/material.dart';
import '../models/recurrence_config.dart';

/// 📅 Widget formulaire configuration récurrence groupe (Planning Center style)
/// 
/// Permet de configurer:
/// - Fréquence: daily, weekly, monthly, yearly
/// - Jour de la semaine (si weekly)
/// - Heure début
/// - Durée réunion
/// - Date début/fin ou nombre max occurrences
/// 
/// Usage:
/// ```dart
/// GroupRecurrenceFormWidget(
///   initialConfig: existingConfig,
///   onConfigChanged: (config) {
///     setState(() => _recurrenceConfig = config);
///   },
/// )
/// ```
class GroupRecurrenceFormWidget extends StatefulWidget {
  final RecurrenceConfig? initialConfig;
  final Function(RecurrenceConfig) onConfigChanged;
  final bool enabled;

  const GroupRecurrenceFormWidget({
    Key? key,
    this.initialConfig,
    required this.onConfigChanged,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<GroupRecurrenceFormWidget> createState() => _GroupRecurrenceFormWidgetState();
}

class _GroupRecurrenceFormWidgetState extends State<GroupRecurrenceFormWidget> {
  late RecurrenceFrequency _frequency;
  late int _interval;
  late int? _dayOfWeek;
  late TimeOfDay _time;
  late int _durationMinutes;
  late bool _useEndDate;
  DateTime? _endDate;
  int? _maxOccurrences;

  @override
  void initState() {
    super.initState();
    _initializeFromConfig();
  }

  void _initializeFromConfig() {
    final config = widget.initialConfig;
    if (config != null) {
      _frequency = config.frequency;
      _interval = config.interval;
      _dayOfWeek = config.dayOfWeek;
      // Convertir "HH:mm" en TimeOfDay
      final timeParts = config.time.split(':');
      _time = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );
      _durationMinutes = config.durationMinutes;
      _useEndDate = config.endDate != null;
      _endDate = config.endDate;
      _maxOccurrences = config.maxOccurrences ?? 26;
    } else {
      // Valeurs par défaut: Tous les vendredis 19h30 pendant 2h
      _frequency = RecurrenceFrequency.weekly;
      _interval = 1;
      _dayOfWeek = 5; // Vendredi
      _time = const TimeOfDay(hour: 19, minute: 30);
      _durationMinutes = 120; // 2h
      _useEndDate = false;
      _maxOccurrences = 26;
    }
  }

  void _notifyChange() {
    final config = RecurrenceConfig(
      frequency: _frequency,
      interval: _interval,
      dayOfWeek: _dayOfWeek,
      time: '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
      durationMinutes: _durationMinutes,
      startDate: DateTime.now(), // Sera overridé par le parent
    );
    widget.onConfigChanged(config);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                Icon(Icons.event_repeat, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Réunions récurrentes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Description générée
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _generateDescription(),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Fréquence
            _buildFrequencySelector(),
            const SizedBox(height: 16),

            // Intervalle (si > 1)
            if (_frequency != RecurrenceFrequency.custom)
              _buildIntervalSelector(),

            // Jour de la semaine (si weekly)
            if (_frequency == RecurrenceFrequency.weekly) ...[
              const SizedBox(height: 16),
              _buildDayOfWeekSelector(),
            ],

            const SizedBox(height: 16),

            // Heure et durée
            Row(
              children: [
                Expanded(child: _buildTimeSelector()),
                const SizedBox(width: 16),
                Expanded(child: _buildDurationSelector()),
              ],
            ),

            const SizedBox(height: 24),

            // Date fin ou nombre max
            _buildEndConditionSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fréquence',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Quotidien'),
              selected: _frequency == RecurrenceFrequency.daily,
              onSelected: widget.enabled ? (selected) {
                if (selected) {
                  setState(() => _frequency = RecurrenceFrequency.daily);
                  _notifyChange();
                }
              } : null,
            ),
            ChoiceChip(
              label: const Text('Hebdomadaire'),
              selected: _frequency == RecurrenceFrequency.weekly,
              onSelected: widget.enabled ? (selected) {
                if (selected) {
                  setState(() {
                    _frequency = RecurrenceFrequency.weekly;
                    if (_dayOfWeek == null) {
                      _dayOfWeek = DateTime.now().weekday;
                    }
                  });
                  _notifyChange();
                }
              } : null,
            ),
            ChoiceChip(
              label: const Text('Mensuel'),
              selected: _frequency == RecurrenceFrequency.monthly,
              onSelected: widget.enabled ? (selected) {
                if (selected) {
                  setState(() => _frequency = RecurrenceFrequency.monthly);
                  _notifyChange();
                }
              } : null,
            ),
            ChoiceChip(
              label: const Text('Annuel'),
              selected: _frequency == RecurrenceFrequency.yearly,
              onSelected: widget.enabled ? (selected) {
                if (selected) {
                  setState(() => _frequency = RecurrenceFrequency.yearly);
                  _notifyChange();
                }
              } : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIntervalSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Répéter tous les',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            SizedBox(
              width: 80,
              child: DropdownButtonFormField<int>(
                value: _interval,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: List.generate(10, (i) => i + 1).map((val) {
                  return DropdownMenuItem(
                    value: val,
                    child: Text('$val'),
                  );
                }).toList(),
                onChanged: widget.enabled
                    ? (value) {
                        if (value != null) {
                          setState(() => _interval = value);
                          _notifyChange();
                        }
                      }
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            Text(_getIntervalLabel()),
          ],
        ),
      ],
    );
  }

  Widget _buildDayOfWeekSelector() {
    const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Jour de la semaine',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: List.generate(7, (index) {
            final dayNum = index + 1; // 1=Lundi, 7=Dimanche
            return ChoiceChip(
              label: Text(days[index]),
              selected: _dayOfWeek == dayNum,
              onSelected: widget.enabled
                  ? (selected) {
                      if (selected) {
                        setState(() => _dayOfWeek = dayNum);
                        _notifyChange();
                      }
                    }
                  : null,
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTimeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Heure début',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: widget.enabled ? _selectTime : null,
          child: InputDecorator(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.access_time),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text(
              _time.format(context),
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationSelector() {
    final durations = [
      30,   // 30 minutes
      60,   // 1 heure
      90,   // 1h30
      120,  // 2 heures
      180,  // 3 heures
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Durée',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: _durationMinutes,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.timer),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: durations.map((minutes) {
            return DropdownMenuItem(
              value: minutes,
              child: Text(_formatDurationMinutes(minutes)),
            );
          }).toList(),
          onChanged: widget.enabled
              ? (value) {
                  if (value != null) {
                    setState(() => _durationMinutes = value);
                    _notifyChange();
                  }
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildEndConditionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fin de récurrence',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        
        // Option: Date fin
        RadioListTile<bool>(
          title: const Text('Date de fin'),
          value: true,
          groupValue: _useEndDate,
          onChanged: widget.enabled
              ? (value) {
                  if (value != null) {
                    setState(() => _useEndDate = value);
                  }
                }
              : null,
        ),
        if (_useEndDate)
          Padding(
            padding: const EdgeInsets.only(left: 56, bottom: 8),
            child: InkWell(
              onTap: widget.enabled ? _selectEndDate : null,
              child: InputDecorator(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: Text(
                  _endDate != null
                      ? _formatDate(_endDate!)
                      : 'Sélectionner une date',
                  style: TextStyle(
                    fontSize: 14,
                    color: _endDate != null ? null : Colors.grey,
                  ),
                ),
              ),
            ),
          ),

        // Option: Nombre max occurrences
        RadioListTile<bool>(
          title: const Text('Nombre de réunions'),
          value: false,
          groupValue: _useEndDate,
          onChanged: widget.enabled
              ? (value) {
                  if (value != null) {
                    setState(() => _useEndDate = value);
                  }
                }
              : null,
        ),
        if (!_useEndDate)
          Padding(
            padding: const EdgeInsets.only(left: 56),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    initialValue: _maxOccurrences?.toString() ?? '26',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      suffixText: 'fois',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    enabled: widget.enabled,
                    onChanged: (value) {
                      final num = int.tryParse(value);
                      if (num != null && num > 0) {
                        setState(() => _maxOccurrences = num);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _maxOccurrences != null && _maxOccurrences! > 1
                      ? 'réunions'
                      : 'réunion',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _time = picked);
      _notifyChange();
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now().add(const Duration(days: 180)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      helpText: 'Date de fin des réunions',
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  String _generateDescription() {
    final config = RecurrenceConfig(
      frequency: _frequency,
      interval: _interval,
      dayOfWeek: _dayOfWeek,
      time: '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
      durationMinutes: _durationMinutes,
      startDate: DateTime.now(),
    );
    return config.description;
  }

  String _getIntervalLabel() {
    switch (_frequency) {
      case RecurrenceFrequency.daily:
        return _interval > 1 ? 'jours' : 'jour';
      case RecurrenceFrequency.weekly:
        return _interval > 1 ? 'semaines' : 'semaine';
      case RecurrenceFrequency.monthly:
        return _interval > 1 ? 'mois' : 'mois';
      case RecurrenceFrequency.yearly:
        return _interval > 1 ? 'ans' : 'an';
      case RecurrenceFrequency.custom:
        return '';
    }
  }

  String _formatDurationMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    
    if (hours > 0 && remainingMinutes > 0) {
      return '${hours}h${remainingMinutes}';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}min';
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // Getters pour récupérer valeurs
  DateTime? get endDate => _useEndDate ? _endDate : null;
  int? get maxOccurrences => !_useEndDate ? _maxOccurrences : null;
}
