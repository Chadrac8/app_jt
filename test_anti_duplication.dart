import 'package:flutter/material.dart';
import 'lib/modules/pain_quotidien/services/branham_scraping_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('=== TEST ANTI-DUPLICATION VERSET/CITATION ===');
  
  final service = BranhamScrapingService.instance;
  
  try {
    print('🚀 Test du service corrigé...');
    final quote = await service.getQuoteOfTheDay();
    
    if (quote != null) {
      print('\n✅ CITATION RÉCUPÉRÉE!');
      print('═══════════════════════════════════════');
      
      print('\n📖 PAIN QUOTIDIEN (Verset biblique):');
      print('Référence: ${quote.dailyBreadReference}');
      print('Texte: ${quote.dailyBread}');
      
      print('\n💬 CITATION DU JOUR (Branham):');
      print('Texte: ${quote.text}');
      print('Prédication: ${quote.sermonTitle}');
      
      print('\n🔍 VÉRIFICATION ANTI-DUPLICATION:');
      
      // Vérifier si les contenus sont identiques
      bool identical = quote.dailyBread.trim() == quote.text.trim();
      
      if (identical) {
        print('❌ PROBLÈME: Le verset et la citation sont identiques!');
        print('Contenu dupliqué: ${quote.dailyBread.substring(0, 50)}...');
      } else {
        print('✅ SUCCÈS: Le verset et la citation sont différents!');
        print('Verset: ${quote.dailyBread.substring(0, 30)}...');
        print('Citation: ${quote.text.substring(0, 30)}...');
      }
      
      print('\n📊 LONGUEURS:');
      print('Verset: ${quote.dailyBread.length} caractères');
      print('Citation: ${quote.text.length} caractères');
      
      print('\n🎯 RÉSULTAT:');
      if (!identical) {
        print('🎉 CORRECTION RÉUSSIE!');
        print('L\'application affichera maintenant:');
        print('- Un verset biblique dans la section "Pain Quotidien"');
        print('- Une citation différente de Branham dans "Citation du Jour"');
      } else {
        print('⚠️ Le problème persiste - vérifiez l\'extraction');
      }
      
    } else {
      print('\n❌ ERREUR: Aucune citation récupérée');
    }
    
  } catch (e) {
    print('\n💥 ERREUR: $e');
  }
  
  print('\n═══════════════════════════════════════');
}
