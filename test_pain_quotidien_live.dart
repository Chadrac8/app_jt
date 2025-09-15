import 'lib/modules/pain_quotidien/services/branham_scraping_service.dart';

void main() async {
  print('🔍 Test du service de scraping du pain quotidien');
  print('=' * 60);
  
  final service = BranhamScrapingService.instance;
  
  try {
    print('📡 Récupération du contenu en cours...');
    final quote = await service.getQuoteOfTheDay();
    
    if (quote != null) {
      print('✅ Contenu récupéré avec succès!\n');
      
      print('📅 Date: ${quote.date}');
      print('📖 Pain quotidien: ${quote.dailyBread}');
      print('📍 Référence: ${quote.dailyBreadReference}');
      print('💬 Citation: ${quote.text}');
      print('📚 Source: ${quote.reference}');
      
      if (quote.sermonTitle.isNotEmpty) {
        print('🎯 Prédication: ${quote.sermonTitle}');
      }
      
      // Vérification des caractères français
      print('\n🔍 Vérification de l\'encodage:');
      String allText = '${quote.dailyBread} ${quote.text}';
      
      List<String> problematicChars = [
        '&eacute;', '&egrave;', '&ecirc;', '&agrave;', '&ocirc;',
        'Ã©', 'Ã¨', 'Ã ', 'â€™', '&rsquo;', '&nbsp;'
      ];
      
      bool hasIssues = false;
      for (String char in problematicChars) {
        if (allText.contains(char)) {
          print('❌ Caractère mal encodé trouvé: $char');
          hasIssues = true;
        }
      }
      
      if (!hasIssues) {
        print('✅ Aucun problème d\'encodage détecté!');
      }
      
    } else {
      print('❌ Aucun contenu récupéré');
    }
    
  } catch (e) {
    print('❌ Erreur: $e');
  }
}
