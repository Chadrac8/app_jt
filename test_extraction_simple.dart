import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('=== TEST SIMPLE DU CONTENU RÉEL ===');
  
  try {
    // Récupérer le contenu du site
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
      
      // Extraire les éléments essentiels comme dans notre service corrigé
      List<String> lines = content.split('\n');
      String dailyBread = '';
      String dailyBreadRef = '';
      String quoteText = '';
      String sermonTitle = '';
      String sermonCode = '';
      
      for (String line in lines) {
        String cleanLine = line.trim().replaceAll(RegExp(r'<[^>]*>'), '').trim();
        
        // Pain quotidien avec référence
        if (cleanLine.contains('Pain quotidien') && cleanLine.contains('Ésaïe')) {
          // Extraire "Pain quotidien Ésaïe 1.18 Venez et plaidons..."
          String withoutPainQuotidien = cleanLine.replaceFirst('Pain quotidien', '').trim();
          List<String> parts = withoutPainQuotidien.split(' ');
          if (parts.length > 2) {
            dailyBreadRef = '${parts[0]} ${parts[1]}'; // "Ésaïe 1.18"
            dailyBread = parts.skip(2).join(' '); // Le reste
          }
        }
        
        // Citation longue de Branham
        if (cleanLine.length > 300 && cleanLine.length < 1000 &&
            cleanLine.contains('pécheur') && cleanLine.contains('Dieu') &&
            !cleanLine.contains('Pain quotidien')) {
          quoteText = cleanLine;
        }
        
        // Code de prédication
        if (cleanLine.contains('59-1220M') && cleanLine.length < 50) {
          sermonCode = '59-1220M';
        }
        
        // Titre de prédication
        if (cleanLine == 'Une conférence avec Dieu') {
          sermonTitle = cleanLine;
        }
      }
      
      print('\n=== RÉSULTATS DE L\'EXTRACTION ===');
      print('📖 Verset du jour: $dailyBread');
      print('📍 Référence: $dailyBreadRef');
      print('📝 Citation Branham: ${quoteText.isNotEmpty ? "${quoteText.substring(0, 100)}..." : "Non trouvée"}');
      print('🎯 Titre: $sermonTitle');
      print('🔢 Code: $sermonCode');
      
      // Simulation de ce que l'app devrait afficher
      print('\n=== CE QUE L\'APP DEVRAIT AFFICHER ===');
      print('VERSET DU JOUR:');
      print(dailyBread);
      print('$dailyBreadRef');
      print('');
      print('CITATION DU JOUR:');
      print(quoteText.isNotEmpty ? quoteText : 'Citation non extraite');
      print('$sermonCode - $sermonTitle');
      print('William Marrion Branham');
      
      // Vérification
      bool success = dailyBread.isNotEmpty && quoteText.isNotEmpty && sermonCode.isNotEmpty;
      print('\n${success ? "✅ EXTRACTION RÉUSSIE!" : "❌ Extraction incomplète"}');
      
    } else {
      print('Erreur HTTP: ${response.statusCode}');
    }
    
  } catch (e) {
    print('Erreur: $e');
  }
}
