import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../theme.dart';
import '../../models/action_group.dart';
import '../../services/action_group_service.dart';

class GroupManagementDialog extends StatefulWidget {
  final List<ActionGroup> groups;
  final Function() onGroupsChanged;

  const GroupManagementDialog({
    Key? key,
    required this.groups,
    required this.onGroupsChanged,
  }) : super(key: key);

  @override
  State<GroupManagementDialog> createState() => _GroupManagementDialogState();
}

class _GroupManagementDialogState extends State<GroupManagementDialog> {
  final ActionGroupService _groupService = ActionGroupService();
  List<ActionGroup> _groups = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _groups = List.from(widget.groups);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(AppTheme.spaceLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                Icon(
                  Icons.group_work,
                  size: 28,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: AppTheme.spaceSmall),
                Text(
                  'Gestion des Groupes',
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize20,
                    fontWeight: AppTheme.fontBold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            
            // Bouton ajouter groupe
            ElevatedButton.icon(
              onPressed: _showAddGroupDialog,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un Groupe'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            
            // Liste des groupes
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _groups.isEmpty
                      ? _buildEmptyState()
                      : _buildGroupsList(),
            ),
            
            // Actions
            const SizedBox(height: AppTheme.spaceMedium),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fermer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_work_outlined,
            size: 64,
            color: AppTheme.grey400,
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          Text(
            'Aucun groupe trouvé',
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize16,
              fontWeight: AppTheme.fontMedium,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Text(
            'Créez votre premier groupe pour organiser les actions',
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize14,
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsList() {
    return ListView.builder(
      itemCount: _groups.length,
      itemBuilder: (context, index) {
        final group = _groups[index];
        return Card(
          margin: const EdgeInsets.only(bottom: AppTheme.spaceSmall),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Icon(
                Icons.folder,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            title: Text(
              group.name,
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize16,
                fontWeight: AppTheme.fontMedium,
              ),
            ),
            subtitle: group.description.isNotEmpty
                ? Text(
                    group.description,
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize14,
                      color: AppTheme.textSecondaryColor,
                    ),
                  )
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ordre: ${group.order}',
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleGroupAction(value, group),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Modifier'),
                        dense: true,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Supprimer', style: TextStyle(color: Colors.red)),
                        dense: true,
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

  void _handleGroupAction(String action, ActionGroup group) {
    switch (action) {
      case 'edit':
        _showEditGroupDialog(group);
        break;
      case 'delete':
        _showDeleteConfirmation(group);
        break;
    }
  }

  void _showAddGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => GroupFormDialog(
        title: 'Ajouter un Groupe',
        onSave: _addGroup,
        initialOrder: _groups.length + 1,
      ),
    );
  }

  void _showEditGroupDialog(ActionGroup group) {
    showDialog(
      context: context,
      builder: (context) => GroupFormDialog(
        title: 'Modifier le Groupe',
        group: group,
        onSave: (name, description, order) => _updateGroup(group, name, description, order),
      ),
    );
  }

  void _showDeleteConfirmation(ActionGroup group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer le groupe "${group.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteGroup(group);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _addGroup(String name, String? description, int order) async {
    setState(() => _isLoading = true);
    
    try {
      final newGroup = ActionGroup(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        description: description ?? '',
        icon: Icons.folder,
        iconCodePoint: Icons.folder.codePoint.toString(),
        order: order,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await _groupService.createGroup(newGroup);
      
      setState(() {
        _groups.add(newGroup);
        _groups.sort((a, b) => a.order.compareTo(b.order));
      });
      
      widget.onGroupsChanged();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Groupe ajouté avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'ajout: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateGroup(ActionGroup group, String name, String? description, int order) async {
    setState(() => _isLoading = true);
    
    try {
      final updatedGroup = group.copyWith(
        name: name,
        description: description,
        order: order,
        updatedAt: DateTime.now(),
      );
      
      await _groupService.updateGroup(group.id, updatedGroup);
      
      setState(() {
        final index = _groups.indexWhere((g) => g.id == group.id);
        if (index != -1) {
          _groups[index] = updatedGroup;
          _groups.sort((a, b) => a.order.compareTo(b.order));
        }
      });
      
      widget.onGroupsChanged();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Groupe modifié avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la modification: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteGroup(ActionGroup group) async {
    setState(() => _isLoading = true);
    
    try {
      await _groupService.deleteGroup(group.id);
      
      setState(() {
        _groups.removeWhere((g) => g.id == group.id);
      });
      
      widget.onGroupsChanged();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Groupe supprimé avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

class GroupFormDialog extends StatefulWidget {
  final String title;
  final ActionGroup? group;
  final Function(String name, String? description, int order) onSave;
  final int? initialOrder;

  const GroupFormDialog({
    Key? key,
    required this.title,
    this.group,
    required this.onSave,
    this.initialOrder,
  }) : super(key: key);

  @override
  State<GroupFormDialog> createState() => _GroupFormDialogState();
}

class _GroupFormDialogState extends State<GroupFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _orderController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.group != null) {
      _nameController.text = widget.group!.name;
      _descriptionController.text = widget.group!.description;
      _orderController.text = widget.group!.order.toString();
    } else if (widget.initialOrder != null) {
      _orderController.text = widget.initialOrder.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom du groupe *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le nom est obligatoire';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optionnelle)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            TextFormField(
              controller: _orderController,
              decoration: const InputDecoration(
                labelText: 'Ordre *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'L\'ordre est obligatoire';
                }
                if (int.tryParse(value) == null) {
                  return 'L\'ordre doit être un nombre';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _saveGroup,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }

  void _saveGroup() {
    if (_formKey.currentState!.validate()) {
      widget.onSave(
        _nameController.text.trim(),
        _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        int.parse(_orderController.text),
      );
      Navigator.of(context).pop();
    }
  }
}