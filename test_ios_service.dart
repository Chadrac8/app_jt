import '../lib/modules/pain_quotidien/services/ios_branham_service.dart';

void main() async {
  print('=== TEST DU SERVICE iOS BRANHAM ===');
  
  try {
    final quote = await IOSBranhamService.getTodaysQuote();
    
    print('\n✅ Citation récupérée avec succès!');
    print('📝 Texte: ${quote.text}');
    print('👤 Référence: ${quote.reference}');
    print('📅 Date: ${quote.date}');
    print('📖 Pain quotidien: ${quote.dailyBread}');
    print('📍 Référence biblique: ${quote.dailyBreadReference}');
    
    print('\n🚀 Le service iOS fonctionne correctement!');
    
  } catch (e) {
    print('❌ Erreur lors du test: $e');
  }
  
  print('\n=== FIN DU TEST ===');
}
