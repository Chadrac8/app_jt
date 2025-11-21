import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme.dart';

/// Widget moderne pour configurer la récurrence de services
/// Inspiré de Planning Center Online avec toutes les options avancées
class ServiceRecurrenceWidget extends StatefulWidget {
  final Map<String, dynamic>? initialPattern;
  final DateTime startDate;
  final Function(Map<String, dynamic>?) onRecurrenceChanged;

  const ServiceRecurrenceWidget({
    Key? key,
    this.initialPattern,
    required this.startDate,
    required this.onRecurrenceChanged,
  }) : super(key: key);

  @override
  State<ServiceRecurrenceWidget> createState() => _ServiceRecurrenceWidgetState();
}

class _ServiceRecurrenceWidgetState extends State<ServiceRecurrenceWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Configuration de récurrence
  String _frequency = 'weekly'; // daily, weekly, monthly, yearly
  int _interval = 1;
  List<int> _selectedWeekDays = [];
  int? _dayOfMonth;
  int? _monthOfYear;
  
  // Type de fin
  String _endType = 'never'; // never, date, occurrences
  DateTime? _endDate;
  int? _maxOccurrences;
  
  // Exceptions
  List<DateTime> _exceptions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialPattern();
    _updateSelectedWeekDays();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadInitialPattern() {
    if (widget.initialPattern != null) {
      final pattern = widget.initialPattern!;
      _frequency = pattern['type'] ?? 'weekly';
      _interval = pattern['interval'] ?? 1;
      _selectedWeekDays = List<int>.from(pattern['daysOfWeek'] ?? []);
      _dayOfMonth = pattern['dayOfMonth'];
      _monthOfYear = pattern['monthOfYear'];
      
      if (pattern['endDate'] != null) {
        _endType = 'date';
        _endDate = DateTime.parse(pattern['endDate']);
      } else if (pattern['occurrenceCount'] != null) {
        _endType = 'occurrences';
        _maxOccurrences = pattern['occurrenceCount'];
      } else {
        _endType = 'never';
      }
      
      // Charger les exceptions
      if (pattern['exceptions'] != null) {
        _exceptions = (pattern['exceptions'] as List)
            .map((e) => DateTime.parse(e))
            .toList();
      }
    }
  }

  void _updateSelectedWeekDays() {
    if (_selectedWeekDays.isEmpty && _frequency == 'weekly') {
      _selectedWeekDays = [widget.startDate.weekday];
    }
  }

  Map<String, dynamic> _buildRecurrencePattern() {
    final pattern = <String, dynamic>{
      'type': _frequency,
      'interval': _interval,
    };

    if (_frequency == 'weekly' && _selectedWeekDays.isNotEmpty) {
      pattern['daysOfWeek'] = _selectedWeekDays;
    }

    if (_frequency == 'monthly' && _dayOfMonth != null) {
      pattern['dayOfMonth'] = _dayOfMonth;
    }

    if (_frequency == 'yearly') {
      pattern['monthOfYear'] = _monthOfYear ?? widget.startDate.month;
      pattern['dayOfMonth'] = _dayOfMonth ?? widget.startDate.day;
    }

    switch (_endType) {
      case 'date':
        if (_endDate != null) {
          pattern['endDate'] = _endDate!.toIso8601String();
        }
        break;
      case 'occurrences':
        if (_maxOccurrences != null) {
          pattern['occurrenceCount'] = _maxOccurrences;
        }
        break;
    }

    if (_exceptions.isNotEmpty) {
      pattern['exceptions'] = _exceptions.map((e) => e.toIso8601String()).toList();
    }

    return pattern;
  }

  void _notifyChange() {
    widget.onRecurrenceChanged(_buildRecurrencePattern());
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec tabs
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusSmall),
                topRight: Radius.circular(AppTheme.radiusSmall),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.repeat), text: 'Récurrence'),
                Tab(icon: Icon(Icons.event_busy), text: 'Fin'),
                Tab(icon: Icon(Icons.block), text: 'Exceptions'),
              ],
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              indicatorColor: Theme.of(context).colorScheme.primary,
            ),
          ),
          
          // Content avec TabBarView
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFrequencyTab(),
                _buildEndTab(),
                _buildExceptionsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyTab() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fréquence
          Text(
            'Fréquence',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          
          Wrap(
            spacing: AppTheme.spaceSmall,
            children: [
              _buildFrequencyChip('daily', 'Quotidien', Icons.today),
              _buildFrequencyChip('weekly', 'Hebdomadaire', Icons.view_week),
              _buildFrequencyChip('monthly', 'Mensuel', Icons.calendar_month),
              _buildFrequencyChip('yearly', 'Annuel', Icons.calendar_today),
            ],
          ),
          
          const SizedBox(height: AppTheme.spaceMedium),
          
          // Intervalle
          Text(
            'Intervalle',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          
          Row(
            children: [
              Text('Tous les'),
              const SizedBox(width: AppTheme.spaceSmall),
              SizedBox(
                width: 80,
                child: TextFormField(
                  initialValue: _interval.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (value) {
                    final newInterval = int.tryParse(value);
                    if (newInterval != null && newInterval > 0) {
                      setState(() => _interval = newInterval);
                      _notifyChange();
                    }
                  },
                ),
              ),
              const SizedBox(width: AppTheme.spaceSmall),
              Text(_getIntervalLabel()),
            ],
          ),
          
          const SizedBox(height: AppTheme.spaceMedium),
          
          // Options spécifiques à la fréquence
          if (_frequency == 'weekly') _buildWeeklyOptions(),
          if (_frequency == 'monthly') _buildMonthlyOptions(),
          if (_frequency == 'yearly') _buildYearlyOptions(),
        ],
      ),
    );
  }

  Widget _buildFrequencyChip(String value, String label, IconData icon) {
    final isSelected = _frequency == value;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _frequency = value;
            _updateSelectedWeekDays();
          });
          _notifyChange();
        }
      },
      backgroundColor: isSelected 
          ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
          : null,
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
    );
  }

  String _getIntervalLabel() {
    switch (_frequency) {
      case 'daily':
        return _interval == 1 ? 'jour' : 'jours';
      case 'weekly':
        return _interval == 1 ? 'semaine' : 'semaines';
      case 'monthly':
        return _interval == 1 ? 'mois' : 'mois';
      case 'yearly':
        return _interval == 1 ? 'an' : 'ans';
      default:
        return '';
    }
  }

  Widget _buildWeeklyOptions() {
    const weekDays = [
      (1, 'Lun'),
      (2, 'Mar'),
      (3, 'Mer'),
      (4, 'Jeu'),
      (5, 'Ven'),
      (6, 'Sam'),
      (7, 'Dim'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jours de la semaine',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spaceSmall),
        
        Wrap(
          spacing: AppTheme.spaceSmall,
          children: weekDays.map((day) {
            final isSelected = _selectedWeekDays.contains(day.$1);
            return FilterChip(
              selected: isSelected,
              label: Text(day.$2),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedWeekDays.add(day.$1);
                  } else {
                    _selectedWeekDays.remove(day.$1);
                  }
                  _selectedWeekDays.sort();
                });
                _notifyChange();
              },
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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spaceSmall),
        
        Row(
          children: [
            Text('Le'),
            const SizedBox(width: AppTheme.spaceSmall),
            SizedBox(
              width: 80,
              child: TextFormField(
                initialValue: (_dayOfMonth ?? widget.startDate.day).toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onChanged: (value) {
                  final day = int.tryParse(value);
                  if (day != null && day >= 1 && day <= 31) {
                    setState(() => _dayOfMonth = day);
                    _notifyChange();
                  }
                },
              ),
            ),
            const SizedBox(width: AppTheme.spaceSmall),
            Text('de chaque mois'),
          ],
        ),
      ],
    );
  }

  Widget _buildYearlyOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date annuelle',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spaceSmall),
        
        Row(
          children: [
            Text('Le'),
            const SizedBox(width: AppTheme.spaceSmall),
            SizedBox(
              width: 80,
              child: TextFormField(
                initialValue: (_dayOfMonth ?? widget.startDate.day).toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onChanged: (value) {
                  final day = int.tryParse(value);
                  if (day != null && day >= 1 && day <= 31) {
                    setState(() => _dayOfMonth = day);
                    _notifyChange();
                  }
                },
              ),
            ),
            const SizedBox(width: AppTheme.spaceSmall),
            Text('du mois'),
            const SizedBox(width: AppTheme.spaceSmall),
            SizedBox(
              width: 80,
              child: TextFormField(
                initialValue: (_monthOfYear ?? widget.startDate.month).toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onChanged: (value) {
                  final month = int.tryParse(value);
                  if (month != null && month >= 1 && month <= 12) {
                    setState(() => _monthOfYear = month);
                    _notifyChange();
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEndTab() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fin de récurrence',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          
          // Options de fin
          RadioListTile<String>(
            title: const Text('Jamais'),
            subtitle: const Text('La récurrence continue indéfiniment'),
            value: 'never',
            groupValue: _endType,
            onChanged: (value) {
              setState(() => _endType = value!);
              _notifyChange();
            },
          ),
          
          RadioListTile<String>(
            title: const Text('Le'),
            subtitle: _endDate != null 
                ? Text(DateFormat('dd/MM/yyyy').format(_endDate!))
                : const Text('Choisir une date de fin'),
            value: 'date',
            groupValue: _endType,
            onChanged: (value) {
              setState(() => _endType = value!);
              if (_endDate == null) {
                _selectEndDate();
              }
              _notifyChange();
            },
          ),
          
          if (_endType == 'date') ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
              child: ElevatedButton.icon(
                onPressed: _selectEndDate,
                icon: const Icon(Icons.calendar_today),
                label: Text(_endDate != null 
                    ? 'Modifier la date'
                    : 'Choisir la date'),
              ),
            ),
          ],
          
          RadioListTile<String>(
            title: const Text('Après'),
            subtitle: _maxOccurrences != null 
                ? Text('$_maxOccurrences occurrences')
                : const Text('Choisir le nombre d\'occurrences'),
            value: 'occurrences',
            groupValue: _endType,
            onChanged: (value) {
              setState(() => _endType = value!);
              _notifyChange();
            }, 
          ),
          
          if (_endType == 'occurrences') ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
              child: Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: TextFormField(
                      initialValue: (_maxOccurrences ?? 10).toString(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Nombre',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (value) {
                        final occurrences = int.tryParse(value);
                        if (occurrences != null && occurrences > 0) {
                          setState(() => _maxOccurrences = occurrences);
                          _notifyChange();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceSmall),
                  const Text('occurrences'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExceptionsTab() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dates d\'exception',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _addException,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter'),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spaceSmall),
          
          Text(
            'Ces dates seront exclues de la récurrence',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          
          const SizedBox(height: AppTheme.spaceMedium),
          
          if (_exceptions.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: AppTheme.spaceSmall),
                  Text(
                    'Aucune exception définie',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _exceptions.length,
                itemBuilder: (context, index) {
                  final exception = _exceptions[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.block),
                      title: Text(DateFormat('EEEE dd/MM/yyyy', 'fr_FR').format(exception)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _removeException(index),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: widget.startDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    
    if (date != null) {
      setState(() => _endDate = date);
      _notifyChange();
    }
  }

  Future<void> _addException() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: widget.startDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    
    if (date != null && !_exceptions.contains(date)) {
      setState(() {
        _exceptions.add(date);
        _exceptions.sort();
      });
      _notifyChange();
    }
  }

  void _removeException(int index) {
    setState(() => _exceptions.removeAt(index));
    _notifyChange();
  }
}