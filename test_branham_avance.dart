import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;

void main() async {
  print('🔍 Test avancé du service Branham avec extraction de citation...');
  print('============================================================\n');
  
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
      print('✅ Site accessible, parsing avancé du contenu...\n');
      
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
      
      // 2. EXTRAIRE LA CITATION - VERSION AMÉLIORÉE
      String citation = '';
      
      if (bodyText.contains('Aujourd\'hui')) {
        print('💬 Section citation trouvée, essai de plusieurs méthodes...');
        final aujourdIndex = bodyText.indexOf('Aujourd\'hui');
        final afterAujourdhui = bodyText.substring(aujourdIndex + 'Aujourd\'hui'.length);
        
        // MÉTHODE 1: Nettoyer et extraire les phrases
        print('🔍 Méthode 1: Extraction par phrases...');
        final cleanedText = afterAujourdhui
            .replaceAll(RegExp(r'DateTitre.*?M4A', dotAll: true), '')
            .replaceAll(RegExp(r'\d{2}-\d{4}.*?Conference[^.]*'), '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        
        final sentences = cleanedText.split(RegExp(r'[.!?]'));
        for (final sentence in sentences) {
          final cleanSentence = sentence.trim();
          if (cleanSentence.length > 30 && 
              cleanSentence.length < 400 &&
              cleanSentence.split(' ').length >= 5 &&
              !cleanSentence.contains('Conference') &&
              !cleanSentence.contains('DateTitre') &&
              !cleanSentence.contains('PDFM4A') &&
              !RegExp(r'^\d{2}-\d{4}').hasMatch(cleanSentence)) {
            citation = '$cleanSentence.';
            print('✅ Citation trouvée par méthode 1: ${citation.substring(0, citation.length > 80 ? 80 : citation.length)}...');
            break;
          }
        }
        
        // MÉTHODE 2: Si pas trouvé, ligne par ligne
        if (citation.isEmpty) {
          print('🔍 Méthode 2: Extraction ligne par ligne...');
          final lines = afterAujourdhui.split(RegExp(r'[\n\r]'));
          for (int i = 0; i < lines.length && i < 15; i++) {
            final line = lines[i].trim();
            
            if (line.length > 40 && 
                line.length < 300 &&
                !line.contains('DateTitre') && 
                !line.contains('PDFM4A') && 
                !line.contains('Conference') &&
                !RegExp(r'^\d{2}-\d{4}').hasMatch(line) &&
                !RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}').hasMatch(line) &&
                line.split(' ').length >= 6) {
              citation = line;
              if (!citation.endsWith('.') && !citation.endsWith('!') && !citation.endsWith('?')) {
                citation += '.';
              }
              print('✅ Citation trouvée par méthode 2: ${citation.substring(0, citation.length > 80 ? 80 : citation.length)}...');
              break;
            }
          }
        }
        
        // MÉTHODE 3: Chercher dans les paragraphes HTML
        if (citation.isEmpty) {
          print('🔍 Méthode 3: Extraction par paragraphes HTML...');
          final paragraphs = document.querySelectorAll('p');
          for (final p in paragraphs) {
            final text = p.text.trim();
            if (text.length > 50 && 
                text.length < 350 &&
                !text.contains('Pain quotidien') &&
                !text.contains('Conference') &&
                !text.contains('DateTitre') &&
                text.split(' ').length >= 8) {
              citation = text;
              if (!citation.endsWith('.') && !citation.endsWith('!') && !citation.endsWith('?')) {
                citation += '.';
              }
              print('✅ Citation trouvée par méthode 3: ${citation.substring(0, citation.length > 80 ? 80 : citation.length)}...');
              break;
            }
          }
        }
        
        // MÉTHODE 4: Debug - afficher du contenu brut pour analyse
        if (citation.isEmpty) {
          print('🔍 Méthode 4: Analyse du contenu brut...');
          final debugSection = afterAujourdhui.substring(0, 
              afterAujourdhui.length > 600 ? 600 : afterAujourdhui.length);
          print('📝 Contenu après "Aujourd\'hui":');
          print(debugSection.replaceAll(RegExp(r'\s+'), ' ').trim());
          
          // Essayer d'extraire quand même quelque chose
          final allLines = debugSection.split(RegExp(r'[\n\r]'));
          for (final line in allLines) {
            final cleanLine = line.trim();
            if (cleanLine.length > 20 && !cleanLine.contains('Conference') && !cleanLine.contains('DateTitre')) {
              citation = cleanLine;
              print('⚠️ Citation extraite en mode debug: $citation');
              break;
            }
          }
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
        print('\n🎉 SUCCÈS COMPLET: Tous les éléments récupérés !');
        print('\n📖 Pain quotidien complet:');
        print('"$dailyBread" - $dailyBreadRef');
        print('\n💬 Citation complète:');
        print('"$citation"');
        print('\n🎵 Prédication: $sermonTitle');
      } else if (dailyBread.isNotEmpty) {
        print('\n✅ SUCCÈS PARTIEL: Pain quotidien récupéré');
        print('\n📖 Pain quotidien complet:');
        print('"$dailyBread" - $dailyBreadRef');
        if (citation.isNotEmpty) {
          print('\n💬 Citation: "$citation"');
        }
      } else {
        print('\n⚠️ PROBLÈME: Éléments manquants');
      }
      
    } else {
      print('❌ ERREUR: HTTP ${response.statusCode}');
    }
  } catch (e) {
    print('❌ ERREUR: Exception: $e');
  }
  
  exit(0);
}
