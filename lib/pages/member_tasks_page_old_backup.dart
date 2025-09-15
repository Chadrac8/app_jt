import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/tasks_firebase_service.dart';
import '../auth/auth_service.dart';
import '../widgets/task_calendar_view.dart';
import 'task_detail_page.dart';
import '../theme.dart';

class MemberTasksPage extends StatefulWidget {
  const MemberTasksPage({super.key});

  @override
  State<MemberTasksPage> createState() => _MemberTasksPageState();
}

class _MemberTasksPageState extends State<MemberTasksPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _headerAnimationController;
  late Animation<double> _slideAnimation;
  
  String _selectedView = 'list'; // 'list', 'calendar'
  String _selectedFilter = 'active'; // 'all', 'active', 'completed', 'overdue', 'due_soon'
  String _selectedPriority = 'all'; // 'all', 'high', 'medium', 'low'
  
  List<TaskModel> _tasks = [];
  List<TaskReminderModel> _reminders = [];

  final Map<String, String> _filterLabels = {
    'all': 'Toutes',
    'active': 'En cours',
    'completed': 'Terminées',
    'overdue': 'En retard',
    'due_soon': 'Échéance proche',
  };

  final Map<String, String> _priorityLabels = {
    'all': 'Toutes priorités',
    'high': 'Haute priorité',
    'medium': 'Priorité moyenne',
    'low': 'Basse priorité',
  };

  final Map<String, IconData> _filterIcons = {
    'all': Icons.all_inbox,
    'active': Icons.play_circle_outline,
    'completed': Icons.check_circle_outline,
    'overdue': Icons.schedule,
    'due_soon': Icons.access_time,
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _headerAnimationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<double>(begin: -50.0, end: 0.0).animate(
      CurvedAnimation(parent: _headerAnimationController, curve: Curves.elasticOut),
    );
    
    // Séquence d'animations
    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _headerAnimationController.forward();
    });
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

  Future<void> _updateTaskStatus(TaskModel task, String newStatus) async {
    try {
      await TasksFirebaseService.updateTaskStatus(
        task.id, 
        newStatus, 
        userId: AuthService.currentUser?.uid,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tâche marquée comme ${task.statusLabel.toLowerCase()}'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
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
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              Text(
                'Authentification requise',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Vous devez être connecté pour voir vos tâches',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildModernAppBar(),
          SliverToBoxAdapter(
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      _buildTasksOverview(),
                      _buildRemindersSection(),
                      _buildQuickFilters(),
                    ],
                  ),
                );
              },
            ),
          ),
          _selectedView == 'list' 
            ? _buildModernTasksList() 
            : SliverToBoxAdapter(child: _buildCalendarView()),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildModernAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        title: AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: const Text(
                'Mes Tâches',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 22,
                ),
              ),
            );
          },
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withOpacity(0.8),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(_selectedView == 'list' ? Icons.calendar_today : Icons.list),
          onPressed: () {
            setState(() {
              _selectedView = _selectedView == 'list' ? 'calendar' : 'list';
            });
          },
          tooltip: _selectedView == 'list' ? 'Vue calendrier' : 'Vue liste',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            const PopupMenuItem(
              enabled: false,
              child: Text(
                'Options d\'affichage',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            PopupMenuItem(
              value: 'refresh',
              child: const Row(
                children: [
                  Icon(Icons.refresh),
                  SizedBox(width: 8),
                  Text('Actualiser'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'settings',
              child: const Row(
                children: [
                  Icon(Icons.settings),
                  SizedBox(width: 8),
                  Text('Paramètres'),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'refresh':
                _loadData();
                break;
              case 'settings':
                // Ouvrir les paramètres
                break;
            }
          },
        ),
      ],
    );
  }

  Widget _buildTasksOverview() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildOverviewCard(
              'En cours',
              _getTaskCount('active'),
              Icons.play_circle_outline,
              AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildOverviewCard(
              'Terminées',
              _getTaskCount('completed'),
              Icons.check_circle_outline,
              Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildOverviewCard(
              'En retard',
              _getTaskCount('overdue'),
              Icons.schedule,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(String title, int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilters() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtres rapides',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          // Filtres par statut
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filterLabels.entries.map((entry) {
                final isSelected = _selectedFilter == entry.key;
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _filterIcons[entry.key],
                          size: 16,
                          color: isSelected ? Colors.white : AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(entry.value),
                      ],
                    ),
                    selectedColor: AppTheme.primaryColor,
                    checkmarkColor: Colors.white,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = entry.key;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          // Filtres par priorité
          Text(
            'Priorité',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _priorityLabels.entries.map((entry) {
                final isSelected = _selectedPriority == entry.key;
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(entry.value),
                    selectedColor: _getPriorityColor(entry.key),
                    checkmarkColor: Colors.white,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? _getPriorityColor(entry.key) : Colors.grey[300]!,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _selectedPriority = entry.key;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () {
        // Naviguer vers la création de tâche
      },
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text('Nouvelle tâche'),
      elevation: 4,
    );
  }

  int _getTaskCount(String filter) {
    // Cette méthode devra être implémentée selon votre logique métier
    // Pour l'instant, retournons des valeurs d'exemple
    switch (filter) {
      case 'active':
        return _tasks.where((task) => ['todo', 'in_progress'].contains(task.status)).length;
      case 'completed':
        return _tasks.where((task) => task.status == 'completed').length;
      case 'overdue':
        return _tasks.where((task) => 
          task.dueDate != null && 
          task.dueDate!.isBefore(DateTime.now()) && 
          task.status != 'completed'
        ).length;
      default:
        return 0;
    }
  }

  Widget _buildModernTasksList() {
    return StreamBuilder<List<TaskModel>>(
      stream: TasksFirebaseService.getTasksStream(
        assigneeIds: [AuthService.currentUser!.uid],
        statusFilters: _getStatusFilters(),
        priorityFilters: _getPriorityFilters(),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Center(
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur lors du chargement',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final tasks = snapshot.data ?? [];
        _tasks = tasks; // Mettre à jour la liste locale

        if (tasks.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: Column(
                children: [
                  const SizedBox(height: 64),
                  Icon(
                    Icons.task_alt,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Aucune tâche trouvée',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Commencez par créer votre première tâche',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Naviguer vers la création de tâche
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Créer une tâche'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final task = tasks[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildModernTaskCard(task),
                );
              },
              childCount: tasks.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernTaskCard(TaskModel task) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _onTaskTap(task),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getPriorityColor(task.priority),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        task.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: task.status == 'completed' 
                            ? TextDecoration.lineThrough 
                            : null,
                        ),
                      ),
                    ),
                    _buildStatusChip(task.status),
                  ],
                ),
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    task.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (task.dueDate != null) ...[
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: _getDueDateColor(task.dueDate!),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDueDate(task.dueDate!),
                        style: TextStyle(
                          fontSize: 12,
                          color: _getDueDateColor(task.dueDate!),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                    ],
                    if (task.assigneeIds.isNotEmpty) ...[
                      Icon(
                        Icons.person,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${task.assigneeIds.length} assigné(s)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
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
        color = Colors.green;
        label = 'Terminée';
        icon = Icons.check_circle;
        break;
      case 'in_progress':
        color = Colors.blue;
        label = 'En cours';
        icon = Icons.play_circle;
        break;
      case 'todo':
        color = Colors.orange;
        label = 'À faire';
        icon = Icons.radio_button_unchecked;
        break;
      default:
        color = Colors.grey;
        label = 'Inconnu';
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getDueDateColor(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;

    if (difference < 0) {
      return Colors.red; // En retard
    } else if (difference <= 1) {
      return Colors.orange; // Échéance proche
    } else {
      return Colors.grey[600]!; // Normal
    }
  }

  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;

    if (difference < 0) {
      return 'En retard de ${-difference} jour(s)';
    } else if (difference == 0) {
      return 'Échéance aujourd\'hui';
    } else if (difference == 1) {
      return 'Échéance demain';
    } else {
      return 'Échéance dans $difference jours';
    }
  }

  Widget _buildRemindersSection() {
    if (_reminders.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.warningColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.notifications_active, color: AppTheme.warningColor),
                const SizedBox(width: 8),
                Text(
                  'Rappels (${_reminders.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.warningColor,
                  ),
                ),
              ],
            ),
          ),
          ...(_reminders.take(3).map((reminder) {
            return ListTile(
              dense: true,
              leading: Icon(
                _getReminderIcon(reminder.type),
                color: AppTheme.warningColor,
                size: 20,
              ),
              title: Text(_getReminderTitle(reminder.type)),
              subtitle: Text(_formatReminderDate(reminder.reminderDate)),
              onTap: () async {
                await TasksFirebaseService.markReminderAsRead(reminder.id);
                // Navigate to related task
              },
            );
          }).toList()),
          if (_reminders.length > 3)
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextButton(
                onPressed: () {
                  // Navigate to full reminders list
                },
                child: Text('Voir tous les rappels (${_reminders.length})'),
              ),
            ),
        ],
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

  IconData _getEmptyStateIcon() {
    switch (_selectedFilter) {
      case 'completed':
        return Icons.check_circle_outline;
      case 'overdue':
        return Icons.warning_amber;
      case 'due_soon':
        return Icons.schedule;
      default:
        return Icons.task_alt;
    }
  }

  String _getEmptyStateTitle() {
    switch (_selectedFilter) {
      case 'completed':
        return 'Aucune tâche terminée';
      case 'overdue':
        return 'Aucune tâche en retard';
      case 'due_soon':
        return 'Aucune échéance proche';
      case 'active':
        return 'Aucune tâche active';
      default:
        return 'Aucune tâche';
    }
  }

  String _getEmptyStateSubtitle() {
    switch (_selectedFilter) {
      case 'completed':
        return 'Terminez vos tâches pour les voir apparaître ici';
      case 'overdue':
        return 'Bravo ! Toutes vos tâches sont à jour';
      case 'due_soon':
        return 'Aucune tâche n\'arrive à échéance prochainement';
      case 'active':
        return 'Vous n\'avez pas de tâches en cours';
      default:
        return 'Vous n\'avez aucune tâche assignée';
    }
  }
}