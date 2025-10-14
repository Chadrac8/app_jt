import 'package:flutter/material.dart';
import 'package:jubile_tabernacle_france/services/group_cleanup_service.dart';

/// Exemple d'utilisation du service de nettoyage
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Exemple 1 : Obtenir les statistiques
  await exemple1_getStats();
  
  // Exemple 2 : Analyse (dry-run)
  await exemple2_dryRun();
  
  // Exemple 3 : Nettoyage réel
  // await exemple3_cleanup();
}

/// Exemple 1 : Obtenir les statistiques des orphelins
Future<void> exemple1_getStats() async {
  print('\n=== EXEMPLE 1 : Statistiques ===\n');
  
  try {
    final stats = await GroupCleanupService.getOrphanStats();
    
    print('📊 Statistiques :');
    print('   Événements orphelins: ${stats.orphanEvents} sur ${stats.totalEventsWithGroup}');
    print('   Meetings orphelins: ${stats.orphanMeetings} sur ${stats.totalMeetings}');
    print('   Total orphelins: ${stats.totalOrphans}');
    print('   Base propre: ${!stats.hasOrphans}');
    
  } catch (e) {
    print('❌ Erreur: $e');
  }
}

/// Exemple 2 : Analyse sans suppression (dry-run)
Future<void> exemple2_dryRun() async {
  print('\n=== EXEMPLE 2 : Analyse (Dry-Run) ===\n');
  
  try {
    final result = await GroupCleanupService.cleanupOrphanedGroupContent(
      dryRun: true,  // Ne supprime rien, juste liste
    );
    
    print('🔍 Résultat de l\'analyse :');
    print('   Événements à supprimer: ${result.eventsDeleted}');
    print('   Meetings à supprimer: ${result.meetingsDeleted}');
    print('   Total: ${result.totalDeleted}');
    
    if (result.eventsBySeries.isNotEmpty) {
      print('\n📦 Répartition par série :');
      result.eventsBySeries.forEach((seriesId, count) {
        if (seriesId != null) {
          print('      - Série $seriesId: $count événements');
        } else {
          print('      - Sans série: $count événements');
        }
      });
    }
    
    if (result.orphanEvents.isNotEmpty) {
      print('\n📋 Premiers orphelins détectés :');
      for (final event in result.orphanEvents.take(5)) {
        print('      - ${event.title} (groupe: ${event.linkedGroupId})');
      }
      if (result.orphanEvents.length > 5) {
        print('      ... et ${result.orphanEvents.length - 5} autres');
      }
    }
    
  } catch (e) {
    print('❌ Erreur: $e');
  }
}

/// Exemple 3 : Nettoyage réel (SUPPRIME LES ORPHELINS)
Future<void> exemple3_cleanup() async {
  print('\n=== EXEMPLE 3 : Nettoyage Réel ===\n');
  print('⚠️  ATTENTION : Cette opération va SUPPRIMER définitivement les orphelins !');
  
  try {
    final result = await GroupCleanupService.cleanupOrphanedGroupContent(
      dryRun: false,  // Suppression réelle
    );
    
    print('✅ Nettoyage terminé :');
    print('   ${result.eventsDeleted} événements supprimés');
    print('   ${result.meetingsDeleted} meetings supprimés');
    print('   Total: ${result.totalDeleted} éléments supprimés');
    
  } catch (e) {
    print('❌ Erreur: $e');
  }
}

/// Exemple 4 : Nettoyer les événements d'un groupe spécifique
Future<void> exemple4_cleanupSpecificGroup(String groupId) async {
  print('\n=== EXEMPLE 4 : Nettoyage Groupe Spécifique ===\n');
  
  try {
    // Nettoyer les événements
    final eventsCount = await GroupCleanupService.cleanupGroupEvents(groupId);
    print('✅ $eventsCount événements supprimés pour le groupe $groupId');
    
    // Nettoyer les meetings
    final meetingsCount = await GroupCleanupService.cleanupGroupMeetings(groupId);
    print('✅ $meetingsCount meetings supprimés pour le groupe $groupId');
    
  } catch (e) {
    print('❌ Erreur: $e');
  }
}

/// Exemple 5 : Utilisation dans un bouton Flutter
class CleanupButtonExample extends StatefulWidget {
  const CleanupButtonExample({super.key});

  @override
  State<CleanupButtonExample> createState() => _CleanupButtonExampleState();
}

class _CleanupButtonExampleState extends State<CleanupButtonExample> {
  bool _isLoading = false;
  CleanupStats? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    
    try {
      final stats = await GroupCleanupService.getOrphanStats();
      setState(() => _stats = stats);
    } catch (e) {
      print('Erreur: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _performCleanup() async {
    // Confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer ${_stats?.totalOrphans ?? 0} éléments orphelins ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final result = await GroupCleanupService.cleanupOrphanedGroupContent(
        dryRun: false,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${result.totalDeleted} éléments supprimés'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Recharger les stats
      await _loadStats();
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
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nettoyage')),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_stats != null) ...[
                    Text(
                      'Orphelins détectés: ${_stats!.totalOrphans}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 20),
                  ],
                  ElevatedButton.icon(
                    onPressed: _stats != null && _stats!.hasOrphans
                        ? _performCleanup
                        : null,
                    icon: const Icon(Icons.delete_sweep),
                    label: const Text('Nettoyer'),
                  ),
                ],
              ),
      ),
    );
  }
}
