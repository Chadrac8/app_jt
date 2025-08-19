import 'package:flutter/material.dart';
import '../modules/songs/services/songs_firebase_service.dart';
import '../widgets/setlist_stats_charts.dart';

class SetlistStatisticsPage extends StatelessWidget {
  const SetlistStatisticsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistiques des playlists')), 
      body: FutureBuilder<Map<String, dynamic>>(
        future: SongsFirebaseService.getSetlistsStatistics(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: [200m${snapshot.error}[0m'));
          }
          final stats = snapshot.data ?? {};
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Playlists créées', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      Text('Total: [200m${stats['totalSetlists'] ?? 0}[0m'),
                      const SizedBox(height: 8),
                      Text('Utilisations totales: [200m${stats['totalUsage'] ?? 0}[0m'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Top utilisateurs (créateurs)', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      if ((stats['topCreators'] ?? []).isEmpty)
                        const Text('Aucune donnée'),
                      for (final user in (stats['topCreators'] ?? []))
                        ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(user['name'] ?? user['id'] ?? 'Inconnu'),
                          trailing: Text('${user['count']} playlists'),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Top playlists par nombre de chants', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      if ((stats['topSetlists'] ?? []).isEmpty)
                        const Text('Aucune donnée'),
                      if ((stats['topSetlists'] ?? []).isNotEmpty)
                        SetlistStatsPieChart(
                          data: {
                            for (final s in (stats['topSetlists'] as List))
                              s['name'] ?? s['id']: s['count'] as int,
                          },
                          title: 'Top playlists par nombre de chants',
                          colors: [
                            Colors.blue,
                            Colors.green,
                            Colors.orange,
                            Colors.purple,
                            Colors.red,
                            Colors.teal,
                            Colors.brown,
                            Colors.pink,
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
