import 'package:flutter/material.dart';
import '../models/recurrence_config.dart';
import '../../theme.dart';

/// 🔄 Widget de configuration de récurrence pour groupes
/// 
/// Permet de configurer la récurrence des événements générés automatiquement
/// Style Planning Center Online Groups
class GroupRecurrenceConfigWidget extends StatefulWidget {
  final RecurrenceConfig? initialConfig;
  final Function(RecurrenceConfig) onConfigChanged;
  final DateTime? startDate;
  final DateTime? endDate;

  const GroupRecurrenceConfigWidget({
    Key? key,
    this.initialConfig,
    required this.onConfigChanged,
    this.startDate,
    this.endDate,
  }) : super(key: key);

  @override
  State<GroupRecurrenceConfigWidget> createState() => _GroupRecurrenceConfigWidgetState();
}

class _GroupRecurrenceConfigWidgetState extends State<GroupRecurrenceConfigWidget> {
  late RecurrenceFrequency _frequency;
  late int _interval;
  late int _dayOfWeek;
  late String _time;
  late int _durationMinutes;
  late DateTime _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _initializeFromConfig();
  }

  void _initializeFromConfig() {
    if (widget.initialConfig != null) {
      _frequency = widget.initialConfig!.frequency;
      _interval = widget.initialConfig!.interval;
      _dayOfWeek = widget.initialConfig!.dayOfWeek ?? 1;
      _time = widget.initialConfig!.time;
      _durationMinutes = widget.initialConfig!.durationMinutes;
      _startDate = widget.initialConfig!.startDate;
      _endDate = widget.initialConfig!.endDate;
    } else {
      _frequency = RecurrenceFrequency.weekly;
      _interval = 1;
      _dayOfWeek = 1; // Lundi par défaut
      _time = '19:00';
      _durationMinutes = 120; // 2h par défaut
      _startDate = widget.startDate ?? DateTime.now();
      _endDate = widget.endDate;
    }
  }

  void _notifyChange() {
    final config = RecurrenceConfig(
      frequency: _frequency,
      interval: _interval,
      dayOfWeek: _dayOfWeek,
      time: _time,
      durationMinutes: _durationMinutes,
      startDate: _startDate,
      endDate: _endDate,
    );
    widget.onConfigChanged(config);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withAlpha(77), // 0.3 * 255 ≈ 77
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre
            Row(
              children: [
                Icon(
                  Icons.event_repeat,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppTheme.spaceSmall),
                Text(
                  'Configuration de récurrence',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: AppTheme.fontSemiBold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMedium),

            // Fréquence
            _buildFrequencySelector(),
            const SizedBox(height: AppTheme.spaceMedium),

            // Jour de la semaine (pour weekly/monthly)
            if (_frequency == RecurrenceFrequency.weekly || _frequency == RecurrenceFrequency.monthly)
              Column(
                children: [
                  _buildDayOfWeekSelector(),
                  const SizedBox(height: AppTheme.spaceMedium),
                ],
              ),

            // Heure et durée
            Row(
              children: [
                Expanded(
                  child: _buildTimePicker(),
                ),
                const SizedBox(width: AppTheme.spaceMedium),
                Expanded(
                  child: _buildDurationSelector(),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMedium),

            // Dates de début et fin
            Row(
              children: [
                Expanded(
                  child: _buildStartDatePicker(),
                ),
                const SizedBox(width: AppTheme.spaceMedium),
                Expanded(
                  child: _buildEndDatePicker(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fréquence',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(179), // 0.7 * 255
              ),
        ),
        const SizedBox(height: AppTheme.spaceSmall),
        SegmentedButton<RecurrenceFrequency>(
          segments: const [
            ButtonSegment(
              value: RecurrenceFrequency.daily,
              label: Text('Quotidien'),
              icon: Icon(Icons.today, size: 16),
            ),
            ButtonSegment(
              value: RecurrenceFrequency.weekly,
              label: Text('Hebdo'),
              icon: Icon(Icons.event, size: 16),
            ),
            ButtonSegment(
              value: RecurrenceFrequency.monthly,
              label: Text('Mensuel'),
              icon: Icon(Icons.calendar_month, size: 16),
            ),
          ],
          selected: {_frequency},
          onSelectionChanged: (Set<RecurrenceFrequency> selected) {
            setState(() {
              _frequency = selected.first;
              _notifyChange();
            });
          },
        ),
      ],
    );
  }

  Widget _buildDayOfWeekSelector() {
    final days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jour de la semaine',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
              ),
        ),
        const SizedBox(height: AppTheme.spaceSmall),
        Wrap(
          spacing: AppTheme.spaceSmall,
          children: List.generate(7, (index) {
            final dayIndex = index + 1;
            final isSelected = _dayOfWeek == dayIndex;
            
            return FilterChip(
              label: Text(days[index]),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _dayOfWeek = dayIndex;
                    _notifyChange();
                  });
                }
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTimePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Heure',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
              ),
        ),
        const SizedBox(height: AppTheme.spaceSmall),
        InkWell(
          onTap: () async {
            final timeParts = _time.split(':');
            final initialTime = TimeOfDay(
              hour: int.parse(timeParts[0]),
              minute: int.parse(timeParts[1]),
            );
            
            final pickedTime = await showTimePicker(
              context: context,
              initialTime: initialTime,
            );
            
            if (pickedTime != null) {
              setState(() {
                _time = '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
                _notifyChange();
              });
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space12,
                vertical: AppTheme.space12,
              ),
              suffixIcon: const Icon(Icons.access_time, size: 20),
            ),
            child: Text(_time),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Durée',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
              ),
        ),
        const SizedBox(height: AppTheme.spaceSmall),
        DropdownButtonFormField<int>(
          value: _durationMinutes,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space12,
              vertical: AppTheme.space12,
            ),
          ),
          items: const [
            DropdownMenuItem(value: 60, child: Text('1h')),
            DropdownMenuItem(value: 90, child: Text('1h30')),
            DropdownMenuItem(value: 120, child: Text('2h')),
            DropdownMenuItem(value: 150, child: Text('2h30')),
            DropdownMenuItem(value: 180, child: Text('3h')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _durationMinutes = value;
                _notifyChange();
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildStartDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date de début',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
              ),
        ),
        const SizedBox(height: AppTheme.spaceSmall),
        InkWell(
          onTap: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: _startDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 730)),
            );
            
            if (pickedDate != null) {
              setState(() {
                _startDate = pickedDate;
                _notifyChange();
              });
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space12,
                vertical: AppTheme.space12,
              ),
              suffixIcon: const Icon(Icons.calendar_today, size: 20),
            ),
            child: Text('${_startDate.day}/${_startDate.month}/${_startDate.year}'),
          ),
        ),
      ],
    );
  }

  Widget _buildEndDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date de fin (optionnel)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
              ),
        ),
        const SizedBox(height: AppTheme.spaceSmall),
        InkWell(
          onTap: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: _endDate ?? _startDate.add(const Duration(days: 180)),
              firstDate: _startDate,
              lastDate: DateTime.now().add(const Duration(days: 730)),
            );
            
            setState(() {
              _endDate = pickedDate;
              _notifyChange();
            });
          },
          child: InputDecorator(
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space12,
                vertical: AppTheme.space12,
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_endDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        setState(() {
                          _endDate = null;
                          _notifyChange();
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  const SizedBox(width: AppTheme.spaceSmall),
                  const Icon(Icons.calendar_today, size: 20),
                  const SizedBox(width: AppTheme.spaceSmall),
                ],
              ),
            ),
            child: Text(_endDate != null 
                ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                : 'Aucune'),
          ),
        ),
      ],
    );
  }
}
