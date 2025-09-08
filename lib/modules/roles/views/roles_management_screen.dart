import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/permission_model.dart';
import '../models/role.dart' as RoleModel;
import '../services/permission_provider.dart';
import '../widgets/role_card.dart';
import '../widgets/create_role_dialog.dart';
import '../widgets/role_details_dialog.dart';
import '../widgets/permission_matrix_dialog.dart';
import '../widgets/user_role_assignment_widget.dart';
import '../widgets/bulk_role_assignment_widget.dart';
import '../widgets/role_settings_dialog.dart';
import 'role_assignment_screen.dart';

class RolesManagementScreen extends StatefulWidget {
  const RolesManagementScreen({super.key});

  @override
  State<RolesManagementScreen> createState() => _RolesManagementScreenState();
}

class _RolesManagementScreenState extends State<RolesManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  RoleFilter _currentFilter = RoleFilter.all;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Rôles et Permissions'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.admin_panel_settings), text: 'Rôles'),
            Tab(icon: Icon(Icons.security), text: 'Permissions'),
            Tab(icon: Icon(Icons.people), text: 'Assignations'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _navigateToFullAssignment,
            icon: const Icon(Icons.assignment_ind),
            tooltip: 'Interface d\'assignation complète',
          ),
          IconButton(
            onPressed: _showPermissionMatrix,
            icon: const Icon(Icons.grid_view),
            tooltip: 'Matrice des permissions',
          ),
          IconButton(
            onPressed: _showSettings,
            icon: const Icon(Icons.settings),
            tooltip: 'Paramètres',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRolesTab(),
          _buildPermissionsTab(),
          _buildAssignmentsTab(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildRolesTab() {
    return Consumer<PermissionProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(provider.error!, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.loadUserData(),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        final filteredRoles = _filterRoles(provider.roles);

        return Column(
          children: [
            _buildSearchAndFilter(),
            Expanded(
              child: filteredRoles.isEmpty
                  ? _buildEmptyState('Aucun rôle trouvé')
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredRoles.length,
                      itemBuilder: (context, index) {
                        final role = filteredRoles[index];
                        return RoleCard(
                          role: role,
                          onTap: () => _showRoleDetails(_convertToRoleModel(role)),
                          onEdit: role.isSystemRole ? null : () => _editRole(role),
                          onDelete: role.isSystemRole ? null : () => _deleteRole(role),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPermissionsTab() {
    return Consumer<PermissionProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final permissionsByModule = provider.permissionsByModule;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: AppModule.allModules.length,
          itemBuilder: (context, index) {
            final module = AppModule.allModules[index];
            final permissions = permissionsByModule[module.id] ?? [];

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ExpansionTile(
                leading: Icon(
                  _getModuleIcon(module.icon),
                  color: Theme.of(context).primaryColor,
                ),
                title: Text(module.name),
                subtitle: Text('${permissions.length} permissions'),
                children: permissions.map((permission) {
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      _getPermissionLevelIcon(permission.level),
                      size: 20,
                      color: _getPermissionLevelColor(permission.level),
                    ),
                    title: Text(permission.name),
                    subtitle: Text(permission.description),
                    trailing: Chip(
                      label: Text(permission.level.displayName),
                      backgroundColor: _getPermissionLevelColor(permission.level),
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAssignmentsTab() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: const TabBar(
              tabs: [
                Tab(
                  icon: Icon(Icons.people),
                  text: 'Assignation individuelle',
                ),
                Tab(
                  icon: Icon(Icons.group_add),
                  text: 'Assignation en masse',
                ),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                UserRoleAssignmentWidget(),
                BulkRoleAssignmentWidget(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher un rôle...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Filtrer:', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: RoleFilter.values.map((filter) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter.displayName),
                          selected: _currentFilter == filter,
                          onSelected: (selected) {
                            setState(() {
                              _currentFilter = filter;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.admin_panel_settings_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(message, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _createRole,
            child: const Text('Créer un rôle'),
          ),
        ],
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    if (_tabController.index == 0) {
      return FloatingActionButton(
        onPressed: _createRole,
        tooltip: 'Créer un rôle',
        child: const Icon(Icons.add),
      );
    }
    return null;
  }

  List<Role> _filterRoles(List<Role> roles) {
    var filtered = roles;

    // Appliquer le filtre
    switch (_currentFilter) {
      case RoleFilter.active:
        filtered = filtered.where((role) => role.isActive).toList();
        break;
      case RoleFilter.inactive:
        filtered = filtered.where((role) => !role.isActive).toList();
        break;
      case RoleFilter.system:
        filtered = filtered.where((role) => role.isSystemRole).toList();
        break;
      case RoleFilter.custom:
        filtered = filtered.where((role) => !role.isSystemRole).toList();
        break;
      case RoleFilter.all:
        break;
    }

    // Appliquer la recherche
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((role) =>
          role.name.toLowerCase().contains(query) ||
          role.description.toLowerCase().contains(query)
      ).toList();
    }

    return filtered;
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
      case PermissionLevel.read: return Colors.blue;
      case PermissionLevel.write: return Colors.green;
      case PermissionLevel.create: return Colors.orange;
      case PermissionLevel.delete: return Colors.red;
      case PermissionLevel.admin: return Colors.purple;
    }
  }

  void _createRole() {
    showDialog(
      context: context,
      builder: (context) => const CreateRoleDialog(),
    );
  }

  void _editRole(Role role) {
    showDialog(
      context: context,
      builder: (context) => CreateRoleDialog(role: role),
    );
  }

  void _deleteRole(Role role) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le rôle'),
        content: Text('Êtes-vous sûr de vouloir supprimer le rôle "${role.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final provider = Provider.of<PermissionProvider>(context, listen: false);
              final success = await provider.deleteRole(role.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Rôle supprimé' : 'Erreur lors de la suppression'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showRoleDetails(RoleModel.Role role) {
    showDialog(
      context: context,
      builder: (context) => RoleDetailsDialog(role: role),
    );
  }

  void _showPermissionMatrix() {
    showDialog(
      context: context,
      builder: (context) => const PermissionMatrixDialog(),
    );
  }

  void _navigateToFullAssignment() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RoleAssignmentScreen(),
      ),
    );
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => const RoleSettingsDialog(),
    );
  }

  // Fonction de conversion entre les deux types de Role
  RoleModel.Role _convertToRoleModel(Role permissionRole) {
    // Convertir modulePermissions (Map) en permissions (List)
    List<String> allPermissions = [];
    permissionRole.modulePermissions.forEach((module, permissions) {
      allPermissions.addAll(permissions);
    });

    return RoleModel.Role(
      id: permissionRole.id,
      name: permissionRole.name,
      description: permissionRole.description,
      permissions: allPermissions,
      isActive: permissionRole.isActive,
      createdAt: permissionRole.createdAt,
      updatedAt: permissionRole.updatedAt,
      color: permissionRole.color,
      icon: permissionRole.icon,
      createdBy: permissionRole.createdBy,
      lastModifiedBy: permissionRole.lastModifiedBy,
    );
  }
}

enum RoleFilter {
  all('Tous'),
  active('Actifs'),
  inactive('Inactifs'),
  system('Système'),
  custom('Personnalisés');

  const RoleFilter(this.displayName);
  final String displayName;
}
