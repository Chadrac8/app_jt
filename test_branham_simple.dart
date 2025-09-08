import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;

void main() async {
  print('🔍 Test final du service Branham (version simple)...');
  print('===================================================\n');
  
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
      print('✅ Site accessible, parsing du contenu...\n');
      
      final document = html_parser.parse(response.body);
      final bodyText = document.body?.text ?? '';
      
      // 1. EXTRAIRE LE PAIN QUOTIDIEN
      String dailyBread = '';
      String dailyBreadRef = '';
      
      if (bodyText.contains('Pain quotidien')) {
        print('📖 Section Pain quotidien trouvée...');
        final painIndex = bodyText.indexOf('Pain quotidien');
        final painSection = bodyText.substring(painIndex, 
            painIndex + 1000 < bodyText.length ? painIndex + 1000 : bodyText.length);
        
        // Extraire la référence biblique
        final refMatch = RegExp(r'([1-3]?\s*[A-Za-zÀ-ÿ]+\s+\d+[.\:]\d+[-\d]*)')
            .firstMatch(painSection);
        if (refMatch != null) {
          dailyBreadRef = refMatch.group(1)?.trim() ?? '';
          print('📍 Référence biblique: $dailyBreadRef');
        }
        
        // Extraire le texte du verset
        if (dailyBreadRef.isNotEmpty) {
          final refIndex = painSection.indexOf(dailyBreadRef);
          final afterRef = painSection.substring(refIndex + dailyBreadRef.length);
          final aujourdIndex = afterRef.indexOf('Aujourd\'hui');
          
          if (aujourdIndex != -1) {
            final verseText = afterRef.substring(0, aujourdIndex);
            dailyBread = verseText
                .replaceAll(RegExp(r'\s+'), ' ')
                .trim();
            
            print('📖 Pain quotidien: ${dailyBread.substring(0, dailyBread.length > 100 ? 100 : dailyBread.length)}...');
          }
        }
      }
      
      // 2. EXTRAIRE LA CITATION
      String citation = '';
      if (bodyText.contains('Aujourd\'hui')) {
        print('💬 Section citation trouvée...');
        final aujourdIndex = bodyText.indexOf('Aujourd\'hui');
        final citationSection = bodyText.substring(aujourdIndex + 'Aujourd\'hui'.length, 
            aujourdIndex + 1500 < bodyText.length ? aujourdIndex + 1500 : bodyText.length);
        
        final lines = citationSection.split('\n');
        for (final line in lines) {
          final cleanLine = line.trim();
          if (cleanLine.length > 50 && 
              !cleanLine.contains('DateTitre') &&
              !cleanLine.contains('PDFM4A') &&
              !cleanLine.contains('Septembre') &&
              !RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}').hasMatch(cleanLine) &&
              !RegExp(r'^\d{2}-\d{4}').hasMatch(cleanLine)) {
            citation = cleanLine;
            break;
          }
        }
        
        if (citation.isNotEmpty) {
          print('💬 Citation: ${citation.substring(0, citation.length > 100 ? 100 : citation.length)}...');
        }
      }
      
      // 3. EXTRAIRE INFO PRÉDICATION
      String sermonTitle = '';
      String audioUrl = '';
      
      final tables = document.querySelectorAll('table');
      for (final table in tables) {
        final rows = table.querySelectorAll('tr');
        if (rows.length > 1) {
          final firstDataRow = rows[1];
          final cells = firstDataRow.querySelectorAll('td');
          if (cells.length >= 2) {
            final dateCell = cells[0].text.trim();
            final titleCell = cells[1].text.trim();
            
            if (RegExp(r'^\d{2}-\d{4}').hasMatch(dateCell)) {
              sermonTitle = '$dateCell $titleCell';
              print('🎵 Prédication: $sermonTitle');
              break;
            }
          }
        }
      }
      
      // Chercher l'audio
      final audioLinks = document.querySelectorAll('a[href*=".m4a"]');
      if (audioLinks.isNotEmpty) {
        audioUrl = audioLinks.first.attributes['href'] ?? '';
        if (audioUrl.isNotEmpty && !audioUrl.startsWith('http')) {
          audioUrl = 'https://branham.org$audioUrl';
        }
        print('🎵 Audio: ${audioUrl.substring(0, audioUrl.length > 60 ? 60 : audioUrl.length)}...');
      }
      
      // 4. RÉSUMÉ FINAL
      print('\n📋 RÉSUMÉ FINAL:');
      print('================');
      print('✅ Pain quotidien récupéré: ${dailyBread.isNotEmpty ? 'OUI' : 'NON'}');
      print('✅ Référence biblique: ${dailyBreadRef.isNotEmpty ? dailyBreadRef : 'Non trouvée'}');
      print('✅ Citation récupérée: ${citation.isNotEmpty ? 'OUI' : 'NON'}');
      print('✅ Titre prédication: ${sermonTitle.isNotEmpty ? 'OUI' : 'NON'}');
      print('✅ URL audio: ${audioUrl.isNotEmpty ? 'OUI' : 'NON'}');
      
      if (dailyBread.isNotEmpty && citation.isNotEmpty) {
        print('\n🎉 SUCCÈS: Le service fonctionne correctement !');
        print('\n📖 Pain quotidien complet:');
        print('"$dailyBread" - $dailyBreadRef');
        print('\n💬 Citation complète:');
        print('"$citation"');
        print('\n🎵 Prédication: $sermonTitle');
      } else {
        print('\n⚠️ PROBLÈME: Certains éléments n\'ont pas été récupérés');
      }
      
    } else {
      print('❌ ERREUR: HTTP ${response.statusCode}');
    }
  } catch (e) {
    print('❌ ERREUR: Exception: $e');
  }
  
  exit(0);
}
