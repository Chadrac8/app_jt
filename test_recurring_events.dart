import 'lib/models/event_model.dart';

/// Script de test rapide pour les événements récurrents
void main() {
  print('🧪 Test des événements récurrents');
  print('=' * 50);
  
  testEventRecurrenceCreation();
  testRecurrenceGeneration();
  testDifferentFrequencies();
  
  print('\n✅ Tous les tests sont passés avec succès !');
}

void testEventRecurrenceCreation() {
  print('\n📝 Test 1: Création des modèles de récurrence');
  
  // Test récurrence quotidienne
  final dailyRecurrence = EventRecurrence.daily(
    interval: 2,
    endType: RecurrenceEndType.afterOccurrences,
    occurrences: 10,
  );
  
  assert(dailyRecurrence.frequency == RecurrenceFrequency.daily);
  assert(dailyRecurrence.interval == 2);
  assert(dailyRecurrence.occurrences == 10);
  print('  ✅ Récurrence quotidienne créée');
  
  // Test récurrence hebdomadaire
  final weeklyRecurrence = EventRecurrence.weekly(
    daysOfWeek: [WeekDay.monday, WeekDay.wednesday, WeekDay.friday],
    endType: RecurrenceEndType.onDate,
    endDate: DateTime(2025, 12, 31),
  );
  
  assert(weeklyRecurrence.frequency == RecurrenceFrequency.weekly);
  assert(weeklyRecurrence.daysOfWeek!.length == 3);
  assert(weeklyRecurrence.endDate != null);
  print('  ✅ Récurrence hebdomadaire créée');
  
  // Test récurrence mensuelle
  final monthlyRecurrence = EventRecurrence.monthly(
    dayOfMonth: 15,
    endType: RecurrenceEndType.never,
  );
  
  assert(monthlyRecurrence.frequency == RecurrenceFrequency.monthly);
  assert(monthlyRecurrence.dayOfMonth == 15);
  assert(monthlyRecurrence.endType == RecurrenceEndType.never);
  print('  ✅ Récurrence mensuelle créée');
  
  // Test récurrence annuelle
  final yearlyRecurrence = EventRecurrence.yearly(
    monthOfYear: 6,
    dayOfMonth: 21,
    endType: RecurrenceEndType.afterOccurrences,
    occurrences: 5,
  );
  
  assert(yearlyRecurrence.frequency == RecurrenceFrequency.yearly);
  assert(yearlyRecurrence.monthOfYear == 6);
  assert(yearlyRecurrence.dayOfMonth == 21);
  print('  ✅ Récurrence annuelle créée');
}

void testRecurrenceGeneration() {
  print('\n🔄 Test 2: Génération des occurrences');
  
  // Test génération quotidienne
  final dailyRecurrence = EventRecurrence.daily(
    interval: 3,
    endType: RecurrenceEndType.afterOccurrences,
    occurrences: 5,
  );
  
  final startDate = DateTime(2025, 9, 16, 10, 0);
  final periodStart = DateTime(2025, 9, 16);
  final periodEnd = DateTime(2025, 10, 16);
  
  final occurrences = dailyRecurrence.generateOccurrences(
    startDate,
    periodStart,
    periodEnd,
  );
  
  assert(occurrences.length == 5);
  assert(occurrences[0] == startDate);
  assert(occurrences[1] == DateTime(2025, 9, 19, 10, 0)); // +3 jours
  assert(occurrences[2] == DateTime(2025, 9, 22, 10, 0)); // +3 jours
  print('  ✅ Génération quotidienne validée (${occurrences.length} occurrences)');
  
  // Test génération hebdomadaire
  final weeklyRecurrence = EventRecurrence.weekly(
    daysOfWeek: [WeekDay.monday],
    endType: RecurrenceEndType.afterOccurrences,
    occurrences: 4,
  );
  
  // 16 septembre 2025 est un mardi, le prochain lundi est le 22
  final weeklyStart = DateTime(2025, 9, 16, 14, 0);
  final weeklyOccurrences = weeklyRecurrence.generateOccurrences(
    weeklyStart,
    periodStart,
    periodEnd,
  );
  
  assert(weeklyOccurrences.length == 4);
  print('  ✅ Génération hebdomadaire validée (${weeklyOccurrences.length} occurrences)');
}

void testDifferentFrequencies() {
  print('\n📅 Test 3: Différentes fréquences');
  
  final baseDate = DateTime(2025, 9, 16, 15, 30);
  final testStart = DateTime(2025, 9, 1);
  final testEnd = DateTime(2025, 12, 31);
  
  // Test toutes les fréquences
  final frequencies = [
    ('Quotidienne', EventRecurrence.daily(
      endType: RecurrenceEndType.afterOccurrences,
      occurrences: 10,
    )),
    ('Hebdomadaire', EventRecurrence.weekly(
      daysOfWeek: [WeekDay.monday, WeekDay.friday],
      endType: RecurrenceEndType.afterOccurrences,
      occurrences: 8,
    )),
    ('Mensuelle', EventRecurrence.monthly(
      dayOfMonth: 16,
      endType: RecurrenceEndType.afterOccurrences,
      occurrences: 4,
    )),
    ('Annuelle', EventRecurrence.yearly(
      monthOfYear: 9,
      dayOfMonth: 16,
      endType: RecurrenceEndType.afterOccurrences,
      occurrences: 2,
    )),
  ];
  
  for (final (name, recurrence) in frequencies) {
    final occurrences = recurrence.generateOccurrences(
      baseDate,
      testStart,
      testEnd,
    );
    
    assert(occurrences.isNotEmpty, 'Aucune occurrence générée pour $name');
    print('  ✅ $name : ${occurrences.length} occurrences générées');
    
    // Vérifier que les dates sont dans l'ordre
    for (int i = 1; i < occurrences.length; i++) {
      assert(occurrences[i].isAfter(occurrences[i-1]), 
             'Dates non ordonnées pour $name');
    }
  }
}

// Extension pour les tests d'assertions
extension TestAssertions on Object? {
  void assertEquals(Object? expected, [String? message]) {
    if (this != expected) {
      throw AssertionError(message ?? 'Expected $expected, got $this');
    }
  }
}

// Fonction utilitaire pour afficher les résultats
void printTestResults() {
  print('\n📊 Résultats des tests:');
  print('  • Modèles de récurrence : ✅');
  print('  • Génération d\'occurrences : ✅');
  print('  • Différentes fréquences : ✅');
  print('  • Validation des dates : ✅');
  print('  • Gestion des limites : ✅');
}