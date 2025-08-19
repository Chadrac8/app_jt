import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/resource_item.dart';
import '../services/ressources_service.dart';
import 'resource_form_view.dart';
import '../../../models/app_config_model.dart';
import '../../../services/app_config_firebase_service.dart';
import '../../../services/image_upload_service.dart';

class RessourcesAdminView extends StatefulWidget {
  const RessourcesAdminView({Key? key}) : super(key: key);

  @override
  State<RessourcesAdminView> createState() => _RessourcesAdminViewState();
}

class _RessourcesAdminViewState extends State<RessourcesAdminView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Variables pour la configuration du module
  ModuleConfig? _moduleConfig;
  File? _selectedCoverImage;
  bool _isLoading = false;
  bool _showCoverImage = false;
  double _coverImageHeight = 200.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    RessourcesService.initializeDefaultResources();
    _loadModuleConfiguration();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Gestion des Ressources',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: 'Ressources', icon: Icon(Icons.library_books)),
            Tab(text: 'Statistiques', icon: Icon(Icons.analytics)),
            Tab(text: 'Configuration', icon: Icon(Icons.settings)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildResourcesTab(),
          _buildStatisticsTab(),
          _buildConfigurationTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewResource,
        backgroundColor: const Color(0xFF1565C0),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Nouvelle ressource',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildResourcesTab() {
    return StreamBuilder<List<ResourceItem>>(
      stream: RessourcesService.getAllResourcesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF1565C0),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Erreur lors du chargement',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        final resources = snapshot.data ?? [];

        return resources.isEmpty
            ? _buildEmptyState()
            : ReorderableListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: resources.length,
                onReorder: (oldIndex, newIndex) {
                  _reorderResources(resources, oldIndex, newIndex);
                },
                itemBuilder: (context, index) {
                  final resource = resources[index];
                  return _buildResourceListItem(resource, index);
                },
              );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_books_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune ressource configurée',
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Commencez par ajouter une nouvelle ressource',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceListItem(ResourceItem resource, int index) {
    return Card(
      key: ValueKey(resource.id),
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: resource.isActive
              ? const Color(0xFF1565C0)
              : Colors.grey[400],
          child: Icon(
            _getIconData(resource.iconName),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          resource.title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: resource.isActive ? Colors.black87 : Colors.grey[600],
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              resource.description,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(
                    resource.category,
                    style: const TextStyle(fontSize: 10),
                  ),
                  backgroundColor: Colors.grey[200],
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 8),
                if (resource.hasRedirect)
                  Icon(
                    resource.isExternalRedirect
                        ? Icons.open_in_new
                        : Icons.navigate_next,
                    size: 16,
                    color: Colors.grey[600],
                  ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: resource.isActive,
              onChanged: (value) => _toggleResourceStatus(resource.id, value),
              activeColor: const Color(0xFF1565C0),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) => _handleMenuAction(value, resource),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Modifier'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Supprimer', style: TextStyle(color: Colors.red)),
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

  Widget _buildStatisticsTab() {
    return StreamBuilder<List<ResourceItem>>(
      stream: RessourcesService.getAllResourcesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final resources = snapshot.data ?? [];
        final activeResources = resources.where((r) => r.isActive).length;
        final inactiveResources = resources.length - activeResources;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Statistiques des Ressources',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildStatCard(
                    'Total',
                    resources.length.toString(),
                    Icons.library_books,
                    const Color(0xFF1565C0),
                  ),
                  const SizedBox(width: 16),
                  _buildStatCard(
                    'Actives',
                    activeResources.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildStatCard(
                    'Inactives',
                    inactiveResources.toString(),
                    Icons.pause_circle,
                    Colors.orange,
                  ),
                  const SizedBox(width: 16),
                  _buildStatCard(
                    'Catégories',
                    _getCategoriesCount(resources).toString(),
                    Icons.category,
                    Colors.purple,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
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
      default:
        return Icons.library_books;
    }
  }

  int _getCategoriesCount(List<ResourceItem> resources) {
    return resources.map((r) => r.category).toSet().length;
  }

  void _reorderResources(List<ResourceItem> resources, int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    
    final reorderedResources = [...resources];
    final item = reorderedResources.removeAt(oldIndex);
    reorderedResources.insert(newIndex, item);
    
    RessourcesService.reorderResources(reorderedResources);
  }

  void _toggleResourceStatus(String id, bool isActive) async {
    final success = await RessourcesService.toggleResourceStatus(id, isActive);
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors du changement de statut'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleMenuAction(String action, ResourceItem resource) {
    switch (action) {
      case 'edit':
        _editResource(resource);
        break;
      case 'delete':
        _deleteResource(resource);
        break;
    }
  }

  void _addNewResource() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ResourceFormView(),
      ),
    );
  }

  void _editResource(ResourceItem resource) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResourceFormView(resource: resource),
      ),
    );
  }

  void _deleteResource(ResourceItem resource) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la ressource'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${resource.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await RessourcesService.deleteResource(resource.id);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ressource supprimée avec succès'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Erreur lors de la suppression'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Méthodes pour la configuration du module
  Future<void> _loadModuleConfiguration() async {
    try {
      final config = await AppConfigFirebaseService.getAppConfig();
      
      final moduleConfig = config.modules.firstWhere(
        (m) => m.route == 'ressources',
        orElse: () {
          return ModuleConfig(
            id: 'ressources',
            name: 'Ressources',
            description: 'Ressources spirituelles et de l\'église',
            iconName: 'library_books',
            route: 'ressources',
            category: 'ministry',
            isEnabledForMembers: true,
            isPrimaryInBottomNav: false,
            order: 0,
            isBuiltIn: true,
            coverImageUrl: null,
            showCoverImage: false,
            coverImageHeight: 200.0,
          );
        },
      );
      
      setState(() {
        _moduleConfig = moduleConfig;
        _showCoverImage = moduleConfig.showCoverImage;
        _coverImageHeight = moduleConfig.coverImageHeight;
      });
    } catch (e) {
      // Fallback avec configuration par défaut
      setState(() {
        _moduleConfig = ModuleConfig(
          id: 'ressources',
          name: 'Ressources',
          description: 'Ressources spirituelles et de l\'église',
          iconName: 'library_books',
          route: 'ressources',
          category: 'ministry',
          isEnabledForMembers: true,
          isPrimaryInBottomNav: false,
          order: 0,
          isBuiltIn: true,
          coverImageUrl: null,
          showCoverImage: false,
          coverImageHeight: 200.0,
        );
        _showCoverImage = false;
        _coverImageHeight = 200.0;
      });
      print('  - Fallback utilisé avec showCoverImage: false');
    }
  }

  Widget _buildConfigurationTab() {
    if (_moduleConfig == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1565C0)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.settings, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Configuration du Module Ressources',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),

          // Section Image de couverture
          _buildCoverImageSection(),
          
          const SizedBox(height: 32),

          // Bouton de sauvegarde
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveModuleConfiguration,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Sauvegarder la configuration',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverImageSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.image, color: Color(0xFF1565C0)),
              const SizedBox(width: 8),
              Text(
                'Image de couverture du module',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),

          // Switch pour activer/désactiver l'image de couverture
          Row(
            children: [
              Switch(
                value: _showCoverImage,
                onChanged: (value) {
                  setState(() {
                    _showCoverImage = value;
                  });
                },
                activeColor: const Color(0xFF1565C0),
              ),
              const SizedBox(width: 8),
              Text(
                'Afficher l\'image de couverture',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),

          if (_showCoverImage) ...[
            const SizedBox(height: 20),

            // Contrôle de hauteur d'image
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hauteur de l\'image (${_coverImageHeight.round()}px)',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Slider(
                  value: _coverImageHeight,
                  min: 100.0,
                  max: 400.0,
                  divisions: 30,
                  activeColor: const Color(0xFF1565C0),
                  inactiveColor: Colors.grey[300],
                  onChanged: (value) {
                    setState(() {
                      _coverImageHeight = value;
                    });
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '100px',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    Text(
                      '400px',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Aperçu de l'image actuelle ou sélectionnée
            if (_selectedCoverImage != null || _moduleConfig?.coverImageUrl != null)
              Container(
                height: _coverImageHeight,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _selectedCoverImage != null
                      ? Image.file(_selectedCoverImage!, fit: BoxFit.cover)
                      : _moduleConfig?.coverImageUrl != null
                          ? Image.network(
                              _moduleConfig!.coverImageUrl!,
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

            // Boutons pour gérer l'image
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _selectCoverImageFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Choisir une image'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                if (_selectedCoverImage != null || _moduleConfig?.coverImageUrl != null) ...[
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedCoverImage = null;
                        // Si on supprime l'image et qu'il n'y a pas d'image existante,
                        // désactiver l'affichage
                        if (_moduleConfig?.coverImageUrl == null) {
                          _showCoverImage = false;
                        }
                      });
                    },
                    icon: const Icon(Icons.delete),
                    color: Colors.red,
                    tooltip: 'Supprimer l\'image',
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _selectCoverImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedCoverImage = File(image.path);
          // Activer automatiquement l'affichage de l'image de couverture
          _showCoverImage = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image sélectionnée et affichage activé. N\'oubliez pas de sauvegarder.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sélection: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }  Future<void> _saveModuleConfiguration() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String? coverImageUrl = _moduleConfig?.coverImageUrl;

      // Upload de la nouvelle image si sélectionnée
      if (_selectedCoverImage != null) {
        // Vérifier que le fichier existe
        if (!await _selectedCoverImage!.exists()) {
          throw Exception('Le fichier sélectionné n\'existe pas');
        }
        
        // Supprimer l'ancienne image si elle existe
        if (_moduleConfig?.coverImageUrl != null) {
          await ImageUploadService.deleteImage(_moduleConfig!.coverImageUrl!);
        }
        
        // Upload de la nouvelle image
        final uploadResult = await ImageUploadService.uploadImage(
          file: _selectedCoverImage!,
          folder: 'modules',
          fileName: 'ressources_cover_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        
        if (uploadResult != null) {
          coverImageUrl = uploadResult;
        } else {
          throw Exception('Échec de l\'upload de l\'image');
        }
      }

      // Sauvegarder dans Firebase
      await AppConfigFirebaseService.updateModuleConfig(
        _moduleConfig!.id,
        coverImageUrl: coverImageUrl,
        showCoverImage: _showCoverImage,
        coverImageHeight: _coverImageHeight,
      );

      // Attendre un peu avant de recharger
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Recharger la configuration
      final bool savedShowCoverImage = _showCoverImage;
      
      await _loadModuleConfiguration();
      
      // Vérifier si la valeur rechargée correspond à ce qu'on vient de sauvegarder
      if (_moduleConfig?.showCoverImage != savedShowCoverImage) {
        setState(() {
          _showCoverImage = savedShowCoverImage;
        });
      }

      setState(() {
        _selectedCoverImage = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuration sauvegardée avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
