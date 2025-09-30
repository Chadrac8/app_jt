import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/current_user_service.dart';
import '../../../../theme.dart';

/// Dialogue pour assigner plusieurs rôles à une personne existante
class AssignRolesToPersonDialog extends StatefulWidget {
  final String personId;
  final String personName;

  const AssignRolesToPersonDialog({
    super.key,
    required this.personId,
    required this.personName,
  });

  @override
  State<AssignRolesToPersonDialog> createState() => _AssignRolesToPersonDialogState();
}

class _AssignRolesToPersonDialogState extends State<AssignRolesToPersonDialog> {
  List<String> _selectedRoleIds = [];
  List<String> _currentRoleIds = [];
  bool _isLoading = true;
  bool _isAssigning = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentRoles();
  }

  Future<void> _loadCurrentRoles() async {
    try {
      final personDoc = await FirebaseFirestore.instance
          .collection('persons')
          .doc(widget.personId)
          .get();
      
      if (personDoc.exists) {
        final data = personDoc.data() as Map<String, dynamic>;
        _currentRoleIds = List<String>.from(data['roles'] ?? []);
      }
    } catch (e) {
      print('Erreur lors du chargement des rôles: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
            _buildHeader(),
            const SizedBox(height: 16),
            if (_isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              Expanded(child: _buildRolesList()),
              const SizedBox(height: 16),
              _buildActions(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          child: Icon(
            Icons.person,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assigner des rôles à',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: AppTheme.fontBold,
                ),
              ),
              Text(
                widget.personName,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: AppTheme.fontSemiBold,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ],
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppTheme.grey300),
                const SizedBox(height: 16),
                Text('Erreur: ${snapshot.error}'),
              ],
            ),
          );
        }

        final roles = snapshot.data?.docs ?? [];

        if (roles.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.admin_panel_settings_outlined, size: 48, color: AppTheme.grey400),
                const SizedBox(height: 16),
                Text(
                  'Aucun rôle disponible',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.grey600,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: roles.length,
          itemBuilder: (context, index) {
            final roleDoc = roles[index];
            final data = roleDoc.data() as Map<String, dynamic>;
            final roleId = roleDoc.id;
            final roleName = data['name'] ?? '';
            final roleDescription = data['description'] ?? '';
            final roleColor = data['color'] ?? '#4CAF50';
            final roleIcon = data['icon'] ?? 'person';
            final isSystemRole = data['isSystemRole'] ?? false;
            
            final hasRole = _currentRoleIds.contains(roleId);
            final isSelected = _selectedRoleIds.contains(roleId);

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: CheckboxListTile(
                value: hasRole ? true : isSelected,
                onChanged: hasRole ? null : (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedRoleIds.add(roleId);
                    } else {
                      _selectedRoleIds.remove(roleId);
                    }
                  });
                },
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _parseColor(roleColor).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        _parseIcon(roleIcon),
                        color: _parseColor(roleColor),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(roleName)),
                    if (isSystemRole)
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
                            fontSize: 10,
                            fontWeight: AppTheme.fontMedium,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (roleDescription.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        roleDescription,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.grey600,
                        ),
                      ),
                    ],
                    if (hasRole) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.greenStandard.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                        child: Text(
                          'Déjà assigné',
                          style: TextStyle(
                            color: AppTheme.grey700,
                            fontSize: 12,
                            fontWeight: AppTheme.fontMedium,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Text(
          '${_selectedRoleIds.length} nouveau(x) rôle(s) sélectionné(s)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.grey600,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _selectedRoleIds.isEmpty || _isAssigning 
              ? null 
              : _assignSelectedRoles,
          child: _isAssigning
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Assigner'),
        ),
      ],
    );
  }

  Future<void> _assignSelectedRoles() async {
    setState(() {
      _isAssigning = true;
    });

    try {
      final batch = FirebaseFirestore.instance.batch();
      final currentUser = await CurrentUserService().getCurrentUserString();

      // Mettre à jour la personne avec les nouveaux rôles
      final personRef = FirebaseFirestore.instance.collection('persons').doc(widget.personId);
      batch.update(personRef, {
        'roles': FieldValue.arrayUnion(_selectedRoleIds),
        'lastModifiedBy': currentUser,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Créer des entrées dans user_roles pour chaque nouveau rôle
      for (final roleId in _selectedRoleIds) {
        final userRoleRef = FirebaseFirestore.instance.collection('user_roles').doc();
        batch.set(userRoleRef, {
          'userId': widget.personId,
          'roleId': roleId,
          'assignedAt': FieldValue.serverTimestamp(),
          'assignedBy': currentUser,
          'isActive': true,
        });
      }

      await batch.commit();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_selectedRoleIds.length} rôle(s) assigné(s) à ${widget.personName}',
            ),
            backgroundColor: AppTheme.greenStandard,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'assignation: $e'),
            backgroundColor: AppTheme.redStandard,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAssigning = false;
        });
      }
    }
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
        case 'purple': return Colors.purple;
        case 'teal': return Colors.teal;
        case 'indigo': return Colors.indigo;
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
