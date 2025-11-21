import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/form_model.dart';
import '../services/forms_firebase_service.dart';
import '../widgets/form_card.dart';
import 'form_builder_page.dart';
import 'form_detail_page.dart';
import '../../theme.dart';

class FormsHomePage extends StatefulWidget {
  const FormsHomePage({super.key});

  @override
  State<FormsHomePage> createState() => _FormsHomePageState();
}

class _FormsHomePageState extends State<FormsHomePage>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  String _searchQuery = '';
  String _statusFilter = '';
  String _accessibilityFilter = '';
  
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  late TabController _tabController;
  
  List<FormModel> _selectedForms = [];
  bool _isSelectionMode = false;

  final List<Map<String, String>> _statusFilters = [
    {'value': '', 'label': 'Tous les statuts'},
    {'value': 'brouillon', 'label': 'Brouillons'},
    {'value': 'publie', 'label': 'Publiés'},
    {'value': 'archive', 'label': 'Archivés'},
  ];

  final List<Map<String, String>> _accessibilityFilters = [
    {'value': '', 'label': 'Toutes les visibilités'},
    {'value': 'public', 'label': 'Public'},
    {'value': 'membres', 'label': 'Membres connectés'},
    {'value': 'groupe', 'label': 'Groupes spécifiques'},
    {'value': 'role', 'label': 'Rôles spécifiques'},
  ];

  @override
  void initState() {
    super.initState();
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
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
  }

  void _onStatusFilterChanged(String? status) {
    setState(() => _statusFilter = status ?? '');
  }

  void _onAccessibilityFilterChanged(String? accessibility) {
    setState(() => _accessibilityFilter = accessibility ?? '');
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedForms.clear();
      }
    });
  }

  void _onFormSelected(FormModel form, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedForms.add(form);
      } else {
        _selectedForms.removeWhere((f) => f.id == form.id);
      }
    });
  }

  Future<void> _createNewForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FormBuilderPage(),
      ),
    );
    
    if (result == true) {
      // Form created successfully
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Formulaire créé avec succès'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  Future<void> _createFromTemplate() async {
    try {
      final templates = await FormsFirebaseService.getFormTemplates();
      
      if (!mounted) return;
      
      final selectedTemplate = await showDialog<FormTemplate>(
        context: context,
        builder: (context) => _TemplateSelectionDialog(templates: templates),
      );
      
      if (selectedTemplate != null) {
        if (!mounted) return;
        
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FormBuilderPage(template: selectedTemplate),
          ),
        );
        
        if (result == true) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Formulaire créé à partir du modèle'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des modèles: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _performBulkAction(String action) async {
    switch (action) {
      case 'publish':
        await _publishSelectedForms();
        break;
      case 'archive':
        await _archiveSelectedForms();
        break;
      case 'delete':
        await _showDeleteConfirmation();
        break;
    }
  }

  Future<void> _publishSelectedForms() async {
    try {
      for (final form in _selectedForms) {
        if (form.status != 'publie') {
          final updatedForm = form.copyWith(
            status: 'publie',
            publishDate: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await FormsFirebaseService.updateForm(updatedForm);
        }
      }
      
      setState(() {
        _selectedForms.clear();
        _isSelectionMode = false;
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedForms.length} formulaire(s) publié(s)'),
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
    }
  }

  Future<void> _archiveSelectedForms() async {
    try {
      for (final form in _selectedForms) {
        await FormsFirebaseService.archiveForm(form.id);
      }
      
      setState(() {
        _selectedForms.clear();
        _isSelectionMode = false;
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedForms.length} formulaire(s) archivé(s)'),
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

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer ${_selectedForms.length} formulaire(s) ?\n\n'
          'Cette action supprimera également toutes les soumissions associées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: AppTheme.white100,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        for (final form in _selectedForms) {
          await FormsFirebaseService.deleteForm(form.id);
        }
        
        setState(() {
          _selectedForms.clear();
          _isSelectionMode = false;
        });
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedForms.length} formulaire(s) supprimé(s)'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _copyFormUrl(FormModel form) {
    final url = FormsFirebaseService.generatePublicFormUrl(form.id);
    Clipboard.setData(ClipboardData(text: url));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lien copié dans le presse-papiers'),
        backgroundColor: AppTheme.successColor,
      ),
    );
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
              expandedHeight: 200.0,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Formulaires',
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
              actions: [
                if (_isSelectionMode) ...[
                  IconButton(
                    icon: const Icon(Icons.more_vert_rounded),
                    onPressed: _showBulkActionsMenu,
                    tooltip: 'Actions groupées',
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: _toggleSelectionMode,
                    tooltip: 'Annuler la sélection',
                  ),
                ] else ...[
                  IconButton(
                    icon: const Icon(Icons.checklist_rounded),
                    onPressed: _toggleSelectionMode,
                    tooltip: 'Mode sélection',
                  ),
                ],
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  color: colorScheme.primary,
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color: colorScheme.onPrimary.withOpacity(0.2),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelStyle: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    unselectedLabelStyle: GoogleFonts.poppins(
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                    ),
                    labelColor: colorScheme.onPrimary,
                    unselectedLabelColor: colorScheme.onPrimary.withOpacity(0.7),
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'Tous'),
                      Tab(text: 'Brouillons'),
                      Tab(text: 'Publiés'),
                      Tab(text: 'Archivés'),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: Column(
          children: [
            _buildSearchAndFilters(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildFormsList(''),
                  _buildFormsList('brouillon'),
                  _buildFormsList('publie'),
                  _buildFormsList('archive'),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _isSelectionMode ? null : ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: _showCreateOptions,
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          elevation: 6,
          icon: const Icon(Icons.add_rounded),
          label: Text(
            'Nouveau formulaire',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Barre de recherche moderne
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: GoogleFonts.poppins(fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Rechercher des formulaires...',
                hintStyle: GoogleFonts.poppins(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 16,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
          ),
          // Filtres modernes avec chips
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _statusFilter.isEmpty ? null : _statusFilter,
                      hint: Text(
                        'Statut',
                        style: GoogleFonts.poppins(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                      onChanged: _onStatusFilterChanged,
                      isExpanded: true,
                      icon: Icon(
                        Icons.expand_more_rounded,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      style: GoogleFonts.poppins(
                        color: colorScheme.onSurface,
                        fontSize: 14,
                      ),
                      items: _statusFilters.map((filter) {
                        return DropdownMenuItem<String>(
                          value: filter['value']!.isEmpty ? null : filter['value'],
                          child: Text(filter['label']!),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _accessibilityFilter.isEmpty ? null : _accessibilityFilter,
                      hint: Text(
                        'Visibilité',
                        style: GoogleFonts.poppins(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                      onChanged: _onAccessibilityFilterChanged,
                      isExpanded: true,
                      icon: Icon(
                        Icons.expand_more_rounded,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      style: GoogleFonts.poppins(
                        color: colorScheme.onSurface,
                        fontSize: 14,
                      ),
                      items: _accessibilityFilters.map((filter) {
                        return DropdownMenuItem<String>(
                          value: filter['value']!.isEmpty ? null : filter['value'],
                          child: Text(filter['label']!),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormsList(String statusFilter) {
    return StreamBuilder<List<FormModel>>(
      stream: FormsFirebaseService.getFormsStream(
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        statusFilter: statusFilter.isNotEmpty ? statusFilter : _statusFilter.isNotEmpty ? _statusFilter : null,
        accessibilityFilter: _accessibilityFilter.isNotEmpty ? _accessibilityFilter : null,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppTheme.errorColor,
                ),
                const SizedBox(height: AppTheme.spaceMedium),
                Text(
                  'Erreur lors du chargement des formulaires',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppTheme.spaceSmall),
                Text(
                  snapshot.error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          );
        }

        final forms = snapshot.data ?? [];

        if (forms.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 64,
                  color: AppTheme.textTertiaryColor,
                ),
                const SizedBox(height: AppTheme.spaceMedium),
                Text(
                  'Aucun formulaire trouvé',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceSmall),
                Text(
                  'Commencez par créer votre premier formulaire',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textTertiaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceLarge),
                ElevatedButton.icon(
                  onPressed: _createNewForm,
                  icon: const Icon(Icons.add),
                  label: const Text('Créer un formulaire'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: AppTheme.white100,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
          itemCount: forms.length,
          itemBuilder: (context, index) {
            final form = forms[index];
            return FormCard(
              form: form,
              onTap: () => _onFormTap(form),
              onLongPress: () => _onFormLongPress(form),
              isSelectionMode: _isSelectionMode,
              isSelected: _selectedForms.any((f) => f.id == form.id),
              onSelectionChanged: (isSelected) => _onFormSelected(form, isSelected),
              onCopyUrl: () => _copyFormUrl(form),
            );
          },
        );
      },
    );
  }

  void _onFormTap(FormModel form) {
    if (_isSelectionMode) {
      final isSelected = _selectedForms.any((f) => f.id == form.id);
      _onFormSelected(form, !isSelected);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FormDetailPage(form: form),
        ),
      );
    }
  }

  void _onFormLongPress(FormModel form) {
    if (!_isSelectionMode) {
      _toggleSelectionMode();
      _onFormSelected(form, true);
    }
  }

  void _showCreateOptions() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.only(top: 80),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle indicator
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Créer un formulaire',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choisissez comment vous souhaitez commencer',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Option formulaire vierge
                  _buildCreateOptionCard(
                    colorScheme: colorScheme,
                    icon: Icons.add_circle_outline_rounded,
                    iconColor: colorScheme.primary,
                    title: 'Formulaire vierge',
                    subtitle: 'Commencez avec un formulaire vide et personnalisez-le',
                    onTap: () {
                      Navigator.pop(context);
                      _createNewForm();
                    },
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Option à partir d'un modèle
                  _buildCreateOptionCard(
                    colorScheme: colorScheme,
                    icon: Icons.content_copy_rounded,
                    iconColor: colorScheme.secondary,
                    title: 'À partir d\'un modèle',
                    subtitle: 'Utilisez un modèle prédéfini pour gagner du temps',
                    onTap: () {
                      Navigator.pop(context);
                      _createFromTemplate();
                    },
                  ),
                  
                  // Safe area bottom padding
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCreateOptionCard({
    required ColorScheme colorScheme,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBulkActionsMenu() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.only(top: 60),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle indicator
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${_selectedForms.length}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'formulaire(s) sélectionné(s)',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  _buildBulkActionCard(
                    colorScheme: colorScheme,
                    icon: Icons.publish_rounded,
                    iconColor: AppTheme.successColor,
                    title: 'Publier',
                    subtitle: 'Rendre les formulaires accessibles au public',
                    onTap: () {
                      Navigator.pop(context);
                      _performBulkAction('publish');
                    },
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildBulkActionCard(
                    colorScheme: colorScheme,
                    icon: Icons.archive_rounded,
                    iconColor: AppTheme.warningColor,
                    title: 'Archiver',
                    subtitle: 'Masquer les formulaires sans les supprimer',
                    onTap: () {
                      Navigator.pop(context);
                      _performBulkAction('archive');
                    },
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildBulkActionCard(
                    colorScheme: colorScheme,
                    icon: Icons.delete_rounded,
                    iconColor: AppTheme.errorColor,
                    title: 'Supprimer',
                    subtitle: 'Supprimer définitivement les formulaires',
                    onTap: () {
                      Navigator.pop(context);
                      _performBulkAction('delete');
                    },
                  ),
                  
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBulkActionCard({
    required ColorScheme colorScheme,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TemplateSelectionDialog extends StatelessWidget {
  final List<FormTemplate> templates;

  const _TemplateSelectionDialog({required this.templates});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choisir un modèle'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: ListView.builder(
          itemCount: templates.length,
          itemBuilder: (context, index) {
            final template = templates[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(template.name),
                subtitle: Text(template.description),
                trailing: Chip(
                  label: Text(template.category),
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                ),
                onTap: () => Navigator.of(context).pop(template),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
      ],
    );
  }
}