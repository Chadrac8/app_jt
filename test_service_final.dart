import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;

void main() async {
  print('🔍 Service Branham - VERSION FINALE CORRIGÉE...');
  print('===============================================\n');
  
  try {
    const url = 'https://branham.org/fr/quoteoftheday';
    print('📡 Récupération depuis: $url');
    
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'fr-FR,fr;q=0.9,en;q=0.8',
      }).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      print('✅ Site accessible, extraction ciblée...\n');
      
      final document = html_parser.parse(response.body);
      
      // EXTRACTION CIBLÉE ET PRÉCISE
      String dailyBread = '';
      String reference = '';
      
      // 1. Trouver la référence biblique d'abord
      final allElements = document.querySelectorAll('div, p, span');
      for (final element in allElements) {
        final text = element.text.trim();
        // Référence biblique exacte seule
        if (RegExp(r'^[1-3]?\s*[A-Za-zÀ-ÿ]+\s+\d+[.\:]\d+$').hasMatch(text) && 
            text.length < 20) {
          reference = text;
          print('📍 Référence trouvée: $reference');
          break;
        }
      }
      
      // 2. Trouver le verset qui correspond à cette référence
      for (final element in allElements) {
        final text = element.text.trim();
        
        // Chercher un texte qui ressemble à un verset biblique
        if (text.length > 80 && text.length < 500) {
          // Vérifier que c'est bien un verset biblique
          bool isBiblicalVerse = (
            text.contains('dit l\'Éternel') ||
            text.contains('Dieu') ||
            text.contains('Seigneur') ||
            text.contains('péchés') ||
            text.contains('cramoisi') ||
            text.contains('neige') ||
            text.contains('pourpre')
          );
          
          // Vérifier que ce n'est pas du contenu de navigation
          bool isNotNavigation = (
            !text.contains('VGR') &&
            !text.contains('English') &&
            !text.contains('Español') &&
            !text.contains('Français') &&
            !text.contains('Português') &&
            !text.contains('Connexion') &&
            !text.contains('Pain quotidien') &&
            !text.contains('Conference') &&
            !text.contains('DateTitre') &&
            !text.contains('Copyright')
          );
          
          if (isBiblicalVerse && isNotNavigation) {
            dailyBread = text.replaceAll(RegExp(r'\s+'), ' ').trim();
            print('📖 Verset trouvé: ${dailyBread.substring(0, 80)}...');
            break;
          }
        }
      }
      
      // 3. Si pas trouvé, utiliser la méthode texte brut avec nettoyage
      if (dailyBread.isEmpty) {
        print('🔍 Méthode fallback: recherche dans le texte brut...');
        final bodyText = document.body?.text ?? '';
        
        if (bodyText.contains('Pain quotidien') && reference.isNotEmpty) {
          final painIndex = bodyText.indexOf('Pain quotidien');
          final afterPain = bodyText.substring(painIndex + 'Pain quotidien'.length);
          
          // Chercher le texte entre la référence et "Aujourd'hui"
          if (afterPain.contains(reference) && afterPain.contains('Aujourd\'hui')) {
            final refIndex = afterPain.indexOf(reference);
            final afterRef = afterPain.substring(refIndex + reference.length);
            final aujourdIndex = afterRef.indexOf('Aujourd\'hui');
            
            if (aujourdIndex != -1) {
              final verseText = afterRef.substring(0, aujourdIndex);
              dailyBread = verseText
                  .replaceAll(RegExp(r'\s+'), ' ')
                  .trim();
              print('📖 Verset trouvé en fallback: ${dailyBread.substring(0, 80)}...');
            }
          }
        }
      }
      
      // 4. Extraire prédication et audio
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
              break;
            }
          }
        }
      }
      
      final audioLinks = document.querySelectorAll('a[href*=".m4a"]');
      if (audioLinks.isNotEmpty) {
        audioUrl = audioLinks.first.attributes['href'] ?? '';
        if (audioUrl.isNotEmpty && !audioUrl.startsWith('http')) {
          audioUrl = 'https://branham.org$audioUrl';
        }
      }
      
      // 5. RÉSULTAT FINAL
      print('\n📋 DONNÉES EXTRAITES:');
      print('=====================');
      print('✅ Référence: "$reference"');
      print('✅ Pain quotidien: "${dailyBread.isNotEmpty ? dailyBread.substring(0, dailyBread.length > 100 ? 100 : dailyBread.length) : 'Vide'}..."');
      print('✅ Prédication: "$sermonTitle"');
      print('✅ Audio disponible: ${audioUrl.isNotEmpty ? 'Oui' : 'Non'}');
      
      if (dailyBread.isNotEmpty && reference.isNotEmpty) {
        print('\n🎉 SUCCÈS TOTAL !');
        print('\n📖 PAIN QUOTIDIEN COMPLET:');
        print('Reference: $reference');
        print('Verset: "$dailyBread"');
        
        // Données pour l'application
        final result = {
          'dailyBread': dailyBread,
          'reference': reference,
          'citation': dailyBread, // Le verset sert aussi de citation
          'sermonTitle': sermonTitle,
          'audioUrl': audioUrl,
          'error': false,
        };
        
        print('\n📊 DONNÉES POUR L\'APPLICATION:');
        print('==============================');
        print(json.encode(result));
        
      } else {
        print('\n⚠️ PROBLÈME: Données incomplètes');
        print('Référence: ${reference.isNotEmpty ? 'OK' : 'MANQUANTE'}');
        print('Pain quotidien: ${dailyBread.isNotEmpty ? 'OK' : 'MANQUANT'}');
      }
      
    } else {
      print('❌ ERREUR HTTP: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ ERREUR: $e');
  }
  
  exit(0);
}
