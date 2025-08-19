import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../theme.dart';
import '../../../models/app_config_model.dart';
import '../../../services/app_config_firebase_service.dart';
import '../../../services/image_upload_service.dart';
import '../models/action_item.dart';
import '../services/pour_vous_service.dart';
import 'action_form_view.dart';
import 'requests_list_view.dart';

class PourVousAdminView extends StatefulWidget {
  const PourVousAdminView({super.key});

  @override
  State<PourVousAdminView> createState() => _PourVousAdminViewState();
}

class _PourVousAdminViewState extends State<PourVousAdminView>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  ModuleConfig? _moduleConfig;
  bool _isLoading = true;
  double _coverImageHeight = 200.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
    _loadModuleConfig();
  }

  void _loadModuleConfig() async {
    try {
      final appConfig = await AppConfigFirebaseService.getAppConfig();
      final config = appConfig.modules.firstWhere(
        (module) => module.id == 'pour_vous',
        orElse: () => ModuleConfig(
          id: 'pour_vous',
          name: 'Pour vous',
          description: 'Module Pour vous',
          iconName: 'favorite',
          route: '/pour-vous',
          category: 'core',
          isEnabledForMembers: true,
          isPrimaryInBottomNav: true,
          order: 1,
          isBuiltIn: true,
          coverImageUrl: null,
          showCoverImage: false,
          coverImageHeight: 200.0,
        ),
      );
      setState(() {
        _moduleConfig = config;
        _coverImageHeight = config.coverImageHeight;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Pour vous - Administration',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.apps), text: 'Actions'),
            Tab(icon: Icon(Icons.list), text: 'Demandes'),
            Tab(icon: Icon(Icons.settings), text: 'Configuration'),
          ],
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: TabBarView(
          controller: _tabController,
          children: [
            _ActionsTab(),
            RequestsListView(),
            _buildConfigurationTab(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewAction,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildConfigurationTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCoverImageSection(),
        ],
      ),
    );
  }

  Widget _buildCoverImageSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.image, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Image de couverture',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Switch pour activer/désactiver l'image de couverture
            Row(
              children: [
                Switch(
                  value: _moduleConfig?.showCoverImage ?? false,
                  onChanged: (value) {
                    setState(() {
                      _saveModuleConfiguration(showCoverImage: value);
                    });
                  },
                  activeColor: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Afficher l\'image de couverture',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
            
            if (_moduleConfig?.showCoverImage == true) ...[
              const SizedBox(height: 16),
              
              // Hauteur de l'image
              Text(
                'Hauteur de l\'image: ${_coverImageHeight.round()}px',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Slider(
                value: _coverImageHeight,
                min: 100,
                max: 400,
                divisions: 30,
                activeColor: AppTheme.primaryColor,
                onChanged: (value) {
                  setState(() {
                    _coverImageHeight = value;
                  });
                },
                onChangeEnd: (value) {
                  _saveModuleConfiguration(coverImageHeight: value);
                },
              ),
              const SizedBox(height: 16),
              
              // Aperçu de l'image actuelle
              if (_moduleConfig?.coverImageUrl != null && _moduleConfig!.coverImageUrl!.isNotEmpty)
                Container(
                  width: double.infinity,
                  height: _coverImageHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: _moduleConfig!.coverImageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade200,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade200,
                        child: const Center(child: Icon(Icons.error)),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  height: _coverImageHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                    color: Colors.grey.shade100,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_outlined, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        'Aucune image sélectionnée',
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Boutons pour gérer l'image
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _selectCoverImage,
                      icon: const Icon(Icons.upload),
                      label: Text(_moduleConfig?.coverImageUrl != null && _moduleConfig!.coverImageUrl!.isNotEmpty 
                          ? 'Changer l\'image' 
                          : 'Sélectionner une image'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  if (_moduleConfig?.coverImageUrl != null && _moduleConfig!.coverImageUrl!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _removeCoverImage,
                      icon: const Icon(Icons.delete),
                      label: const Text('Supprimer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _selectCoverImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        final File file = File(image.path);
        final imageUrl = await ImageUploadService.uploadImage(
          file: file,
          folder: 'module_covers',
        );
        
        if (imageUrl != null) {
          _saveModuleConfiguration(coverImageUrl: imageUrl);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du téléchargement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeCoverImage() async {
    _saveModuleConfiguration(coverImageUrl: '');
  }

  void _saveModuleConfiguration({
    String? coverImageUrl,
    bool? showCoverImage,
    double? coverImageHeight,
  }) async {
    try {
      await AppConfigFirebaseService.updateModuleConfig(
        'pour_vous',
        coverImageUrl: coverImageUrl,
        showCoverImage: showCoverImage,
        coverImageHeight: coverImageHeight,
      );
      
      // Recharger la configuration
      _loadModuleConfig();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuration mise à jour avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sauvegarde: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addNewAction() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ActionFormView(),
      ),
    );
  }
}

class _ActionsTab extends StatefulWidget {
  @override
  State<_ActionsTab> createState() => __ActionsTabState();
}

class __ActionsTabState extends State<_ActionsTab> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ActionItem>>(
      stream: PourVousService.getAllActionsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'Erreur de chargement',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Détail: ${snapshot.error}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        final actions = snapshot.data ?? [];

        if (actions.isEmpty) {
          return _buildEmptyState();
        }

        return _buildActionsList(actions);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_outline,
            size: 80,
            color: AppTheme.primaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'Aucune action configurée',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Créez votre première action pour les membres.',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _addNewAction(context),
            icon: const Icon(Icons.add),
            label: const Text('Créer une action'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsList(List<ActionItem> actions) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return _buildActionCard(action);
      },
    );
  }

  Widget _buildActionCard(ActionItem action) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _editAction(action),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Image de couverture ou icône
                  if (action.coverImageUrl != null && action.coverImageUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: action.coverImageUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 60,
                          height: 60,
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => _buildIconContainer(action),
                      ),
                    )
                  else
                    _buildIconContainer(action),

                  const SizedBox(width: 16),

                  // Titre et description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                action.title,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimaryColor,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: action.isActive 
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                action.isActive ? 'Actif' : 'Inactif',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: action.isActive ? Colors.green : Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          action.description,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppTheme.textSecondaryColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.sort,
                              size: 16,
                              color: AppTheme.textSecondaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Ordre: ${action.order}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.link,
                              size: 16,
                              color: AppTheme.textSecondaryColor,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                action.redirectRoute ?? action.redirectUrl ?? 'Aucune',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppTheme.textSecondaryColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Actions
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleActionMenu(value, action),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Modifier'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(
                              action.isActive ? Icons.visibility_off : Icons.visibility,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(action.isActive ? 'Désactiver' : 'Activer'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Supprimer', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconContainer(ActionItem action) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        _getIconData(action.iconName),
        size: 30,
        color: AppTheme.primaryColor,
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'prayer':
        return Icons.favorite_outline;
      case 'water_drop':
        return Icons.water_drop;
      case 'groups':
        return Icons.groups;
      case 'schedule':
        return Icons.schedule;
      case 'help':
        return Icons.help_outline;
      case 'lightbulb':
        return Icons.lightbulb_outline;
      case 'phone':
        return Icons.phone;
      case 'email':
        return Icons.email;
      case 'question_answer':
        return Icons.question_answer;
      case 'volunteer_activism':
        return Icons.volunteer_activism;
      default:
        return Icons.help_outline;
    }
  }

  void _addNewAction(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ActionFormView(),
      ),
    );
  }

  void _editAction(ActionItem action) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ActionFormView(action: action),
      ),
    );
  }

  void _handleActionMenu(String value, ActionItem action) async {
    switch (value) {
      case 'edit':
        _editAction(action);
        break;
      case 'toggle':
        try {
          await PourVousService.updateAction(
            action.id,
            action.copyWith(isActive: !action.isActive),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                action.isActive 
                    ? 'Action désactivée avec succès'
                    : 'Action activée avec succès'
              ),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la modification: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        break;
      case 'delete':
        _confirmDelete(action);
        break;
    }
  }

  void _confirmDelete(ActionItem action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer l\'action "${action.title}" ?\n\n'
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await PourVousService.deleteAction(action.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Action supprimée avec succès'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur lors de la suppression: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
