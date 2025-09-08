import 'package:flutter/material.dart';
import '../views/role_assignment_screen.dart';

/// Widget de navigation pour le module des rôles et permissions
class RoleModuleMenuWidget extends StatelessWidget {
  const RoleModuleMenuWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rôles et Permissions'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildMenuCard(
              context,
              title: 'Gestion des Rôles',
              subtitle: 'Créer, modifier et supprimer des rôles',
              icon: Icons.admin_panel_settings,
              color: Colors.blue,
              onTap: () => _showComingSoon(context),
            ),
            _buildMenuCard(
              context,
              title: 'Assignation des Rôles',
              subtitle: 'Assigner des rôles aux utilisateurs',
              icon: Icons.people,
              color: Colors.green,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const RoleAssignmentScreen(),
                ),
              ),
            ),
            _buildMenuCard(
              context,
              title: 'Aperçu des Permissions',
              subtitle: 'Visualiser la matrice des permissions',
              icon: Icons.security,
              color: Colors.orange,
              onTap: () => _showComingSoon(context),
            ),
            _buildMenuCard(
              context,
              title: 'Audit des Accès',
              subtitle: 'Historique des assignations',
              icon: Icons.history,
              color: Colors.purple,
              onTap: () => _showComingSoon(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bientôt disponible'),
        content: const Text('Cette fonctionnalité sera disponible dans une prochaine version.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
