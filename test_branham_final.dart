import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;

void main() async {
  print('🔍 Test final du service Branham CORRIGÉ...');
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
      }).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      print('✅ Site accessible, parsing corrigé du contenu...\n');
      
      final document = html_parser.parse(response.body);
      final bodyText = document.body?.text ?? '';
      
      // EXTRACTION AMÉLIORÉE DU PAIN QUOTIDIEN
      String dailyBread = '';
      String reference = '';
      
      // Méthode 1: Chercher dans les éléments HTML spécifiques
      final divs = document.querySelectorAll('div');
      for (final div in divs) {
        final divText = div.text.trim();
        
        // Chercher la référence biblique (ex: Ésaïe 1.18)
        if (reference.isEmpty) {
          final refMatch = RegExp(r'^([1-3]?\s*[A-Za-zÀ-ÿ]+\s+\d+[.\:]\d+[-\d]*)$')
              .firstMatch(divText);
          if (refMatch != null) {
            reference = refMatch.group(1)?.trim() ?? '';
            print('📍 Référence trouvée dans DIV: $reference');
            continue;
          }
        }
        
        // Chercher le texte du verset (phrases bibliques)
        if (dailyBread.isEmpty && divText.length > 50 && divText.length < 500) {
          if (divText.contains('dit l\'Éternel') || 
              divText.contains('Dieu') ||
              divText.contains('Seigneur') ||
              (divText.contains(';') && divText.contains(','))) {
            dailyBread = divText;
            print('📖 Pain quotidien trouvé dans DIV: ${dailyBread.substring(0, 80)}...');
            continue;
          }
        }
      }
      
      // Méthode 2: Si pas trouvé dans les divs, chercher dans les paragraphes
      if (dailyBread.isEmpty || reference.isEmpty) {
        final paragraphs = document.querySelectorAll('p');
        for (final p in paragraphs) {
          final pText = p.text.trim();
          
          if (reference.isEmpty) {
            final refMatch = RegExp(r'^([1-3]?\s*[A-Za-zÀ-ÿ]+\s+\d+[.\:]\d+[-\d]*)$')
                .firstMatch(pText);
            if (refMatch != null) {
              reference = refMatch.group(1)?.trim() ?? '';
              print('📍 Référence trouvée dans P: $reference');
              continue;
            }
          }
          
          if (dailyBread.isEmpty && pText.length > 50 && pText.length < 500) {
            if (pText.contains('dit l\'Éternel') || 
                pText.contains('Dieu') ||
                pText.contains('Seigneur') ||
                (pText.contains(';') && pText.contains(','))) {
              dailyBread = pText;
              print('📖 Pain quotidien trouvé dans P: ${dailyBread.substring(0, 80)}...');
              continue;
            }
          }
        }
      }
      
      // Méthode 3: Fallback avec la méthode texte original si nécessaire
      if (dailyBread.isEmpty && bodyText.contains('Pain quotidien')) {
        print('🔍 Fallback: recherche dans le texte brut...');
        final painIndex = bodyText.indexOf('Pain quotidien');
        final painSection = bodyText.substring(painIndex, 
            painIndex + 1000 < bodyText.length ? painIndex + 1000 : bodyText.length);
        
        if (reference.isEmpty) {
          final refMatch = RegExp(r'([1-3]?\s*[A-Za-zÀ-ÿ]+\s+\d+[.\:]\d+[-\d]*)')
              .firstMatch(painSection);
          if (refMatch != null) {
            reference = refMatch.group(1)?.trim() ?? '';
            print('📍 Référence trouvée en fallback: $reference');
          }
        }
        
        if (reference.isNotEmpty) {
          final refIndex = painSection.indexOf(reference);
          final afterRef = painSection.substring(refIndex + reference.length);
          final aujourdIndex = afterRef.indexOf('Aujourd\'hui');
          
          if (aujourdIndex != -1) {
            final verseText = afterRef.substring(0, aujourdIndex);
            dailyBread = verseText
                .replaceAll(RegExp(r'\s+'), ' ')
                .trim();
            print('📖 Pain quotidien trouvé en fallback: ${dailyBread.substring(0, 80)}...');
          }
        }
      }
      
      // Pour la citation, utiliser le verset biblique comme citation du jour
      String citation = dailyBread.isNotEmpty ? dailyBread : '';
      
      // EXTRAIRE INFO PRÉDICATION
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
      
      // RÉSUMÉ FINAL
      print('\n📋 RÉSUMÉ FINAL CORRIGÉ:');
      print('========================');
      print('✅ Pain quotidien récupéré: ${dailyBread.isNotEmpty ? 'OUI' : 'NON'}');
      print('✅ Référence biblique: ${reference.isNotEmpty ? reference : 'Non trouvée'}');
      print('✅ Citation (= verset): ${citation.isNotEmpty ? 'OUI' : 'NON'}');
      print('✅ Titre prédication: ${sermonTitle.isNotEmpty ? 'OUI' : 'NON'}');
      print('✅ URL audio: ${audioUrl.isNotEmpty ? 'OUI' : 'NON'}');
      
      if (dailyBread.isNotEmpty && reference.isNotEmpty) {
        print('\n🎉 SUCCÈS: Service fonctionnel !');
        print('\n📖 Pain quotidien complet:');
        print('"$dailyBread" - $reference');
        print('\n💬 Citation du jour (verset biblique):');
        print('"$citation"');
        if (sermonTitle.isNotEmpty) {
          print('\n🎵 Prédication: $sermonTitle');
        }
        
        print('\n📊 DONNÉES À RETOURNER:');
        print('========================');
        print('dailyBread: "$dailyBread"');
        print('reference: "$reference"');
        print('citation: "$citation"');
        print('sermonTitle: "$sermonTitle"');
        print('audioUrl: "$audioUrl"');
        print('error: false');
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
