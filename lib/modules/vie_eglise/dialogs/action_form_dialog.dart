import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme.dart';
import '../models/pour_vous_action.dart';
import '../models/action_group.dart';
import '../services/pour_vous_action_service.dart';
import '../services/action_group_service.dart';

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

  String _selectedActionType = 'navigation';
  String? _selectedGroupId;
  String? _selectedTargetModule;
  String? _selectedTargetRoute;
  IconData _selectedIcon = Icons.help_outline;
  Color _selectedColor = AppTheme.primaryColor;
  bool _isActive = true;
  int _order = 0;
  bool _isLoading = false;
  List<ActionGroup> _groups = [];

  final List<String> _actionTypes = [
    'navigation',
    'form',
    'external',
    'contact',
  ];

  final List<String> _targetModules = [
    'bible',
    'vie_eglise',
    'songs',
    'pour_vous',
    'profile',
    'settings',
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
    Colors.purple,
    Colors.orange,
    Colors.teal,
    Colors.indigo,
    Colors.pink,
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.isDuplicate 
            ? 'Dupliquer l\'action'
            : widget.action == null 
                ? 'Créer une action'
                : 'Modifier l\'action',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBasicInfoSection(),
                const SizedBox(height: 24),
                _buildAppearanceSection(),
                const SizedBox(height: 24),
                _buildActionConfigSection(),
                const SizedBox(height: 24),
                _buildAdvancedSection(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Annuler',
            style: GoogleFonts.poppins(color: AppTheme.textSecondaryColor),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveAction,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  widget.action == null || widget.isDuplicate ? 'Créer' : 'Modifier',
                  style: GoogleFonts.poppins(color: AppTheme.surfaceColor),
                ),
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations de base',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: 'Titre *',
            labelStyle: GoogleFonts.poppins(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.primaryColor),
            ),
          ),
          style: GoogleFonts.poppins(),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le titre est requis';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            labelText: 'Description *',
            labelStyle: GoogleFonts.poppins(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.primaryColor),
            ),
          ),
          style: GoogleFonts.poppins(),
          maxLines: 3,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'La description est requise';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedGroupId,
          decoration: InputDecoration(
            labelText: 'Groupe',
            labelStyle: GoogleFonts.poppins(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.primaryColor),
            ),
          ),
          style: GoogleFonts.poppins(),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text('Aucun groupe', style: GoogleFonts.poppins()),
            ),
            ..._groups.map((group) => DropdownMenuItem<String>(
              value: group.id,
              child: Text(group.name, style: GoogleFonts.poppins()),
            )),
          ],
          onChanged: (value) {
            setState(() {
              _selectedGroupId = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildAppearanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Apparence',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Icône',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.textTertiaryColor.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: _availableIcons.length,
            itemBuilder: (context, index) {
              final icon = _availableIcons[index];
              final isSelected = icon == _selectedIcon;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedIcon = icon;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? AppTheme.primaryColor.withOpacity(0.1)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected 
                          ? AppTheme.primaryColor
                          : AppTheme.textTertiaryColor.withOpacity(0.3),
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Couleur',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 60,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.textTertiaryColor.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: _availableColors.length,
            itemBuilder: (context, index) {
              final color = _availableColors[index];
              final isSelected = color == _selectedColor;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedColor = color;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    border: Border.all(
                      color: isSelected ? Colors.black : Colors.grey,
                      width: isSelected ? 3 : 1,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionConfigSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration de l\'action',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedActionType,
          decoration: InputDecoration(
            labelText: 'Type d\'action *',
            labelStyle: GoogleFonts.poppins(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.primaryColor),
            ),
          ),
          style: GoogleFonts.poppins(),
          items: _actionTypes.map((type) => DropdownMenuItem<String>(
            value: type,
            child: Text(_getActionTypeLabel(type), style: GoogleFonts.poppins()),
          )).toList(),
          onChanged: (value) {
            setState(() {
              _selectedActionType = value!;
              _selectedTargetModule = null;
              _selectedTargetRoute = null;
            });
          },
        ),
        if (_selectedActionType == 'navigation') ...[
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedTargetModule,
            decoration: InputDecoration(
              labelText: 'Module cible',
              labelStyle: GoogleFonts.poppins(),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppTheme.primaryColor),
              ),
            ),
            style: GoogleFonts.poppins(),
            items: _targetModules.map((module) => DropdownMenuItem<String>(
              value: module,
              child: Text(_getModuleLabel(module), style: GoogleFonts.poppins()),
            )).toList(),
            onChanged: (value) {
              setState(() {
                _selectedTargetModule = value;
                _selectedTargetRoute = null;
              });
            },
          ),
          if (_selectedTargetModule != null) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedTargetRoute,
              decoration: InputDecoration(
                labelText: 'Route cible',
                labelStyle: GoogleFonts.poppins(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.primaryColor),
                ),
              ),
              style: GoogleFonts.poppins(),
              items: (_moduleRoutes[_selectedTargetModule] ?? [])
                  .map((route) => DropdownMenuItem<String>(
                value: route,
                child: Text(route, style: GoogleFonts.poppins()),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTargetRoute = value;
                });
              },
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildAdvancedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Options avancées',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: _order.toString(),
                decoration: InputDecoration(
                  labelText: 'Ordre d\'affichage',
                  labelStyle: GoogleFonts.poppins(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.primaryColor),
                  ),
                ),
                style: GoogleFonts.poppins(),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _order = int.tryParse(value) ?? 0;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SwitchListTile(
                title: Text(
                  'Action active',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
                activeColor: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getActionTypeLabel(String type) {
    switch (type) {
      case 'navigation':
        return 'Navigation';
      case 'form':
        return 'Formulaire';
      case 'external':
        return 'Lien externe';
      case 'contact':
        return 'Contact';
      default:
        return type;
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

      if (widget.action == null || widget.isDuplicate) {
        // Créer une nouvelle action
        final newAction = PourVousAction(
          id: '', // Sera généré par Firestore
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          icon: _selectedIcon,
          iconCodePoint: _selectedIcon.codePoint.toString(),
          actionType: _selectedActionType,
          targetModule: _selectedTargetModule,
          targetRoute: _selectedTargetRoute,
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
          targetModule: _selectedTargetModule,
          targetRoute: _selectedTargetRoute,
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
