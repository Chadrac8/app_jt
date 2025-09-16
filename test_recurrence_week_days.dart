import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'lib/firebase_options.dart';
import 'lib/models/event_model.dart';
import 'lib/models/event_recurrence_model.dart';
import 'lib/theme.dart';

/// Programme de test pour vérifier la récurrence avec jours de la semaine
class TestRecurrenceWeekDays extends StatelessWidget {
  const TestRecurrenceWeekDays({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test - Récurrence Jours Semaine',
      theme: AppTheme.lightTheme,
      home: const TestRecurrencePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TestRecurrencePage extends StatefulWidget {
  const TestRecurrencePage({Key? key}) : super(key: key);

  @override
  State<TestRecurrencePage> createState() => _TestRecurrencePageState();
}

class _TestRecurrencePageState extends State<TestRecurrencePage> {
  final List<Map<String, dynamic>> _testResults = [];

  @override
  void initState() {
    super.initState();
    _runTests();
  }

  void _runTests() {
    setState(() {
      _testResults.clear();
    });

    // Test 1: Récurrence hebdomadaire - Tous les lundis et mercredis
    _testWeeklyRecurrence([1, 3], 'Tous les lundis et mercredis');

    // Test 2: Récurrence hebdomadaire - Tous les vendredi
    _testWeeklyRecurrence([5], 'Tous les vendredis');

    // Test 3: Récurrence hebdomadaire - Week-end (samedi et dimanche)
    _testWeeklyRecurrence([6, 7], 'Tous les week-ends (samedi et dimanche)');

    // Test 4: Récurrence hebdomadaire - Jours de travail
    _testWeeklyRecurrence([1, 2, 3, 4, 5], 'Tous les jours de travail (lundi à vendredi)');
  }

  void _testWeeklyRecurrence(List<int> daysOfWeek, String description) {
    try {
      // Créer un EventRecurrenceModel
      final recurrenceModel = EventRecurrenceModel(
        id: 'test-${DateTime.now().millisecondsSinceEpoch}',
        parentEventId: 'parent-event',
        type: RecurrenceType.weekly,
        interval: 1,
        daysOfWeek: daysOfWeek,
        dayOfMonth: null,
        monthsOfYear: null,
        endDate: null,
        occurrenceCount: null,
        exceptions: [],
        overrides: [],
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Convertir vers EventRecurrence
      final eventRecurrence = EventRecurrence.fromEventRecurrenceModel(recurrenceModel);

      // Générer quelques occurrences pour tester
      final startDate = DateTime(2025, 1, 6); // Lundi 6 janvier 2025
      final endDate = DateTime(2025, 1, 20);  // 2 semaines plus tard
      final occurrences = eventRecurrence.generateOccurrences(startDate, startDate, endDate);

      // Vérifier que les jours de la semaine correspondent
      final expectedWeekdays = daysOfWeek.map((day) => WeekDay.values[day - 1]).toList();
      final actualWeekdays = occurrences.map((date) => WeekDay.values[date.weekday - 1]).toSet();
      
      bool allDaysMatch = true;
      for (final occurrence in occurrences) {
        final weekday = WeekDay.values[occurrence.weekday - 1];
        if (!expectedWeekdays.contains(weekday)) {
          allDaysMatch = false;
          break;
        }
      }

      _testResults.add({
        'test': description,
        'status': allDaysMatch ? 'PASS' : 'FAIL',
        'details': {
          'daysOfWeekInput': daysOfWeek,
          'expectedWeekdays': expectedWeekdays.map((d) => d.toString().split('.').last).toList(),
          'actualWeekdays': actualWeekdays.map((d) => d.toString().split('.').last).toList(),
          'occurrences': occurrences.length,
          'occurrenceDates': occurrences.map((d) => '${d.day}/${d.month} (${_weekDayName(d.weekday)})').toList(),
        },
        'conversion': {
          'originalModel': 'daysOfWeek: $daysOfWeek',
          'convertedRecurrence': 'daysOfWeek: ${eventRecurrence.daysOfWeek?.map((d) => d.toString().split('.').last).toList()}',
          'description': eventRecurrence.description,
        }
      });

    } catch (e) {
      _testResults.add({
        'test': description,
        'status': 'ERROR',
        'error': e.toString(),
      });
    }

    setState(() {});
  }

  String _weekDayName(int weekday) {
    const names = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return names[weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test - Récurrence Jours Semaine'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _runTests,
            tooltip: 'Relancer les tests',
          ),
        ],
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
                      '🧪 Test de Récurrence - Jours de la Semaine',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ce test vérifie que la conversion entre EventRecurrenceModel et EventRecurrence '
                      'préserve correctement les jours de la semaine et génère les bonnes occurrences.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Résultats des tests: ${_testResults.length}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            if (_testResults.isEmpty)
              const Center(
                child: CircularProgressIndicator(),
              )
            else
              ..._testResults.map((result) => _buildTestResult(result)),
          ],
        ),
      ),
    );
  }

  Widget _buildTestResult(Map<String, dynamic> result) {
    final status = result['status'] as String;
    final isPass = status == 'PASS';
    final isError = status == 'ERROR';
    
    Color statusColor;
    IconData statusIcon;
    
    if (isPass) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (isError) {
      statusColor = Colors.red;
      statusIcon = Icons.error;
    } else {
      statusColor = Colors.orange;
      statusIcon = Icons.warning;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result['test'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            if (isError)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    'Erreur: ${result['error']}',
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              ),
            
            if (!isError && result['details'] != null) ...[
              const SizedBox(height: 12),
              _buildDetailSection('Conversion', result['conversion']),
              const SizedBox(height: 8),
              _buildDetailSection('Détails', result['details']),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, Map<String, dynamic> details) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          ...details.entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '${entry.key}: ${entry.value}',
              style: const TextStyle(fontSize: 12),
            ),
          )),
        ],
      ),
    );
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
  
  runApp(const TestRecurrenceWeekDays());
}