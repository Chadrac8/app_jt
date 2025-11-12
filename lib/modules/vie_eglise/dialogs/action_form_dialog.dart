import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme.dart';
import '../models/pour_vous_action.dart';
import '../models/action_group.dart';
import '../services/pour_vous_action_service.dart';
import '../services/action_group_service.dart';
import '../../../../models/form_model.dart';
import '../../../../services/forms_firebase_service.dart';

class ActionFormDialog extends StatefulWidget {
  final PourVousAction? action;
  final bool isDuplicate;

  const ActionFormDialog({
    Key? key,
    this.action,
    this.isDuplicate = false,
  }) : super(key: key);

  @override
  State<ActionFormDialog> createState() => _ActionFormDialogState();
}

class _ActionFormDialogState extends State<ActionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final PourVousActionService _actionService = PourVousActionService();
  final ActionGroupService _groupService = ActionGroupService();

  String _selectedActionType = 'navigate_page';
  String? _selectedGroupId;
  String? _selectedTargetModule;
  String? _selectedTargetRoute;
  String? _selectedCustomActionType;
  String? _selectedFormId;
  String _selectedTargetType = 'form'; // 'form' ou 'special_song'
  IconData _selectedIcon = Icons.help_outline;
  Color _selectedColor = AppTheme.primaryColor;
  bool _isActive = true;
  int _order = 0;
  bool _isLoading = false;
  List<ActionGroup> _groups = [];
  List<FormModel> _availableForms = [];
  
  final TextEditingController _urlController = TextEditingController();

  final List<String> _actionTypes = [
    'navigate_page',
    'navigate_module', 
    'external_url',
    'action_custom',
    'target_module',
  ];

  final List<String> _targetModules = [
    'bible',
    'vie_eglise',
    'songs',
    'pour_vous',
    'profile',
    'settings',
  ];

  final List<String> _customActionTypes = [
    'baptism_request',
    'team_join',
    'appointment_request', 
    'question_ask',
    'special_song',
    'testimony_share',
    'idea_suggest',
    'issue_report',
  ];

  final Map<String, List<String>> _moduleRoutes = {
    'bible': ['/bible', '/bible/search', '/bible/favorites'],
    'vie_eglise': ['/vie_eglise', '/vie_eglise/sermons', '/vie_eglise/prayers'],
    'songs': ['/songs', '/songs/favorites', '/songs/setlists'],
    'pour_vous': ['/pour_vous', '/pour_vous/baptism', '/pour_vous/contact'],
    'profile': ['/profile', '/profile/edit'],
    'settings': ['/settings', '/settings/notifications'],
  };

  final List<IconData> _availableIcons = [
    Icons.church,
    Icons.water_drop,
    Icons.volunteer_activism,
    Icons.contact_phone,
    Icons.email,
    Icons.calendar_month,
    Icons.group,
    Icons.favorite,
    Icons.star,
    Icons.info,
    Icons.help,
    Icons.settings,
    Icons.notifications,
    Icons.home,
    Icons.person,
    Icons.chat,
    Icons.library_books,
    Icons.music_note,
    Icons.event,
    Icons.location_on,
    Icons.share,
  ];

  final List<Color> _availableColors = [
    AppTheme.primaryColor,
    AppTheme.secondaryColor,
    AppTheme.successColor,
    AppTheme.warningColor,
    AppTheme.errorColor,
    AppTheme.primaryColor,
    AppTheme.orangeStandard,
    AppTheme.secondaryColor,
    AppTheme.secondaryColor,
    AppTheme.pinkStandard,
  ];

  @override
  void initState() {
    super.initState();
    _loadGroups();
    _initializeForm();
  }

  void _loadGroups() async {
    final groups = await _groupService.getAllGroups().first;
    setState(() {
      _groups = groups;
    });
    _loadForms();
  }

  void _loadForms() async {
    try {
      final forms = await FormsFirebaseService.getFormsStream(
        statusFilter: 'publie',
        limit: 100,
      ).first;
      setState(() {
        _availableForms = forms;
      });
    } catch (e) {
      print('Erreur lors du chargement des formulaires: $e');
    }
  }

  void _initializeForm() {
    if (widget.action != null) {
      final action = widget.action!;
      _titleController.text = widget.isDuplicate ? '${action.title} (Copie)' : action.title;
      _descriptionController.text = action.description;
      _selectedActionType = action.actionType;
      _selectedGroupId = action.groupId;
      _selectedTargetModule = action.targetModule;
      _selectedTargetRoute = action.targetRoute;
      _selectedIcon = action.icon;
      _isActive = widget.isDuplicate ? true : action.isActive;
      _order = widget.isDuplicate ? 0 : action.order;
      
      // Initialiser les champs spécifiques selon le type d'action
      if (action.actionType == 'external_url') {
        _urlController.text = action.targetRoute ?? '';
      } else if (action.actionType == 'action_custom' && action.actionData != null) {
        _selectedCustomActionType = action.actionData!['type'] as String?;
      } else if (action.actionType == 'target_module' && action.actionData != null) {
        _selectedTargetType = action.actionData!['targetType'] as String? ?? 'form';
        _selectedFormId = action.actionData!['formId'] as String?;
      }
      
      if (action.color != null) {
        try {
          _selectedColor = Color(int.parse(action.color!.replaceFirst('#', '0xFF')));
        } catch (e) {
          _selectedColor = AppTheme.primaryColor;
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenSize = MediaQuery.of(context).size;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: screenSize.width * 0.95,
          maxHeight: screenSize.height * 0.9,
          minHeight: 600,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
          child: Column(
            children: [
              // Header moderne avec couleur dégradée
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceLarge),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.space12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      child: Icon(
                        widget.isDuplicate 
                            ? Icons.content_copy_rounded
                            : widget.action == null 
                                ? Icons.add_rounded
                                : Icons.edit_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isDuplicate 
                                ? 'Dupliquer l\'action'
                                : widget.action == null 
                                    ? 'Nouvelle action'
                                    : 'Modifier l\'action',
                            style: GoogleFonts.poppins(
                              fontSize: AppTheme.fontSize20,
                              fontWeight: AppTheme.fontBold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Configurez les détails de votre action',
                            style: GoogleFonts.poppins(
                              fontSize: AppTheme.fontSize14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            
              // Contenu avec scroll
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppTheme.spaceLarge),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBasicInfoSection(),
                        const SizedBox(height: AppTheme.spaceLarge),
                        _buildAppearanceSection(),
                        const SizedBox(height: AppTheme.spaceLarge),
                        _buildActionConfigSection(),
                        const SizedBox(height: AppTheme.spaceLarge),
                        _buildAdvancedSection(),
                      ],
                    ),
                  ),
                ),
              ),
            
              // Footer avec boutons
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceLarge),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.3),
                  border: Border(
                    top: BorderSide(
                      color: colorScheme.outline.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Bouton annuler
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.onSurface,
                          side: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.close_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Annuler',
                              style: GoogleFonts.poppins(
                                fontWeight: AppTheme.fontMedium,
                                fontSize: AppTheme.fontSize14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: AppTheme.spaceMedium),
                    
                    // Bouton sauvegarder
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _saveAction,
                        style: FilledButton.styleFrom(
                          backgroundColor: _isLoading ? colorScheme.outline.withOpacity(0.3) : AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                          elevation: _isLoading ? 0 : 2,
                        ),
                        child: _isLoading
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Sauvegarde...',
                                    style: GoogleFonts.poppins(
                                      fontWeight: AppTheme.fontMedium,
                                      fontSize: AppTheme.fontSize14,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    widget.action == null || widget.isDuplicate 
                                        ? Icons.add_rounded 
                                        : Icons.save_rounded,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.action == null || widget.isDuplicate ? 'Créer l\'action' : 'Sauvegarder',
                                    style: GoogleFonts.poppins(
                                      fontWeight: AppTheme.fontSemiBold,
                                      fontSize: AppTheme.fontSize14,
                                    ),
                                  ),
                                ],
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

  Widget _buildBasicInfoSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      elevation: 0,
      color: colorScheme.surfaceVariant.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppTheme.space12),
                Text(
                  'Informations générales',
                  style: GoogleFonts.poppins(
                    fontSize: AppTheme.fontSize16,
                    fontWeight: AppTheme.fontSemiBold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            
            // Titre
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Titre de l\'action *',
                hintText: 'Ex: Demande de baptême',
                prefixIcon: Icon(Icons.title_rounded, color: AppTheme.primaryColor),
                filled: true,
                fillColor: colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: BorderSide(color: colorScheme.error, width: 2),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: BorderSide(color: colorScheme.error, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              style: GoogleFonts.poppins(fontSize: AppTheme.fontSize14),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le titre est requis';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            
            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description *',
                hintText: 'Décrivez brièvement cette action...',
                prefixIcon: Icon(Icons.description_outlined, color: AppTheme.primaryColor),
                filled: true,
                fillColor: colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: BorderSide(color: colorScheme.error, width: 2),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: BorderSide(color: colorScheme.error, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              style: GoogleFonts.poppins(fontSize: AppTheme.fontSize14),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'La description est requise';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            
            // Groupe
            DropdownButtonFormField<String>(
              initialValue: (_groups.any((g) => g.id == _selectedGroupId)) ? _selectedGroupId : null,
              decoration: InputDecoration(
                labelText: 'Groupe (optionnel)',
                hintText: 'Sélectionner un groupe',
                prefixIcon: Icon(Icons.group_outlined, color: AppTheme.primaryColor),
                filled: true,
                fillColor: colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              style: GoogleFonts.poppins(fontSize: AppTheme.fontSize14),
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text(
                    'Aucun groupe',
                    style: GoogleFonts.poppins(
                      color: colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                ..._groups.map((group) => DropdownMenuItem<String>(
                  value: group.id,
                  child: Row(
                    children: [
                      Icon(group.icon, size: 16, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      Text(group.name, style: GoogleFonts.poppins()),
                    ],
                  ),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedGroupId = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      elevation: 0,
      color: colorScheme.surfaceVariant.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Icon(
                    Icons.palette_outlined,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppTheme.space12),
                Text(
                  'Apparence',
                  style: GoogleFonts.poppins(
                    fontSize: AppTheme.fontSize16,
                    fontWeight: AppTheme.fontSemiBold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                // Prévisualisation
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _selectedColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(color: _selectedColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_selectedIcon, color: _selectedColor, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Aperçu',
                        style: GoogleFonts.poppins(
                          fontSize: AppTheme.fontSize12,
                          color: _selectedColor,
                          fontWeight: AppTheme.fontMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            
            // Sélection d'icône
            Row(
              children: [
                Icon(Icons.category_outlined, size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  'Icône',
                  style: GoogleFonts.poppins(
                    fontSize: AppTheme.fontSize14,
                    fontWeight: AppTheme.fontMedium,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space12),
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
              ),
              child: GridView.builder(
                padding: const EdgeInsets.all(AppTheme.space12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: _availableIcons.length,
                itemBuilder: (context, index) {
                  final icon = _availableIcons[index];
                  final isSelected = icon == _selectedIcon;
                  
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedIcon = icon;
                        });
                      },
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? AppTheme.primaryColor.withOpacity(0.15)
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected 
                                ? AppTheme.primaryColor
                                : colorScheme.outline.withOpacity(0.3),
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        child: Icon(
                          icon,
                          color: isSelected 
                              ? AppTheme.primaryColor 
                              : colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: AppTheme.spaceLarge),
            
            // Sélection de couleur
            Row(
              children: [
                Icon(Icons.color_lens_outlined, size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  'Couleur thématique',
                  style: GoogleFonts.poppins(
                    fontSize: AppTheme.fontSize14,
                    fontWeight: AppTheme.fontMedium,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space12),
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
              ),
              child: GridView.builder(
                padding: const EdgeInsets.all(AppTheme.space12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: _availableColors.length,
                itemBuilder: (context, index) {
                  final color = _availableColors[index];
                  final isSelected = color == _selectedColor;
                  
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedColor = color;
                        });
                      },
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          border: Border.all(
                            color: isSelected 
                                ? colorScheme.onSurface 
                                : color.withOpacity(0.3),
                            width: isSelected ? 3 : 1,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: color.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ] : null,
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 16,
                              )
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionConfigSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      elevation: 0,
      color: colorScheme.surfaceVariant.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Icon(
                    Icons.settings_outlined,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppTheme.space12),
                Text(
                  'Configuration de l\'action',
                  style: GoogleFonts.poppins(
                    fontSize: AppTheme.fontSize16,
                    fontWeight: AppTheme.fontSemiBold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            
            // Type d'action avec cards visuelles
            Text(
              'Type d\'action *',
              style: GoogleFonts.poppins(
                fontSize: AppTheme.fontSize14,
                fontWeight: AppTheme.fontMedium,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppTheme.space12),
            
            // Grid de sélection de types
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3.5,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: _actionTypes.length,
              itemBuilder: (context, index) {
                final type = _actionTypes[index];
                final isSelected = type == _selectedActionType;
                final icon = _getActionTypeIcon(type);
                
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedActionType = type;
                        _selectedTargetModule = null;
                        _selectedTargetRoute = null;
                        _selectedCustomActionType = null;
                        _urlController.clear();
                      });
                    },
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? AppTheme.primaryColor.withOpacity(0.1)
                            : colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        border: Border.all(
                          color: isSelected 
                              ? AppTheme.primaryColor 
                              : colorScheme.outline.withOpacity(0.3),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            icon,
                            color: isSelected 
                                ? AppTheme.primaryColor 
                                : colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getActionTypeLabel(type),
                              style: GoogleFonts.poppins(
                                fontSize: AppTheme.fontSize12,
                                fontWeight: isSelected 
                                    ? AppTheme.fontMedium 
                                    : AppTheme.fontRegular,
                                color: isSelected 
                                    ? AppTheme.primaryColor 
                                    : colorScheme.onSurface,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: AppTheme.spaceLarge),
            
            // Configuration spécifique selon le type
            ..._buildTypeSpecificConfig(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTypeSpecificConfig() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Configuration selon le type d'action
    if (_selectedActionType == 'navigate_page') {
      return [
          const SizedBox(height: AppTheme.spaceMedium),
        TextFormField(
          initialValue: _selectedTargetRoute,
          decoration: InputDecoration(
            labelText: 'Route de navigation *',
            hintText: '/page/example',
            prefixIcon: Icon(Icons.route_rounded, color: AppTheme.primaryColor),
            filled: true,
            fillColor: colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
          ),
          style: GoogleFonts.poppins(fontSize: AppTheme.fontSize14),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'La route est requise pour ce type d\'action';
            }
            return null;
          },
          onChanged: (value) {
            _selectedTargetRoute = value;
          },
        ),
      ];
    } else if (_selectedActionType == 'navigate_module') {
      return [
        DropdownButtonFormField<String>(
          initialValue: (_targetModules.contains(_selectedTargetModule)) ? _selectedTargetModule : null,
          decoration: InputDecoration(
            labelText: 'Module cible *',
            hintText: 'Sélectionner un module',
            prefixIcon: Icon(Icons.apps_rounded, color: AppTheme.primaryColor),
            filled: true,
            fillColor: colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
          ),
          style: GoogleFonts.poppins(fontSize: AppTheme.fontSize14),
          items: _targetModules.map((module) => DropdownMenuItem<String>(
            value: module,
            child: Text(_getModuleLabel(module)),
          )).toList(),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Le module cible est requis';
            }
            return null;
          },
          onChanged: (value) {
            setState(() {
              _selectedTargetModule = value;
              _selectedTargetRoute = null;
            });
          },
        ),
        if (_selectedTargetModule != null) ...[
          const SizedBox(height: AppTheme.spaceMedium),
          DropdownButtonFormField<String>(
            initialValue: ((_moduleRoutes[_selectedTargetModule] ?? []).contains(_selectedTargetRoute)) ? _selectedTargetRoute : null,
            decoration: InputDecoration(
              labelText: 'Route dans le module (optionnel)',
              hintText: 'Route spécifique',
              prefixIcon: Icon(Icons.alt_route_rounded, color: AppTheme.primaryColor.withOpacity(0.7)),
              filled: true,
              fillColor: colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
            ),
            style: GoogleFonts.poppins(fontSize: AppTheme.fontSize14),
            items: [
              DropdownMenuItem<String>(
                value: null,
                child: Text(
                  'Aucune route spécifique',
                  style: GoogleFonts.poppins(
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              ...(_moduleRoutes[_selectedTargetModule] ?? [])
                  .map((route) => DropdownMenuItem<String>(
                value: route,
                child: Text(route),
              )),
            ],
            onChanged: (value) {
              setState(() {
                _selectedTargetRoute = value;
              });
            },
          ),
        ],
      ];
    } else if (_selectedActionType == 'external_url') {
      return [
        TextFormField(
          controller: _urlController,
          decoration: InputDecoration(
            labelText: 'URL externe *',
            hintText: 'https://example.com',
            prefixIcon: Icon(Icons.link_rounded, color: AppTheme.primaryColor),
            filled: true,
            fillColor: colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
          ),
          style: GoogleFonts.poppins(fontSize: AppTheme.fontSize14),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'L\'URL est requise pour ce type d\'action';
            }
            final uri = Uri.tryParse(value);
            if (uri == null || !uri.hasScheme) {
              return 'Veuillez entrer une URL valide (ex: https://example.com)';
            }
            return null;
          },
        ),
      ];
    } else if (_selectedActionType == 'target_module') {
      return [
        // Sélection du type de cible (formulaire ou chant spécial)
        DropdownButtonFormField<String>(
          initialValue: _selectedTargetType,
          decoration: InputDecoration(
            labelText: 'Type de module cible *',
            hintText: 'Sélectionner le type',
            prefixIcon: Icon(Icons.category_rounded, color: AppTheme.primaryColor),
            filled: true,
            fillColor: colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
          ),
          style: GoogleFonts.poppins(fontSize: AppTheme.fontSize14),
          items: const [
            DropdownMenuItem<String>(
              value: 'form',
              child: Text('Formulaire du module Formulaires'),
            ),
            DropdownMenuItem<String>(
              value: 'special_song',
              child: Text('Page Réservation Chants spéciaux'),
            ),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Le type de module cible est requis';
            }
            return null;
          },
          onChanged: (value) {
            setState(() {
              _selectedTargetType = value!;
              _selectedFormId = null; // Reset form selection when type changes
            });
          },
        ),
        
        // Si c'est un formulaire, permettre de sélectionner lequel
        if (_selectedTargetType == 'form') ...[
          const SizedBox(height: AppTheme.spaceMedium),
          DropdownButtonFormField<String>(
            initialValue: _selectedFormId,
            decoration: InputDecoration(
              labelText: 'Formulaire *',
              hintText: 'Sélectionner un formulaire',
              prefixIcon: Icon(Icons.assignment_rounded, color: AppTheme.primaryColor),
              filled: true,
              fillColor: colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
            ),
            style: GoogleFonts.poppins(fontSize: AppTheme.fontSize14),
            items: _availableForms.map((form) => DropdownMenuItem<String>(
              value: form.id,
              child: Text(form.title),
            )).toList(),
            validator: (value) {
              if (_selectedTargetType == 'form' && (value == null || value.isEmpty)) {
                return 'Veuillez sélectionner un formulaire';
              }
              return null;
            },
            onChanged: (value) {
              setState(() {
                _selectedFormId = value;
              });
            },
          ),
          
          // Information sur le formulaire sélectionné
          if (_selectedFormId != null) ...[
            const SizedBox(height: AppTheme.spaceMedium),
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppTheme.primaryColor,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Formulaire sélectionné',
                        style: GoogleFonts.poppins(
                          fontSize: AppTheme.fontSize12,
                          fontWeight: AppTheme.fontMedium,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceSmall),
                  Text(
                    () {
                      final form = _availableForms.firstWhere(
                        (f) => f.id == _selectedFormId,
                        orElse: () => FormModel(
                          id: '',
                          title: 'Formulaire non trouvé',
                          description: '',
                          fields: [],
                          settings: FormSettings(),
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        ),
                      );
                      return form.description.isNotEmpty 
                          ? form.description 
                          : 'Ce formulaire sera ouvert lorsque l\'utilisateur cliquera sur l\'action.';
                    }(),
                    style: GoogleFonts.poppins(
                      fontSize: AppTheme.fontSize12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
        
        // Si c'est la réservation de chants spéciaux
        if (_selectedTargetType == 'special_song') ...[
          const SizedBox(height: AppTheme.spaceMedium),
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.music_note_rounded,
                      color: AppTheme.primaryColor,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Réservation de chants spéciaux',
                      style: GoogleFonts.poppins(
                        fontSize: AppTheme.fontSize12,
                        fontWeight: AppTheme.fontMedium,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceSmall),
                Text(
                  'Cette action ouvrira la page de réservation pour les chants spéciaux du dimanche.',
                  style: GoogleFonts.poppins(
                    fontSize: AppTheme.fontSize12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ];
    } else if (_selectedActionType == 'action_custom') {
      return [
        DropdownButtonFormField<String>(
          initialValue: _selectedCustomActionType,
          decoration: InputDecoration(
            labelText: 'Type d\'action personnalisée *',
            hintText: 'Sélectionner une action',
            prefixIcon: Icon(Icons.extension_rounded, color: AppTheme.primaryColor),
            filled: true,
            fillColor: colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
          ),
          style: GoogleFonts.poppins(fontSize: AppTheme.fontSize14),
          items: _customActionTypes.map((type) => DropdownMenuItem<String>(
            value: type,
            child: Text(_getCustomActionTypeLabel(type)),
          )).toList(),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Le type d\'action personnalisée est requis';
            }
            return null;
          },
          onChanged: (value) {
            setState(() {
              _selectedCustomActionType = value;
            });
          },
        ),
        if (_selectedCustomActionType != null) ...[
          const SizedBox(height: AppTheme.spaceMedium),
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppTheme.primaryColor,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Description de l\'action',
                      style: GoogleFonts.poppins(
                        fontSize: AppTheme.fontSize12,
                        fontWeight: AppTheme.fontMedium,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceSmall),
                Text(
                  _getCustomActionDescription(_selectedCustomActionType!),
                  style: GoogleFonts.poppins(
                    fontSize: AppTheme.fontSize12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ];
    }
    
    return [];
  }

  Widget _buildAdvancedSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      elevation: 0,
      color: colorScheme.surfaceVariant.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppTheme.space12),
                Text(
                  'Options avancées',
                  style: GoogleFonts.poppins(
                    fontSize: AppTheme.fontSize16,
                    fontWeight: AppTheme.fontSemiBold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            
            Row(
              children: [
                // Ordre d'affichage
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: _order.toString(),
                    decoration: InputDecoration(
                      labelText: 'Ordre d\'affichage',
                      hintText: '0',
                      prefixIcon: Icon(Icons.sort_rounded, color: AppTheme.primaryColor),
                      filled: true,
                      fillColor: colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    style: GoogleFonts.poppins(fontSize: AppTheme.fontSize14),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _order = int.tryParse(value) ?? 0;
                    },
                  ),
                ),
                
                const SizedBox(width: AppTheme.spaceLarge),
                
                // Status actif/inactif
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(AppTheme.spaceMedium),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isActive ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                          color: _isActive ? AppTheme.primaryColor : colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        const SizedBox(width: AppTheme.space12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Action active',
                                style: GoogleFonts.poppins(
                                  fontSize: AppTheme.fontSize14,
                                  fontWeight: AppTheme.fontMedium,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                _isActive ? 'Visible pour les membres' : 'Masquée aux membres',
                                style: GoogleFonts.poppins(
                                  fontSize: AppTheme.fontSize12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isActive,
                          onChanged: (value) {
                            setState(() {
                              _isActive = value;
                            });
                          },
                          activeColor: AppTheme.primaryColor,
                          activeTrackColor: AppTheme.primaryColor.withOpacity(0.3),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.spaceMedium),
            
            // Aide contextuelle
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    color: colorScheme.onSurfaceVariant,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'L\'ordre détermine la position d\'affichage (0 = premier). Les actions inactives ne sont visibles que par les administrateurs.',
                      style: GoogleFonts.poppins(
                        fontSize: AppTheme.fontSize12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getActionTypeLabel(String type) {
    switch (type) {
      case 'navigate_page':
        return 'Navigation vers une page';
      case 'navigate_module':
        return 'Navigation vers un module';
      case 'external_url':
        return 'Ouvrir une URL externe';
      case 'action_custom':
        return 'Action personnalisée';
      case 'target_module':
        return 'Module cible (Formulaire/Chant)';
      default:
        return type;
    }
  }

  IconData _getActionTypeIcon(String type) {
    switch (type) {
      case 'navigate_page':
        return Icons.launch_rounded;
      case 'navigate_module':
        return Icons.apps_rounded;
      case 'external_url':
        return Icons.open_in_new_rounded;
      case 'action_custom':
        return Icons.extension_rounded;
      case 'target_module':
        return Icons.assignment_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String _getCustomActionTypeLabel(String type) {
    switch (type) {
      case 'baptism_request':
        return 'Demande de baptême d\'eau';
      case 'team_join':
        return 'Rejoindre une équipe';
      case 'appointment_request':
        return 'Prendre rendez-vous avec le pasteur';
      case 'question_ask':
        return 'Poser une question au pasteur';
      case 'special_song':
        return 'Réserver un chant spécial';
      case 'testimony_share':
        return 'Partager un témoignage';
      case 'idea_suggest':
        return 'Proposer une idée d\'amélioration';
      case 'issue_report':
        return 'Signaler un problème';
      default:
        return type;
    }
  }

  String _getCustomActionDescription(String type) {
    switch (type) {
      case 'baptism_request':
        return 'Ouvre le formulaire de demande de baptême d\'eau pour les nouveaux convertis.';
      case 'team_join':
        return 'Permet de rejoindre une équipe de service dans l\'église.';
      case 'appointment_request':
        return 'Navigue vers la page de prise de rendez-vous avec le pasteur.';
      case 'question_ask':
        return 'Ouvre le formulaire pour poser des questions au pasteur.';
      case 'special_song':
        return 'Accède à la page de réservation pour présenter un chant spécial.';
      case 'testimony_share':
        return 'Ouvre le formulaire pour partager un témoignage public.';
      case 'idea_suggest':
        return 'Permet de proposer des idées d\'amélioration pour l\'église.';
      case 'issue_report':
        return 'Ouvre le formulaire pour signaler un problème ou dysfonctionnement.';
      default:
        return '';
    }
  }

  String _getModuleLabel(String module) {
    switch (module) {
      case 'bible':
        return 'Bible & Message';
      case 'vie_eglise':
        return 'Vie de l\'église';
      case 'songs':
        return 'Chants';
      case 'pour_vous':
        return 'Pour vous';
      case 'profile':
        return 'Profil';
      case 'settings':
        return 'Paramètres';
      default:
        return module;
    }
  }

  Future<void> _saveAction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      final colorHex = '#${_selectedColor.value.toRadixString(16).substring(2).toUpperCase()}';

      // Préparer les données selon le type d'action
      String? targetRoute;
      String? targetModule;
      Map<String, dynamic>? actionData;
      
      switch (_selectedActionType) {
        case 'navigate_page':
          targetRoute = _selectedTargetRoute;
          break;
        case 'navigate_module':
          targetModule = _selectedTargetModule;
          targetRoute = _selectedTargetRoute;
          break;
        case 'external_url':
          targetRoute = _urlController.text.trim();
          actionData = {'url': _urlController.text.trim()};
          break;
        case 'action_custom':
          if (_selectedCustomActionType != null) {
            actionData = {'type': _selectedCustomActionType};
          }
          break;
        case 'target_module':
          actionData = {
            'targetType': _selectedTargetType,
            'formId': _selectedTargetType == 'form' ? _selectedFormId : null,
          };
          break;
      }

      if (widget.action == null || widget.isDuplicate) {
        // Créer une nouvelle action
        final newAction = PourVousAction(
          id: '', // Sera généré par Firestore
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          icon: _selectedIcon,
          iconCodePoint: _selectedIcon.codePoint.toString(),
          actionType: _selectedActionType,
          targetModule: targetModule,
          targetRoute: targetRoute,
          actionData: actionData,
          isActive: _isActive,
          order: _order,
          createdAt: now,
          updatedAt: now,
          color: colorHex,
          groupId: _selectedGroupId,
        );

        await _actionService.createAction(newAction);
      } else {
        // Modifier l'action existante
        final updatedAction = widget.action!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          icon: _selectedIcon,
          iconCodePoint: _selectedIcon.codePoint.toString(),
          actionType: _selectedActionType,
          targetModule: targetModule,
          targetRoute: targetRoute,
          actionData: actionData,
          isActive: _isActive,
          order: _order,
          updatedAt: now,
          color: colorHex,
          groupId: _selectedGroupId,
        );

        await _actionService.updateAction(widget.action!.id, updatedAction);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.action == null || widget.isDuplicate 
                  ? 'Action créée avec succès'
                  : 'Action modifiée avec succès',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur: ${e.toString()}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
