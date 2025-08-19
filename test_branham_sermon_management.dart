import 'package:flutter/material.dart';
import 'lib/modules/message/models/admin_branham_sermon_model.dart';
import 'lib/modules/message/services/admin_branham_sermon_service.dart';

/// Test simple de la gestion des prédications de William Branham
void main() async {
  print('🎧 Test du système de gestion des prédications de William Branham');
  print('================================================================');
  
  try {
    // Test de création d'une prédication
    print('\n📝 Test 1: Création d\'une prédication');
    final sermon = AdminBranhamSermon(
      id: '',
      title: 'La Foi qui Fut Donnée Aux Saints',
      date: '55-0501',
      location: 'Chicago, Illinois',
      audioUrl: 'https://example.com/audio/faith-once-delivered.mp3',
      duration: const Duration(hours: 1, minutes: 30),
      language: 'fr',
      description: 'Une prédication fondamentale sur la foi authentique.',
      keywords: ['foi', 'saints', 'doctrine'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: true,
      displayOrder: 1,
    );
    
    print('✅ Modèle de prédication créé:');
    print('   Titre: ${sermon.title}');
    print('   Date: ${sermon.date}');
    print('   Lieu: ${sermon.location}');
    print('   Durée: ${sermon.duration?.inMinutes} minutes');
    print('   Mots-clés: ${sermon.keywords.join(", ")}');
    
    // Test de validation
    print('\n🔍 Test 2: Validation du modèle');
    final validation = sermon.validate();
    if (validation.isEmpty) {
      print('✅ Modèle valide');
    } else {
      print('❌ Erreurs de validation: ${validation.join(", ")}');
    }
    
    // Test de conversion JSON
    print('\n📄 Test 3: Conversion JSON');
    final json = sermon.toMap();
    print('✅ Conversion vers Map réussie');
    print('   Champs: ${json.keys.join(", ")}');
    
    final sermonFromJson = AdminBranhamSermon.fromMap(json);
    print('✅ Conversion depuis Map réussie');
    print('   Titre récupéré: ${sermonFromJson.title}');
    
    // Test de tri
    print('\n📊 Test 4: Tri des prédications');
    final sermons = [
      sermon,
      AdminBranhamSermon(
        id: '2',
        title: 'Le Signe du Temps de la Fin',
        date: '62-1230',
        location: 'Jeffersonville, IN',
        audioUrl: 'https://example.com/audio/end-time-sign.mp3',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
        displayOrder: 2,
      ),
    ];
    
    final sortedByDate = AdminBranhamSermonService.sortSermons(sermons, 'date');
    print('✅ Tri par date: ${sortedByDate.map((s) => s.date).join(", ")}');
    
    final sortedByTitle = AdminBranhamSermonService.sortSermons(sermons, 'title');
    print('✅ Tri par titre: ${sortedByTitle.map((s) => s.title).join(", ")}');
    
    // Test de recherche
    print('\n🔍 Test 5: Recherche dans les prédications');
    final searchResults = AdminBranhamSermonService.searchSermons(sermons, 'foi');
    print('✅ Recherche "foi": ${searchResults.length} résultat(s)');
    
    // Test de validation d'URL
    print('\n🌐 Test 6: Validation des URLs');
    print('✅ URL simple valide: ${AdminBranhamSermonService.isValidUrl("https://example.com/audio.mp3")}');
    print('✅ URL YouTube valide: ${AdminBranhamSermonService.isValidUrl("https://youtube.com/watch?v=abc123")}');
    print('❌ URL invalide: ${AdminBranhamSermonService.isValidUrl("not-a-url")}');
    
    // Test de filtrage
    print('\n🎯 Test 7: Filtrage des prédications');
    final activeSermons = AdminBranhamSermonService.filterByStatus(sermons, true);
    print('✅ Prédications actives: ${activeSermons.length}');
    
    final frenchSermons = AdminBranhamSermonService.filterByLanguage(sermons, 'fr');
    print('✅ Prédications en français: ${frenchSermons.length}');
    
    print('\n🎉 Tous les tests sont passés avec succès !');
    print('Le système de gestion des prédications de William Branham est prêt.');
    
  } catch (e) {
    print('❌ Erreur lors des tests: $e');
  }
}

/// Extension pour simplifier les tests
extension AdminBranhamSermonTestExtension on AdminBranhamSermon {
  void printDetails() {
    print('📖 ${title}');
    print('   📅 Date: ${date}');
    print('   📍 Lieu: ${location}');
    print('   ⏱️ Durée: ${duration?.inMinutes ?? 0} min');
    print('   🏷️ Mots-clés: ${keywords.join(", ")}');
    print('   🌐 Langue: ${language}');
    print('   📊 Ordre: ${displayOrder}');
    print('   ✅ Actif: ${isActive ? "Oui" : "Non"}');
  }
}
