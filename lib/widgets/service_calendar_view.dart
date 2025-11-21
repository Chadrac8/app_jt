import 'package:flutter/material.dart';
import '../models/service_model.dart';
import '../models/calendar_item.dart';
import '../theme.dart';

class ServiceCalendarView extends StatefulWidget {
  final List<ServiceModel> services;
  final Function(ServiceModel) onServiceTap;
  final Function(ServiceModel) onServiceLongPress;
  final Function(DateTime)? onQuickCreate; // Création rapide par date
  final Function(ServiceModel, DateTime)? onServiceMove; // Drag & drop
  final bool isSelectionMode;
  final List<ServiceModel> selectedServices;
  final Function(ServiceModel, bool) onSelectionChanged;
  
  // Filtres intégrés
  final List<String>? typeFilters;
  final List<String>? statusFilters;
  final String? searchQuery;
  final bool showRecurringSeries; // Afficher séries récurrentes

  const ServiceCalendarView({
    super.key,
    required this.services,
    required this.onServiceTap,
    required this.onServiceLongPress,
    this.onQuickCreate,
    this.onServiceMove,
    required this.isSelectionMode,
    required this.selectedServices,
    required this.onSelectionChanged,
    this.typeFilters,
    this.statusFilters,
    this.searchQuery,
    this.showRecurringSeries = true,
  });

  @override
  State<ServiceCalendarView> createState() => _ServiceCalendarViewState();
}

