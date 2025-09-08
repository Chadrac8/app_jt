import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/person_model.dart';
import '../../../services/firebase_service.dart';
import '../providers/role_provider.dart';
import '../models/role.dart';
import '../services/current_user_service.dart';

class AssignRoleToPersonDialog extends StatefulWidget {
  const AssignRoleToPersonDialog({super.key});

  @override
  State<AssignRoleToPersonDialog> createState() => _AssignRoleToPersonDialogState();
}

class _AssignRoleToPersonDialogState extends State<AssignRoleToPersonDialog> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  List<PersonModel> _searchResults = [];
  PersonModel? _selectedPerson;
  Role? _selectedRole;
  DateTime? _expiresAt;
  bool _isLoading = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadInitialPersons();
  }

  Future<void> _loadInitialPersons() async {
    setState(() => _isLoading = true);
    try {
      final persons = await FirebaseService.getActivePersons();
      setState(() {
        _searchResults = persons.take(20).toList(); // Limiter à 20 pour commencer
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement : $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchPersons(String query) async {
    if (query.trim().isEmpty) {
      await _loadInitialPersons();
      return;
    }

    setState(() => _isSearching = true);
    try {
      final persons = await FirebaseService.searchPersons(query);
      setState(() {
        _searchResults = persons;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de recherche : $e')),
        );
      }
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _assignRole() async {
    if (_selectedPerson == null || _selectedRole == null) return;

    setState(() => _isLoading = true);
    try {
      final provider = Provider.of<RoleProvider>(context, listen: false);
      
      final success = await provider.assignRolesToUser(
        userId: _selectedPerson!.id,
        userEmail: _selectedPerson!.email,
        userName: _selectedPerson!.fullName,
        roleIds: [_selectedRole!.id],
        assignedBy: CurrentUserService().getCurrentUserIdOrDefault(),
        expiresAt: _expiresAt,
      );

      if (mounted) {
        if (success) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Rôle "${_selectedRole!.name}" assigné à ${_selectedPerson!.fullName}',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de l\'assignation : ${provider.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'assignation : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<RoleProvider>(context);

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                Icon(Icons.person_add, color: theme.primaryColor, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Assigner un rôle à une personne',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recherche de personne
            Text(
              '1. Sélectionner une personne',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Rechercher une personne',
                hintText: 'Nom, prénom ou email...',
                prefixIcon: _isSearching 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _loadInitialPersons();
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
              ),
              onChanged: (value) {
                if (value.length >= 2) {
                  _searchPersons(value);
                } else if (value.isEmpty) {
                  _loadInitialPersons();
                }
              },
            ),
            const SizedBox(height: 16),

            // Liste des personnes
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final person = _searchResults[index];
                          final isSelected = _selectedPerson?.id == person.id;
                          
                          return ListTile(
                            selected: isSelected,
                            leading: CircleAvatar(
                              backgroundColor: isSelected
                                  ? theme.primaryColor
                                  : Colors.grey.shade300,
                              foregroundColor: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade700,
                              child: Text(person.displayInitials),
                            ),
                            title: Text(
                              person.fullName,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (person.email.isNotEmpty) Text(person.email),
                                if (person.roles.isNotEmpty)
                                  Text(
                                    'Rôles actuels: ${person.roles.join(', ')}',
                                    style: TextStyle(
                                      color: Colors.blue.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: isSelected
                                ? Icon(Icons.check_circle, color: theme.primaryColor)
                                : null,
                            onTap: () {
                              setState(() {
                                _selectedPerson = person;
                              });
                            },
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // Sélection du rôle
            Text(
              '2. Choisir un rôle',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Role>(
                  isExpanded: true,
                  hint: const Text('Sélectionner un rôle'),
                  value: _selectedRole,
                  items: provider.roles
                      .where((role) => role.isActive)
                      .map((role) => DropdownMenuItem<Role>(
                            value: role,
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade400,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        role.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (role.description.isNotEmpty)
                                        Text(
                                          role.description,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (role) {
                    setState(() {
                      _selectedRole = role;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Date d'expiration optionnelle
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Date d\'expiration (optionnelle)',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _expiresAt ?? DateTime.now().add(const Duration(days: 365)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                    );
                    if (date != null) {
                      setState(() {
                        _expiresAt = date;
                      });
                    }
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(_expiresAt?.toString().split(' ')[0] ?? 'Choisir'),
                ),
                if (_expiresAt != null)
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _expiresAt = null;
                      });
                    },
                    icon: const Icon(Icons.clear),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Notes
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optionnelles)',
                hintText: 'Commentaires sur cette assignation...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Boutons d'action
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: (_selectedPerson != null && _selectedRole != null && !_isLoading)
                      ? _assignRole
                      : null,
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Assigner le rôle'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
