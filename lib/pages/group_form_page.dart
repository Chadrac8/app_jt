import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/group_model.dart';
import '../models/recurrence_config.dart';
import '../services/groups_firebase_service.dart';
import '../services/group_event_integration_service.dart';
import '../image_upload.dart';
import '../services/image_storage_service.dart' as ImageStorage;
import '../widgets/group_recurrence_config_widget.dart';
import '../../theme.dart';


class GroupFormPage extends StatefulWidget {
  final GroupModel? group;

  const GroupFormPage({super.key, this.group});

  @override
  State<GroupFormPage> createState() => _GroupFormPageState();
}

class _GroupFormPageState extends State<GroupFormPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  // Form controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _meetingLinkController = TextEditingController();
  final _timeController = TextEditingController();
  
  // Form values
  String? _selectedType;
  String? _selectedFrequency;
  int _selectedDayOfWeek = 1;
  bool _isPublic = true;
  String _selectedColor = '#6F61EF';
  List<String> _selectedLeaderIds = [];
  List<String> _tags = [];
  bool _isActive = true;
  bool _isLoading = false;
  
  // 🆕 Génération événements
  bool _generateEvents = false;
  RecurrenceConfig? _recurrenceConfig;
  DateTime? _recurrenceStartDate;
  DateTime? _recurrenceEndDate;
  int? _maxOccurrences;
  
  // Image handling
  String? _groupImageUrl;
  bool _hasImageChanged = false;

  final List<String> _groupTypes = [
    'Petit groupe',
    'Prière',
    'Jeunesse',
    'Étude biblique',
    'Louange',
    'Leadership',
    'Conseil',
    'Ministère',
    'Formation',
    'Autre',
  ];

  final List<String> _frequencies = [
    'weekly',
    'biweekly',
    'monthly',
    'quarterly',
  ];

  final Map<String, String> _frequencyLabels = {
    'weekly': 'Hebdomadaire',
    'biweekly': 'Bi-mensuel',
    'monthly': 'Mensuel',
    'quarterly': 'Trimestriel',
  };

  final List<String> _weekDays = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche',
  ];

  final List<String> _predefinedColors = [
    '#6F61EF', // Primary
    '#39D2C0', // Secondary
    '#EE8B60', // Tertiary
    '#FF6B6B', // Red
    '#4ECDC4', // Teal
    '#45B7D1', // Blue
    '#96CEB4', // Green
    '#FFEAA7', // Yellow
    '#DDA0DD', // Plum
    '#98D8C8', // Mint
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _initializeForm();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _meetingLinkController.dispose();
    _timeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    if (widget.group != null) {
      final group = widget.group!;
      _nameController.text = group.name;
      _descriptionController.text = group.description;
      _locationController.text = group.location;
      _meetingLinkController.text = group.meetingLink ?? '';
      _timeController.text = group.time;
      _selectedType = group.type;
      _selectedFrequency = group.frequency;
      _selectedDayOfWeek = group.dayOfWeek;
      _isPublic = group.isPublic;
      _selectedColor = group.color;
      _selectedLeaderIds = List.from(group.leaderIds);
      _tags = List.from(group.tags);
      _groupImageUrl = group.groupImageUrl;
      _isActive = group.isActive;
      
      // 🆕 Initialiser génération événements
      _generateEvents = group.generateEvents;
      if (group.recurrenceConfig != null) {
        _recurrenceConfig = RecurrenceConfig.fromMap(group.recurrenceConfig!);
      }
      _recurrenceStartDate = group.recurrenceStartDate;
      _recurrenceEndDate = group.recurrenceEndDate;
      _maxOccurrences = group.maxOccurrences;
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _timeController.text.isNotEmpty
          ? TimeOfDay(
              hour: int.parse(_timeController.text.split(':')[0]),
              minute: int.parse(_timeController.text.split(':')[1]),
            )
          : TimeOfDay.now(),
    );
    
    if (time != null) {
      setState(() {
        _timeController.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  void _addTag() {
    showDialog(
      context: context,
      builder: (context) {
        String newTag = '';
        return AlertDialog(
          title: const Text('Ajouter un tag'),
          content: TextField(
            onChanged: (value) => newTag = value,
            decoration: const InputDecoration(
              hintText: 'Nom du tag',
              border: OutlineInputBorder(),
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
                if (newTag.isNotEmpty && !_tags.contains(newTag)) {
                  setState(() {
                    _tags.add(newTag);
                  });
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

  Future<void> _pickGroupImage() async {
    try {
      setState(() => _isLoading = true);
      final imageBytes = await ImageUploadHelper.pickImageFromGallery();
      if (imageBytes != null) {
        final oldImageUrl = _groupImageUrl;
        final imageUrl = await ImageStorage.ImageStorageService.uploadImage(
          imageBytes,
          customPath: 'groups/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        if (imageUrl != null) {
          setState(() {
            _groupImageUrl = imageUrl;
            _hasImageChanged = true;
          });
          if (oldImageUrl != null &&
              oldImageUrl.isNotEmpty &&
              ImageStorage.ImageStorageService.isFirebaseStorageUrl(oldImageUrl)) {
            ImageStorage.ImageStorageService.deleteImageByUrl(oldImageUrl);
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Image du groupe mise à jour avec succès'),
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Erreur : l\'image n\'a pas pu être uploadée. Vérifiez votre connexion ou réessayez.'),
                backgroundColor: AppTheme.redStandard,
                duration: Duration(seconds: 5),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'upload de l\'image : $e'),
            backgroundColor: AppTheme.redStandard,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveGroup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      
      final group = GroupModel(
        id: widget.group?.id ?? '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType!,
        frequency: _selectedFrequency!,
        location: _locationController.text.trim(),
        meetingLink: _meetingLinkController.text.trim().isEmpty 
            ? null 
            : _meetingLinkController.text.trim(),
        dayOfWeek: _selectedDayOfWeek,
        time: _timeController.text,
        isPublic: _isPublic,
        color: _selectedColor,
        leaderIds: _selectedLeaderIds,
        tags: _tags,
        isActive: _isActive,
        groupImageUrl: _groupImageUrl,
        // 🆕 Génération événements
        generateEvents: _generateEvents,
        recurrenceConfig: _recurrenceConfig?.toMap(),
        recurrenceStartDate: _recurrenceStartDate,
        recurrenceEndDate: _recurrenceEndDate,
        maxOccurrences: _maxOccurrences,
        createdAt: widget.group?.createdAt ?? now,
        updatedAt: now,
      );

      String savedGroupId;
      
      if (widget.group == null) {
        // Création nouveau groupe
        savedGroupId = await GroupsFirebaseService.createGroup(group);
      } else {
        // Mise à jour groupe existant
        await GroupsFirebaseService.updateGroup(group);
        savedGroupId = group.id;
      }

      // 🆕 Générer les événements si activé
      if (_generateEvents && _recurrenceConfig != null) {
        try {
          final integrationService = GroupEventIntegrationService();
          
          await integrationService.enableEventsForGroup(
            groupId: savedGroupId,
            recurrenceConfig: _recurrenceConfig!,
            startDate: _recurrenceStartDate ?? DateTime.now(),
            endDate: _recurrenceEndDate,
            maxOccurrences: _maxOccurrences,
            userId: FirebaseAuth.instance.currentUser?.uid ?? 'system',
          );
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Groupe créé avec succès ! ${_maxOccurrences ?? 'Plusieurs'} événements générés.',
                ),
                backgroundColor: AppTheme.greenStandard,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Groupe créé mais erreur génération événements: $e'),
                backgroundColor: AppTheme.orangeStandard,
              ),
            );
          }
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.redStandard,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.group == null ? 'Nouveau groupe' : 'Modifier le groupe'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _saveGroup,
              child: Text(
                'Enregistrer',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: AppTheme.fontBold,
                ),
              ),
            ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 50 * _slideAnimation.value),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: _buildForm(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppTheme.space20),
        children: [
          // Basic Information Section
          _buildSection(
            title: 'Informations de base',
            icon: Icons.info_outline,
            children: [
              _buildTextField(
                controller: _nameController,
                label: 'Nom du groupe',
                icon: Icons.group,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le nom est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                icon: Icons.description,
                maxLines: 3,
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              _buildDropdown(
                value: _selectedType,
                label: 'Type de groupe',
                icon: Icons.category,
                items: _groupTypes,
                onChanged: (value) => setState(() => _selectedType = value),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le type est requis';
                  }
                  return null;
                },
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spaceLarge),

          // Group Image Section
          _buildSection(
            title: 'Photo du groupe',
            icon: Icons.image,
            children: [
              _buildGroupImageSection(),
            ],
          ),

          const SizedBox(height: AppTheme.spaceLarge),

          // Schedule Section
          _buildSection(
            title: 'Horaires',
            icon: Icons.schedule,
            children: [
              _buildDropdown(
                value: _selectedFrequency,
                label: 'Fréquence',
                icon: Icons.repeat,
                items: _frequencies,
                itemLabels: _frequencyLabels,
                onChanged: (value) => setState(() => _selectedFrequency = value),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La fréquence est requise';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      value: _weekDays[_selectedDayOfWeek - 1],
                      label: 'Jour',
                      icon: Icons.calendar_today,
                      items: _weekDays,
                      onChanged: (value) {
                        setState(() {
                          _selectedDayOfWeek = _weekDays.indexOf(value!) + 1;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceMedium),
                  Expanded(
                    child: _buildTextField(
                      controller: _timeController,
                      label: 'Heure',
                      icon: Icons.access_time,
                      readOnly: true,
                      onTap: _selectTime,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'L\'heure est requise';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spaceLarge),

          // Location Section
          _buildSection(
            title: 'Lieu',
            icon: Icons.location_on,
            children: [
              _buildTextField(
                controller: _locationController,
                label: 'Adresse ou lieu',
                icon: Icons.place,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le lieu est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              _buildTextField(
                controller: _meetingLinkController,
                label: 'Lien de réunion (optionnel)',
                icon: Icons.link,
                keyboardType: TextInputType.url,
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spaceLarge),

          // Settings Section
          _buildSection(
            title: 'Paramètres',
            icon: Icons.settings,
            children: [
              // Visibility Toggle
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceMedium),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.visibility,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: AppTheme.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Groupe public',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: AppTheme.fontMedium,
                            ),
                          ),
                          Text(
                            'Visible par tous les membres',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isPublic,
                      onChanged: (value) => setState(() => _isPublic = value),
                      activeThumbColor: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppTheme.spaceMedium),
              
              // Color Selection
              Text(
                'Couleur du groupe',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: AppTheme.fontBold,
                ),
              ),
              const SizedBox(height: AppTheme.spaceSmall),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _predefinedColors.map((color) {
                  final isSelected = _selectedColor == color;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(int.parse(color.replaceFirst('#', '0xFF'))).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: AppTheme.white100,
                              size: 20,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spaceLarge),

          // Tags Section
          _buildSection(
            title: 'Tags',
            icon: Icons.label,
            children: [
              if (_tags.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tags.map((tag) => Chip(
                    label: Text(tag),
                    onDeleted: () {
                      setState(() {
                        _tags.remove(tag);
                      });
                    },
                    backgroundColor: Color(int.parse(_selectedColor.replaceFirst('#', '0xFF'))).withOpacity(0.1),
                    labelStyle: TextStyle(
                      color: Color(int.parse(_selectedColor.replaceFirst('#', '0xFF'))),
                    ),
                    deleteIconColor: Color(int.parse(_selectedColor.replaceFirst('#', '0xFF'))),
                  )).toList(),
                ),
                const SizedBox(height: AppTheme.space12),
              ],
              OutlinedButton.icon(
                onPressed: _addTag,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un tag'),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spaceLarge),

          // Generation evenements automatique
          _buildSection(
            title: 'Generation evenements',
            icon: Icons.event_repeat,
            children: [
              SwitchListTile(
                value: _generateEvents,
                onChanged: (value) {
                  setState(() {
                    _generateEvents = value;
                    if (value && _recurrenceConfig == null) {
                      // Initialiser avec config par défaut
                      _recurrenceConfig = RecurrenceConfig(
                        frequency: RecurrenceFrequency.weekly,
                        interval: 1,
                        dayOfWeek: _selectedDayOfWeek,
                        time: _timeController.text.isNotEmpty ? _timeController.text : '19:00',
                        durationMinutes: 120,
                        startDate: DateTime.now(),
                      );
                      _recurrenceStartDate = DateTime.now();
                    }
                  });
                },
                title: const Text('Générer des événements automatiquement'),
                subtitle: Text(
                  'Créer automatiquement des événements dans le calendrier pour chaque réunion de groupe',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
                      ),
                ),
                contentPadding: EdgeInsets.zero,
              ),
              
              if (_generateEvents) ...[
                const SizedBox(height: AppTheme.spaceMedium),
                const Divider(),
                const SizedBox(height: AppTheme.spaceMedium),
                
                // Widget de configuration récurrence
                GroupRecurrenceConfigWidget(
                  initialConfig: _recurrenceConfig,
                  startDate: _recurrenceStartDate,
                  endDate: _recurrenceEndDate,
                  onConfigChanged: (config) {
                    setState(() {
                      _recurrenceConfig = config;
                      _recurrenceStartDate = config.startDate;
                      _recurrenceEndDate = config.endDate;
                    });
                  },
                ),
                
                const SizedBox(height: AppTheme.spaceMedium),
                
                // Max occurrences (optionnel)
                TextFormField(
                  initialValue: _maxOccurrences?.toString() ?? '',
                  decoration: InputDecoration(
                    labelText: 'Nombre maximum d\'occurrences (optionnel)',
                    hintText: 'Ex: 20',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    helperText: 'Limiter le nombre d\'événements générés',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      _maxOccurrences = value.isEmpty ? null : int.tryParse(value);
                    });
                  },
                ),
                
                const SizedBox(height: AppTheme.spaceSmall),
                
                // Info box
                Container(
                  padding: const EdgeInsets.all(AppTheme.space12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withAlpha(128),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withAlpha(77),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: AppTheme.spaceSmall),
                      Expanded(
                        child: Text(
                          _recurrenceConfig != null 
                              ? 'Configuration : ${_recurrenceConfig!.description}'
                              : 'Configurez la récurrence pour générer les événements',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 100), // Space for floating action button
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black100.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppTheme.space12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: AppTheme.fontBold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int? maxLines,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines ?? 1,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    Map<String, String>? itemLabels,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
      ),
      items: items.map((item) => DropdownMenuItem(
        value: item,
        child: Text(itemLabels?[item] ?? item),
      )).toList(),
    );
  }

  Widget _buildGroupImageSection() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          width: 2,
          style: BorderStyle.solid,
        ),
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
      ),
      child: Stack(
        children: [
          if (_groupImageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _groupImageUrl!.startsWith('data:image')
                  ? Image.memory(
                      base64Decode(_groupImageUrl!.split(',').last),
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildImagePlaceholder();
                      },
                    )
                  : CachedNetworkImage(
                      imageUrl: _groupImageUrl!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => _buildImagePlaceholder(),
                      errorWidget: (context, url, error) => _buildImagePlaceholder(),
                    ),
            )
          else
            _buildImagePlaceholder(),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: AppTheme.black100.withOpacity(0.4),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          if (_groupImageUrl != null && !_isLoading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppTheme.black100.withOpacity(0.3),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _pickGroupImage,
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Changer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: AppTheme.white100,
                          ),
                        ),
                        const SizedBox(width: AppTheme.space12),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _groupImageUrl = null;
                              _hasImageChanged = true;
                            });
                          },
                          icon: const Icon(Icons.delete, size: 16),
                          label: const Text('Supprimer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.errorColor,
                            foregroundColor: AppTheme.white100,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return InkWell(
      onTap: _pickGroupImage,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              size: 48,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
            ),
            const SizedBox(height: AppTheme.space12),
            Text(
              'Ajouter une photo',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: AppTheme.fontMedium,
              ),
            ),
            const SizedBox(height: AppTheme.spaceXSmall),
            Text(
              'Cliquez pour sélectionner une image',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}