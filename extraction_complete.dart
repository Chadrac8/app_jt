import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;

void main() async {
  print('=== EXTRACTION COMPLÈTE DU CONTENU BRANHAM.ORG ===');
  
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
      final document = html_parser.parse(content);
      
      print('Taille du contenu: ${content.length} caractères');
      print('');
      
      // 1. Extraire tous les éléments textuels substantiels
      print('=== EXTRACTION DE TOUS LES TEXTES ===');
      final allElements = document.querySelectorAll('*');
      List<String> substantialTexts = [];
      
      for (final element in allElements) {
        String text = element.text.trim();
        
        // Garder les textes de 20 à 2000 caractères
        if (text.length > 20 && text.length < 2000) {
          // Nettoyer et éviter les doublons
          String cleanText = text.replaceAll(RegExp(r'\s+'), ' ').trim();
          
          // Éviter les éléments de navigation
          if (!cleanText.contains('VGR') &&
              !cleanText.contains('Copyright') &&
              !cleanText.contains('English') &&
              !cleanText.contains('Español') &&
              !cleanText.contains('menu') &&
              !cleanText.contains('Navigation') &&
              !cleanText.contains('http://') &&
              !cleanText.contains('www.') &&
              !substantialTexts.contains(cleanText)) {
            substantialTexts.add(cleanText);
          }
        }
      }
      
      print('Nombre de textes substantiels trouvés: ${substantialTexts.length}');
      print('');
      
      // 2. Analyser chaque texte pour identifier la citation et le verset
      print('=== ANALYSE DES TEXTES ===');
      String? dailyBreadVerse;
      String? dailyBreadRef = 'Ésaïe 1.18'; // On sait qu'elle est là
      String? branhamQuote;
      String? sermonCode = '59-1220M'; // On sait qu'il est là
      
      for (int i = 0; i < substantialTexts.length; i++) {
        String text = substantialTexts[i];
        
        print('--- Texte ${i + 1} (${text.length} caractères) ---');
        print(text);
        print('');
        
        // Identifier les différents types de contenu
        if (text.contains('Ésaïe') && text.length < 200) {
          print('🎯 VERSET BIBLIQUE POTENTIEL: $text');
          if (dailyBreadVerse == null || text.length > dailyBreadVerse.length) {
            dailyBreadVerse = text;
          }
        }
        
        if (text.contains('59-1220M') && text.length > 100) {
          print('🎯 CITATION BRANHAM POTENTIELLE: $text');
          if (branhamQuote == null || text.length > branhamQuote.length) {
            branhamQuote = text;
          }
        }
        
        // Chercher d'autres citations religieuses longues
        if (text.length > 100 && 
            (text.contains('Dieu') || text.contains('Seigneur') || 
             text.contains('Christ') || text.contains('Jésus')) &&
            !text.contains('Pain quotidien') &&
            !text.contains('59-1220M') &&
            !text.contains('Ésaïe')) {
          print('🎯 AUTRE CITATION RELIGIEUSE: $text');
          if (branhamQuote == null) {
            branhamQuote = text;
          }
        }
        
        print('');
      }
      
      print('=== RÉSULTATS FINAUX ===');
      print('Verset du jour: ${dailyBreadVerse ?? "Non trouvé"}');
      print('Référence biblique: $dailyBreadRef');
      print('Citation Branham: ${branhamQuote ?? "Non trouvée"}');
      print('Code de prédication: $sermonCode');
      
      // 3. Essayer une approche par parsing HTML plus ciblée
      print('\n=== PARSING HTML CIBLÉ ===');
      
      // Chercher les divs, spans, p avec du contenu substantiel
      final containers = document.querySelectorAll('div, span, p, td, th');
      
      for (final container in containers) {
        String text = container.text.trim();
        if (text.length > 50 && text.length < 500) {
          
          // Chercher spécifiquement pour du contenu français de Branham
          if ((text.contains('Dieu') || text.contains('Seigneur')) &&
              !text.contains('VGR') &&
              !text.contains('Copyright') &&
              !text.contains('English')) {
            
            print('HTML Element: ${container.localName}');
            print('Classe: ${container.classes}');
            print('Contenu: $text');
            print('');
          }
        }
      }
      
    }
    
  } catch (e) {
    print('Erreur: $e');
  }
}
