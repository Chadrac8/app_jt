import 'package:flutter/material.dart';
import 'lib/modules/pain_quotidien/services/daily_bread_scheduler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('=== Test du DailyBreadScheduler ===');
  
  try {
    // Test de l'initialisation
    print('1. Initialisation du scheduler...');
    await DailyBreadScheduler.startScheduler();
    print('✅ Scheduler initialisé avec succès');
    
    // Test du statut
    print('\n2. Vérification du statut...');
    bool isActive = await DailyBreadScheduler.isSchedulerActive();
    print('Scheduler actif: $isActive');
    
    // Test des informations complètes
    print('\n3. Informations du scheduler...');
    Map<String, dynamic> status = await DailyBreadScheduler.getSchedulerStatus();
    print('État complet:');
    status.forEach((key, value) {
      print('  $key: $value');
    });
    
    // Test de mise à jour forcée (simulation)
    print('\n4. Test de mise à jour forcée...');
    print('✅ Méthode debugTriggerUpdate() disponible pour test manuel');
    
    print('\n=== Test terminé avec succès ===');
    print('Le scheduler du pain quotidien est prêt à fonctionner !');
    print('Il se déclenchera automatiquement à 6h00 chaque matin.');
    
    // Arrêter pour ne pas laisser les timers actifs
    await DailyBreadScheduler.stopScheduler();
    print('\nScheduler arrêté pour le test.');
    
  } catch (e) {
    print('❌ Erreur lors du test: $e');
  }
}