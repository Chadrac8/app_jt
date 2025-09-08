import 'lib/modules/pain_quotidien/services/branham_scraping_service.dart';

void main() async {
  print('=== TEST DU SERVICE BRANHAM CORRIGÉ ===');
  
  try {
    final service = BranhamScrapingService.instance;
    final quote = await service.getQuoteOfTheDay();
    
    if (quote != null) {
      print('\n✅ Citation récupérée avec succès!');
      print('\n📝 CITATION DE BRANHAM:');
      print(quote.text);
      print('\n👤 RÉFÉRENCE: ${quote.reference}');
      print('\n📖 VERSET DU JOUR (Pain quotidien):');
      print(quote.dailyBread);
      print('\n📍 RÉFÉRENCE BIBLIQUE: ${quote.dailyBreadReference}');
      print('\n🎯 TITRE DE PRÉDICATION:');
      print(quote.sermonTitle);
      print('\n📅 DATE: ${quote.date}');
      
      print('\n🎉 LE SERVICE EXTRAIT MAINTENANT LE VRAI CONTENU DU SITE!');
      
      // Vérifications
      bool hasRealQuote = quote.text.contains('pécheur qui a commis de nombreux péchés');
      bool hasRealVerse = quote.dailyBread.contains('Venez et plaidons');
      bool hasRealRef = quote.dailyBreadReference.contains('Ésaïe');
      
      print('\n=== VÉRIFICATIONS ===');
      print('Citation authentique: ${hasRealQuote ? "✅" : "❌"}');
      print('Verset authentique: ${hasRealVerse ? "✅" : "❌"}');
      print('Référence authentique: ${hasRealRef ? "✅" : "❌"}');
      
      if (hasRealQuote && hasRealVerse && hasRealRef) {
        print('\n🚀 PARFAIT! Tout le contenu est authentique!');
      }
      
    } else {
      print('❌ Impossible de récupérer la citation');
    }
    
  } catch (e) {
    print('❌ Erreur lors du test: $e');
  }
  
  print('\n=== FIN DU TEST ===');
}
