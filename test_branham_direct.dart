import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;

void main() async {
  print('🔍 Test de récupération du site branham.org...');
  print('=============================================\n');
  
  try {
    const url = 'https://branham.org/fr/quoteoftheday';
    print('🌐 Récupération depuis: $url');
    
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'fr-FR,fr;q=0.9,en;q=0.8',
        'Accept-Encoding': 'gzip, deflate, br',
        'DNT': '1',
        'Connection': 'keep-alive',
        'Upgrade-Insecure-Requests': '1',
      }).timeout(const Duration(seconds: 15));

    print('📊 Status code: ${response.statusCode}');
    print('📏 Content length: ${response.body.length}');
    
    if (response.statusCode == 200) {
      print('✅ SUCCESS: Site accessible');
      
      final document = html_parser.parse(response.body);
      print('📄 Titre de la page: ${document.querySelector('title')?.text ?? 'N/A'}');
      
      // Analyser le contenu pour voir s'il y a du contenu pertinent
      final bodyText = document.body?.text ?? '';
      print('📝 Contenu trouve "Pain quotidien": ${bodyText.contains('Pain quotidien')}');
      print('📝 Contenu trouve "Quote": ${bodyText.contains('Quote')}');
      print('📝 Contenu trouve "Aujourd": ${bodyText.contains('Aujourd')}');
      
      // Afficher les premiers 500 caractères pour debug
      print('\n🔍 Début du contenu HTML:');
      print(response.body.substring(0, response.body.length > 500 ? 500 : response.body.length));
      print('...\n');
      
      // Afficher quelques éléments texte trouvés
      final paragraphs = document.querySelectorAll('p');
      print('📋 Paragraphes trouvés: ${paragraphs.length}');
      for (int i = 0; i < paragraphs.length && i < 5; i++) {
        final text = paragraphs[i].text.trim();
        if (text.isNotEmpty) {
          print('📝 P$i: ${text.substring(0, text.length > 100 ? 100 : text.length)}...');
        }
      }
      
    } else {
      print('❌ ERREUR: HTTP ${response.statusCode}');
      print('📝 Response body: ${response.body}');
    }
  } catch (e) {
    print('❌ ERREUR: Exception: $e');
  }
  
  exit(0);
}
