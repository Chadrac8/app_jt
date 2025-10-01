import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/permission_model.dart';
import '../dialogs/assign_role_to_persons_dialog.dart';
import '../dialogs/assign_roles_to_person_dialog.dart';
import '../../../../theme.dart';
import '../../../theme.dart';

/// Widget pour l'assignation en masse de rôles
class BulkRoleAssignmentWidget extends StatefulWidget {
  const BulkRoleAssignmentWidget({super.key});

  @override
  State<BulkRoleAssignmentWidget> createState() => _BulkRoleAssignmentWidgetState();
}

class _BulkRoleAssignmentWidgetState extends State<BulkRoleAssignmentWidget> 
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _showInactivePersons = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(
                icon: Icon(Icons.group_add),
                text: 'Assigner un rôle à plusieurs personnes',
              ),
              Tab(
                icon: Icon(Icons.person_add),
                text: 'Assigner plusieurs rôles à une personne',
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAssignRoleToPersonsTab(),
              _buildAssignRolesToPersonTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAssignRoleToPersonsTab() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sélectionnez un rôle à assigner à plusieurs personnes',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: AppTheme.fontSemiBold,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Text(
            'Choisissez un rôle dans la liste ci-dessous, puis sélectionnez les personnes qui doivent recevoir ce rôle.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.grey600,
            ),
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          Expanded(
            child: _buildRolesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignRolesToPersonTab() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sélectionnez une personne pour lui assigner plusieurs rôles',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: AppTheme.fontSemiBold,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Text(
            'Choisissez une personne dans la liste ci-dessous, puis sélectionnez les rôles à lui assigner.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.grey600,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Inclure les personnes inactives',
              style: TextStyle(fontSize: AppTheme.fontSize14),
            ),
            value: _showInactivePersons,
            onChanged: (value) {
              setState(() {
                _showInactivePersons = value;
              });
            },
            dense: true,
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Expanded(
            child: _buildPersonsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRolesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('roles')
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState('Erreur lors du chargement des rôles: ${snapshot.error}');
        }

        final roles = snapshot.data?.docs ?? [];

        if (roles.isEmpty) {
          return _buildEmptyState(
            Icons.admin_panel_settings_outlined,
            'Aucun rôle disponible',
            'Créez des rôles dans la gestion des rôles pour pouvoir les assigner.',
          );
        }

        return ListView.builder(
          itemCount: roles.length,
          itemBuilder: (context, index) {
            final roleDoc = roles[index];
            final data = roleDoc.data() as Map<String, dynamic>;
            
            final role = Role(
              id: roleDoc.id,
              name: data['name'] ?? '',
              description: data['description'] ?? '',
              color: data['color'] ?? '#4CAF50',
              icon: data['icon'] ?? 'person',
              modulePermissions: Map<String, List<String>>.from(
                (data['modulePermissions'] as Map<String, dynamic>? ?? {}).map(
                  (key, value) => MapEntry(key, List<String>.from(value ?? [])),
                ),
              ),
              isSystemRole: data['isSystemRole'] ?? false,
              isActive: data['isActive'] ?? true,
              createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              createdBy: data['createdBy'],
              lastModifiedBy: data['lastModifiedBy'],
            );

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(AppTheme.spaceSmall),
                  decoration: BoxDecoration(
                    color: _parseColor(role.color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Icon(
                    _parseIcon(role.icon),
                    color: _parseColor(role.color),
                    size: 24,
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(child: Text(role.name)),
                    if (role.isSystemRole)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.orangeStandard.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Système',
                          style: TextStyle(
                            color: AppTheme.grey700,
                            fontSize: AppTheme.fontSize10,
                            fontWeight: AppTheme.fontMedium,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: role.description.isNotEmpty 
                    ? Text(role.description)
                    : null,
                trailing: Icon(
                  Icons.group_add,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onTap: () => _showAssignRoleToPersonsDialog(role),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPersonsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _showInactivePersons 
          ? FirebaseFirestore.instance
              .collection('persons')
              .orderBy('lastName')
              .orderBy('firstName')
              .snapshots()
          : FirebaseFirestore.instance
              .collection('persons')
              .where('isActive', isEqualTo: true)
              .orderBy('lastName')
              .orderBy('firstName')
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState('Erreur lors du chargement des personnes: ${snapshot.error}');
        }

        final persons = snapshot.data?.docs ?? [];

        if (persons.isEmpty) {
          return _buildEmptyState(
            Icons.people_outline,
            'Aucune personne trouvée',
            'Ajoutez des personnes dans le module Personnes pour pouvoir leur assigner des rôles.',
          );
        }

        return ListView.builder(
          itemCount: persons.length,
          itemBuilder: (context, index) {
            final person = persons[index];
            final data = person.data() as Map<String, dynamic>;
            final personId = person.id;
            final firstName = data['firstName'] ?? '';
            final lastName = data['lastName'] ?? '';
            final email = data['email'] ?? '';
            final isActive = data['isActive'] ?? true;
            final roles = List<String>.from(data['roles'] ?? []);
            
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: isActive ? null : AppTheme.grey100,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isActive 
                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                      : AppTheme.grey500.withValues(alpha: 0.3),
                  child: Text(
                    '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}',
                    style: TextStyle(
                      color: isActive 
                          ? Theme.of(context).colorScheme.primary
                          : AppTheme.grey500,
                      fontWeight: AppTheme.fontBold,
                    ),
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(child: Text('$firstName $lastName')),
                    if (!isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.grey300,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        child: const Text(
                          'Inactif',
                          style: TextStyle(fontSize: AppTheme.fontSize10, color: AppTheme.grey500),
                        ),
                      ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(email),
                    if (roles.isNotEmpty) ...[
                      const SizedBox(height: AppTheme.spaceXSmall),
                      Text(
                        '${roles.length} rôle(s) assigné(s)',
                        style: TextStyle(
                          color: AppTheme.grey600,
                          fontSize: AppTheme.fontSize12,
                          fontWeight: AppTheme.fontMedium,
                        ),
                      ),
                    ],
                  ],
                ),
                trailing: Icon(
                  Icons.person_add,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onTap: () => _showAssignRolesToPersonDialog(personId, '$firstName $lastName'),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppTheme.grey300),
          const SizedBox(height: AppTheme.spaceMedium),
          Text(
            'Erreur',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.grey700,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.grey600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: AppTheme.grey400),
          const SizedBox(height: AppTheme.spaceMedium),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.grey600,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.grey500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAssignRoleToPersonsDialog(Role role) {
    showDialog(
      context: context,
      builder: (context) => AssignRoleToPersonsDialog(role: role),
    );
  }

  void _showAssignRolesToPersonDialog(String personId, String personName) {
    showDialog(
      context: context,
      builder: (context) => AssignRolesToPersonDialog(
        personId: personId,
        personName: personName,
      ),
    );
  }

  // Utilitaires pour parser couleurs et icônes
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
}
