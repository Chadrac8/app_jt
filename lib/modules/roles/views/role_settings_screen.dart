import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/permission_model.dart';
import '../services/enhanced_permission_provider.dart';
import '../services/roles_permissions_service.dart';
import '../../../theme.dart';

/// Écran de configuration et paramètres du système de rôles
class RoleSettingsScreen extends StatefulWidget {
  const RoleSettingsScreen({super.key});

  @override
  State<RoleSettingsScreen> createState() => _RoleSettingsScreenState();
}

class _RoleSettingsScreenState extends State<RoleSettingsScreen> {
  bool _isInitializing = false;
  bool _enableAuditLog = true;
  bool _enableRoleExpiration = true;
  bool _enableMultipleRoles = true;
  int _maxRolesPerUser = 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration des Rôles'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            onPressed: () => _exportConfiguration(context),
            icon: const Icon(Icons.download),
            tooltip: 'Exporter la configuration',
          ),
        ],
      ),
      body: Consumer<PermissionProvider>(
        builder: (context, provider, child) {
          return ListView(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            children: [
              _buildSystemSection(context, provider),
              const SizedBox(height: AppTheme.spaceLarge),
              _buildSecuritySection(context),
              const SizedBox(height: AppTheme.spaceLarge),
              _buildAuditSection(context),
              const SizedBox(height: AppTheme.spaceLarge),
              _buildMaintenanceSection(context, provider),
              const SizedBox(height: AppTheme.spaceLarge),
              _buildDangerZoneSection(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSystemSection(BuildContext context, PermissionProvider provider) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings_system_daydream,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppTheme.spaceSmall),
                Text(
                  'Configuration Système',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: AppTheme.fontSemiBold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            
            // Statut du système
            Container(
              padding: const EdgeInsets.all(AppTheme.space12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Row(
                children: [
                  Icon(
                    provider.isInitialized ? Icons.check_circle : Icons.warning,
                    color: provider.isInitialized 
                        ? AppTheme.successColor 
                        : theme.colorScheme.error,
                  ),
                  const SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.isInitialized 
                              ? 'Système initialisé'
                              : 'Système non initialisé',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: AppTheme.fontSemiBold,
                          ),
                        ),
                        Text(
                          provider.isInitialized
                              ? '${provider.roles.length} rôles • ${provider.systemRoles.length} rôles système'
                              : 'Le système n\'a pas encore été initialisé',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppTheme.spaceMedium),
            
            // Bouton d'initialisation
            if (!provider.isInitialized)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isInitializing ? null : () => _initializeSystem(context, provider),
                  icon: _isInitializing 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow),
                  label: Text(_isInitializing ? 'Initialisation...' : 'Initialiser le système'),
                ),
              ),
              
            // Statistiques
            if (provider.isInitialized) ...[
              const Divider(height: 32),
              Text(
                'Statistiques',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: AppTheme.fontSemiBold,
                ),
              ),
              const SizedBox(height: AppTheme.space12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Rôles totaux',
                      provider.roles.length.toString(),
                      Icons.admin_panel_settings,
                      theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Rôles actifs',
                      provider.activeRoles.length.toString(),
                      Icons.check_circle,
                      AppTheme.successColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Modules',
                      AppModule.allModules.length.toString(),
                      Icons.apps,
                      theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Permissions',
                      _getTotalPermissionsCount().toString(),
                      Icons.security,
                      theme.colorScheme.tertiary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.security,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppTheme.spaceSmall),
                Text(
                  'Sécurité',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: AppTheme.fontSemiBold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            
            SwitchListTile(
              title: const Text('Rôles multiples'),
              subtitle: const Text('Autoriser plusieurs rôles par utilisateur'),
              value: _enableMultipleRoles,
              onChanged: (value) {
                setState(() => _enableMultipleRoles = value);
              },
            ),
            
            if (_enableMultipleRoles) ...[
              const SizedBox(height: AppTheme.spaceSmall),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      'Maximum de rôles par utilisateur: $_maxRolesPerUser',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 120,
                      child: Slider(
                        value: _maxRolesPerUser.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: _maxRolesPerUser.toString(),
                        onChanged: (value) {
                          setState(() => _maxRolesPerUser = value.round());
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const Divider(height: 24),
            
            SwitchListTile(
              title: const Text('Expiration des rôles'),
              subtitle: const Text('Permettre l\'expiration automatique des rôles'),
              value: _enableRoleExpiration,
              onChanged: (value) {
                setState(() => _enableRoleExpiration = value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppTheme.spaceSmall),
                Text(
                  'Audit et Logs',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: AppTheme.fontSemiBold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            
            SwitchListTile(
              title: const Text('Journalisation des audits'),
              subtitle: const Text('Enregistrer toutes les actions sur les rôles'),
              value: _enableAuditLog,
              onChanged: (value) {
                setState(() => _enableAuditLog = value);
              },
            ),
            
            const SizedBox(height: AppTheme.spaceMedium),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showAuditLogs(context),
                    icon: const Icon(Icons.visibility),
                    label: const Text('Voir les logs'),
                  ),
                ),
                const SizedBox(width: AppTheme.space12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _exportAuditLogs(context),
                    icon: const Icon(Icons.download),
                    label: const Text('Exporter'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceSection(BuildContext context, PermissionProvider provider) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.build,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppTheme.spaceSmall),
                Text(
                  'Maintenance',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: AppTheme.fontSemiBold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _cleanupExpiredRoles(context),
                    icon: const Icon(Icons.cleaning_services),
                    label: const Text('Nettoyer les rôles expirés'),
                  ),
                ),
                const SizedBox(width: AppTheme.space12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _validateDataIntegrity(context),
                    icon: const Icon(Icons.verified),
                    label: const Text('Vérifier l\'intégrité'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.space12),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _optimizeDatabase(context),
                    icon: const Icon(Icons.tune),
                    label: const Text('Optimiser la base'),
                  ),
                ),
                const SizedBox(width: AppTheme.space12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _refreshCache(context, provider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Actualiser le cache'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZoneSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      color: theme.colorScheme.errorContainer.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: AppTheme.spaceSmall),
                Text(
                  'Zone de Danger',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: AppTheme.fontSemiBold,
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            
            Text(
              'Ces actions sont irréversibles et peuvent affecter le système.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            
            const SizedBox(height: AppTheme.spaceMedium),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _resetAllRoles(context),
                    icon: const Icon(Icons.restore),
                    label: const Text('Réinitialiser tous les rôles'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.space12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _deleteAllCustomRoles(context),
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Supprimer rôles personnalisés'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: AppTheme.fontBold,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _initializeSystem(BuildContext context, PermissionProvider provider) async {
    setState(() => _isInitializing = true);
    
    try {
      await RolesPermissionsService.initializeSystem();
      await provider.refresh();
      
      if (mounted) {
        _showSuccessSnackBar(context, 'Système initialisé avec succès');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(context, 'Erreur lors de l\'initialisation: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  void _showAuditLogs(BuildContext context) {
    _showInfoSnackBar(context, 'Affichage des logs d\'audit à implémenter');
  }

  void _exportAuditLogs(BuildContext context) {
    _showInfoSnackBar(context, 'Export des logs d\'audit à implémenter');
  }

  void _exportConfiguration(BuildContext context) {
    _showInfoSnackBar(context, 'Export de la configuration à implémenter');
  }

  void _cleanupExpiredRoles(BuildContext context) {
    _showInfoSnackBar(context, 'Nettoyage des rôles expirés à implémenter');
  }

  void _validateDataIntegrity(BuildContext context) {
    _showInfoSnackBar(context, 'Validation de l\'intégrité des données à implémenter');
  }

  void _optimizeDatabase(BuildContext context) {
    _showInfoSnackBar(context, 'Optimisation de la base de données à implémenter');
  }

  void _refreshCache(BuildContext context, PermissionProvider provider) async {
    try {
      await provider.refresh();
      _showSuccessSnackBar(context, 'Cache actualisé avec succès');
    } catch (e) {
      _showErrorSnackBar(context, 'Erreur lors de l\'actualisation: $e');
    }
  }

  void _resetAllRoles(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: AppTheme.spaceSmall),
            const Text('Réinitialiser tous les rôles'),
          ],
        ),
        content: const Text(
          'Cette action supprimera TOUS les rôles personnalisés et réinitialisera '
          'le système avec uniquement les rôles par défaut.\n\n'
          'Cette action est IRRÉVERSIBLE.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _showErrorSnackBar(context, 'Réinitialisation des rôles à implémenter');
            },
            child: const Text('Confirmer la réinitialisation'),
          ),
        ],
      ),
    );
  }

  void _deleteAllCustomRoles(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: AppTheme.spaceSmall),
            const Text('Supprimer les rôles personnalisés'),
          ],
        ),
        content: const Text(
          'Cette action supprimera TOUS les rôles personnalisés créés.\n'
          'Les rôles système seront conservés.\n\n'
          'Cette action est IRRÉVERSIBLE.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _showErrorSnackBar(context, 'Suppression des rôles personnalisés à implémenter');
            },
            child: const Text('Confirmer la suppression'),
          ),
        ],
      ),
    );
  }

  int _getTotalPermissionsCount() {
    return AppModule.allModules.length * 5; // 5 permissions par module
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}