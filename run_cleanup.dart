import 'package:firebase_core/firebase_core.dart';
import 'lib/services/app_config_firebase_service.dart';

/// Script simple pour nettoyer les modules orphelins
/// Usage: dart run run_cleanup.dart

void main() async {
  print('🚀 Initialisation de Firebase...');
  
  try {
    await Firebase.initializeApp();
    print('✅ Firebase initialisé');
    
    print('\n🗑️ Lancement du nettoyage des modules orphelins...');
    await AppConfigFirebaseService.cleanupOrphanModules();
    
    print('\n🎉 Nettoyage terminé avec succès!');
    print('💡 Les modules "Pour vous", "Ressources" et "Dons" ont été supprimés de Firebase.');
    print('🔄 Redémarrez l\'application pour voir les changements.');
    
  } catch (e) {
    print('❌ Erreur: $e');
  }
}
