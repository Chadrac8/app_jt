import 'package:http/http.dart' as http;

void main() async {
  print('=== ANALYSE DU CONTENU HTML BRUT ===');
  
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
      
      print('📋 Analyse des lignes significatives:');
      for (int i = 0; i < lines.length; i++) {
        String line = lines[i].trim();
        String cleanLine = line.replaceAll(RegExp(r'<[^>]*>'), '').trim();
        
        // Lignes contenant des mots-clés importants
        if (cleanLine.isNotEmpty && (
            cleanLine.contains('Pain quotidien') ||
            cleanLine.contains('Ésaïe') ||
            cleanLine.contains('59-1220M') ||
            cleanLine.contains('conférence') ||
            cleanLine.contains('Dieu') ||
            cleanLine.contains('pécheur') ||
            cleanLine.length > 200
        )) {
          print('\n--- Ligne $i ---');
          print('HTML: ${line.length > 100 ? line.substring(0, 100) + "..." : line}');
          print('CLEAN: ${cleanLine.length > 100 ? cleanLine.substring(0, 100) + "..." : cleanLine}');
          print('Longueur: ${cleanLine.length}');
        }
      }
      
      // Recherche de patterns spécifiques
      print('\n=== RECHERCHE DE PATTERNS ===');
      
      // Recherche du titre de prédication
      for (String line in lines) {
        String cleanLine = line.replaceAll(RegExp(r'<[^>]*>'), '').trim();
        if (cleanLine.contains('Une conférence avec Dieu')) {
          print('✅ Titre trouvé: $cleanLine');
        }
      }
      
      // Recherche de citations longues
      List<String> longTexts = [];
      for (String line in lines) {
        String cleanLine = line.replaceAll(RegExp(r'<[^>]*>'), '').trim();
        if (cleanLine.length > 300 && cleanLine.length < 1000) {
          longTexts.add(cleanLine);
        }
      }
      
      print('\n📝 Textes longs trouvés (${longTexts.length}):');
      for (int i = 0; i < longTexts.length; i++) {
        print('$i: ${longTexts[i].substring(0, 50)}...');
      }
      
    } else {
      print('Erreur HTTP: ${response.statusCode}');
    }
    
  } catch (e) {
    print('Erreur: $e');
  }
}
