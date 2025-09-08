import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;

void main() async {
  print('🔍 Analyse détaillée du contenu Branham pour trouver la vraie citation...');
  print('=========================================================================\n');
  
  try {
    const url = 'https://branham.org/fr/quoteoftheday';
    print('🌐 Récupération depuis: $url');
    
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'fr-FR,fr;q=0.9,en;q=0.8',
      }).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      print('✅ Site accessible, analyse du contenu HTML...\n');
      
      final document = html_parser.parse(response.body);
      final bodyText = document.body?.text ?? '';
      
      print('🔍 ANALYSE DU CONTENU APRÈS "Aujourd\'hui":');
      print('==========================================');
      
      if (bodyText.contains('Aujourd\'hui')) {
        final aujourdIndex = bodyText.indexOf('Aujourd\'hui');
        final afterAujourdhui = bodyText.substring(aujourdIndex);
        
        // Afficher le contenu brut pour analyse
        final sections = afterAujourdhui.split('\n');
        print('📝 Sections trouvées après "Aujourd\'hui":');
        for (int i = 0; i < sections.length && i < 20; i++) {
          final section = sections[i].trim();
          if (section.isNotEmpty) {
            print('[$i] "${section.substring(0, section.length > 100 ? 100 : section.length)}..."');
          }
        }
        
        print('\n🔍 RECHERCHE DANS LES ÉLÉMENTS HTML:');
        print('====================================');
        
        // Chercher dans les divs
        final divs = document.querySelectorAll('div');
        print('📝 Contenu des DIVs pertinents:');
        for (int i = 0; i < divs.length; i++) {
          final divText = divs[i].text.trim();
          if (divText.length > 30 && 
              divText.length < 500 &&
              !divText.contains('Pain quotidien') &&
              !divText.contains('Conference') &&
              !divText.contains('DateTitre') &&
              !divText.contains('Septembre') &&
              !divText.contains('try {') &&
              !RegExp(r'\d{10,}').hasMatch(divText) &&
              divText.split(' ').length > 5) {
            print('[DIV $i] "${divText.substring(0, divText.length > 150 ? 150 : divText.length)}..."');
          }
        }
        
        // Chercher dans les paragraphes
        final paragraphs = document.querySelectorAll('p');
        print('\n📝 Contenu des PARAGRAPHEs pertinents:');
        for (int i = 0; i < paragraphs.length; i++) {
          final pText = paragraphs[i].text.trim();
          if (pText.length > 30 && 
              pText.length < 500 &&
              !pText.contains('Pain quotidien') &&
              !pText.contains('Conference') &&
              !pText.contains('DateTitre') &&
              !pText.contains('Septembre') &&
              !pText.contains('try {') &&
              pText.split(' ').length > 5) {
            print('[P $i] "${pText.substring(0, pText.length > 150 ? 150 : pText.length)}..."');
          }
        }
        
        // Chercher dans les spans
        final spans = document.querySelectorAll('span');
        print('\n📝 Contenu des SPANs pertinents:');
        for (int i = 0; i < spans.length; i++) {
          final spanText = spans[i].text.trim();
          if (spanText.length > 30 && 
              spanText.length < 500 &&
              !spanText.contains('Pain quotidien') &&
              !spanText.contains('Conference') &&
              !spanText.contains('DateTitre') &&
              !spanText.contains('Septembre') &&
              !spanText.contains('try {') &&
              spanText.split(' ').length > 5) {
            print('[SPAN $i] "${spanText.substring(0, spanText.length > 150 ? 150 : spanText.length)}..."');
          }
        }
        
        // Analyser le texte autour de "Aujourd'hui"
        print('\n🔍 ANALYSE CONTEXTUELLE AUTOUR D\'AUJOURD\'HUI:');
        print('================================================');
        final contextBefore = bodyText.substring(
            aujourdIndex > 300 ? aujourdIndex - 300 : 0, 
            aujourdIndex);
        final contextAfter = afterAujourdhui.substring(0, 
            afterAujourdhui.length > 1000 ? 1000 : afterAujourdhui.length);
        
        print('📍 300 caractères AVANT "Aujourd\'hui":');
        print('"${contextBefore.replaceAll(RegExp(r'\s+'), ' ').trim()}"');
        
        print('\n📍 1000 caractères APRÈS "Aujourd\'hui":');
        print('"${contextAfter.replaceAll(RegExp(r'\s+'), ' ').trim()}"');
        
        // Recherche de patterns spécifiques
        print('\n🔍 RECHERCHE DE PATTERNS DE CITATION:');
        print('====================================');
        
        // Pattern pour trouver des citations (phrases avec guillemets ou longues phrases)
        final quotePatterns = [
          RegExp(r'"[^"]{30,300}"'),  // Texte entre guillemets
          RegExp(r'«[^»]{30,300}»'),  // Texte entre guillemets français
          RegExp(r'[A-Z][^.!?]{50,300}[.!?]'),  // Phrases longues
        ];
        
        for (int i = 0; i < quotePatterns.length; i++) {
          final matches = quotePatterns[i].allMatches(contextAfter);
          print('📝 Pattern ${i + 1} trouvé ${matches.length} correspondances:');
          for (final match in matches) {
            final matchText = match.group(0) ?? '';
            if (!matchText.contains('Conference') && 
                !matchText.contains('DateTitre') &&
                !matchText.contains('Septembre')) {
              print('   - "${matchText.substring(0, matchText.length > 100 ? 100 : matchText.length)}..."');
            }
          }
        }
      }
      
    } else {
      print('❌ ERREUR: HTTP ${response.statusCode}');
    }
  } catch (e) {
    print('❌ ERREUR: Exception: $e');
  }
  
  exit(0);
}
