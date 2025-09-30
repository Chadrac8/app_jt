import 'package:flutter/material.dart';
import '../../../../theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

import '../../services/models/service_assignment.dart';
import '../../services/services/services_service.dart';
import '../../../pages/member_tasks_page.dart';
import '../../services/views/member_services_page.dart';
import '../../../pages/workflow_followups_management_page.dart';
import '../../../services/firebase_service.dart';
import '../../../pages/member_groups_page.dart';

/// Onglet "Bénévolat" moderne du module Vie de l'église
/// Design inspiré des meilleures applications d'église
class BenevolatTab extends StatefulWidget {
  const BenevolatTab({super.key});

  @override
  State<BenevolatTab> createState() => _BenevolatTabState();
}

class _BenevolatTabState extends State<BenevolatTab> 
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  
  // Services
  final ServicesService _servicesService = ServicesService();
  final ScrollController _scrollController = ScrollController();
  
  // Animation Controllers
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Loading states
  bool _isLoadingStats = true;
  
  // Statistics
  int _completedTasks = 0;
  int _totalTasks = 0;
  int _upcomingTasksCount = 0;
  int _overdueTasksCount = 0;
  int _confirmedAssignments = 0;
  int _totalAssignments = 0;
  int _upcomingServicesCount = 0;
  
  // Workflow suivis statistics
  int _activeWorkflows = 0;
  int _totalPersonsInWorkflows = 0;
  
  // Groupes statistics
  int _myGroupsCount = 0;
  int _totalGroupsCount = 0;
  int _upcomingMeetingsCount = 0;
  int _completedWorkflowSteps = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadStatistics();
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this);
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeAnimationController, curve: Curves.easeOutCubic));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero).animate(CurvedAnimation(parent: _slideAnimationController, curve: Curves.easeOutCubic));

    _fadeAnimationController.forward();
    _slideAnimationController.forward();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoadingStats = true;
    });

    try {
      await Future.wait([
        _loadTaskStatistics(),
        _loadServiceStatistics(),
        _loadWorkflowStatistics(),
      ]);
    } catch (e) {
      _showErrorSnackBar('Erreur lors du chargement des statistiques');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  Future<void> _loadTaskStatistics() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final tasksQuery = await FirebaseFirestore.instance
          .collection('tasks')
          .where('assigneeIds', arrayContains: user.uid)
          .get();

      int completed = 0;
      int upcoming = 0;
      int overdue = 0;
      final now = DateTime.now();

      for (var doc in tasksQuery.docs) {
        final data = doc.data();
        final status = data['status'] as String? ?? 'todo';
        final dueDate = data['dueDate'] != null 
            ? (data['dueDate'] as Timestamp).toDate()
            : null;

        if (status == 'completed') {
          completed++;
        } else {
          if (dueDate != null) {
            if (dueDate.isAfter(now)) {
              upcoming++;
            } else {
              overdue++;
            }
          }
        }
      }

      setState(() {
        _totalTasks = tasksQuery.docs.length;
        _completedTasks = completed;
        _upcomingTasksCount = upcoming;
        _overdueTasksCount = overdue;
      });
    } catch (e) {
      print('Erreur lors du chargement des statistiques de tâches: $e');
    }
  }

  Future<void> _loadServiceStatistics() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final assignments = await _servicesService.getMemberAssignments(user.uid);
      
      int confirmed = 0;
      int upcoming = 0;
      final now = DateTime.now();

      for (var assignment in assignments) {
        if (assignment.status == AssignmentStatus.confirmed) {
          confirmed++;
        }
        
        try {
          final serviceDoc = await FirebaseFirestore.instance
              .collection('services')
              .doc(assignment.serviceId)
              .get();
          
          if (serviceDoc.exists) {
            final serviceData = serviceDoc.data()!;
            final startDate = (serviceData['startDate'] as Timestamp).toDate();
            if (startDate.isAfter(now)) {
              upcoming++;
            }
          }
        } catch (e) {
          // Ignorer les erreurs de service individuel
        }
      }

      setState(() {
        _totalAssignments = assignments.length;
        _confirmedAssignments = confirmed;
        _upcomingServicesCount = upcoming;
      });
    } catch (e) {
      print('Erreur lors du chargement des statistiques de services: $e');
    }
  }

  Future<void> _loadWorkflowStatistics() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final workflows = await FirebaseService.getWorkflowsStream().first;
      
      int activeWorkflows = 0;
      int totalPersons = 0;
      int completedSteps = 0;

      for (final workflow in workflows) {
        final personWorkflows = await FirebaseService.getPersonWorkflowsByWorkflowId(workflow.id).first;
        
        if (personWorkflows.isNotEmpty) {
          activeWorkflows++;
          totalPersons += personWorkflows.length;
          
          for (final personWorkflow in personWorkflows) {
            completedSteps += personWorkflow.completedSteps.length;
          }
        }
      }

      setState(() {
        _activeWorkflows = activeWorkflows;
        _totalPersonsInWorkflows = totalPersons;
        _completedWorkflowSteps = completedSteps;
      });
    } catch (e) {
      print('Erreur lors du chargement des statistiques de workflows: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.settings, color: AppTheme.surfaceColor, size: 20),
            const SizedBox(width: 8),
            Text(message),
          ]),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium))));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: RefreshIndicator(
            onRefresh: _loadStatistics,
            color: const Color(0xFF6B73FF),
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Mes Contributions
                  _buildContributionsSection(),
                  const SizedBox(height: 32),
                  
                  // Section Actions rapides
                  _buildQuickActionsSection(),
                ]))))));
  }

  /// Section Mes Contributions - 2 rangées de 2 widgets
  Widget _buildContributionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre de section avec style moderne
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Mes Contributions',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: AppTheme.fontBold,
              color: const Color(0xFF1a1a1a),
              letterSpacing: -0.5))),
        const SizedBox(height: 20),
        
        // Première rangée
        Row(
          children: [
            Expanded(
              child: _buildModernContributionCard(
                title: 'Mes Tâches',
                subtitle: 'Voir toutes mes tâches',
                icon: Icons.task_alt,
                count: '$_completedTasks/$_totalTasks',
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)]),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const MemberTasksPage())))),
            const SizedBox(width: 16),
            Expanded(
              child: _buildModernContributionCard(
                title: 'Mes Services',
                subtitle: 'Gérer mes services',
                icon: Icons.church,
                count: '$_confirmedAssignments/$_totalAssignments',
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6B73FF), Color(0xFF9DD5EA)]),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const MemberServicesPage())))),
          ]),
        const SizedBox(height: 16),
        
        // Deuxième rangée
        Row(
          children: [
            Expanded(
              child: _buildModernContributionCard(
                title: 'Mes Groupes',
                subtitle: 'Organisation et suivi',
                icon: Icons.groups,
                count: '$_myGroupsCount/$_totalGroupsCount',
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2196F3), Color(0xFF64B5F6)]),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const MemberGroupsPage())))),
            const SizedBox(width: 16),
            Expanded(
              child: _buildModernContributionCard(
                title: 'Suivis',
                subtitle: 'Workflows actifs',
                icon: Icons.track_changes,
                count: '$_activeWorkflows',
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)]),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const WorkflowFollowupsManagementPage())))),
          ]),
      ]);
  }

  /// Widget de carte de contribution moderne
  Widget _buildModernContributionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String count,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8)),
          ]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                  child: Icon(
                    icon,
                    color: AppTheme.surfaceColor,
                    size: 24)),
                Text(
                  count,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: AppTheme.fontBold,
                    color: AppTheme.surfaceColor)),
              ]),
            const Spacer(),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: AppTheme.fontSemiBold,
                color: AppTheme.surfaceColor)),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.surfaceColor.withOpacity(0.8))),
          ])));
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre de section avec style moderne
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Actions Rapides',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: AppTheme.fontBold,
              color: const Color(0xFF1a1a1a),
              letterSpacing: -0.5))),
        const SizedBox(height: 20),
        
        // Première rangée
        Row(
          children: [
            Expanded(
              child: _buildModernActionCard(
                title: 'Nouvelle Tâche',
                subtitle: 'Créer une tâche',
                icon: Icons.add_task,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFF6B6B), Color(0xFFFFB8B8)]),
                onTap: () {
                  // Action pour créer une nouvelle tâche
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Création de tâche - À implémenter')));
                })),
            const SizedBox(width: 16),
            Expanded(
              child: _buildModernActionCard(
                title: 'Planning',
                subtitle: 'Voir mon planning',
                icon: Icons.calendar_today,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)]),
                onTap: () {
                  // Action pour voir le planning
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Planning - À implémenter')));
                })),
          ]),
        const SizedBox(height: 16),
        
        // Deuxième rangée
        Row(
          children: [
            Expanded(
              child: _buildModernActionCard(
                title: 'Notifications',
                subtitle: 'Gérer alertes',
                icon: Icons.notifications_active,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFD93D), Color(0xFF6BCF7F)]),
                onTap: () {
                  // Action pour gérer les notifications
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notifications - À implémenter')));
                })),
            const SizedBox(width: 16),
            Expanded(
              child: _buildModernActionCard(
                title: 'Aide',
                subtitle: 'Support bénévolat',
                icon: Icons.help_outline,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF8E44AD), Color(0xFFE74C3C)]),
                onTap: () {
                  // Action pour l'aide
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Aide - À implémenter')));
                })),
          ]),
      ]);
  }

  /// Widget de carte d'action moderne
  Widget _buildModernActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: gradient.colors.first.withOpacity(0.2),
            width: 2),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8)),
          ]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
              child: Icon(
                icon,
                color: AppTheme.surfaceColor,
                size: 24)),
            const Spacer(),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: AppTheme.fontSemiBold,
                color: const Color(0xFF1a1a1a))),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.textSecondaryColor)),
          ])));
  }
}
