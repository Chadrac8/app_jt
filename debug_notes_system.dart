#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';

/// Script de débogage pour vérifier le système de notes de la Bible
void main() async {
  print('🔍 Analyse du système de notes et surlignements de la Bible...\n');
  
  // Vérifier le fichier BiblePage
  await checkBiblePageStructure();
  
  // Vérifier les SharedPreferences
  await checkSharedPreferences();
  
  print('\n✅ Analyse terminée !');
}

Future<void> checkBiblePageStructure() async {
  print('📄 Vérification de la structure du fichier bible_page.dart...');
  
  final biblePageFile = File('lib/modules/bible/bible_page.dart');
  if (!await biblePageFile.exists()) {
    print('❌ Le fichier bible_page.dart n\'existe pas !');
    return;
  }
  
  final content = await biblePageFile.readAsString();
  
  // Vérifier les méthodes importantes
  final checkpoints = {
    '_toggleFavorite': content.contains('void _toggleFavorite(BibleVerse v)'),
    '_toggleHighlight': content.contains('void _toggleHighlight(BibleVerse v)'),
    '_editNoteDialog': content.contains('void _editNoteDialog(BibleVerse v)'),
    '_loadPrefs': content.contains('_loadPrefs()'),
    '_savePrefs': content.contains('_savePrefs()'),
    '_buildNotesAndHighlightsTab': content.contains('Widget _buildNotesAndHighlightsTab()'),
    '_showFirstTimeHint': content.contains('void _showFirstTimeHint()'),
    'SharedPreferences': content.contains('import \'package:shared_preferences/shared_preferences.dart\''),
  };
  
  checkpoints.forEach((method, exists) {
    print(exists ? '✅ $method trouvé' : '❌ $method manquant');
  });
  
  // Vérifier les variables d'état
  final stateVariables = {
    '_notes': content.contains('Map<String, String> _notes'),
    '_highlights': content.contains('Set<String> _highlights'),
    '_favorites': content.contains('Set<String> _favorites'),
    '_selectedVerseKey': content.contains('String? _selectedVerseKey'),
  };
  
  print('\n📊 Variables d\'état :');
  stateVariables.forEach((variable, exists) {
    print(exists ? '✅ $variable déclaré' : '❌ $variable manquant');
  });
}

Future<void> checkSharedPreferences() async {
  print('\n💾 Vérification des SharedPreferences...');
  
  // Vérifier que le package est dans pubspec.yaml
  final pubspecFile = File('pubspec.yaml');
  if (await pubspecFile.exists()) {
    final pubspecContent = await pubspecFile.readAsString();
    final hasSharedPrefs = pubspecContent.contains('shared_preferences:');
    print(hasSharedPrefs 
        ? '✅ Package shared_preferences trouvé dans pubspec.yaml' 
        : '❌ Package shared_preferences manquant dans pubspec.yaml');
  }
  
  print('\n🔧 Conseils de débogage :');
  print('• Ajoutez des print() dans _loadPrefs() pour voir si les données sont chargées');
  print('• Vérifiez que _loadPrefs() est appelé dans initState()');
  print('• Testez _savePrefs() après chaque action (note, favori, surlignement)');
  print('• Regardez les logs de debug dans _buildNotesAndHighlightsTab()');
  
  print('\n📱 Pour tester l\'application :');
  print('1. Allez dans l\'onglet Lecture');
  print('2. Tapez sur un verset');
  print('3. Ajoutez une note, un favori ou un surlignement');
  print('4. Vérifiez l\'onglet Notes');
  print('5. Regardez les logs de debug dans la console');
}