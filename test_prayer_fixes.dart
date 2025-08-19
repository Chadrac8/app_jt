import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'lib/services/prayers_firebase_service.dart';
import 'lib/models/prayer_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  print('=== Test des corrections du module Mur de prière ===\n');
  
  await testPrayerService();
}

Future<void> testPrayerService() async {
  try {
    print('1. Test du stream simplifié des prières...');
    
    // Test du stream simplifié
    final simpleStream = PrayersFirebaseService.getSimplePrayersStream(limit: 10);
    
    await for (final prayers in simpleStream.take(1)) {
      print('   ✅ Stream simplifié: ${prayers.length} prières récupérées');
      break;
    }
    
    print('\n2. Test de récupération des catégories...');
    
    // Test des catégories
    final categories = await PrayersFirebaseService.getCategories();
    print('   ✅ Catégories trouvées: ${categories.length}');
    for (final category in categories.take(5)) {
      print('      - $category');
    }
    
    print('\n3. Test du stream avec filtres...');
    
    // Test du stream avec filtres
    final filteredStream = PrayersFirebaseService.getPrayersStream(
      approvedOnly: true,
      activeOnly: true,
      limit: 5,
    );
    
    await for (final prayers in filteredStream.take(1)) {
      print('   ✅ Stream avec filtres: ${prayers.length} prières récupérées');
      if (prayers.isNotEmpty) {
        final prayer = prayers.first;
        print('      Exemple: "${prayer.title}" (${prayer.category})');
      }
      break;
    }
    
    print('\n4. Test de recherche...');
    
    // Test de recherche
    final searchResults = await PrayersFirebaseService.searchPrayers('famille');
    print('   ✅ Recherche "famille": ${searchResults.length} résultats');
    
    print('\n🎉 Tous les tests sont passés avec succès !');
    print('Les corrections d\'index Firebase sont fonctionnelles.');
    
  } catch (e) {
    print('❌ Erreur lors des tests: $e');
  }
}
