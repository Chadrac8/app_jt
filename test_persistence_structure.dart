#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';

/// Test de vérification du système de persistance des surlignements
void main() async {
  print('🔍 Vérification du système de persistance - Surlignements\n');
  
  // 1. Vérifier la structure des méthodes de toggle
  await checkToggleMethods();
  
  // 2. Vérifier la sauvegarde
  await checkSaveMethods();
  
  // 3. Vérifier le chargement
  await checkLoadMethods();
  
  // 4. Vérifier les listeners d'onglets
  await checkTabListeners();
  
  print('\n✅ Analyse terminée !');
}

Future<void> checkToggleMethods() async {
  print('📝 Vérification des méthodes de toggle...');
  
  final biblePageFile = File('lib/modules/bible/bible_page.dart');
  final content = await biblePageFile.readAsString();
  
  final checks = {
    'async _toggleHighlight': content.contains('void _toggleHighlight(BibleVerse v) async'),
    'async _toggleFavorite': content.contains('void _toggleFavorite(BibleVerse v) async'),
    'DEBUG toggle logging': content.contains('DEBUG _toggleHighlight:'),
    'immediate save': content.contains('await _savePrefs();'),
    'SharedPreferences verification': content.contains('final saved = prefs.getStringList'),
  };
  
  checks.forEach((check, passed) {
    print(passed ? '✅ $check' : '❌ $check');
  });
}

Future<void> checkSaveMethods() async {
  print('\n💾 Vérification des méthodes de sauvegarde...');
  
  final biblePageFile = File('lib/modules/bible/bible_page.dart');
  final content = await biblePageFile.readAsString();
  
  final checks = {
    'DEBUG save logging': content.contains('DEBUG: Sauvegarde des préférences...'),
    'highlights save': content.contains("prefs.setStringList('bible_highlights'"),
    'favorites save': content.contains("prefs.setStringList('bible_favorites'"),
    'notes save': content.contains("prefs.setString('bible_notes'"),
  };
  
  checks.forEach((check, passed) {
    print(passed ? '✅ $check' : '❌ $check');
  });
}

Future<void> checkLoadMethods() async {
  print('\n📥 Vérification des méthodes de chargement...');
  
  final biblePageFile = File('lib/modules/bible/bible_page.dart');
  final content = await biblePageFile.readAsString();
  
  final checks = {
    'DEBUG load logging': content.contains('DEBUG: Chargement des préférences...'),
    'highlights load': content.contains("prefs.getStringList('bible_highlights')"),
    'favorites load': content.contains("prefs.getStringList('bible_favorites')"),
    'notes load': content.contains("prefs.getString('bible_notes')"),
    'force reload method': content.contains('Future<void> _forceReloadPrefs()'),
  };
  
  checks.forEach((check, passed) {
    print(passed ? '✅ $check' : '❌ $check');
  });
}

Future<void> checkTabListeners() async {
  print('\n🔄 Vérification des listeners d\'onglets...');
  
  final biblePageFile = File('lib/modules/bible/bible_page.dart');
  final content = await biblePageFile.readAsString();
  
  final checks = {
    'tab controller listener': content.contains('_tabController.addListener'),
    'notes tab reload': content.contains('if (_tabController.index == 3)'),
    'reading tab reload': content.contains('if (_tabController.index == 0)'),
    'force reload call': content.contains('_forceReloadPrefs();'),
  };
  
  checks.forEach((check, passed) {
    print(passed ? '✅ $check' : '❌ $check');
  });
}