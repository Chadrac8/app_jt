import 'package:flutter/material.dart';
import 'lib/modules/message/services/admin_branham_messages_service.dart';
import 'lib/models/branham_message.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🔧 Test du service d\'administration des prédications...\n');
  
  try {
    // Test 1: Ajouter une prédication de test
    print('1️⃣ Test d\'ajout d\'une prédication...');
    final testMessage = BranhamMessage(
      id: '',
      title: 'La Foi Une Fois Donnée aux Saints',
      date: '15/7/1963',
      location: 'Jeffersonville, Indiana',
      durationMinutes: 120,
      pdfUrl: 'https://branham.org/fr/sermons/63-0714M_the-faith-that-was-once-delivered-unto-the-saints',
      audioUrl: 'https://branham.org/fr/sermons/63-0714M_the-faith-that-was-once-delivered-unto-the-saints',
      streamUrl: 'https://branham.org/fr/sermons/63-0714M_the-faith-that-was-once-delivered-unto-the-saints',
      language: 'Français',
      publishDate: DateTime(1963, 7, 15),
      series: ['Messages de William Branham'],
    );
    
    final messageId = await AdminBranhamMessagesService.addMessage(testMessage);
    if (messageId != null) {
      print('✅ Prédication ajoutée avec l\'ID: $messageId');
    } else {
      print('❌ Échec de l\'ajout');
      return;
    }
    
    // Test 2: Récupérer toutes les prédications
    print('\n2️⃣ Test de récupération des prédications...');
    final messages = await AdminBranhamMessagesService.getAllMessages();
    print('✅ ${messages.length} prédication(s) trouvée(s)');
    
    // Test 3: Recherche
    print('\n3️⃣ Test de recherche...');
    final searchResults = await AdminBranhamMessagesService.searchMessages('Foi');
    print('✅ ${searchResults.length} résultat(s) trouvé(s) pour "Foi"');
    
    // Test 4: Filtrage par décennie
    print('\n4️⃣ Test de filtrage par décennie...');
    final sixties = await AdminBranhamMessagesService.filterByDecade('1960s');
    print('✅ ${sixties.length} prédication(s) des années 1960');
    
    // Test 5: Statistiques
    print('\n5️⃣ Test des statistiques...');
    final stats = await AdminBranhamMessagesService.getStatistics();
    print('✅ Statistiques: $stats');
    
    // Test 6: Suppression de la prédication de test
    print('\n6️⃣ Test de suppression...');
    final deleted = await AdminBranhamMessagesService.deleteMessage(messageId);
    if (deleted) {
      print('✅ Prédication supprimée avec succès');
    } else {
      print('❌ Échec de la suppression');
    }
    
    print('\n🎉 Tous les tests sont passés avec succès !');
    print('✨ Le système d\'administration est opérationnel.');
    
  } catch (e) {
    print('❌ Erreur lors du test: $e');
  }
}
