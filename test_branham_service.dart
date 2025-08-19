import 'package:flutter/material.dart';
import 'lib/modules/message/services/branham_messages_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('=== Test du service Branham Messages ===');
  
  try {
    // Test de récupération des messages
    final messages = await BranhamMessagesService.getAllMessages();
    
    print('Nombre de messages récupérés: ${messages.length}');
    
    if (messages.isNotEmpty) {
      print('\nExemples de messages:');
      for (int i = 0; i < (messages.length > 3 ? 3 : messages.length); i++) {
        final message = messages[i];
        print('---');
        print('ID: ${message.id}');
        print('Titre: ${message.title}');
        print('Lieu: ${message.location}');
        print('Durée: ${message.formattedDuration}');
        print('Date: ${message.formattedDate}');
        print('PDF URL: ${message.pdfUrl}');
        print('Audio URL: ${message.audioUrl}');
      }
    }
    
    // Test de recherche
    print('\n=== Test de recherche ===');
    final searchResults = BranhamMessagesService.searchMessages(messages, 'foi');
    print('Résultats pour "foi": ${searchResults.length} messages');
    
    // Test de filtre par décennie
    print('\n=== Test de filtres ===');
    final messages1960s = BranhamMessagesService.filterByDecade(messages, '1960s');
    print('Messages des années 1960s: ${messages1960s.length}');
    
    final messages1950s = BranhamMessagesService.filterByDecade(messages, '1950s');
    print('Messages des années 1950s: ${messages1950s.length}');
    
    print('\n=== Test terminé avec succès! ===');
    
  } catch (e, stackTrace) {
    print('Erreur lors du test: $e');
    print('StackTrace: $stackTrace');
  }
}
