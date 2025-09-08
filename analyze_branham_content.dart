import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;

void main() async {
  print('🔍 Analyse détaillée du contenu branham.org...');
  print('===============================================\n');
  
  try {
    const url = 'https://branham.org/fr/quoteoftheday';
    
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'fr-FR,fr;q=0.9,en;q=0.8',
        'Accept-Encoding': 'gzip, deflate, br',
        'Connection': 'keep-alive',
      }).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final document = html_parser.parse(response.body);
      final bodyText = document.body?.text ?? '';
      
      // Rechercher les sections principales
      print('🔍 Recherche des sections principales...\n');
      
      // 1. Pain quotidien
      if (bodyText.contains('Pain quotidien')) {
        print('📖 SECTION PAIN QUOTIDIEN TROUVÉE:');
        final painIndex = bodyText.indexOf('Pain quotidien');
        final section = bodyText.substring(painIndex, painIndex + 500);
        print(section);
        print('\n' + '='*50 + '\n');
      }
      
      // 2. Citation principale
      print('💬 CITATIONS LONGUES (>80 caractères):');
      final paragraphs = document.querySelectorAll('p, div');
      int citationCount = 0;
      for (final p in paragraphs) {
        final text = p.text.trim();
        if (text.length > 80 && 
            !text.contains('Pain quotidien') &&
            !text.contains('Aujourd\'hui') &&
            !text.contains('janvier') &&
            !text.contains('février') &&
            !text.contains('mars') &&
            !text.contains('avril') &&
            !text.contains('mai') &&
            !text.contains('juin') &&
            !text.contains('juillet') &&
            !text.contains('août') &&
            !text.contains('septembre') &&
            !text.contains('octobre') &&
            !text.contains('novembre') &&
            !text.contains('décembre') &&
            !RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}').hasMatch(text)) {
          print('Citation ${++citationCount}:');
          print(text.substring(0, text.length > 200 ? 200 : text.length) + '...');
          print('');
          if (citationCount >= 3) break; // Limiter à 3 pour la lisibilité
        }
      }
      
      // 3. Éléments de tableau (pour titres et dates)
      print('\n📊 CONTENU DES TABLEAUX:');
      final tables = document.querySelectorAll('table');
      for (int i = 0; i < tables.length && i < 2; i++) {
        print('Table ${i + 1}:');
        final rows = tables[i].querySelectorAll('tr');
        for (int j = 0; j < rows.length && j < 3; j++) {
          final cells = rows[j].querySelectorAll('td, th');
          final cellTexts = cells.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
          if (cellTexts.isNotEmpty) {
            print('  Row ${j + 1}: ${cellTexts.join(' | ')}');
          }
        }
        print('');
      }
      
      // 4. Liens audio
      print('🎵 LIENS AUDIO TROUVÉS:');
      final audioLinks = document.querySelectorAll('a[href*=".m4a"], a[href*=".mp3"], source[src*=".m4a"], source[src*=".mp3"]');
      for (final link in audioLinks) {
        final href = link.attributes['href'] ?? link.attributes['src'] ?? '';
        print('  Audio: $href');
      }
      
      // 5. Structure générale
      print('\n📝 STRUCTURE GÉNÉRALE:');
      final allText = bodyText.replaceAll(RegExp(r'\s+'), ' ');
      
      // Chercher les patterns de date
      final dateMatches = RegExp(r'(\d{2}-\d{4})')
          .allMatches(allText)
          .map((m) => m.group(1))
          .toSet()
          .toList();
      print('Dates trouvées: $dateMatches');
      
      // Chercher les références bibliques
      final refMatches = RegExp(r'([1-3]?\s*[A-Za-zÀ-ÿ]+\s+\d+[.\:]\d+[-\d]*)')
          .allMatches(allText)
          .map((m) => m.group(1))
          .toSet()
          .toList();
      print('Références bibliques: $refMatches');
      
    } else {
      print('❌ ERREUR: HTTP ${response.statusCode}');
    }
  } catch (e) {
    print('❌ ERREUR: Exception: $e');
  }
  
  exit(0);
}
