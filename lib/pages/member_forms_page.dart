import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/form_model.dart';
import '../services/forms_firebase_service.dart';
import '../auth/auth_service.dart';
import '../../theme.dart';
import 'form_public_page.dart';

class MemberFormsPage extends StatefulWidget {
  const MemberFormsPage({super.key});

  @override
  State<MemberFormsPage> createState() => _MemberFormsPageState();
}

class _MemberFormsPageState extends State<MemberFormsPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  List<FormModel> _availableForms = [];
  List<FormSubmissionModel> _mySubmissions = [];
  bool _isLoading = true;
  String _selectedTab = 'available';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadFormsData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  Future<void> _loadFormsData() async {
    try {
      final user = AuthService.currentUser;
      if (user == null) return;

      // Charger les formulaires disponibles
      final formsStream = FormsFirebaseService.getFormsStream(
        statusFilter: 'publie',
        limit: 100,
      );

      await for (final forms in formsStream.take(1)) {
        if (mounted) {
          setState(() {
            _availableForms = forms;
          });
        }
        break;
      }

      // Charger mes soumissions
      final submissions = await FormsFirebaseService.getUserSubmissions(user.uid);
      if (mounted) {
        setState(() {
          _mySubmissions = submissions;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement : $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _fillForm(FormModel form) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => FormPublicPage(formId: form.id),
      ),
    );

    if (result == true) {
      // Recharger les données après soumission
      _loadFormsData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar.large(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Mes Formulaires',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 24,
                  ),
                ),
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primary,
                        colorScheme.primary.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -50,
                        top: -50,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.onPrimary.withOpacity(0.1),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 20,
                        bottom: 80,
                        child: Icon(
                          Icons.assignment_outlined,
                          size: 80,
                          color: colorScheme.onPrimary.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Chargement des formulaires...',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
            : FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    _buildTabSelector(),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadFormsData,
                        child: _selectedTab == 'available'
                            ? _buildAvailableFormsList()
                            : _buildMySubmissionsList(),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTabSelector() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              'available',
              'Disponibles',
              Icons.assignment_outlined,
              _availableForms.length,
              colorScheme,
            ),
          ),
          Expanded(
            child: _buildTabButton(
              'submitted',
              'Mes Réponses',
              Icons.assignment_turned_in_outlined,
              _mySubmissions.length,
              colorScheme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tabId, String title, IconData icon, int count, ColorScheme colorScheme) {
    final isSelected = _selectedTab == tabId;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedTab = tabId),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 14,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? colorScheme.onPrimary.withOpacity(0.2) 
                        : colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: GoogleFonts.poppins(
                      color: isSelected 
                          ? colorScheme.onPrimary 
                          : colorScheme.onPrimaryContainer,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvailableFormsList() {
    final colorScheme = Theme.of(context).colorScheme;
    
    if (_availableForms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.assignment_outlined,
                size: 48,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucun formulaire disponible',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Les formulaires à remplir apparaîtront ici',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _availableForms.length,
      itemBuilder: (context, index) {
        final form = _availableForms[index];
        final hasSubmitted = _mySubmissions.any((s) => s.formId == form.id);
        return _buildAvailableFormCard(form, hasSubmitted);
      },
    );
  }

  Widget _buildMySubmissionsList() {
    final colorScheme = Theme.of(context).colorScheme;
    
    if (_mySubmissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.assignment_turned_in_outlined,
                size: 48,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucune réponse soumise',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vos réponses aux formulaires apparaîtront ici',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _mySubmissions.length,
      itemBuilder: (context, index) {
        final submission = _mySubmissions[index];
        return _buildSubmissionCard(submission);
      },
    );
  }

  Widget _buildAvailableFormCard(FormModel form, bool hasSubmitted) {
    final colorScheme = Theme.of(context).colorScheme;
    final isOpen = form.isOpen;
    final canSubmit = isOpen && (!hasSubmitted || form.settings.allowMultipleSubmissions);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: canSubmit ? () => _fillForm(form) : null,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _getFormColor(form.accessibility).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      _getFormIcon(form.accessibility),
                      color: _getFormColor(form.accessibility),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          form.title,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getFormColor(form.accessibility).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            form.accessibilityLabel,
                            style: GoogleFonts.poppins(
                              color: _getFormColor(form.accessibility),
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasSubmitted)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Rempli',
                        style: GoogleFonts.poppins(
                          color: colorScheme.onPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              
              if (form.description.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  form.description,
                  style: GoogleFonts.poppins(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                    fontSize: 14,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Icon(
                    Icons.quiz_outlined,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${form.fields.length} questions',
                    style: GoogleFonts.poppins(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  if (form.closeDate != null) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.schedule_outlined,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Ferme le ${_formatDate(form.closeDate!)}',
                      style: GoogleFonts.poppins(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
              
              if (form.hasSubmissionLimit) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Limité à ${form.submissionLimit} réponses',
                      style: GoogleFonts.poppins(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
              
              const SizedBox(height: 20),
              
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: canSubmit ? () => _fillForm(form) : null,
                  icon: Icon(
                    canSubmit ? Icons.edit_outlined : Icons.lock_outline,
                    size: 18,
                  ),
                  label: Text(
                    canSubmit
                        ? hasSubmitted ? 'Remplir à nouveau' : 'Remplir le formulaire'
                        : isOpen ? 'Déjà rempli' : 'Formulaire fermé',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: canSubmit 
                        ? _getFormColor(form.accessibility) 
                        : colorScheme.surfaceVariant,
                    foregroundColor: canSubmit 
                        ? Colors.white 
                        : colorScheme.onSurfaceVariant,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmissionCard(FormSubmissionModel submission) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = _getSubmissionStatusColor(submission.status);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // View submission details
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Détails de la soumission'),
              content: SizedBox(
                width: 400,
                height: 300,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Date: 15/11/2025', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      const Text('Statut: Soumis', style: TextStyle(color: Colors.green)),
                      const SizedBox(height: 16),
                      const Text('Réponses:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('Question 1: Réponse 1'),
                      const Text('Question 2: Réponse 2'),
                      const Text('Question 3: Réponse 3'),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fermer'),
                ),
              ],
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getSubmissionStatusIcon(submission.status),
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FutureBuilder<String>(
                          future: _getFormTitle(submission.formId),
                          builder: (context, snapshot) {
                            return Text(
                              snapshot.data ?? 'Formulaire ${submission.formId}',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Soumis le ${_formatDateTime(submission.submittedAt)}',
                          style: GoogleFonts.poppins(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getSubmissionStatusLabel(submission.status),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            
            const SizedBox(height: 16),
            
            // Aperçu des réponses
            if (submission.responses.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aperçu des réponses :',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...submission.responses.entries.take(3).map((entry) => 
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.only(top: 8, right: 8),
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${entry.key}: ${_truncateText(entry.value.toString(), 50)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (submission.responses.length > 3)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '... et ${submission.responses.length - 3} autres réponses',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            
            if (submission.isTestSubmission) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.science_outlined,
                      size: 16,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Soumission de test',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getFormColor(String accessibility) {
    switch (accessibility) {
      case 'public':
        return AppTheme.successColor;
      case 'membres':
        return AppTheme.primaryColor;
      case 'groupe':
        return AppTheme.secondaryColor;
      case 'role':
        return AppTheme.tertiaryColor;
      default:
        return AppTheme.textSecondaryColor;
    }
  }

  IconData _getFormIcon(String accessibility) {
    switch (accessibility) {
      case 'public':
        return Icons.public;
      case 'membres':
        return Icons.people;
      case 'groupe':
        return Icons.groups;
      case 'role':
        return Icons.badge;
      default:
        return Icons.assignment;
    }
  }

  Color _getSubmissionStatusColor(String status) {
    switch (status) {
      case 'submitted':
        return AppTheme.primaryColor;
      case 'processed':
        return AppTheme.successColor;
      case 'archived':
        return AppTheme.textSecondaryColor;
      default:
        return AppTheme.textSecondaryColor;
    }
  }

  IconData _getSubmissionStatusIcon(String status) {
    switch (status) {
      case 'submitted':
        return Icons.send;
      case 'processed':
        return Icons.check_circle;
      case 'archived':
        return Icons.archive;
      default:
        return Icons.help_outline;
    }
  }

  String _getSubmissionStatusLabel(String status) {
    switch (status) {
      case 'submitted':
        return 'Soumis';
      case 'processed':
        return 'Traité';
      case 'archived':
        return 'Archivé';
      default:
        return status;
    }
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<String> _getFormTitle(String formId) async {
    try {
      final formDoc = await FormsFirebaseService.getForm(formId);
      return formDoc?.title ?? 'Formulaire $formId';
    } catch (e) {
      return 'Formulaire $formId';
    }
  }
}