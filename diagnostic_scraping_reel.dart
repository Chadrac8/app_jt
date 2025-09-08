import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('=== DIAGNOSTIC SCRAPING RÉEL DU SITE BRANHAM.ORG ===');
  
  try {
    // Test direct sur le site français
    final response = await http.get(
      Uri.parse('https://branham.org/fr/quoteoftheday'),
      headers: {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
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
      String content = response.body;
      
      print('\n=== ANALYSE DU CONTENU RÉEL ===');
      
      // 1. Rechercher les citations actuelles du jour
      print('\n1. Recherche de citations longues dans le contenu:');
      
      // Diviser en lignes et chercher des phrases substantielles
      List<String> lines = content.split('\n');
      List<String> potentialQuotes = [];
      
      for (String line in lines) {
        String cleanLine = line.trim().replaceAll(RegExp(r'<[^>]*>'), '').trim();
        
        // Chercher des phrases de plus de 50 caractères qui semblent être des citations
        if (cleanLine.length > 50 && 
            cleanLine.length < 800 &&
            (cleanLine.contains('Dieu') || 
             cleanLine.contains('Jésus') || 
             cleanLine.contains('Christ') ||
             cleanLine.contains('Seigneur') ||
             cleanLine.contains('péché') ||
             cleanLine.contains('foi') ||
             cleanLine.contains('amour'))) {
          
          // Éviter le contenu de navigation
          if (!cleanLine.contains('Copyright') &&
              !cleanLine.contains('VGR') &&
              !cleanLine.contains('English') &&
              !cleanLine.contains('Español') &&
              !cleanLine.contains('menu') &&
              !cleanLine.contains('http') &&
              !cleanLine.contains('www') &&
              !cleanLine.contains('&nbsp;')) {
            potentialQuotes.add(cleanLine);
          }
        }
      }
      
      print('Nombre de citations potentielles trouvées: ${potentialQuotes.length}');
      for (int i = 0; i < potentialQuotes.length && i < 5; i++) {
        print('Citation ${i + 1}: ${potentialQuotes[i]}');
        print('');
      }
      
      // 2. Rechercher des codes de prédication (ex: 59-1220M, 60-0515E)
      print('\n2. Recherche de codes de prédication:');
      RegExp sermonCodeRegex = RegExp(r'\b\d{2}-\d{4}[A-Z]?\b');
      Iterable<Match> sermonMatches = sermonCodeRegex.allMatches(content);
      
      for (Match match in sermonMatches.take(5)) {
        print('Code trouvé: ${match.group(0)}');
      }
      
      // 3. Rechercher des références bibliques
      print('\n3. Recherche de références bibliques:');
      List<String> biblicalBooks = [
        'Jean', 'Matthieu', 'Marc', 'Luc', 'Actes', 'Romains',
        'Corinthiens', 'Galates', 'Éphésiens', 'Philippiens',
        'Genèse', 'Exode', 'Psaumes', 'Proverbes', 'Ésaïe'
      ];
      
      for (String book in biblicalBooks) {
        RegExp bookRegex = RegExp('$book\\s+\\d+[:\\.]\\d+', caseSensitive: false);
        Iterable<Match> bookMatches = bookRegex.allMatches(content);
        for (Match match in bookMatches.take(2)) {
          print('Référence trouvée: ${match.group(0)}');
        }
      }
      
      // 4. Rechercher le terme "Pain quotidien"
      print('\n4. Recherche de "Pain quotidien":');
      if (content.contains('Pain quotidien')) {
        print('✅ "Pain quotidien" trouvé dans le contenu');
        
        // Trouver le contexte autour de "Pain quotidien"
        int painIndex = content.indexOf('Pain quotidien');
        int start = (painIndex - 200).clamp(0, content.length);
        int end = (painIndex + 500).clamp(0, content.length);
        String context = content.substring(start, end);
        
        print('Contexte:');
        print(context.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll(RegExp(r'\s+'), ' ').trim());
      } else {
        print('⚠️ "Pain quotidien" non trouvé, essayons "Daily Bread"');
        if (content.contains('Daily Bread')) {
          print('✅ "Daily Bread" trouvé (version anglaise)');
        }
      }
      
      // 5. Recherche de la citation spécifique mentionnée
      print('\n5. Recherche de la citation spécifique:');
      String targetQuote = "Vous êtes peut-être un pécheur qui a commis de nombreux péchés";
      if (content.contains(targetQuote)) {
        print('✅ Citation cible trouvée!');
        
        // Extraire le contexte complet
        int quoteIndex = content.indexOf(targetQuote);
        int start = (quoteIndex - 50).clamp(0, content.length);
        int end = (quoteIndex + 800).clamp(0, content.length);
        String fullQuote = content.substring(start, end);
        
        print('Citation complète:');
        print(fullQuote.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll(RegExp(r'\s+'), ' ').trim());
      } else {
        print('⚠️ Citation cible non trouvée - le contenu a peut-être changé');
      }
      
    } else {
      print('Erreur: ${response.statusCode}');
    }
    
  } catch (e) {
    print('Erreur lors du diagnostic: $e');
  }
  
  print('\n=== FIN DU DIAGNOSTIC ===');
}
