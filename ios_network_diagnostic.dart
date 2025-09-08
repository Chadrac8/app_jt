import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;

class IOSDiagnostic {
  static Future<void> testNetworkAccess() async {
    print('=== DIAGNOSTIC iOS PAIN QUOTIDIEN ===');
    print('Platform: ${defaultTargetPlatform}');
    
    try {
      // Test 1: Vérifier la connectivité de base
      print('\n🔍 Test 1: Connectivité de base...');
      final basicResponse = await http.get(
        Uri.parse('https://www.google.com'),
        headers: {'User-Agent': 'Flutter iOS App'},
      ).timeout(const Duration(seconds: 10));
      
      print('✅ Connectivité de base OK: ${basicResponse.statusCode}');
      
      // Test 2: Tester branham.org avec headers iOS
      print('\n🔍 Test 2: Accès branham.org...');
      final branhamResponse = await http.get(
        Uri.parse('https://branham.org/fr/quoteoftheday'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'fr-FR,fr;q=0.9,en;q=0.8',
          'Connection': 'keep-alive',
        },
      ).timeout(const Duration(seconds: 15));
      
      print('✅ Branham.org accessible: ${branhamResponse.statusCode}');
      print('   Taille de la réponse: ${branhamResponse.body.length} caractères');
      
      // Test 3: Vérifier si le contenu attendu est présent
      String content = branhamResponse.body;
      bool hasTargetQuote = content.contains('Vous êtes peut-être un pécheur qui a commis de nombreux péchés');
      bool hasVerse = content.contains('Pain quotidien') || content.contains('Daily Bread');
      
      print('   Citation cible trouvée: $hasTargetQuote');
      print('   Section Pain quotidien trouvée: $hasVerse');
      
      if (hasTargetQuote) {
        print('✅ iOS peut accéder au contenu correctement!');
      } else {
        print('⚠️ iOS n\'arrive pas à extraire le bon contenu');
      }
      
    } catch (e) {
      print('❌ Erreur réseau iOS: $e');
      print('   Type d\'erreur: ${e.runtimeType}');
      
      // Analyser le type d'erreur
      String errorStr = e.toString().toLowerCase();
      if (errorStr.contains('handshake') || errorStr.contains('certificate')) {
        print('   📱 Problème SSL/TLS détecté');
      } else if (errorStr.contains('timeout')) {
        print('   📱 Timeout de connexion');
      } else if (errorStr.contains('network') || errorStr.contains('connection')) {
        print('   📱 Problème de réseau');
      } else {
        print('   📱 Erreur inconnue');
      }
    }
    
    print('\n=== FIN DU DIAGNOSTIC ===');
  }
}

// Pour utiliser dans l'app iOS
void main() async {
  await IOSDiagnostic.testNetworkAccess();
}
