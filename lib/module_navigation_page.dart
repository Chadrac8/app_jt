import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'theme.dart';

// Providers
import 'modules/roles/providers/role_provider.dart';
import 'modules/roles/providers/permission_provider.dart';
import 'modules/roles/providers/role_template_provider.dart';

// Screens
import 'modules/roles/screens/role_module_test_page.dart';
import 'modules/roles/screens/role_template_management_screen.dart';

// Themes
import 'theme.dart';

/// Page de navigation principale pour accéder aux différents modules de l'application
class ModuleNavigationPage extends StatelessWidget {
  const ModuleNavigationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modules Jubilé Tabernacle'),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(context),
              const SizedBox(height: AppTheme.spaceLarge),
              _buildModulesSection(context),
              const SizedBox(height: AppTheme.spaceLarge),
              _buildQuickActionsSection(context),
              const SizedBox(height: AppTheme.spaceLarge),
              _buildInfoSection(context),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToRoleModule(context),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
        label: const Text('Module Rôles', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return Card(
      elevation: 2,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.space20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor.withOpacity(0.8),
              AppTheme.primaryColor,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.church,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: AppTheme.space12),
                const Expanded(
                  child: Text(
                    'Bienvenue dans l\'application',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: AppTheme.fontSize24,
                      fontWeight: AppTheme.fontBold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceSmall),
            const Text(
              'Gérez facilement tous les aspects de votre communauté religieuse',
              style: TextStyle(
                color: Colors.white70,
                fontSize: AppTheme.fontSize16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModulesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Modules disponibles',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: AppTheme.fontBold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildModuleCard(
              context,
              title: 'Rôles & Permissions',
              subtitle: 'Gestion complète des accès',
              icon: Icons.admin_panel_settings,
              color: AppTheme.primaryColor,
              onTap: () => _navigateToRoleModule(context),
              isImplemented: true,
            ),
            _buildModuleCard(
              context,
              title: 'Événements',
              subtitle: 'Calendrier et récurrences',
              icon: Icons.event,
              color: AppTheme.success,
              onTap: () => _showComingSoon(context, 'Événements'),
              isImplemented: false,
            ),
            _buildModuleCard(
              context,
              title: 'Membres',
              subtitle: 'Gestion des fidèles',
              icon: Icons.people,
              color: AppTheme.info,
              onTap: () => _showComingSoon(context, 'Membres'),
              isImplemented: false,
            ),
            _buildModuleCard(
              context,
              title: 'Pain Quotidien',
              subtitle: 'Messages spirituels',
              icon: Icons.book,
              color: AppTheme.warning,
              onTap: () => _showComingSoon(context, 'Pain Quotidien'),
              isImplemented: false,
            ),
            _buildModuleCard(
              context,
              title: 'Finances',
              subtitle: 'Dîmes et offrandes',
              icon: Icons.account_balance_wallet,
              color: AppTheme.success,
              onTap: () => _showComingSoon(context, 'Finances'),
              isImplemented: false,
            ),
            _buildModuleCard(
              context,
              title: 'Cantiques',
              subtitle: 'Bibliothèque musicale',
              icon: Icons.music_note,
              color: AppTheme.pinkStandard,
              onTap: () => _showComingSoon(context, 'Cantiques'),
              isImplemented: false,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions rapides',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: AppTheme.fontBold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _navigateToTemplateManagement(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.view_module),
                label: const Text('Templates Rôles'),
              ),
            ),
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showSystemInfo(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.info),
                label: const Text('Infos Système'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: AppTheme.warning),
                const SizedBox(width: AppTheme.spaceSmall),
                const Text(
                  'État du développement',
                  style: TextStyle(fontWeight: AppTheme.fontBold, fontSize: AppTheme.fontSize16),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space12),
            _buildStatusItem('Module Rôles', true, 'Complètement fonctionnel avec système de templates'),
            _buildStatusItem('Module Événements', false, 'En cours de développement'),
            _buildStatusItem('Module Membres', false, 'Planifié pour la prochaine version'),
            _buildStatusItem('Module Pain Quotidien', false, 'Partiellement implémenté'),
            _buildStatusItem('Module Finances', false, 'À venir'),
            _buildStatusItem('Module Cantiques', false, 'À venir'),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isImplemented,
  }) {
    return Card(
      elevation: isImplemented ? 4 : 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: isImplemented 
                ? Border.all(color: color.withOpacity(0.3), width: 2)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.space12),
                decoration: BoxDecoration(
                  color: isImplemented ? color.withOpacity(0.1) : AppTheme.grey500.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                ),
                child: Icon(
                  icon,
                  color: isImplemented ? color : AppTheme.grey500,
                  size: 32,
                ),
              ),
              const SizedBox(height: AppTheme.space12),
              Text(
                title,
                style: TextStyle(
                  fontWeight: AppTheme.fontBold,
                  fontSize: AppTheme.fontSize14,
                  color: isImplemented ? Colors.black87 : AppTheme.grey500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spaceXSmall),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: AppTheme.fontSize12,
                  color: isImplemented ? Colors.black54 : AppTheme.grey500,
                ),
                textAlign: TextAlign.center,
              ),
              if (!isImplemented) ...[
                const SizedBox(height: AppTheme.spaceSmall),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  ),
                  child: const Text(
                    'À venir',
                    style: TextStyle(
                      fontSize: AppTheme.fontSize10,
                      color: AppTheme.warning,
                      fontWeight: AppTheme.fontBold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusItem(String title, bool isImplemented, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isImplemented ? AppTheme.success : AppTheme.warning,
            ),
            child: Icon(
              isImplemented ? Icons.check : Icons.schedule,
              color: Colors.white,
              size: 12,
            ),
          ),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: AppTheme.fontMedium),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: AppTheme.fontSize12,
                    color: AppTheme.grey600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToRoleModule(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => RoleProvider()),
            ChangeNotifierProvider(create: (_) => PermissionProvider()),
            ChangeNotifierProvider(create: (_) => RoleTemplateProvider()),
          ],
          child: const RoleModuleTestPage(),
        ),
      ),
    );
  }

  void _navigateToTemplateManagement(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => RoleProvider()),
            ChangeNotifierProvider(create: (_) => PermissionProvider()),
            ChangeNotifierProvider(create: (_) => RoleTemplateProvider()),
          ],
          child: const RoleTemplateManagementScreen(),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String moduleName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.construction, color: AppTheme.warning),
            const SizedBox(width: AppTheme.spaceSmall),
            Text('Module $moduleName'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Le module $moduleName est actuellement en cours de développement.',
              style: const TextStyle(fontSize: AppTheme.fontSize16),
            ),
            const SizedBox(height: AppTheme.space12),
            const Text(
              'Fonctionnalités prévues :',
              style: TextStyle(fontWeight: AppTheme.fontBold),
            ),
            const SizedBox(height: AppTheme.spaceSmall),
            _getModuleFeatures(moduleName),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToRoleModule(context); // Rediriger vers le module fonctionnel
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Voir Module Rôles'),
          ),
        ],
      ),
    );
  }

  Widget _getModuleFeatures(String moduleName) {
    final Map<String, List<String>> features = {
      'Événements': [
        '• Création d\'événements récurrents',
        '• Gestion du calendrier',
        '• Notifications automatiques',
        '• Inscription des participants',
      ],
      'Membres': [
        '• Annuaire des membres',
        '• Gestion des groupes',
        '• Historique de participation',
        '• Communication intégrée',
      ],
      'Pain Quotidien': [
        '• Méditations quotidiennes',
        '• Planification des messages',
        '• Notifications push',
        '• Archive consultable',
      ],
      'Finances': [
        '• Suivi des dîmes',
        '• Gestion des offrandes',
        '• Rapports financiers',
        '• Budgets et projections',
      ],
      'Cantiques': [
        '• Bibliothèque de cantiques',
        '• Recherche avancée',
        '• Listes de lecture',
        '• Partage et favoris',
      ],
    };

    final moduleFeatures = features[moduleName] ?? ['• Fonctionnalités à définir'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: moduleFeatures
          .map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(feature, style: const TextStyle(fontSize: AppTheme.fontSize14)),
              ))
          .toList(),
    );
  }

  void _showSystemInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info, color: AppTheme.info),
            const SizedBox(width: AppTheme.spaceSmall),
            const Text('Informations Système'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Application Jubilé Tabernacle',
                style: TextStyle(fontWeight: AppTheme.fontBold, fontSize: AppTheme.fontSize16),
              ),
              SizedBox(height: AppTheme.spaceSmall),
              Text('Version: 1.0.0 (Beta)'),
              Text('Framework: Flutter 3.32.5'),
              Text('Backend: Firebase'),
              Text('État: Développement actif'),
              SizedBox(height: AppTheme.spaceMedium),
              Text(
                'Module Rôles & Permissions:',
                style: TextStyle(fontWeight: AppTheme.fontBold),
              ),
              Text('✅ Templates système (9 prédéfinis)'),
              Text('✅ Gestion complète des rôles'),
              Text('✅ Matrice des permissions'),
              Text('✅ Opérations en masse'),
              Text('✅ Interface de test complète'),
              SizedBox(height: AppTheme.spaceMedium),
              Text(
                'Prochaines étapes:',
                style: TextStyle(fontWeight: AppTheme.fontBold),
              ),
              Text('🔄 Finalisation module Événements'),
              Text('🔄 Intégration Firebase complète'),
              Text('🔄 Tests d\'intégration'),
              Text('🔄 Documentation utilisateur'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}