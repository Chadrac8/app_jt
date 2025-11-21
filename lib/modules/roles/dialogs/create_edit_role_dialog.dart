import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/module_permission_model.dart';
import '../models/role.dart';
import '../providers/role_provider.dart';
import '../services/current_user_service.dart';
import '../widgets/module_permissions_selector.dart';
import '../../../../theme.dart';

class CreateEditRoleDialog extends StatefulWidget {
  final Role? existingRole;
  final String? initialName;

  const CreateEditRoleDialog({
    super.key,
    this.existingRole,
    this.initialName,
  });

  @override
  State<CreateEditRoleDialog> createState() => _CreateEditRoleDialogState();
}

class _CreateEditRoleDialogState extends State<CreateEditRoleDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  late TabController _tabController;
  
  String _selectedColor = '#4CAF50';
  String _selectedIcon = 'person';
  bool _isActive = true;
  bool _isLoading = false;
  String _searchQuery = '';
  
  List<ModulePermissionModel> _modulePermissions = [];
  
  final List<String> _availableColors = [
    '#4CAF50', '#2196F3', '#FF9800', '#9C27B0',
    '#F44336', '#795548', '#607D8B', '#E91E63',
    '#3F51B5', '#009688', '#8BC34A', '#FFC107',
  ];
  
  final List<Map<String, dynamic>> _availableIcons = [
    {'icon': Icons.person, 'name': 'person'},
    {'icon': Icons.admin_panel_settings, 'name': 'admin_panel_settings'},
    {'icon': Icons.supervisor_account, 'name': 'supervisor_account'},
    {'icon': Icons.group, 'name': 'group'},
    {'icon': Icons.security, 'name': 'security'},
    {'icon': Icons.verified_user, 'name': 'verified_user'},
    {'icon': Icons.badge, 'name': 'badge'},
    {'icon': Icons.star, 'name': 'star'},
    {'icon': Icons.work, 'name': 'work'},
    {'icon': Icons.school, 'name': 'school'},
    {'icon': Icons.church, 'name': 'church'},
    {'icon': Icons.volunteer_activism, 'name': 'volunteer_activism'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Initialiser les permissions pour tous les modules
    _modulePermissions = AppModules.all.map((module) => 
        ModulePermissionModel(module: module)).toList();
    
    if (widget.existingRole != null) {
      _loadExistingRole();
    } else if (widget.initialName != null) {
      _nameController.text = widget.initialName!;
    }
  }

  void _loadExistingRole() {
    final role = widget.existingRole!;
    _nameController.text = role.name;
    _descriptionController.text = role.description;
    _selectedColor = role.color;
    _selectedIcon = role.icon;
    _isActive = role.isActive;
    
    // Charger les permissions existantes
    _modulePermissions = AppModules.fromPermissionKeys(role.permissions);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  IconData _getIconFromName(String iconName) {
    final iconMap = {
      for (var item in _availableIcons) item['name']: item['icon']
    };
    return iconMap[iconName] ?? Icons.person;
  }

  Future<void> _saveRole() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final permissions = AppModules.toPermissionKeys(_modulePermissions);
      
      final role = Role(
        id: widget.existingRole?.id ?? '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        color: _selectedColor,
        permissions: permissions,
        icon: _selectedIcon,
        isActive: _isActive,
        createdAt: widget.existingRole?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: widget.existingRole?.createdBy,
        lastModifiedBy: CurrentUserService().getCurrentUserString(),
      );

      final roleProvider = Provider.of<RoleProvider>(context, listen: false);
      
      if (widget.existingRole != null) {
        await roleProvider.updateRole(role.id, role);
      } else {
        await roleProvider.createRole(role);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingRole != null
                ? 'Rôle modifié avec succès'
                : 'Rôle créé avec succès'),
            backgroundColor: AppTheme.greenStandard,
          ),
        );
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        child: Column(
          children: [
            // En-tête
            Container(
              padding: const EdgeInsets.all(AppTheme.space20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getIconFromName(_selectedIcon),
                    color: AppTheme.white100,
                    size: 28,
                  ),
                  const SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: Text(
                      widget.existingRole != null ? 'Modifier le rôle' : 'Créer un nouveau rôle',
                      style: const TextStyle(
                        color: AppTheme.white100,
                        fontSize: AppTheme.fontSize20,
                        fontWeight: AppTheme.fontBold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppTheme.white100),
                  ),
                ],
              ),
            ),
            
            // Onglets
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.info), text: 'Informations'),
                Tab(icon: Icon(Icons.security), text: 'Permissions'),
              ],
            ),
            
            // Contenu des onglets
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildInfoTab(),
                  _buildPermissionsTab(),
                ],
              ),
            ),
            
            // Actions
            Container(
              padding: const EdgeInsets.all(AppTheme.space20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppTheme.grey500),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: AppTheme.space12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveRole,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(widget.existingRole != null ? 'Modifier' : 'Créer'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nom du rôle
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom du rôle',
                hintText: 'Ex: Administrateur, Modérateur...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le nom du rôle est requis';
                }
                if (value.trim().length < 2) {
                  return 'Le nom doit contenir au moins 2 caractères';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            
            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Décrivez les responsabilités de ce rôle...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'La description est requise';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            
            // Couleur
            Text(
              'Couleur du rôle',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spaceSmall),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableColors.map((color) {
                final isSelected = _selectedColor == color;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(int.parse(color.substring(1, 7), radix: 16) + 0xFF000000),
                      borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                      border: isSelected
                          ? Border.all(color: AppTheme.black100, width: 3)
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: AppTheme.white100)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            
            // Icône
            Text(
              'Icône du rôle',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spaceSmall),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableIcons.map((iconData) {
                final isSelected = _selectedIcon == iconData['name'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = iconData['name']),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : AppTheme.grey500,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Icon(
                      iconData['icon'],
                      color: isSelected ? AppTheme.white100 : AppTheme.grey500,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            
            // État actif
            SwitchListTile(
              title: const Text('Rôle actif'),
              subtitle: const Text('Les rôles inactifs ne peuvent pas être assignés'),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
              secondary: Icon(
                _isActive ? Icons.toggle_on : Icons.toggle_off,
                color: _isActive ? AppTheme.greenStandard : AppTheme.grey500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsTab() {
    return Column(
      children: [
        // Barre de recherche
        Padding(
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Rechercher un module',
              hintText: 'Tapez pour filtrer les modules...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        
        // Sélecteur de permissions
        Expanded(
          child: ModulePermissionsSelector(
            initialPermissions: _modulePermissions,
            onPermissionsChanged: (permissions) {
              setState(() => _modulePermissions = permissions);
            },
            searchQuery: _searchQuery,
          ),
        ),
      ],
    );
  }
}
