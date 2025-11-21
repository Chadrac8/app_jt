import 'package:flutter/material.dart';
import '../scripts/fix_existing_recurring_events.dart';

/// Page d'administration pour exécuter la migration des événements récurrents
class FixRecurrenceAdminPage extends StatefulWidget {
  const FixRecurrenceAdminPage({super.key});

  @override
  State<FixRecurrenceAdminPage> createState() => _FixRecurrenceAdminPageState();
}

class _FixRecurrenceAdminPageState extends State<FixRecurrenceAdminPage> {
  bool _isRunning = false;
  String _log = '';

  Future<void> _runMigration() async {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _log = '🔄 Démarrage de la migration...\n\n';
    });

    try {
      // Configurer le callback pour capturer les logs
      FixExistingRecurringEvents.onLog = (message) {
        setState(() {
          _log += '$message\n';
        });
      };

      await FixExistingRecurringEvents.run();

      setState(() {
        _log += '\n✅ Migration terminée avec succès !';
      });
    } catch (e) {
      setState(() {
        _log += '\n❌ ERREUR: $e';
      });
    } finally {
      // Nettoyer le callback
      FixExistingRecurringEvents.onLog = null;
      setState(() {
        _isRunning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔧 Migration Événements Récurrents'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // En-tête explicatif
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'À propos de cette migration',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Cette migration corrige les événements récurrents créés avant la mise à jour.\n\n'
                      'Problème : Les événements ont isRecurring=true mais le champ recurrence est vide.\n'
                      'Solution : Récupère les règles depuis event_recurrences et les ajoute aux événements.\n\n'
                      '⚠️  Exécutez cette migration UNE SEULE FOIS après le déploiement.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Bouton de lancement
            ElevatedButton.icon(
              onPressed: _isRunning ? null : _runMigration,
              icon: _isRunning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(
                _isRunning ? 'Migration en cours...' : 'Lancer la Migration',
                style: const TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Log
            Expanded(
              child: Card(
                color: Colors.grey.shade900,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _log.isEmpty
                        ? '📋 Les logs de migration apparaîtront ici...'
                        : _log,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: _log.isEmpty ? Colors.grey.shade500 : Colors.green.shade300,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
