import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme.dart';
import '../models/pour_vous_action.dart';
import '../models/action_group.dart';
import '../services/pour_vous_action_service.dart';
import '../services/action_group_service.dart';

class AdminPourVousTab extends StatefulWidget {
  const AdminPourVousTab({Key? key}) : super(key: key);

  @override
  State<AdminPourVousTab> createState() => _AdminPourVousTabState();
}

class _AdminPourVousTabState extends State<AdminPourVousTab>
    with TickerProviderStateMixin {
  final PourVousActionService _actionService = PourVousActionService();
  final ActionGroupService _groupService = ActionGroupService();
  
  // Controllers et services
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // États et données
  List<PourVousAction> _actions = [];
  List<PourVousAction> _filteredActions = [];
  List<ActionGroup> _groups = [];
  ActionGroup? _selectedGroup;
  
  // Filtres et tri
  String _searchTerm = '';
  String _sortBy = 'order';
  bool _sortAscending = true;
  String _filterStatus = 'all';
  String _filterActionType = 'all';
  
  // États UI
  bool _isLoading = true;
  bool _isUploading = false;
  PourVousAction? _editingAction;
  bool _showFormVisible = false;
  bool _isGridView = false;
  
  // Formulaire
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _targetModuleController = TextEditingController();
  final TextEditingController _targetPageController = TextEditingController();
  final TextEditingController _externalUrlController = TextEditingController();
  String _selectedActionType = 'navigation';
  String _selectedCategory = 'general';
  String? _selectedImageUrl;
  String? _selectedBackgroundImageUrl;
  bool _isActiveAction = true;
  int _orderValue = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _targetModuleController.dispose();
    _targetPageController.dispose();
    _externalUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final actions = await _actionService.getAllActions().first;
      final groups = await _groupService.getAllGroups().first;
      
      // Créer les groupes par défaut s'ils n'existent pas
      if (groups.isEmpty) {
        await _groupService.createDefaultGroups();
        final newGroups = await _groupService.getAllGroups().first;
        setState(() {
          _groups = newGroups;
        });
      } else {
        setState(() {
          _groups = groups;
        });
      }
      
      setState(() {
        _actions = actions;
        _filteredActions = actions;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Erreur lors du chargement: $e');
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchTerm = _searchController.text;
    });
    _applyFilters();
  }

  void _applyFilters() {
    List<PourVousAction> filtered = List.from(_actions);
    
    // Filtre par terme de recherche
    if (_searchTerm.isNotEmpty) {
      filtered = filtered.where((action) {
        return action.title.toLowerCase().contains(_searchTerm.toLowerCase()) ||
               action.description.toLowerCase().contains(_searchTerm.toLowerCase()) ||
               action.actionType.toLowerCase().contains(_searchTerm.toLowerCase());
      }).toList();
    }
    
    // Filtre par statut
    if (_filterStatus != 'all') {
      filtered = filtered.where((action) {
        return _filterStatus == 'active' ? action.isActive : !action.isActive;
      }).toList();
    }
    
    // Filtre par type d'action
    if (_filterActionType != 'all') {
      filtered = filtered.where((action) {
        return action.actionType == _filterActionType;
      }).toList();
    }
    
    // Filtre par groupe
    if (_selectedGroup != null) {
      filtered = filtered.where((action) {
        return action.groupId == _selectedGroup!.id;
      }).toList();
    }
    
    // Tri
    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'title':
          comparison = a.title.compareTo(b.title);
          break;
        case 'order':
          comparison = a.order.compareTo(b.order);
          break;
        case 'created':
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case 'updated':
          comparison = a.updatedAt.compareTo(b.updatedAt);
          break;
        case 'type':
          comparison = a.actionType.compareTo(b.actionType);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });
    
    setState(() {
      _filteredActions = filtered;
    });
  }

  void _showForm({PourVousAction? action}) {
    setState(() {
      _editingAction = action;
      _showFormVisible = true;
      
      if (action != null) {
        _titleController.text = action.title;
        _descriptionController.text = action.description;
        _targetModuleController.text = action.targetModule ?? '';
        _targetPageController.text = action.targetRoute ?? '';
        _externalUrlController.text = action.actionData?['externalUrl'] ?? '';
        _selectedActionType = action.actionType;
        _selectedCategory = action.category ?? 'general';
        _selectedImageUrl = action.actionData?['imageUrl'];
        _selectedBackgroundImageUrl = action.backgroundImageUrl;
        _isActiveAction = action.isActive;
        _orderValue = action.order;
      } else {
        _titleController.clear();
        _descriptionController.clear();
        _targetModuleController.clear();
        _targetPageController.clear();
        _externalUrlController.clear();
        _selectedActionType = 'navigation';
        _selectedCategory = 'general';
        _selectedImageUrl = null;
        _selectedBackgroundImageUrl = null;
        _isActiveAction = true;
        _orderValue = _actions.length;
      }
    });
  }

  void _hideForm() {
    setState(() {
      _showFormVisible = false;
      _editingAction = null;
    });
  }

  String _getImageUrl(PourVousAction action) {
    return action.actionData?['imageUrl'] ?? '';
  }

  // Helper method to safely get color from group
  Color _getGroupColor(ActionGroup group) {
    if (group.color != null && group.color!.isNotEmpty) {
      try {
        if (group.color!.startsWith('#')) {
          return Color(int.parse('0xff${group.color!.substring(1)}'));
        } else {
          return Color(int.parse('0xff${group.color!}'));
        }
      } catch (e) {
        return AppTheme.grey500;
      }
    }
    return AppTheme.grey500;
  }

  ActionGroup _getDefaultGroup() {
    return ActionGroup(
      id: '',
      name: 'Aucun groupe',
      description: '',
      icon: Icons.help,
      iconCodePoint: Icons.help.codePoint.toString(),
      color: AppTheme.grey500.value.toRadixString(16),
      order: 0,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _showFormVisible
              ? _buildForm()
              : Column(
                  children: [
                    _buildToolbar(),
                    _buildFilterBar(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildActionsTab(),
                          _buildGroupsTab(),
                          _buildAnalyticsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
      floatingActionButton: _showFormVisible
          ? null
          : FloatingActionButton(
              onPressed: _showForm,
              child: const Icon(Icons.add),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Administration - Pour Vous'),
      bottom: _showFormVisible
          ? null
          : PreferredSize(
              preferredSize: const Size.fromHeight(50),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor, // Couleur primaire cohérente
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.black100.withOpacity(0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.onPrimaryColor, // Texte blanc
                  unselectedLabelColor: AppTheme.onPrimaryColor.withOpacity(0.7), // Texte blanc semi-transparent
                  indicatorColor: AppTheme.onPrimaryColor, // Indicateur blanc
                  indicatorWeight: 3.0,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  labelStyle: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize14,
                    fontWeight: AppTheme.fontSemiBold,
                  ),
                  unselectedLabelStyle: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize14,
                    fontWeight: AppTheme.fontMedium,
                  ),
                  tabs: const [
                    Tab(
                      text: 'Actions',
                      icon: Icon(Icons.touch_app),
                      iconMargin: EdgeInsets.only(bottom: 4),
                    ),
                    Tab(
                      text: 'Groupes',
                      icon: Icon(Icons.group_work),
                      iconMargin: EdgeInsets.only(bottom: 4),
                    ),
                    Tab(
                      text: 'Analytiques',
                      icon: Icon(Icons.analytics),
                      iconMargin: EdgeInsets.only(bottom: 4),
                    ),
                  ],
                ),
              ),
            ),
      actions: _showFormVisible
          ? [
              IconButton(
                onPressed: _hideForm,
                icon: const Icon(Icons.close),
              ),
            ]
          : [
              IconButton(
                onPressed: _exportActions,
                icon: const Icon(Icons.download),
              ),
              IconButton(
                onPressed: _importActions,
                icon: const Icon(Icons.upload),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'refresh':
                      _loadData();
                      break;
                    case 'reorder':
                      _reorderActions();
                      break;
                    case 'toggle_view':
                      setState(() => _isGridView = !_isGridView);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'refresh',
                    child: Row(
                      children: [
                        Icon(Icons.refresh),
                        SizedBox(width: AppTheme.spaceSmall),
                        Text('Actualiser'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'reorder',
                    child: Row(
                      children: [
                        Icon(Icons.sort),
                        SizedBox(width: AppTheme.spaceSmall),
                        Text('Réorganiser'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle_view',
                    child: Row(
                      children: [
                        Icon(_isGridView ? Icons.list : Icons.grid_view),
                        const SizedBox(width: AppTheme.spaceSmall),
                        Text(_isGridView ? 'Vue liste' : 'Vue grille'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
    );
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final actions = await _actionService.getAllActions().first;
      final groups = await _groupService.getAllGroups().first;
      
      // Créer les groupes par défaut s'ils n'existent pas
      if (groups.isEmpty) {
        await _groupService.createDefaultGroups();
        final newGroups = await _groupService.getAllGroups().first;
        setState(() {
          _groups = newGroups;
        });
      } else {
        setState(() {
          _groups = groups;
        });
      }
      
      setState(() {
        _actions = actions;
        _filteredActions = actions;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Erreur lors du chargement: $e');
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchTerm = _searchController.text;
    });
    _applyFilters();
  }

  void _applyFilters() {
    List<PourVousAction> filtered = List.from(_actions);
    
    // Filtre par terme de recherche
    if (_searchTerm.isNotEmpty) {
      filtered = filtered.where((action) {
        return action.title.toLowerCase().contains(_searchTerm.toLowerCase()) ||
               action.description.toLowerCase().contains(_searchTerm.toLowerCase()) ||
               action.actionType.toLowerCase().contains(_searchTerm.toLowerCase());
      }).toList();
    }
    
    // Filtre par statut
    if (_filterStatus != 'all') {
      filtered = filtered.where((action) {
        return _filterStatus == 'active' ? action.isActive : !action.isActive;
      }).toList();
    }
    
    // Filtre par type d'action
    if (_filterActionType != 'all') {
      filtered = filtered.where((action) {
        return action.actionType == _filterActionType;
      }).toList();
    }
    
    // Filtre par groupe
    if (_selectedGroup != null) {
      filtered = filtered.where((action) {
        return action.groupId == _selectedGroup!.id;
      }).toList();
    }
    
    // Tri
    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'title':
          comparison = a.title.compareTo(b.title);
          break;
        case 'order':
          comparison = a.order.compareTo(b.order);
          break;
        case 'created':
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case 'updated':
          comparison = a.updatedAt.compareTo(b.updatedAt);
          break;
        case 'type':
          comparison = a.actionType.compareTo(b.actionType);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });
    
    setState(() {
      _filteredActions = filtered;
    });
  }

  void _showForm({PourVousAction? action}) {
    setState(() {
      _editingAction = action;
      _showForm = true;
      
      if (action != null) {
        _titleController.text = action.title;
        _descriptionController.text = action.description;
        _targetModuleController.text = action.targetModule ?? '';
        _targetPageController.text = action.targetRoute ?? '';
        _externalUrlController.text = action.actionData?['externalUrl'] ?? '';
        _selectedActionType = action.actionType;
        _selectedCategory = action.category ?? 'general';
        _selectedImageUrl = action.actionData?['imageUrl'];
        _selectedBackgroundImageUrl = action.backgroundImageUrl;
        _isActiveAction = action.isActive;
        _orderValue = action.order;
      } else {
        _titleController.clear();
        _descriptionController.clear();
        _targetModuleController.clear();
        _targetPageController.clear();
        _externalUrlController.clear();
        _selectedActionType = 'navigation';
        _selectedCategory = 'general';
        _selectedImageUrl = null;
        _selectedBackgroundImageUrl = null;
        _isActiveAction = true;
        _orderValue = _actions.length;
      }
    });
  }

  void _hideForm() {
    setState(() {
      _showForm = false;
      _editingAction = null;
    });
  }

  Future<void> _saveAction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);

    try {
      // Préparer les données d'action
      final actionData = <String, dynamic>{};
      if (_selectedImageUrl != null) {
        actionData['imageUrl'] = _selectedImageUrl;
      }
      if (_externalUrlController.text.isNotEmpty) {
        actionData['externalUrl'] = _externalUrlController.text;
      }

      final action = PourVousAction(
        id: _editingAction?.id ?? '',
        title: _titleController.text,
        description: _descriptionController.text,
        icon: Icons.touch_app, // Icône par défaut
        iconCodePoint: Icons.touch_app.codePoint.toString(),
        actionType: _selectedActionType,
        targetModule: _targetModuleController.text.isEmpty ? null : _targetModuleController.text,
        targetRoute: _targetPageController.text.isEmpty ? null : _targetPageController.text,
        actionData: actionData.isEmpty ? null : actionData,
        backgroundImageUrl: _selectedBackgroundImageUrl,
        isActive: _isActiveAction,
        order: _orderValue,
        groupId: _selectedGroup?.id,
        category: _selectedCategory,
        createdAt: _editingAction?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      bool success;
      if (_editingAction != null) {
        success = await _actionService.updateAction(_editingAction!.id, action);
      } else {
        final newId = await _actionService.createAction(action);
        success = newId != null;
      }

      if (success) {
        _showSuccessSnackBar(_editingAction != null ? 'Action mise à jour' : 'Action créée');
        _hideForm();
        await _loadData();
      } else {
        throw Exception('Échec de la sauvegarde');
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la sauvegarde: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteAction(PourVousAction action) async {
    final confirmed = await _showConfirmDialog(
      'Supprimer l\'action',
      'Êtes-vous sûr de vouloir supprimer "${action.title}" ?',
    );
    
    if (!confirmed) return;

    try {
      final success = await _actionService.deleteAction(action.id);
      if (success) {
        _showSuccessSnackBar('Action supprimée');
        await _loadData();
      } else {
        throw Exception('Échec de la suppression');
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la suppression: $e');
    }
  }

  Future<void> _duplicateAction(PourVousAction action) async {
    try {
      final newId = await _actionService.duplicateAction(action.id);
      if (newId != null) {
        _showSuccessSnackBar('Action dupliquée');
        await _loadData();
      } else {
        throw Exception('Échec de la duplication');
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la duplication: $e');
    }
  }

  Future<void> _reorderActions() async {
    try {
      final success = await _actionService.reorderActions(_filteredActions);
      if (success) {
        _showSuccessSnackBar('Ordre mis à jour');
        await _loadData();
      } else {
        throw Exception('Échec de la réorganisation');
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la réorganisation: $e');
    }
  }

  Future<void> _pickImage(bool isBackground) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: isBackground ? 1920 : 512,
        maxHeight: isBackground ? 1080 : 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _isUploading = true);
        
        final imageFile = File(image.path);
        final imageUrl = await _actionService.uploadImage(imageFile, 'pour_vous_images');
        if (imageUrl != null) {
          setState(() {
            if (isBackground) {
              _selectedBackgroundImageUrl = imageUrl;
            } else {
              _selectedImageUrl = imageUrl;
            }
          });
          _showSuccessSnackBar('Image uploadée');
        } else {
          throw Exception('Échec de l\'upload');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de l\'upload: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _exportActions() async {
    try {
      final data = await _actionService.exportActions();
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      
      if (kIsWeb) {
        // Pour le web, copier dans le presse-papiers
        await Clipboard.setData(ClipboardData(text: jsonString));
        _showSuccessSnackBar('Données copiées dans le presse-papiers');
      } else {
        // Pour mobile, sauvegarder dans un fichier
        final result = await FilePicker.platform.saveFile(
          dialogTitle: 'Exporter les actions',
          fileName: 'pour_vous_actions_${DateTime.now().millisecondsSinceEpoch}.json',
        );
        
        if (result != null) {
          final file = File(result);
          await file.writeAsString(jsonString);
          _showSuccessSnackBar('Export réussi: $result');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de l\'export: $e');
    }
  }

  Future<void> _importActions() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;
        
        final success = await _actionService.importActions(data);
        if (success) {
          _showSuccessSnackBar('Import réussi');
          await _loadData();
        } else {
          throw Exception('Échec de l\'import');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de l\'import: $e');
    }
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.greenStandard,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.redStandard,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _showForm
              ? _buildForm()
              : Column(
                  children: [
                    _buildToolbar(),
                    _buildFilterBar(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildActionsTab(),
                          _buildGroupsTab(),
                          _buildAnalyticsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
      floatingActionButton: _showForm
          ? null
          : FloatingActionButton(
              onPressed: () => _showForm(),
              child: const Icon(Icons.add),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Administration - Pour Vous'),
      bottom: _showForm
          ? null
          : PreferredSize(
              preferredSize: const Size.fromHeight(50),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor, // Couleur primaire cohérente
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.black100.withOpacity(0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.onPrimaryColor, // Texte blanc
                  unselectedLabelColor: AppTheme.onPrimaryColor.withOpacity(0.7), // Texte blanc semi-transparent
                  indicatorColor: AppTheme.onPrimaryColor, // Indicateur blanc
                  indicatorWeight: 3.0,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  labelStyle: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize14,
                    fontWeight: AppTheme.fontSemiBold,
                  ),
                  unselectedLabelStyle: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize14,
                    fontWeight: AppTheme.fontMedium,
                  ),
                  tabs: const [
                    Tab(
                      text: 'Actions',
                      icon: Icon(Icons.touch_app),
                      iconMargin: EdgeInsets.only(bottom: 4),
                    ),
                    Tab(
                      text: 'Groupes',
                      icon: Icon(Icons.group_work),
                      iconMargin: EdgeInsets.only(bottom: 4),
                    ),
                    Tab(
                      text: 'Analytiques',
                      icon: Icon(Icons.analytics),
                      iconMargin: EdgeInsets.only(bottom: 4),
                    ),
                  ],
                ),
              ),
            ),
      actions: _showForm
          ? [
              IconButton(
                onPressed: _hideForm,
                icon: const Icon(Icons.close),
              ),
            ]
          : [
              IconButton(
                onPressed: _exportActions,
                icon: const Icon(Icons.download),
              ),
              IconButton(
                onPressed: _importActions,
                icon: const Icon(Icons.upload),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'refresh':
                      _loadData();
                      break;
                    case 'reorder':
                      _reorderActions();
                      break;
                    case 'toggle_view':
                      setState(() => _isGridView = !_isGridView);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'refresh',
                    child: Row(
                      children: [
                        Icon(Icons.refresh),
                        SizedBox(width: AppTheme.spaceSmall),
                        Text('Actualiser'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'reorder',
                    child: Row(
                      children: [
                        Icon(Icons.sort),
                        SizedBox(width: AppTheme.spaceSmall),
                        Text('Réorganiser'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle_view',
                    child: Row(
                      children: [
                        Icon(_isGridView ? Icons.list : Icons.grid_view),
                        const SizedBox(width: AppTheme.spaceSmall),
                        Text(_isGridView ? 'Vue liste' : 'Vue grille'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Rechercher des actions...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spaceMedium),
          DropdownButton<String>(
            value: _sortBy,
            onChanged: (value) {
              setState(() => _sortBy = value!);
              _applyFilters();
            },
            items: const [
              DropdownMenuItem(value: 'order', child: Text('Ordre')),
              DropdownMenuItem(value: 'title', child: Text('Titre')),
              DropdownMenuItem(value: 'created', child: Text('Créé')),
              DropdownMenuItem(value: 'updated', child: Text('Modifié')),
              DropdownMenuItem(value: 'type', child: Text('Type')),
            ],
          ),
          IconButton(
            onPressed: () {
              setState(() => _sortAscending = !_sortAscending);
              _applyFilters();
            },
            icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Filtre par statut
            ChoiceChip(
              label: const Text('Tous'),
              selected: _filterStatus == 'all',
              onSelected: (selected) {
                if (selected) {
                  setState(() => _filterStatus = 'all');
                  _applyFilters();
                }
              },
            ),
            const SizedBox(width: AppTheme.spaceSmall),
            ChoiceChip(
              label: const Text('Actifs'),
              selected: _filterStatus == 'active',
              onSelected: (selected) {
                if (selected) {
                  setState(() => _filterStatus = 'active');
                  _applyFilters();
                }
              },
            ),
            const SizedBox(width: AppTheme.spaceSmall),
            ChoiceChip(
              label: const Text('Inactifs'),
              selected: _filterStatus == 'inactive',
              onSelected: (selected) {
                if (selected) {
                  setState(() => _filterStatus = 'inactive');
                  _applyFilters();
                }
              },
            ),
            const SizedBox(width: AppTheme.spaceMedium),
            
            // Filtre par groupes
            ...(_groups.map((group) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(group.name),
                selected: _selectedGroup?.id == group.id,
                onSelected: (selected) {
                  setState(() {
                    _selectedGroup = selected ? group : null;
                  });
                  _applyFilters();
                },
                backgroundColor: Color(group.color),
              ),
            )).toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsTab() {
    if (_filteredActions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app, size: 64, color: AppTheme.grey500),
            SizedBox(height: AppTheme.spaceMedium),
            Text('Aucune action trouvée'),
            SizedBox(height: AppTheme.spaceSmall),
            Text('Créez votre première action ou ajustez vos filtres'),
          ],
        ),
      );
    }

    return _isGridView ? _buildGridView() : _buildListView();
  }

  Widget _buildListView() {
    return ReorderableListView.builder(
      scrollController: _scrollController,
      itemCount: _filteredActions.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex--;
          final item = _filteredActions.removeAt(oldIndex);
          _filteredActions.insert(newIndex, item);
          
          // Mettre à jour les ordres
          for (int i = 0; i < _filteredActions.length; i++) {
            _filteredActions[i] = _filteredActions[i].copyWith(order: i);
          }
        });
        _reorderActions();
      },
      itemBuilder: (context, index) {
        final action = _filteredActions[index];
        return _buildActionListTile(action, index);
      },
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _filteredActions.length,
      itemBuilder: (context, index) {
        final action = _filteredActions[index];
        return _buildActionCard(action);
      },
    );
  }

  Widget _buildActionListTile(PourVousAction action, int index) {
    final group = _groups.firstWhere(
      (g) => g.id == action.groupId,
      orElse: () => ActionGroup(
        id: '',
        name: 'Aucun groupe',
        description: '',
        color: AppTheme.grey500.value,
        order: 0,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    return Card(
      key: ValueKey(action.id),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: action.imageUrl != null
              ? NetworkImage(action.imageUrl!)
              : null,
          backgroundColor: Color(group.color).withOpacity(0.2),
          child: action.imageUrl == null
              ? Icon(
                  _getActionTypeIcon(action.actionType),
                  color: Color(group.color),
                )
              : null,
        ),
        title: Text(
          action.title,
          style: TextStyle(
            decoration: action.isActive ? null : TextDecoration.lineThrough,
            color: action.isActive ? null : AppTheme.grey500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(action.description),
            const SizedBox(height: AppTheme.spaceXSmall),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Color(group.color).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Text(
                    group.name,
                    style: TextStyle(
                      fontSize: AppTheme.fontSize12,
                      color: Color(group.color),
                      fontWeight: AppTheme.fontBold,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceSmall),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Text(
                    _getActionTypeLabel(action.actionType),
                    style: TextStyle(
                      fontSize: AppTheme.fontSize12,
                      color: Theme.of(context).primaryColor,
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
            Text('${action.order}'),
            const SizedBox(width: AppTheme.spaceSmall),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _showForm(action: action);
                    break;
                  case 'duplicate':
                    _duplicateAction(action);
                    break;
                  case 'delete':
                    _deleteAction(action);
                    break;
                  case 'toggle':
                    _toggleActionStatus(action);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: AppTheme.spaceSmall),
                      Text('Modifier'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'duplicate',
                  child: Row(
                    children: [
                      Icon(Icons.copy),
                      SizedBox(width: AppTheme.spaceSmall),
                      Text('Dupliquer'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(action.isActive ? Icons.visibility_off : Icons.visibility),
                      const SizedBox(width: AppTheme.spaceSmall),
                      Text(action.isActive ? 'Désactiver' : 'Activer'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: AppTheme.redStandard),
                      SizedBox(width: AppTheme.spaceSmall),
                      Text('Supprimer', style: TextStyle(color: AppTheme.redStandard)),
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

  Widget _buildActionCard(PourVousAction action) {
    final group = _groups.firstWhere(
      (g) => g.id == action.groupId,
      orElse: () => ActionGroup(
        id: '',
        name: 'Aucun groupe',
        description: '',
        color: AppTheme.grey500.value,
        order: 0,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showForm(action: action),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image de fond ou couleur
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: action.backgroundImageUrl != null
                      ? null
                      : LinearGradient(
                          colors: [
                            Color(group.color).withOpacity(0.7),
                            Color(group.color),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  image: action.backgroundImageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(action.backgroundImageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: Stack(
                  children: [
                    if (action.backgroundImageUrl != null)
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.black100.withOpacity(0.3),
                              Colors.transparent,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(AppTheme.spaceXSmall),
                        decoration: BoxDecoration(
                          color: action.isActive ? AppTheme.greenStandard : AppTheme.grey500,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          action.isActive ? Icons.check : Icons.close,
                          size: 16,
                          color: AppTheme.primaryColor, // Couleur primaire cohérente
                        ),
                      ),
                    ),
                    Center(
                      child: CircleAvatar(
                        radius: 24,
                        backgroundImage: action.imageUrl != null
                            ? NetworkImage(action.imageUrl!)
                            : null,
                        backgroundColor: AppTheme.white100.withOpacity(0.9),
                        child: action.imageUrl == null
                            ? Icon(
                                _getActionTypeIcon(action.actionType),
                                color: Color(group.color),
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Contenu
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.space12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: AppTheme.fontBold,
                        decoration: action.isActive ? null : TextDecoration.lineThrough,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTheme.spaceXSmall),
                    Text(
                      action.description,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Color(group.color).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          ),
                          child: Text(
                            group.name,
                            style: TextStyle(
                              fontSize: AppTheme.fontSize10,
                              color: Color(group.color),
                              fontWeight: AppTheme.fontBold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${action.order}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.grey500,
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
      ),
    );
  }

  Widget _buildGroupsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      itemCount: _groups.length,
      itemBuilder: (context, index) {
        final group = _groups[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Color(group.color),
              child: Text(
                group.name.isNotEmpty ? group.name[0].toUpperCase() : 'G',
                style: const TextStyle(
                  color: AppTheme.primaryColor, // Couleur primaire cohérente
                  fontWeight: AppTheme.fontBold,
                ),
              ),
            ),
            title: Text(group.name),
            subtitle: Text(group.description),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: group.isActive,
                  onChanged: (value) => _toggleGroupStatus(group),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showGroupForm(group: group);
                        break;
                      case 'delete':
                        _deleteGroup(group);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: AppTheme.spaceSmall),
                          Text('Modifier'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: AppTheme.redStandard),
                          SizedBox(width: AppTheme.spaceSmall),
                          Text('Supprimer', style: TextStyle(color: AppTheme.redStandard)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics, size: 64, color: AppTheme.grey500),
          SizedBox(height: AppTheme.spaceMedium),
          Text('Analytiques'),
          SizedBox(height: AppTheme.spaceSmall),
          Text('Bientôt disponible'),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _editingAction != null ? 'Modifier l\'action' : 'Nouvelle action',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            
            // Titre
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titre *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un titre';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            
            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer une description';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            
            // Type d'action
            DropdownButtonFormField<String>(
              initialValue: _selectedActionType,
              decoration: const InputDecoration(
                labelText: 'Type d\'action *',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'navigate_page', child: Text('Naviguer vers une page')),
                DropdownMenuItem(value: 'navigate_module', child: Text('Naviguer vers un module')),
                DropdownMenuItem(value: 'external_url', child: Text('URL externe')),
                DropdownMenuItem(value: 'action_custom', child: Text('Action personnalisée')),
              ],
              onChanged: (value) {
                setState(() => _selectedActionType = value!);
              },
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            
            // Champs conditionnels selon le type
            if (_selectedActionType == 'navigate_page') ...[
              TextFormField(
                controller: _targetPageController,
                decoration: const InputDecoration(
                  labelText: 'Page cible',
                  border: OutlineInputBorder(),
                  hintText: 'ex: /bible, /priere, /events',
                ),
              ),
              const SizedBox(height: AppTheme.spaceMedium),
            ],
            
            if (_selectedActionType == 'navigate_module') ...[
              TextFormField(
                controller: _targetModuleController,
                decoration: const InputDecoration(
                  labelText: 'Module cible',
                  border: OutlineInputBorder(),
                  hintText: 'ex: bible, priere, events',
                ),
              ),
              const SizedBox(height: AppTheme.spaceMedium),
            ],
            
            if (_selectedActionType == 'external_url') ...[
              TextFormField(
                controller: _externalUrlController,
                decoration: const InputDecoration(
                  labelText: 'URL externe',
                  border: OutlineInputBorder(),
                  hintText: 'https://...',
                ),
                validator: (value) {
                  if (_selectedActionType == 'external_url' &&
                      (value == null || value.isEmpty)) {
                    return 'Veuillez entrer une URL';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spaceMedium),
            ],
            
            // Catégorie
            DropdownButtonFormField<String>(
              initialValue: (['general','spiritual','community','service','events','resources'].contains(_selectedCategory)) ? _selectedCategory : null,
              decoration: const InputDecoration(
                labelText: 'Catégorie',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'general', child: Text('Général')),
                DropdownMenuItem(value: 'spiritual', child: Text('Spirituel')),
                DropdownMenuItem(value: 'community', child: Text('Communauté')),
                DropdownMenuItem(value: 'service', child: Text('Service')),
                DropdownMenuItem(value: 'events', child: Text('Événements')),
                DropdownMenuItem(value: 'resources', child: Text('Ressources')),
              ],
              onChanged: (value) {
                setState(() => _selectedCategory = value!);
              },
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            
            // Groupe
            DropdownButtonFormField<String>(
              initialValue: (_groups.any((g) => g.id == _selectedGroup?.id)) ? _selectedGroup?.id : null,
              decoration: const InputDecoration(
                labelText: 'Groupe',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Aucun groupe')),
                ..._groups.map((group) => DropdownMenuItem(
                  value: group.id,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Color(group.color),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceSmall),
                      Text(group.name),
                    ],
                  ),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedGroup = value != null
                      ? _groups.firstWhere((g) => g.id == value)
                      : null;
                });
              },
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            
            // Images
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Image icône'),
                      const SizedBox(height: AppTheme.spaceSmall),
                      GestureDetector(
                        onTap: () => _pickImage(false),
                        child: Container(
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.grey500),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          ),
                          child: _selectedImageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                  child: Image.network(
                                    _selectedImageUrl!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                )
                              : const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate),
                                      Text('Ajouter'),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Image de fond'),
                      const SizedBox(height: AppTheme.spaceSmall),
                      GestureDetector(
                        onTap: () => _pickImage(true),
                        child: Container(
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.grey500),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          ),
                          child: _selectedBackgroundImageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                  child: Image.network(
                                    _selectedBackgroundImageUrl!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                )
                              : const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate),
                                      Text('Ajouter'),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            
            // Ordre et statut
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _orderValue.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Ordre',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _orderValue = int.tryParse(value) ?? 0;
                    },
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMedium),
                Expanded(
                  child: SwitchListTile(
                    title: const Text('Actif'),
                    value: _isActiveAction,
                    onChanged: (value) {
                      setState(() => _isActiveAction = value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceXLarge),
            
            // Boutons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _hideForm,
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMedium),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _saveAction,
                    child: _isUploading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_editingAction != null ? 'Modifier' : 'Créer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Méthodes utilitaires pour les actions
  Future<void> _toggleActionStatus(PourVousAction action) async {
    try {
      final updatedAction = action.copyWith(isActive: !action.isActive);
      final success = await _actionService.updateAction(updatedAction);
      if (success) {
        _showSuccessSnackBar('Statut mis à jour');
        await _loadData();
      } else {
        throw Exception('Échec de la mise à jour');
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la mise à jour: $e');
    }
  }

  // Méthodes utilitaires pour les groupes
  Future<void> _toggleGroupStatus(ActionGroup group) async {
    try {
      final success = await _groupService.toggleGroupStatus(group.id);
      if (success) {
        _showSuccessSnackBar('Statut du groupe mis à jour');
        await _loadData();
      } else {
        throw Exception('Échec de la mise à jour');
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la mise à jour: $e');
    }
  }

  Future<void> _deleteGroup(ActionGroup group) async {
    final confirmed = await _showConfirmDialog(
      'Supprimer le groupe',
      'Êtes-vous sûr de vouloir supprimer le groupe "${group.name}" ?',
    );
    
    if (!confirmed) return;

    try {
      final success = await _groupService.deleteGroup(group.id);
      if (success) {
        _showSuccessSnackBar('Groupe supprimé');
        await _loadData();
      } else {
        throw Exception('Échec de la suppression');
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la suppression: $e');
    }
  }

  void _showGroupForm({ActionGroup? group}) {
    // TODO: Implémenter le formulaire de groupe
    _showErrorSnackBar('Formulaire de groupe pas encore implémenté');
  }

  // Utilitaires pour l'interface
  IconData _getActionTypeIcon(String actionType) {
    switch (actionType) {
      case 'navigate_page':
        return Icons.web;
      case 'navigate_module':
        return Icons.apps;
      case 'external_url':
        return Icons.link;
      case 'action_custom':
        return Icons.settings;
      default:
        return Icons.touch_app;
    }
  }

  String _getActionTypeLabel(String actionType) {
    switch (actionType) {
      case 'navigate_page':
        return 'Page';
      case 'navigate_module':
        return 'Module';
      case 'external_url':
        return 'URL';
      case 'action_custom':
        return 'Personnalisé';
      default:
        return actionType;
    }
  }
}
