import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/role_provider.dart';
import '../models/role.dart';
import '../models/user_role.dart';
import '../widgets/bulk_role_assignment_widget.dart';
import '../widgets/export_options_dialog.dart' as widgets;
import '../widgets/print_options_dialog.dart' as widgets;
import '../dialogs/create_edit_role_dialog.dart';
import '../services/current_user_service.dart';

class NewRolesManagementScreen extends StatefulWidget {
  const NewRolesManagementScreen({super.key});

  @override
  State<NewRolesManagementScreen> createState() => _NewRolesManagementScreenState();
}

class _NewRolesManagementScreenState extends State<NewRolesManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _userSearchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      final provider = Provider.of<RoleProvider>(context, listen: false);
      provider.updateSearchQuery(_searchController.text);
    });
    
    // Initialiser le provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<RoleProvider>(context, listen: false);
      provider.initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _userSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Rôles'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'export':
                  _showExportDialog();
                  break;
                case 'print':
                  _showPrintDialog();
                  break;
                case 'bulk_assign':
                  // Pour l'instant, on affiche un message informatif
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Utilisez l\'onglet Assignations pour ces fonctionnalités')),
                  );
                  break;
                case 'assign_to_person':
                  // Pour l'instant, on affiche un message informatif
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Utilisez l\'onglet Assignations pour ces fonctionnalités')),
                  );
                  break;
                case 'migrate':
                  _showMigrationDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.file_download),
                    SizedBox(width: 8),
                    Text('Exporter'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'print',
                child: Row(
                  children: [
                    Icon(Icons.print),
                    SizedBox(width: 8),
                    Text('Imprimer'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'bulk_assign',
                child: Row(
                  children: [
                    Icon(Icons.group_add),
                    SizedBox(width: 8),
                    Text('Assignation en masse'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'assign_to_person',
                child: Row(
                  children: [
                    Icon(Icons.person_add),
                    SizedBox(width: 8),
                    Text('Assigner à une personne'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'migrate',
                child: Row(
                  children: [
                    Icon(Icons.sync),
                    SizedBox(width: 8),
                    Text('Migrer les rôles'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.security), text: 'Rôles'),
            Tab(icon: Icon(Icons.people), text: 'Utilisateurs'),
            Tab(icon: Icon(Icons.assignment), text: 'Assignations'),
          ],
        ),
      ),
      body: Consumer<RoleProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Erreur: ${provider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.initialize(),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildRolesTab(provider),
              _buildUsersTab(provider),
              _buildAssignmentsTab(provider),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateRoleDialog(),
        child: const Icon(Icons.add),
        tooltip: 'Créer un rôle',
      ),
    );
  }

  Widget _buildRolesTab(RoleProvider provider) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Rechercher des rôles',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: provider.activeRoles.length,
            itemBuilder: (context, index) {
              final role = provider.activeRoles[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getRoleColor(role.id),
                    child: Icon(
                      _getRoleIcon(role.id),
                      color: Colors.white,
                    ),
                  ),
                  title: Text(role.name),
                  subtitle: Text(role.description),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${role.permissions.length} permissions'),
                      const SizedBox(width: 8),
                      PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              leading: Icon(Icons.edit),
                              title: Text('Modifier'),
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(Icons.delete),
                              title: Text('Supprimer'),
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              _showEditRoleDialog(role);
                              break;
                            case 'delete':
                              _showDeleteRoleDialog(role);
                              break;
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUsersTab(RoleProvider provider) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _userSearchController,
            decoration: const InputDecoration(
              labelText: 'Rechercher des utilisateurs',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              provider.updateSearchQuery(value);
            },
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: provider.filteredUserRoles.length,
            itemBuilder: (context, index) {
              final userRole = provider.filteredUserRoles[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(userRole.userName.substring(0, 1).toUpperCase()),
                  ),
                  title: Text(userRole.userName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userRole.userEmail),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        children: userRole.roleIds.map((roleId) {
                          final role = provider.getRoleById(roleId);
                          return Chip(
                            label: Text(
                              role?.name ?? roleId,
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: _getRoleColor(roleId).withOpacity(0.2),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Modifier les rôles'),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'remove',
                        child: ListTile(
                          leading: Icon(Icons.remove_circle),
                          title: Text('Retirer les rôles'),
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _showEditUserRolesDialog(userRole);
                          break;
                        case 'remove':
                          _showRemoveUserRolesDialog(userRole);
                          break;
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAssignmentsTab(RoleProvider provider) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showAssignRolesToPersonDialog(),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Assigner des rôles à une personne'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showAssignRoleToPersonsDialog(),
                  icon: const Icon(Icons.group_add),
                  label: const Text('Assigner un rôle à plusieurs personnes'),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: BulkRoleAssignmentWidget(),
        ),
      ],
    );
  }

  Color _getRoleColor(String roleId) {
    switch (roleId) {
      case 'admin': return Colors.red;
      case 'moderator': return Colors.orange;
      case 'contributor': return Colors.blue;
      case 'viewer': return Colors.green;
      default: return Colors.grey;
    }
  }

  IconData _getRoleIcon(String roleId) {
    switch (roleId) {
      case 'admin': return Icons.admin_panel_settings;
      case 'moderator': return Icons.shield;
      case 'contributor': return Icons.edit;
      case 'viewer': return Icons.visibility;
      default: return Icons.person;
    }
  }

  void _showCreateRoleDialog() {
    showDialog(
      context: context,
      builder: (context) => const CreateEditRoleDialog(),
    ).then((result) {
      if (result == true) {
        // Le rôle a été créé avec succès
        // Le provider se mettra à jour automatiquement via les streams
      }
    });
  }

  void _showEditRoleDialog(Role role) {
    showDialog(
      context: context,
      builder: (context) => CreateEditRoleDialog(existingRole: role),
    ).then((result) {
      if (result == true) {
        // Le rôle a été modifié avec succès
        // Le provider se mettra à jour automatiquement via les streams
      }
    });
  }

  void _showDeleteRoleDialog(Role role) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer ${role.name}'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce rôle ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final provider = Provider.of<RoleProvider>(context, listen: false);
              final success = await provider.deleteRole(role.id);
              if (!success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur: ${provider.error}')),
                );
              }
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showEditUserRolesDialog(UserRole userRole) {
    showDialog(
      context: context,
      builder: (context) => _EditUserRolesDialog(userRole: userRole),
    );
  }

  void _showRemoveUserRolesDialog(UserRole userRole) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Retirer les rôles de ${userRole.userName}'),
        content: const Text('Êtes-vous sûr de vouloir retirer tous les rôles de cet utilisateur ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final provider = Provider.of<RoleProvider>(context, listen: false);
              final success = await provider.deactivateUserRoles(userRole.userId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success 
                        ? 'Rôles retirés avec succès' 
                        : 'Erreur: ${provider.error}'),
                  ),
                );
              }
            },
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
  }

  void _showAssignRolesToPersonDialog() {
    // Pour l'instant, affichons un message informatif
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Utilisez l\'interface dans l\'onglet pour assigner des rôles à une personne'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showAssignRoleToPersonsDialog() {
    // Pour l'instant, affichons un message informatif
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Utilisez l\'interface dans l\'onglet pour assigner un rôle à plusieurs personnes'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Afficher le dialogue d'export
  void _showExportDialog() {
    final provider = Provider.of<RoleProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => widgets.ExportOptionsDialog(
        roles: provider.roles,
        permissions: provider.permissions.map((p) => p.id).toList(),
        userRoles: provider.userRoles,
      ),
    );
  }

  /// Afficher le dialogue d'impression
  void _showPrintDialog() {
    final provider = Provider.of<RoleProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => widgets.PrintOptionsDialog(
        roles: provider.roles,
        permissions: provider.permissions.map((p) => p.id).toList(),
        userRoles: provider.userRoles,
      ),
    );
  }

  void _showMigrationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.sync, color: Colors.orange),
            SizedBox(width: 8),
            Text('Migration des rôles'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cette action va migrer les rôles depuis la collection "persons" vers "user_roles".',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Cela permettra d\'afficher correctement tous les utilisateurs avec leurs rôles dans l\'onglet "Utilisateurs".',
            ),
            SizedBox(height: 16),
            Text(
              '⚠️ Cette action est sûre et ne supprimera aucune donnée existante.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _performMigration();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Migrer'),
          ),
        ],
      ),
    );
  }

  Future<void> _performMigration() async {
    final provider = Provider.of<RoleProvider>(context, listen: false);
    
    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Migration en cours...'),
          ],
        ),
      ),
    );

    try {
      final result = await provider.migratePersonsRolesToUserRoles();
      
      if (mounted) {
        Navigator.of(context).pop(); // Fermer le dialogue de chargement
        
        // Afficher les résultats
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Migration terminée'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('✅ Personnes migrées: ${result['migrated']}'),
                Text('⏭️ Personnes ignorées: ${result['skipped']}'),
                Text('❌ Erreurs: ${result['errors']}'),
                Text('📊 Total traité: ${result['total']}'),
                const SizedBox(height: 16),
                const Text(
                  'L\'onglet Utilisateurs devrait maintenant afficher tous les utilisateurs avec leurs rôles.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Fermer le dialogue de chargement
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la migration: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _AssignRoleDialog extends StatefulWidget {
  @override
  State<_AssignRoleDialog> createState() => _AssignRoleDialogState();
}

class _AssignRoleDialogState extends State<_AssignRoleDialog> {
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _userEmailController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();
  List<String> _selectedRoleIds = [];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Assigner des rôles'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _userIdController,
              decoration: const InputDecoration(
                labelText: 'ID Utilisateur',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _userEmailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _userNameController,
              decoration: const InputDecoration(
                labelText: 'Nom',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Sélectionner des rôles:'),
            Consumer<RoleProvider>(
              builder: (context, provider, child) {
                return Column(
                  children: provider.activeRoles.map((role) {
                    return CheckboxListTile(
                      title: Text(role.name),
                      subtitle: Text(role.description),
                      value: _selectedRoleIds.contains(role.id),
                      onChanged: (selected) {
                        setState(() {
                          if (selected == true) {
                            _selectedRoleIds.add(role.id);
                          } else {
                            _selectedRoleIds.remove(role.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                );
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
          onPressed: _selectedRoleIds.isEmpty || 
                   _userIdController.text.isEmpty ||
                   _userEmailController.text.isEmpty ||
                   _userNameController.text.isEmpty
              ? null
              : () async {
                  final provider = Provider.of<RoleProvider>(context, listen: false);
                  final success = await provider.assignRolesToUser(
                    userId: _userIdController.text,
                    userEmail: _userEmailController.text,
                    userName: _userNameController.text,
                    roleIds: _selectedRoleIds,
                    assignedBy: CurrentUserService().getCurrentUserIdOrDefault(),
                  );
                  
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success 
                            ? 'Rôles assignés avec succès' 
                            : 'Erreur: ${provider.error}'),
                      ),
                    );
                  }
                },
          child: const Text('Assigner'),
        ),
      ],
    );
  }
}

class _EditUserRolesDialog extends StatefulWidget {
  final UserRole userRole;

  const _EditUserRolesDialog({required this.userRole});

  @override
  State<_EditUserRolesDialog> createState() => _EditUserRolesDialogState();
}

class _EditUserRolesDialogState extends State<_EditUserRolesDialog> {
  late List<String> _selectedRoleIds;

  @override
  void initState() {
    super.initState();
    _selectedRoleIds = List.from(widget.userRole.roleIds);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Modifier les rôles de ${widget.userRole.userName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Email: ${widget.userRole.userEmail}'),
            const SizedBox(height: 16),
            const Text('Sélectionner des rôles:'),
            Consumer<RoleProvider>(
              builder: (context, provider, child) {
                return Column(
                  children: provider.activeRoles.map((role) {
                    return CheckboxListTile(
                      title: Text(role.name),
                      subtitle: Text(role.description),
                      value: _selectedRoleIds.contains(role.id),
                      onChanged: (selected) {
                        setState(() {
                          if (selected == true) {
                            _selectedRoleIds.add(role.id);
                          } else {
                            _selectedRoleIds.remove(role.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                );
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
          onPressed: () async {
            final provider = Provider.of<RoleProvider>(context, listen: false);
            final success = await provider.assignRolesToUser(
              userId: widget.userRole.userId,
              userEmail: widget.userRole.userEmail,
              userName: widget.userRole.userName,
              roleIds: _selectedRoleIds,
              assignedBy: CurrentUserService().getCurrentUserIdOrDefault(),
            );
            
            if (mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success 
                      ? 'Rôles modifiés avec succès' 
                      : 'Erreur: ${provider.error}'),
                ),
              );
            }
          },
          child: const Text('Sauvegarder'),
        ),
      ],
    );
  }

}
