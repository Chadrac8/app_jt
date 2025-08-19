import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/resource_item.dart';
import '../services/ressources_service.dart';

class ResourceFormView extends StatefulWidget {
  final ResourceItem? resource;

  const ResourceFormView({Key? key, this.resource}) : super(key: key);

  @override
  State<ResourceFormView> createState() => _ResourceFormViewState();
}

class _ResourceFormViewState extends State<ResourceFormView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _redirectUrlController = TextEditingController();
  final _redirectRouteController = TextEditingController();
  final _coverImageUrlController = TextEditingController();

  String _selectedIcon = 'library_books';
  String _selectedCategory = 'general';
  bool _isActive = true;
  bool _isLoading = false;
  String _redirectType = 'route'; // 'route' ou 'url'
  File? _selectedImageFile;
  String? _selectedModuleRoute;

  final List<String> _availableIcons = [
    'library_books',
    'menu_book',
    'campaign',
    'library_music',
    'church',
    'school',
    'video_library',
    'audio_file',
    'article',
    'help',
    'favorite',
    'groups',
    'event',
    'assignment',
    'task_alt',
    'notifications',
    'settings',
    'web',
    'dashboard',
    'prayer_hands',
    'bar_chart',
    'list_alt',
    'self_improvement',
    'psychology',
    'healing',
    'celebration',
    'volunteer_activism',
  ];

  final List<String> _availableCategories = [
    'general',
    'spiritual',
    'worship',
    'church',
    'education',
    'media',
  ];

  // Routes des modules disponibles pour la redirection
  final Map<String, String> _availableModuleRoutes = {
    'Accueil': '/member/dashboard',
    'Mes groupes': '/member/groups',
    'Événements': '/member/events',
    'Services/Cultes': '/member/services',
    'Formulaires': '/member/forms',
    'Tâches': '/member/tasks',
    'La Bible': '/member/bible',
    'Cantiques': '/member/songs',
    'Le Message': '/member/message',
    'Pour Vous': '/member/pour-vous',
    'Mur de prière': '/member/prayer-wall',
    'Calendrier': '/member/calendar',
    'Notifications': '/member/notifications',
    'Mon profil': '/member/profile',
    'Rendez-vous': '/member/appointments',
    'Listes dynamiques': '/member/dynamic-lists',
    'Blog': '/member/blog',
    'Pages personnalisées': '/member/pages',
  };

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.resource != null) {
      final resource = widget.resource!;
      _titleController.text = resource.title;
      _descriptionController.text = resource.description;
      _selectedIcon = resource.iconName;
      _selectedCategory = resource.category;
      _isActive = resource.isActive;
      _coverImageUrlController.text = resource.coverImageUrl ?? '';
      
      if (resource.redirectUrl != null) {
        _redirectType = 'url';
        _redirectUrlController.text = resource.redirectUrl!;
      } else if (resource.redirectRoute != null) {
        _redirectType = 'route';
        _selectedModuleRoute = resource.redirectRoute!;
        _redirectRouteController.text = resource.redirectRoute!;
      }
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
          // Ne pas mettre le chemin local dans le controller
          // L'image sera uploadée lors de la sauvegarde
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.resource == null ? 'Nouvelle Ressource' : 'Modifier Ressource',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveResource,
              child: Text(
                'Sauvegarder',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Informations générales'),
              _buildTextFormField(
                controller: _titleController,
                label: 'Titre de la ressource',
                hint: 'Ex: Lire la Bible',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le titre est obligatoire';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Décrivez cette ressource...',
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La description est obligatoire';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              _buildSectionTitle('Apparence'),
              _buildIconSelector(),
              const SizedBox(height: 16),
              _buildCategorySelector(),
              const SizedBox(height: 16),
              _buildCoverImageSelector(),
              const SizedBox(height: 24),
              
              _buildSectionTitle('Redirection'),
              _buildRedirectTypeSelector(),
              const SizedBox(height: 16),
              if (_redirectType == 'url')
                _buildTextFormField(
                  controller: _redirectUrlController,
                  label: 'URL de redirection',
                  hint: 'https://exemple.com',
                )
              else
                _buildModuleRouteSelector(),
              const SizedBox(height: 24),
              
              _buildSectionTitle('Options'),
              _buildActiveSwitch(),
              const SizedBox(height: 32),
              
              _buildPreview(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1565C0),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildIconSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Icône',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _availableIcons.length,
            itemBuilder: (context, index) {
              final iconName = _availableIcons[index];
              final isSelected = iconName == _selectedIcon;
              
              return GestureDetector(
                onTap: () => setState(() => _selectedIcon = iconName),
                child: Container(
                  width: 60,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF1565C0) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF1565C0) : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    _getIconData(iconName),
                    color: isSelected ? Colors.white : const Color(0xFF1565C0),
                    size: 24,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'Catégorie',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      items: _availableCategories.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Text(_getCategoryDisplayName(category)),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedCategory = value!),
    );
  }

  Widget _buildRedirectTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type de redirection',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Route interne'),
                value: 'route',
                groupValue: _redirectType,
                onChanged: (value) => setState(() => _redirectType = value!),
                activeColor: const Color(0xFF1565C0),
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('URL externe'),
                value: 'url',
                groupValue: _redirectType,
                onChanged: (value) => setState(() => _redirectType = value!),
                activeColor: const Color(0xFF1565C0),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActiveSwitch() {
    return Row(
      children: [
        Text(
          'Ressource active',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Switch(
          value: _isActive,
          onChanged: (value) => setState(() => _isActive = value),
          activeColor: const Color(0xFF1565C0),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aperçu',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1565C0),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[100],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getIconData(_selectedIcon),
                    size: 32,
                    color: _isActive ? const Color(0xFF1565C0) : Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _titleController.text.isEmpty ? 'Titre de la ressource' : _titleController.text,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _isActive ? Colors.black87 : Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _descriptionController.text.isEmpty ? 'Description...' : _descriptionController.text,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'menu_book':
        return Icons.menu_book;
      case 'campaign':
        return Icons.campaign;
      case 'library_music':
        return Icons.library_music;
      case 'church':
        return Icons.church;
      case 'school':
        return Icons.school;
      case 'video_library':
        return Icons.video_library;
      case 'audio_file':
        return Icons.audio_file;
      case 'article':
        return Icons.article;
      case 'help':
        return Icons.help;
      default:
        return Icons.library_books;
    }
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'spiritual':
        return 'Spirituel';
      case 'worship':
        return 'Louange';
      case 'church':
        return 'Église';
      case 'education':
        return 'Éducation';
      case 'media':
        return 'Média';
      default:
        return 'Général';
    }
  }

  void _saveResource() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final resource = ResourceItem(
        id: widget.resource?.id ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        iconName: _selectedIcon,
        redirectUrl: _redirectType == 'url' ? _redirectUrlController.text.trim() : null,
        redirectRoute: _redirectType == 'route' ? _redirectRouteController.text.trim() : null,
        coverImageUrl: widget.resource?.coverImageUrl, // Garder l'ancienne URL pour les mises à jour
        isActive: _isActive,
        category: _selectedCategory,
        order: widget.resource?.order ?? 0,
        createdAt: widget.resource?.createdAt ?? now,
        updatedAt: now,
      );

      bool success;
      if (widget.resource == null) {
        // Création d'une nouvelle ressource
        final id = await RessourcesService.createResourceWithImage(
          resource: resource,
          imageFile: _selectedImageFile,
        );
        success = id != null;
      } else {
        // Mise à jour d'une ressource existante
        success = await RessourcesService.updateResourceWithImage(
          resource: resource,
          newImageFile: _selectedImageFile,
        );
      }

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.resource == null 
                  ? 'Ressource créée avec succès' 
                  : 'Ressource mise à jour avec succès',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la sauvegarde'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Widget pour la sélection d'image de couverture
  Widget _buildCoverImageSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Image de couverture',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        
        // Aperçu de l'image si disponible
        if (_selectedImageFile != null || widget.resource?.coverImageUrl != null || _coverImageUrlController.text.isNotEmpty)
          Container(
            height: 120,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _selectedImageFile != null
                  ? Image.file(_selectedImageFile!, fit: BoxFit.cover)
                  : widget.resource?.coverImageUrl != null
                      ? Image.network(
                          widget.resource!.coverImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image, size: 50),
                            );
                          },
                        )
                      : _coverImageUrlController.text.isNotEmpty
                          ? Image.network(
                              _coverImageUrlController.text,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.broken_image, size: 50),
                                );
                              },
                            )
                      : Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.image, size: 50),
                        ),
            ),
          ),
        
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _coverImageUrlController,
                decoration: InputDecoration(
                  labelText: 'URL de l\'image',
                  hintText: 'https://exemple.com/image.jpg',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.link),
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _selectImageFromGallery,
              icon: const Icon(Icons.photo_library),
              label: const Text('Galerie'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            if (_selectedImageFile != null || widget.resource?.coverImageUrl != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedImageFile = null;
                    _coverImageUrlController.clear();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Image supprimée'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
                icon: const Icon(Icons.delete),
                color: Colors.red,
                tooltip: 'Supprimer l\'image',
              ),
            ],
          ],
        ),
      ],
    );
  }

  /// Widget pour la sélection de route de module
  Widget _buildModuleRouteSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Module de destination',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedModuleRoute,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: const Icon(Icons.route),
            hintText: 'Choisir un module...',
          ),
          items: _availableModuleRoutes.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.value,
              child: Row(
                children: [
                  Icon(_getIconForRoute(entry.value), size: 20),
                  const SizedBox(width: 8),
                  Text(entry.key),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedModuleRoute = value;
              _redirectRouteController.text = value ?? '';
            });
          },
          validator: (value) {
            if (_redirectType == 'route' && (value == null || value.isEmpty)) {
              return 'Veuillez sélectionner un module';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Route: ${_selectedModuleRoute ?? "Aucune sélection"}',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// Obtenir l'icône pour une route donnée
  IconData _getIconForRoute(String route) {
    switch (route) {
      case '/member/dashboard':
        return Icons.dashboard;
      case '/member/groups':
        return Icons.groups;
      case '/member/events':
        return Icons.event;
      case '/member/services':
        return Icons.church;
      case '/member/forms':
        return Icons.assignment;
      case '/member/tasks':
        return Icons.task_alt;
      case '/member/bible':
        return Icons.menu_book;
      case '/member/songs':
        return Icons.library_music;
      case '/member/message':
        return Icons.campaign;
      case '/member/pour-vous':
        return Icons.auto_awesome;
      case '/member/prayer-wall':
        return Icons.favorite;
      case '/member/calendar':
        return Icons.calendar_today;
      case '/member/notifications':
        return Icons.notifications;
      case '/member/profile':
        return Icons.person;
      case '/member/appointments':
        return Icons.event_available;
      case '/member/dynamic-lists':
        return Icons.list_alt;
      case '/member/blog':
        return Icons.article;
      case '/member/pages':
        return Icons.web;
      default:
        return Icons.apps;
    }
  }
}
