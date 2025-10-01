import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/tasks_firebase_service.dart';
import '../auth/auth_service.dart';
import '../widgets/task_calendar_view.dart';
import 'task_detail_page.dart';
import '../../theme.dart';

class MemberTasksPage extends StatefulWidget {
  const MemberTasksPage({super.key});

  @override
  State<MemberTasksPage> createState() => _MemberTasksPageState();
}

class _MemberTasksPageState extends State<MemberTasksPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  String _selectedFilter = 'active';
  String _selectedPriority = 'all';
  
  List<TaskReminderModel> _reminders = [];
  
  // Statistiques
  int _totalTasks = 0;
  int _completedTasks = 0;
  int _overdueTasks = 0;
  int _dueSoonTasks = 0;

  final Map<String, String> _filterLabels = {
    'all': 'Toutes',
    'active': 'En cours',
    'completed': 'Terminées',
    'overdue': 'En retard',
    'due_soon': 'À venir',
  };

  final Map<String, IconData> _filterIcons = {
    'all': Icons.list_alt,
    'active': Icons.play_circle,
    'completed': Icons.check_circle,
    'overdue': Icons.warning,
    'due_soon': Icons.schedule,
  };

  final Map<String, String> _priorityLabels = {
    'all': 'Toutes',
    'high': 'Haute',
    'medium': 'Moyenne',
    'low': 'Basse',
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeTabController();
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  void _initializeTabController() {
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _loadData() async {
    try {
      final userId = AuthService.currentUser?.uid;
      if (userId == null) return;
      
      // Load user's reminders
      TasksFirebaseService.getUserRemindersStream(userId).listen((reminders) {
        if (mounted) {
          setState(() => _reminders = reminders);
        }
      });
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _updateStatistics(List<TaskModel> tasks) {
    final now = DateTime.now();
    _totalTasks = tasks.length;
    _completedTasks = tasks.where((task) => task.status == 'completed').length;
    _overdueTasks = tasks.where((task) => 
      task.dueDate != null && 
      task.dueDate!.isBefore(now) && 
      task.status != 'completed'
    ).length;
    _dueSoonTasks = tasks.where((task) => 
      task.dueDate != null && 
      task.dueDate!.isAfter(now) && 
      task.dueDate!.isBefore(now.add(const Duration(days: 3))) &&
      task.status != 'completed'
    ).length;
  }

  List<String> _getStatusFilters() {
    switch (_selectedFilter) {
      case 'active':
        return ['todo', 'in_progress'];
      case 'completed':
        return ['completed'];
      case 'overdue':
      case 'due_soon':
        return ['todo', 'in_progress'];
      default:
        return [];
    }
  }

  List<String> _getPriorityFilters() {
    if (_selectedPriority == 'all') return [];
    return [_selectedPriority];
  }

  void _onTaskTap(TaskModel task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailPage(task: task),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = AuthService.currentUser?.uid;
    if (userId == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_off,
                size: 64,
                color: AppTheme.grey400,
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              Text(
                'Connexion requise',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.grey600,
                ),
              ),
              const SizedBox(height: AppTheme.spaceSmall),
              Text(
                'Vous devez être connecté pour voir vos tâches',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.grey500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.grey50,
      appBar: _buildAppBar(),
      body: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildStatsSection(),
              if (_reminders.isNotEmpty) _buildRemindersSection(),
              _buildFilterSection(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTasksList(),
                    _buildCalendarView(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Mes Tâches',
        style: TextStyle(fontWeight: AppTheme.fontSemiBold),
      ),
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: AppTheme.white100,
      elevation: 0,
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: AppTheme.white100,
        indicatorWeight: 3,
        labelColor: AppTheme.white100,
        unselectedLabelColor: AppTheme.white100.withOpacity(0.70),
        labelStyle: const TextStyle(fontWeight: AppTheme.fontSemiBold),
        tabs: const [
          Tab(
            icon: Icon(Icons.list_alt),
            text: 'Liste',
          ),
          Tab(
            icon: Icon(Icons.calendar_month),
            text: 'Calendrier',
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadData,
          tooltip: 'Actualiser',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            // Handle menu selections
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings),
                  SizedBox(width: AppTheme.spaceSmall),
                  Text('Paramètres'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.download),
                  SizedBox(width: AppTheme.spaceSmall),
                  Text('Exporter'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return StreamBuilder<List<TaskModel>>(
      stream: TasksFirebaseService.getTasksStream(
        assigneeIds: [AuthService.currentUser!.uid],
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            height: 120,
            margin: const EdgeInsets.all(AppTheme.spaceMedium),
            decoration: BoxDecoration(
              color: AppTheme.white100,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.black100.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final tasks = snapshot.data!;
        _updateStatistics(tasks);

        return Container(
          margin: const EdgeInsets.all(AppTheme.spaceMedium),
          padding: const EdgeInsets.all(AppTheme.space20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total',
                  _totalTasks.toString(),
                  Icons.assignment,
                  AppTheme.white100,
                ),
              ),
              Container(width: 1, height: 40, color: AppTheme.white100),
              Expanded(
                child: _buildStatItem(
                  'Terminées',
                  _completedTasks.toString(),
                  Icons.check_circle,
                  AppTheme.grey300,
                ),
              ),
              Container(width: 1, height: 40, color: AppTheme.white100),
              Expanded(
                child: _buildStatItem(
                  'En retard',
                  _overdueTasks.toString(),
                  Icons.warning,
                  AppTheme.grey300,
                ),
              ),
              Container(width: 1, height: 40, color: AppTheme.white100),
              Expanded(
                child: _buildStatItem(
                  'À venir',
                  _dueSoonTasks.toString(),
                  Icons.schedule,
                  AppTheme.grey300,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: AppTheme.spaceSmall),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.white100,
            fontSize: AppTheme.fontSize24,
            fontWeight: AppTheme.fontBold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.white100.withOpacity(0.70),
            fontSize: AppTheme.fontSize12,
            fontWeight: AppTheme.fontMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtres',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: AppTheme.fontSemiBold,
              color: AppTheme.grey700,
            ),
          ),
          const SizedBox(height: AppTheme.space12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ..._filterLabels.entries.map((entry) {
                  final isSelected = _selectedFilter == entry.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _filterIcons[entry.key]!,
                            size: 16,
                            color: isSelected ? AppTheme.white100 : AppTheme.primaryColor,
                          ),
                          const SizedBox(width: AppTheme.spaceXSmall),
                          Text(entry.value),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = entry.key;
                        });
                      },
                      selectedColor: AppTheme.primaryColor,
                      backgroundColor: AppTheme.white100,
                      checkmarkColor: AppTheme.white100,
                      labelStyle: TextStyle(
                        color: isSelected ? AppTheme.white100 : AppTheme.primaryColor,
                        fontWeight: AppTheme.fontMedium,
                      ),
                      elevation: isSelected ? 4 : 1,
                      shadowColor: AppTheme.primaryColor.withOpacity(0.3),
                    ),
                  );
                }),
                // Priorité filter
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.white100,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                    border: Border.all(color: AppTheme.grey300!),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedPriority,
                      isDense: true,
                      icon: const Icon(Icons.arrow_drop_down, size: 16),
                      items: _priorityLabels.entries.map((entry) {
                        return DropdownMenuItem(
                          value: entry.key,
                          child: Text(
                            entry.value,
                            style: const TextStyle(fontSize: AppTheme.fontSize14),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedPriority = value;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spaceMedium),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () {
        // Navigate to create new task
      },
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: AppTheme.white100,
      elevation: 8,
      icon: const Icon(Icons.add),
      label: const Text(
        'Nouvelle tâche',
        style: TextStyle(fontWeight: AppTheme.fontSemiBold),
      ),
    );
  }

  Widget _buildRemindersSection() {
    if (_reminders.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.grey50,
            AppTheme.grey100.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.grey200),
        boxShadow: [
          BoxShadow(
            color: AppTheme.orangeStandard.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            decoration: BoxDecoration(
              color: AppTheme.grey600,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.notifications_active,
                  color: AppTheme.white100,
                  size: 24,
                ),
                const SizedBox(width: AppTheme.space12),
                Expanded(
                  child: Text(
                    'Rappels urgents (${_reminders.length})',
                    style: const TextStyle(
                      color: AppTheme.white100,
                      fontSize: AppTheme.fontSize16,
                      fontWeight: AppTheme.fontSemiBold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.white100.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Text(
                    '${_reminders.length}',
                    style: const TextStyle(
                      color: AppTheme.white100,
                      fontWeight: AppTheme.fontBold,
                      fontSize: AppTheme.fontSize12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...(_reminders.take(3).map((reminder) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(AppTheme.space12),
              decoration: BoxDecoration(
                color: AppTheme.white100,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.black100.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spaceSmall),
                    decoration: BoxDecoration(
                      color: AppTheme.grey100,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Icon(
                      _getReminderIcon(reminder.type),
                      color: AppTheme.grey700,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getReminderTitle(reminder.type),
                          style: const TextStyle(
                            fontWeight: AppTheme.fontSemiBold,
                            fontSize: AppTheme.fontSize14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatReminderDate(reminder.reminderDate),
                          style: TextStyle(
                            color: AppTheme.grey600,
                            fontSize: AppTheme.fontSize12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppTheme.grey400,
                    ),
                    onPressed: () async {
                      await TasksFirebaseService.markReminderAsRead(reminder.id);
                      // Navigate to related task
                    },
                  ),
                ],
              ),
            );
          }).toList()),
          if (_reminders.length > 3)
            Padding(
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              child: SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    // Navigate to full reminders list
                  },
                  icon: const Icon(Icons.visibility),
                  label: Text('Voir tous les rappels (${_reminders.length})'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.grey700,
                    backgroundColor: AppTheme.white100,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTasksList() {
    return StreamBuilder<List<TaskModel>>(
      stream: TasksFirebaseService.getTasksStream(
        assigneeIds: [AuthService.currentUser!.uid],
        statusFilters: _getStatusFilters(),
        priorityFilters: _getPriorityFilters(),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: AppTheme.spaceMedium),
                Text(
                  'Chargement de vos tâches...',
                  style: TextStyle(color: AppTheme.grey500),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Container(
              margin: const EdgeInsets.all(AppTheme.spaceXLarge),
              padding: const EdgeInsets.all(AppTheme.spaceLarge),
              decoration: BoxDecoration(
                color: AppTheme.grey50,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                border: Border.all(color: AppTheme.grey200),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppTheme.grey400,
                  ),
                  const SizedBox(height: AppTheme.spaceMedium),
                  Text(
                    'Erreur de chargement',
                    style: TextStyle(
                      fontSize: AppTheme.fontSize18,
                      fontWeight: AppTheme.fontSemiBold,
                      color: AppTheme.grey700,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceSmall),
                  Text(
                    'Impossible de charger vos tâches',
                    style: TextStyle(color: AppTheme.grey600),
                  ),
                  const SizedBox(height: AppTheme.spaceMedium),
                  ElevatedButton.icon(
                    onPressed: () => setState(() {}),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.grey600,
                      foregroundColor: AppTheme.white100,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        var tasks = snapshot.data ?? [];

        // Apply special filters
        if (_selectedFilter == 'overdue') {
          tasks = tasks.where((task) => task.isOverdue).toList();
        } else if (_selectedFilter == 'due_soon') {
          tasks = tasks.where((task) => task.isDueSoon).toList();
        }

        if (tasks.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: _loadData,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              if (index >= tasks.length) {
                return const SizedBox.shrink();
              }
              
              final task = tasks[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildModernTaskCard(task),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildModernTaskCard(TaskModel task) {
    Color priorityColor = _getPriorityColor(task.priority);
    bool isOverdue = task.isOverdue;
    bool isDueSoon = task.isDueSoon;
    
    return GestureDetector(
      onTap: () => _onTaskTap(task),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.white100,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: AppTheme.black100.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: isOverdue 
                ? AppTheme.grey300 
                : isDueSoon 
                    ? AppTheme.grey300 
                    : AppTheme.grey200!,
            width: isOverdue || isDueSoon ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with priority indicator
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              decoration: BoxDecoration(
                color: priorityColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: priorityColor,
                      borderRadius: BorderRadius.circular(AppTheme.radius2),
                    ),
                  ),
                  const SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: AppTheme.fontSize16,
                        fontWeight: AppTheme.fontSemiBold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusChip(task.status),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (task.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        task.description,
                        style: TextStyle(
                          color: AppTheme.grey600,
                          fontSize: AppTheme.fontSize14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  
                  Row(
                    children: [
                      if (task.dueDate != null) ...[
                        Icon(
                          Icons.schedule,
                          size: 16,
                          color: isOverdue ? AppTheme.grey600 : AppTheme.grey500,
                        ),
                        const SizedBox(width: AppTheme.spaceXSmall),
                        Text(
                          _formatDueDate(task.dueDate!),
                          style: TextStyle(
                            fontSize: AppTheme.fontSize12,
                            color: isOverdue ? AppTheme.grey600 : AppTheme.grey600,
                            fontWeight: isOverdue ? AppTheme.fontSemiBold : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spaceMedium),
                      ],
                      Icon(
                        Icons.flag,
                        size: 16,
                        color: priorityColor,
                      ),
                      const SizedBox(width: AppTheme.spaceXSmall),
                      Text(
                        _priorityLabels[task.priority] ?? 'Moyenne',
                        style: TextStyle(
                          fontSize: AppTheme.fontSize12,
                          color: priorityColor,
                          fontWeight: AppTheme.fontMedium,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case 'completed':
        color = AppTheme.greenStandard;
        label = 'Terminée';
        icon = Icons.check_circle;
        break;
      case 'in_progress':
        color = AppTheme.blueStandard;
        label = 'En cours';
        icon = Icons.play_circle;
        break;
      default:
        color = AppTheme.grey500;
        label = 'À faire';
        icon = Icons.radio_button_unchecked;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: AppTheme.spaceXSmall),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: AppTheme.fontSize11,
              fontWeight: AppTheme.fontSemiBold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return AppTheme.grey600;
      case 'medium':
        return AppTheme.grey600;
      case 'low':
        return AppTheme.grey600;
      default:
        return AppTheme.grey600!;
    }
  }

  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;
    
    if (difference < 0) {
      return 'En retard de ${difference.abs()} jour${difference.abs() > 1 ? 's' : ''}';
    } else if (difference == 0) {
      return 'Aujourd\'hui';
    } else if (difference == 1) {
      return 'Demain';
    } else if (difference <= 7) {
      return 'Dans $difference jours';
    } else {
      return '${dueDate.day}/${dueDate.month}/${dueDate.year}';
    }
  }

  Widget _buildEmptyState() {
    IconData icon;
    String title;
    String subtitle;
    Color color;

    switch (_selectedFilter) {
      case 'completed':
        icon = Icons.celebration;
        title = 'Aucune tâche terminée';
        subtitle = 'Terminez vos tâches pour les voir apparaître ici';
        color = AppTheme.greenStandard;
        break;
      case 'overdue':
        icon = Icons.thumb_up;
        title = 'Bravo !';
        subtitle = 'Aucune tâche en retard. Continuez comme ça !';
        color = AppTheme.greenStandard;
        break;
      case 'due_soon':
        icon = Icons.schedule;
        title = 'Rien d\'urgent';
        subtitle = 'Aucune tâche n\'arrive à échéance prochainement';
        color = AppTheme.blueStandard;
        break;
      case 'active':
        icon = Icons.task_alt;
        title = 'Aucune tâche active';
        subtitle = 'Vous n\'avez pas de tâches en cours actuellement';
        color = AppTheme.orangeStandard;
        break;
      default:
        icon = Icons.assignment_outlined;
        title = 'Aucune tâche';
        subtitle = 'Vous n\'avez aucune tâche assignée pour le moment';
        color = AppTheme.grey500;
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppTheme.spaceXLarge),
        padding: const EdgeInsets.all(AppTheme.spaceXLarge),
        decoration: BoxDecoration(
          color: AppTheme.white100,
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          boxShadow: [
            BoxShadow(
              color: AppTheme.black100.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.space20),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: color,
              ),
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            Text(
              title,
              style: TextStyle(
                fontSize: AppTheme.fontSize22,
                fontWeight: AppTheme.fontSemiBold,
                color: AppTheme.grey800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.space12),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: AppTheme.fontSize16,
                color: AppTheme.grey600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spaceXLarge),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to create new task
              },
              icon: const Icon(Icons.add),
              label: const Text('Créer une tâche'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: AppTheme.white100,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarView() {
    return TaskCalendarView(
      assigneeIds: [AuthService.currentUser!.uid],
      statusFilters: _getStatusFilters(),
      priorityFilters: _getPriorityFilters(),
      onTaskTap: _onTaskTap,
    );
  }

  IconData _getReminderIcon(String type) {
    switch (type) {
      case 'due_soon':
        return Icons.schedule;
      case 'overdue':
        return Icons.warning;
      case 'assigned':
        return Icons.assignment_ind;
      case 'comment_added':
        return Icons.chat;
      default:
        return Icons.notifications;
    }
  }

  String _getReminderTitle(String type) {
    switch (type) {
      case 'due_soon':
        return 'Échéance proche';
      case 'overdue':
        return 'Tâche en retard';
      case 'assigned':
        return 'Nouvelle assignation';
      case 'comment_added':
        return 'Nouveau commentaire';
      default:
        return 'Rappel';
    }
  }

  String _formatReminderDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }

}