import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/task_model.dart';
import '../services/tasks_firebase_service.dart';
import '../widgets/task_card.dart';
import '../widgets/task_list_card.dart';
import '../widgets/task_kanban_view.dart';
import '../widgets/task_calendar_view.dart';
import '../widgets/task_search_filter_bar.dart';
import 'task_form_page.dart';
import 'task_list_form_page.dart';
import 'task_detail_page.dart';
import '../../theme.dart';

class TasksHomePage extends StatefulWidget {
  const TasksHomePage({super.key});

  @override
  State<TasksHomePage> createState() => _TasksHomePageState();
}

class _TasksHomePageState extends State<TasksHomePage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  String _searchQuery = '';
  List<String> _selectedStatusFilters = ['todo', 'in_progress'];
  List<String> _selectedPriorityFilters = [];
  DateTime? _dueBefore;
  DateTime? _dueAfter;
  String _currentView = 'lists'; // 'lists', 'tasks', 'kanban', 'calendar'
  
  List<TaskModel> _selectedTasks = [];
  List<TaskListModel> _selectedTaskLists = [];
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeOut),
    );
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fabAnimationController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
  }

  void _onFiltersChanged(
    List<String> statusFilters,
    List<String> priorityFilters,
    DateTime? dueBefore,
    DateTime? dueAfter,
  ) {
    setState(() {
      _selectedStatusFilters = statusFilters;
      _selectedPriorityFilters = priorityFilters;
      _dueBefore = dueBefore;
      _dueAfter = dueAfter;
    });
  }

  void _changeView(String view) {
    if (_currentView == view) return;
    
    HapticFeedback.selectionClick();
    
    // Animation de transition fluide
    _fabAnimationController.reverse().then((_) {
      setState(() {
        _currentView = view;
        _isSelectionMode = false;
        _selectedTasks.clear();
        _selectedTaskLists.clear();
      });
      _fabAnimationController.forward();
    });
    
    // Afficher le SnackBar moderne pour la confirmation du changement de vue
    final viewNames = {
      'lists': 'Listes de tâches',
      'tasks': 'Vue tâches',
      'kanban': 'Tableau Kanban',
      'calendar': 'Vue calendrier',
    };
    
    _showModernSnackBar(
      'Basculé vers ${viewNames[view] ?? view}',
      AppTheme.info,
      AppTheme.isApplePlatform ? CupertinoIcons.checkmark : Icons.check_rounded,
    );
  }

  void _toggleSelectionMode() {
    HapticFeedback.mediumImpact();
    
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedTasks.clear();
        _selectedTaskLists.clear();
      }
    });
    
    // Animation du FAB avec transition fluide
    _fabAnimationController.reset();
    _fabAnimationController.forward();
  }

  void _onTaskSelected(TaskModel task, bool isSelected) {
    HapticFeedback.lightImpact();
    
    setState(() {
      if (isSelected) {
        _selectedTasks.add(task);
      } else {
        _selectedTasks.remove(task);
      }
    });
    
    // Si plus aucun élément sélectionné, quitter le mode sélection
    if (_selectedTasks.isEmpty && _selectedTaskLists.isEmpty && _isSelectionMode) {
      _toggleSelectionMode();
    }
  }

  void _onTaskListSelected(TaskListModel taskList, bool isSelected) {
    HapticFeedback.lightImpact();
    
    setState(() {
      if (isSelected) {
        _selectedTaskLists.add(taskList);
      } else {
        _selectedTaskLists.remove(taskList);
      }
    });
    
    // Si plus aucun élément sélectionné, quitter le mode sélection
    if (_selectedTasks.isEmpty && _selectedTaskLists.isEmpty && _isSelectionMode) {
      _toggleSelectionMode();
    }
  }

  Future<void> _createNewTask() async {
    HapticFeedback.lightImpact();
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TaskFormPage(),
        settings: const RouteSettings(name: '/task-form'),
      ),
    );
    
    if (result == true && mounted) {
      _showModernSnackBar(
        'Tâche créée avec succès',
        AppTheme.success,
        AppTheme.isApplePlatform ? CupertinoIcons.checkmark_circle : Icons.check_circle_rounded,
      );
    }
  }

  Future<void> _createNewTaskList() async {
    HapticFeedback.lightImpact();
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TaskListFormPage(),
        settings: const RouteSettings(name: '/task-list-form'),
      ),
    );
    
    if (result == true && mounted) {
      _showModernSnackBar(
        'Liste de tâches créée avec succès',
        AppTheme.success,
        AppTheme.isApplePlatform ? CupertinoIcons.checkmark_circle : Icons.check_circle_rounded,
      );
    }
  }

  Future<void> _createFromTemplate() async {
    await _showTemplateDialog();
  }

  Future<void> _performBulkAction(String action) async {
    try {
      switch (action) {
        case 'complete':
          await _completeSelectedTasks();
          break;
        case 'delete':
          await _showDeleteConfirmation();
          break;
        case 'assign':
          await _showAssignmentDialog();
          break;
        case 'move':
          await _showMoveToListDialog();
          break;
      }
    } catch (e) {
      if (mounted) {
        _showModernSnackBar(
          'Erreur: $e',
          AppTheme.error,
          AppTheme.isApplePlatform ? CupertinoIcons.exclamationmark_triangle : Icons.error_rounded,
        );
      }
    }
  }

  Future<void> _completeSelectedTasks() async {
    for (final task in _selectedTasks) {
      await TasksFirebaseService.updateTaskStatus(task.id, 'completed');
    }
    _toggleSelectionMode();
    if (mounted) {
      _showModernSnackBar(
        'Tâches marquées comme terminées',
        AppTheme.success,
        AppTheme.isApplePlatform ? CupertinoIcons.checkmark_circle : Icons.check_circle_rounded,
      );
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          _selectedTasks.isNotEmpty
              ? 'Voulez-vous vraiment supprimer ${_selectedTasks.length} tâche(s) ?'
              : 'Voulez-vous vraiment supprimer ${_selectedTaskLists.length} liste(s) ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      for (final task in _selectedTasks) {
        await TasksFirebaseService.deleteTask(task.id);
      }
      for (final taskList in _selectedTaskLists) {
        await TasksFirebaseService.deleteTaskList(taskList.id);
      }
      _toggleSelectionMode();
      if (mounted) {
        _showModernSnackBar(
          'Éléments supprimés',
          AppTheme.success,
          AppTheme.isApplePlatform ? CupertinoIcons.trash : Icons.delete_rounded,
        );
      }
    }
  }

  Future<void> _showAssignmentDialog() async {
    // Implementation would show user selection dialog
    // For now, just show a placeholder
    _showModernSnackBar(
      'Fonctionnalité d\'assignation à implémenter',
      AppTheme.info,
      AppTheme.isApplePlatform ? CupertinoIcons.person_add : Icons.person_add_rounded,
    );
  }

  Future<void> _showMoveToListDialog() async {
    // Implementation would show task list selection dialog
    _showModernSnackBar(
      'Fonctionnalité de déplacement à implémenter',
      AppTheme.info,
      AppTheme.isApplePlatform ? CupertinoIcons.tray_arrow_down : Icons.move_to_inbox_rounded,
    );
  }

  Future<void> _showTemplateDialog() async {
    final templates = await TasksFirebaseService.getTaskTemplates();
    
    if (!mounted) return;
    
    await showDialog(
      context: context,
      builder: (context) => _TemplateSelectionDialog(templates: templates),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isApple = AppTheme.isApplePlatform;
    
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: _buildModernAppBar(context, isApple),
      body: _buildModernBody(context),
      floatingActionButton: _buildModernFAB(context, isApple),
    );
  }

  PreferredSizeWidget _buildModernAppBar(BuildContext context, bool isApple) {
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
        _buildViewSelectorButton(isApple),
        if (_isSelectionMode) 
          _buildSelectionModeActions(isApple)
        else 
          _buildNormalModeActions(isApple),
      ],
    );
  }

  Widget _buildViewSelectorButton(bool isApple) {
    final viewIcons = {
      'lists': isApple ? CupertinoIcons.list_bullet : Icons.view_list_rounded,
      'tasks': isApple ? CupertinoIcons.doc_text : Icons.view_agenda_rounded,
      'kanban': isApple ? CupertinoIcons.square_grid_2x2 : Icons.view_kanban_rounded,
      'calendar': isApple ? CupertinoIcons.calendar : Icons.calendar_today_rounded,
    };
    
    return Container(
      margin: const EdgeInsets.only(right: AppTheme.spaceSmall),
      decoration: BoxDecoration(
        color: AppTheme.primaryContainer,
        borderRadius: AppTheme.borderRadiusMedium,
      ),
      child: IconButton(
        icon: Icon(
          viewIcons[_currentView] ?? viewIcons['lists']!,
          color: AppTheme.onPrimaryContainer,
        ),
        onPressed: () {
          HapticFeedback.lightImpact();
          _showModernViewSelector();
        },
        tooltip: 'Changer de vue',
      ),
    );
  }

  Widget _buildSelectionModeActions(bool isApple) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.only(right: AppTheme.spaceXSmall),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceSmall,
            vertical: AppTheme.spaceXSmall,
          ),
          decoration: BoxDecoration(
            color: AppTheme.primaryContainer,
            borderRadius: AppTheme.borderRadiusLarge,
          ),
          child: Text(
            '${_selectedTasks.length + _selectedTaskLists.length}',
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize14,
              fontWeight: AppTheme.fontSemiBold,
              color: AppTheme.onPrimaryContainer,
            ),
          ),
        ),
        IconButton(
          icon: Icon(
            isApple ? CupertinoIcons.ellipsis : Icons.more_vert_rounded,
            color: AppTheme.onSurface,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            _showModernBulkActionsMenu();
          },
        ),
        IconButton(
          icon: Icon(
            isApple ? CupertinoIcons.xmark : Icons.close_rounded,
            color: AppTheme.error,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            _toggleSelectionMode();
          },
        ),
      ],
    );
  }

  Widget _buildNormalModeActions(bool isApple) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            isApple ? CupertinoIcons.search : Icons.search_rounded,
            color: AppTheme.onSurface,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            // Toggle search functionality
          },
          tooltip: 'Rechercher',
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
              'template',
              isApple ? CupertinoIcons.doc_on_clipboard : Icons.content_copy_rounded,
              'Créer depuis modèle',
              isApple,
            ),
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
              case 'template':
                _createFromTemplate();
                break;
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

  Widget _buildModernBody(BuildContext context) {
    return Column(
      children: [
        _buildModernSearchAndFilters(),
        Expanded(
          child: _buildCurrentView(),
        ),
      ],
    );
  }

  Widget _buildModernSearchAndFilters() {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spaceMedium),
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
      child: TaskSearchFilterBar(
        searchController: _searchController,
        onSearchChanged: _onSearchChanged,
        onFiltersChanged: _onFiltersChanged,
        selectedStatusFilters: _selectedStatusFilters,
        selectedPriorityFilters: _selectedPriorityFilters,
        dueBefore: _dueBefore,
        dueAfter: _dueAfter,
      ),
    );
  }

  Widget _buildModernFAB(BuildContext context, bool isApple) {
    return AnimatedBuilder(
      animation: _fabAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _fabAnimation.value,
          child: _isSelectionMode
              ? FloatingActionButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _toggleSelectionMode();
                  },
                  backgroundColor: AppTheme.error,
                  foregroundColor: AppTheme.onError,
                  elevation: 6,
                  child: Icon(
                    isApple ? CupertinoIcons.xmark : Icons.close_rounded,
                  ),
                )
              : FloatingActionButton.extended(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _showModernCreateMenu();
                  },
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: AppTheme.onPrimaryColor,
                  elevation: 6,
                  icon: Icon(
                    isApple ? CupertinoIcons.add : Icons.add_rounded,
                  ),
                  label: Text(
                    'Créer',
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize16,
                      fontWeight: AppTheme.fontSemiBold,
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildCurrentView() {
    switch (_currentView) {
      case 'lists':
        return _buildListsView();
      case 'tasks':
        return _buildTasksView();
      case 'kanban':
        return _buildKanbanView();
      case 'calendar':
        return _buildCalendarView();
      default:
        return _buildListsView();
    }
  }

  Widget _buildListsView() {
    return StreamBuilder<List<TaskListModel>>(
      stream: TasksFirebaseService.getTaskListsStream(
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        statusFilters: ['active'],
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: AppTheme.errorColor),
                const SizedBox(height: AppTheme.spaceMedium),
                Text('Erreur: ${snapshot.error}'),
                const SizedBox(height: AppTheme.spaceMedium),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        final taskLists = snapshot.data ?? [];

        if (taskLists.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.list_alt, size: 64, color: AppTheme.grey400),
                const SizedBox(height: AppTheme.spaceMedium),
                Text(
                  'Aucune liste de tâches',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.grey600,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceSmall),
                Text(
                  'Créez votre première liste pour organiser vos tâches',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.grey500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spaceLarge),
                ElevatedButton.icon(
                  onPressed: _createNewTaskList,
                  icon: const Icon(Icons.add),
                  label: const Text('Créer une liste'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
          itemCount: taskLists.length,
          itemBuilder: (context, index) {
            // Vérification de sécurité pour éviter les erreurs d'index
            if (index >= taskLists.length) {
              return const SizedBox.shrink();
            }
            
            final taskList = taskLists[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TaskListCard(
                taskList: taskList,
                onTap: () => _onTaskListTap(taskList),
                onLongPress: () => _onTaskListLongPress(taskList),
                isSelectionMode: _isSelectionMode,
                isSelected: _selectedTaskLists.contains(taskList),
                onSelectionChanged: (isSelected) => _onTaskListSelected(taskList, isSelected),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTasksView() {
    return StreamBuilder<List<TaskModel>>(
      stream: TasksFirebaseService.getTasksStream(
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        statusFilters: _selectedStatusFilters.isNotEmpty ? _selectedStatusFilters : null,
        priorityFilters: _selectedPriorityFilters.isNotEmpty ? _selectedPriorityFilters : null,
        dueBefore: _dueBefore,
        dueAfter: _dueAfter,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        final tasks = snapshot.data ?? [];

        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.task_alt, size: 64, color: AppTheme.grey400),
                const SizedBox(height: AppTheme.spaceMedium),
                const Text('Aucune tâche trouvée'),
                const SizedBox(height: AppTheme.spaceLarge),
                ElevatedButton.icon(
                  onPressed: _createNewTask,
                  icon: const Icon(Icons.add),
                  label: const Text('Créer une tâche'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            // Vérification de sécurité pour éviter les erreurs d'index
            if (index >= tasks.length) {
              return const SizedBox.shrink();
            }
            
            final task = tasks[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TaskCard(
                task: task,
                onTap: () => _onTaskTap(task),
                onLongPress: () => _onTaskLongPress(task),
                isSelectionMode: _isSelectionMode,
                isSelected: _selectedTasks.contains(task),
                onSelectionChanged: (isSelected) => _onTaskSelected(task, isSelected),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildKanbanView() {
    return TaskKanbanView(
      searchQuery: _searchQuery,
      statusFilters: _selectedStatusFilters,
      priorityFilters: _selectedPriorityFilters,
      dueBefore: _dueBefore,
      dueAfter: _dueAfter,
      onTaskTap: _onTaskTap,
    );
  }

  Widget _buildCalendarView() {
    return TaskCalendarView(
      searchQuery: _searchQuery,
      statusFilters: _selectedStatusFilters,
      priorityFilters: _selectedPriorityFilters,
      onTaskTap: _onTaskTap,
    );
  }

  void _onTaskTap(TaskModel task) {
    if (_isSelectionMode) {
      _onTaskSelected(task, !_selectedTasks.contains(task));
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TaskDetailPage(task: task),
        ),
      );
    }
  }

  void _onTaskLongPress(TaskModel task) {
    if (!_isSelectionMode) {
      _toggleSelectionMode();
      _onTaskSelected(task, true);
    }
  }

  void _onTaskListTap(TaskListModel taskList) {
    if (_isSelectionMode) {
      _onTaskListSelected(taskList, !_selectedTaskLists.contains(taskList));
    } else {
      // Navigate to task list detail view
      setState(() {
        _currentView = 'tasks';
        // Filter tasks by this list
      });
    }
  }

  void _onTaskListLongPress(TaskListModel taskList) {
    if (!_isSelectionMode) {
      _toggleSelectionMode();
      _onTaskListSelected(taskList, true);
    }
  }

  void _showModernViewSelector() {
    final isApple = AppTheme.isApplePlatform;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusLarge),
          ),
        ),
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle indicator
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppTheme.spaceMedium),
              decoration: BoxDecoration(
                color: AppTheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Text(
              'Changer de vue',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize18,
                fontWeight: AppTheme.fontSemiBold,
                color: AppTheme.onSurface,
              ),
            ),
            
            const SizedBox(height: AppTheme.spaceMedium),
            
            _buildViewSelectorTile(
              'lists',
              'Listes de tâches',
              isApple ? CupertinoIcons.list_bullet : Icons.view_list_rounded,
              isApple,
            ),
            _buildViewSelectorTile(
              'tasks',
              'Vue tâches',
              isApple ? CupertinoIcons.doc_text : Icons.view_agenda_rounded,
              isApple,
            ),
            _buildViewSelectorTile(
              'kanban',
              'Tableau Kanban',
              isApple ? CupertinoIcons.square_grid_2x2 : Icons.view_kanban_rounded,
              isApple,
            ),
            _buildViewSelectorTile(
              'calendar',
              'Vue calendrier',
              isApple ? CupertinoIcons.calendar : Icons.calendar_today_rounded,
              isApple,
            ),
            
            const SizedBox(height: AppTheme.spaceSmall),
          ],
        ),
      ),
    );
  }

  Widget _buildViewSelectorTile(String viewKey, String title, IconData icon, bool isApple) {
    final isSelected = _currentView == viewKey;
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceSmall),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryContainer : Colors.transparent,
        borderRadius: AppTheme.borderRadiusMedium,
        border: Border.all(
          color: isSelected ? AppTheme.primaryColor : AppTheme.outline,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppTheme.onPrimaryContainer : AppTheme.onSurface,
          size: 24,
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: AppTheme.fontSize16,
            fontWeight: isSelected ? AppTheme.fontSemiBold : AppTheme.fontMedium,
            color: isSelected ? AppTheme.onPrimaryContainer : AppTheme.onSurface,
          ),
        ),
        trailing: isSelected
            ? Icon(
                isApple ? CupertinoIcons.checkmark : Icons.check_rounded,
                color: AppTheme.onPrimaryContainer,
                size: 20,
              )
            : null,
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
          _changeView(viewKey);
        },
      ),
    );
  }

  void _showModernCreateMenu() {
    final isApple = AppTheme.isApplePlatform;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusLarge),
          ),
        ),
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle indicator
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppTheme.spaceMedium),
              decoration: BoxDecoration(
                color: AppTheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Text(
              'Créer nouveau',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize18,
                fontWeight: AppTheme.fontSemiBold,
                color: AppTheme.onSurface,
              ),
            ),
            
            const SizedBox(height: AppTheme.spaceMedium),
            
            _buildCreateMenuItem(
              'Nouvelle tâche',
              'Créer une tâche individuelle',
              isApple ? CupertinoIcons.doc_text : Icons.task_alt_rounded,
              AppTheme.primaryColor,
              () => _createNewTask(),
              isApple,
            ),
            
            _buildCreateMenuItem(
              'Nouvelle liste',
              'Créer une liste de tâches',
              isApple ? CupertinoIcons.list_bullet : Icons.list_alt_rounded,
              AppTheme.secondaryColor,
              () => _createNewTaskList(),
              isApple,
            ),
            
            _buildCreateMenuItem(
              'Depuis un modèle',
              'Utiliser un modèle prédéfini',
              isApple ? CupertinoIcons.doc_on_clipboard : Icons.content_copy_rounded,
              AppTheme.tertiaryColor,
              () => _createFromTemplate(),
              isApple,
            ),
            
            const SizedBox(height: AppTheme.spaceSmall),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateMenuItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
    bool isApple,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceSmall),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: AppTheme.borderRadiusMedium,
        border: Border.all(color: AppTheme.outline),
      ),
      child: ListTile(
        leading: Container(
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
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: AppTheme.fontSize16,
            fontWeight: AppTheme.fontSemiBold,
            color: AppTheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: AppTheme.fontSize14,
            fontWeight: AppTheme.fontRegular,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          isApple ? CupertinoIcons.chevron_right : Icons.chevron_right_rounded,
          color: AppTheme.onSurfaceVariant,
          size: 20,
        ),
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
          onTap();
        },
      ),
    );
  }

  void _showModernBulkActionsMenu() {
    final isApple = AppTheme.isApplePlatform;
    final selectedCount = _selectedTasks.length + _selectedTaskLists.length;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusLarge),
          ),
        ),
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle indicator
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppTheme.spaceMedium),
              decoration: BoxDecoration(
                color: AppTheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Text(
              '$selectedCount élément${selectedCount > 1 ? 's' : ''} sélectionné${selectedCount > 1 ? 's' : ''}',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize18,
                fontWeight: AppTheme.fontSemiBold,
                color: AppTheme.onSurface,
              ),
            ),
            
            const SizedBox(height: AppTheme.spaceMedium),
            
            if (_selectedTasks.isNotEmpty) ...[
              _buildBulkActionTile(
                'Marquer comme terminé',
                isApple ? CupertinoIcons.checkmark_circle : Icons.check_circle_rounded,
                AppTheme.success,
                () => _performBulkAction('complete'),
                isApple,
              ),
              _buildBulkActionTile(
                'Assigner à quelqu\'un',
                isApple ? CupertinoIcons.person_add : Icons.person_add_rounded,
                AppTheme.info,
                () => _performBulkAction('assign'),
                isApple,
              ),
              _buildBulkActionTile(
                'Déplacer vers une liste',
                isApple ? CupertinoIcons.tray_arrow_down : Icons.move_to_inbox_rounded,
                AppTheme.warning,
                () => _performBulkAction('move'),
                isApple,
              ),
            ],
            
            _buildBulkActionTile(
              'Supprimer définitivement',
              isApple ? CupertinoIcons.trash : Icons.delete_rounded,
              AppTheme.error,
              () => _performBulkAction('delete'),
              isApple,
              isDestructive: true,
            ),
            
            const SizedBox(height: AppTheme.spaceSmall),
          ],
        ),
      ),
    );
  }

  Widget _buildBulkActionTile(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
    bool isApple, {
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceSmall),
      decoration: BoxDecoration(
        color: isDestructive ? AppTheme.errorContainer.withOpacity(0.3) : AppTheme.surfaceVariant,
        borderRadius: AppTheme.borderRadiusMedium,
        border: Border.all(
          color: isDestructive ? AppTheme.error.withOpacity(0.3) : AppTheme.outline,
        ),
      ),
      child: ListTile(
        leading: Container(
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
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: AppTheme.fontSize16,
            fontWeight: AppTheme.fontSemiBold,
            color: isDestructive ? AppTheme.error : AppTheme.onSurface,
          ),
        ),
        trailing: Icon(
          isApple ? CupertinoIcons.chevron_right : Icons.chevron_right_rounded,
          color: isDestructive ? AppTheme.error : AppTheme.onSurfaceVariant,
          size: 20,
        ),
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
          onTap();
        },
      ),
    );
  }

  void _showStatistics() {
    _showModernSnackBar(
      'Statistiques à implémenter',
      AppTheme.info,
      AppTheme.isApplePlatform ? CupertinoIcons.chart_bar : Icons.analytics_rounded,
    );
  }

  void _showSettings() {
    _showModernSnackBar(
      'Paramètres à implémenter',
      AppTheme.info,
      AppTheme.isApplePlatform ? CupertinoIcons.settings : Icons.settings_rounded,
    );
  }

  void _showModernSnackBar(String message, Color backgroundColor, IconData icon) {
    HapticFeedback.lightImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon,
              color: AppTheme.onPrimaryColor,
              size: 20,
            ),
            const SizedBox(width: AppTheme.spaceSmall),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: AppTheme.fontSize14,
                  fontWeight: AppTheme.fontMedium,
                  color: AppTheme.onPrimaryColor,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.borderRadiusMedium,
        ),
        margin: const EdgeInsets.all(AppTheme.spaceMedium),
        duration: const Duration(seconds: 3),
        elevation: 6,
      ),
    );
  }

  // Méthode statique pour afficher des SnackBars modernes depuis d'autres widgets
  static void _showModernSnackBarStatic(BuildContext context, String message, Color backgroundColor, IconData icon) {
    HapticFeedback.lightImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon,
              color: AppTheme.onPrimaryColor,
              size: 20,
            ),
            const SizedBox(width: AppTheme.spaceSmall),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: AppTheme.fontSize14,
                  fontWeight: AppTheme.fontMedium,
                  color: AppTheme.onPrimaryColor,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.borderRadiusMedium,
        ),
        margin: const EdgeInsets.all(AppTheme.spaceMedium),
        duration: const Duration(seconds: 3),
        elevation: 6,
      ),
    );
  }
}

