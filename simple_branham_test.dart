import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;

void main() async {
  print('🔍 DEBUG: Analyse Branham sans Flutter');
  print('=' * 50);
  
  try {
    final response = await http.get(
      Uri.parse('https://branham.org/fr/quoteoftheday'),
      headers: {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'fr-FR,fr;q=0.9,en;q=0.8',
        'Accept-Encoding': 'gzip, deflate, br',
        'DNT': '1',
        'Connection': 'keep-alive',
        'Upgrade-Insecure-Requests': '1',
        'Sec-Fetch-Dest': 'document',
        'Sec-Fetch-Mode': 'navigate',
        'Sec-Fetch-Site': 'none'
      }).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      print('✅ Page récupérée: ${response.body.length} caractères');
      
      final document = html_parser.parse(response.body);
      final allElements = document.querySelectorAll('div, p, span, td, th');
      
      print('\n📝 TOUS LES TEXTES LONGS (300+ caractères):');
      print('-' * 50);
      
      int count = 0;
      for (final element in allElements) {
        final text = element.text.trim();
        if (text.length > 300) {
          count++;
          print('\n[$count] Élément: ${element.localName}');
          print('Longueur: ${text.length} caractères');
          print('Début: "${text.substring(0, text.length > 200 ? 200 : text.length)}..."');
          
          // Analyse du contenu
          print('Contient "Vous êtes": ${text.contains('Vous êtes')}');
          print('Contient "pécheur": ${text.contains('pécheur')}');
          print('Contient "dit l\'Éternel": ${text.contains('dit l\'Éternel')}');
          print('Contient "VGR": ${text.contains('VGR')}');
          print('Contient "English": ${text.contains('English')}');
          print('Contient "conférence": ${text.contains('conférence')}');
          
          // Test si c'est la citation attendue
          bool isTargetQuote = text.contains('Vous êtes peut-être un pécheur qui a commis de nombreux péchés');
          if (isTargetQuote) {
            print('🎯 *** CITATION CIBLE TROUVÉE ! ***');
          }
          
          print('-' * 30);
        }
      }
      
      print('\n📊 RÉSUMÉ: $count textes longs trouvés');
      
      // Recherche spécifique de la citation exacte
      final bodyText = document.body?.text ?? '';
      bool hasTargetText = bodyText.contains('Vous êtes peut-être un pécheur qui a commis de nombreux péchés');
      print('\n🎯 Texte cible présent dans le body: $hasTargetText');
      
      if (hasTargetText) {
        int startIndex = bodyText.indexOf('Vous êtes peut-être un pécheur qui a commis de nombreux péchés');
        String targetText = bodyText.substring(startIndex, startIndex + 400);
        print('Extrait: "$targetText..."');
      }
      
    } else {
      print('❌ Erreur HTTP: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Erreur: $e');
  }
}
