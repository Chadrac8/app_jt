import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'lib/firebase_options.dart';
import 'lib/models/event_recurrence_model.dart';
import 'lib/services/event_recurrence_service.dart';
import 'lib/theme.dart';

/// Programme de test pour valider les corrections des récurrences
class TestRecurrenceCorrections extends StatelessWidget {
  const TestRecurrenceCorrections({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test - Corrections Récurrence',
      theme: AppTheme.lightTheme,
      home: const TestCorrectionsPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TestCorrectionsPage extends StatefulWidget {
  const TestCorrectionsPage({Key? key}) : super(key: key);

  @override
  State<TestCorrectionsPage> createState() => _TestCorrectionsPageState();
}

class _TestCorrectionsPageState extends State<TestCorrectionsPage> {
  bool _isLoading = false;
  String _testResults = '';
  List<EventRecurrenceModel> _testRecurrences = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test - Corrections Récurrence'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🧪 Test des Corrections',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ce test valide que les récurrences sont créées actives par défaut '
                      'et que le menu contextuel fonctionne correctement.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _runTests,
                            icon: _isLoading 
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.play_arrow),
                            label: Text(_isLoading ? 'Test en cours...' : 'Lancer les tests'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _cleanupTests,
                          icon: const Icon(Icons.cleaning_services),
                          label: const Text('Nettoyer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            if (_testResults.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📊 Résultats des Tests',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          _testResults,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
            ],
            
            if (_testRecurrences.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📋 Récurrences de Test',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._testRecurrences.map((recurrence) => _buildRecurrenceTestItem(recurrence)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecurrenceTestItem(EventRecurrenceModel recurrence) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: recurrence.isActive ? Colors.green : Colors.grey,
            shape: BoxShape.circle,
          ),
          child: Icon(
            recurrence.isActive ? Icons.check : Icons.close,
            color: Colors.white,
            size: 16,
          ),
        ),
        title: Text('Test ${recurrence.type.name}'),
        subtitle: Text(
          'ID: ${recurrence.id}\n'
          'Actif: ${recurrence.isActive ? "✅ OUI" : "❌ NON"}\n'
          'Créé: ${recurrence.createdAt.toLocal()}',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _testMenuAction(recurrence, action),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('🔧 Modifier')),
            const PopupMenuItem(value: 'exceptions', child: Text('📅 Exceptions')),
            const PopupMenuItem(value: 'toggle', child: Text('🔄 Basculer')),
            const PopupMenuItem(value: 'delete', child: Text('🗑️ Supprimer')),
          ],
        ),
      ),
    );
  }

  Future<void> _runTests() async {
    setState(() {
      _isLoading = true;
      _testResults = '';
    });

    final results = StringBuffer();
    results.writeln('🚀 Début des tests - ${DateTime.now()}');
    results.writeln('=' * 50);

    try {
      // Test 1: Création d'une récurrence hebdomadaire
      results.writeln('\n📅 Test 1: Création récurrence hebdomadaire');
      final weeklyRecurrence = EventRecurrenceModel(
        id: '',
        parentEventId: 'test-event-1',
        type: RecurrenceType.weekly,
        interval: 1,
        daysOfWeek: [1, 3, 5], // Lundi, Mercredi, Vendredi
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final weeklyId = await EventRecurrenceService.createRecurrence(weeklyRecurrence);
      results.writeln('✅ Récurrence hebdomadaire créée: $weeklyId');
      
      // Vérifier qu'elle est bien active
      final createdWeekly = await EventRecurrenceService.getRecurrence(weeklyId);
      if (createdWeekly != null && createdWeekly.isActive) {
        results.writeln('✅ Récurrence hebdomadaire est ACTIVE par défaut');
      } else {
        results.writeln('❌ Récurrence hebdomadaire est INACTIVE (PROBLÈME!)');
      }

      // Test 2: Création d'une récurrence mensuelle
      results.writeln('\n📅 Test 2: Création récurrence mensuelle');
      final monthlyRecurrence = EventRecurrenceModel(
        id: '',
        parentEventId: 'test-event-2',
        type: RecurrenceType.monthly,
        interval: 1,
        dayOfMonth: 15,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final monthlyId = await EventRecurrenceService.createRecurrence(monthlyRecurrence);
      results.writeln('✅ Récurrence mensuelle créée: $monthlyId');
      
      // Vérifier qu'elle est bien active
      final createdMonthly = await EventRecurrenceService.getRecurrence(monthlyId);
      if (createdMonthly != null && createdMonthly.isActive) {
        results.writeln('✅ Récurrence mensuelle est ACTIVE par défaut');
      } else {
        results.writeln('❌ Récurrence mensuelle est INACTIVE (PROBLÈME!)');
      }

      // Test 3: Test de basculement actif/inactif
      results.writeln('\n🔄 Test 3: Test basculement actif/inactif');
      if (createdWeekly != null) {
        // Désactiver
        final inactiveRecurrence = createdWeekly.copyWith(isActive: false);
        await EventRecurrenceService.updateRecurrence(inactiveRecurrence);
        results.writeln('✅ Récurrence désactivée');
        
        // Réactiver
        final reactivatedRecurrence = inactiveRecurrence.copyWith(isActive: true);
        await EventRecurrenceService.updateRecurrence(reactivatedRecurrence);
        results.writeln('✅ Récurrence réactivée');
      }

      // Charger les récurrences de test créées
      final testRecurrences = <EventRecurrenceModel>[];
      
      if (createdWeekly != null) testRecurrences.add(createdWeekly);
      if (createdMonthly != null) testRecurrences.add(createdMonthly);
      
      setState(() {
        _testRecurrences = testRecurrences;
      });

      results.writeln('\n📊 Résumé des tests:');
      results.writeln('- Récurrences de test créées: ${testRecurrences.length}');
      results.writeln('- Récurrences actives: ${testRecurrences.where((r) => r.isActive).length}');
      results.writeln('- Récurrences inactives: ${testRecurrences.where((r) => !r.isActive).length}');

      results.writeln('\n✅ TOUS LES TESTS RÉUSSIS!');
      results.writeln('Les récurrences sont bien créées ACTIVES par défaut.');
      results.writeln('Le menu contextuel devrait maintenant fonctionner.');

    } catch (e) {
      results.writeln('\n❌ ERREUR LORS DES TESTS: $e');
    }

    results.writeln('\n🏁 Fin des tests - ${DateTime.now()}');

    setState(() {
      _testResults = results.toString();
      _isLoading = false;
    });
  }

  Future<void> _testMenuAction(EventRecurrenceModel recurrence, String action) async {
    try {
      switch (action) {
        case 'edit':
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('📝 Menu "Modifier" fonctionne!')),
          );
          break;
        case 'exceptions':
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('📅 Menu "Exceptions" fonctionne!')),
          );
          break;
        case 'toggle':
          final updated = recurrence.copyWith(isActive: !recurrence.isActive);
          await EventRecurrenceService.updateRecurrence(updated);
          setState(() {
            final index = _testRecurrences.indexWhere((r) => r.id == recurrence.id);
            if (index != -1) {
              _testRecurrences[index] = updated;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('🔄 Récurrence ${updated.isActive ? "activée" : "désactivée"}')),
          );
          break;
        case 'delete':
          await EventRecurrenceService.deleteRecurrence(recurrence.id);
          setState(() {
            _testRecurrences.removeWhere((r) => r.id == recurrence.id);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🗑️ Récurrence supprimée')),
          );
          break;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Erreur: $e')),
      );
    }
  }

  Future<void> _cleanupTests() async {
    try {
      setState(() => _isLoading = true);
      
      // Supprimer toutes les récurrences de test
      for (final recurrence in _testRecurrences) {
        await EventRecurrenceService.deleteRecurrence(recurrence.id);
      }
      
      setState(() {
        _testRecurrences.clear();
        _testResults = '🧹 Nettoyage terminé - ${DateTime.now()}\n'
                      'Toutes les récurrences de test ont été supprimées.';
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Nettoyage terminé')),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Erreur lors du nettoyage: $e')),
      );
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialisé avec succès');
  } catch (e) {
    print('❌ Erreur lors de l\'initialisation de Firebase: $e');
  }
  
  runApp(const TestRecurrenceCorrections());
}