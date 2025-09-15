import 'lib/modules/pain_quotidien/services/branham_scraping_service.dart';
import 'lib/services/encoding_fix_service.dart';

void main() async {
  print('🔧 Test forcé du pain quotidien sans cache');
  print('=' * 60);
  
  final service = BranhamScrapingService.instance;
  
  try {
    // Tester notre service d'encodage d'abord
    print('🧪 Test du service d\'encodage:');
    String testText = 'L&rsquo;&eacute;glise prie pour avoir la paix &agrave; No&euml;l';
    String corrected = EncodingFixService.fixEncoding(testText);
    print('   Avant: $testText');
    print('   Après: $corrected');
    
    print('\n📡 Récupération forcée depuis le web...');
    
    // Récupérer directement sans cache (nous accédons à une méthode privée via reflection si nécessaire)
    final quote = await service.getQuoteOfTheDay();
    
    if (quote != null) {
      print('\n✅ Citation récupérée!');
      print('📅 Date: ${quote.date}');
      print('📖 Pain quotidien: "${quote.dailyBread}"');
      print('📍 Référence: "${quote.dailyBreadReference}"');
      print('💬 Citation: "${quote.text}"');
      print('📚 Source: "${quote.reference}"');
      
      // Vérification d'encodage
      print('\n🔍 Vérification de l\'encodage:');
      String allText = '${quote.dailyBread} ${quote.text} ${quote.dailyBreadReference}';
      
      List<String> problematicChars = [
        '&eacute;', '&egrave;', '&ecirc;', '&agrave;', '&ocirc;',
        'Ã©', 'Ã¨', 'Ã ', 'â€™', '&rsquo;', '&nbsp;', '&ccedil;'
      ];
      
      bool hasIssues = false;
      for (String char in problematicChars) {
        if (allText.contains(char)) {
          print('❌ Problème d\'encodage: $char trouvé dans le texte');
          hasIssues = true;
        }
      }
      
      if (!hasIssues) {
        print('✅ Encodage correct! Aucun caractère mal encodé détecté.');
      } else {
        print('⚠️ Des problèmes d\'encodage persistent');
        
        // Tester la correction manuelle
        print('\n🔧 Test de correction manuelle:');
        String manualFix = EncodingFixService.fixEncoding(allText);
        print('Texte corrigé: $manualFix');
      }
      
    } else {
      print('❌ Impossible de récupérer la citation');
    }
    
  } catch (e) {
    print('❌ Erreur: $e');
    print('Stack trace: ${StackTrace.current}');
  }
}
