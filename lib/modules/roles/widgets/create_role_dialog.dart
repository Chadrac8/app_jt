import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/permission_model.dart';
import '../providers/permission_provider.dart';
import '../services/roles_permissions_service.dart';
import '../../../theme.dart';

/// Dialogue de création/édition de rôles avec Material Design 3
class CreateRoleDialog extends StatefulWidget {
  final Role? roleToEdit;
  final Function(Role)? onRoleCreated;

  const CreateRoleDialog({
    super.key,
    this.roleToEdit,
    this.onRoleCreated,
  });

  @override
  State<CreateRoleDialog> createState() => _CreateRoleDialogState();
}

class _CreateRoleDialogState extends State<CreateRoleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedColor = '#4CAF50';
  String _selectedIcon = 'person';
  bool _isActive = true;
  Map<String, List<String>> _selectedPermissions = {};
  bool _isLoading = false;

  final List<String> _availableColors = [
    '#4CAF50', '#2196F3', '#FF9800', '#9C27B0',
    '#F44336', '#795548', '#607D8B', '#E91E63',
    '#3F51B5', '#009688', '#CDDC39', '#FF5722',
  ];

  final List<String> _availableIcons = [
    'person', 'group', 'admin_panel_settings', 'supervisor_account',
    'security', 'manage_accounts', 'verified_user', 'shield',
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.roleToEdit != null) {
      _nameController.text = widget.roleToEdit!.name;
      _descriptionController.text = widget.roleToEdit!.description;
      _selectedColor = widget.roleToEdit!.color;
      _selectedIcon = widget.roleToEdit!.icon;
      _isActive = widget.roleToEdit!.isActive;
      _selectedPermissions = Map.from(widget.roleToEdit!.modulePermissions);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.roleToEdit == null ? 'Créer un rôle' : 'Modifier le rôle',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBasicInfoSection(),
                      const SizedBox(height: 24),
                      _buildAppearanceSection(),
                      const SizedBox(height: 24),
                      _buildPermissionsSection(),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations de base',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: AppTheme.fontBold,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nom du rôle *',
            hintText: 'Ex: Gestionnaire de contenu',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le nom est requis';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'Décrivez les responsabilités de ce rôle...',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Rôle actif'),
          subtitle: const Text('Les rôles inactifs ne peuvent pas être assignés'),
          value: _isActive,
          onChanged: (value) {
            setState(() {
              _isActive = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildAppearanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Apparence',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: AppTheme.fontBold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Aperçu
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _parseColor(_selectedColor).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Icon(
                  _parseIcon(_selectedIcon),
                  color: _parseColor(_selectedColor),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nameController.text.isEmpty ? 'Nom du rôle' : _nameController.text,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: AppTheme.fontBold,
                      ),
                    ),
                    Text(
                      _descriptionController.text.isEmpty 
                          ? 'Description du rôle' 
                          : _descriptionController.text,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.grey600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Sélection de couleur
        Text(
          'Couleur',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: AppTheme.fontMedium,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableColors.map((color) {
            final isSelected = _selectedColor == color;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedColor = color;
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _parseColor(color),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  border: Border.all(
                    color: isSelected ? AppTheme.black100 : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: isSelected 
                    ? const Icon(Icons.check, color: AppTheme.white100)
                    : null,
              ),
            );
          }).toList(),
        ),
        
        const SizedBox(height: 16),
        
        // Sélection d'icône
        Text(
          'Icône',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: AppTheme.fontMedium,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableIcons.map((iconName) {
            final isSelected = _selectedIcon == iconName;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedIcon = iconName;
                });
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected 
                      ? _parseColor(_selectedColor).withOpacity(0.2)
                      : AppTheme.grey100,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  border: Border.all(
                    color: isSelected 
                        ? _parseColor(_selectedColor)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Icon(
                  _parseIcon(iconName),
                  color: isSelected 
                      ? _parseColor(_selectedColor)
                      : AppTheme.grey600,
                  size: 24,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPermissionsSection() {
    return Consumer<PermissionProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Permissions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: AppTheme.fontBold,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _selectAllPermissions,
                  icon: const Icon(Icons.select_all),
                  label: const Text('Tout sélectionner'),
                ),
                TextButton.icon(
                  onPressed: _clearAllPermissions,
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Tout désélectionner'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Modules avec permissions
            ...AppModule.allModules.map((module) {
              final modulePermissions = provider.getModulePermissions(module.id);
              if (modulePermissions.isEmpty) return const SizedBox.shrink();
              
              return _buildModulePermissionCard(module, modulePermissions);
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildModulePermissionCard(AppModule module, List<Permission> permissions) {
    final selectedCount = _selectedPermissions[module.id]?.length ?? 0;
    final totalCount = permissions.length;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(_getModuleIcon(module.icon)),
        title: Text(module.name),
        subtitle: Text('$selectedCount/$totalCount permissions sélectionnées'),
        trailing: selectedCount > 0 
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Text(
                  '$selectedCount',
                  style: const TextStyle(color: AppTheme.white100, fontSize: 12),
                ),
              )
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Boutons de sélection rapide
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _selectModulePermissions(module.id, permissions),
                      icon: const Icon(Icons.check_box, size: 18),
                      label: const Text('Tout'),
                    ),
                    TextButton.icon(
                      onPressed: () => _clearModulePermissions(module.id),
                      icon: const Icon(Icons.check_box_outline_blank, size: 18),
                      label: const Text('Aucun'),
                    ),
                    TextButton.icon(
                      onPressed: () => _selectReadOnlyPermissions(module.id, permissions),
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text('Lecture seule'),
                    ),
                  ],
                ),
                const Divider(),
                
                // Liste des permissions
                ...permissions.map((permission) {
                  final isSelected = _selectedPermissions[module.id]?.contains(permission.id) ?? false;
                  
                  return CheckboxListTile(
                    dense: true,
                    value: isSelected,
                    onChanged: (value) => _togglePermission(module.id, permission.id, value ?? false),
                    title: Text(permission.name),
                    subtitle: Text(permission.description),
                    secondary: Icon(
                      _getPermissionLevelIcon(permission.level),
                      color: _getPermissionLevelColor(permission.level),
                      size: 20,
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveRole,
            child: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(widget.roleToEdit == null ? 'Créer' : 'Modifier'),
          ),
        ),
      ],
    );
  }

  void _togglePermission(String moduleId, String permissionId, bool selected) {
    setState(() {
      if (!_selectedPermissions.containsKey(moduleId)) {
        _selectedPermissions[moduleId] = [];
      }
      
      if (selected) {
        if (!_selectedPermissions[moduleId]!.contains(permissionId)) {
          _selectedPermissions[moduleId]!.add(permissionId);
        }
      } else {
        _selectedPermissions[moduleId]!.remove(permissionId);
        if (_selectedPermissions[moduleId]!.isEmpty) {
          _selectedPermissions.remove(moduleId);
        }
      }
    });
  }

  void _selectAllPermissions() {
    final provider = Provider.of<PermissionProvider>(context, listen: false);
    setState(() {
      _selectedPermissions.clear();
      for (final module in AppModule.allModules) {
        final permissions = provider.getModulePermissions(module.id);
        if (permissions.isNotEmpty) {
          _selectedPermissions[module.id] = permissions.map((p) => p.id).toList();
        }
      }
    });
  }

  void _clearAllPermissions() {
    setState(() {
      _selectedPermissions.clear();
    });
  }

  void _selectModulePermissions(String moduleId, List<Permission> permissions) {
    setState(() {
      _selectedPermissions[moduleId] = permissions.map((p) => p.id).toList();
    });
  }

  void _clearModulePermissions(String moduleId) {
    setState(() {
      _selectedPermissions.remove(moduleId);
    });
  }

  void _selectReadOnlyPermissions(String moduleId, List<Permission> permissions) {
    setState(() {
      _selectedPermissions[moduleId] = permissions
          .where((p) => p.level == PermissionLevel.read)
          .map((p) => p.id)
          .toList();
      if (_selectedPermissions[moduleId]!.isEmpty) {
        _selectedPermissions.remove(moduleId);
      }
    });
  }

  Future<void> _saveRole() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<PermissionProvider>(context, listen: false);
      
      final role = Role(
        id: widget.roleToEdit?.id ?? '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        color: _selectedColor,
        icon: _selectedIcon,
        modulePermissions: _selectedPermissions,
        isActive: _isActive,
        createdAt: widget.roleToEdit?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: widget.roleToEdit?.createdBy,
        lastModifiedBy: provider.currentUserId,
      );

      bool success = false;
      if (widget.roleToEdit == null) {
        // Créer un nouveau rôle
        final roleId = await RolesPermissionsService.createRole(
          role, 
          createdBy: provider.currentUserId ?? 'system'
        );
        success = roleId.isNotEmpty;
      } else {
        // Mettre à jour un rôle existant
        await RolesPermissionsService.updateRole(
          widget.roleToEdit!.id, 
          role, 
          updatedBy: provider.currentUserId ?? 'system'
        );
        success = true;
      }

      if (success && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.roleToEdit == null ? 'Rôle créé avec succès' : 'Rôle modifié avec succès'),
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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Color _parseColor(String colorString) {
    try {
      final hexColor = colorString.replaceAll('#', '');
      return Color(int.parse('FF$hexColor', radix: 16));
    } catch (e) {
      return AppTheme.blueStandard;
    }
  }

  IconData _parseIcon(String iconName) {
    switch (iconName) {
      case 'admin_panel_settings': return Icons.admin_panel_settings;
      case 'supervisor_account': return Icons.supervisor_account;
      case 'security': return Icons.security;
      case 'person': return Icons.person;
      case 'group': return Icons.group;
      case 'manage_accounts': return Icons.manage_accounts;
      case 'verified_user': return Icons.verified_user;
      case 'shield': return Icons.shield;
      default: return Icons.person;
    }
  }

  IconData _getModuleIcon(String iconName) {
    switch (iconName) {
      case 'dashboard': return Icons.dashboard;
      case 'people': return Icons.people;
      case 'group': return Icons.group;
      case 'event': return Icons.event;
      case 'church': return Icons.church;
      case 'task': return Icons.task;
      case 'article': return Icons.article;
      case 'monetization_on': return Icons.monetization_on;
      case 'music_note': return Icons.music_note;
      case 'menu_book': return Icons.menu_book;
      case 'description': return Icons.description;
      case 'web': return Icons.web;
      case 'favorite': return Icons.favorite;
      case 'settings': return Icons.settings;
      case 'admin_panel_settings': return Icons.admin_panel_settings;
      default: return Icons.extension;
    }
  }

  IconData _getPermissionLevelIcon(PermissionLevel level) {
    switch (level) {
      case PermissionLevel.read: return Icons.visibility;
      case PermissionLevel.write: return Icons.edit;
      case PermissionLevel.create: return Icons.add;
      case PermissionLevel.delete: return Icons.delete;
      case PermissionLevel.admin: return Icons.admin_panel_settings;
    }
  }

  Color _getPermissionLevelColor(PermissionLevel level) {
    switch (level) {
      case PermissionLevel.read: return AppTheme.blueStandard;
      case PermissionLevel.write: return AppTheme.greenStandard;
      case PermissionLevel.create: return AppTheme.orangeStandard;
      case PermissionLevel.delete: return AppTheme.redStandard;
      case PermissionLevel.admin: return Colors.purple;
    }
  }
}
