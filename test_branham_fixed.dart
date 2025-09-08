import 'dart:io';
import 'lib/modules/pain_quotidien/services/branham_scraping_service_fixed.dart';

void main() async {
  print('🔍 Test du service Branham corrigé...');
  print('=====================================\n');
  
  try {
    final service = BranhamScrapingServiceFixed.instance;
    final quote = await service.getQuoteOfTheDay();
    
    if (quote != null) {
      print('✅ SUCCESS: Citation récupérée avec succès !');
      print('=====================================');
      print('📅 Date: ${quote.date}');
      print('📖 Pain quotidien: ${quote.dailyBread}');
      print('📍 Référence biblique: ${quote.dailyBreadReference}');
      print('💬 Citation: ${quote.text}');
      print('🎵 Titre de la prédication: ${quote.sermonTitle}');
      print('📅 Date de la prédication: ${quote.sermonDate}');
      print('🔗 Audio URL: ${quote.audioUrl}');
      print('\n📋 Texte de partage complet:');
      print(quote.shareText);
    } else {
      print('❌ ERREUR: Impossible de récupérer la citation');
    }
  } catch (e) {
    print('❌ ERREUR: Exception attrapée: $e');
  }
  
  exit(0);
}
