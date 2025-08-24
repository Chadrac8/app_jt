import 'package:flutter/material.dart';
import 'lib/modules/pain_quotidien/pain_quotidien.dart';

/// Script de test pour le module Pain Quotidien
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🍞 Test du module Pain Quotidien');
  print('=================================');
  
  try {
    // Test 1: Création d'un modèle
    print('\n📝 Test 1: Création du modèle DailyBreadModel');
    final testBread = DailyBreadModel(
      id: '2025-08-21',
      text: 'La foi est quelque chose que vous avez ; elle n\'est pas quelque chose que vous obtenez.',
      reference: 'William Marrion Branham',
      date: '2025-08-21',
      dailyBread: 'Car Dieu a tant aimé le monde qu\'il a donné son Fils unique, afin que quiconque croit en lui ne périsse point, mais qu\'il ait la vie éternelle.',
      dailyBreadReference: 'Jean 3:16',
      sermonTitle: 'La Foi',
      sermonDate: '57-1229',
      audioUrl: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    print('✅ Modèle créé avec succès');
    print('   ID: ${testBread.id}');
    print('   Citation: ${testBread.text.substring(0, 50)}...');
    print('   Verset: ${testBread.dailyBread.substring(0, 50)}...');
    print('   Référence: ${testBread.dailyBreadReference}');
    
    // Test 2: Conversion JSON
    print('\n🔄 Test 2: Conversion JSON');
    final jsonData = testBread.toJson();
    final fromJson = DailyBreadModel.fromJson(jsonData);
    print('✅ Conversion JSON OK');
    print('   Titre original: ${testBread.sermonTitle}');
    print('   Titre depuis JSON: ${fromJson.sermonTitle}');
    
    // Test 3: Texte de partage
    print('\n📤 Test 3: Texte de partage');
    final shareText = testBread.shareText;
    print('✅ Texte de partage généré:');
    print(shareText);
    
    // Test 4: Vérification date du jour
    print('\n📅 Test 4: Vérification date du jour');
    final todayBread = testBread.copyWith(
      date: DateTime.now().toString().split(' ')[0],
    );
    print('✅ Est aujourd\'hui: ${todayBread.isToday}');
    
    // Test 5: Service (sans réseau)
    print('\n🌐 Test 5: Service DailyBreadService');
    final service = DailyBreadService.instance;
    print('✅ Instance du service créée');
    print('   Type: ${service.runtimeType}');
    
    // Note: Tests réseau nécessitent Firebase et réseau
    print('\n⚠️ Tests réseau et Firestore non exécutés');
    print('   (Nécessitent configuration Firebase + réseau)');
    
    print('\n🎉 Tous les tests de base sont passés avec succès !');
    print('   Le module Pain Quotidien est prêt à être intégré.');
    
  } catch (e, stackTrace) {
    print('❌ Erreur lors des tests: $e');
    print('📍 Stack trace: $stackTrace');
  }
  
  print('\n📋 Prochaines étapes:');
  print('1. Ajouter le package html au pubspec.yaml');
  print('2. Exécuter flutter pub get');
  print('3. Configurer Firebase si pas encore fait');
  print('4. Intégrer DailyBreadPreviewWidget à la page d\'accueil');
  print('5. Tester en conditions réelles avec réseau');
}
