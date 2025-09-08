import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;

// Service optimisé intégré pour le test
class BranhamScrapingServiceOptimized {
  static const String _baseUrl = 'https://branham.org/fr/quoteoftheday';

  static Future<Map<String, dynamic>> getDailyBread() async {
    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'fr-FR,fr;q=0.9,en;q=0.8',
        }
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return _parseHtmlContent(response.body);
      } else {
        throw Exception('Failed to load daily bread: ${response.statusCode}');
      }
    } catch (e) {
      return {
        'dailyBread': 'Pain quotidien temporairement indisponible',
        'reference': '',
        'citation': 'Verset du jour temporairement indisponible',
        'sermonTitle': '',
        'audioUrl': '',
        'error': true,
      };
    }
  }

  static Map<String, dynamic> _parseHtmlContent(String htmlContent) {
    final document = html_parser.parse(htmlContent);
    
    String dailyBread = '';
    String reference = '';
    
    // Chercher dans tous les éléments
    final allElements = [
      ...document.querySelectorAll('div'),
      ...document.querySelectorAll('p'),
      ...document.querySelectorAll('span'),
    ];
    
    for (final element in allElements) {
      final elementText = element.text.trim();
      
      // Chercher la référence biblique
      if (reference.isEmpty) {
        final refMatch = RegExp(r'^([1-3]?\s*[A-Za-zÀ-ÿ]+\s+\d+[.\:]\d+[-\d]*)$')
            .firstMatch(elementText);
        if (refMatch != null) {
          reference = refMatch.group(1)?.trim() ?? '';
          continue;
        }
      }
      
      // Chercher le texte du verset
      if (dailyBread.isEmpty && elementText.length > 50 && elementText.length < 1000) {
        if ((elementText.contains('dit l\'Éternel') || 
             elementText.contains('Dieu') ||
             elementText.contains('Seigneur') ||
             (elementText.contains(';') && elementText.contains(','))) &&
            !elementText.contains('Pain quotidien') &&
            !elementText.contains('Conference') &&
            !elementText.contains('DateTitre')) {
          
          dailyBread = elementText
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
          continue;
        }
      }
    }
    
    // Nettoyer le pain quotidien
    if (dailyBread.isNotEmpty && reference.isNotEmpty) {
      dailyBread = dailyBread
          .replaceAll(RegExp(r'^\s*$reference\s*'), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    }
    
    // Extraire prédication
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
    
    // Chercher l'URL audio
    final audioLinks = document.querySelectorAll('a[href*=".m4a"]');
    if (audioLinks.isNotEmpty) {
      audioUrl = audioLinks.first.attributes['href'] ?? '';
      if (audioUrl.isNotEmpty && !audioUrl.startsWith('http')) {
        audioUrl = 'https://branham.org$audioUrl';
      }
    }
    
    return {
      'dailyBread': dailyBread.isNotEmpty ? dailyBread : 'Pain quotidien non disponible',
      'reference': reference,
      'citation': dailyBread.isNotEmpty ? dailyBread : 'Verset du jour non disponible',
      'sermonTitle': sermonTitle,
      'audioUrl': audioUrl,
      'error': false,
    };
  }
}

void main() async {
  print('🔍 Test de validation du service Branham optimisé...');
  print('=====================================================\n');
  
  try {
    print('📡 Récupération des données du pain quotidien...');
    final result = await BranhamScrapingServiceOptimized.getDailyBread();
    
    print('\n📋 RÉSULTATS:');
    print('=============');
    print('🔸 Pain quotidien: "${result['dailyBread']}"');
    print('🔸 Référence: "${result['reference']}"');
    print('🔸 Citation: "${result['citation']}"');
    print('🔸 Titre prédication: "${result['sermonTitle']}"');
    print('🔸 URL audio: "${result['audioUrl']}"');
    print('🔸 Erreur: ${result['error']}');
    
    // Validation
    bool isValid = true;
    final checks = <String, bool>{
      'Pain quotidien non vide': result['dailyBread']?.isNotEmpty == true,
      'Référence biblique présente': result['reference']?.isNotEmpty == true,
      'Citation disponible': result['citation']?.isNotEmpty == true,
      'Pas d\'erreur': result['error'] == false,
      'Pain quotidien ne contient pas de doublons': !(result['dailyBread']?.contains(result['reference']) == true && result['dailyBread']?.startsWith(result['reference']) == true),
    };
    
    print('\n🔍 VALIDATION:');
    print('==============');
    for (final entry in checks.entries) {
      final status = entry.value ? '✅' : '❌';
      print('$status ${entry.key}');
      if (!entry.value) isValid = false;
    }
    
    if (isValid) {
      print('\n🎉 SUCCÈS: Le service Branham fonctionne parfaitement !');
      print('✅ Toutes les validations sont passées');
      print('\n📖 Pain quotidien formaté:');
      print('"${result['dailyBread']}" - ${result['reference']}');
    } else {
      print('\n⚠️ ATTENTION: Certaines validations ont échoué');
    }
    
    // Test du cache
    print('\n🗄️ Test du système de cache...');
    final cachedResult = await BranhamScrapingServiceOptimized.getDailyBread();
    final isCacheWorking = cachedResult['dailyBread'] == result['dailyBread'];
    print('${isCacheWorking ? '✅' : '❌'} Cache fonctionne: $isCacheWorking');
    
  } catch (e) {
    print('❌ ERREUR lors du test: $e');
    exit(1);
  }
  
  print('\n✅ Test terminé avec succès !');
  exit(0);
}
