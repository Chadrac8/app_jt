import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;

void main() async {
  print('🔍 DEBUG: Analyse détaillée de l\'extraction Branham');
  print('=' * 60);
  
  try {
    final response = await http.get(
      Uri.parse('https://branham.org/fr/quoteoftheday'),
      headers: {
        'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'fr-FR,fr;q=0.9,en;q=0.8',
      }).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      print('✅ Page récupérée avec succès');
      
      final document = html_parser.parse(response.body);
      final allElements = document.querySelectorAll('div, p, span, td, th');
      
      // 1. RECHERCHE DU VERSET BIBLIQUE
      print('\n📖 1. RECHERCHE DU VERSET BIBLIQUE:');
      print('-' * 40);
      
      String dailyBreadRef = '';
      String dailyBread = '';
      
      // Chercher la référence biblique
      for (final element in allElements) {
        final text = element.text.trim();
        if (RegExp(r'^[1-3]?\s*[A-Za-zÀ-ÿ]+\s+\d+[.\:]\d+$').hasMatch(text) && text.length < 20) {
          dailyBreadRef = text;
          print('📍 Référence trouvée: "$dailyBreadRef"');
          break;
        }
      }
      
      // Chercher le verset correspondant
      for (final element in allElements) {
        final text = element.text.trim();
        if (text.length > 80 && text.length < 500) {
          bool isBiblicalVerse = (
            text.contains('dit l\'Éternel') ||
            text.contains('Dieu') ||
            text.contains('Seigneur') ||
            text.contains('péchés') ||
            text.contains('cramoisi') ||
            text.contains('neige') ||
            text.contains('pourpre')
          );
          
          if (isBiblicalVerse) {
            dailyBread = text.replaceAll(RegExp(r'\s+'), ' ').trim();
            print('📜 Verset trouvé: "${dailyBread.substring(0, 100)}..."');
            print('   Longueur: ${dailyBread.length} caractères');
            break;
          }
        }
      }
      
      // 2. RECHERCHE DE LA CITATION DE BRANHAM
      print('\n💬 2. RECHERCHE DE LA CITATION DE BRANHAM:');
      print('-' * 40);
      
      String quoteText = '';
      List<String> candidats = [];
      
      // Analyser tous les textes possibles
      for (final element in allElements) {
        final text = element.text.trim();
        if (text.length > 300 && text.length < 2000) {
          
          // Vérifier si c'est une citation de Branham
          bool isBranhamQuote = (
            text.contains('Vous êtes') ||
            text.contains('pécheur') ||
            text.contains('Peut-être') ||
            text.contains('Dieu') ||
            text.contains('mais vous ne pouvez') ||
            text.contains('contre nature') ||
            text.contains('conférence') ||
            text.contains('peu importe')
          );
          
          // Vérifier que ce n'est pas du contenu de navigation ou le verset
          bool isNotNavigation = (
            !text.contains('VGR') &&
            !text.contains('English') &&
            !text.contains('dit l\'Éternel') &&
            !text.contains('cramoisi') &&
            !text.contains('neige') &&
            !text.contains('pourpre') &&
            !text.contains('Copyright')
          );
          
          if (isBranhamQuote && isNotNavigation) {
            candidats.add(text);
            print('🎯 Candidat ${candidats.length}: "${text.substring(0, 150)}..."');
            print('   Longueur: ${text.length} caractères');
            print('   Élément: ${element.localName}');
            
            if (quoteText.isEmpty) {
              quoteText = text.replaceAll(RegExp(r'\s+'), ' ').trim();
            }
          }
        }
      }
      
      print('\n📊 RÉSUMÉ CANDIDATS:');
      print('   Nombre de candidats trouvés: ${candidats.length}');
      
      if (candidats.isEmpty) {
        print('❌ Aucune citation de Branham trouvée');
        
        print('\n🔍 RECHERCHE ÉLARGIE - Tous les textes longs:');
        for (final element in allElements) {
          final text = element.text.trim();
          if (text.length > 200 && text.length < 2000) {
            print('📄 Texte long: "${text.substring(0, 200)}..."');
            print('   Longueur: ${text.length} caractères, Élément: ${element.localName}');
            print('   Contient "Vous êtes": ${text.contains('Vous êtes')}');
            print('   Contient "pécheur": ${text.contains('pécheur')}');
            print('   Contient "dit l\'Éternel": ${text.contains('dit l\'Éternel')}');
            print('   ----');
          }
        }
      }
      
      // 3. RECHERCHE DES MÉTADONNÉES
      print('\n🎙️ 3. RECHERCHE DES MÉTADONNÉES:');
      print('-' * 40);
      
      // Code de prédication
      final bodyText = document.body?.text ?? '';
      final codeMatches = RegExp(r'\b(\d{2}-\d{4}[A-Z]?)\b').allMatches(bodyText);
      String sermonCode = '';
      if (codeMatches.isNotEmpty) {
        sermonCode = codeMatches.first.group(1) ?? '';
        print('📅 Code de prédication: "$sermonCode"');
      }
      
      // Titre de prédication
      String sermonTitle = '';
      for (final element in allElements) {
        final text = element.text.trim();
        if (text.length > 10 && text.length < 100 && 
            (text.contains('conférence') || text.contains('Une ') || text.contains('avec'))) {
          bool isTitle = (
            !text.contains('VGR') &&
            !text.contains('Copyright') &&
            text.split(' ').length <= 8
          );
          
          if (isTitle) {
            sermonTitle = text.trim();
            print('📖 Titre de prédication: "$sermonTitle"');
            break;
          }
        }
      }
      
      // 4. RÉSULTAT FINAL
      print('\n🎯 4. RÉSULTAT FINAL:');
      print('-' * 40);
      print('Verset (${dailyBreadRef}): "${dailyBread.substring(0, dailyBread.length > 100 ? 100 : dailyBread.length)}..."');
      print('Citation de Branham: "${quoteText.substring(0, quoteText.length > 100 ? 100 : quoteText.length)}..."');
      print('Code: "$sermonCode"');
      print('Titre: "$sermonTitle"');
      
      // Test de comparaison
      if (quoteText == dailyBread) {
        print('❌ PROBLÈME: Citation et verset sont identiques!');
      } else if (quoteText.isNotEmpty) {
        print('✅ Citation et verset sont différents');
      } else {
        print('❌ PROBLÈME: Aucune citation extraite');
      }
      
    } else {
      print('❌ Erreur HTTP: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Erreur: $e');
  }
}
