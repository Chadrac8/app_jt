import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme.dart';
import '../models/pour_vous_action.dart';
import '../services/pour_vous_action_service.dart';

class AdminPourVousTab extends StatefulWidget {
  const AdminPourVousTab({Key? key}) : super(key: key);

  @override
  State<AdminPourVousTab> createState() => _AdminPourVousTabState();
}

class _AdminPourVousTabState extends State<AdminPourVousTab> {
  final PourVousActionService _actionService = PourVousActionService();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _ensureDefaultActions();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _ensureDefaultActions() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    
    await _actionService.ensureDefaultActionsExist();
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading ? _buildLoadingWidget() : _buildContent(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddActionDialog,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.settings,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Gestion des actions "Pour vous"',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              // Boutons d'actions rapides
              IconButton(
                icon: const Icon(Icons.file_download),
                onPressed: _exportActions,
                tooltip: 'Exporter',
                color: AppTheme.primaryColor,
              ),
              IconButton(
                icon: const Icon(Icons.file_upload),
                onPressed: _importActions,
                tooltip: 'Importer',
                color: AppTheme.primaryColor,
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _refreshActions,
                tooltip: 'Actualiser',
                color: AppTheme.primaryColor,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Configurez les actions disponibles pour les membres',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 16),
          // Barre de recherche
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher une action...',
              hintStyle: GoogleFonts.poppins(color: Colors.grey),
              prefixIcon: Icon(Icons.search, color: AppTheme.primaryColor),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primaryColor),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: GoogleFonts.poppins(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildContent() {
    return StreamBuilder<List<PourVousAction>>(
      stream: _actionService.getAllActions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingWidget();
        }

        if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error.toString());
        }

        final allActions = snapshot.data ?? [];
        
        // Filtrer les actions selon la recherche
        final filteredActions = _searchQuery.isEmpty
            ? allActions
            : allActions.where((action) {
                return action.title.toLowerCase().contains(_searchQuery) ||
                       action.description.toLowerCase().contains(_searchQuery) ||
                       action.actionType.toLowerCase().contains(_searchQuery);
              }).toList();

        if (filteredActions.isEmpty) {
          return _searchQuery.isNotEmpty 
              ? _buildNoResultsWidget()
              : _buildEmptyWidget();
        }

        return Column(
          children: [
            _buildStatsCard(allActions),
            if (_searchQuery.isNotEmpty) _buildSearchResultsHeader(filteredActions.length, allActions.length),
            Expanded(
              child: _buildActionsList(filteredActions),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsCard(List<PourVousAction> actions) {
    final activeCount = actions.where((a) => a.isActive).length;
    final inactiveCount = actions.length - activeCount;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Total',
              actions.length.toString(),
              Icons.list,
              AppTheme.primaryColor,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.shade300,
          ),
          Expanded(
            child: _buildStatItem(
              'Actives',
              activeCount.toString(),
              Icons.check_circle,
              Colors.green,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.shade300,
          ),
          Expanded(
            child: _buildStatItem(
              'Inactives',
              inactiveCount.toString(),
              Icons.pause_circle,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildActionsList(List<PourVousAction> actions) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: actions.length,
      onReorder: (oldIndex, newIndex) => _reorderActions(actions, oldIndex, newIndex),
      itemBuilder: (context, index) {
        final action = actions[index];
        return _buildActionCard(action, index);
      },
    );
  }

  Widget _buildActionCard(PourVousAction action, int index) {
    final color = action.color != null 
        ? Color(int.parse(action.color!.replaceFirst('#', '0xFF')))
        : AppTheme.primaryColor;

    return Card(
      key: ValueKey(action.id),
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            action.icon,
            color: color,
            size: 24,
          ),
        ),
        title: Text(
          action.title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              action.description,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: action.isActive ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    action.isActive ? 'Active' : 'Inactive',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: action.isActive ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    action.actionType,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                action.isActive ? Icons.pause : Icons.play_arrow,
                color: action.isActive ? Colors.orange : Colors.green,
              ),
              onPressed: () => _toggleActionStatus(action),
              tooltip: action.isActive ? 'Désactiver' : 'Activer',
            ),
            IconButton(
              icon: Icon(Icons.edit, color: AppTheme.primaryColor),
              onPressed: () => _showEditActionDialog(action),
              tooltip: 'Modifier',
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
              onSelected: (value) {
                switch (value) {
                  case 'preview':
                    _previewAction(action);
                    break;
                  case 'duplicate':
                    _duplicateAction(action);
                    break;
                  case 'delete':
                    _confirmDeleteAction(action);
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'preview',
                  child: Row(
                    children: [
                      const Icon(Icons.visibility, size: 20),
                      const SizedBox(width: 8),
                      Text('Prévisualiser', style: GoogleFonts.poppins()),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'duplicate',
                  child: Row(
                    children: [
                      const Icon(Icons.copy, size: 20),
                      const SizedBox(width: 8),
                      Text('Dupliquer', style: GoogleFonts.poppins()),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete, size: 20, color: Colors.red),
                      const SizedBox(width: 8),
                      Text('Supprimer', style: GoogleFonts.poppins(color: Colors.red)),
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

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: AppTheme.textSecondaryColor.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune action configurée',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez votre première action',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _actionService.initializeDefaultActions(),
            icon: const Icon(Icons.refresh),
            label: Text(
              'Créer les actions par défaut',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _reorderActions(List<PourVousAction> actions, int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final action = actions.removeAt(oldIndex);
    actions.insert(newIndex, action);

    _actionService.updateActionsOrder(actions);
  }

  Future<void> _toggleActionStatus(PourVousAction action) async {
    final success = await _actionService.toggleActionStatus(action.id, !action.isActive);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            action.isActive ? 'Action désactivée' : 'Action activée',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    }
  }

  void _confirmDeleteAction(PourVousAction action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Supprimer l\'action',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${action.title}" ?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Annuler',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteAction(action);
            },
            child: Text(
              'Supprimer',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAction(PourVousAction action) async {
    final success = await _actionService.deleteAction(action.id);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Action supprimée',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddActionDialog() {
    _showActionFormDialog();
  }

  void _showActionFormDialog([PourVousAction? existingAction]) {
    final titleController = TextEditingController(text: existingAction?.title ?? '');
    final descriptionController = TextEditingController(text: existingAction?.description ?? '');
    final targetModuleController = TextEditingController(text: existingAction?.targetModule ?? '');
    final targetRouteController = TextEditingController(text: existingAction?.targetRoute ?? '');
    final colorController = TextEditingController(text: existingAction?.color ?? '');
    
    IconData selectedIcon = existingAction?.icon ?? Icons.help_outline;
    String selectedActionType = existingAction?.actionType ?? 'navigation';
    bool isActive = existingAction?.isActive ?? true;
    int order = existingAction?.order ?? 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
              existingAction == null ? 'Ajouter une action' : 'Modifier l\'action',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Titre
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Titre de l\'action',
                        labelStyle: GoogleFonts.poppins(),
                        border: const OutlineInputBorder(),
                      ),
                      style: GoogleFonts.poppins(),
                    ),
                    const SizedBox(height: 16),
                    
                    // Description
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        labelStyle: GoogleFonts.poppins(),
                        border: const OutlineInputBorder(),
                      ),
                      style: GoogleFonts.poppins(),
                    ),
                    const SizedBox(height: 16),
                    
                    // Type d'action
                    DropdownButtonFormField<String>(
                      value: selectedActionType,
                      decoration: InputDecoration(
                        labelText: 'Type d\'action',
                        labelStyle: GoogleFonts.poppins(),
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(value: 'navigation', child: Text('Navigation', style: GoogleFonts.poppins())),
                        DropdownMenuItem(value: 'form', child: Text('Formulaire', style: GoogleFonts.poppins())),
                        DropdownMenuItem(value: 'external', child: Text('Lien externe', style: GoogleFonts.poppins())),
                        DropdownMenuItem(value: 'action', child: Text('Action directe', style: GoogleFonts.poppins())),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedActionType = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Module cible (si navigation)
                    if (selectedActionType == 'navigation') ...[
                      TextField(
                        controller: targetModuleController,
                        decoration: InputDecoration(
                          labelText: 'Module cible',
                          labelStyle: GoogleFonts.poppins(),
                          border: const OutlineInputBorder(),
                          hintText: 'Ex: bible, message, songs',
                        ),
                        style: GoogleFonts.poppins(),
                      ),
                      const SizedBox(height: 16),
                      
                      TextField(
                        controller: targetRouteController,
                        decoration: InputDecoration(
                          labelText: 'Route cible (optionnel)',
                          labelStyle: GoogleFonts.poppins(),
                          border: const OutlineInputBorder(),
                          hintText: 'Ex: /bible/search',
                        ),
                        style: GoogleFonts.poppins(),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Sélection d'icône
                    Row(
                      children: [
                        Text('Icône: ', style: GoogleFonts.poppins()),
                        IconButton(
                          onPressed: () => _showIconPicker(setDialogState, (icon) {
                            selectedIcon = icon;
                          }),
                          icon: Icon(selectedIcon, color: AppTheme.primaryColor),
                        ),
                        const Spacer(),
                        Text('Ordre: ', style: GoogleFonts.poppins()),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            ),
                            style: GoogleFonts.poppins(),
                            onChanged: (value) {
                              order = int.tryParse(value) ?? 0;
                            },
                            controller: TextEditingController(text: order.toString()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Couleur
                    TextField(
                      controller: colorController,
                      decoration: InputDecoration(
                        labelText: 'Couleur (hex)',
                        labelStyle: GoogleFonts.poppins(),
                        border: const OutlineInputBorder(),
                        hintText: '#FF5722',
                      ),
                      style: GoogleFonts.poppins(),
                    ),
                    const SizedBox(height: 16),
                    
                    // Status actif/inactif
                    Row(
                      children: [
                        Text('Statut: ', style: GoogleFonts.poppins()),
                        Switch(
                          value: isActive,
                          onChanged: (value) {
                            setDialogState(() {
                              isActive = value;
                            });
                          },
                          activeColor: AppTheme.primaryColor,
                        ),
                        Text(
                          isActive ? 'Active' : 'Inactive',
                          style: GoogleFonts.poppins(
                            color: isActive ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Annuler',
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Le titre est obligatoire',
                          style: GoogleFonts.poppins(),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  
                  await _saveAction(
                    existingAction,
                    titleController.text.trim(),
                    descriptionController.text.trim(),
                    selectedIcon,
                    selectedActionType,
                    targetModuleController.text.trim(),
                    targetRouteController.text.trim(),
                    colorController.text.trim(),
                    isActive,
                    order,
                  );
                  
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: Text(
                  existingAction == null ? 'Ajouter' : 'Modifier',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditActionDialog(PourVousAction action) {
    _showActionFormDialog(action);
  }

  void _showIconPicker(StateSetter setDialogState, Function(IconData) onIconSelected) {
    final List<IconData> availableIcons = [
      Icons.home, Icons.person, Icons.church, Icons.book, Icons.music_note,
      Icons.event, Icons.group, Icons.favorite, Icons.star, Icons.settings,
      Icons.info, Icons.help, Icons.phone, Icons.email, Icons.web,
      Icons.play_arrow, Icons.pause, Icons.stop, Icons.download, Icons.share,
      Icons.bookmark, Icons.search, Icons.filter_list, Icons.calendar_today,
      Icons.location_on, Icons.notifications, Icons.camera, Icons.photo,
      Icons.video_call, Icons.mic, Icons.headphones, Icons.library_books,
      Icons.school, Icons.work, Icons.business, Icons.local_hospital,
      Icons.restaurant, Icons.shopping_cart, Icons.fitness_center, Icons.spa,
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Choisir une icône',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SizedBox(
          width: 300,
          height: 400,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: availableIcons.length,
            itemBuilder: (context, index) {
              final icon = availableIcons[index];
              return InkWell(
                onTap: () {
                  onIconSelected(icon);
                  setDialogState(() {});
                  Navigator.of(context).pop();
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppTheme.primaryColor),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Fermer',
              style: GoogleFonts.poppins(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAction(
    PourVousAction? existingAction,
    String title,
    String description,
    IconData icon,
    String actionType,
    String targetModule,
    String targetRoute,
    String color,
    bool isActive,
    int order,
  ) async {
    try {
      setState(() => _isLoading = true);

      final now = DateTime.now();

      if (existingAction != null) {
        // Modification
        final updatedAction = PourVousAction(
          id: existingAction.id,
          title: title,
          description: description,
          icon: icon,
          iconCodePoint: icon.codePoint.toString(),
          actionType: actionType,
          targetModule: targetModule.isNotEmpty ? targetModule : null,
          targetRoute: targetRoute.isNotEmpty ? targetRoute : null,
          color: color.isNotEmpty ? color : null,
          isActive: isActive,
          order: order,
          createdAt: existingAction.createdAt,
          updatedAt: now,
          createdBy: existingAction.createdBy,
        );
        
        await _actionService.updateAction(existingAction.id, updatedAction);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Action modifiée avec succès',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Création
        final newAction = PourVousAction(
          id: '', // Sera généré par Firestore
          title: title,
          description: description,
          icon: icon,
          iconCodePoint: icon.codePoint.toString(),
          actionType: actionType,
          targetModule: targetModule.isNotEmpty ? targetModule : null,
          targetRoute: targetRoute.isNotEmpty ? targetRoute : null,
          color: color.isNotEmpty ? color : null,
          isActive: isActive,
          order: order,
          createdAt: now,
          updatedAt: now,
          createdBy: 'admin', // TODO: Utiliser l'utilisateur connecté
        );
        
        await _actionService.addAction(newAction);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Action créée avec succès',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur: ${e.toString()}',
              style: GoogleFonts.poppins(),
            ),
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

  // Nouvelles méthodes pour les fonctionnalités supplémentaires

  Widget _buildNoResultsWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
          Text(
            'Aucun résultat trouvé',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Essayez d\'autres mots-clés',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              _searchController.clear();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: Text(
              'Effacer la recherche',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultsHeader(int filteredCount, int totalCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.search, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 8),
          Text(
            '$filteredCount résultat${filteredCount > 1 ? 's' : ''} sur $totalCount',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              _searchController.clear();
            },
            child: Text(
              'Tout voir',
              style: GoogleFonts.poppins(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportActions() async {
    try {
      setState(() => _isLoading = true);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Fonction d\'export en cours de développement',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _importActions() async {
    try {
      setState(() => _isLoading = true);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Fonction d\'import en cours de développement',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshActions() async {
    try {
      setState(() => _isLoading = true);
      await _ensureDefaultActions();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Actions actualisées',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _duplicateAction(PourVousAction action) {
    final duplicatedAction = PourVousAction(
      id: '', // Sera généré par Firestore
      title: '${action.title} (copie)',
      description: action.description,
      icon: action.icon,
      iconCodePoint: action.iconCodePoint,
      actionType: action.actionType,
      targetModule: action.targetModule,
      targetRoute: action.targetRoute,
      color: action.color,
      isActive: false, // Désactivée par défaut
      order: action.order + 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: 'admin',
    );

    _showActionFormDialog(duplicatedAction);
  }

  void _previewAction(PourVousAction action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(action.icon, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(
              'Prévisualisation',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPreviewCard(action),
            const SizedBox(height: 16),
            Text(
              'Informations techniques:',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Type:', action.actionType),
            if (action.targetModule != null) _buildInfoRow('Module:', action.targetModule!),
            if (action.targetRoute != null) _buildInfoRow('Route:', action.targetRoute!),
            _buildInfoRow('Ordre:', action.order.toString()),
            _buildInfoRow('Statut:', action.isActive ? 'Active' : 'Inactive'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Fermer',
              style: GoogleFonts.poppins(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(PourVousAction action) {
    final color = action.color != null 
        ? Color(int.parse(action.color!.replaceFirst('#', '0xFF')))
        : AppTheme.primaryColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              action.icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action.title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  action.description,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppTheme.textSecondaryColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
