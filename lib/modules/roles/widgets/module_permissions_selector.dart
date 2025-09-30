import 'package:flutter/material.dart';
import '../../../models/module_permission_model.dart';
import '../../../../theme.dart';

class ModulePermissionsSelector extends StatefulWidget {
  final List<ModulePermissionModel> initialPermissions;
  final ValueChanged<List<ModulePermissionModel>> onPermissionsChanged;
  final bool showCategories;
  final String? searchQuery;

  const ModulePermissionsSelector({
    super.key,
    required this.initialPermissions,
    required this.onPermissionsChanged,
    this.showCategories = true,
    this.searchQuery,
  });

  @override
  State<ModulePermissionsSelector> createState() => _ModulePermissionsSelectorState();
}

class _ModulePermissionsSelectorState extends State<ModulePermissionsSelector> {
  late List<ModulePermissionModel> _permissions;
  String _searchQuery = '';
  bool _selectAllModules = false;

  @override
  void initState() {
    super.initState();
    _permissions = List.from(widget.initialPermissions);
    _searchQuery = widget.searchQuery ?? '';
    _updateSelectAllState();
  }

  @override
  void didUpdateWidget(ModulePermissionsSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != oldWidget.searchQuery) {
      setState(() {
        _searchQuery = widget.searchQuery ?? '';
      });
    }
  }

  void _updateSelectAllState() {
    _selectAllModules = _permissions.every((modulePermission) =>
        modulePermission.permissions.values.any((hasPermission) => hasPermission));
  }

  void _onPermissionChanged(String moduleKey, PermissionType type, bool value) {
    setState(() {
      final index = _permissions.indexWhere((mp) => mp.module.key == moduleKey);
      if (index != -1) {
        _permissions[index].setPermission(type, value);
        _updateSelectAllState();
        widget.onPermissionsChanged(_permissions);
      }
    });
  }

  void _onModuleToggled(String moduleKey, bool value) {
    setState(() {
      final index = _permissions.indexWhere((mp) => mp.module.key == moduleKey);
      if (index != -1) {
        final module = _permissions[index].module;
        for (final permissionType in module.availablePermissions) {
          _permissions[index].setPermission(permissionType, value);
        }
        _updateSelectAllState();
        widget.onPermissionsChanged(_permissions);
      }
    });
  }

  void _toggleAllModules(bool value) {
    setState(() {
      _selectAllModules = value;
      for (final modulePermission in _permissions) {
        for (final permissionType in modulePermission.module.availablePermissions) {
          modulePermission.setPermission(permissionType, value);
        }
      }
      widget.onPermissionsChanged(_permissions);
    });
  }

  bool _moduleHasAnyPermission(ModulePermissionModel modulePermission) {
    return modulePermission.permissions.values.any((hasPermission) => hasPermission);
  }

  List<ModulePermissionModel> get _filteredPermissions {
    if (_searchQuery.isEmpty) return _permissions;
    
    return _permissions.where((modulePermission) {
      final module = modulePermission.module;
      return module.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             module.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             module.category.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredPermissions = _filteredPermissions;
    
    if (widget.showCategories) {
      return _buildCategorizedView(filteredPermissions);
    } else {
      return _buildListView(filteredPermissions);
    }
  }

  Widget _buildCategorizedView(List<ModulePermissionModel> permissions) {
    final categories = <String, List<ModulePermissionModel>>{};
    
    for (final permission in permissions) {
      categories.putIfAbsent(permission.module.category, () => []);
      categories[permission.module.category]!.add(permission);
    }

    return Column(
      children: [
        // En-tête avec sélection globale
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Checkbox(
                  value: _selectAllModules,
                  onChanged: (bool? value) => _toggleAllModules(value ?? false),
                ),
                const SizedBox(width: 8),
                Text(
                  'Sélectionner tous les modules',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Liste des catégories
        Expanded(
          child: ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories.keys.elementAt(index);
              final modulePermissions = categories[category]!;
              
              return _buildCategorySection(category, modulePermissions);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildListView(List<ModulePermissionModel> permissions) {
    return ListView.builder(
      itemCount: permissions.length,
      itemBuilder: (context, index) {
        return _buildModuleCard(permissions[index]);
      },
    );
  }

  Widget _buildCategorySection(String category, List<ModulePermissionModel> modulePermissions) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: Icon(
          _getCategoryIcon(category),
          color: Theme.of(context).primaryColor,
        ),
        title: Text(
          category,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: AppTheme.fontBold,
          ),
        ),
        subtitle: Text('${modulePermissions.length} module(s)'),
        children: modulePermissions.map((modulePermission) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildModuleCard(modulePermission, isInCategory: true),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildModuleCard(ModulePermissionModel modulePermission, {bool isInCategory = false}) {
    final module = modulePermission.module;
    final hasAnyPermission = _moduleHasAnyPermission(modulePermission);

    return Card(
      elevation: isInCategory ? 1 : 2,
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Icon(
          module.icon,
          color: hasAnyPermission ? Theme.of(context).primaryColor : AppTheme.grey500,
        ),
        title: Row(
          children: [
            Checkbox(
              value: hasAnyPermission,
              onChanged: (value) => _onModuleToggled(module.key, value ?? false),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    module.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: hasAnyPermission ? AppTheme.fontBold : FontWeight.normal,
                    ),
                  ),
                  Text(
                    module.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.grey600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        trailing: hasAnyPermission
            ? Chip(
                label: Text(
                  '${modulePermission.permissions.values.where((v) => v).length}/${module.availablePermissions.length}',
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              )
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: module.availablePermissions.map((permissionType) {
                final hasPermission = modulePermission.hasPermission(permissionType);
                
                return CheckboxListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.only(left: 32),
                  secondary: Icon(
                    permissionType.icon,
                    size: 20,
                    color: hasPermission ? Theme.of(context).primaryColor : AppTheme.grey500,
                  ),
                  title: Text(
                    permissionType.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: hasPermission ? AppTheme.fontMedium : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    permissionType.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.grey600,
                    ),
                  ),
                  value: hasPermission,
                  onChanged: (value) => _onPermissionChanged(
                    module.key,
                    permissionType,
                    value ?? false,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'gestion des données':
        return Icons.storage;
      case 'planification':
        return Icons.schedule;
      case 'contenu':
        return Icons.content_copy;
      case 'finance':
        return Icons.attach_money;
      case 'communication':
        return Icons.chat;
      case 'administration':
        return Icons.admin_panel_settings;
      default:
        return Icons.folder;
    }
  }
}

/// Widget pour afficher un résumé des permissions sélectionnées
class PermissionsSummary extends StatelessWidget {
  final List<ModulePermissionModel> permissions;
  final VoidCallback? onEdit;

  const PermissionsSummary({
    super.key,
    required this.permissions,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final activeModules = permissions.where((mp) => 
        mp.permissions.values.any((hasPermission) => hasPermission)).toList();
    
    final totalPermissions = permissions.fold<int>(0, (sum, mp) => 
        sum + mp.permissions.values.where((v) => v).length);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Résumé des permissions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: AppTheme.fontBold,
                  ),
                ),
                if (onEdit != null)
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Modifier'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Icon(Icons.apps, color: Theme.of(context).primaryColor, size: 20),
                const SizedBox(width: 8),
                Text('${activeModules.length} module(s) avec permissions'),
              ],
            ),
            const SizedBox(width: 8),
            
            Row(
              children: [
                Icon(Icons.security, color: Theme.of(context).primaryColor, size: 20),
                const SizedBox(width: 8),
                Text('$totalPermissions permission(s) accordée(s)'),
              ],
            ),
            
            if (activeModules.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: activeModules.map((mp) {
                  final permissionCount = mp.permissions.values.where((v) => v).length;
                  return Chip(
                    avatar: Icon(mp.module.icon, size: 16),
                    label: Text(
                      '${mp.module.name} ($permissionCount)',
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