class _TemplateSelectionDialog extends StatelessWidget {
  final List<TaskTemplateModel> templates;

  const _TemplateSelectionDialog({required this.templates});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choisir un modèle'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: templates.length,
          itemBuilder: (context, index) {
            final template = templates[index];
            return ListTile(
              leading: Icon(
                template.type == 'task' ? Icons.task_alt : Icons.list_alt,
                color: AppTheme.primaryColor,
              ),
              title: Text(template.name),
              subtitle: Text(template.description),
              onTap: () {
                Navigator.pop(context);
                _createFromTemplate(context, template);
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
      ],
    );
  }

  void _createFromTemplate(BuildContext context, TaskTemplateModel template) async {
    try {
      await TasksFirebaseService.createFromTemplate(template.id, {});
      
      if (context.mounted) {
        _TasksHomePageState._showModernSnackBarStatic(
          context,
          '${template.name} créé avec succès',
          AppTheme.success,
          AppTheme.isApplePlatform ? CupertinoIcons.checkmark_circle : Icons.check_circle_rounded,
        );
      }
    } catch (e) {
      if (context.mounted) {
        _TasksHomePageState._showModernSnackBarStatic(
          context,
          'Erreur: $e',
          AppTheme.error,
          AppTheme.isApplePlatform ? CupertinoIcons.exclamationmark_triangle : Icons.error_rounded,
        );
      }
    }
  }
}