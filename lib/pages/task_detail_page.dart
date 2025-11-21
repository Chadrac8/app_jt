import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/task_model.dart';
import '../services/tasks_firebase_service.dart';
import '../widgets/task_comments_widget.dart';
import 'task_form_page.dart';
import '../../theme.dart';

class TaskDetailPage extends StatefulWidget {
  final TaskModel task;

  const TaskDetailPage({
    super.key,
    required this.task,
  });

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _heroAnimationController;
  late AnimationController _contentAnimationController;
  late Animation<Offset> _contentSlideAnimation;
  late Animation<double> _contentFadeAnimation;
  
  TaskModel? _currentTask;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentTask = widget.task;
    _tabController = TabController(length: 3, vsync: this);
    
    // Hero animation pour l'entrée
    _heroAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // Content animation pour le slide-in
    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _contentSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.easeOutCubic,
    ));
    _contentFadeAnimation = CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.easeOut,
    );
    
    // Démarrer les animations
    _heroAnimationController.forward();
    _contentAnimationController.forward(from: 0.3);
    
    _refreshTaskData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _heroAnimationController.dispose();
    _contentAnimationController.dispose();
    super.dispose();
  }

  Future<void> _refreshTaskData() async {
    try {
      final task = await TasksFirebaseService.getTask(widget.task.id);
      if (task != null && mounted) {
        setState(() => _currentTask = task);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du rafraîchissement: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _updateTaskStatus(String newStatus) async {
    try {
      setState(() => _isLoading = true);
      
      await TasksFirebaseService.updateTaskStatus(_currentTask!.id, newStatus);
      await _refreshTaskData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Statut mis à jour: ${_getStatusLabel(newStatus)}'),
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
    } finally {
      setState(() => _isLoading = false);
    }
  }



  String _getStatusLabel(String status) {
    switch (status) {
      case 'todo':
        return 'À faire';
      case 'in_progress':
        return 'En cours';
      case 'completed':
        return 'Terminé';
      case 'cancelled':
        return 'Annulé';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentTask == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: _buildLoadingIndicator(),
        ),
      );
    }

    return Theme(
      data: Theme.of(context).copyWith(
        // Adapter le theme pour Material Design 3
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.primaryColor,
          brightness: Brightness.light,
        ),
      ),
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // App bar moderne avec hero animation
            SliverAppBar.large(
              backgroundColor: AppTheme.surface,
              foregroundColor: AppTheme.onSurface,
              elevation: 0,
              shadowColor: Colors.transparent,
              surfaceTintColor: AppTheme.surfaceTint,
              pinned: true,
              stretch: true,
              title: FadeTransition(
                opacity: _contentFadeAnimation,
                child: Text(
                  _currentTask!.title,
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize24,
                    fontWeight: AppTheme.fontSemiBold,
                    color: AppTheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              leading: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  AppTheme.isApplePlatform ? CupertinoIcons.back : Icons.arrow_back,
                  color: AppTheme.onSurface,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.surfaceVariant.withOpacity(0.6),
                  foregroundColor: AppTheme.onSurfaceVariant,
                ),
              ),
              actions: [
                _buildActionButton(),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(120),
                child: SlideTransition(
                  position: _contentSlideAnimation,
                  child: FadeTransition(
                    opacity: _contentFadeAnimation,
                    child: _buildHeaderContent(),
                  ),
                ),
              ),
            ),
            
            // Tab bar avec Material Design 3
            SliverPersistentHeader(
              delegate: _ModernTabBarDelegate(_buildTabBar()),
              pinned: true,
            ),
            
            // Contenu principal
            SliverFillRemaining(
              child: SlideTransition(
                position: _contentSlideAnimation,
                child: FadeTransition(
                  opacity: _contentFadeAnimation,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDetailsTab(),
                      _buildCommentsTab(),
                      _buildActivityTab(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: ScaleTransition(
          scale: _contentFadeAnimation,
          child: _buildModernFAB(),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  // === NOUVEAUX WIDGETS MATERIAL DESIGN 3 ===

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceXLarge),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator.adaptive(),
          const SizedBox(height: AppTheme.spaceMedium),
          Text(
            'Chargement de la tâche...',
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize16,
              fontWeight: AppTheme.fontMedium,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(AppTheme.spaceSmall),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant.withOpacity(0.6),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        child: Icon(
          AppTheme.isApplePlatform ? CupertinoIcons.ellipsis : Icons.more_vert,
          color: AppTheme.onSurfaceVariant,
        ),
      ),
      elevation: AppTheme.elevation3,
      shadowColor: AppTheme.primaryColor.withOpacity(0.2),
      surfaceTintColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'edit',
          child: _buildMenuTile(
            icon: AppTheme.isApplePlatform ? CupertinoIcons.pencil : Icons.edit_outlined,
            title: 'Modifier',
            color: AppTheme.primaryColor,
          ),
        ),
        PopupMenuItem<String>(
          value: 'duplicate',
          child: _buildMenuTile(
            icon: AppTheme.isApplePlatform ? CupertinoIcons.doc_on_doc : Icons.content_copy_outlined,
            title: 'Dupliquer',
            color: AppTheme.info,
          ),
        ),
        PopupMenuItem<String>(
          value: 'share',
          child: _buildMenuTile(
            icon: AppTheme.isApplePlatform ? CupertinoIcons.share : Icons.share_outlined,
            title: 'Partager',
            color: AppTheme.secondaryColor,
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'delete',
          child: _buildMenuTile(
            icon: AppTheme.isApplePlatform ? CupertinoIcons.trash : Icons.delete_outline,
            title: 'Supprimer',
            color: AppTheme.error,
          ),
        ),
      ],
      onSelected: (value) {
        _handleMenuAction(value);
      },
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spaceSmall),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Icon(
            icon,
            color: color,
            size: 18,
          ),
        ),
        const SizedBox(width: AppTheme.space12),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: AppTheme.fontSize14,
            fontWeight: AppTheme.fontMedium,
            color: AppTheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMedium,
        AppTheme.spaceSmall,
        AppTheme.spaceMedium,
        AppTheme.spaceLarge,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badges de statut et priorité
          Row(
            children: [
              _buildModernBadge(
                label: _getStatusLabel(_currentTask!.status),
                color: _getStatusColor(_currentTask!.status),
                icon: _getStatusIcon(_currentTask!.status),
                isPrimary: true,
              ),
              const SizedBox(width: AppTheme.spaceSmall),
              _buildModernBadge(
                label: _getPriorityLabel(_currentTask!.priority),
                color: _getPriorityColor(_currentTask!.priority),
                icon: _getPriorityIcon(_currentTask!.priority),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.space12),
          
          // Date d'échéance et informations supplémentaires
          if (_currentTask!.dueDate != null)
            _buildInfoChip(
              icon: _currentTask!.isOverdue 
                  ? (AppTheme.isApplePlatform ? CupertinoIcons.exclamationmark_triangle : Icons.warning_outlined)
                  : (AppTheme.isApplePlatform ? CupertinoIcons.calendar : Icons.schedule_outlined),
              label: _formatDueDate(_currentTask!.dueDate!),
              color: _currentTask!.isOverdue ? AppTheme.error : AppTheme.info,
              isWarning: _currentTask!.isOverdue,
            ),
        ],
      ),
    );
  }

  Widget _buildModernBadge({
    required String label,
    required Color color,
    required IconData icon,
    bool isPrimary = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space12,
        vertical: AppTheme.spaceSmall,
      ),
      decoration: BoxDecoration(
        color: isPrimary ? color : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        border: isPrimary ? null : Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isPrimary ? AppTheme.white : color,
          ),
          const SizedBox(width: AppTheme.space6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize12,
              fontWeight: AppTheme.fontSemiBold,
              color: isPrimary ? AppTheme.white : color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
    bool isWarning = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space12,
        vertical: AppTheme.spaceSmall,
      ),
      decoration: BoxDecoration(
        color: isWarning ? color.withOpacity(0.1) : AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: isWarning ? Border.all(
          color: color.withOpacity(0.3),
        ) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isWarning ? color : AppTheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppTheme.spaceSmall),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize13,
              fontWeight: AppTheme.fontMedium,
              color: isWarning ? color : AppTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelStyle: GoogleFonts.inter(
          fontSize: AppTheme.fontSize14,
          fontWeight: AppTheme.fontSemiBold,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: AppTheme.fontSize14,
          fontWeight: AppTheme.fontMedium,
        ),
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: AppTheme.onSurfaceVariant,
        indicatorColor: AppTheme.primaryColor,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        tabs: [
          Tab(
            icon: Icon(
              AppTheme.isApplePlatform ? CupertinoIcons.info : Icons.info_outlined,
              size: 20,
            ),
            text: 'Détails',
          ),
          Tab(
            icon: Icon(
              AppTheme.isApplePlatform ? CupertinoIcons.chat_bubble_2 : Icons.comment_outlined,
              size: 20,
            ),
            text: 'Commentaires',
          ),
          Tab(
            icon: Icon(
              AppTheme.isApplePlatform ? CupertinoIcons.time : Icons.history_outlined,
              size: 20,
            ),
            text: 'Activité',
          ),
        ],
      ),
    );
  }

  Widget _buildModernFAB() {
    final isCompleted = _currentTask!.status == 'completed';
    return FloatingActionButton.extended(
      onPressed: () => _toggleTaskStatus(),
      backgroundColor: isCompleted ? AppTheme.warningContainer : AppTheme.successContainer,
      foregroundColor: isCompleted ? AppTheme.onWarningContainer : AppTheme.onSuccessContainer,
      elevation: AppTheme.elevation3,
      extendedPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLarge),
      icon: Icon(
        isCompleted 
            ? (AppTheme.isApplePlatform ? CupertinoIcons.refresh : Icons.refresh_outlined)
            : (AppTheme.isApplePlatform ? CupertinoIcons.check_mark : Icons.check_outlined),
        size: 20,
      ),
      label: Text(
        isCompleted ? 'Rouvrir' : 'Terminer',
        style: GoogleFonts.inter(
          fontSize: AppTheme.fontSize14,
          fontWeight: AppTheme.fontSemiBold,
        ),
      ),
    );
  }

  // === MÉTHODES UTILITAIRES MATERIAL DESIGN 3 ===

  void _handleMenuAction(String action) {
    HapticFeedback.lightImpact();
    
    switch (action) {
      case 'edit':
        _editTask();
        break;
      case 'duplicate':
        _duplicateTask();
        break;
      case 'share':
        _shareTask();
        break;
      case 'delete':
        _showModernDeleteConfirmation();
        break;
    }
  }

  Future<void> _editTask() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskFormPage(task: _currentTask),
      ),
    );
    
    if (result == true) {
      await _refreshTaskData();
    }
  }

  Future<void> _duplicateTask() async {
    try {
      setState(() => _isLoading = true);
      
      await TasksFirebaseService.duplicateTask(_currentTask!.id);
      
      if (mounted) {
        _showModernSnackBar(
          'Tâche dupliquée avec succès',
          AppTheme.success,
          CupertinoIcons.doc_on_doc,
        );
      }
    } catch (e) {
      if (mounted) {
        _showModernSnackBar(
          'Erreur lors de la duplication: $e',
          AppTheme.error,
          CupertinoIcons.exclamationmark_triangle,
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _shareTask() {
    // TODO: Implémenter le partage de tâche
    _showModernSnackBar(
      'Partage de tâche à implémenter',
      AppTheme.info,
      CupertinoIcons.share,
    );
  }

  void _toggleTaskStatus() async {
    try {
      setState(() => _isLoading = true);
      
      final newStatus = _currentTask!.status == 'completed' ? 'todo' : 'completed';
      await _updateTaskStatus(newStatus);
      
      HapticFeedback.mediumImpact();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return AppTheme.success;
      case 'in_progress':
        return AppTheme.warning;
      case 'cancelled':
        return AppTheme.outline;
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return AppTheme.isApplePlatform ? CupertinoIcons.check_mark_circled_solid : Icons.check_circle;
      case 'in_progress':
        return AppTheme.isApplePlatform ? CupertinoIcons.clock_solid : Icons.schedule;
      case 'cancelled':
        return AppTheme.isApplePlatform ? CupertinoIcons.xmark_circle_fill : Icons.cancel;
      default:
        return AppTheme.isApplePlatform ? CupertinoIcons.circle : Icons.radio_button_unchecked;
    }
  }

  String _getPriorityLabel(String priority) {
    switch (priority) {
      case 'high':
        return 'Haute';
      case 'medium':
        return 'Moyenne';
      case 'low':
        return 'Basse';
      default:
        return 'Normale';
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return AppTheme.error;
      case 'medium':
        return AppTheme.warning;
      case 'low':
        return AppTheme.success;
      default:
        return AppTheme.info;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority) {
      case 'high':
        return AppTheme.isApplePlatform ? CupertinoIcons.flag_fill : Icons.flag;
      case 'medium':
        return AppTheme.isApplePlatform ? CupertinoIcons.flag : Icons.outlined_flag;
      case 'low':
        return AppTheme.isApplePlatform ? CupertinoIcons.minus_circle : Icons.minimize;
      default:
        return AppTheme.isApplePlatform ? CupertinoIcons.circle : Icons.radio_button_unchecked;
    }
  }

  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now);
    
    if (difference.isNegative) {
      return 'En retard de ${difference.inDays.abs()} jour(s)';
    } else if (difference.inDays == 0) {
      return 'Échéance aujourd\'hui';
    } else if (difference.inDays == 1) {
      return 'Échéance demain';
    } else {
      return 'Échéance dans ${difference.inDays} jour(s)';
    }
  }

  void _showModernSnackBar(String message, Color color, IconData icon) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceSmall),
              decoration: BoxDecoration(
                color: AppTheme.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Icon(
                icon,
                color: AppTheme.white,
                size: 16,
              ),
            ),
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: AppTheme.fontSize14,
                  fontWeight: AppTheme.fontMedium,
                  color: AppTheme.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        margin: const EdgeInsets.all(AppTheme.spaceMedium),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _showModernDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        surfaceTintColor: AppTheme.error,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceSmall),
              decoration: BoxDecoration(
                color: AppTheme.errorContainer,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              ),
              child: Icon(
                AppTheme.isApplePlatform ? CupertinoIcons.trash : Icons.delete_outlined,
                color: AppTheme.onErrorContainer,
                size: 20,
              ),
            ),
            const SizedBox(width: AppTheme.space12),
            Text(
              'Supprimer la tâche',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize18,
                fontWeight: AppTheme.fontSemiBold,
                color: AppTheme.onSurface,
              ),
            ),
          ],
        ),
        content: Text(
          'Cette action est irréversible. Voulez-vous vraiment supprimer cette tâche ?',
          style: GoogleFonts.inter(
            fontSize: AppTheme.fontSize14,
            color: AppTheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Annuler',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize14,
                fontWeight: AppTheme.fontMedium,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: AppTheme.onError,
            ),
            child: Text(
              'Supprimer',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize14,
                fontWeight: AppTheme.fontSemiBold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await TasksFirebaseService.deleteTask(_currentTask!.id);
        if (mounted) {
          Navigator.pop(context);
          _showModernSnackBar(
            'Tâche supprimée',
            AppTheme.success,
            CupertinoIcons.checkmark,
          );
        }
      } catch (e) {
        if (mounted) {
          _showModernSnackBar(
            'Erreur lors de la suppression: $e',
            AppTheme.error,
            CupertinoIcons.exclamationmark_triangle,
          );
        }
      }
    }
  }



  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description avec Material Design 3
          if (_currentTask!.description.isNotEmpty) ...[
            _buildModernInfoCard(
              title: 'Description',
              icon: AppTheme.isApplePlatform ? CupertinoIcons.doc_text : Icons.description_outlined,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTheme.spaceMedium),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    _currentTask!.description,
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize14,
                      height: 1.6,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceLarge),
          ],
          
          // Informations principales
          _buildModernInfoCard(
            title: 'Informations',
            icon: AppTheme.isApplePlatform ? CupertinoIcons.info : Icons.info_outlined,
            children: [
              _buildModernInfoRow(
                icon: AppTheme.isApplePlatform ? CupertinoIcons.person : Icons.person_outlined,
                label: 'Créé par',
                value: _currentTask!.createdBy,
                color: AppTheme.primaryColor,
              ),
              if (_currentTask!.assigneeIds.isNotEmpty)
                _buildModernInfoRow(
                  icon: AppTheme.isApplePlatform ? CupertinoIcons.group : Icons.people_outlined,
                  label: 'Assigné à',
                  value: '${_currentTask!.assigneeIds.length} personne(s)',
                  color: AppTheme.secondaryColor,
                ),
              _buildModernInfoRow(
                icon: AppTheme.isApplePlatform ? CupertinoIcons.calendar : Icons.calendar_today_outlined,
                label: 'Créé le',
                value: _formatDate(_currentTask!.createdAt),
                color: AppTheme.info,
              ),
              if (_currentTask!.updatedAt != _currentTask!.createdAt)
                _buildModernInfoRow(
                  icon: AppTheme.isApplePlatform ? CupertinoIcons.clock : Icons.update_outlined,
                  label: 'Modifié le',
                  value: _formatDate(_currentTask!.updatedAt),
                  color: AppTheme.warning,
                ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spaceLarge),
          
          // Tags modernes
          if (_currentTask!.tags.isNotEmpty) ...[
            _buildModernInfoCard(
              title: 'Étiquettes',
              icon: AppTheme.isApplePlatform ? CupertinoIcons.tag : Icons.label_outlined,
              children: [
                Wrap(
                  spacing: AppTheme.spaceSmall,
                  runSpacing: AppTheme.spaceSmall,
                  children: _currentTask!.tags.map((tag) {
                    return _buildModernTag(tag);
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceLarge),
          ],
          
          // Pièces jointes
          if (_currentTask!.attachmentUrls.isNotEmpty) ...[
            _buildModernInfoCard(
              title: 'Pièces jointes',
              icon: AppTheme.isApplePlatform ? CupertinoIcons.paperclip : Icons.attach_file_outlined,
              children: [
                ..._currentTask!.attachmentUrls.map((url) {
                  return _buildAttachmentTile(url);
                }).toList(),
              ],
            ),
            const SizedBox(height: AppTheme.spaceLarge),
          ],
          
          // Éléments liés
          if (_currentTask!.linkedToType != null) ...[
            _buildModernInfoCard(
              title: 'Lié à',
              icon: AppTheme.isApplePlatform ? CupertinoIcons.link : Icons.link_outlined,
              children: [
                _buildModernInfoRow(
                  icon: AppTheme.isApplePlatform ? CupertinoIcons.square_stack_3d_down_dottedline : Icons.category_outlined,
                  label: 'Type',
                  value: _currentTask!.linkedToType!,
                  color: AppTheme.tertiaryColor,
                ),
                _buildModernInfoRow(
                  icon: AppTheme.isApplePlatform ? CupertinoIcons.number_square : Icons.tag_outlined,
                  label: 'Identifiant',
                  value: _currentTask!.linkedToId ?? '',
                  color: AppTheme.tertiaryColor,
                ),
              ],
            ),
          ],
          
          // Espace supplémentaire pour le FAB
          const SizedBox(height: AppTheme.spaceXXLarge),
        ],
      ),
    );
  }

  // === NOUVEAUX COMPOSANTS MATERIAL DESIGN 3 ===

  Widget _buildModernInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        border: Border.all(
          color: AppTheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête de carte moderne
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.space10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  ),
                  child: Icon(
                    icon,
                    color: AppTheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppTheme.space12),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize18,
                    fontWeight: AppTheme.fontSemiBold,
                    color: AppTheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildModernInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceSmall),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Icon(
              icon,
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize12,
                    fontWeight: AppTheme.fontMedium,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppTheme.space2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize14,
                    fontWeight: AppTheme.fontMedium,
                    color: AppTheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTag(String tag) {
    final colors = [
      AppTheme.primaryColor,
      AppTheme.secondaryColor,
      AppTheme.tertiaryColor,
      AppTheme.info,
      AppTheme.success,
      AppTheme.warning,
    ];
    final color = colors[tag.hashCode % colors.length];
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space12,
        vertical: AppTheme.spaceSmall,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppTheme.spaceSmall),
          Text(
            tag,
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize12,
              fontWeight: AppTheme.fontMedium,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentTile(String url) {
    final fileName = url.split('/').last;
    final extension = fileName.split('.').last.toLowerCase();
    
    IconData fileIcon;
    Color fileColor;
    
    switch (extension) {
      case 'pdf':
        fileIcon = AppTheme.isApplePlatform ? CupertinoIcons.doc_text_fill : Icons.picture_as_pdf;
        fileColor = AppTheme.error;
        break;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        fileIcon = AppTheme.isApplePlatform ? CupertinoIcons.photo_fill : Icons.image;
        fileColor = AppTheme.success;
        break;
      case 'doc':
      case 'docx':
        fileIcon = AppTheme.isApplePlatform ? CupertinoIcons.doc_fill : Icons.description;
        fileColor = AppTheme.info;
        break;
      default:
        fileIcon = AppTheme.isApplePlatform ? CupertinoIcons.doc : Icons.insert_drive_file;
        fileColor = AppTheme.onSurfaceVariant;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceSmall),
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: AppTheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.space10),
            decoration: BoxDecoration(
              color: fileColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Icon(
              fileIcon,
              color: fileColor,
              size: 20,
            ),
          ),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize14,
                    fontWeight: AppTheme.fontMedium,
                    color: AppTheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  extension.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize12,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // TODO: Ouvrir ou télécharger le fichier
              _showModernSnackBar(
                'Téléchargement à implémenter',
                AppTheme.info,
                CupertinoIcons.arrow_down_circle,
              );
            },
            icon: Icon(
              AppTheme.isApplePlatform ? CupertinoIcons.arrow_down_circle : Icons.download_outlined,
              color: AppTheme.primaryColor,
            ),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.primaryContainer,
              foregroundColor: AppTheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsTab() {
    return Container(
      color: AppTheme.background,
      child: TaskCommentsWidget(task: _currentTask!),
    );
  }

  Widget _buildActivityTab() {
    return Container(
      color: AppTheme.background,
      padding: const EdgeInsets.all(AppTheme.spaceLarge),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceXLarge),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(AppTheme.radiusXXLarge),
              ),
              child: Icon(
                AppTheme.isApplePlatform ? CupertinoIcons.time : Icons.history_outlined,
                size: 48,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            Text(
              'Historique des activités',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize20,
                fontWeight: AppTheme.fontSemiBold,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: AppTheme.spaceSmall),
            Text(
              'Cette fonctionnalité sera bientôt disponible',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize14,
                color: AppTheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    const months = [
      'jan', 'fév', 'mar', 'avr', 'mai', 'jun',
      'jul', 'aoû', 'sep', 'oct', 'nov', 'déc'
    ];
    
    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
  }
}

// === DELEGATE POUR LA TAB BAR MODERNE ===

class _ModernTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget _tabBar;

  _ModernTabBarDelegate(this._tabBar);

  @override
  double get minExtent => 56.0;

  @override
  double get maxExtent => 56.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_ModernTabBarDelegate oldDelegate) {
    return false;
  }
}