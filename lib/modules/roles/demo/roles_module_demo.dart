import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/permission_model.dart';
import '../services/enhanced_permission_provider.dart';
import '../../../theme.dart';

/// Widget de démonstration pour tester le module Rôles
class RolesModuleDemo extends StatelessWidget {
  const RolesModuleDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Module Rôles - Démonstration'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Consumer<PermissionProvider>(
        builder: (context, provider, child) {
          if (!provider.isInitialized) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: AppTheme.spaceMedium),
                  const Text('Initialisation du module...'),
                  const SizedBox(height: AppTheme.spaceLarge),
                  FilledButton(
                    onPressed: () => provider.initialize('demo_user'),
                    child: const Text('Initialiser'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeCard(context),
                const SizedBox(height: AppTheme.spaceLarge),
                _buildStatsCards(context, provider),
                const SizedBox(height: AppTheme.spaceLarge),
                _buildQuickActions(context),
                const SizedBox(height: AppTheme.spaceLarge),
                _buildModulesList(context),
                const SizedBox(height: AppTheme.spaceLarge),
                _buildSystemInfo(context, provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primaryContainer,
              theme.colorScheme.primaryContainer.withOpacity(0.7),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    size: 32,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: Text(
                      'Module Rôles et Permissions',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: AppTheme.fontBold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              Text(
                'Système complet de gestion des rôles, permissions et restrictions développé selon Material Design 3.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer.withOpacity(0.9),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppTheme.space20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFeatureChip(context, 'RBAC Complet'),
                  _buildFeatureChip(context, 'Material Design 3'),
                  _buildFeatureChip(context, 'Permissions granulaires'),
                  _buildFeatureChip(context, 'Audit intégré'),
                  _buildFeatureChip(context, 'Cache optimisé'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureChip(BuildContext context, String label) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(fontSize: AppTheme.fontSize12),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.8),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildStatsCards(BuildContext context, PermissionProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            'Rôles',
            provider.roles.length.toString(),
            Icons.admin_panel_settings,
            AppTheme.infoColor,
          ),
        ),
        const SizedBox(width: AppTheme.space12),
        Expanded(
          child: _buildStatCard(
            context,
            'Modules',
            AppModule.allModules.length.toString(),
            Icons.apps,
            AppTheme.successColor,
          ),
        ),
        const SizedBox(width: AppTheme.space12),
        Expanded(
          child: _buildStatCard(
            context,
            'Système',
            provider.systemRoles.length.toString(),
            Icons.verified_user,
            AppTheme.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: AppTheme.spaceSmall),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: AppTheme.fontBold,
                color: color,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions rapides',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: AppTheme.fontSemiBold,
              ),
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildActionButton(
                  context,
                  'Gestion des rôles',
                  Icons.admin_panel_settings,
                  () => _navigateToRolesManagement(context),
                ),
                _buildActionButton(
                  context,
                  'Assignation',
                  Icons.person_add,
                  () => _navigateToRoleAssignment(context),
                ),
                _buildActionButton(
                  context,
                  'Configuration',
                  Icons.settings,
                  () => _navigateToSettings(context),
                ),
                _buildActionButton(
                  context,
                  'Statistiques',
                  Icons.analytics,
                  () => _showStats(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        alignment: Alignment.centerLeft,
      ),
    );
  }

  Widget _buildModulesList(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Modules de l\'application',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: AppTheme.fontSemiBold,
              ),
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            ...AppModule.allModules.take(8).map((module) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      _getModuleIcon(module.icon),
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: AppTheme.space12),
                    Expanded(
                      child: Text(module.name),
                    ),
                    Text(
                      '5 permissions',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            if (AppModule.allModules.length > 8) ...[
              const SizedBox(height: AppTheme.spaceSmall),
              Text(
                'Et ${AppModule.allModules.length - 8} autres modules...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSystemInfo(BuildContext context, PermissionProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations système',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: AppTheme.fontSemiBold,
              ),
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            _buildInfoRow('Statut', provider.isInitialized ? 'Initialisé' : 'Non initialisé'),
            _buildInfoRow('Version du module', '1.0.0'),
            _buildInfoRow('Cache actif', provider.isCacheEnabled ? 'Oui' : 'Non'),
            _buildInfoRow('Dernière mise à jour', _formatLastUpdate(provider.lastUpdate)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: AppTheme.fontMedium),
          ),
        ],
      ),
    );
  }

  void _navigateToRolesManagement(BuildContext context) {
    // Dans une implémentation réelle, naviguer vers RolesManagementScreen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navigation vers la gestion des rôles'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateToRoleAssignment(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navigation vers l\'assignation des rôles'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateToSettings(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navigation vers la configuration'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showStats(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Consumer<PermissionProvider>(
        builder: (context, provider, child) {
          final stats = provider.getRolesStats();
          
          return AlertDialog(
            title: const Text('Statistiques du module'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...stats.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key.replaceAll('_', ' ').toUpperCase()),
                        Text(
                          entry.value.toString(),
                          style: const TextStyle(fontWeight: AppTheme.fontBold),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fermer'),
              ),
            ],
          );
        },
      ),
    );
  }

  IconData _getModuleIcon(String iconName) {
    switch (iconName) {
      case 'dashboard': return Icons.dashboard;
      case 'people': return Icons.people;
      case 'group': return Icons.group;
      case 'event': return Icons.event;
      case 'church': return Icons.church;
      case 'task': return Icons.task;
      case 'article': return Icons.article;
      case 'monetization_on': return Icons.monetization_on;
      case 'music_note': return Icons.music_note;
      case 'menu_book': return Icons.menu_book;
      case 'description': return Icons.description;
      case 'web': return Icons.web;
      case 'favorite': return Icons.favorite;
      case 'settings': return Icons.settings;
      case 'admin_panel_settings': return Icons.admin_panel_settings;
      default: return Icons.extension;
    }
  }

  String _formatLastUpdate(DateTime? lastUpdate) {
    if (lastUpdate == null) return 'Jamais';
    
    final now = DateTime.now();
    final difference = now.difference(lastUpdate);
    
    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return 'Il y a ${difference.inHours} h';
    } else {
      return 'Il y a ${difference.inDays} j';
    }
  }
}