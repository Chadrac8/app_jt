import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/form_model.dart';
import '../services/forms_firebase_service.dart';
import '../widgets/form_responses_list.dart';
import '../widgets/form_statistics_view.dart';
import 'form_builder_page.dart';
import '../../theme.dart';

class FormDetailPage extends StatefulWidget {
  final FormModel form;

  const FormDetailPage({
    super.key,
    required this.form,
  });

  @override
  State<FormDetailPage> createState() => _FormDetailPageState();
}

class _FormDetailPageState extends State<FormDetailPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  
  FormModel? _currentForm;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentForm = widget.form;
    _tabController = TabController(length: 4, vsync: this);
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  // Helper methods for status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'publie':
        return AppTheme.successColor;
      case 'brouillon':
        return AppTheme.warningColor;
      case 'archive':
        return AppTheme.textSecondaryColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'publie':
        return 'Publié';
      case 'brouillon':
        return 'Brouillon';
      case 'archive':
        return 'Archivé';
      default:
        return status;
    }
  }

  Future<void> _refreshFormData() async {
    setState(() => _isLoading = true);
    try {
      final updatedForm = await FormsFirebaseService.getForm(widget.form.id);
      if (updatedForm != null) {
        setState(() => _currentForm = updatedForm);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du rechargement: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _editForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormBuilderPage(form: _currentForm),
      ),
    );
    
    if (result == true) {
      await _refreshFormData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Formulaire mis à jour avec succès'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  Future<void> _publishForm() async {
    if (_currentForm?.status == 'publie') return;
    
    setState(() => _isLoading = true);
    try {
      final updatedForm = _currentForm!.copyWith(
        status: 'publie',
        publishDate: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await FormsFirebaseService.updateForm(updatedForm);
      setState(() => _currentForm = updatedForm);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Formulaire publié avec succès'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la publication: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _copyFormUrl() {
    final url = FormsFirebaseService.generatePublicFormUrl(_currentForm!.id);
    Clipboard.setData(ClipboardData(text: url));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lien copié dans le presse-papiers'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _handleAction(String action) {
    switch (action) {
      case 'edit':
        _editForm();
        break;
      case 'publish':
        _publishForm();
        break;
      case 'copy_url':
        _copyFormUrl();
        break;
      case 'duplicate':
        _duplicateForm();
        break;
      case 'archive':
        _archiveForm();
        break;
    }
  }

  Future<void> _duplicateForm() async {
    try {
      final duplicatedForm = _currentForm!.copyWith(
        title: '${_currentForm!.title} (Copie)',
        status: 'brouillon',
        updatedAt: DateTime.now(),
        publishDate: null,
      );
      
      await FormsFirebaseService.createForm(duplicatedForm);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Formulaire dupliqué avec succès'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      
      // Navigate to the new form
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FormBuilderPage(
              form: duplicatedForm,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la duplication: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _archiveForm() async {
    try {
      await FormsFirebaseService.archiveForm(_currentForm!.id);
      
      final updatedForm = _currentForm!.copyWith(
        status: 'archive',
        updatedAt: DateTime.now(),
      );
      
      setState(() => _currentForm = updatedForm);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Formulaire archivé avec succès'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'archivage: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    if (_currentForm == null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: Text(
            'Formulaire',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 80,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Formulaire introuvable',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar.large(
              expandedHeight: 280,
              pinned: true,
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  _currentForm!.title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                  ),
                ),
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16, right: 72),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Gradient background
                    Container(
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
                    ),
                    
                    // Decorative elements
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
                    
                    // Status badge
                    Positioned(
                      top: 100,
                      left: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(_currentForm!.status).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getStatusLabel(_currentForm!.status),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    
                    // Form icon
                    Positioned(
                      right: 20,
                      bottom: 80,
                      child: Icon(
                        Icons.assignment_outlined,
                        size: 60,
                        color: colorScheme.onPrimary.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _refreshFormData,
                  tooltip: 'Actualiser',
                ),
                PopupMenuButton<String>(
                  onSelected: _handleAction,
                  icon: const Icon(Icons.more_vert_rounded),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit_rounded, color: colorScheme.primary),
                        title: const Text('Modifier'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    if (_currentForm!.status != 'publie')
                      PopupMenuItem(
                        value: 'publish',
                        child: ListTile(
                          leading: Icon(Icons.publish_rounded, color: AppTheme.successColor),
                          title: const Text('Publier'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    if (_currentForm!.isPublished)
                      PopupMenuItem(
                        value: 'copy_url',
                        child: ListTile(
                          leading: Icon(Icons.link_rounded, color: colorScheme.secondary),
                          title: const Text('Copier le lien'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    PopupMenuItem(
                      value: 'duplicate',
                      child: ListTile(
                        leading: Icon(Icons.content_copy_rounded, color: colorScheme.tertiary),
                        title: const Text('Dupliquer'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'archive',
                      child: ListTile(
                        leading: Icon(Icons.archive_rounded, color: AppTheme.warningColor),
                        title: const Text('Archiver'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: colorScheme.primary,
                  labelColor: colorScheme.primary,
                  unselectedLabelColor: colorScheme.onSurfaceVariant,
                  labelStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(text: 'Aperçu'),
                    Tab(text: 'Réponses'),
                    Tab(text: 'Statistiques'),
                    Tab(text: 'Paramètres'),
                  ],
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildResponsesTab(),
            _buildStatisticsTab(),
            _buildSettingsTab(),
          ],
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: _currentForm!.isPublished ? _copyFormUrl : _publishForm,
          backgroundColor: _currentForm!.isPublished 
              ? theme.colorScheme.secondary 
              : AppTheme.successColor,
          foregroundColor: Colors.white,
          icon: Icon(_currentForm!.isPublished ? Icons.link_rounded : Icons.publish_rounded),
          label: Text(
            _currentForm!.isPublished ? 'Partager' : 'Publier',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Form info card
          Card(
            elevation: 2,
            color: colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Informations générales',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  _buildInfoRow('Titre', _currentForm!.title),
                  if (_currentForm!.description.isNotEmpty)
                    _buildInfoRow('Description', _currentForm!.description),
                  _buildInfoRow('Statut', _getStatusLabel(_currentForm!.status)),
                  _buildInfoRow('Visibilité', _currentForm!.accessibilityLabel),
                  _buildInfoRow('Créé le', _formatDate(_currentForm!.createdAt)),
                  if (_currentForm!.publishDate != null)
                    _buildInfoRow('Publié le', _formatDate(_currentForm!.publishDate!)),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Fields preview card
          Card(
            elevation: 2,
            color: colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.list_alt_rounded,
                        color: colorScheme.secondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Champs du formulaire',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_currentForm!.fields.length}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  ...List.generate(_currentForm!.fields.length, (index) {
                    final field = _currentForm!.fields[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            _getFieldIcon(field.type),
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              field.label,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (field.isRequired)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.errorColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Requis',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.errorColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsesTab() {
    return FormResponsesList(form: _currentForm!);
  }

  Widget _buildStatisticsTab() {
    return FormStatisticsView(form: _currentForm!);
  }

  Widget _buildSettingsTab() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            color: colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.settings_rounded,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Paramètres',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  _buildInfoRow('Mode d\'affichage', _currentForm!.displayMode == 'single_page' ? 'Page unique' : 'Multi-pages'),
                  if (_currentForm!.submissionLimit != null && _currentForm!.submissionLimit! > 0)
                    _buildInfoRow('Limite de soumissions', '${_currentForm!.submissionLimit}'),
                  if (_currentForm!.closeDate != null)
                    _buildInfoRow('Date de fermeture', _formatDate(_currentForm!.closeDate!)),
                  
                  const SizedBox(height: 24),
                  
                  // Actions
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _editForm,
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Modifier le formulaire'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFieldIcon(String type) {
    switch (type.toLowerCase()) {
      case 'text':
        return Icons.text_fields_rounded;
      case 'textarea':
        return Icons.notes_rounded;
      case 'email':
        return Icons.email_rounded;
      case 'phone':
        return Icons.phone_rounded;
      case 'number':
        return Icons.numbers_rounded;
      case 'select':
        return Icons.list_rounded;
      case 'radio':
        return Icons.radio_button_checked_rounded;
      case 'checkbox':
        return Icons.check_box_rounded;
      case 'date':
        return Icons.calendar_today_rounded;
      case 'time':
        return Icons.access_time_rounded;
      case 'file':
        return Icons.attach_file_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}