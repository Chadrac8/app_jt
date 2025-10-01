#!/usr/bin/env dart

/// Test unitaire simple pour vérifier le système de persistance des surlignements
/// Ce test simule les opérations sans interface graphique

import 'dart:convert';

void main() async {
  print('🧪 Test Unitaire - Système de Persistance des Surlignements\n');
  
  // Test 1: Simulation de la méthode _verseKey
  testVerseKeyGeneration();
  
  // Test 2: Simulation de la sauvegarde JSON
  testJsonSerialization();
  
  // Test 3: Simulation de la logique de toggle
  testToggleLogic();
  
  // Test 4: Test de la cohérence des clés
  testKeyConsistency();
  
  print('\n✅ Tous les tests sont terminés !');
}

void testVerseKeyGeneration() {
  print('📝 Test 1: Génération des clés de versets');
  
  // Simuler la méthode _verseKey(BibleVerse v) => '${v.book}_${v.chapter}_${v.verse}';
  final testCases = [
    {'book': 'Genesis', 'chapter': 1, 'verse': 1, 'expected': 'Genesis_1_1'},
    {'book': 'Psalms', 'chapter': 23, 'verse': 4, 'expected': 'Psalms_23_4'},
    {'book': 'John', 'chapter': 3, 'verse': 16, 'expected': 'John_3_16'},
  ];
  
  for (final test in testCases) {
    final key = '${test['book']}_${test['chapter']}_${test['verse']}';
    final expected = test['expected'];
    final passed = key == expected;
    print(passed ? '✅ $key' : '❌ $key (attendu: $expected)');
  }
}

void testJsonSerialization() {
  print('\n💾 Test 2: Sérialisation JSON');
  
  // Test de la sauvegarde des highlights (Set<String> -> List<String> -> JSON)
  final highlights = <String>{'Genesis_1_1', 'John_3_16', 'Psalms_23_4'};
  final highlightsList = highlights.toList();
  final highlightsJson = jsonEncode(highlightsList);
  print('✅ Highlights JSON: $highlightsJson');
  
  // Test de la restauration (JSON -> List<String> -> Set<String>)
  final restoredList = List<String>.from(jsonDecode(highlightsJson));
  final restoredSet = restoredList.toSet();
  final roundTripSuccess = highlights.length == restoredSet.length && 
                           highlights.every((item) => restoredSet.contains(item));
  print(roundTripSuccess ? '✅ Round-trip JSON réussi' : '❌ Round-trip JSON échoué');
  
  // Test des notes (Map<String, String> -> JSON)
  final notes = <String, String>{
    'Genesis_1_1': 'Au commencement était la Parole',
    'John_3_16': 'Car Dieu a tant aimé le monde',
  };
  final notesJson = jsonEncode(notes);
  print('✅ Notes JSON: $notesJson');
  
  final restoredNotes = Map<String, String>.from(jsonDecode(notesJson));
  final notesRoundTripSuccess = notes.length == restoredNotes.length &&
                                notes.keys.every((key) => restoredNotes[key] == notes[key]);
  print(notesRoundTripSuccess ? '✅ Notes round-trip réussi' : '❌ Notes round-trip échoué');
}

void testToggleLogic() {
  print('\n🔄 Test 3: Logique de Toggle');
  
  var highlights = <String>{};
  final verseKey = 'Genesis_1_1';
  
  // Premier toggle : ajouter
  if (highlights.contains(verseKey)) {
    highlights.remove(verseKey);
    print('❌ Erreur: le verset ne devrait pas être déjà présent');
  } else {
    highlights.add(verseKey);
    print('✅ Verset ajouté aux surlignements');
  }
  
  print('   Total surlignements: ${highlights.length}');
  print('   Contenu: ${highlights.toList()}');
  
  // Deuxième toggle : retirer
  if (highlights.contains(verseKey)) {
    highlights.remove(verseKey);
    print('✅ Verset retiré des surlignements');
  } else {
    highlights.add(verseKey);
    print('❌ Erreur: le verset devrait être présent');
  }
  
  print('   Total surlignements: ${highlights.length}');
  print('   Contenu: ${highlights.toList()}');
}

void testKeyConsistency() {
  print('\n🔑 Test 4: Cohérence des Clés');
  
  // Simuler différentes façons de générer la même clé
  final book = 'Genesis';
  final chapter = 1;
  final verse = 1;
  
  final key1 = '${book}_${chapter}_${verse}';
  final key2 = 'Genesis_1_1';
  final key3 = '$book' + '_' + '$chapter' + '_' + '$verse';
  
  final allSame = key1 == key2 && key2 == key3;
  print(allSame ? '✅ Toutes les méthodes génèrent la même clé: $key1' : '❌ Incohérence dans la génération des clés');
  
  // Test avec des caractères spéciaux
  final bookWithSpaces = 'Song of Songs';
  final keyWithSpaces = '${bookWithSpaces}_${chapter}_${verse}';
  print('✅ Clé avec espaces: $keyWithSpaces');
  
  // Test que les clés sont bien uniques
  final keys = <String>{};
  for (int c = 1; c <= 3; c++) {
    for (int v = 1; v <= 5; v++) {
      keys.add('Genesis_${c}_$v');
    }
  }
  
  final expectedCount = 3 * 5; // 3 chapitres × 5 versets
  final actualCount = keys.length;
  print(actualCount == expectedCount 
    ? '✅ Unicité des clés vérifiée ($actualCount clés uniques)'
    : '❌ Problème d\'unicité: $actualCount au lieu de $expectedCount');
}