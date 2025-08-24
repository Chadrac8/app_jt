import 'package:flutter/material.dart';
import '../models/pour_vous_action.dart';
import '../models/action_group.dart';
import '../services/pour_vous_action_service.dart';
import '../services/action_group_service.dart';

class AdminPourVousTab extends StatefulWidget {
  const AdminPourVousTab({Key? key}) : super(key: key);

  @override
  State<AdminPourVousTab> createState() => _AdminPourVousTabState();
}

class _AdminPourVousTabState extends State<AdminPourVousTab> {
  final PourVousActionService _actionService = PourVousActionService();
  final ActionGroupService _groupService = ActionGroupService();
  
  List<PourVousAction> _actions = [];
  List<ActionGroup> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final actions = await _actionService.getAllActions().first;
      final groups = await _groupService.getAllGroups().first;
      
      setState(() {
        _actions = actions;
        _groups = groups;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteAction(PourVousAction action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'action'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${action.title}" ?'),
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
    
    if (!confirmed) return;

    try {
      final success = await _actionService.deleteAction(action.id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Action supprimée'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _duplicateAction(PourVousAction action) async {
    try {
      final newId = await _actionService.duplicateAction(action.id);
      if (newId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Action dupliquée'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  ActionGroup _getActionGroup(String? groupId) {
    if (groupId == null) {
      return ActionGroup(
        id: '',
        name: 'Aucun groupe',
        description: '',
        icon: Icons.help,
        iconCodePoint: Icons.help.codePoint.toString(),
        color: 'grey',
        order: 0,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
    
    return _groups.firstWhere(
      (g) => g.id == groupId,
      orElse: () => ActionGroup(
        id: '',
        name: 'Groupe inconnu',
        description: '',
        icon: Icons.help,
        iconCodePoint: Icons.help.codePoint.toString(),
        color: 'grey',
        order: 0,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Color _getGroupColor(ActionGroup group) {
    try {
      if (group.color != null && group.color!.isNotEmpty) {
        if (group.color!.startsWith('#')) {
          return Color(int.parse('0xff${group.color!.substring(1)}'));
        } else if (group.color == 'grey') {
          return Colors.grey;
        } else if (group.color == 'blue') {
          return Colors.blue;
        } else if (group.color == 'green') {
          return Colors.green;
        } else if (group.color == 'orange') {
          return Colors.orange;
        } else if (group.color == 'purple') {
          return Colors.purple;
        } else if (group.color == 'red') {
          return Colors.red;
        } else {
          return Color(int.parse('0xff${group.color!}'));
        }
      }
    } catch (e) {
      // Ignore parsing errors
    }
    return Colors.grey;
  }

  String _getImageUrl(PourVousAction action) {
    return action.actionData?['imageUrl'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration - Pour Vous'),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'manage_groups':
                  _showGroupManagement();
                  break;
                case 'templates':
                  _showActionTemplates();
                  break;
                case 'import_export':
                  _showImportExport();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'manage_groups',
                child: Row(
                  children: [
                    Icon(Icons.group_work),
                    SizedBox(width: 8),
                    Text('Gestion des groupes'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'templates',
                child: Row(
                  children: [
                    Icon(Icons.copy),
                    SizedBox(width: 8),
                    Text('Templates d\'actions'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'import_export',
                child: Row(
                  children: [
                    Icon(Icons.import_export),
                    SizedBox(width: 8),
                    Text('Import/Export'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddActionDialog,
        child: const Icon(Icons.add),
        tooltip: 'Ajouter une action',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Statistiques en haut
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Icon(Icons.touch_app, size: 32),
                                const SizedBox(height: 8),
                                Text(
                                  '${_actions.length}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text('Actions totales'),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Icon(Icons.visibility, size: 32, color: Colors.green),
                                const SizedBox(height: 8),
                                Text(
                                  '${_actions.where((a) => a.isActive).length}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                const Text('Actions actives'),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Icon(Icons.group_work, size: 32, color: Colors.blue),
                                const SizedBox(height: 8),
                                Text(
                                  '${_groups.length}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                const Text('Groupes'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Liste des actions
                Expanded(
                  child: _actions.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.touch_app, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('Aucune action trouvée'),
                              SizedBox(height: 8),
                              Text('Les actions apparaîtront ici'),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _actions.length,
                          itemBuilder: (context, index) {
                            final action = _actions[index];
                            final group = _getActionGroup(action.groupId);
                            final groupColor = _getGroupColor(group);
                            final imageUrl = _getImageUrl(action);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: imageUrl.isNotEmpty
                                      ? NetworkImage(imageUrl)
                                      : null,
                                  backgroundColor: groupColor.withOpacity(0.2),
                                  child: imageUrl.isEmpty
                                      ? Icon(
                                          action.icon,
                                          color: groupColor,
                                        )
                                      : null,
                                ),
                                title: Text(
                                  action.title,
                                  style: TextStyle(
                                    decoration: action.isActive ? null : TextDecoration.lineThrough,
                                    color: action.isActive ? null : Colors.grey,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(action.description),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: groupColor.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            group.name,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: groupColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            action.actionType,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context).primaryColor,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: action.isActive
                                                ? Colors.green.withOpacity(0.1)
                                                : Colors.grey.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            action.isActive ? 'Actif' : 'Inactif',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: action.isActive ? Colors.green : Colors.grey,
                                              fontWeight: FontWeight.bold,
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
                                    const SizedBox(width: 8),
                                    PopupMenuButton<String>(
                                      onSelected: (value) {
                                        switch (value) {
                                          case 'duplicate':
                                            _duplicateAction(action);
                                            break;
                                          case 'delete':
                                            _deleteAction(action);
                                            break;
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'duplicate',
                                          child: Row(
                                            children: [
                                              Icon(Icons.copy),
                                              SizedBox(width: 8),
                                              Text('Dupliquer'),
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
                          },
                        ),
                ),
              ],
            ),
    );
  }

  // Méthodes pour les nouvelles fonctionnalités

  void _showAddActionDialog() {
    showDialog(
      context: context,
      builder: (context) => _ActionFormDialog(
        actionService: _actionService,
        groups: _groups,
        onSaved: () {
          Navigator.of(context).pop();
          _loadData();
        },
      ),
    );
  }

  void _showGroupManagement() {
    showDialog(
      context: context,
      builder: (context) => _GroupManagementDialog(
        groupService: _groupService,
        groups: _groups,
        onSaved: () {
          Navigator.of(context).pop();
          _loadData();
        },
      ),
    );
  }

  void _showActionTemplates() {
    showDialog(
      context: context,
      builder: (context) => _ActionTemplatesDialog(
        actionService: _actionService,
        groups: _groups,
        onSaved: () {
          Navigator.of(context).pop();
          _loadData();
        },
      ),
    );
  }

  void _showImportExport() {
    showDialog(
      context: context,
      builder: (context) => _ImportExportDialog(
        actionService: _actionService,
        onImported: () {
          Navigator.of(context).pop();
          _loadData();
        },
      ),
    );
  }
}

// Dialog pour ajouter/modifier une action
class _ActionFormDialog extends StatefulWidget {
  final PourVousActionService actionService;
  final List<ActionGroup> groups;
  final VoidCallback onSaved;

  const _ActionFormDialog({
    required this.actionService,
    required this.groups,
    required this.onSaved,
  });

  @override
  State<_ActionFormDialog> createState() => _ActionFormDialogState();
}

class _ActionFormDialogState extends State<_ActionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _targetRouteController;
  late final TextEditingController _colorController;
  
  String _actionType = 'navigation';
  String _targetModule = 'rendez_vous';
  String? _selectedGroupId;
  IconData _selectedIcon = Icons.touch_app;
  bool _isActive = true;
  int _order = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _targetRouteController = TextEditingController();
    _colorController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetRouteController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter une action'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Titre *',
                    border: OutlineInputBorder(),
                  ),
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
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    border: OutlineInputBorder(),
                  ),
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
                  value: _actionType,
                  decoration: const InputDecoration(
                    labelText: 'Type d\'action',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'navigation', child: Text('Navigation')),
                    DropdownMenuItem(value: 'form', child: Text('Formulaire')),
                    DropdownMenuItem(value: 'external', child: Text('Lien externe')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _actionType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _targetModule,
                  decoration: const InputDecoration(
                    labelText: 'Module cible',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'rendez_vous', child: Text('Rendez-vous')),
                    DropdownMenuItem(value: 'groupes', child: Text('Groupes')),
                    DropdownMenuItem(value: 'mur_priere', child: Text('Mur de prière')),
                    DropdownMenuItem(value: 'bible', child: Text('Bible')),
                    DropdownMenuItem(value: 'message', child: Text('Message')),
                    DropdownMenuItem(value: 'benevolat', child: Text('Bénévolat')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _targetModule = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _targetRouteController,
                  decoration: const InputDecoration(
                    labelText: 'Route cible (optionnel)',
                    border: OutlineInputBorder(),
                    hintText: '/rendez_vous',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  value: _selectedGroupId,
                  decoration: const InputDecoration(
                    labelText: 'Groupe',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Aucun groupe')),
                    ...widget.groups.map((group) => DropdownMenuItem(
                      value: group.id,
                      child: Text(group.name),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedGroupId = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _colorController,
                  decoration: const InputDecoration(
                    labelText: 'Couleur (optionnel)',
                    border: OutlineInputBorder(),
                    hintText: '#FF5722',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _order.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Ordre d\'affichage',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _order = int.tryParse(value) ?? 0;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SwitchListTile(
                        title: const Text('Actif'),
                        value: _isActive,
                        onChanged: (value) {
                          setState(() {
                            _isActive = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveAction,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Ajouter'),
        ),
      ],
    );
  }

  Future<void> _saveAction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final action = PourVousAction(
        id: '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        icon: _selectedIcon,
        iconCodePoint: _selectedIcon.codePoint.toString(),
        actionType: _actionType,
        targetModule: _targetModule,
        targetRoute: _targetRouteController.text.trim().isNotEmpty 
            ? _targetRouteController.text.trim() 
            : null,
        groupId: _selectedGroupId,
        color: _colorController.text.trim().isNotEmpty 
            ? _colorController.text.trim() 
            : null,
        isActive: _isActive,
        order: _order,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await widget.actionService.createAction(action);
      widget.onSaved();
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
}

// Dialog pour la gestion des groupes
class _GroupManagementDialog extends StatefulWidget {
  final ActionGroupService groupService;
  final List<ActionGroup> groups;
  final VoidCallback onSaved;

  const _GroupManagementDialog({
    required this.groupService,
    required this.groups,
    required this.onSaved,
  });

  @override
  State<_GroupManagementDialog> createState() => _GroupManagementDialogState();
}

class _GroupManagementDialogState extends State<_GroupManagementDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Gestion des groupes'),
      content: SizedBox(
        width: 400,
        height: 400,
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _addGroup,
              child: const Text('Ajouter un groupe'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: widget.groups.length,
                itemBuilder: (context, index) {
                  final group = widget.groups[index];
                  return ListTile(
                    leading: Icon(group.icon, color: _getGroupColor(group)),
                    title: Text(group.name),
                    subtitle: Text(group.description),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _editGroup(group);
                            break;
                          case 'delete':
                            _deleteGroup(group);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Modifier'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Supprimer'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
      ],
    );
  }

  Color _getGroupColor(ActionGroup group) {
    try {
      if (group.color != null && group.color!.startsWith('#')) {
        return Color(int.parse('0xff${group.color!.substring(1)}'));
      }
    } catch (e) {
      // Ignore
    }
    return Colors.blue;
  }

  void _addGroup() {
    // Implémentation pour ajouter un groupe
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ajouter un groupe - Fonctionnalité en cours de développement')),
    );
  }

  void _editGroup(ActionGroup group) {
    // Implémentation pour modifier un groupe
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Modifier le groupe "${group.name}" - Fonctionnalité en cours de développement')),
    );
  }

  void _deleteGroup(ActionGroup group) {
    // Implémentation pour supprimer un groupe
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Supprimer le groupe "${group.name}" - Fonctionnalité en cours de développement')),
    );
  }
}

// Dialog pour les templates d'actions
class _ActionTemplatesDialog extends StatelessWidget {
  final PourVousActionService actionService;
  final List<ActionGroup> groups;
  final VoidCallback onSaved;

  const _ActionTemplatesDialog({
    required this.actionService,
    required this.groups,
    required this.onSaved,
  });

  @override
  Widget build(BuildContext context) {
    final templates = [
      {
        'title': 'Prise de Rendez-vous',
        'description': 'Prenez rendez-vous avec un pasteur',
        'actionType': 'navigation',
        'targetModule': 'rendez_vous',
        'icon': Icons.calendar_today,
        'color': '#4CAF50',
      },
      {
        'title': 'Mur de Prière',
        'description': 'Partagez vos demandes de prière',
        'actionType': 'navigation',
        'targetModule': 'mur_priere',
        'icon': Icons.favorite,
        'color': '#E91E63',
      },
      {
        'title': 'Groupes de Maison',
        'description': 'Rejoignez un groupe près de chez vous',
        'actionType': 'navigation',
        'targetModule': 'groupes',
        'icon': Icons.home,
        'color': '#FF9800',
      },
      {
        'title': 'Bible en Ligne',
        'description': 'Accédez à la Bible et aux outils d\'étude',
        'actionType': 'navigation',
        'targetModule': 'bible',
        'icon': Icons.book,
        'color': '#3F51B5',
      },
      {
        'title': 'Bénévolat',
        'description': 'Participez aux activités de service',
        'actionType': 'navigation',
        'targetModule': 'benevolat',
        'icon': Icons.volunteer_activism,
        'color': '#9C27B0',
      },
      {
        'title': 'Contactez-nous',
        'description': 'Envoyez un message à l\'équipe',
        'actionType': 'form',
        'targetModule': 'message',
        'icon': Icons.message,
        'color': '#607D8B',
      },
    ];

    return AlertDialog(
      title: const Text('Templates d\'actions'),
      content: SizedBox(
        width: 400,
        height: 400,
        child: ListView.builder(
          itemCount: templates.length,
          itemBuilder: (context, index) {
            final template = templates[index];
            return ListTile(
              leading: Icon(
                template['icon'] as IconData,
                color: Color(int.parse('0xff${(template['color'] as String).substring(1)}')),
              ),
              title: Text(template['title'] as String),
              subtitle: Text(template['description'] as String),
              trailing: ElevatedButton(
                onPressed: () => _useTemplate(context, template),
                child: const Text('Utiliser'),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
      ],
    );
  }

  Future<void> _useTemplate(BuildContext context, Map<String, dynamic> template) async {
    try {
      final action = PourVousAction(
        id: '',
        title: template['title'] as String,
        description: template['description'] as String,
        icon: template['icon'] as IconData,
        iconCodePoint: (template['icon'] as IconData).codePoint.toString(),
        actionType: template['actionType'] as String,
        targetModule: template['targetModule'] as String,
        color: template['color'] as String,
        isActive: true,
        order: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await actionService.createAction(action);
      onSaved();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Template "${template['title']}" ajouté avec succès'),
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
    }
  }
}

// Dialog pour import/export
class _ImportExportDialog extends StatelessWidget {
  final PourVousActionService actionService;
  final VoidCallback onImported;

  const _ImportExportDialog({
    required this.actionService,
    required this.onImported,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import/Export'),
      content: const SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Fonctionnalités d\'import/export en cours de développement.'),
            SizedBox(height: 16),
            Text('Prochainement disponible :'),
            Text('• Export des actions au format JSON'),
            Text('• Import d\'actions depuis un fichier'),
            Text('• Sauvegarde automatique'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
        ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Fonctionnalité en cours de développement')),
            );
          },
          child: const Text('Export (demo)'),
        ),
      ],
    );
  }
}
