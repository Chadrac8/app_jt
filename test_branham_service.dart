import 'package:flutter/material.dart';
import 'lib/modules/pain_quotidien/services/branham_scraping_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🧪 Test du service de scraping Branham amélioré...');
  print('=' * 50);
  
  final service = BranhamScrapingService.instance;
  
  try {
    final quote = await service.getQuoteOfTheDay();
    
    if (quote != null) {
      print('✅ Citation récupérée avec succès !');
      print('');
      print('📅 Date: ${quote.date}');
      print('📖 Verset biblique (${quote.dailyBreadReference}):');
      print('   ${quote.dailyBread}');
      print('');
      print('💬 Citation de Branham:');
      print('   ${quote.text}');
      print('');
      print('🎙️ Prédication: ${quote.sermonTitle}');
      print('📂 Référence: ${quote.reference}');
      print('🎵 Audio: ${quote.audioUrl.isNotEmpty ? quote.audioUrl : 'Non disponible'}');
      print('');
      print('📏 Longueurs:');
      print('   - Verset: ${quote.dailyBread.length} caractères');
      print('   - Citation: ${quote.text.length} caractères');
      
      // Vérifier que la citation n'est pas le même texte que le verset
      if (quote.text != quote.dailyBread) {
        print('✅ Citation et verset sont différents (correct)');
      } else {
        print('❌ Citation et verset sont identiques (problème)');
      }
      
    } else {
      print('❌ Aucune citation récupérée');
    }
    
  } catch (e) {
    print('❌ Erreur lors du test: $e');
  }
}
