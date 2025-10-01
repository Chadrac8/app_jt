import 'package:flutter/material.dart';
import '../../theme.dart';

class TaskSearchFilterBar extends StatefulWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final Function(List<String>, List<String>, DateTime?, DateTime?) onFiltersChanged;
  final List<String> selectedStatusFilters;
  final List<String> selectedPriorityFilters;
  final DateTime? dueBefore;
  final DateTime? dueAfter;

  const TaskSearchFilterBar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onFiltersChanged,
    required this.selectedStatusFilters,
    required this.selectedPriorityFilters,
    this.dueBefore,
    this.dueAfter,
  });

  @override
  State<TaskSearchFilterBar> createState() => _TaskSearchFilterBarState();
}

class _TaskSearchFilterBarState extends State<TaskSearchFilterBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  bool _isFilterExpanded = false;
  bool _isSearchFocused = false;
  final FocusNode _searchFocusNode = FocusNode();

  final List<Map<String, String>> _statusOptions = [
    {'value': 'todo', 'label': 'À faire'},
    {'value': 'in_progress', 'label': 'En cours'},
    {'value': 'completed', 'label': 'Terminé'},
    {'value': 'cancelled', 'label': 'Annulé'},
  ];

  final List<Map<String, String>> _priorityOptions = [
    {'value': 'high', 'label': 'Haute'},
    {'value': 'medium', 'label': 'Moyenne'},
    {'value': 'low', 'label': 'Basse'},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _searchFocusNode.addListener(() {
      setState(() => _isSearchFocused = _searchFocusNode.hasFocus);
    });

    widget.searchController.addListener(() {
      widget.onSearchChanged(widget.searchController.text);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleFilters() {
    setState(() => _isFilterExpanded = !_isFilterExpanded);
    if (_isFilterExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _onStatusFilterChanged(String status, bool isSelected) {
    final newFilters = List<String>.from(widget.selectedStatusFilters);
    if (isSelected) {
      newFilters.add(status);
    } else {
      newFilters.remove(status);
    }
    widget.onFiltersChanged(newFilters, widget.selectedPriorityFilters, widget.dueBefore, widget.dueAfter);
  }

  void _onPriorityFilterChanged(String priority, bool isSelected) {
    final newFilters = List<String>.from(widget.selectedPriorityFilters);
    if (isSelected) {
      newFilters.add(priority);
    } else {
      newFilters.remove(priority);
    }
    widget.onFiltersChanged(widget.selectedStatusFilters, newFilters, widget.dueBefore, widget.dueAfter);
  }

  void _onDateRangeChanged(DateTime? dueBefore, DateTime? dueAfter) {
    widget.onFiltersChanged(widget.selectedStatusFilters, widget.selectedPriorityFilters, dueBefore, dueAfter);
  }

  void _clearAllFilters() {
    widget.onFiltersChanged([], [], null, null);
  }

  Future<void> _selectDateRange() async {
    final dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: widget.dueBefore != null && widget.dueAfter != null
          ? DateTimeRange(start: widget.dueAfter!, end: widget.dueBefore!)
          : null,
    );
    
    if (dateRange != null) {
      _onDateRangeChanged(dateRange.end, dateRange.start);
    }
  }

  int get _totalActiveFilters {
    return widget.selectedStatusFilters.length + 
           widget.selectedPriorityFilters.length + 
           (widget.dueBefore != null || widget.dueAfter != null ? 1 : 0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.backgroundColor,
      child: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Rechercher des tâches...',
                      prefixIcon: Icon(
                        Icons.search,
                        color: _isSearchFocused ? AppTheme.primaryColor : AppTheme.grey500,
                      ),
                      suffixIcon: widget.searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                widget.searchController.clear();
                                widget.onSearchChanged('');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppTheme.white100,
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.space12),
                // Filter button
                Material(
                  color: _isFilterExpanded ? AppTheme.primaryColor : AppTheme.white100,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  child: InkWell(
                    onTap: _toggleFilters,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        border: Border.all(
                          color: _isFilterExpanded ? AppTheme.primaryColor : AppTheme.grey300!,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Icon(
                              Icons.filter_list,
                              color: _isFilterExpanded ? AppTheme.white100 : AppTheme.grey600,
                            ),
                          ),
                          if (_totalActiveFilters > 0)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: AppTheme.errorColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '$_totalActiveFilters',
                                    style: const TextStyle(
                                      color: AppTheme.white100,
                                      fontSize: AppTheme.fontSize10,
                                      fontWeight: AppTheme.fontBold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Filters panel
          if (_isFilterExpanded)
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * _slideAnimation.value),
                    child: Container(
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.spaceMedium),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header with clear button
                              Row(
                                children: [
                                  Text(
                                    'Filtres',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: AppTheme.fontBold,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (_totalActiveFilters > 0)
                                    TextButton(
                                      onPressed: _clearAllFilters,
                                      child: const Text('Effacer tout'),
                                    ),
                                ],
                              ),
                              
                              const SizedBox(height: AppTheme.spaceMedium),
                              
                              // Status filters
                              Text(
                                'Statut',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: AppTheme.fontSemiBold,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spaceSmall),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _statusOptions.map((status) {
                                  final isSelected = widget.selectedStatusFilters.contains(status['value']);
                                  return FilterChip(
                                    label: Text(status['label']!),
                                    selected: isSelected,
                                    onSelected: (selected) => _onStatusFilterChanged(status['value']!, selected),
                                    selectedColor: AppTheme.primaryColor.withOpacity(0.3),
                                    checkmarkColor: AppTheme.primaryColor,
                                  );
                                }).toList(),
                              ),
                              
                              const SizedBox(height: AppTheme.spaceMedium),
                              
                              // Priority filters
                              Text(
                                'Priorité',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: AppTheme.fontSemiBold,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spaceSmall),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _priorityOptions.map((priority) {
                                  final isSelected = widget.selectedPriorityFilters.contains(priority['value']);
                                  Color priorityColor = AppTheme.warningColor;
                                  if (priority['value'] == 'high') priorityColor = AppTheme.errorColor;
                                  if (priority['value'] == 'low') priorityColor = AppTheme.successColor;
                                  
                                  return FilterChip(
                                    label: Text(priority['label']!),
                                    selected: isSelected,
                                    onSelected: (selected) => _onPriorityFilterChanged(priority['value']!, selected),
                                    selectedColor: priorityColor.withOpacity(0.3),
                                    checkmarkColor: priorityColor,
                                  );
                                }).toList(),
                              ),
                              
                              const SizedBox(height: AppTheme.spaceMedium),
                              
                              // Date range filter
                              Text(
                                'Échéance',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: AppTheme.fontSemiBold,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spaceSmall),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _selectDateRange,
                                      icon: const Icon(Icons.date_range),
                                      label: Text(
                                        widget.dueBefore != null && widget.dueAfter != null
                                            ? 'Période sélectionnée'
                                            : 'Sélectionner une période',
                                      ),
                                    ),
                                  ),
                                  if (widget.dueBefore != null || widget.dueAfter != null) ...[
                                    const SizedBox(width: AppTheme.spaceSmall),
                                    IconButton(
                                      onPressed: () => _onDateRangeChanged(null, null),
                                      icon: const Icon(Icons.clear),
                                      tooltip: 'Effacer la période',
                                    ),
                                  ],
                                ],
                              ),
                              
                              if (widget.dueBefore != null && widget.dueAfter != null) ...[
                                const SizedBox(height: AppTheme.spaceSmall),
                                Container(
                                  padding: const EdgeInsets.all(AppTheme.spaceSmall),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                  ),
                                  child: Text(
                                    'Du ${_formatDate(widget.dueAfter!)} au ${_formatDate(widget.dueBefore!)}',
                                    style: TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontSize: AppTheme.fontSize12,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'jan', 'fév', 'mar', 'avr', 'mai', 'jun',
      'jul', 'aoû', 'sep', 'oct', 'nov', 'déc'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }
}