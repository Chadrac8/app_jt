import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;

void main() async {
  print('🔍 Analyse spécifique de la section Pain quotidien...');
  print('==================================================\n');
  
  try {
    const url = 'https://branham.org/fr/quoteoftheday';
    
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'fr-FR,fr;q=0.9,en;q=0.8',
      }).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final document = html_parser.parse(response.body);
      final bodyText = document.body?.text ?? '';
      
      // Analyse détaillée de la section Pain quotidien
      if (bodyText.contains('Pain quotidien')) {
        print('📖 SECTION PAIN QUOTIDIEN DÉTAILLÉE:');
        final painIndex = bodyText.indexOf('Pain quotidien');
        final section = bodyText.substring(painIndex, painIndex + 1000);
        
        print('Section complète (1000 chars):');
        print(section);
        print('\n' + '='*60 + '\n');
        
        // Essayer d'extraire plus intelligemment
        final lines = section.split('\n');
        print('📋 LIGNES DE LA SECTION:');
        for (int i = 0; i < lines.length && i < 15; i++) {
          final line = lines[i].trim();
          if (line.isNotEmpty) {
            print('Line $i: "$line"');
          }
        }
        
        print('\n' + '='*60 + '\n');
        
        // Chercher autour de la référence Ésaïe
        if (section.contains('Ésaïe')) {
          print('🔍 AUTOUR DE LA RÉFÉRENCE ÉSAÏE:');
          final esaieIndex = section.indexOf('Ésaïe');
          final beforeEsaie = section.substring(0, esaieIndex);
          final afterEsaie = section.substring(esaieIndex);
          
          print('AVANT Ésaïe (derniers 100 chars):');
          print(beforeEsaie.substring(beforeEsaie.length > 100 ? beforeEsaie.length - 100 : 0));
          print('\nAPRÈS Ésaïe (premiers 500 chars):');
          print(afterEsaie.substring(0, afterEsaie.length > 500 ? 500 : afterEsaie.length));
        }
      }
      
      // Chercher aussi la citation principale (après le pain quotidien)
      print('\n\n💬 CITATION PRINCIPALE:');
      if (bodyText.contains('Aujourd\'hui')) {
        final aujourdIndex = bodyText.indexOf('Aujourd\'hui');
        final citationSection = bodyText.substring(aujourdIndex, 
            aujourdIndex + 1000 < bodyText.length ? aujourdIndex + 1000 : bodyText.length);
        
        print('Section "Aujourd\'hui" (1000 chars):');
        print(citationSection);
      }
      
    } else {
      print('❌ ERREUR: HTTP ${response.statusCode}');
    }
  } catch (e) {
    print('❌ ERREUR: Exception: $e');
  }
  
  exit(0);
}
