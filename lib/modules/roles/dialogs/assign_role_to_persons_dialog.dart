import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/permission_model.dart';
import '../services/current_user_service.dart';
import '../../../../theme.dart';
import '../../../theme.dart';

/// Dialogue pour assigner un rôle à plusieurs personnes existantes
class AssignRoleToPersonsDialog extends StatefulWidget {
  final Role role;

  const AssignRoleToPersonsDialog({
    super.key,
    required this.role,
  });

  @override
  State<AssignRoleToPersonsDialog> createState() => _AssignRoleToPersonsDialogState();
}

class _AssignRoleToPersonsDialogState extends State<AssignRoleToPersonsDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<String> _selectedPersonIds = [];
  bool _isLoading = false;
  bool _showInactivePersons = false;

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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(AppTheme.spaceLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: AppTheme.spaceMedium),
            _buildSearchBar(),
            const SizedBox(height: AppTheme.spaceSmall),
            _buildOptions(),
            const SizedBox(height: AppTheme.spaceMedium),
            Expanded(child: _buildPersonsList()),
            const SizedBox(height: AppTheme.spaceMedium),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spaceSmall),
          decoration: BoxDecoration(
            color: _parseColor(widget.role.color).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Icon(
            _parseIcon(widget.role.icon),
            color: _parseColor(widget.role.color),
            size: 24,
          ),
        ),
        const SizedBox(width: AppTheme.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assigner le rôle : ${widget.role.name}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: AppTheme.fontBold,
                ),
              ),
              Text(
                'Sélectionnez les personnes à qui assigner ce rôle',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.grey600,
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

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        labelText: 'Rechercher une personne',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                },
                icon: const Icon(Icons.clear),
              )
            : null,
      ),
    );
  }

  Widget _buildOptions() {
    return Row(
      children: [
        Expanded(
          child: SwitchListTile(
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
        ),
      ],
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppTheme.grey300),
                const SizedBox(height: AppTheme.spaceMedium),
                Text('Erreur: ${snapshot.error}'),
              ],
            ),
          );
        }

        final persons = snapshot.data?.docs ?? [];
        final filteredPersons = persons.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final fullName = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.toLowerCase();
          final email = (data['email'] ?? '').toLowerCase();
          
          return fullName.contains(_searchQuery) || email.contains(_searchQuery);
        }).toList();

        if (filteredPersons.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 48, color: AppTheme.grey400),
                const SizedBox(height: AppTheme.spaceMedium),
                Text(
                  _searchQuery.isEmpty 
                      ? 'Aucune personne trouvée'
                      : 'Aucune personne correspondant à "$_searchQuery"',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.grey600,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredPersons.length,
          itemBuilder: (context, index) {
            final person = filteredPersons[index];
            final data = person.data() as Map<String, dynamic>;
            final personId = person.id;
            final firstName = data['firstName'] ?? '';
            final lastName = data['lastName'] ?? '';
            final email = data['email'] ?? '';
            final isActive = data['isActive'] ?? true;
            final roles = List<String>.from(data['roles'] ?? []);
            final hasRole = roles.contains(widget.role.id);
            final isSelected = _selectedPersonIds.contains(personId);

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: isActive ? null : AppTheme.grey100,
              child: CheckboxListTile(
                value: isSelected,
                onChanged: hasRole ? null : (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedPersonIds.add(personId);
                    } else {
                      _selectedPersonIds.remove(personId);
                    }
                  });
                },
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
                    if (hasRole) ...[
                      const SizedBox(height: AppTheme.spaceXSmall),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _parseColor(widget.role.color).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                        child: Text(
                          'Déjà assigné à ce rôle',
                          style: TextStyle(
                            color: _parseColor(widget.role.color),
                            fontSize: AppTheme.fontSize12,
                            fontWeight: AppTheme.fontMedium,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                secondary: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  child: Text(
                    '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: AppTheme.fontBold,
                    ),
                  ),
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
        Expanded(
          child: Text(
            '${_selectedPersonIds.length} personne(s) sélectionnée(s)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.grey600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppTheme.spaceSmall),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        const SizedBox(width: AppTheme.spaceSmall),
        ElevatedButton(
          onPressed: _selectedPersonIds.isEmpty || _isLoading 
              ? null 
              : _assignRoleToSelectedPersons,
          child: _isLoading
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

  Future<void> _assignRoleToSelectedPersons() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final batch = FirebaseFirestore.instance.batch();
      final currentUser = await CurrentUserService().getCurrentUserString();

      for (final personId in _selectedPersonIds) {
        final personRef = FirebaseFirestore.instance.collection('persons').doc(personId);
        
        // Ajouter le rôle à la liste des rôles de la personne
        batch.update(personRef, {
          'roles': FieldValue.arrayUnion([widget.role.id]),
          'lastModifiedBy': currentUser,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Créer une entrée dans la collection user_roles pour le suivi
        final userRoleRef = FirebaseFirestore.instance.collection('user_roles').doc();
        batch.set(userRoleRef, {
          'userId': personId,
          'roleId': widget.role.id,
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
              'Rôle "${widget.role.name}" assigné à ${_selectedPersonIds.length} personne(s)',
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
          _isLoading = false;
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
