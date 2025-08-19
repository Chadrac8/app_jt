import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async';

import '../models/task_model.dart';
import '../models/service_model.dart';
import 'task_search_filter_bar.dart';
import 'task_create_edit_modal.dart';
import 'task_detail_view.dart';
import 'services_member_view.dart';

class BenevolatTab extends StatefulWidget {
  const BenevolatTab({super.key});

  @override
  State<BenevolatTab> createState() => _BenevolatTabState();
}

class _BenevolatTabState extends State<BenevolatTab> 
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  StreamSubscription<QuerySnapshot>? _tasksSubscription;
  StreamSubscription<QuerySnapshot>? _servicesSubscription;
  
  // Data
  List<TaskModel> _myTasks = [];
  List<TaskModel> _availableTasks = [];
  List<Service> _services = [];
  List<Service> _upcomingServices = [];
  
  // Loading states
  bool _isLoadingTasks = true;
  bool _isLoadingServices = true;
  bool _isLoadingStats = true;
  
  // Statistics
  int _completedTasks = 0;
  int _totalTasks = 0;
  int _upcomingTasksCount = 0;
  int _overdueTasksCount = 0;
  
  // Search and filters
  final TextEditingController _searchController = TextEditingController();
  List<String> _selectedStatusFilters = ['todo', 'in_progress'];
  
  // Other states
  int _currentTabIndex = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _searchController.dispose();
    _tasksSubscription?.cancel();
    _servicesSubscription?.cancel();
    super.dispose();
  }

  void _initializeControllers() {
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: _currentTabIndex,
    );
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
    
    _animationController.forward();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoadingTasks = true;
      _isLoadingServices = true;
      _isLoadingStats = true;
    });

    try {
      await Future.wait([
        _loadTasks(),
        _loadServices(),
        _loadStatistics(),
      ]);
    } catch (e) {
      _showErrorSnackBar('Erreur lors du chargement des données');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingTasks = false;
          _isLoadingServices = false;
          _isLoadingStats = false;
        });
      }
    }
  }

  Future<void> _loadTasks() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Charger mes tâches
      final myTasksQuery = await FirebaseFirestore.instance
          .collection('tasks')
          .where('assigneeIds', arrayContains: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      // Charger les tâches disponibles
      final availableTasksQuery = await FirebaseFirestore.instance
          .collection('tasks')
          .where('isPublic', isEqualTo: true)
          .where('status', isNotEqualTo: 'completed')
          .orderBy('status')
          .orderBy('createdAt', descending: true)
          .get();

      if (mounted) {
        setState(() {
          _myTasks = myTasksQuery.docs
              .map((doc) => TaskModel.fromFirestore(doc))
              .toList();
          
          _availableTasks = availableTasksQuery.docs
              .map((doc) => TaskModel.fromFirestore(doc))
              .where((task) => !task.assigneeIds.contains(user.uid))
              .toList();
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des tâches: $e');
    }
  }

  Future<void> _loadServices() async {
    try {
      final servicesQuery = await FirebaseFirestore.instance
          .collection('services')
          .where('status', isEqualTo: 'published')
          .where('startDate', isGreaterThan: DateTime.now())
          .orderBy('startDate')
          .limit(10)
          .get();

      if (mounted) {
        setState(() {
          _services = servicesQuery.docs
              .map((doc) => Service.fromFirestore(doc))
              .toList();
          
          _upcomingServices = _services.where((service) => 
              service.startDate.isAfter(DateTime.now())).toList();
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des services: $e');
    }
  }

  Future<void> _loadStatistics() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final statsQuery = await FirebaseFirestore.instance
          .collection('tasks')
          .where('assigneeIds', arrayContains: user.uid)
          .get();

      final tasks = statsQuery.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();
      
      if (mounted) {
        setState(() {
          _totalTasks = tasks.length;
          _completedTasks = tasks.where((task) => task.status == 'completed').length;
          _upcomingTasksCount = tasks.where((task) => 
              task.dueDate != null && 
              task.dueDate!.isAfter(DateTime.now()) &&
              task.status != 'completed').length;
          _overdueTasksCount = tasks.where((task) => task.isOverdue).length;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des statistiques: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: Column(
            children: [
              _buildHeader(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildTasksTab(),
                    _buildAvailableTasksTab(),
                    _buildServicesTab(),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade600,
            Colors.blue.shade800,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.volunteer_activism,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Bénévolat',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              if (_overdueTasksCount > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_overdueTasksCount',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Contribuez et participez à la vie de l\'église',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          _buildStatisticsCards(),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards() {
    if (_isLoadingStats) {
      return Row(
        children: List.generate(4, (index) => 
          Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        _buildStatCard('Tâches\nterminées', '$_completedTasks/$_totalTasks', 
            Icons.check_circle, Colors.green),
        const SizedBox(width: 8),
        _buildStatCard('À venir', '$_upcomingTasksCount', 
            Icons.schedule, Colors.orange),
        const SizedBox(width: 8),
        _buildStatCard('En retard', '$_overdueTasksCount', 
            Icons.warning, Colors.red),
        const SizedBox(width: 8),
        _buildStatCard('Services', '${_upcomingServices.length}', 
            Icons.event, Colors.purple),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.blue,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: Colors.blue,
        indicatorWeight: 3,
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'Vue d\'ensemble'),
          Tab(text: 'Mes tâches'),
          Tab(text: 'Disponibles'),
          Tab(text: 'Services'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressSection(),
          const SizedBox(height: 20),
          _buildUrgentTasksSection(),
          const SizedBox(height: 20),
          _buildUpcomingServicesSection(),
          const SizedBox(height: 20),
          _buildVolunteerOpportunitiesSection(),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    final progressPercentage = _totalTasks > 0 ? (_completedTasks / _totalTasks) * 100 : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: Colors.blue, size: 24),
              const SizedBox(width: 8),
              Text(
                'Progression générale',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${progressPercentage.toStringAsFixed(0)}%',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      'Tâches terminées',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: progressPercentage / 100,
                  strokeWidth: 8,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  backgroundColor: Colors.grey[200],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUrgentTasksSection() {
    final urgentTasks = _myTasks.where((task) => 
        task.isUrgent && task.status != 'completed').take(3).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.red, size: 24),
              const SizedBox(width: 8),
              Text(
                'Tâches urgentes',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (urgentTasks.isEmpty)
            _buildEmptyState('Aucune tâche urgente', Icons.check_circle)
          else
            ...urgentTasks.map((task) => 
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildTaskCard(task, showUrgentBadge: true),
                ),
            ),
        ],
      ),
    );
  }

  Widget _buildUpcomingServicesSection() {
    final nextServices = _upcomingServices.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event, color: Colors.green, size: 24),
              const SizedBox(width: 8),
              Text(
                'Prochains services',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (nextServices.isEmpty)
            _buildEmptyState('Aucun service programmé', Icons.event_available)
          else
            ...nextServices.map((service) => 
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildServiceCard(service),
                ),
            ),
        ],
      ),
    );
  }

  Widget _buildVolunteerOpportunitiesSection() {
    final opportunities = _availableTasks.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.add_task, color: Colors.blue, size: 24),
              const SizedBox(width: 8),
              Text(
                'Opportunités bénévoles',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (opportunities.isEmpty)
            _buildEmptyState('Aucune opportunité disponible', Icons.done_all)
          else
            ...opportunities.map((task) => 
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildTaskCard(task, showJoinButton: true),
                ),
            ),
        ],
      ),
    );
  }

  Widget _buildTasksTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TaskSearchFilterBar(
            searchController: _searchController,
            onSearchChanged: (query) => setState(() {}),
            selectedStatusFilters: _selectedStatusFilters,
            selectedPriorityFilters: const [],
            onFiltersChanged: (status, priority, dueBefore, dueAfter) => 
              setState(() => _selectedStatusFilters = status),
          ),
        ),
        Expanded(
          child: _isLoadingTasks
            ? const Center(child: CircularProgressIndicator())
            : _buildTasksList(_myTasks, showJoinButtons: false),
        ),
      ],
    );
  }

  Widget _buildAvailableTasksTab() {
    return Column(
      children: [
        _buildAvailableTasksHeader(),
        Expanded(
          child: _isLoadingTasks
            ? const Center(child: CircularProgressIndicator())
            : _buildTasksList(_availableTasks, showJoinButtons: true),
        ),
      ],
    );
  }

  Widget _buildAvailableTasksHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.add_task, color: Colors.orange[600], size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tâches disponibles',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Rejoignez des projets et contribuez à la communauté',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${_availableTasks.length} opportunité${_availableTasks.length > 1 ? 's' : ''} disponible${_availableTasks.length > 1 ? 's' : ''}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.orange[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesTab() {
    return _isLoadingServices
      ? const Center(child: CircularProgressIndicator())
      : const ServicesMemberView();
  }

  Widget _buildTasksList(List<TaskModel> tasks, {bool showJoinButtons = false}) {
    if (tasks.isEmpty) {
      return _buildEmptyState(
        showJoinButtons ? 'Aucune tâche disponible' : 'Aucune tâche trouvée',
        showJoinButtons ? Icons.volunteer_activism : Icons.search_off,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildTaskCard(task, showJoinButton: showJoinButtons),
        );
      },
    );
  }

  Widget _buildTaskCard(TaskModel task, {bool showJoinButton = false, bool showUrgentBadge = false}) {
    final isOverdue = task.dueDate != null && task.dueDate!.isBefore(DateTime.now());
    final isUrgent = task.dueDate != null && 
                     task.dueDate!.isBefore(DateTime.now().add(const Duration(days: 3))) &&
                     task.status != 'completed';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverdue ? Colors.red.shade300 : Colors.grey[200]!,
          width: isOverdue ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getPriorityColor(task.priority).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getPriorityIcon(task.priority),
                  color: _getPriorityColor(task.priority),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                              decoration: task.status == 'completed' ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                        if (showUrgentBadge && isUrgent) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'URGENT',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              _buildTaskStatusBadge(task.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (task.dueDate != null) ...[
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: isOverdue ? Colors.red : Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDueDate(task.dueDate!),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isOverdue ? Colors.red : Colors.grey[600],
                    fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Icon(
                Icons.person,
                size: 16,
                color: Colors.grey[500],
              ),
              const SizedBox(width: 4),
              Text(
                '${task.assigneeIds.length} assigné${task.assigneeIds.length > 1 ? 's' : ''}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              if (showJoinButton) ...[
                ElevatedButton.icon(
                  onPressed: () => _joinTask(task),
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(
                    'Rejoindre',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                  ),
                ),
              ] else ...[
                IconButton(
                  onPressed: () => _navigateToTaskDetail(task),
                  icon: Icon(
                    Icons.chevron_right,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskStatusBadge(String status) {
    Color color;
    String label;
    
    switch (status) {
      case 'completed':
        color = Colors.green;
        label = 'Terminé';
        break;
      case 'in_progress':
        color = Colors.blue;
        label = 'En cours';
        break;
      case 'todo':
        color = Colors.orange;
        label = 'À faire';
        break;
      default:
        color = Colors.grey;
        label = 'Inconnu';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildServiceCard(Service service) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getServiceTypeColor(service.type).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getServiceTypeIcon(service.type),
              color: _getServiceTypeColor(service.type),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  service.description,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatServiceDate(service.startDate),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        service.location,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Colors.grey[400],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    if (_currentTabIndex == 1) {
      return FloatingActionButton(
        onPressed: _showCreateTaskModal,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      );
    }
    return const SizedBox.shrink();
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference < 0) {
      return 'En retard de ${(-difference)} jour${-difference > 1 ? 's' : ''}';
    } else if (difference == 0) {
      return 'Aujourd\'hui';
    } else if (difference == 1) {
      return 'Demain';
    } else if (difference <= 7) {
      return 'Dans $difference jours';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  String _formatServiceDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference < 0) {
      return 'Passé';
    } else if (difference == 0) {
      return 'Aujourd\'hui';
    } else if (difference == 1) {
      return 'Demain';
    } else if (difference <= 7) {
      return 'Dans $difference jours';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
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

  IconData _getPriorityIcon(String priority) {
    switch (priority) {
      case 'high':
        return Icons.priority_high;
      case 'medium':
        return Icons.remove;
      case 'low':
        return Icons.expand_more;
      default:
        return Icons.help_outline;
    }
  }

  Color _getServiceTypeColor(String type) {
    switch (type) {
      case 'music':
        return Colors.purple;
      case 'tech':
        return Colors.blue;
      case 'welcome':
        return Colors.green;
      case 'children':
        return Colors.orange;
      case 'youth':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getServiceTypeIcon(String type) {
    switch (type) {
      case 'music':
        return Icons.music_note;
      case 'tech':
        return Icons.settings;
      case 'welcome':
        return Icons.handshake;
      case 'children':
        return Icons.child_care;
      case 'youth':
        return Icons.group;
      default:
        return Icons.volunteer_activism;
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  void _showCreateTaskModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TaskCreateEditModal(),
    ).then((result) {
      if (result == true) {
        _refreshData();
      }
    });
  }

  void _joinTask(TaskModel task) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(task.id)
          .update({
        'assigneeIds': FieldValue.arrayUnion([user.uid]),
      });

      _showSuccessSnackBar('Vous avez rejoint la tâche "${task.title}"');
      _refreshData();
    } catch (e) {
      _showErrorSnackBar('Erreur lors de l\'adhésion à la tâche');
    }
  }

  void _navigateToTaskDetail(TaskModel task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailView(task: task),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
