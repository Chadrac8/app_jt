import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../theme.dart';
import '../../../services/image_upload_service.dart';
import '../models/action_item.dart';
import '../services/pour_vous_service.dart';

class ActionFormView extends StatefulWidget {
  final ActionItem? action;

  const ActionFormView({
    super.key,
    this.action,
  });

  @override
  State<ActionFormView> createState() => _ActionFormViewState();
}

class _ActionFormViewState extends State<ActionFormView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _redirectUrlController = TextEditingController();
  final _redirectRouteController = TextEditingController();
  final _coverImageUrlController = TextEditingController();
  final _orderController = TextEditingController();

  String _selectedIcon = 'help';
  bool _isActive = true;
  bool _isLoading = false;
  String _redirectType = 'route'; // 'route' ou 'url'
  File? _selectedImageFile;
  String? _selectedModuleRoute;

  // Routes des modules disponibles pour la redirection
  final Map<String, String> _availableModuleRoutes = {
    'Accueil': '/member/dashboard',
    'Mes groupes': '/member/groups',
    'Événements': '/member/events',
    'Services/Cultes': '/member/services',
    'Formulaires': '/member/forms',
    'Tâches': '/member/tasks',
    'Bible': '/member/bible',
    'Cantiques': '/member/songs',
    'Le Message': '/member/message',
    'Ressources': '/member/resources',
    'Mur de prière': '/member/prayer-wall',
    'Calendrier': '/member/calendar',
    'Notifications': '/member/notifications',
    'Mon profil': '/member/profile',
    'Rendez-vous': '/member/appointments',
    'Listes dynamiques': '/member/dynamic-lists',
    'Blog': '/member/blog',
    'Pages personnalisées': '/member/pages',
  };

  final List<Map<String, dynamic>> _availableIcons = [
    {'name': 'help', 'icon': Icons.help_outline, 'label': 'Aide'},
    {'name': 'prayer', 'icon': Icons.favorite_outline, 'label': 'Prière'},
    {'name': 'water_drop', 'icon': Icons.water_drop, 'label': 'Baptême'},
    {'name': 'groups', 'icon': Icons.groups, 'label': 'Groupes'},
    {'name': 'schedule', 'icon': Icons.schedule, 'label': 'Rendez-vous'},
    {'name': 'lightbulb', 'icon': Icons.lightbulb_outline, 'label': 'Idée'},
    {'name': 'phone', 'icon': Icons.phone, 'label': 'Téléphone'},
    {'name': 'email', 'icon': Icons.email, 'label': 'Email'},
    {'name': 'question_answer', 'icon': Icons.question_answer, 'label': 'Questions'},
    {'name': 'volunteer_activism', 'icon': Icons.volunteer_activism, 'label': 'Bénévolat'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.action != null) {
      _populateForm();
    }
  }

  void _populateForm() {
    final action = widget.action!;
    _titleController.text = action.title;
    _descriptionController.text = action.description;
    _redirectUrlController.text = action.redirectUrl ?? '';
    _redirectRouteController.text = action.redirectRoute ?? '';
    _coverImageUrlController.text = action.coverImageUrl ?? '';
    _orderController.text = action.order.toString();
    _selectedIcon = action.iconName;
    _isActive = action.isActive;
    
    // Déterminer le type de redirection
    if (action.redirectRoute != null && action.redirectRoute!.isNotEmpty) {
      _redirectType = 'route';
      _selectedModuleRoute = action.redirectRoute;
    } else if (action.redirectUrl != null && action.redirectUrl!.isNotEmpty) {
      _redirectType = 'url';
    }
  }

  /// Sélectionner une image depuis la galerie
  Future<void> _selectImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedImageFile = File(image.path);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image sélectionnée. Elle sera uploadée lors de la sauvegarde.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sélection d\'image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _redirectUrlController.dispose();
    _redirectRouteController.dispose();
    _coverImageUrlController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.action == null ? 'Nouvelle action' : 'Modifier l\'action',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (widget.action != null)
            IconButton(
              onPressed: _deleteAction,
              icon: const Icon(Icons.delete),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildBasicInfoCard(),
            const SizedBox(height: 16),
            _buildRedirectionCard(),
            const SizedBox(height: 16),
            _buildAppearanceCard(),
            const SizedBox(height: 16),
            _buildConfigurationCard(),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: AppTheme.primaryColor),
                  ),
                  child: Text(
                    'Annuler',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Enregistrer',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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

  Widget _buildBasicInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations de base',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titre *',
                hintText: 'Ex: Demander une prière',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le titre est obligatoire';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'Décrivez brièvement cette action',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'La description est obligatoire';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRedirectionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Redirection',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choisissez où diriger l\'utilisateur quand il clique sur cette action',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 16),
            
            // Sélecteur de type de redirection
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: const Text('Redirection vers un module'),
                    subtitle: const Text('Naviguer vers un module de l\'application'),
                    value: 'route',
                    groupValue: _redirectType,
                    onChanged: (value) {
                      setState(() {
                        _redirectType = value!;
                        if (value == 'route') {
                          _redirectUrlController.clear();
                        } else {
                          _redirectRouteController.clear();
                          _selectedModuleRoute = null;
                        }
                      });
                    },
                  ),
                  if (_redirectType == 'route') ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: DropdownButtonFormField<String>(
                        value: _selectedModuleRoute,
                        decoration: const InputDecoration(
                          labelText: 'Sélectionner un module',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.navigation),
                        ),
                        items: _availableModuleRoutes.entries.map((entry) {
                          return DropdownMenuItem<String>(
                            value: entry.value,
                            child: Text(entry.key),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedModuleRoute = value;
                            _redirectRouteController.text = value ?? '';
                          });
                        },
                      ),
                    ),
                  ],
                  RadioListTile<String>(
                    title: const Text('Redirection vers une URL externe'),
                    subtitle: const Text('Ouvrir un lien web externe'),
                    value: 'url',
                    groupValue: _redirectType,
                    onChanged: (value) {
                      setState(() {
                        _redirectType = value!;
                        if (value == 'url') {
                          _redirectRouteController.clear();
                          _selectedModuleRoute = null;
                        } else {
                          _redirectUrlController.clear();
                        }
                      });
                    },
                  ),
                  if (_redirectType == 'url') ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: TextFormField(
                        controller: _redirectUrlController,
                        decoration: const InputDecoration(
                          labelText: 'URL externe',
                          hintText: 'https://example.com',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.link),
                        ),
                        validator: (value) {
                          if (_redirectType == 'url' && (value == null || value.isEmpty)) {
                            return 'Veuillez entrer une URL';
                          }
                          if (value != null && value.isNotEmpty && !value.startsWith('http')) {
                            return 'L\'URL doit commencer par http:// ou https://';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apparence',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            
            // Sélection d'icône
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
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _availableIcons.length,
                itemBuilder: (context, index) {
                  final iconData = _availableIcons[index];
                  final isSelected = iconData['name'] == _selectedIcon;
                  
                  return InkWell(
                    onTap: () => setState(() => _selectedIcon = iconData['name']),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? AppTheme.primaryColor
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected 
                              ? AppTheme.primaryColor
                              : Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            iconData['icon'],
                            color: isSelected ? Colors.white : AppTheme.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            iconData['label'],
                            style: GoogleFonts.poppins(
                              fontSize: 8,
                              color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),
            
            // Image de couverture
            Text(
              'Image de couverture',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            
            // Aperçu de l'image
            if (_selectedImageFile != null || _coverImageUrlController.text.isNotEmpty)
              Container(
                width: double.infinity,
                height: 120,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _selectedImageFile != null
                      ? Image.file(
                          _selectedImageFile!,
                          fit: BoxFit.cover,
                        )
                      : _coverImageUrlController.text.isNotEmpty
                          ? Image.network(
                              _coverImageUrlController.text,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: Icon(Icons.error, color: Colors.red),
                                ),
                              ),
                            )
                          : Container(
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: Icon(Icons.image, size: 40, color: Colors.grey),
                              ),
                            ),
                ),
              ),
            
            // Boutons pour gérer l'image
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectImageFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: Text(_selectedImageFile != null ? 'Changer l\'image' : 'Depuis la galerie'),
                  ),
                ),
                const SizedBox(width: 8),
                if (_selectedImageFile != null || _coverImageUrlController.text.isNotEmpty)
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedImageFile = null;
                        _coverImageUrlController.clear();
                      });
                    },
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Supprimer l\'image',
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Champ URL manuel (optionnel)
            TextFormField(
              controller: _coverImageUrlController,
              decoration: const InputDecoration(
                labelText: 'Ou entrer une URL d\'image',
                hintText: 'https://example.com/image.jpg',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              onChanged: (value) {
                setState(() {
                  if (value.isNotEmpty) {
                    _selectedImageFile = null; // Priorité à l'URL
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigurationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuration',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _orderController,
              decoration: const InputDecoration(
                labelText: 'Ordre d\'affichage',
                hintText: '1, 2, 3...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.sort),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final order = int.tryParse(value);
                  if (order == null || order < 0) {
                    return 'L\'ordre doit être un nombre positif';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(
                'Action active',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                _isActive 
                    ? 'L\'action est visible pour les membres'
                    : 'L\'action est masquée pour les membres',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
              activeColor: AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? finalCoverImageUrl = _coverImageUrlController.text.trim().isEmpty 
          ? null 
          : _coverImageUrlController.text.trim();

      // Si une nouvelle image a été sélectionnée, l'uploader
      if (_selectedImageFile != null) {
        final uploadedUrl = await ImageUploadService.uploadImage(
          file: _selectedImageFile!,
          folder: 'pour_vous_actions',
        );
        
        if (uploadedUrl != null) {
          finalCoverImageUrl = uploadedUrl;
        } else {
          throw Exception('Échec de l\'upload de l\'image');
        }
      }

      final order = int.tryParse(_orderController.text) ?? 0;
      
      final action = ActionItem(
        id: widget.action?.id ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        iconName: _selectedIcon,
        redirectUrl: _redirectType == 'url' && _redirectUrlController.text.trim().isNotEmpty
            ? _redirectUrlController.text.trim()
            : null,
        redirectRoute: _redirectType == 'route' && _redirectRouteController.text.trim().isNotEmpty
            ? _redirectRouteController.text.trim()
            : null,
        coverImageUrl: finalCoverImageUrl,
        isActive: _isActive,
        order: order,
        createdAt: widget.action?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: widget.action?.createdBy ?? FirebaseAuth.instance.currentUser?.uid,
      );

      if (widget.action == null) {
        await PourVousService.createAction(action);
      } else {
        await PourVousService.updateAction(widget.action!.id, action);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.action == null 
                  ? 'Action créée avec succès'
                  : 'Action mise à jour avec succès'
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'enregistrement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteAction() async {
    if (widget.action == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer l\'action "${widget.action!.title}" ?\n\n'
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await PourVousService.deleteAction(widget.action!.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Action supprimée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la suppression: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }
}
