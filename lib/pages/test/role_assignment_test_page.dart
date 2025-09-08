import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../modules/roles/providers/role_provider.dart';

class RoleAssignmentTestPage extends StatefulWidget {
  const RoleAssignmentTestPage({super.key});

  @override
  State<RoleAssignmentTestPage> createState() => _RoleAssignmentTestPageState();
}

class _RoleAssignmentTestPageState extends State<RoleAssignmentTestPage> {
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pré-remplir avec des données de test
    _userIdController.text = 'test_user_${DateTime.now().millisecondsSinceEpoch}';
    _emailController.text = 'test@example.com';
    _nameController.text = 'Utilisateur Test';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Assignation Rôles'),
      ),
      body: Consumer<RoleProvider>(
        builder: (context, provider, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Statut du Provider',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              provider.isLoading ? Icons.hourglass_empty : Icons.check_circle,
                              color: provider.isLoading ? Colors.orange : Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Text(provider.isLoading ? 'Chargement...' : 'Prêt'),
                          ],
                        ),
                        if (provider.error != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.error, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(child: Text('Erreur: ${provider.error}')),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text('Rôles disponibles: ${provider.roles.length}'),
                        Text('Utilisateurs avec rôles: ${provider.userRoles.length}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Test d\'Assignation',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _userIdController,
                          decoration: const InputDecoration(
                            labelText: 'ID Utilisateur',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nom',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('Rôles disponibles:'),
                        const SizedBox(height: 8),
                        ...provider.roles.map((role) => ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getRoleColor(role.id),
                            child: Icon(
                              _getRoleIcon(role.id),
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          title: Text(role.name),
                          subtitle: Text(role.description),
                          trailing: ElevatedButton(
                            onPressed: provider.isLoading 
                                ? null 
                                : () => _assignRole(provider, role.id),
                            child: const Text('Assigner'),
                          ),
                        )),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: provider.isLoading 
                                    ? null 
                                    : () => provider.initialize(),
                                icon: const Icon(Icons.refresh),
                                label: const Text('Actualiser'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: provider.isLoading 
                                    ? null 
                                    : () => _testConnection(provider),
                                icon: const Icon(Icons.wifi),
                                label: const Text('Tester Firebase'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                if (provider.userRoles.isNotEmpty) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Utilisateurs avec Rôles',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          ...provider.userRoles.take(5).map((userRole) => ListTile(
                            leading: CircleAvatar(
                              child: Text(userRole.userName.substring(0, 1).toUpperCase()),
                            ),
                            title: Text(userRole.userName),
                            subtitle: Text(userRole.userEmail),
                            trailing: Wrap(
                              spacing: 4,
                              children: userRole.roleIds.map((roleId) {
                                final role = provider.getRoleById(roleId);
                                return Chip(
                                  label: Text(
                                    role?.name ?? roleId,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                  backgroundColor: _getRoleColor(roleId).withOpacity(0.2),
                                );
                              }).toList(),
                            ),
                          )),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _assignRole(RoleProvider provider, String roleId) async {
    if (_userIdController.text.isEmpty || 
        _emailController.text.isEmpty || 
        _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    final success = await provider.assignRolesToUser(
      userId: _userIdController.text,
      userEmail: _emailController.text,
      userName: _nameController.text,
      roleIds: [roleId],
      assignedBy: 'test_admin',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success 
                ? '✅ Rôle assigné avec succès!' 
                : '❌ Erreur: ${provider.error}',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _testConnection(RoleProvider provider) async {
    try {
      await provider.loadAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Connexion Firebase OK'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur Firebase: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  @override
  void dispose() {
    _userIdController.dispose();
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}
