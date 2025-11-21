import 'package:flutter/material.dart';
import '../models/person_model.dart';
import '../models/role_model.dart';
import '../services/roles_firebase_service.dart';
import '../services/firebase_service.dart';
import '../../theme.dart';

class RoleAssignmentsPage extends StatefulWidget {
  const RoleAssignmentsPage({super.key});

  @override
  State<RoleAssignmentsPage> createState() => _RoleAssignmentsPageState();
}

class _RoleAssignmentsPageState extends State<RoleAssignmentsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  RoleModel? _selectedRole;
  List<PersonModel> _selectedPersons = [];
  bool _isAssignMode = false;
  bool _hasManageRolesPermission = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkPermissions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _tabController = TabController(length: 2, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  Future<void> _checkPermissions() async {
    final hasPermission = await RolesFirebaseService.currentUserHasPermission('manage_roles');
    if (mounted) {
      setState(() {
        _hasManageRolesPermission = hasPermission;
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _toggleAssignMode() {
    setState(() {
      _isAssignMode = !_isAssignMode;
      if (!_isAssignMode) {
        _selectedPersons.clear();
        _selectedRole = null;
      }
    });
  }

  void _onPersonSelected(PersonModel person, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedPersons.add(person);
      } else {
        _selectedPersons.removeWhere((p) => p.id == person.id);
      }
    });
  }

  Future<void> _assignRole() async {
    if (_selectedRole == null || _selectedPersons.isEmpty) return;

    try {
      final personIds = _selectedPersons.map((p) => p.id).toList();
      await RolesFirebaseService.assignRoleToPersons(personIds, _selectedRole!.id);

      if (mounted) {
        setState(() {
          _selectedPersons.clear();
          _selectedRole = null;
          _isAssignMode = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rôle "${_selectedRole!.name}" assigné à ${personIds.length} personne(s)'),
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
    }
  }

  Future<void> _removeRole(PersonModel person, RoleModel role) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer le rôle'),
        content: Text(
          'Êtes-vous sûr de vouloir retirer le rôle "${role.name}" de ${person.fullName} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.redStandard,
              foregroundColor: AppTheme.white100,
            ),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await RolesFirebaseService.removeRoleFromPersons([person.id], role.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Rôle "${role.name}" retiré de ${person.fullName}'),
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isAssignMode
            ? Text('${_selectedPersons.length} personne(s) sélectionnée(s)')
            : const Text('Assignations de rôles'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.white100,
        elevation: 0,
        leading: _isAssignMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleAssignMode,
              )
            : null,
        actions: [
          if (_isAssignMode) ...[
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _selectedPersons.isNotEmpty && _selectedRole != null 
                  ? _assignRole 
                  : null,
              tooltip: 'Assigner le rôle',
            ),
          ] else if (_hasManageRolesPermission) ...[
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: _toggleAssignMode,
              tooltip: 'Assigner des rôles',
            ),
          ],
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.white100,
          unselectedLabelColor: AppTheme.white100.withOpacity(0.70),
          indicatorColor: AppTheme.white100,
          tabs: const [
            Tab(text: 'Par personne', icon: Icon(Icons.people)),
            Tab(text: 'Par rôle', icon: Icon(Icons.security)),
          ],
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildSearchBar(),
            if (_isAssignMode) _buildRoleSelector(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildByPersonTab(),
                  _buildByRoleTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: AppTheme.white100,
        boxShadow: [
          BoxShadow(
            color: AppTheme.grey500.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Rechercher...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: AppTheme.backgroundColor,
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: AppTheme.grey500.withOpacity(0.2)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sélectionner un rôle à assigner:',
            style: TextStyle(
              fontWeight: AppTheme.fontMedium,
            ),
          ),
          const SizedBox(height: AppTheme.space12),
          StreamBuilder<List<RoleModel>>(
            stream: RolesFirebaseService.getRolesStream(activeOnly: true),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final roles = snapshot.data!;
              
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: roles.map((role) {
                  final isSelected = _selectedRole?.id == role.id;
                  final roleColor = Color(int.parse(role.color.replaceFirst('#', '0xFF')));
                  
                  return FilterChip(
                    selected: isSelected,
                    label: Text(role.name),
                    avatar: Icon(
                      _getIconFromString(role.icon),
                      size: 16,
                      color: isSelected ? AppTheme.white100 : roleColor,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _selectedRole = selected ? role : null;
                      });
                    },
                    selectedColor: roleColor,
                    checkmarkColor: AppTheme.white100,
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.white100 : roleColor,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildByPersonTab() {
    return StreamBuilder<List<PersonModel>>(
      stream: FirebaseService.getPersonsStream(
        searchQuery: _searchQuery,
        activeOnly: true,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Erreur: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final persons = snapshot.data!;

        if (persons.isEmpty) {
          return const Center(
            child: Text('Aucune personne trouvée'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
          itemCount: persons.length,
          itemBuilder: (context, index) {
            final person = persons[index];
            return _buildPersonCard(person);
          },
        );
      },
    );
  }

  Widget _buildPersonCard(PersonModel person) {
    final isSelected = _selectedPersons.any((p) => p.id == person.id);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: _isAssignMode
            ? Checkbox(
                value: isSelected,
                onChanged: (value) => _onPersonSelected(person, value ?? false),
                activeColor: AppTheme.primaryColor,
              )
            : CircleAvatar(
                backgroundColor: AppTheme.primaryColor,
                child: Text(
                  person.displayInitials,
                  style: const TextStyle(color: AppTheme.white100),
                ),
              ),
        title: Text(person.fullName),
        subtitle: person.roles.isNotEmpty
            ? StreamBuilder<List<RoleModel>>(
                stream: RolesFirebaseService.getRolesStream(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  
                  final allRoles = snapshot.data!;
                  final personRoles = allRoles.where((role) => person.roles.contains(role.id)).toList();
                  
                  return Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: personRoles.map((role) {
                      final roleColor = Color(int.parse(role.color.replaceFirst('#', '0xFF')));
                      
                      return Chip(
                        label: Text(
                          role.name,
                          style: const TextStyle(fontSize: AppTheme.fontSize12),
                        ),
                        backgroundColor: roleColor.withOpacity(0.1),
                        side: BorderSide(color: roleColor.withOpacity(0.3)),
                        labelStyle: TextStyle(color: roleColor),
                        deleteIcon: _hasManageRolesPermission && !_isAssignMode
                            ? const Icon(Icons.close, size: 16)
                            : null,
                        onDeleted: _hasManageRolesPermission && !_isAssignMode
                            ? () => _removeRole(person, role)
                            : null,
                      );
                    }).toList(),
                  );
                },
              )
            : const Text('Aucun rôle assigné'),
      ),
    );
  }

  Widget _buildByRoleTab() {
    return StreamBuilder<List<RoleModel>>(
      stream: RolesFirebaseService.getRolesStream(
        searchQuery: _searchQuery,
        activeOnly: true,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Erreur: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final roles = snapshot.data!;

        if (roles.isEmpty) {
          return const Center(
            child: Text('Aucun rôle trouvé'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
          itemCount: roles.length,
          itemBuilder: (context, index) {
            final role = roles[index];
            return _buildRoleCard(role);
          },
        );
      },
    );
  }

  Widget _buildRoleCard(RoleModel role) {
    final roleColor = Color(int.parse(role.color.replaceFirst('#', '0xFF')));
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: roleColor,
          child: Icon(
            _getIconFromString(role.icon),
            color: AppTheme.white100,
          ),
        ),
        title: Text(
          role.name,
          style: TextStyle(
            fontWeight: AppTheme.fontBold,
            color: roleColor,
          ),
        ),
        subtitle: StreamBuilder<List<PersonModel>>(
          stream: RolesFirebaseService.getPersonsWithRole(role.id),
          builder: (context, snapshot) {
            final count = snapshot.data?.length ?? 0;
            return Text('$count personne${count > 1 ? 's' : ''}');
          },
        ),
        children: [
          StreamBuilder<List<PersonModel>>(
            stream: RolesFirebaseService.getPersonsWithRole(role.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(AppTheme.spaceMedium),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final persons = snapshot.data!;

              if (persons.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(AppTheme.spaceMedium),
                  child: Text('Aucune personne avec ce rôle'),
                );
              }

              return Column(
                children: persons.map((person) {
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.grey300,
                      radius: 16,
                      child: Text(
                        person.displayInitials,
                        style: const TextStyle(fontSize: AppTheme.fontSize12),
                      ),
                    ),
                    title: Text(person.fullName),
                    subtitle: Text(person.email ?? ''),
                    trailing: _hasManageRolesPermission
                        ? IconButton(
                            icon: const Icon(Icons.remove_circle, color: AppTheme.redStandard),
                            onPressed: () => _removeRole(person, role),
                            tooltip: 'Retirer ce rôle',
                          )
                        : null,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  IconData _getIconFromString(String iconName) {
    const iconMap = {
      'security': Icons.security,
      'admin_panel_settings': Icons.admin_panel_settings,
      'church': Icons.church,
      'supervisor_account': Icons.supervisor_account,
      'person': Icons.person,
      'people': Icons.people,
      'group': Icons.group,
      'groups': Icons.groups,
      'event': Icons.event,
      'assignment': Icons.assignment,
      'description': Icons.description,
      'work': Icons.work,
      'school': Icons.school,
      'volunteer_activism': Icons.volunteer_activism,
      'manage_accounts': Icons.manage_accounts,
      'psychology': Icons.psychology,
      'music_note': Icons.music_note,
      'mic': Icons.mic,
      'campaign': Icons.campaign,
      'handshake': Icons.handshake,
    };
    
    return iconMap[iconName] ?? Icons.security;
  }
}