import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/form_model.dart';
import '../services/forms_firebase_service.dart';
import '../widgets/form_field_editor.dart';
import '../../theme.dart';

class FormBuilderPage extends StatefulWidget {
  final FormModel? form;
  final FormTemplate? template;

  const FormBuilderPage({
    super.key,
    this.form,
    this.template,
  });

  @override
  State<FormBuilderPage> createState() => _FormBuilderPageState();
}

class _FormBuilderPageState extends State<FormBuilderPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _uuid = const Uuid();
  
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late TabController _tabController;
  
  // Mobile responsive variables
  bool _isMobile = false;
  bool _showFieldsPanel = false;
  
  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _confirmationMessageController = TextEditingController();
  
  // Form values
  String? _headerImageUrl;
  String _status = 'brouillon';
  DateTime? _publishDate;
  DateTime? _closeDate;
  int? _submissionLimit;
  String _accessibility = 'public';
  List<String> _accessibilityTargets = [];
  String _displayMode = 'single_page';
  List<CustomFormField> _fields = [];
  FormSettings _settings = FormSettings();
  bool _isLoading = false;
  bool _hasUnsavedChanges = false;

  final List<Map<String, dynamic>> _fieldTypes = [
    {'type': 'text', 'label': 'Texte court', 'icon': Icons.text_fields, 'category': 'Texte'},
    {'type': 'textarea', 'label': 'Texte long', 'icon': Icons.subject, 'category': 'Texte'},
    {'type': 'email', 'label': 'Email', 'icon': Icons.email, 'category': 'Contact'},
    {'type': 'phone', 'label': 'Téléphone', 'icon': Icons.phone, 'category': 'Contact'},
    {'type': 'checkbox', 'label': 'Cases à cocher', 'icon': Icons.check_box, 'category': 'Choix'},
    {'type': 'radio', 'label': 'Boutons radio', 'icon': Icons.radio_button_checked, 'category': 'Choix'},
    {'type': 'select', 'label': 'Liste déroulante', 'icon': Icons.arrow_drop_down, 'category': 'Choix'},
    {'type': 'date', 'label': 'Date', 'icon': Icons.calendar_today, 'category': 'Date/Heure'},
    {'type': 'time', 'label': 'Heure', 'icon': Icons.access_time, 'category': 'Date/Heure'},
    {'type': 'file', 'label': 'Fichier', 'icon': Icons.attach_file, 'category': 'Média'},
    {'type': 'signature', 'label': 'Signature', 'icon': Icons.edit, 'category': 'Média'},
    {'type': 'section', 'label': 'Section', 'icon': Icons.view_headline, 'category': 'Mise en forme'},
    {'type': 'title', 'label': 'Titre', 'icon': Icons.title, 'category': 'Mise en forme'},
    {'type': 'instructions', 'label': 'Instructions', 'icon': Icons.info, 'category': 'Mise en forme'},
    {'type': 'person_field', 'label': 'Champ personne', 'icon': Icons.person, 'category': 'Données'},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _tabController = TabController(length: 2, vsync: this);
    
    _initializeForm();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _confirmationMessageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    if (widget.form != null) {
      // Editing existing form
      final form = widget.form!;
      _titleController.text = form.title;
      _descriptionController.text = form.description;
      _headerImageUrl = form.headerImageUrl;
      _status = form.status;
      _publishDate = form.publishDate;
      _closeDate = form.closeDate;
      _submissionLimit = form.submissionLimit;
      _accessibility = form.accessibility;
      _accessibilityTargets = List.from(form.accessibilityTargets);
      _displayMode = form.displayMode;
      _fields = List.from(form.fields);
      _settings = form.settings;
      _confirmationMessageController.text = _settings.confirmationMessage;
    } else if (widget.template != null) {
      // Creating from template
      final template = widget.template!;
      _titleController.text = template.name;
      _descriptionController.text = template.description;
      _fields = List.from(template.fields);
      _settings = template.defaultSettings;
      _confirmationMessageController.text = _settings.confirmationMessage;
    } else {
      // New form with default values
      _confirmationMessageController.text = _settings.confirmationMessage;
    }
  }

  void _markAsChanged() {
    setState(() => _hasUnsavedChanges = true);
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final settings = FormSettings(
        confirmationMessage: _confirmationMessageController.text,
        redirectUrl: _settings.redirectUrl,
        sendConfirmationEmail: _settings.sendConfirmationEmail,
        confirmationEmailTemplate: _settings.confirmationEmailTemplate,
        notificationEmails: _settings.notificationEmails,
        autoAddToGroup: _settings.autoAddToGroup,
        targetGroupId: _settings.targetGroupId,
        autoAddToWorkflow: _settings.autoAddToWorkflow,
        targetWorkflowId: _settings.targetWorkflowId,
        allowMultipleSubmissions: _settings.allowMultipleSubmissions,
        showProgressBar: _settings.showProgressBar,
        enableTestMode: _settings.enableTestMode,
        postSubmissionActions: _settings.postSubmissionActions,
      );

      if (widget.form != null) {
        // Update existing form
        final updatedForm = widget.form!.copyWith(
          title: _titleController.text,
          description: _descriptionController.text,
          headerImageUrl: _headerImageUrl,
          status: _status,
          publishDate: _publishDate,
          closeDate: _closeDate,
          submissionLimit: _submissionLimit,
          accessibility: _accessibility,
          accessibilityTargets: _accessibilityTargets,
          displayMode: _displayMode,
          fields: _fields,
          settings: settings,
          updatedAt: DateTime.now(),
        );
        
        await FormsFirebaseService.updateForm(updatedForm);
      } else {
        // Create new form
        final newForm = FormModel(
          id: '',
          title: _titleController.text,
          description: _descriptionController.text,
          headerImageUrl: _headerImageUrl,
          status: _status,
          publishDate: _publishDate,
          closeDate: _closeDate,
          submissionLimit: _submissionLimit,
          accessibility: _accessibility,
          accessibilityTargets: _accessibilityTargets,
          displayMode: _displayMode,
          fields: _fields,
          settings: settings,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        await FormsFirebaseService.createForm(newForm);
      }

      setState(() => _hasUnsavedChanges = false);
      
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sauvegarde: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addField(Map<String, dynamic> fieldData) {
    final newField = CustomFormField(
      id: _uuid.v4(),
      type: fieldData['type'],
      label: fieldData['label'],
      order: _fields.length,
    );
    
    setState(() {
      _fields.add(newField);
      _markAsChanged();
    });
  }

  void _editField(CustomFormField field) {
    showDialog(
      context: context,
      builder: (context) => FormFieldEditor(
        field: field,
        onSave: (updatedField) {
          setState(() {
            final index = _fields.indexWhere((f) => f.id == field.id);
            if (index != -1) {
              _fields[index] = updatedField;
              _markAsChanged();
            }
          });
        },
      ),
    );
  }

  void _deleteField(CustomFormField field) {
    setState(() {
      _fields.removeWhere((f) => f.id == field.id);
      // Reorder remaining fields
      for (int i = 0; i < _fields.length; i++) {
        _fields[i] = _fields[i].copyWith(order: i);
      }
      _markAsChanged();
    });
  }

  void _reorderFields(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final field = _fields.removeAt(oldIndex);
      _fields.insert(newIndex, field);
      
      // Update order for all fields
      for (int i = 0; i < _fields.length; i++) {
        _fields[i] = _fields[i].copyWith(order: i);
      }
      _markAsChanged();
    });
  }

  void _previewForm() {
    // Create a preview version of the form
    final previewSettings = FormSettings(
      confirmationMessage: _confirmationMessageController.text.isEmpty 
          ? 'Merci pour votre soumission !' 
          : _confirmationMessageController.text,
      sendConfirmationEmail: _settings.sendConfirmationEmail,
      notificationEmails: _settings.notificationEmails,
      allowMultipleSubmissions: _settings.allowMultipleSubmissions,
      showProgressBar: _settings.showProgressBar,
      enableTestMode: true, // Always enable test mode for preview
      autoAddToGroup: _settings.autoAddToGroup,
      targetGroupId: _settings.targetGroupId,
      autoAddToWorkflow: _settings.autoAddToWorkflow,
      targetWorkflowId: _settings.targetWorkflowId,
      postSubmissionActions: _settings.postSubmissionActions,
    );

    final previewForm = FormModel(
      id: 'preview',
      title: _titleController.text.isEmpty ? 'Titre du formulaire' : _titleController.text,
      description: _descriptionController.text,
      headerImageUrl: _headerImageUrl,
      fields: _fields,
      status: 'preview',
      accessibility: _accessibility,
      accessibilityTargets: _accessibilityTargets,
      displayMode: _displayMode,
      settings: previewSettings,
      publishDate: _publishDate,
      closeDate: _closeDate,
      submissionLimit: _submissionLimit,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: 'preview',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FormPreviewPage(form: previewForm),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    _isMobile = screenWidth < 768;
    
    return WillPopScope(
      onWillPop: () async {
        if (_hasUnsavedChanges) {
          return await _showUnsavedChangesDialog();
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: Text(
            widget.form != null ? 'Modifier le formulaire' : 'Nouveau formulaire',
            style: const TextStyle(fontSize: 18),
          ),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: AppTheme.white100,
          elevation: 0,
          actions: [
            if (!_isMobile) ...[
              IconButton(
                icon: const Icon(Icons.preview),
                onPressed: _previewForm,
                tooltip: 'Aperçu',
              ),
            ],
            if (_isMobile) ...[
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'preview':
                      _previewForm();
                      break;
                    case 'fields':
                      setState(() => _showFieldsPanel = !_showFieldsPanel);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'preview',
                    child: ListTile(
                      leading: Icon(Icons.preview),
                      title: Text('Aperçu'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'fields',
                    child: ListTile(
                      leading: Icon(Icons.widgets),
                      title: Text('Types de champs'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
            if (_hasUnsavedChanges)
              Container(
                margin: const EdgeInsets.only(right: 16),
                child: const Icon(
                  Icons.circle,
                  color: AppTheme.warningColor,
                  size: 8,
                ),
              ),
          ],
          bottom: _isMobile ? TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.white100,
            labelColor: AppTheme.white100,
            unselectedLabelColor: AppTheme.white100.withOpacity(0.7),
            tabs: const [
              Tab(
                icon: Icon(Icons.settings),
                text: 'Paramètres',
              ),
              Tab(
                icon: Icon(Icons.list),
                text: 'Champs',
              ),
            ],
          ) : null,
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.3),
              end: Offset.zero,
            ).animate(_slideAnimation),
            child: _buildBody(),
          ),
        ),
        floatingActionButton: _isMobile 
            ? FloatingActionButton(
                onPressed: _isLoading ? null : _saveForm,
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: AppTheme.white100,
                child: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white100),
                        ),
                      )
                    : const Icon(Icons.save),
              )
            : FloatingActionButton.extended(
                onPressed: _isLoading ? null : _saveForm,
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: AppTheme.white100,
                icon: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white100),
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_isLoading ? 'Sauvegarde...' : 'Sauvegarder'),
              ),
        floatingActionButtonLocation: _isMobile 
            ? FloatingActionButtonLocation.centerFloat
            : FloatingActionButtonLocation.endFloat,
        // Bottom sheet pour les types de champs sur mobile
        bottomSheet: _isMobile && _showFieldsPanel ? _buildMobileFieldsPanel() : null,
      ),
    );
  }

  Widget _buildBody() {
    if (_isMobile) {
      return TabBarView(
        controller: _tabController,
        children: [
          _buildMobileFormSettings(),
          _buildMobileFieldsList(),
        ],
      );
    } else {
      return Row(
        children: [
          // Form builder
          Expanded(
            flex: 2,
            child: _buildFormBuilder(),
          ),
          
          // Field types panel
          Container(
            width: 300,
            decoration: const BoxDecoration(
              color: AppTheme.white100,
              border: Border(left: BorderSide(color: AppTheme.grey500, width: 0.5)),
            ),
            child: _buildFieldTypesPanel(),
          ),
        ],
      );
    }
  }

  Widget _buildFormBuilder() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppTheme.spaceLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFormSettings(),
            const SizedBox(height: AppTheme.spaceXLarge),
            _buildFieldsList(),
            const SizedBox(height: 100), // Space for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildFormSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paramètres du formulaire',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: AppTheme.fontBold,
              ),
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            
            // Title and description
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titre du formulaire *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Le titre est obligatoire';
                }
                return null;
              },
              onChanged: (_) => _markAsChanged(),
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (_) => _markAsChanged(),
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            
            // Status and accessibility - Responsive layout
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 600) {
                  // Mobile: Stack vertically
                  return Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _status,
                        decoration: const InputDecoration(
                          labelText: 'Statut',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'brouillon', child: Text('Brouillon')),
                          DropdownMenuItem(value: 'publie', child: Text('Publié')),
                          DropdownMenuItem(value: 'archive', child: Text('Archivé')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _status = value!;
                            _markAsChanged();
                          });
                        },
                      ),
                      const SizedBox(height: AppTheme.spaceMedium),
                      DropdownButtonFormField<String>(
                        initialValue: _accessibility,
                        decoration: const InputDecoration(
                          labelText: 'Accessibilité',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'public', child: Text('Public')),
                          DropdownMenuItem(value: 'membres', child: Text('Membres connectés')),
                          DropdownMenuItem(value: 'groupe', child: Text('Groupes spécifiques')),
                          DropdownMenuItem(value: 'role', child: Text('Rôles spécifiques')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _accessibility = value!;
                            _markAsChanged();
                          });
                        },
                      ),
                    ],
                  );
                } else {
                  // Desktop: Side by side
                  return Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _status,
                          decoration: const InputDecoration(
                            labelText: 'Statut',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'brouillon', child: Text('Brouillon')),
                            DropdownMenuItem(value: 'publie', child: Text('Publié')),
                            DropdownMenuItem(value: 'archive', child: Text('Archivé')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _status = value!;
                              _markAsChanged();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceMedium),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _accessibility,
                          decoration: const InputDecoration(
                            labelText: 'Accessibilité',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'public', child: Text('Public')),
                            DropdownMenuItem(value: 'membres', child: Text('Membres connectés')),
                            DropdownMenuItem(value: 'groupe', child: Text('Groupes spécifiques')),
                            DropdownMenuItem(value: 'role', child: Text('Rôles spécifiques')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _accessibility = value!;
                              _markAsChanged();
                            });
                          },
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            
            // Advanced settings
            ExpansionTile(
              title: const Text('Paramètres avancés'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spaceMedium),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _confirmationMessageController,
                        decoration: const InputDecoration(
                          labelText: 'Message de confirmation',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                        onChanged: (_) => _markAsChanged(),
                      ),
                      const SizedBox(height: AppTheme.spaceMedium),
                      TextFormField(
                        initialValue: _submissionLimit?.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Limite de soumissions',
                          border: OutlineInputBorder(),
                          hintText: 'Laisser vide pour aucune limite',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _submissionLimit = int.tryParse(value);
                          _markAsChanged();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldsList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Champs du formulaire',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: AppTheme.fontBold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_fields.length} champ${_fields.length > 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            
            if (_fields.isEmpty)
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceXLarge),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(
                    color: AppTheme.textTertiaryColor.withOpacity(0.3),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.quiz_outlined,
                      size: 48,
                      color: AppTheme.textTertiaryColor,
                    ),
                    const SizedBox(height: AppTheme.spaceMedium),
                    Text(
                      'Aucun champ ajouté',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceSmall),
                    Text(
                      'Glissez-déposez des champs depuis le panneau de droite',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textTertiaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                onReorder: _reorderFields,
                itemCount: _fields.length,
                itemBuilder: (context, index) {
                  final field = _fields[index];
                  return _buildFieldCard(field, index);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldCard(CustomFormField field, int index) {
    return Card(
      key: ValueKey(field.id),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          _getFieldIcon(field.type),
          color: AppTheme.primaryColor,
        ),
        title: Text(field.label.isNotEmpty ? field.label : field.typeLabel),
        subtitle: Text('${field.typeLabel}${field.isRequired ? ' • Obligatoire' : ''}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editField(field),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: AppTheme.errorColor),
              onPressed: () => _deleteField(field),
            ),
            const Icon(Icons.drag_handle),
          ],
        ),
        onTap: () => _editField(field),
      ),
    );
  }

  Widget _buildFieldTypesPanel() {
    final groupedFields = <String, List<Map<String, dynamic>>>{};
    for (final fieldType in _fieldTypes) {
      final category = fieldType['category'] as String;
      if (!groupedFields.containsKey(category)) {
        groupedFields[category] = [];
      }
      groupedFields[category]!.add(fieldType);
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
          decoration: const BoxDecoration(
            color: AppTheme.primaryColor,
          ),
          child: Row(
            children: [
              const Icon(Icons.widgets, color: AppTheme.white100),
              const SizedBox(width: AppTheme.spaceSmall),
              Text(
                'Types de champs',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.white100,
                  fontWeight: AppTheme.fontBold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            children: groupedFields.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      entry.key,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: AppTheme.fontBold,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ),
                  ...entry.value.map((fieldType) => _buildFieldTypeCard(fieldType)),
                  const SizedBox(height: AppTheme.spaceMedium),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldTypeCard(Map<String, dynamic> fieldType) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppTheme.white100,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        child: InkWell(
          onTap: () => _addField(fieldType),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          child: Container(
            padding: const EdgeInsets.all(AppTheme.space12),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.grey500),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Row(
              children: [
                Icon(
                  fieldType['icon'] as IconData,
                  size: 20,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: AppTheme.space12),
                Expanded(
                  child: Text(
                    fieldType['label'] as String,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const Icon(
                  Icons.add,
                  size: 16,
                  color: AppTheme.textTertiaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getFieldIcon(String type) {
    final fieldType = _fieldTypes.firstWhere(
      (ft) => ft['type'] == type,
      orElse: () => {'icon': Icons.help_outline},
    );
    return fieldType['icon'] as IconData;
  }

  Future<bool> _showUnsavedChangesDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifications non sauvegardées'),
        content: const Text(
          'Vous avez des modifications non sauvegardées. '
          'Voulez-vous quitter sans sauvegarder ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Quitter'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(false);
              _saveForm();
            },
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    ) ?? false;
  }

  // Méthodes pour l'interface mobile
  Widget _buildMobileFormSettings() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFormSettings(),
            const SizedBox(height: 100), // Space for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildMobileFieldsList() {
    return Column(
      children: [
        // Bouton pour ajouter des champs
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            border: const Border(
              bottom: BorderSide(color: AppTheme.grey300),
            ),
          ),
          child: ElevatedButton.icon(
            onPressed: () => _showMobileFieldTypesBottomSheet(),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un champ'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: AppTheme.white100,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        
        // Liste des champs
        Expanded(
          child: _fields.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.list_alt,
                        size: 64,
                        color: AppTheme.grey400,
                      ),
                      const SizedBox(height: AppTheme.spaceMedium),
                      Text(
                        'Aucun champ ajouté',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceSmall),
                      Text(
                        'Ajoutez des champs pour commencer à construire votre formulaire',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                )
              : ReorderableListView(
                  padding: const EdgeInsets.all(AppTheme.spaceMedium),
                  onReorder: _reorderFields,
                  children: _fields.map((field) {
                    return _buildMobileFieldCard(field);
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildMobileFieldCard(CustomFormField field) {
    return Card(
      key: ValueKey(field.id),
      margin: const EdgeInsets.only(bottom: AppTheme.spaceMedium),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: Icon(
            _getFieldIcon(field.type),
            color: AppTheme.primaryColor,
            size: 20,
          ),
        ),
        title: Text(
          field.label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          _getFieldTypeLabel(field.type),
          style: TextStyle(
            color: AppTheme.textSecondaryColor,
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _editField(field),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              onPressed: () => _showDeleteFieldDialog(field),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
          ],
        ),
        onTap: () => _editField(field),
      ),
    );
  }

  void _showMobileFieldTypesBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppTheme.white100,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppTheme.radiusLarge),
              topRight: Radius.circular(AppTheme.radiusLarge),
            ),
          ),
          child: Column(
            children: [
              // Poignée
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // En-tête
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
                child: Row(
                  children: [
                    const Icon(Icons.widgets, color: AppTheme.primaryColor),
                    const SizedBox(width: AppTheme.spaceSmall),
                    Text(
                      'Types de champs',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: AppTheme.fontBold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              
              const Divider(),
              
              // Liste des types de champs
              Expanded(
                child: _buildMobileFieldTypesList(scrollController),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileFieldTypesList(ScrollController scrollController) {
    final groupedFields = <String, List<Map<String, dynamic>>>{};
    for (final fieldType in _fieldTypes) {
      final category = fieldType['category'] as String;
      if (!groupedFields.containsKey(category)) {
        groupedFields[category] = [];
      }
      groupedFields[category]!.add(fieldType);
    }

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      children: groupedFields.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                entry.key,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: AppTheme.fontBold,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ),
            ...entry.value.map((fieldType) => _buildMobileFieldTypeCard(fieldType)),
            const SizedBox(height: AppTheme.spaceMedium),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildMobileFieldTypeCard(Map<String, dynamic> fieldType) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppTheme.white100,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        elevation: 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          onTap: () {
            Navigator.pop(context);
            _addField(fieldType);
          },
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Icon(
                    fieldType['icon'] as IconData,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMedium),
                Expanded(
                  child: Text(
                    fieldType['label'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(
                  Icons.add_circle_outline,
                  color: AppTheme.primaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileFieldsPanel() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: AppTheme.white100,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radiusLarge),
          topRight: Radius.circular(AppTheme.radiusLarge),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Poignée et en-tête
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceMedium),
                Row(
                  children: [
                    const Icon(Icons.widgets, color: AppTheme.primaryColor),
                    const SizedBox(width: AppTheme.spaceSmall),
                    Text(
                      'Types de champs',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: AppTheme.fontBold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => setState(() => _showFieldsPanel = false),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const Divider(),
          
          // Liste des types de champs
          Expanded(
            child: _buildMobileFieldTypesList(ScrollController()),
          ),
        ],
      ),
    );
  }

  String _getFieldTypeLabel(String type) {
    final fieldType = _fieldTypes.firstWhere(
      (field) => field['type'] == type,
      orElse: () => {'label': 'Inconnu'},
    );
    return fieldType['label'] as String;
  }

  void _showDeleteFieldDialog(CustomFormField field) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le champ'),
        content: Text('Êtes-vous sûr de vouloir supprimer le champ "${field.label}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteField(field);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

// Widget de prévisualisation du formulaire
class _FormPreviewPage extends StatefulWidget {
  final FormModel form;

  const _FormPreviewPage({required this.form});

  @override
  State<_FormPreviewPage> createState() => _FormPreviewPageState();
}

class _FormPreviewPageState extends State<_FormPreviewPage> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _formData = {};
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _initializeControllers() {
    for (final field in widget.form.fields) {
      if (['text', 'email', 'phone', 'number', 'textarea'].contains(field.type)) {
        _controllers[field.id] = TextEditingController();
        _focusNodes[field.id] = FocusNode();
      }
    }
  }

  void _submitPreview() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    
    // Simulate form submission delay
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      setState(() => _isSubmitting = false);
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 50,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Aperçu envoyé !',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.form.settings.confirmationMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '(Ceci est un aperçu - aucune donnée n\'a été sauvegardée)',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.orange[700],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close preview
            },
            child: const Text('Fermer l\'aperçu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Aperçu - ${widget.form.title}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.preview,
                  size: 16,
                  color: Colors.orange[700],
                ),
                const SizedBox(width: 4),
                Text(
                  'APERÇU',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec image si présente
              if (widget.form.headerImageUrl != null) ...[
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(widget.form.headerImageUrl!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Titre du formulaire
              Text(
                widget.form.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              
              // Description
              if (widget.form.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  widget.form.description,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
              
              const SizedBox(height: 32),

              // Champs du formulaire
              ...widget.form.fields.asMap().entries.map((entry) {
                final index = entry.key;
                final field = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _buildPreviewField(field, index),
                );
              }),

              const SizedBox(height: 32),

              // Bouton de soumission
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitPreview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Envoyer',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Note d'aperçu
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue[700],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ceci est un aperçu de votre formulaire. Aucune donnée ne sera sauvegardée lors de la soumission.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[700],
                        ),
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

  Widget _buildPreviewField(CustomFormField field, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label du champ
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: field.label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              if (field.isRequired)
                TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
        
        if (field.helpText != null && field.helpText!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            field.helpText!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        
        const SizedBox(height: 8),
        
        // Widget du champ selon le type
        _buildFieldWidget(field),
      ],
    );
  }

  Widget _buildFieldWidget(CustomFormField field) {
    final colorScheme = Theme.of(context).colorScheme;
    
    switch (field.type) {
      case 'text':
      case 'email':
      case 'phone':
      case 'number':
        return TextFormField(
          controller: _controllers[field.id],
          focusNode: _focusNodes[field.id],
          keyboardType: _getKeyboardType(field.type),
          decoration: InputDecoration(
            hintText: field.placeholder,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            filled: true,
            fillColor: colorScheme.surface,
          ),
          validator: (value) {
            if (field.isRequired && (value == null || value.isEmpty)) {
              return 'Ce champ est requis';
            }
            if (field.type == 'email' && value != null && value.isNotEmpty) {
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Veuillez entrer un email valide';
              }
            }
            return null;
          },
          onChanged: (value) => _formData[field.id] = value,
        );
        
      case 'textarea':
        return TextFormField(
          controller: _controllers[field.id],
          focusNode: _focusNodes[field.id],
          maxLines: 4,
          decoration: InputDecoration(
            hintText: field.placeholder,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            filled: true,
            fillColor: colorScheme.surface,
          ),
          validator: (value) {
            if (field.isRequired && (value == null || value.isEmpty)) {
              return 'Ce champ est requis';
            }
            return null;
          },
          onChanged: (value) => _formData[field.id] = value,
        );
        
      case 'select':
        return DropdownButtonFormField<String>(
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            filled: true,
            fillColor: colorScheme.surface,
          ),
          hint: Text(field.placeholder ?? 'Sélectionner...'),
          items: field.options.map((option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(option),
            );
          }).toList(),
          validator: (value) {
            if (field.isRequired && value == null) {
              return 'Veuillez sélectionner une option';
            }
            return null;
          },
          onChanged: (value) => _formData[field.id] = value,
        );
        
      case 'radio':
        return Column(
          children: field.options.map((option) {
            return RadioListTile<String>(
              title: Text(option),
              value: option,
              groupValue: _formData[field.id],
              onChanged: (value) {
                setState(() => _formData[field.id] = value);
              },
              contentPadding: EdgeInsets.zero,
            );
          }).toList(),
        );
        
      case 'checkbox':
        return Column(
          children: field.options.map((option) {
            final List<String> selectedValues = List<String>.from(_formData[field.id] ?? []);
            return CheckboxListTile(
              title: Text(option),
              value: selectedValues.contains(option),
              onChanged: (checked) {
                setState(() {
                  if (checked == true) {
                    selectedValues.add(option);
                  } else {
                    selectedValues.remove(option);
                  }
                  _formData[field.id] = selectedValues;
                });
              },
              contentPadding: EdgeInsets.zero,
            );
          }).toList(),
        );
        
      case 'date':
        return TextFormField(
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'Sélectionner une date',
            suffixIcon: const Icon(Icons.calendar_today),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            filled: true,
            fillColor: colorScheme.surface,
          ),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (date != null) {
              setState(() => _formData[field.id] = date.toIso8601String());
            }
          },
          validator: (value) {
            if (field.isRequired && _formData[field.id] == null) {
              return 'Veuillez sélectionner une date';
            }
            return null;
          },
        );
        
      default:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Type de champ non supporté: ${field.type}',
            style: TextStyle(color: colorScheme.onErrorContainer),
          ),
        );
    }
  }

  TextInputType _getKeyboardType(String fieldType) {
    switch (fieldType) {
      case 'email':
        return TextInputType.emailAddress;
      case 'phone':
        return TextInputType.phone;
      case 'number':
        return TextInputType.number;
      default:
        return TextInputType.text;
    }
  }
}