class _ServiceCalendarViewState extends State<ServiceCalendarView>
    with TickerProviderStateMixin {
  late DateTime _currentMonth;
  late PageController _pageController;
  late TabController _viewTabController;
  
  // Cache et état
  final Map<String, List<CalendarItem>> _monthCache = {};
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    _pageController = PageController(initialPage: 1000); // Page infinie
    _viewTabController = TabController(length: 3, vsync: this);
    _loadCalendarData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _viewTabController.dispose();
    super.dispose();
  }

  void _previousMonth() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextMonth() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToToday() {
    final now = DateTime.now();
    final monthsDiff = (now.year - _currentMonth.year) * 12 + (now.month - _currentMonth.month);
    _pageController.animateToPage(
      1000 + monthsDiff,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
  
  void _onPageChanged(int pageIndex) {
    final monthsDiff = pageIndex - 1000;
    final now = DateTime.now();
    setState(() {
      _currentMonth = DateTime(now.year + (monthsDiff ~/ 12), now.month + (monthsDiff % 12));
    });
    _loadCalendarData();
  }
  
  // Chargement intelligent des données calendrier
  Future<void> _loadCalendarData() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    final monthKey = '${_currentMonth.year}-${_currentMonth.month}';
    
    if (!_monthCache.containsKey(monthKey)) {
      try {
        final items = await _getCalendarItemsForMonth(_currentMonth);
        _monthCache[monthKey] = items;
      } catch (e) {
        print('Erreur chargement calendrier: $e');
      }
    }
    
    setState(() => _isLoading = false);
  }
  
  // Combinaison services + événements + occurrences
  Future<List<CalendarItem>> _getCalendarItemsForMonth(DateTime month) async {
    final items = <CalendarItem>[];
    
    // 1. Services directs du mois
    final monthServices = widget.services.where((service) {
      return service.dateTime.year == month.year && service.dateTime.month == month.month;
    }).toList();
    
    // 2. Occurrences récurrentes pour ce mois
    if (widget.showRecurringSeries) {
    // TODO: Ajouter ici la logique de récurrence quand ServiceRecurrenceService sera prêt
    // Pour l'instant, on charge juste les services directs
    }
    
    // 3. Convertir en CalendarItem et ajouter événements liés
    for (final service in monthServices) {
      if (_passesFilters(service)) {
        final item = CalendarItem.fromService(service);
        
        // Charger événement lié si disponible
        if (service.linkedEventId != null) {
          try {
            // TODO: Implémenter chargement des événements liés
            print('Événement lié détecté: ${service.linkedEventId}');
          } catch (e) {
            print('Erreur événement lié: $e');
          }
        }
        
        items.add(item);
      }
    }
    
    return items;
  }
  
  bool _passesFilters(ServiceModel service) {
    // Filtre par type
    if (widget.typeFilters != null && widget.typeFilters!.isNotEmpty) {
      if (!widget.typeFilters!.contains(service.type)) return false;
    }
    
    // Filtre par statut
    if (widget.statusFilters != null && widget.statusFilters!.isNotEmpty) {
      if (!widget.statusFilters!.contains(service.status)) return false;
    }
    
    // Filtre par recherche
    if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
      final query = widget.searchQuery!.toLowerCase();
      if (!service.name.toLowerCase().contains(query) &&
          !(service.description?.toLowerCase().contains(query) ?? false)) {
        return false;
      }
    }
    
    return true;
  }

  List<CalendarItem> _getItemsForDate(DateTime date) {
    final monthKey = '${date.year}-${date.month}';
    final monthItems = _monthCache[monthKey] ?? [];
    
    return monthItems.where((item) {
      return item.dateTime.year == date.year &&
             item.dateTime.month == date.month &&
             item.dateTime.day == date.day;
    }).toList();
  }
  
  // Rétrocompatibilité pour l'ancien code
  List<ServiceModel> _getServicesForDate(DateTime date) {
    final items = _getItemsForDate(date);
    return items.where((item) => item.sourceService != null)
        .map((item) => item.sourceService!)
        .toList();
  }

  Color _getServiceColor(ServiceModel service) {
    switch (service.status) {
      case 'publie': return AppTheme.greenStandard;
      case 'brouillon': return AppTheme.orangeStandard;
      case 'archive': return AppTheme.grey500;
      case 'annule': return AppTheme.redStandard;
      default: return AppTheme.blueStandard;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Calendar Header avec filtres rapides
        _buildCalendarHeader(context),

        // Weekday Headers
        _buildWeekdayHeaders(context),

        // Calendar PageView pour navigation fluide
        Expanded(
          child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (context, pageIndex) {
                    return _buildCalendarGrid();
                  },
                ),
        ),
      ],
    );
  }
  
  Widget _buildCalendarHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          // Navigation principale
          Row(
            children: [
              IconButton(
                onPressed: _previousMonth,
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Mois précédent',
              ),
              Expanded(
                child: Center(
                  child: Text(
                    _getMonthYear(_currentMonth),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: AppTheme.fontBold,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Mois suivant',
              ),
              const SizedBox(width: AppTheme.spaceSmall),
              TextButton(
                onPressed: _goToToday,
                child: const Text('Aujourd\'hui'),
              ),
            ],
          ),
          
          // Filtres rapides si activés
          if (widget.typeFilters != null || widget.statusFilters != null || widget.searchQuery != null)
            const SizedBox(height: AppTheme.spaceSmall),
          if (widget.typeFilters != null || widget.statusFilters != null || widget.searchQuery != null)
            _buildQuickFilters(context),
        ],
      ),
    );
  }
  
  Widget _buildQuickFilters(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        if (widget.typeFilters != null && widget.typeFilters!.isNotEmpty)
          ...widget.typeFilters!.map((type) => Chip(
            label: Text(type),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          )),
        if (widget.statusFilters != null && widget.statusFilters!.isNotEmpty)
          ...widget.statusFilters!.map((status) => Chip(
            label: Text(status),
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          )),
        if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty)
          Chip(
            label: Text('"${widget.searchQuery}"'),
            backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
          ),
      ],
    );
  }
  
  Widget _buildWeekdayHeaders(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(77),
      ),
      child: Row(
        children: ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'].map((day) {
          return Expanded(
            child: Center(
              child: Text(
                day,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: AppTheme.fontSemiBold,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;

    // Calculate days to show (including previous/next month days)
    final totalCells = ((daysInMonth + firstWeekday - 1) / 7).ceil() * 7;
    final startDate = firstDayOfMonth.subtract(Duration(days: firstWeekday - 1));

    return GridView.builder(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.8,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        final date = startDate.add(Duration(days: index));
        final isCurrentMonth = date.month == _currentMonth.month;
        final isToday = _isToday(date);
        final services = _getServicesForDate(date);

        return _buildCalendarCell(date, isCurrentMonth, isToday, services);
      },
    );
  }

  Widget _buildCalendarCell(DateTime date, bool isCurrentMonth, bool isToday, List<ServiceModel> services) {
    return Container(
      decoration: BoxDecoration(
        color: isToday
            ? Theme.of(context).colorScheme.primary.withAlpha(25) // 0.1 opacity
            : Colors.transparent,
        border: Border.all(
                color: Theme.of(context).colorScheme.outline.withAlpha(51), // 0.2 opacity
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        onTap: services.isNotEmpty 
            ? () => _showDayServices(date, services) 
            : (widget.onQuickCreate != null 
                ? () => widget.onQuickCreate!(date) 
                : null),
        onDoubleTap: widget.onQuickCreate != null 
            ? () => widget.onQuickCreate!(date) 
            : null,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceXSmall),
          child: Column(
            children: [
              // Date number
              Text(
                date.day.toString(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isToday ? AppTheme.fontBold : FontWeight.normal,
                  color: isCurrentMonth
                      ? (isToday 
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface)
                      : Theme.of(context).colorScheme.onSurface.withAlpha(102), // 0.4 opacity
                ),
              ),
              
              // Service indicators avec améliorations visuelles
              Expanded(
                child: services.isEmpty
                    ? (widget.onQuickCreate != null 
                        ? Center(
                            child: Icon(
                              Icons.add_circle_outline,
                              size: 16,
                              color: Theme.of(context).colorScheme.outline.withAlpha(128),
                            ),
                          )
                        : const SizedBox.shrink())
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            ...services.take(3).map((service) {
                              return Container(
                                width: double.infinity,
                                height: 4,
                                margin: const EdgeInsets.symmetric(vertical: 1),
                                decoration: BoxDecoration(
                                  color: _getServiceColor(service),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: service.isRecurring 
                                    ? Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 1),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withAlpha(128),
                                          borderRadius: BorderRadius.circular(1),
                                        ),
                                      )
                                    : null,
                              );
                            }).toList(),
                            if (services.length > 3)
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.outline.withAlpha(51),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '+${services.length - 3}',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontSize: 8,
                                    color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDayServices(DateTime date, List<ServiceModel> services) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(51),
                  borderRadius: BorderRadius.circular(AppTheme.radius2),
                ),
              ),

              // Header avec actions
              Padding(
                padding: const EdgeInsets.all(AppTheme.spaceMedium),
                child: Row(
                  children: [
                    Icon(
                      Icons.event,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: AppTheme.spaceSmall),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDate(date),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: AppTheme.fontBold,
                            ),
                          ),
                          Text(
                            '${services.length} service${services.length > 1 ? 's' : ''}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.onQuickCreate != null)
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onQuickCreate!(date);
                        },
                        icon: const Icon(Icons.add),
                        tooltip: 'Créer un service',
                      ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              // Services list améliorée
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final service = services[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getServiceColor(service).withAlpha(51),
                          child: Icon(
                            _getServiceIcon(service.type),
                            color: _getServiceColor(service),
                            size: 20,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                service.name,
                                style: const TextStyle(fontWeight: AppTheme.fontSemiBold),
                              ),
                            ),
                            if (service.isRecurring)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.repeat,
                                      size: 12,
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      'Récurrent',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.schedule, size: 14, color: Theme.of(context).colorScheme.outline),
                                const SizedBox(width: 4),
                                Text(_formatTime(service.dateTime)),
                                const SizedBox(width: 16),
                                Icon(Icons.location_on, size: 14, color: Theme.of(context).colorScheme.outline),
                                const SizedBox(width: 4),
                                Expanded(child: Text(service.location)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              service.typeLabel,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.outline,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getServiceColor(service),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                          child: Text(
                            service.statusLabel,
                            style: const TextStyle(
                              color: AppTheme.white100,
                              fontSize: AppTheme.fontSize12,
                              fontWeight: AppTheme.fontMedium,
                            ),
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          widget.onServiceTap(service);
                        },
                        onLongPress: () {
                          Navigator.pop(context);
                          widget.onServiceLongPress(service);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  IconData _getServiceIcon(String type) {
    switch (type) {
      case 'culte': return Icons.church;
      case 'repetition': return Icons.music_note;
      case 'evenement_special': return Icons.celebration;
      case 'reunion': return Icons.meeting_room;
      default: return Icons.event;
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  String _getMonthYear(DateTime date) {
    final months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatDate(DateTime date) {
    final weekdays = [
      'lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'
    ];
    return '${weekdays[date.weekday - 1]} ${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${hour}h$minute';
  }
}