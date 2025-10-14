import 'package:flutter/material.dart';
import 'package:staggered_grid_view_flutter/widgets/staggered_grid_view.dart';
import 'package:staggered_grid_view_flutter/widgets/staggered_tile.dart';
import '../../models/dashboard_widget_model.dart';
import '../../services/dashboard_firebase_service.dart';
import '../../services/statistics_service.dart';
import '../../widgets/dashboard_widgets/dashboard_stat_widget.dart';
import '../../widgets/dashboard_widgets/dashboard_chart_widget.dart';
import '../../widgets/dashboard_widgets/dashboard_list_widget.dart';
import '../../widgets/member_view_toggle_button.dart';
import '../../widgets/bottom_navigation_wrapper.dart';
import 'dashboard_configuration_page.dart';
import 'home_config_admin_page.dart';
import 'outbox_notifications_page.dart';
import '../../../theme.dart';
import '../../temp_cleanup.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({Key? key}) : super(key: key);

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool _isLoading = true;
  bool _isRefreshing = false;
  Map<String, dynamic> _preferences = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  Future<void> _initializeDashboard() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Vérifier si l'utilisateur a des widgets configurés
      final hasWidgets = await DashboardFirebaseService.hasConfiguredWidgets();
      
      if (!hasWidgets) {
        // Initialiser les widgets par défaut
        await DashboardFirebaseService.initializeDefaultWidgets();
      }

      // Charger les préférences
      _preferences = await DashboardFirebaseService.getDashboardPreferences();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur lors de l\'initialisation du dashboard: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur lors du chargement du dashboard: $e';
      });
    }
  }

  Future<void> _refreshDashboard() async {
    try {
      setState(() {
        _isRefreshing = true;
      });

      // Recharger les préférences
      _preferences = await DashboardFirebaseService.getDashboardPreferences();

      setState(() {
        _isRefreshing = false;
      });

      // Afficher un message de confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dashboard actualisé'),
            backgroundColor: AppTheme.greenStandard,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Erreur lors de l\'actualisation: $e');
      setState(() {
        _isRefreshing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'actualisation: $e'),
            backgroundColor: AppTheme.redStandard,
          ),
        );
      }
    }
  }

  Future<void> _cleanupOrphanEvents() async {
    // Afficher un dialog de confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cleaning_services, color: Colors.orange),
            SizedBox(width: 8),
            Text('Nettoyer les événements orphelins'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cette action va rechercher et supprimer tous les événements '
              'du calendrier dont les réunions de groupe ont été supprimées.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Événements concernés :',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('• Événements sans réunion liée'),
                  Text('• Réunions supprimées manuellement'),
                  Text('• Événements orphelins dans le calendrier'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Cette action est irréversible. Continuer ?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Nettoyer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Afficher un spinner pendant le nettoyage
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Nettoyage en cours...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Lancer le nettoyage
      await runCleanup();

      if (mounted) {
        Navigator.pop(context); // Fermer le spinner
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('✅ Nettoyage terminé avec succès'),
                ),
              ],
            ),
            backgroundColor: AppTheme.greenStandard,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Fermer le spinner
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('❌ Erreur: $e'),
                ),
              ],
            ),
            backgroundColor: AppTheme.redStandard,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: AppTheme.white100,
        elevation: 0,
        actions: [
          // Bouton de basculement vers la vue membre
          AppBarMemberViewToggle(
            onToggle: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const BottomNavigationWrapper(initialRoute: 'dashboard'),
                ),
                (route) => false,
              );
            },
          ),
          // Bouton de configuration de la dashboard membre
          IconButton(
            onPressed: () => _navigateToHomeConfiguration(),
            icon: const Icon(Icons.home_filled),
            tooltip: 'Configurer l\'accueil membre',
          ),
          // Bouton de rafraîchissement
          IconButton(
            onPressed: _isRefreshing ? null : _refreshDashboard,
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white100),
                    ),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Actualiser',
          ),
          // Bouton de nettoyage des événements orphelins
          IconButton(
            onPressed: _cleanupOrphanEvents,
            icon: const Icon(Icons.cleaning_services),
            tooltip: 'Nettoyer les événements orphelins',
          ),
          // Bouton de configuration
          IconButton(
            onPressed: () => _navigateToConfiguration(),
            icon: const Icon(Icons.settings),
            tooltip: 'Configurer le dashboard',
          ),
          // Bouton pour accéder à l'outbox notifications
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const OutboxNotificationsPage(),
                ),
              );
            },
            icon: const Icon(Icons.notifications_active),
            tooltip: 'Outbox Notifications',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              AppTheme.white100,
            ],
          ),
        ),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppTheme.spaceMedium),
            Text('Chargement du dashboard...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.grey300,
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: AppTheme.fontSize16),
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            ElevatedButton(
              onPressed: _initializeDashboard,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<List<DashboardWidgetModel>>(
      stream: DashboardFirebaseService.getDashboardWidgetsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppTheme.grey300,
                ),
                const SizedBox(height: AppTheme.spaceMedium),
                Text(
                  'Erreur: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spaceMedium),
                ElevatedButton(
                  onPressed: _initializeDashboard,
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final widgets = snapshot.data!;
        
        if (widgets.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: _refreshDashboard,
          child: _buildDashboardGrid(widgets),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.dashboard,
            size: 80,
            color: AppTheme.grey400,
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          Text(
            'Aucun widget configuré',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.grey600,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Text(
            'Configurez votre dashboard pour afficher les statistiques importantes',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.grey500,
            ),
          ),
          const SizedBox(height: AppTheme.spaceLarge),
          ElevatedButton.icon(
            onPressed: _navigateToConfiguration,
            icon: const Icon(Icons.settings),
            label: const Text('Configurer le Dashboard'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardGrid(List<DashboardWidgetModel> widgets) {
    final compactView = _preferences['compactView'] ?? false;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
          child: SizedBox(
            height: constraints.maxHeight,
            child: StaggeredGridView.countBuilder(
              crossAxisCount: 4,
              itemCount: widgets.length,
              itemBuilder: (context, index) {
                final widget = widgets[index];
                return _buildDashboardWidget(widget, compactView);
              },
              staggeredTileBuilder: (index) {
                final widget = widgets[index];
                return _getStaggeredTile(widget, compactView);
              },
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
            ),
          ),
        );
      },
    );
  }

  StaggeredTile _getStaggeredTile(DashboardWidgetModel widget, bool compactView) {
    switch (widget.type) {
      case 'stat':
        return compactView 
            ? const StaggeredTile.count(2, 1.5)
            : const StaggeredTile.count(2, 1.8);
      case 'chart':
        return compactView 
            ? const StaggeredTile.count(4, 2)
            : const StaggeredTile.count(4, 2.5);
      case 'list':
        return compactView 
            ? const StaggeredTile.count(4, 2)
            : const StaggeredTile.count(4, 3);
      default:
        return const StaggeredTile.count(2, 1.5);
    }
  }

  Widget _buildDashboardWidget(DashboardWidgetModel widget, bool compactView) {
    switch (widget.type) {
      case 'stat':
        return FutureBuilder<DashboardStatModel>(
          future: StatisticsService.calculateWidgetStatistics(widget),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return DashboardStatWidget(
                stat: snapshot.data!,
                compactView: compactView,
              );
            }
            return _buildLoadingWidget(widget.title);
          },
        );
        
      case 'chart':
        return FutureBuilder<DashboardChartModel>(
          future: StatisticsService.calculateChartData(widget),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return DashboardChartWidget(
                chart: snapshot.data!,
                compactView: compactView,
              );
            }
            return _buildLoadingWidget(widget.title);
          },
        );
        
      case 'list':
        return FutureBuilder<DashboardListModel>(
          future: StatisticsService.calculateListData(widget),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return DashboardListWidget(
                listData: snapshot.data!,
                compactView: compactView,
              );
            }
            return _buildLoadingWidget(widget.title);
          },
        );
        
      default:
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            child: Center(
              child: Text('Widget non supporté: ${widget.type}'),
            ),
          ),
        );
    }
  }

  Widget _buildLoadingWidget(String title) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppTheme.spaceSmall),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToHomeConfiguration() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const HomeConfigAdminPage(),
      ),
    );
  }

  void _navigateToConfiguration() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DashboardConfigurationPage(),
      ),
    );
  }
}