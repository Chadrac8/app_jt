import 'package:flutter/material.dart';
import '../services/group_cleanup_service.dart';
import '../theme.dart';

/// Page d'administration pour nettoyer les événements et meetings orphelins
class GroupCleanupAdminPage extends StatefulWidget {
  const GroupCleanupAdminPage({super.key});

  @override
  State<GroupCleanupAdminPage> createState() => _GroupCleanupAdminPageState();
}

class _GroupCleanupAdminPageState extends State<GroupCleanupAdminPage> {
  CleanupStats? _stats;
  CleanupResult? _lastResult;
  bool _isLoading = false;
  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stats = await GroupCleanupService.getOrphanStats();
      setState(() {
        _stats = stats;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _performCleanup({bool dryRun = false}) async {
    // Confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(dryRun ? 'Analyse' : '⚠️ Confirmer la suppression'),
        content: Text(
          dryRun
              ? 'Analyser les événements et meetings orphelins sans les supprimer ?'
              : 'Êtes-vous sûr de vouloir supprimer définitivement tous les événements et meetings orphelins ?\n\n'
                  'Cette action est irréversible !\n\n'
                  '${_stats?.orphanEvents ?? 0} événements et ${_stats?.orphanMeetings ?? 0} meetings seront supprimés.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: dryRun ? AppTheme.blueStandard : AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: Text(dryRun ? 'Analyser' : 'Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await GroupCleanupService.cleanupOrphanedGroupContent(
        dryRun: dryRun,
      );

      setState(() {
        _lastResult = result;
      });

      // Recharger les stats
      await _loadStats();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              dryRun
                  ? 'Analyse terminée: ${result.totalDeleted} éléments orphelins détectés'
                  : '✅ ${result.totalDeleted} éléments supprimés avec succès',
            ),
            backgroundColor: dryRun ? AppTheme.blueStandard : AppTheme.successColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nettoyage Groupes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadStats,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading && _stats == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spaceLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête
                  _buildHeader(),
                  const SizedBox(height: AppTheme.spaceLarge),

                  // Statistiques
                  _buildStatsCards(),
                  const SizedBox(height: AppTheme.spaceLarge),

                  // Actions
                  _buildActionButtons(),
                  const SizedBox(height: AppTheme.spaceLarge),

                  // Dernier résultat
                  if (_lastResult != null) ...[
                    _buildLastResult(),
                    const SizedBox(height: AppTheme.spaceLarge),
                  ],

                  // Détails des orphelins
                  if (_showDetails && _lastResult != null) _buildOrphanDetails(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    final hasOrphans = _stats?.hasOrphans ?? false;

    return Card(
      color: hasOrphans ? AppTheme.orangeStandard.withOpacity(0.1) : AppTheme.greenStandard.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasOrphans ? Icons.warning_amber : Icons.check_circle,
                  color: hasOrphans ? AppTheme.orangeStandard : AppTheme.greenStandard,
                  size: 40,
                ),
                const SizedBox(width: AppTheme.spaceMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasOrphans ? 'Éléments orphelins détectés' : 'Base de données propre',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: AppTheme.fontBold,
                              color: hasOrphans ? AppTheme.orangeStandard : AppTheme.greenStandard,
                            ),
                      ),
                      const SizedBox(height: AppTheme.spaceSmall),
                      Text(
                        hasOrphans
                            ? 'Des événements/meetings sont liés à des groupes supprimés'
                            : 'Tous les événements et meetings sont correctement liés',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    if (_stats == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Événements',
                _stats!.orphanEvents,
                _stats!.totalEventsWithGroup,
                Icons.event,
                AppTheme.blueStandard,
              ),
            ),
            const SizedBox(width: AppTheme.spaceMedium),
            Expanded(
              child: _buildStatCard(
                'Meetings',
                _stats!.orphanMeetings,
                _stats!.totalMeetings,
                Icons.people,
                AppTheme.blueStandard,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        _buildTotalCard(),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    int orphanCount,
    int totalCount,
    IconData icon,
    Color color,
  ) {
    final percentage = totalCount > 0 ? (orphanCount / totalCount * 100) : 0.0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: AppTheme.spaceSmall),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: AppTheme.fontSemiBold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            Text(
              '$orphanCount',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: AppTheme.fontBold,
                    color: orphanCount > 0 ? AppTheme.orangeStandard : AppTheme.greenStandard,
                  ),
            ),
            Text(
              'orphelins sur $totalCount',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: AppTheme.spaceSmall),
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                orphanCount > 0 ? AppTheme.orangeStandard : AppTheme.greenStandard,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCard() {
    final totalOrphans = _stats?.totalOrphans ?? 0;

    return Card(
      elevation: 3,
      color: totalOrphans > 0 ? AppTheme.orangeStandard.withOpacity(0.1) : AppTheme.greenStandard.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLarge),
        child: Row(
          children: [
            Icon(
              totalOrphans > 0 ? Icons.delete_sweep : Icons.check_circle_outline,
              color: totalOrphans > 0 ? AppTheme.orangeStandard : AppTheme.greenStandard,
              size: 32,
            ),
            const SizedBox(width: AppTheme.spaceMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total éléments orphelins',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppTheme.spaceXSmall),
                  Text(
                    '$totalOrphans',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: AppTheme.fontBold,
                          color: totalOrphans > 0 ? AppTheme.orangeStandard : AppTheme.greenStandard,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final hasOrphans = _stats?.hasOrphans ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _isLoading ? null : () => _performCleanup(dryRun: true),
          icon: const Icon(Icons.search),
          label: const Text('Analyser (Dry Run)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.blueStandard,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
          ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        ElevatedButton.icon(
          onPressed: (_isLoading || !hasOrphans) ? null : () => _performCleanup(dryRun: false),
          icon: const Icon(Icons.delete_sweep),
          label: const Text('Supprimer les orphelins'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.errorColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
          ),
        ),
        const SizedBox(height: AppTheme.spaceSmall),
        Text(
          hasOrphans
              ? '⚠️ La suppression est irréversible'
              : '✅ Aucun orphelin à supprimer',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: hasOrphans ? AppTheme.orangeStandard : AppTheme.greenStandard,
                fontWeight: AppTheme.fontMedium,
              ),
        ),
      ],
    );
  }

  Widget _buildLastResult() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Dernier nettoyage',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: AppTheme.fontBold,
                      ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showDetails = !_showDetails;
                    });
                  },
                  icon: Icon(_showDetails ? Icons.expand_less : Icons.expand_more),
                  label: Text(_showDetails ? 'Masquer' : 'Détails'),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            _buildResultRow('Événements supprimés', _lastResult!.eventsDeleted, Icons.event),
            const SizedBox(height: AppTheme.spaceSmall),
            _buildResultRow('Meetings supprimés', _lastResult!.meetingsDeleted, Icons.people),
            const Divider(height: AppTheme.spaceLarge),
            _buildResultRow(
              'Total',
              _lastResult!.totalDeleted,
              Icons.delete_sweep,
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, int count, IconData icon, {bool isTotal = false}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: isTotal ? AppTheme.primaryColor : Colors.grey[600]),
        const SizedBox(width: AppTheme.spaceSmall),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: isTotal ? AppTheme.fontBold : AppTheme.fontMedium,
              ),
        ),
        const Spacer(),
        Text(
          '$count',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: AppTheme.fontBold,
                color: count > 0 ? AppTheme.successColor : Colors.grey,
              ),
        ),
      ],
    );
  }

  Widget _buildOrphanDetails() {
    if (_lastResult == null || _lastResult!.orphanEvents.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Détails des événements orphelins',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: AppTheme.fontBold,
                  ),
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            ...(_lastResult!.orphanEvents.take(10).map((event) => ListTile(
                  leading: const Icon(Icons.event_busy, color: AppTheme.orangeStandard),
                  title: Text(event.title),
                  subtitle: Text('Groupe: ${event.linkedGroupId}'),
                  trailing: event.seriesId != null
                      ? Chip(
                          label: Text('Série', style: const TextStyle(fontSize: 10)),
                          backgroundColor: AppTheme.blueStandard.withOpacity(0.2),
                        )
                      : null,
                ))),
            if (_lastResult!.orphanEvents.length > 10)
              Padding(
                padding: const EdgeInsets.all(AppTheme.spaceSmall),
                child: Text(
                  '... et ${_lastResult!.orphanEvents.length - 10} autres',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[600],
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
