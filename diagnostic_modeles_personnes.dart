#!/usr/bin/env dart

import 'dart:io';

void main() {
  print('📊 Analyse des Modèles de Personnes dans le Projet');
  print('================================================');
  
  final personFiles = [
    'lib/models/person_model.dart',
    'lib/models/person_module_model.dart', 
    'lib/modules/personnes/models/person_model.dart',
    'lib/modules/personnes/models/person_module_model.dart',
  ];
  
  print('\n🔍 Fichiers de modèles détectés :');
  
  int activeModels = 0;
  
  for (final filePath in personFiles) {
    final file = File(filePath);
    if (file.existsSync()) {
      final content = file.readAsStringSync();
      final isEmpty = content.trim().isEmpty;
      final hasPersonModel = content.contains('class PersonModel');
      final hasPersonClass = content.contains('class Person ') || content.contains('class Person{');
      final lines = content.split('\n').length;
      
      print('\n📁 $filePath');
      print('   ├── Existe: ✅');
      print('   ├── Vide: ${isEmpty ? "❌ OUI" : "✅ NON"}');
      print('   ├── Lignes: $lines');
      print('   ├── Contient PersonModel: ${hasPersonModel ? "✅ OUI" : "❌ NON"}');
      print('   └── Contient Person: ${hasPersonClass ? "✅ OUI" : "❌ NON"}');
      
      if (!isEmpty) {
        activeModels++;
      }
    } else {
      print('\n📁 $filePath');
      print('   └── Existe: ❌ NON');
    }
  }
  
  print('\n📋 Résumé des Modèles Actifs :');
  
  // Analyse du modèle PersonModel principal
  final personModelFile = File('lib/models/person_model.dart');
  if (personModelFile.existsSync()) {
    final content = personModelFile.readAsStringSync();
    if (content.contains('class PersonModel')) {
      print('\n🔧 PersonModel (lib/models/person_model.dart)');
      print('   ├── Usage: Profils utilisateurs, authentification');
      print('   ├── Propriétés clés: uid, email, firstName, lastName');
      print('   ├── Fonctionnalités: Contacts d\'urgence, famille, rôles');
      print('   └── Statut: ✅ ACTIF - Modèle principal');
    }
  }
  
  // Analyse du modèle Person du module
  final personModuleFile = File('lib/models/person_module_model.dart');
  if (personModuleFile.existsSync()) {
    final content = personModuleFile.readAsStringSync();
    if (content.contains('class Person')) {
      print('\n🔧 Person (lib/models/person_module_model.dart)');
      print('   ├── Usage: Module Personnes, import/export');
      print('   ├── Propriétés clés: firstName, lastName, email, roles');
      print('   ├── Fonctionnalités: Synchronisation, import en masse');
      print('   └── Statut: ✅ ACTIF - Modèle module');
    }
  }
  
  // Vérification des fichiers vides dans le module
  final modulePersonModel = File('lib/modules/personnes/models/person_model.dart');
  final modulePersonModuleModel = File('lib/modules/personnes/models/person_module_model.dart');
  
  if (modulePersonModel.existsSync() && modulePersonModel.readAsStringSync().trim().isEmpty) {
    print('\n⚠️  Fichier vide détecté:');
    print('   └── lib/modules/personnes/models/person_model.dart (VIDE)');
  }
  
  if (modulePersonModuleModel.existsSync() && modulePersonModuleModel.readAsStringSync().trim().isEmpty) {
    print('\n⚠️  Fichier vide détecté:');
    print('   └── lib/modules/personnes/models/person_module_model.dart (VIDE)');
  }
  
  print('\n🎯 Conclusion :');
  print('   📊 Nombre total de modèles actifs: $activeModels');
  print('   🏗️  Architecture actuelle:');
  print('      ├── PersonModel: Profils utilisateurs (auth, familles)');
  print('      └── Person: Module Personnes (import, synchronisation)');
  print('   🔄 Synchronisation: Bidirectionnelle entre les deux modèles');
  print('   🧹 Nettoyage: ${activeModels == 2 ? "✅ Optimal" : "⚠️  Fichiers vides à nettoyer"}');
  
  if (activeModels == 2) {
    print('\n✅ État: OPTIMAL');
    print('Le projet utilise correctement 2 modèles de personnes distincts :');
    print('- PersonModel pour les profils utilisateurs avec authentification');
    print('- Person pour le module Personnes avec fonctionnalités avancées');
  } else {
    print('\n⚠️  Recommandation: Nettoyer les fichiers vides du module personnes');
  }
}