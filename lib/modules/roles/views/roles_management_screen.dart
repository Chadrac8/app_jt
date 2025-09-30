import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/permission_model.dart';
import '../providers/permission_provider.dart';
import '../services/roles_permissions_service.dart';
import '../widgets/role_card_widget.dart';
import '../widgets/create_role_dialog.dart';
import '../widgets/permission_guard_widget.dart';

/// Écran principal de gestion des rôles avec Material Design 3
class RolesManagementScreen extends StatefulWidget {
  const RolesManagementScreen({super.key});

  @override
  State<RolesManagementScreen> createState() => _RolesManagementScreenState();
}

class _RolesManagementScreenState extends State<RolesManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeData();
  }

  Future<void> _initializeData() async {
    final provider = Provider.of<PermissionProvider>(context, listen: false);
    if (!provider.isInitialized) {
      // Initialiser avec l'ID utilisateur - à adapter selon votre système d'auth
      await provider.initialize('current_user_id');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PermissionProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: _buildAppBar(context, provider),
          body: provider.isLoading 
              ? _buildLoadingScreen()
              : provider.error != null
                  ? _buildErrorScreen(provider.error!)
                  : _buildContent(context, provider),
          floatingActionButton: _buildFloatingActionButton(context, provider),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, PermissionProvider provider) {
    final theme = Theme.of(context);
    
    return AppBar(
      elevation: 0,
      backgroundColor: theme.colorScheme.surface,
      foregroundColor: theme.colorScheme.onSurface,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gestion des rôles',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (provider.roles.isNotEmpty)
            Text(
              '${provider.roles.length} rôles • ${provider.systemRoles.length} système',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => _showStatsDialog(context, provider),
          icon: const Icon(Icons.analytics_outlined),
          tooltip: 'Statistiques',
        ),
        IconButton(
          onPressed: provider.refresh,
          icon: const Icon(Icons.refresh_outlined),
          tooltip: 'Actualiser',
        ),
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(context, value, provider),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'init_system',
              child: Row(
                children: [
                  Icon(Icons.system_security_update_good),
                  SizedBox(width: 8),
                  Text('Initialiser le système'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.download),
                  SizedBox(width: 8),
                  Text('Exporter'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings),
                  SizedBox(width: 8),
                  Text('Paramètres'),
                ],
              ),
            ),
          ],
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(
            icon: Icon(Icons.admin_panel_settings),
            text: 'Tous les rôles',
          ),
          Tab(
            icon: Icon(Icons.verified_user),
            text: 'Rôles système',
          ),
          Tab(
            icon: Icon(Icons.person_add),
            text: 'Rôles personnalisés',
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, PermissionProvider provider) {
    return Column(
      children: [
        _buildSearchBar(context),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRolesList(context, provider.searchRoles(_searchQuery)),
              _buildRolesList(context, provider.systemRoles.where((role) =>
                  _searchQuery.isEmpty || 
                  role.name.toLowerCase().contains(_searchQuery.toLowerCase())
              ).toList()),
              _buildRolesList(context, provider.customRoles.where((role) =>
                  _searchQuery.isEmpty || 
                  role.name.toLowerCase().contains(_searchQuery.toLowerCase())
              ).toList()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: SearchBar(
        controller: _searchController,
        hintText: 'Rechercher des rôles...',
        leading: const Icon(Icons.search),
        trailing: _searchQuery.isNotEmpty
            ? [
                IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  icon: const Icon(Icons.clear),
                ),
              ]
            : null,
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
        backgroundColor: WidgetStateProperty.all(
          theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildRolesList(BuildContext context, List<Role> roles) {
    if (roles.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: roles.length,
      itemBuilder: (context, index) {
        final role = roles[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: RoleCardWidget(
            role: role,
            onTap: () => _showRoleDetails(context, role),
            onEdit: role.isSystemRole 
                ? null 
                : () => _editRole(context, role),
            onDelete: role.isSystemRole 
                ? null 
                : () => _deleteRole(context, role),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.admin_panel_settings_outlined,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun rôle trouvé',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Essayez de modifier votre recherche'
                : 'Créez votre premier rôle personnalisé',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _createRole(context),
              icon: const Icon(Icons.add),
              label: const Text('Créer un rôle'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Chargement des rôles...'),
        ],
      ),
    );
  }

  Widget _buildErrorScreen(String error) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              final provider = Provider.of<PermissionProvider>(context, listen: false);
              provider.refresh();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget? _buildFloatingActionButton(BuildContext context, PermissionProvider provider) {
    return PermissionGuardWidget(
      requiredPermission: 'roles_create',
      child: FloatingActionButton.extended(
        onPressed: () => _createRole(context),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau rôle'),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action, PermissionProvider provider) {
    switch (action) {
      case 'init_system':
        _initializeSystem(context);
        break;
      case 'export':
        _exportRoles(context);
        break;
      case 'settings':
        _showSettings(context);
        break;
    }
  }

  void _showRoleDetails(BuildContext context, Role role) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.admin_panel_settings,
              color: Color(int.parse(role.color.substring(1), radix: 16) + 0xFF000000),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(role.name),
            ),
            if (role.isSystemRole)
              Chip(
                label: const Text('Système'),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(role.description),
              const SizedBox(height: 16),
              Text(
                'Permissions (${role.allPermissions.length})',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ...role.modulePermissions.entries.map((entry) {
                final moduleName = AppModule.allModules
                    .where((m) => m.id == entry.key)
                    .firstOrNull?.name ?? entry.key;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$moduleName (${entry.value.length} permissions)',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          if (!role.isSystemRole) ...[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _editRole(context, role);
              },
              child: const Text('Modifier'),
            ),
          ],
        ],
      ),
    );
  }

  void _createRole(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CreateRoleDialog(
        onRoleCreated: (role) {
          final provider = Provider.of<PermissionProvider>(context, listen: false);
          provider.refresh();
          _showSuccessSnackBar(context, 'Rôle "${role.name}" créé avec succès');
        },
      ),
    );
  }

  void _editRole(BuildContext context, Role role) {
    showDialog(
      context: context,
      builder: (context) => CreateRoleDialog(
        roleToEdit: role,
        onRoleCreated: (updatedRole) {
          final provider = Provider.of<PermissionProvider>(context, listen: false);
          provider.refresh();
          _showSuccessSnackBar(context, 'Rôle "${updatedRole.name}" modifié avec succès');
        },
      ),
    );
  }

  void _deleteRole(BuildContext context, Role role) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le rôle'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer le rôle "${role.name}" ?\n\n'
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              await _performDeleteRole(context, role);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _performDeleteRole(BuildContext context, Role role) async {
    try {
      // Ici vous devriez implémenter la suppression via votre service
      // await RolesPermissionsService.deleteRole(role.id);
      
      final provider = Provider.of<PermissionProvider>(context, listen: false);
      await provider.refresh();
      
      _showSuccessSnackBar(context, 'Rôle "${role.name}" supprimé avec succès');
    } catch (e) {
      _showErrorSnackBar(context, 'Erreur lors de la suppression: $e');
    }
  }

  void _showStatsDialog(BuildContext context, PermissionProvider provider) {
    final stats = provider.getRolesStats();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Statistiques des rôles'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatRow('Rôles totaux', stats['total_roles'].toString()),
              _buildStatRow('Rôles actifs', stats['active_roles'].toString()),
              _buildStatRow('Rôles système', stats['system_roles'].toString()),
              _buildStatRow('Rôles personnalisés', stats['custom_roles'].toString()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _initializeSystem(BuildContext context) async {
    try {
      await RolesPermissionsService.initializeSystem();
      final provider = Provider.of<PermissionProvider>(context, listen: false);
      await provider.refresh();
      _showSuccessSnackBar(context, 'Système initialisé avec succès');
    } catch (e) {
      _showErrorSnackBar(context, 'Erreur lors de l\'initialisation: $e');
    }
  }

  void _exportRoles(BuildContext context) {
    _showSuccessSnackBar(context, 'Fonction d\'export à implémenter');
  }

  void _showSettings(BuildContext context) {
    _showSuccessSnackBar(context, 'Paramètres à implémenter');
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
