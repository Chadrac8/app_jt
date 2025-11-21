import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final isApple = AppTheme.isApplePlatform;
    
    if (userId == null) {
      return _buildNotConnectedState(isApple);
    }

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: _buildModernAppBar(isApple),
      body: _buildModernBody(isApple),
      floatingActionButton: _buildModernFAB(isApple),
    );
  }

  Widget _buildNotConnectedState(bool isApple) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceLarge),
              decoration: BoxDecoration(
                color: AppTheme.errorContainer,
                borderRadius: AppTheme.borderRadiusLarge,
              ),
              child: Icon(
                isApple ? CupertinoIcons.person_crop_circle_badge_xmark : Icons.person_off_rounded,
                size: 64,
                color: AppTheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            Text(
              'Connexion requise',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize24,
                fontWeight: AppTheme.fontBold,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: AppTheme.spaceSmall),
            Text(
              'Vous devez être connecté pour voir vos tâches',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize16,
                fontWeight: AppTheme.fontRegular,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar(bool isApple) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      title: Text(
        'Mes Tâches',
        style: GoogleFonts.inter(
          fontSize: AppTheme.fontSize22,
          fontWeight: AppTheme.fontBold,
          color: AppTheme.onSurface,
        ),
      ),
      centerTitle: isApple,
      actions: [
        IconButton(
          icon: Icon(
            isApple ? CupertinoIcons.bell : Icons.notifications_rounded,
            color: AppTheme.onSurface,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            _showNotificationsPanel();
          },
          tooltip: 'Notifications',
        ),
        PopupMenuButton<String>(
          icon: Icon(
            isApple ? CupertinoIcons.ellipsis : Icons.more_vert_rounded,
            color: AppTheme.onSurface,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppTheme.borderRadiusMedium,
          ),
          elevation: 8,
          shadowColor: AppTheme.primaryColor.withOpacity(0.2),
          itemBuilder: (context) => [
            _buildPopupMenuItem(
              'statistics',
              isApple ? CupertinoIcons.chart_bar : Icons.analytics_rounded,
              'Statistiques',
              isApple,
            ),
            _buildPopupMenuItem(
              'settings',
              isApple ? CupertinoIcons.settings : Icons.settings_rounded,
              'Paramètres',
              isApple,
            ),
          ],
          onSelected: (value) {
            HapticFeedback.lightImpact();
            switch (value) {
              case 'statistics':
                _showStatistics();
                break;
              case 'settings':
                _showSettings();
                break;
            }
          },
        ),
      ],
      bottom: _buildModernTabBar(isApple),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(
    String value,
    IconData icon,
    String title,
    bool isApple,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          icon,
          color: AppTheme.onSurface,
          size: 20.0,
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: AppTheme.fontSize14,
            fontWeight: AppTheme.fontMedium,
            color: AppTheme.onSurface,
          ),
        ),
        minLeadingWidth: 20.0 + AppTheme.spaceSmall,
      ),
    );
  }

  PreferredSizeWidget _buildModernTabBar(bool isApple) {
    return TabBar(
      controller: _tabController,
      indicator: BoxDecoration(
        color: AppTheme.primaryContainer,
        borderRadius: AppTheme.borderRadiusMedium,
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Colors.transparent,
      labelColor: AppTheme.onPrimaryContainer,
      unselectedLabelColor: AppTheme.onSurfaceVariant,
      labelStyle: GoogleFonts.inter(
        fontWeight: AppTheme.fontSemiBold,
        fontSize: AppTheme.fontSize14,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontWeight: AppTheme.fontMedium,
        fontSize: AppTheme.fontSize14,
      ),
      tabs: [
        Tab(
          icon: Icon(
            isApple ? CupertinoIcons.list_bullet : Icons.view_list_rounded,
            size: 20,
          ),
          text: 'Liste',
        ),
        Tab(
          icon: Icon(
            isApple ? CupertinoIcons.calendar : Icons.calendar_today_rounded,
            size: 20,
          ),
          text: 'Calendrier',
        ),
      ],
    );
  }

  Widget _buildModernBody(bool isApple) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildModernStatsSection(isApple),
            if (_reminders.isNotEmpty) _buildModernRemindersSection(isApple),
            _buildModernFilterSection(isApple),
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
    );
  }

  Widget _buildModernFAB(bool isApple) {
    return FloatingActionButton(
      onPressed: () {
        HapticFeedback.lightImpact();
        _showCreateTaskDialog();
      },
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: AppTheme.onPrimaryColor,
      elevation: 6,
      child: Icon(
        isApple ? CupertinoIcons.add : Icons.add_rounded,
      ),
    );
  }



  Widget _buildModernStatsSection(bool isApple) {
    return StreamBuilder<List<TaskModel>>(
      stream: TasksFirebaseService.getTasksStream(
        assigneeIds: [AuthService.currentUser!.uid],
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            height: 140,
            margin: const EdgeInsets.all(AppTheme.spaceMedium),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: AppTheme.borderRadiusLarge,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
                strokeWidth: 3,
              ),
            ),
          );
        }

        final tasks = snapshot.data!;
        _updateStatistics(tasks);

        return Container(
          margin: const EdgeInsets.all(AppTheme.spaceMedium),
          padding: const EdgeInsets.all(AppTheme.spaceLarge),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withOpacity(0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: AppTheme.borderRadiusLarge,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Aperçu de mes tâches',
                style: GoogleFonts.inter(
                  fontSize: AppTheme.fontSize16,
                  fontWeight: AppTheme.fontSemiBold,
                  color: AppTheme.onPrimaryColor,
                ),
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              Row(
                children: [
                  Expanded(
                    child: _buildModernStatItem(
                      'Total',
                      _totalTasks.toString(),
                      isApple ? CupertinoIcons.doc_text : Icons.assignment_rounded,
                      AppTheme.onPrimaryColor,
                      isApple,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 50,
                    color: AppTheme.onPrimaryColor.withOpacity(0.3),
                  ),
                  Expanded(
                    child: _buildModernStatItem(
                      'Terminées',
                      _completedTasks.toString(),
                      isApple ? CupertinoIcons.checkmark_circle : Icons.check_circle_rounded,
                      AppTheme.onPrimaryColor,
                      isApple,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 50,
                    color: AppTheme.onPrimaryColor.withOpacity(0.3),
                  ),
                  Expanded(
                    child: _buildModernStatItem(
                      'En retard',
                      _overdueTasks.toString(),
                      isApple ? CupertinoIcons.exclamationmark_triangle : Icons.warning_rounded,
                      AppTheme.onPrimaryColor,
                      isApple,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 50,
                    color: AppTheme.onPrimaryColor.withOpacity(0.3),
                  ),
                  Expanded(
                    child: _buildModernStatItem(
                      'À venir',
                      _dueSoonTasks.toString(),
                      isApple ? CupertinoIcons.clock : Icons.schedule_rounded,
                      AppTheme.onPrimaryColor,
                      isApple,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModernStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isApple,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spaceSmall),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: AppTheme.borderRadiusSmall,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: AppTheme.spaceSmall),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: AppTheme.fontSize20,
            fontWeight: AppTheme.fontBold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: AppTheme.fontSize12,
            fontWeight: AppTheme.fontMedium,
            color: color.withOpacity(0.85),
          ),
        ),
      ],
    );
  }

  Widget _buildModernFilterSection(bool isApple) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spaceMedium),
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: AppTheme.borderRadiusMedium,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isApple ? CupertinoIcons.slider_horizontal_3 : Icons.filter_list_rounded,
                color: AppTheme.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spaceSmall),
              Text(
                'Filtres',
                style: GoogleFonts.inter(
                  fontSize: AppTheme.fontSize16,
                  fontWeight: AppTheme.fontSemiBold,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ..._filterLabels.entries.map((entry) {
                  final isSelected = _selectedFilter == entry.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppTheme.spaceSmall),
                    child: _buildModernFilterChip(
                      entry.key,
                      entry.value,
                      _filterIcons[entry.key]!,
                      isSelected,
                      isApple,
                    ),
                  );
                }),
                const SizedBox(width: AppTheme.spaceSmall),
                _buildModernPriorityDropdown(isApple),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernFilterChip(
    String key,
    String label,
    IconData icon,
    bool isSelected,
    bool isApple,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedFilter = key;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceMedium,
          vertical: AppTheme.spaceSmall,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryContainer : AppTheme.surface,
          borderRadius: AppTheme.borderRadiusLarge,
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppTheme.onPrimaryContainer : AppTheme.onSurface,
            ),
            const SizedBox(width: AppTheme.spaceXSmall),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize14,
                fontWeight: isSelected ? AppTheme.fontSemiBold : AppTheme.fontMedium,
                color: isSelected ? AppTheme.onPrimaryContainer : AppTheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernPriorityDropdown(bool isApple) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceMedium,
        vertical: AppTheme.spaceXSmall,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.borderRadiusMedium,
        border: Border.all(color: AppTheme.outline),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPriority,
          isDense: true,
          icon: Icon(
            isApple ? CupertinoIcons.chevron_down : Icons.keyboard_arrow_down_rounded,
            size: 16,
            color: AppTheme.onSurface,
          ),
          style: GoogleFonts.inter(
            fontSize: AppTheme.fontSize14,
            fontWeight: AppTheme.fontMedium,
            color: AppTheme.onSurface,
          ),
          items: _priorityLabels.entries.map((entry) {
            return DropdownMenuItem(
              value: entry.key,
              child: Text(entry.value),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              HapticFeedback.lightImpact();
              setState(() {
                _selectedPriority = value;
              });
            }
          },
        ),
      ),
    );
  }



  Widget _buildModernRemindersSection(bool isApple) {
    if (_reminders.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: AppTheme.warningContainer,
        borderRadius: AppTheme.borderRadiusMedium,
        border: Border.all(
          color: AppTheme.warning.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.warning.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            decoration: BoxDecoration(
              color: AppTheme.warning,
              borderRadius: BorderRadius.only(
                topLeft: AppTheme.borderRadiusMedium.topLeft,
                topRight: AppTheme.borderRadiusMedium.topRight,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isApple ? CupertinoIcons.bell_fill : Icons.notifications_active_rounded,
                  color: AppTheme.onWarning,
                  size: 24,
                ),
                const SizedBox(width: AppTheme.spaceSmall),
                Expanded(
                  child: Text(
                    'Rappels urgents',
                    style: GoogleFonts.inter(
                      color: AppTheme.onWarning,
                      fontSize: AppTheme.fontSize16,
                      fontWeight: AppTheme.fontSemiBold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceSmall,
                    vertical: AppTheme.spaceXSmall,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.onWarning.withOpacity(0.2),
                    borderRadius: AppTheme.borderRadiusSmall,
                  ),
                  child: Text(
                    '${_reminders.length}',
                    style: GoogleFonts.inter(
                      color: AppTheme.onWarning,
                      fontWeight: AppTheme.fontBold,
                      fontSize: AppTheme.fontSize12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...(_reminders.take(3).map((reminder) {
            return _buildModernReminderItem(reminder, isApple);
          }).toList()),
          if (_reminders.length > 3)
            Padding(
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    // Navigate to full reminders list
                  },
                  icon: Icon(
                    isApple ? CupertinoIcons.eye_fill : Icons.visibility_rounded,
                    size: 20,
                  ),
                  label: Text(
                    'Voir tous les rappels (${_reminders.length})',
                    style: GoogleFonts.inter(
                      fontWeight: AppTheme.fontMedium,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceSmall),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModernReminderItem(dynamic reminder, bool isApple) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceMedium,
        vertical: AppTheme.spaceSmall,
      ),
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.borderRadiusSmall,
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceSmall),
            decoration: BoxDecoration(
              color: AppTheme.warningContainer,
              borderRadius: AppTheme.borderRadiusSmall,
            ),
            child: Icon(
              _getReminderIcon(reminder.type),
              color: AppTheme.onWarningContainer,
              size: 20,
            ),
          ),
          const SizedBox(width: AppTheme.spaceSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getReminderTitle(reminder.type),
                  style: GoogleFonts.inter(
                    fontWeight: AppTheme.fontSemiBold,
                    fontSize: AppTheme.fontSize14,
                    color: AppTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatReminderDate(reminder.reminderDate),
                  style: GoogleFonts.inter(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: AppTheme.fontSize12,
                    fontWeight: AppTheme.fontMedium,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              isApple ? CupertinoIcons.chevron_right : Icons.chevron_right_rounded,
              size: 20,
              color: AppTheme.onSurfaceVariant,
            ),
            onPressed: () async {
              HapticFeedback.lightImpact();
              await TasksFirebaseService.markReminderAsRead(reminder.id);
              // Navigate to related task
            },
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
                    : AppTheme.grey200,
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
        return AppTheme.grey600;
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

  void _showNotificationsPanel() {
    // TODO: Implement notifications panel
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: const Text('Panel de notifications à implémenter'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showStatistics() {
    // TODO: Implement statistics dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Statistiques'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tâches totales: $_totalTasks'),
            Text('Tâches complétées: $_completedTasks'),
            Text('Tâches en retard: $_overdueTasks'),
            Text('Tâches à échéance proche: $_dueSoonTasks'),
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

  void _showSettings() {
    // TODO: Implement settings dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Paramètres'),
        content: const Text('Panel de paramètres à implémenter'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showCreateTaskDialog() {
    // TODO: Implement create task dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Créer une tâche'),
        content: const Text('Dialog de création de tâche à implémenter'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

}