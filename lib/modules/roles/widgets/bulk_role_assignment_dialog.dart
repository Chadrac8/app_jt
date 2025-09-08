import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/role.dart';
import '../providers/role_provider.dart';
import '../services/current_user_service.dart';

class BulkRoleAssignmentDialog extends StatefulWidget {
  const BulkRoleAssignmentDialog({super.key});

  @override
  State<BulkRoleAssignmentDialog> createState() => _BulkRoleAssignmentDialogState();
}

class _BulkRoleAssignmentDialogState extends State<BulkRoleAssignmentDialog>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usersController = TextEditingController();
  
  List<String> _selectedRoleIds = [];
  List<UserData> _users = [];
  DateTime? _expirationDate;
  bool _isLoading = false;
  int _currentStep = 0;
  
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _usersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(_slideAnimation),
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.95,
          constraints: const BoxConstraints(
            maxHeight: 700,
            maxWidth: 800,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildStepIndicator(),
              const SizedBox(height: 24),
              Expanded(
                child: _buildStepContent(),
              ),
              const SizedBox(height: 24),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.group_add,
            color: Theme.of(context).primaryColor,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assignation en masse',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Assigner des rôles à plusieurs utilisateurs simultanément',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
          tooltip: 'Fermer',
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _buildStepIcon(0, 'Utilisateurs', Icons.people),
        _buildStepConnector(0),
        _buildStepIcon(1, 'Rôles', Icons.admin_panel_settings),
        _buildStepConnector(1),
        _buildStepIcon(2, 'Confirmation', Icons.check_circle),
      ],
    );
  }

  Widget _buildStepIcon(int step, String label, IconData icon) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;
    
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted 
                  ? Colors.green
                  : isActive 
                      ? Theme.of(context).primaryColor
                      : Colors.grey[300],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isCompleted ? Icons.check : icon,
              color: isActive || isCompleted ? Colors.white : Colors.grey[600],
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive 
                  ? Theme.of(context).primaryColor
                  : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector(int step) {
    return Expanded(
      child: Container(
        height: 2,
        color: _currentStep > step ? Colors.green : Colors.grey[300],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildUsersStep();
      case 1:
        return _buildRolesStep();
      case 2:
        return _buildConfirmationStep();
      default:
        return Container();
    }
  }

  Widget _buildUsersStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Étape 1: Sélectionner les utilisateurs',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _usersController,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Emails des utilisateurs',
              hintText: 'user1@example.com\nuser2@example.com\nuser3@example.com\n\nUn email par ligne',
              border: OutlineInputBorder(),
              helperText: 'Entrez un email par ligne',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Veuillez entrer au moins un email';
              }
              
              final emails = value.trim().split('\n')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty);
                  
              for (final email in emails) {
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
                  return 'Email invalide: $email';
                }
              }
              
              return null;
            },
            onChanged: _parseUsers,
          ),
          const SizedBox(height: 16),
          if (_users.isNotEmpty) ...[
            Text(
              'Utilisateurs détectés (${_users.length}):',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                        child: Text(
                          user.email[0].toUpperCase(),
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(user.email),
                      subtitle: Text(user.name),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _users.removeAt(index);
                            _updateUsersController();
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRolesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Étape 2: Sélectionner les rôles',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                'Rôles à assigner:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedRoleIds.clear();
                });
              },
              child: const Text('Tout désélectionner'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Consumer<RoleProvider>(
            builder: (context, roleProvider, child) {
              final roles = roleProvider.activeRoles;
              
              if (roles.isEmpty) {
                return const Center(
                  child: Text('Aucun rôle disponible'),
                );
              }
              
              return ListView.builder(
                itemCount: roles.length,
                itemBuilder: (context, index) {
                  final role = roles[index];
                  final isSelected = _selectedRoleIds.contains(role.id);
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: CheckboxListTile(
                      title: Text(
                        role.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(role.description),
                          const SizedBox(height: 4),
                          Text(
                            '${role.permissions.length} permissions',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedRoleIds.add(role.id);
                          } else {
                            _selectedRoleIds.remove(role.id);
                          }
                        });
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                'Date d\'expiration (optionnel):',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (_expirationDate != null)
              TextButton(
                onPressed: () {
                  setState(() {
                    _expirationDate = null;
                  });
                },
                child: const Text('Supprimer'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now().add(const Duration(days: 30)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) {
              setState(() {
                _expirationDate = date;
              });
            }
          },
          icon: const Icon(Icons.calendar_today),
          label: Text(
            _expirationDate == null
                ? 'Sélectionner une date'
                : 'Expire le ${_expirationDate!.day}/${_expirationDate!.month}/${_expirationDate!.year}',
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Étape 3: Confirmation',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(
                  'Utilisateurs',
                  '${_users.length} utilisateur(s)',
                  Icons.people,
                  Colors.blue,
                  _users.map((u) => u.email).join(', '),
                ),
                const SizedBox(height: 16),
                Consumer<RoleProvider>(
                  builder: (context, roleProvider, child) {
                    final selectedRoles = _selectedRoleIds
                        .map((id) => roleProvider.getRoleById(id))
                        .where((role) => role != null)
                        .cast<Role>()
                        .toList();
                    
                    return _buildSummaryCard(
                      'Rôles',
                      '${selectedRoles.length} rôle(s)',
                      Icons.admin_panel_settings,
                      Colors.orange,
                      selectedRoles.map((r) => r.name).join(', '),
                    );
                  },
                ),
                const SizedBox(height: 16),
                if (_expirationDate != null)
                  _buildSummaryCard(
                    'Expiration',
                    '${_expirationDate!.day}/${_expirationDate!.month}/${_expirationDate!.year}',
                    Icons.schedule,
                    Colors.red,
                    'Les rôles expireront automatiquement',
                  ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    border: Border.all(color: Colors.amber[200]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning,
                        color: Colors.amber[700],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Cette action assignera les rôles sélectionnés à tous les utilisateurs listés. '
                          'Les rôles existants seront remplacés.',
                          style: TextStyle(
                            color: Colors.amber[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String subtitle, IconData icon, Color color, String details) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              details,
              style: const TextStyle(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: _isLoading ? null : () {
                setState(() {
                  _currentStep--;
                });
              },
              child: const Text('Précédent'),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 16),
        Expanded(
          child: _currentStep == 2
              ? ElevatedButton(
                  onPressed: _isLoading ? null : _performBulkAssignment,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Assigner'),
                )
              : ElevatedButton(
                  onPressed: _canProceedToNextStep() ? () {
                    setState(() {
                      _currentStep++;
                    });
                  } : null,
                  child: const Text('Suivant'),
                ),
        ),
      ],
    );
  }

  bool _canProceedToNextStep() {
    switch (_currentStep) {
      case 0:
        return _users.isNotEmpty && _formKey.currentState?.validate() == true;
      case 1:
        return _selectedRoleIds.isNotEmpty;
      default:
        return false;
    }
  }

  void _parseUsers(String value) {
    final emails = value.trim().split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet();

    setState(() {
      _users = emails.map((email) => UserData(
        email: email,
        name: _generateNameFromEmail(email),
      )).toList();
    });
  }

  String _generateNameFromEmail(String email) {
    final parts = email.split('@')[0].split('.');
    return parts.map((part) => part[0].toUpperCase() + part.substring(1)).join(' ');
  }

  void _updateUsersController() {
    _usersController.text = _users.map((u) => u.email).join('\n');
  }

  Future<void> _performBulkAssignment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final roleProvider = Provider.of<RoleProvider>(context, listen: false);
      
      int successCount = 0;
      int failureCount = 0;
      
      for (final user in _users) {
        try {
          final success = await roleProvider.assignRolesToUser(
            userId: user.email, // En l'absence d'ID, on utilise l'email
            userEmail: user.email,
            userName: user.name,
            roleIds: _selectedRoleIds,
            assignedBy: CurrentUserService().getCurrentUserIdOrDefault(),
            expiresAt: _expirationDate,
          );
          
          if (success) {
            successCount++;
          } else {
            failureCount++;
          }
        } catch (e) {
          failureCount++;
        }
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Assignation terminée: $successCount réussies, $failureCount échouées',
            ),
            backgroundColor: failureCount == 0 ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
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
}

class UserData {
  final String email;
  final String name;

  UserData({
    required this.email,
    required this.name,
  });
}
