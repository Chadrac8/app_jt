import 'package:http/http.dart' as http;

void main() async {
  print('=== DIAGNOSTIC DU PROBLÈME DE DUPLICATION ===');
  
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
      
      print('🔍 Recherche des sections distinctes...');
      
      String scriptureReference = '';
      String scriptureText = '';
      String quoteContent = '';
      String sermonTitle = '';
      String sermonCode = '';
      
      for (String line in lines) {
        String trimmedLine = line.trim();
        
        // Référence biblique
        if (trimmedLine.contains('<span id="scripturereference">')) {
          scriptureReference = trimmedLine
              .replaceAll(RegExp(r'<[^>]*>'), '')
              .trim();
          print('📍 Référence biblique: $scriptureReference');
        }
        
        // Texte biblique
        if (trimmedLine.contains('<span id="scripturetext">')) {
          scriptureText = trimmedLine
              .replaceAll(RegExp(r'<[^>]*>'), '')
              .trim();
          print('📖 Texte biblique: ${scriptureText.substring(0, 50)}...');
        }
        
        // Citation de Branham (différente du verset biblique)
        if (trimmedLine.contains('<span id="content">')) {
          quoteContent = trimmedLine
              .replaceAll(RegExp(r'<[^>]*>'), '')
              .trim();
          print('💬 Citation Branham: ${quoteContent.substring(0, 50)}...');
        }
        
        // Titre de prédication
        if (trimmedLine.contains('<span id="summary">')) {
          sermonTitle = trimmedLine
              .replaceAll(RegExp(r'<[^>]*>'), '')
              .trim();
          print('🎯 Titre: $sermonTitle');
        }
        
        // Code de prédication
        if (trimmedLine.contains('<span id="title">')) {
          sermonCode = trimmedLine
              .replaceAll(RegExp(r'<[^>]*>'), '')
              .trim();
          print('🔢 Code: $sermonCode');
        }
      }
      
      print('\n=== ANALYSE DU PROBLÈME ===');
      print('Verset biblique et citation Branham sont-ils identiques?');
      print('Verset: ${scriptureText.substring(0, 30)}...');
      print('Citation: ${quoteContent.substring(0, 30)}...');
      print('Identiques: ${scriptureText == quoteContent ? "❌ OUI - PROBLÈME!" : "✅ NON - OK"}');
      
      print('\n=== SOLUTION ===');
      print('Il faut séparer clairement:');
      print('1. dailyBread = scriptureText (verset biblique)');
      print('2. text = quoteContent (citation de Branham)');
      print('3. Vérifier qu\'ils sont différents');
      
    } else {
      print('Erreur HTTP: ${response.statusCode}');
    }
    
  } catch (e) {
    print('Erreur: $e');
  }
}
