import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import '../models/task_model.dart';
import '../models/person_model.dart';
import '../services/tasks_firebase_service.dart';
import '../services/firebase_service.dart';
import '../auth/auth_service.dart';
import '../../theme.dart';
import '../image_upload.dart';

class TaskFormPage extends StatefulWidget {
  final TaskModel? task;

  const TaskFormPage({super.key, this.task});

  @override
  State<TaskFormPage> createState() => _TaskFormPageState();
}

class _TaskFormPageState extends State<TaskFormPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // Form values
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  String _priority = 'medium';
  String _status = 'todo';
  List<String> _assigneeIds = [];
  List<String> _tags = [];
  List<String> _attachmentUrls = [];
  String? _linkedToType;
  String? _linkedToId;
  String? _taskListId;
  bool _isRecurring = false;
  Map<String, dynamic>? _recurrencePattern;
  bool _isLoading = false;

  final List<Map<String, String>> _priorityOptions = [
    {'value': 'low', 'label': 'Basse', 'color': '4CAF50'},
    {'value': 'medium', 'label': 'Moyenne', 'color': 'FF9800'},
    {'value': 'high', 'label': 'Haute', 'color': 'F44336'},
  ];

  final List<Map<String, String>> _statusOptions = [
    {'value': 'todo', 'label': 'À faire'},
    {'value': 'in_progress', 'label': 'En cours'},
    {'value': 'completed', 'label': 'Terminé'},
    {'value': 'cancelled', 'label': 'Annulé'},
  ];



  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeForm();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuart),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _animationController.forward();
  }

  void _initializeForm() {
    if (widget.task != null) {
      final task = widget.task!;
      _titleController.text = task.title;
      _descriptionController.text = task.description;
      _dueDate = task.dueDate;
      if (task.dueDate != null) {
        _dueTime = TimeOfDay.fromDateTime(task.dueDate!);
      }
      _priority = task.priority;
      _status = task.status;
      _assigneeIds = List.from(task.assigneeIds);
      _tags = List.from(task.tags);
      _attachmentUrls = List.from(task.attachmentUrls);
      _linkedToType = task.linkedToType;
      _linkedToId = task.linkedToId;
      _taskListId = task.taskListId;
      _isRecurring = task.isRecurring;
      _recurrencePattern = task.recurrencePattern;
    }
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    
    if (date != null) {
      setState(() => _dueDate = date);
      if (_dueTime == null) {
        setState(() => _dueTime = TimeOfDay.now());
      }
    }
  }

  Future<void> _selectDueTime() async {
    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez d\'abord sélectionner une date')),
      );
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
    );
    
    if (time != null) {
      setState(() => _dueTime = time);
    }
  }

  void _addTag() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Ajouter un tag'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Nom du tag',
              hintText: 'ex: urgent, personnel',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final tag = controller.text.trim();
                if (tag.isNotEmpty && !_tags.contains(tag)) {
                  setState(() => _tags.add(tag));
                }
                Navigator.pop(context);
              },
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickAttachment() async {
    try {
      final bytes = await ImageUploadHelper.pickImageFromGallery();
      if (bytes != null) {
        setState(() => _isLoading = true);
        
        final fileName = 'attachment_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final taskId = widget.task?.id ?? 'temp_${DateTime.now().millisecondsSinceEpoch}';
        final url = await TasksFirebaseService.uploadTaskAttachment(bytes, fileName, taskId);
        
        setState(() {
          _attachmentUrls.add(url);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du téléchargement: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _selectAssignees() async {
    try {
      final persons = await FirebaseService.getAllPersons();
      
      if (!mounted) return;
      
      final selectedIds = await showDialog<List<String>>(
        context: context,
        builder: (context) => _AssigneeSelectionDialog(
          persons: persons,
          selectedIds: _assigneeIds,
        ),
      );
      
      if (selectedIds != null) {
        setState(() => _assigneeIds = selectedIds);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des personnes: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _selectTaskList() async {
    try {
      final taskLists = await TasksFirebaseService.getTaskListsStream().first;
      
      if (!mounted) return;
      
      final selectedListId = await showDialog<String>(
        context: context,
        builder: (context) => _TaskListSelectionDialog(
          taskLists: taskLists,
          selectedId: _taskListId,
        ),
      );
      
      setState(() => _taskListId = selectedListId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des listes: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      DateTime? combinedDueDate;
      if (_dueDate != null && _dueTime != null) {
        combinedDueDate = DateTime(
          _dueDate!.year,
          _dueDate!.month,
          _dueDate!.day,
          _dueTime!.hour,
          _dueTime!.minute,
        );
      } else if (_dueDate != null) {
        combinedDueDate = _dueDate;
      }

      final now = DateTime.now();
      final currentUserId = AuthService.currentUser?.uid ?? '';

      if (widget.task == null) {
        // Create new task
        final task = TaskModel(
          id: '',
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          dueDate: combinedDueDate,
          priority: _priority,
          status: _status,
          assigneeIds: _assigneeIds,
          createdBy: currentUserId,
          tags: _tags,
          attachmentUrls: _attachmentUrls,
          linkedToType: _linkedToType,
          linkedToId: _linkedToId,
          taskListId: _taskListId,
          isRecurring: _isRecurring,
          recurrencePattern: _recurrencePattern,
          createdAt: now,
          updatedAt: now,
        );

        await TasksFirebaseService.createTask(task);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tâche créée avec succès'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        // Update existing task
        final updatedTask = widget.task!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          dueDate: combinedDueDate,
          priority: _priority,
          status: _status,
          assigneeIds: _assigneeIds,
          tags: _tags,
          attachmentUrls: _attachmentUrls,
          linkedToType: _linkedToType,
          linkedToId: _linkedToId,
          taskListId: _taskListId,
          isRecurring: _isRecurring,
          recurrencePattern: _recurrencePattern,
          updatedAt: now,
          lastModifiedBy: currentUserId,
        );

        await TasksFirebaseService.updateTask(updatedTask);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tâche mise à jour avec succès'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isApple = Platform.isIOS || Platform.isMacOS;
    
    return Theme(
      data: Theme.of(context).copyWith(
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
            // App bar moderne avec Material Design 3
            SliverAppBar.large(
              backgroundColor: AppTheme.surface,
              foregroundColor: AppTheme.onSurface,
              elevation: 0,
              shadowColor: Colors.transparent,
              surfaceTintColor: AppTheme.surfaceTint,
              pinned: true,
              stretch: true,
              title: AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      widget.task == null ? 'Nouvelle tâche' : 'Modifier la tâche',
                      style: GoogleFonts.inter(
                        fontSize: AppTheme.fontSize24,
                        fontWeight: AppTheme.fontSemiBold,
                        color: AppTheme.onSurface,
                      ),
                    ),
                  );
                },
              ),
              leading: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  isApple ? CupertinoIcons.back : Icons.arrow_back_rounded,
                  color: AppTheme.onSurface,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.surfaceVariant.withOpacity(0.6),
                  foregroundColor: AppTheme.onSurfaceVariant,
                ),
              ),
              actions: [
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildSaveButton(isApple),
                    );
                  },
                ),
              ],
            ),
            
            // Contenu principal avec animation
            SliverToBoxAdapter(
              child: AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: Transform.translate(
                      offset: Offset(0, 30 * _slideAnimation.value),
                      child: _buildModernForm(isApple),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return ScaleTransition(
              scale: _fadeAnimation,
              child: _buildModernFAB(isApple),
            );
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  Widget _buildSaveButton(bool isApple) {
    return Container(
      margin: const EdgeInsets.only(right: AppTheme.spaceMedium),
      child: _isLoading
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primaryColor,
              ),
            )
          : Material(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  HapticFeedback.lightImpact();
                  _saveTask();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceMedium,
                    vertical: AppTheme.spaceSmall,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isApple ? CupertinoIcons.checkmark : Icons.save_rounded,
                        color: AppTheme.white100,
                        size: 18,
                      ),
                      const SizedBox(width: AppTheme.spaceSmall),
                      Text(
                        'Sauvegarder',
                        style: GoogleFonts.inter(
                          fontSize: AppTheme.fontSize14,
                          fontWeight: AppTheme.fontMedium,
                          color: AppTheme.white100,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildModernFAB(bool isApple) {
    return FloatingActionButton.extended(
      onPressed: _isLoading ? null : () {
        HapticFeedback.mediumImpact();
        _saveTask();
      },
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: AppTheme.white100,
      elevation: 6,
      icon: _isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.white100,
              ),
            )
          : Icon(isApple ? CupertinoIcons.checkmark : Icons.save_rounded),
      label: Text(
        _isLoading ? 'Sauvegarde...' : 'Sauvegarder',
        style: GoogleFonts.inter(
          fontSize: AppTheme.fontSize14,
          fontWeight: AppTheme.fontMedium,
        ),
      ),
    );
  }

  Widget _buildModernForm(bool isApple) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Section Informations générales
          _buildModernSection(
            title: 'Informations générales',
            icon: isApple ? CupertinoIcons.info : Icons.info_outline_rounded,
            isApple: isApple,
            children: [
              _buildModernTextField(
                controller: _titleController,
                label: 'Titre de la tâche',
                hint: 'Entrez le titre de la tâche',
                icon: isApple ? CupertinoIcons.textformat : Icons.title_rounded,
                isApple: isApple,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le titre est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spaceLarge),
              _buildModernTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Décrivez la tâche en détail',
                icon: isApple ? CupertinoIcons.doc_text : Icons.description_rounded,
                isApple: isApple,
                maxLines: 3,
              ),
            ],
          ),
          
          // Section Priorité et statut
          _buildModernSection(
            title: 'Priorité et statut',
            icon: isApple ? CupertinoIcons.flag : Icons.flag_outlined,
            isApple: isApple,
            children: [
              _buildModernPrioritySelector(isApple),
              const SizedBox(height: AppTheme.spaceLarge),
              _buildModernStatusSelector(isApple),
            ],
          ),
          
          // Section Échéance
          _buildModernSection(
            title: 'Échéance',
            icon: isApple ? CupertinoIcons.clock : Icons.schedule_rounded,
            isApple: isApple,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildModernDateField('Date d\'échéance', _dueDate, _selectDueDate, isApple),
                  ),
                  const SizedBox(width: AppTheme.spaceMedium),
                  Expanded(
                    child: _buildModernTimeField('Heure', _dueTime, _selectDueTime, isApple),
                  ),
                ],
              ),
            ],
          ),
          
          // Section Assignation
          _buildModernSection(
            title: 'Assignation',
            icon: isApple ? CupertinoIcons.person_2 : Icons.people_outline_rounded,
            isApple: isApple,
            children: [
              _buildModernAssigneeSelector(isApple),
            ],
          ),
          
          // Section Organisation
          _buildModernSection(
            title: 'Organisation',
            icon: isApple ? CupertinoIcons.folder : Icons.folder_outlined,
            isApple: isApple,
            children: [
              _buildModernTaskListSelector(isApple),
              const SizedBox(height: AppTheme.spaceLarge),
              _buildModernTagsSection(isApple),
            ],
          ),
          
          // Section Pièces jointes
          _buildModernSection(
            title: 'Pièces jointes',
            icon: isApple ? CupertinoIcons.paperclip : Icons.attach_file_rounded,
            isApple: isApple,
            children: [
              _buildModernAttachmentsSection(isApple),
            ],
          ),
          
          // Espacement final
          const SizedBox(height: 100), // Pour le FAB
        ],
      ),
    );
  }

  Widget _buildModernSection({
    required String title,
    required IconData icon,
    required bool isApple,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppTheme.space20,
        AppTheme.space20,
        AppTheme.space20,
        0,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spaceSmall),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMedium),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize16,
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

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isApple,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(
          fontSize: AppTheme.fontSize16,
          fontWeight: AppTheme.fontMedium,
          color: AppTheme.onSurface,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, size: 20, color: AppTheme.onSurfaceVariant),
          ),
          labelStyle: GoogleFonts.inter(
            fontSize: AppTheme.fontSize14,
            fontWeight: AppTheme.fontMedium,
            color: AppTheme.onSurfaceVariant,
          ),
          hintStyle: GoogleFonts.inter(
            fontSize: AppTheme.fontSize14,
            fontWeight: AppTheme.fontRegular,
            color: AppTheme.onSurfaceVariant.withOpacity(0.6),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceMedium,
            vertical: AppTheme.spaceMedium,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
        onTap: () => HapticFeedback.selectionClick(),
      ),
    );
  }

  Widget _buildModernPrioritySelector(bool isApple) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            child: Row(
              children: [
                Icon(
                  isApple ? CupertinoIcons.flag : Icons.flag_outlined,
                  size: 20,
                  color: AppTheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppTheme.spaceSmall),
                Text(
                  'Priorité',
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize14,
                    fontWeight: AppTheme.fontMedium,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          ...(_priorityOptions.map((option) => 
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _priority = option['value']!);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceMedium,
                    vertical: AppTheme.spaceSmall,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.only(right: AppTheme.spaceMedium),
                        decoration: BoxDecoration(
                          color: Color(int.parse('FF${option['color']}', radix: 16)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          option['label']!,
                          style: GoogleFonts.inter(
                            fontSize: AppTheme.fontSize16,
                            fontWeight: _priority == option['value'] 
                                ? AppTheme.fontSemiBold 
                                : AppTheme.fontMedium,
                            color: AppTheme.onSurface,
                          ),
                        ),
                      ),
                      if (_priority == option['value'])
                        Icon(
                          isApple ? CupertinoIcons.checkmark : Icons.check_rounded,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ).toList()),
        ],
      ),
    );
  }

  Widget _buildModernStatusSelector(bool isApple) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            child: Row(
              children: [
                Icon(
                  isApple ? CupertinoIcons.checkmark_circle : Icons.task_alt_rounded,
                  size: 20,
                  color: AppTheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppTheme.spaceSmall),
                Text(
                  'Statut',
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize14,
                    fontWeight: AppTheme.fontMedium,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          ...(_statusOptions.map((option) => 
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _status = option['value']!);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceMedium,
                    vertical: AppTheme.spaceSmall,
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 32), // Align with priority icons
                      Expanded(
                        child: Text(
                          option['label']!,
                          style: GoogleFonts.inter(
                            fontSize: AppTheme.fontSize16,
                            fontWeight: _status == option['value'] 
                                ? AppTheme.fontSemiBold 
                                : AppTheme.fontMedium,
                            color: AppTheme.onSurface,
                          ),
                        ),
                      ),
                      if (_status == option['value'])
                        Icon(
                          isApple ? CupertinoIcons.checkmark : Icons.check_rounded,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ).toList()),
        ],
      ),
    );
  }

  Widget _buildModernDateField(String label, DateTime? date, VoidCallback onTap, bool isApple) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Row(
          children: [
            Icon(
              isApple ? CupertinoIcons.calendar : Icons.calendar_today_rounded,
              size: 20,
              color: AppTheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppTheme.spaceMedium),
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
                  const SizedBox(height: 4),
                  Text(
                    date != null 
                        ? DateFormat('dd MMM yyyy', 'fr_FR').format(date)
                        : 'Aucune date',
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize16,
                      fontWeight: AppTheme.fontMedium,
                      color: date != null ? AppTheme.onSurface : AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isApple ? CupertinoIcons.chevron_right : Icons.chevron_right_rounded,
              color: AppTheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTimeField(String label, TimeOfDay? time, VoidCallback onTap, bool isApple) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Row(
          children: [
            Icon(
              isApple ? CupertinoIcons.clock : Icons.access_time_rounded,
              size: 20,
              color: AppTheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppTheme.spaceMedium),
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
                  const SizedBox(height: 4),
                  Text(
                    time != null 
                        ? time.format(context)
                        : 'Aucune heure',
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize16,
                      fontWeight: AppTheme.fontMedium,
                      color: time != null ? AppTheme.onSurface : AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isApple ? CupertinoIcons.chevron_right : Icons.chevron_right_rounded,
              color: AppTheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAssigneeSelector(bool isApple) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _selectAssignees();
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Row(
          children: [
            Icon(
              isApple ? CupertinoIcons.person_2 : Icons.people_outline_rounded,
              size: 20,
              color: AppTheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppTheme.spaceMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assignés',
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize12,
                      fontWeight: AppTheme.fontMedium,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _assigneeIds.isEmpty 
                        ? 'Aucune personne assignée'
                        : '${_assigneeIds.length} personne(s) assignée(s)',
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize16,
                      fontWeight: AppTheme.fontMedium,
                      color: _assigneeIds.isNotEmpty ? AppTheme.onSurface : AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isApple ? CupertinoIcons.chevron_right : Icons.chevron_right_rounded,
              color: AppTheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTaskListSelector(bool isApple) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _selectTaskList();
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Row(
          children: [
            Icon(
              isApple ? CupertinoIcons.list_bullet : Icons.list_alt_rounded,
              size: 20,
              color: AppTheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppTheme.spaceMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Liste de tâches',
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize12,
                      fontWeight: AppTheme.fontMedium,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _taskListId != null ? 'Liste sélectionnée' : 'Aucune liste',
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize16,
                      fontWeight: AppTheme.fontMedium,
                      color: _taskListId != null ? AppTheme.onSurface : AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isApple ? CupertinoIcons.chevron_right : Icons.chevron_right_rounded,
              color: AppTheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTagsSection(bool isApple) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isApple ? CupertinoIcons.tag : Icons.label_outline_rounded,
                      size: 20,
                      color: AppTheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppTheme.spaceSmall),
                    Text(
                      'Tags',
                      style: GoogleFonts.inter(
                        fontSize: AppTheme.fontSize14,
                        fontWeight: AppTheme.fontMedium,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Material(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _addTag();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        isApple ? CupertinoIcons.add : Icons.add_rounded,
                        color: AppTheme.white100,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceMedium,
                0,
                AppTheme.spaceMedium,
                AppTheme.spaceMedium,
              ),
              child: Wrap(
                spacing: AppTheme.spaceSmall,
                runSpacing: AppTheme.spaceSmall,
                children: _tags.map((tag) => 
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spaceSmall,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          tag,
                          style: GoogleFonts.inter(
                            fontSize: AppTheme.fontSize12,
                            fontWeight: AppTheme.fontMedium,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() => _tags.remove(tag));
                          },
                          child: Icon(
                            isApple ? CupertinoIcons.xmark : Icons.close_rounded,
                            size: 14,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).toList(),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceMedium,
                0,
                AppTheme.spaceMedium,
                AppTheme.spaceMedium,
              ),
              child: Text(
                'Aucun tag ajouté',
                style: GoogleFonts.inter(
                  fontSize: AppTheme.fontSize14,
                  fontWeight: AppTheme.fontMedium,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModernAttachmentsSection(bool isApple) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isApple ? CupertinoIcons.paperclip : Icons.attach_file_rounded,
                      size: 20,
                      color: AppTheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppTheme.spaceSmall),
                    Text(
                      'Pièces jointes',
                      style: GoogleFonts.inter(
                        fontSize: AppTheme.fontSize14,
                        fontWeight: AppTheme.fontMedium,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Material(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _pickAttachment();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        isApple ? CupertinoIcons.add : Icons.add_rounded,
                        color: AppTheme.white100,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spaceMedium,
              0,
              AppTheme.spaceMedium,
              AppTheme.spaceMedium,
            ),
            child: _attachmentUrls.isNotEmpty
                ? Column(
                    children: _attachmentUrls.map((url) => 
                      Container(
                        margin: const EdgeInsets.only(bottom: AppTheme.spaceSmall),
                        padding: const EdgeInsets.all(AppTheme.spaceSmall),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.outline.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isApple ? CupertinoIcons.doc : Icons.insert_drive_file_rounded,
                              size: 20,
                              color: AppTheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: AppTheme.spaceSmall),
                            Expanded(
                              child: Text(
                                'Pièce jointe',
                                style: GoogleFonts.inter(
                                  fontSize: AppTheme.fontSize14,
                                  fontWeight: AppTheme.fontMedium,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setState(() => _attachmentUrls.remove(url));
                              },
                              child: Icon(
                                isApple ? CupertinoIcons.trash : Icons.delete_outline_rounded,
                                size: 20,
                                color: AppTheme.errorColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).toList(),
                  )
                : Text(
                    'Aucune pièce jointe',
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize14,
                      fontWeight: AppTheme.fontMedium,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

}

class _AssigneeSelectionDialog extends StatefulWidget {
  final List<PersonModel> persons;
  final List<String> selectedIds;

  const _AssigneeSelectionDialog({
    required this.persons,
    required this.selectedIds,
  });

  @override
  State<_AssigneeSelectionDialog> createState() => _AssigneeSelectionDialogState();
}

class _AssigneeSelectionDialogState extends State<_AssigneeSelectionDialog> {
  late List<String> _selectedIds;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    final filteredPersons = widget.persons.where((person) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return person.fullName.toLowerCase().contains(query) ||
                              (person.email?.toLowerCase().contains(query) ?? false);
    }).toList();

    return AlertDialog(
      title: const Text('Sélectionner les responsables'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Rechercher',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            Expanded(
              child: ListView.builder(
                itemCount: filteredPersons.length,
                itemBuilder: (context, index) {
                  final person = filteredPersons[index];
                  final isSelected = _selectedIds.contains(person.id);
                  
                  return CheckboxListTile(
                    title: Text(person.fullName),
                                            subtitle: Text(person.email ?? ''),
                    value: isSelected,
                    onChanged: (selected) {
                      setState(() {
                        if (selected == true) {
                          _selectedIds.add(person.id);
                        } else {
                          _selectedIds.remove(person.id);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedIds),
          child: const Text('Confirmer'),
        ),
      ],
    );
  }
}

class _TaskListSelectionDialog extends StatelessWidget {
  final List<TaskListModel> taskLists;
  final String? selectedId;

  const _TaskListSelectionDialog({
    required this.taskLists,
    this.selectedId,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sélectionner une liste'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: taskLists.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return RadioListTile<String?>(
                title: const Text('Aucune liste'),
                value: null,
                groupValue: selectedId,
                onChanged: (value) => Navigator.pop(context, value),
              );
            }
            
            final taskList = taskLists[index - 1];
            return RadioListTile<String?>(
              title: Text(taskList.name),
              subtitle: Text(taskList.description),
              value: taskList.id,
              groupValue: selectedId,
              onChanged: (value) => Navigator.pop(context, value),
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
}