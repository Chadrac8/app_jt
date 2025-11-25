import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sermon_analytics.dart';
import '../providers/sermon_analytics_provider.dart';

/// Widget affichant les statistiques d'un sermon
class SermonStatsCard extends StatelessWidget {
  final String sermonId;
  final VoidCallback? onTap;

  const SermonStatsCard({
    Key? key,
    required this.sermonId,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SermonAnalyticsProvider>(
      builder: (context, provider, child) {
        final analytics = provider.getSermonAnalytics(sermonId);

        if (analytics == null) {
          return const SizedBox.shrink();
        }

        final theme = Theme.of(context);

        return InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Progression circulaire
                SizedBox(
                  width: 50,
                  height: 50,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: analytics.progressPercent / 100,
                        backgroundColor: theme.colorScheme.surfaceVariant,
                        strokeWidth: 4,
                      ),
                      Center(
                        child: Text(
                          '${analytics.progressPercent.toInt()}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                
                // Statistiques
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            analytics.formattedReadingTime,
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.visibility,
                            size: 16,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${analytics.viewCount} vues',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Page ${analytics.lastPageRead}/${analytics.totalPages}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                
                // Badge complété
                if (analytics.isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.check, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Terminé',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Dialogue affichant les statistiques détaillées
class SermonStatsDialog extends StatelessWidget {
  final SermonAnalytics analytics;

  const SermonStatsDialog({
    Key? key,
    required this.analytics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Statistiques de lecture'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progression
            _buildStatRow(
              context,
              Icons.trending_up,
              'Progression',
              '${analytics.progressPercent.toInt()}%',
            ),
            const Divider(),
            
            // Temps de lecture
            _buildStatRow(
              context,
              Icons.access_time,
              'Temps de lecture',
              analytics.formattedReadingTime,
            ),
            const Divider(),
            
            // Nombre de vues
            _buildStatRow(
              context,
              Icons.visibility,
              'Nombre de vues',
              '${analytics.viewCount}',
            ),
            const Divider(),
            
            // Sessions
            _buildStatRow(
              context,
              Icons.event_note,
              'Sessions',
              '${analytics.sessions.length}',
            ),
            const Divider(),
            
            // Temps moyen par session
            _buildStatRow(
              context,
              Icons.schedule,
              'Temps moyen/session',
              analytics.averageSessionTime,
            ),
            const Divider(),
            
            // Page actuelle
            _buildStatRow(
              context,
              Icons.bookmark,
              'Position',
              'Page ${analytics.lastPageRead}/${analytics.totalPages}',
            ),
            const Divider(),
            
            // Dernière lecture
            _buildStatRow(
              context,
              Icons.calendar_today,
              'Dernière lecture',
              _formatDate(analytics.lastViewDate),
            ),
            
            // Sessions récentes
            if (analytics.recentSessions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Sessions récentes',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ...analytics.recentSessions.take(5).map((session) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDate(session.startDate),
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        session.formattedDuration,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ],
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return "Aujourd'hui";
    } else if (diff.inDays == 1) {
      return 'Hier';
    } else if (diff.inDays < 7) {
      return 'Il y a ${diff.inDays} jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

/// Widget affichant les statistiques globales
class GlobalStatsWidget extends StatefulWidget {
  const GlobalStatsWidget({Key? key}) : super(key: key);

  @override
  State<GlobalStatsWidget> createState() => _GlobalStatsWidgetState();
}

class _GlobalStatsWidgetState extends State<GlobalStatsWidget> {
  Map<String, dynamic>? _globalStats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    
    final provider = Provider.of<SermonAnalyticsProvider>(context, listen: false);
    final stats = await provider.getGlobalStats();
    
    setState(() {
      _globalStats = stats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_globalStats == null) {
      return const Center(child: Text('Aucune statistique'));
    }

    final theme = Theme.of(context);
    final totalTime = _formatDuration(_globalStats!['totalReadingTimeSeconds'] as int);
    final totalSermons = _globalStats!['totalSermonsViewed'] as int;
    final avgTime = _globalStats!['averageReadingTime'] as String;
    final stats7Days = _globalStats!['last7Days'] as Map<String, dynamic>;
    final stats30Days = _globalStats!['last30Days'] as Map<String, dynamic>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Text(
            'Mes statistiques',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Stats générales
          _buildStatsCard(
            context,
            'Statistiques générales',
            [
              _StatItem(Icons.access_time, 'Temps total', totalTime),
              _StatItem(Icons.library_books, 'Sermons consultés', '$totalSermons'),
              _StatItem(Icons.schedule, 'Temps moyen', avgTime),
            ],
          ),
          const SizedBox(height: 16),
          
          // 7 derniers jours
          _buildStatsCard(
            context,
            '7 derniers jours',
            [
              _StatItem(Icons.book, 'Sermons lus', '${stats7Days['sermonsRead']}'),
              _StatItem(Icons.access_time, 'Temps', _formatDuration(stats7Days['totalReadingTimeSeconds'] as int)),
              _StatItem(Icons.event_note, 'Sessions', '${stats7Days['totalSessions']}'),
            ],
          ),
          const SizedBox(height: 16),
          
          // 30 derniers jours
          _buildStatsCard(
            context,
            '30 derniers jours',
            [
              _StatItem(Icons.book, 'Sermons lus', '${stats30Days['sermonsRead']}'),
              _StatItem(Icons.access_time, 'Temps', _formatDuration(stats30Days['totalReadingTimeSeconds'] as int)),
              _StatItem(Icons.event_note, 'Sessions', '${stats30Days['totalSessions']}'),
            ],
          ),
          const SizedBox(height: 24),
          
          // Listes
          _buildTopSermonsList(context),
        ],
      ),
    );
  }

  Widget _buildStatsCard(
    BuildContext context,
    String title,
    List<_StatItem> items,
  ) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...items.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(item.icon, size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.label,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      item.value,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSermonsList(BuildContext context) {
    final provider = Provider.of<SermonAnalyticsProvider>(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sermons les plus consultés',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<SermonAnalytics>>(
          future: provider.getMostViewedSermons(limit: 5),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final sermons = snapshot.data!;
            
            if (sermons.isEmpty) {
              return const Center(child: Text('Aucun sermon consulté'));
            }

            return Column(
              children: sermons.map((analytics) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text('${analytics.viewCount}'),
                    ),
                    title: Text(analytics.sermonId),
                    subtitle: Text(
                      '${analytics.formattedReadingTime} • ${analytics.progressPercent.toInt()}% lu',
                    ),
                    trailing: Icon(
                      analytics.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: analytics.isCompleted ? Colors.green : null,
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '${seconds}s';
    }
  }
}

class _StatItem {
  final IconData icon;
  final String label;
  final String value;

  _StatItem(this.icon, this.label, this.value);
}
