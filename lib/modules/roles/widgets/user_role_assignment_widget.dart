import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/permission_model.dart';
import '../providers/permission_provider.dart';
import '../../../../theme.dart';

/// Widget pour l'assignation de rôles aux utilisateurs
class UserRoleAssignmentWidget extends StatefulWidget {
  const UserRoleAssignmentWidget({super.key});

  @override
  State<UserRoleAssignmentWidget> createState() => _UserRoleAssignmentWidgetState();
}

class _UserRoleAssignmentWidgetState extends State<UserRoleAssignmentWidget> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedRoleFilter;
  bool _showInactiveUsers = false;

  @override
  void initState() {
    super.initState();
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

  // Utilitaires pour convertir les strings en objets Flutter
  Color _parseColor(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
      }
      switch (colorString.toLowerCase()) {
        case 'blue': return AppTheme.blueStandard;
        case 'green': return AppTheme.greenStandard;
        case 'red': return AppTheme.redStandard;
        case 'orange': return AppTheme.orangeStandard;
        case 'purple': return AppTheme.primaryColor;
        case 'teal': return AppTheme.secondaryColor;
        case 'indigo': return AppTheme.secondaryColor;
        default: return AppTheme.blueStandard;
      }
    } catch (e) {
      return AppTheme.blueStandard;
    }
  }

  IconData _parseIcon(String iconString) {
    switch (iconString.toLowerCase()) {
      case 'admin_panel_settings': return Icons.admin_panel_settings;
      case 'person': return Icons.person;
      case 'people': return Icons.people;
      case 'security': return Icons.security;
      case 'supervisor_account': return Icons.supervisor_account;
      case 'volunteer_activism': return Icons.volunteer_activism;
      case 'work': return Icons.work;
      case 'school': return Icons.school;
      case 'settings': return Icons.settings;
      case 'shield': return Icons.shield;
      default: return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchAndFilters(),
        Expanded(
          child: _buildUsersList(),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher un utilisateur...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
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
            ),
          ),
          const SizedBox(height: AppTheme.space12),
          Row(
            children: [
              Expanded(
                child: Consumer<PermissionProvider>(
                  builder: (context, provider, child) {
                    final roles = provider.roles;
                    return DropdownButtonFormField<String>(
                      initialValue: _selectedRoleFilter,
                      decoration: InputDecoration(
                        labelText: 'Filtrer par rôle',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Tous les rôles'),
                        ),
                        ...roles.map((role) => DropdownMenuItem(
                          value: role.id,
                          child: Text(role.name),
                        )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedRoleFilter = value;
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              FilterChip(
                label: const Text('Inactifs'),
                selected: _showInactiveUsers,
                onSelected: (selected) {
                  setState(() {
                    _showInactiveUsers = selected;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    return Consumer<PermissionProvider>(
      builder: (context, provider, child) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('persons')
              .where('isActive', isEqualTo: _showInactiveUsers ? null : true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Erreur: ${snapshot.error}'),
              );
            }

            final users = snapshot.data?.docs ?? [];
            final filteredUsers = users.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final name = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.toLowerCase();
              final email = (data['email'] ?? '').toLowerCase();
              
              return _searchQuery.isEmpty ||
                     name.contains(_searchQuery) ||
                     email.contains(_searchQuery);
            }).toList();

            if (filteredUsers.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 64, color: AppTheme.grey500),
                    SizedBox(height: AppTheme.spaceMedium),
                    Text('Aucun utilisateur trouvé'),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final userDoc = filteredUsers[index];
                return _buildUserRoleCard(userDoc);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildUserRoleCard(QueryDocumentSnapshot userDoc) {
    final userData = userDoc.data() as Map<String, dynamic>;
    final userId = userDoc.id;
    final firstName = userData['firstName'] ?? '';
    final lastName = userData['lastName'] ?? '';
    final email = userData['email'] ?? '';
    final photoUrl = userData['photoUrl'] as String?;
    final isActive = userData['isActive'] ?? true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: isActive ? AppTheme.greenStandard : AppTheme.grey500,
          backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
          child: photoUrl == null
              ? Text(
                  firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                  style: const TextStyle(color: AppTheme.white100),
                )
              : null,
        ),
        title: Text(
          '$firstName $lastName',
          style: TextStyle(
            fontWeight: AppTheme.fontSemiBold,
            color: isActive ? null : AppTheme.grey500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (email.isNotEmpty) Text(email),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('user_roles')
                  .where('userId', isEqualTo: userId)
                  .snapshots(),
              builder: (context, snapshot) {
                final userRoles = snapshot.data?.docs ?? [];
                if (userRoles.isEmpty) {
                  return const Text(
                    'Aucun rôle assigné',
                    style: TextStyle(color: AppTheme.orangeStandard),
                  );
                }
                return Text(
                  '${userRoles.length} rôle(s) assigné(s)',
                  style: TextStyle(
                    color: AppTheme.grey600,
                    fontWeight: AppTheme.fontMedium,
                  ),
                );
              },
            ),
          ],
        ),
        children: [
          _buildUserRolesList(userId),
        ],
      ),
    );
  }

  Widget _buildUserRolesList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('user_roles')
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(AppTheme.spaceMedium),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final userRoleDocs = snapshot.data?.docs ?? [];
        
        return Consumer<PermissionProvider>(
          builder: (context, provider, child) {
            final roles = provider.roles;
            
            return Padding(
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rôles assignés (${userRoleDocs.length})',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: AppTheme.fontSemiBold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showAssignRoleToUserDialog(userId),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Ajouter'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space12),
                  if (userRoleDocs.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spaceMedium),
                      decoration: BoxDecoration(
                        color: AppTheme.grey50,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber, color: AppTheme.orangeStandard),
                          SizedBox(width: AppTheme.spaceSmall),
                          Text('Aucun rôle assigné à cet utilisateur'),
                        ],
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: userRoleDocs.map((userRoleDoc) {
                        final userRoleData = userRoleDoc.data() as Map<String, dynamic>;
                        final roleId = userRoleData['roleId'] as String;
                        
                        final role = roles.firstWhere(
                          (r) => r.id == roleId,
                          orElse: () => Role(
                            id: roleId,
                            name: 'Rôle inconnu',
                            description: '',
                            color: '#9E9E9E',
                            icon: 'help',
                            modulePermissions: {},
                            isActive: false,
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                          ),
                        );
                        
                        final roleColor = _parseColor(role.color);
                        final roleIcon = _parseIcon(role.icon);
                        
                        return Chip(
                          avatar: Icon(
                            roleIcon,
                            size: 16,
                            color: roleColor,
                          ),
                          label: Text(role.name),
                          backgroundColor: roleColor.withValues(alpha: 0.1),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () => _revokeRole(userId, roleId, role.name),
                        );
                      }).toList(),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showAssignRoleToUserDialog(String userId) async {
    showDialog(
      context: context,
      builder: (context) => _AssignRoleToUserDialog(userId: userId),
    );
  }

  Future<void> _revokeRole(String userId, String roleId, String roleName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la révocation'),
        content: Text(
          'Voulez-vous vraiment révoquer le rôle "$roleName" pour cet utilisateur ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.redStandard),
            child: const Text('Révoquer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('user_roles')
            .where('userId', isEqualTo: userId)
            .where('roleId', isEqualTo: roleId)
            .get()
            .then((querySnapshot) {
          for (var doc in querySnapshot.docs) {
            doc.reference.delete();
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Rôle "$roleName" révoqué avec succès'),
              backgroundColor: AppTheme.greenStandard,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la révocation: $e'),
              backgroundColor: AppTheme.redStandard,
            ),
          );
        }
      }
    }
  }
}

/// Dialog pour assigner un rôle à un utilisateur spécifique
class _AssignRoleToUserDialog extends StatefulWidget {
  final String userId;

  const _AssignRoleToUserDialog({required this.userId});

  @override
  State<_AssignRoleToUserDialog> createState() => _AssignRoleToUserDialogState();
}

class _AssignRoleToUserDialogState extends State<_AssignRoleToUserDialog> {
  String? _selectedRoleId;
  bool _isLoading = false;

  Color _parseColor(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
      }
      switch (colorString.toLowerCase()) {
        case 'blue': return AppTheme.blueStandard;
        case 'green': return AppTheme.greenStandard;
        case 'red': return AppTheme.redStandard;
        case 'orange': return AppTheme.orangeStandard;
        case 'purple': return AppTheme.primaryColor;
        case 'teal': return AppTheme.secondaryColor;
        case 'indigo': return AppTheme.secondaryColor;
        default: return AppTheme.blueStandard;
      }
    } catch (e) {
      return AppTheme.blueStandard;
    }
  }

  IconData _parseIcon(String iconString) {
    switch (iconString.toLowerCase()) {
      case 'admin_panel_settings': return Icons.admin_panel_settings;
      case 'person': return Icons.person;
      case 'people': return Icons.people;
      case 'security': return Icons.security;
      case 'supervisor_account': return Icons.supervisor_account;
      case 'volunteer_activism': return Icons.volunteer_activism;
      case 'work': return Icons.work;
      case 'school': return Icons.school;
      case 'settings': return Icons.settings;
      case 'shield': return Icons.shield;
      default: return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Assigner un rôle'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Sélectionnez un rôle à assigner à cet utilisateur :'),
            const SizedBox(height: AppTheme.spaceMedium),
            Consumer<PermissionProvider>(
              builder: (context, provider, child) {
                final availableRoles = provider.roles.where((role) => role.isActive).toList();
                
                if (availableRoles.isEmpty) {
                  return const Text('Aucun rôle disponible');
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('user_roles')
                      .where('userId', isEqualTo: widget.userId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final userRoles = snapshot.data?.docs ?? [];
                    final assignedRoleIds = userRoles
                        .map((doc) => (doc.data() as Map<String, dynamic>)['roleId'] as String)
                        .toSet();

                    final unassignedRoles = availableRoles
                        .where((role) => !assignedRoleIds.contains(role.id))
                        .toList();

                    if (unassignedRoles.isEmpty) {
                      return const Text('Tous les rôles disponibles sont déjà assignés');
                    }

                    return DropdownButtonFormField<String>(
                      initialValue: _selectedRoleId,
                      hint: const Text('Choisir un rôle...'),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: unassignedRoles.map((role) {
                        final roleColor = _parseColor(role.color);
                        final roleIcon = _parseIcon(role.icon);
                        
                        return DropdownMenuItem(
                          value: role.id,
                          child: Row(
                            children: [
                              Icon(roleIcon, color: roleColor, size: 20),
                              const SizedBox(width: AppTheme.spaceSmall),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(role.name, style: const TextStyle(fontWeight: AppTheme.fontSemiBold)),
                                    if (role.description.isNotEmpty)
                                      Text(
                                        role.description,
                                        style: Theme.of(context).textTheme.bodySmall,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedRoleId = value;
                        });
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading || _selectedRoleId == null ? null : _assignRole,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Assigner'),
        ),
      ],
    );
  }

  Future<void> _assignRole() async {
    if (_selectedRoleId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Créer l'assignation dans Firestore
      await FirebaseFirestore.instance.collection('user_roles').add({
        'userId': widget.userId,
        'roleId': _selectedRoleId!,
        'assignedAt': FieldValue.serverTimestamp(),
        'assignedBy': 'current_user_id', // TODO: Récupérer l'ID de l'utilisateur connecté
        'isActive': true,
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rôle assigné avec succès'),
            backgroundColor: AppTheme.greenStandard,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'assignation: $e'),
            backgroundColor: AppTheme.redStandard,
          ),
        );
      }
    }
  }
}
