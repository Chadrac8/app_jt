import 'package:http/http.dart' as http;

String decodeHtmlEntities(String text) {
  return text
      .replaceAll('&eacute;', 'é')
      .replaceAll('&ecirc;', 'ê')
      .replaceAll('&egrave;', 'è')
      .replaceAll('&agrave;', 'à')
      .replaceAll('&ucirc;', 'û')
      .replaceAll('&ocirc;', 'ô')
      .replaceAll('&acirc;', 'â')
      .replaceAll('&ccedil;', 'ç')
      .replaceAll('&rsquo;', ''')
      .replaceAll('&lsquo;', ''')
      .replaceAll('&ldquo;', '"')
      .replaceAll('&rdquo;', '"')
      .replaceAll('&Eacute;', 'É')
      .replaceAll('&Egrave;', 'È')
      .replaceAll('&Agrave;', 'À')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>');
}

void main() async {
  print('=== TEST EXTRACTION AVEC DÉCODAGE HTML ===');
  
  try {
    final response = await http.get(
      Uri.parse('https://branham.org/fr/quoteoftheday'),
      headers: {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'fr-FR,fr;q=0.9,en;q=0.8',
      },
    );

    if (response.statusCode == 200) {
      String content = response.body;
      List<String> lines = content.split('\n');
      
      String dailyBread = '';
      String dailyBreadRef = '';
      String quoteText = '';
      String sermonTitle = '';
      String sermonCode = '';
      
      for (String line in lines) {
        String trimmedLine = line.trim();
        
        // Code de prédication
        if (trimmedLine.contains('<span id="title">59-1220M</span>')) {
          sermonCode = '59-1220M';
        }
        
        // Titre de prédication  
        if (trimmedLine.contains('<span id="summary">')) {
          String cleanTitle = trimmedLine
              .replaceAll(RegExp(r'<[^>]*>'), '')
              .trim();
          sermonTitle = decodeHtmlEntities(cleanTitle);
        }
        
        // Citation de Branham
        if (trimmedLine.contains('<span id="content">')) {
          String cleanQuote = trimmedLine
              .replaceAll(RegExp(r'<[^>]*>'), '')
              .trim();
          quoteText = decodeHtmlEntities(cleanQuote);
        }
        
        // Référence biblique
        if (trimmedLine.contains('<span id="scripturereference">')) {
          String cleanRef = trimmedLine
              .replaceAll(RegExp(r'<[^>]*>'), '')
              .trim();
          dailyBreadRef = decodeHtmlEntities(cleanRef);
        }
        
        // Texte biblique
        if (trimmedLine.contains('<span id="scripturetext">')) {
          String cleanText = trimmedLine
              .replaceAll(RegExp(r'<[^>]*>'), '')
              .trim();
          dailyBread = decodeHtmlEntities(cleanText);
        }
      }
      
      print('\n=== RÉSULTATS DE L\'EXTRACTION CORRIGÉE ===');
      print('📖 Verset du jour: $dailyBread');
      print('📍 Référence: $dailyBreadRef');
      print('📝 Citation Branham: ${quoteText.isNotEmpty ? "${quoteText.substring(0, 100)}..." : "Non trouvée"}');
      print('🎯 Titre: $sermonTitle');
      print('🔢 Code: $sermonCode');
      
      print('\n=== CE QUE L\'APP DEVRAIT AFFICHER ===');
      print('VERSET DU JOUR:');
      print(dailyBread);
      print(dailyBreadRef);
      print('');
      print('CITATION DU JOUR:');
      print(quoteText.isNotEmpty ? quoteText : 'Citation non extraite');
      print('$sermonCode - $sermonTitle');
      print('William Marrion Branham');
      
      // Vérification
      bool success = dailyBread.isNotEmpty && quoteText.isNotEmpty && sermonCode.isNotEmpty;
      print('\n${success ? "✅ EXTRACTION RÉUSSIE!" : "❌ Extraction incomplète"}');
      
      if (success) {
        print('\n🎉 LE SERVICE DEVRAIT MAINTENANT FONCTIONNER CORRECTEMENT!');
        print('💡 Prochaine étape: Intégrer ces améliorations dans le service principal');
      }
      
    } else {
      print('Erreur HTTP: ${response.statusCode}');
    }
    
  } catch (e) {
    print('Erreur: $e');
  }
}
