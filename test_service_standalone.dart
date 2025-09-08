import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('=== Test du Service de Pain Quotidien (Standalone) ===');
  
  try {
    // Test direct sur le site
    final response = await http.get(
      Uri.parse('https://www.branham.org/quotesoftheday'),
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'fr-FR,fr;q=0.9,en;q=0.8',
        'Accept-Encoding': 'gzip, deflate',
        'DNT': '1',
        'Connection': 'keep-alive',
        'Upgrade-Insecure-Requests': '1',
      },
    );

    print('Statut de la réponse: ${response.statusCode}');
    print('Taille du contenu: ${response.body.length} caractères');
    
    if (response.statusCode == 200) {
      // Recherche du contenu de citation spécifique
      String content = response.body;
      
      // Recherche du verset biblique
      List<RegExp> versePatterns = [
        RegExp(r'<div[^>]*class="[^"]*verse[^"]*"[^>]*>(.*?)</div>', 
               caseSensitive: false, multiLine: true, dotAll: true),
        RegExp(r'<span[^>]*class="[^"]*verse[^"]*"[^>]*>(.*?)</span>', 
               caseSensitive: false, multiLine: true, dotAll: true),
        RegExp(r'<p[^>]*class="[^"]*verse[^"]*"[^>]*>(.*?)</p>', 
               caseSensitive: false, multiLine: true, dotAll: true),
      ];
      
      String? biblicalVerse;
      for (var pattern in versePatterns) {
        var match = pattern.firstMatch(content);
        if (match != null) {
          biblicalVerse = match.group(1)?.replaceAll(RegExp(r'<[^>]*>'), '').trim();
          if (biblicalVerse != null && biblicalVerse.isNotEmpty) {
            break;
          }
        }
      }
      
      // Recherche de la citation Branham spécifique
      String targetCitation = "Vous êtes peut-être un pécheur qui a commis de nombreux péchés";
      bool foundTargetCitation = content.contains(targetCitation);
      
      // Analyse du contenu
      print('\n=== ANALYSE DU CONTENU ===');
      print('Verset biblique trouvé: ${biblicalVerse ?? "Non trouvé"}');
      print('Citation cible trouvée: $foundTargetCitation');
      
      if (foundTargetCitation) {
        // Extraire le contexte autour de la citation
        int index = content.indexOf(targetCitation);
        int start = (index - 100).clamp(0, content.length);
        int end = (index + 800).clamp(0, content.length);
        String context = content.substring(start, end);
        print('\nContexte de la citation:');
        print(context.replaceAll(RegExp(r'<[^>]*>'), '').trim());
      }
      
      // Chercher tous les divs, spans, et p qui pourraient contenir la citation
      List<RegExp> patterns = [
        RegExp(r'<div[^>]*>(.*?)</div>', caseSensitive: false, multiLine: true, dotAll: true),
        RegExp(r'<span[^>]*>(.*?)</span>', caseSensitive: false, multiLine: true, dotAll: true),
        RegExp(r'<p[^>]*>(.*?)</p>', caseSensitive: false, multiLine: true, dotAll: true),
      ];
      
      int elementCount = 0;
      for (var pattern in patterns) {
        var matches = pattern.allMatches(content);
        for (var match in matches) {
          var text = match.group(1)?.replaceAll(RegExp(r'<[^>]*>'), '').trim() ?? '';
          if (text.contains(targetCitation)) {
            elementCount++;
            print('\nÉlément $elementCount contenant la citation:');
            print('Longueur: ${text.length} caractères');
            if (text.length <= 800) {
              print('Contenu: $text');
            } else {
              print('Contenu (tronqué): ${text.substring(0, 800)}...');
            }
          }
        }
      }
      
      print('\nNombre d\'éléments contenant la citation cible: $elementCount');
      
    } else {
      print('Erreur: ${response.statusCode}');
      print('Corps de la réponse: ${response.body}');
    }
    
  } catch (e) {
    print('Erreur lors du test: $e');
  }
  
  print('\n=== Fin du test ===');
}
