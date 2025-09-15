import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service simplifié pour tester le pain quotidien
class SimpleBranhamTest {
  static const String _baseUrl = 'https://branham.org/fr/quoteoftheday';
  
  /// Test de récupération directe pour voir l'encodage
  static Future<void> testDirectFetch() async {
    print('🔍 Test de récupération directe du pain quotidien');
    print('=' * 60);
    
    try {
      print('📡 Récupération depuis: $_baseUrl');
      final response = await http.get(Uri.parse(_baseUrl));
      
      if (response.statusCode == 200) {
        print('✅ Réponse reçue (${response.statusCode})');
        print('📄 Content-Type: ${response.headers['content-type']}');
        
        // Analyser les premiers caractères pour voir l'encodage
        String content = response.body;
        print('\n🔍 Analyse de l\'encodage des premiers 500 caractères:');
        print('-' * 40);
        
        String preview = content.length > 500 ? content.substring(0, 500) : content;
        print(preview);
        
        print('\n🔍 Recherche de caractères problématiques:');
        List<String> problematicPatterns = [
          '&eacute;', '&egrave;', '&ecirc;', '&agrave;', '&ocirc;', '&rsquo;',
          'Ã©', 'Ã¨', 'Ã ', 'â€™', '&nbsp;'
        ];
        
        for (String pattern in problematicPatterns) {
          if (content.contains(pattern)) {
            print('❌ Trouvé: $pattern');
          }
        }
        
        // Chercher spécifiquement le contenu du pain quotidien
        print('\n🍞 Recherche du contenu du pain quotidien:');
        if (content.contains('pain-quotidien') || content.contains('daily-bread')) {
          print('✅ Section pain quotidien trouvée');
          
          // Extraire et analyser la section
          RegExp painQuotidienRegex = RegExp(r'<div[^>]*class="[^"]*pain-quotidien[^"]*"[^>]*>(.*?)</div>', 
              multiLine: true, dotAll: true);
          
          var match = painQuotidienRegex.firstMatch(content);
          if (match != null) {
            String painContent = match.group(1) ?? '';
            print('📝 Contenu brut:');
            print(painContent.length > 200 ? painContent.substring(0, 200) + '...' : painContent);
          }
        } else {
          print('⚠️  Section pain quotidien non trouvée avec ce pattern');
        }
        
      } else {
        print('❌ Erreur HTTP: ${response.statusCode}');
      }
      
    } catch (e) {
      print('❌ Erreur: $e');
    }
  }
}

void main() async {
  await SimpleBranhamTest.testDirectFetch();
}
