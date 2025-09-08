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
      .replaceAll('&ugrave;', 'ù')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      // Nettoyer les artefacts de parsing 
      .replaceAll(RegExp(r'\s*\.\s*replaceAll\([^)]+\)\s*'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

void main() async {
  print('=== TEST DE NETTOYAGE DU TEXTE ===');
  
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
      
      for (String line in lines) {
        String trimmedLine = line.trim();
        
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
      
      print('✅ TEXTE NETTOYÉ:');
      print('Référence: $dailyBreadRef');
      print('Verset: $dailyBread');
      
      // Vérification de la propreté
      bool isClean = !dailyBread.contains('replaceAll') && !dailyBread.contains('&');
      print('\n${isClean ? "✅" : "❌"} Texte propre: $isClean');
      
    } else {
      print('Erreur HTTP: ${response.statusCode}');
    }
    
  } catch (e) {
    print('Erreur: $e');
  }
}
