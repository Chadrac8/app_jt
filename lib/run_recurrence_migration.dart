import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'scripts/fix_existing_recurring_events.dart';

/// Point d'entrée pour exécuter la migration des événements récurrents
/// 
/// Pour exécuter :
/// flutter run -t lib/run_recurrence_migration.dart -d chrome
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MigrationApp());
}

class MigrationApp extends StatelessWidget {
  const MigrationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Migration Événements Récurrents',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MigrationPage(),
    );
  }
}

class MigrationPage extends StatefulWidget {
  const MigrationPage({super.key});

  @override
  State<MigrationPage> createState() => _MigrationPageState();
}

class _MigrationPageState extends State<MigrationPage> {
  bool _isRunning = false;
  bool _isCompleted = false;
  final List<String> _logs = [];

  Future<void> _runMigration() async {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _isCompleted = false;
      _logs.clear();
      _logs.add('🔄 Démarrage de la migration...\n');
    });

    try {
      // Configurer le callback pour capturer les logs
      FixExistingRecurringEvents.onLog = (message) {
        setState(() {
          _logs.add(message);
        });
      };

      await FixExistingRecurringEvents.run();

      setState(() {
        _logs.add('\n✅ Migration terminée avec succès !');
        _logs.add('\n🎉 Vous pouvez maintenant vérifier le calendrier.');
        _isCompleted = true;
      });
    } catch (e, stackTrace) {
      setState(() {
        _logs.add('\n❌ ERREUR: $e');
        _logs.add('\n📋 Stack trace:');
        _logs.add(stackTrace.toString());
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
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('🔧 Migration Événements Récurrents'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // En-tête
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, 
                          color: Colors.blue.shade700, 
                          size: 28
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Migration des Événements Récurrents',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '✅ Cette migration corrige les événements récurrents existants\n'
                      '✅ Ajoute le champ "recurrence" aux événements qui en manquent\n'
                      '✅ Permet au calendrier d\'afficher les occurrences\n\n'
                      '⚠️  À exécuter UNE SEULE FOIS après le déploiement\n'
                      '⚠️  Peut prendre quelques secondes selon le nombre d\'événements',
                      style: TextStyle(fontSize: 15, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Bouton de lancement
            SizedBox(
              height: 60,
              child: ElevatedButton.icon(
                onPressed: _isRunning ? null : _runMigration,
                icon: _isRunning
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                      )
                    : Icon(_isCompleted ? Icons.check_circle : Icons.play_arrow, 
                        size: 28
                      ),
                label: Text(
                  _isRunning 
                      ? 'Migration en cours...' 
                      : (_isCompleted ? 'Migration Terminée ✅' : 'Lancer la Migration'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isCompleted 
                      ? Colors.green 
                      : Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Logs
            Expanded(
              child: Card(
                color: Colors.grey.shade900,
                elevation: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // En-tête des logs
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.terminal, color: Colors.green.shade300, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Console de Migration',
                            style: TextStyle(
                              color: Colors.green.shade300,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Contenu des logs
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: _logs.isEmpty
                            ? Center(
                                child: Text(
                                  '📋 Cliquez sur "Lancer la Migration" pour commencer...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              )
                            : SelectableText(
                                _logs.join('\n'),
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 13,
                                  color: Colors.green.shade300,
                                  height: 1.5,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
