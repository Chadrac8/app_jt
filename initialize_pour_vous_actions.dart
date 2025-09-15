import 'package:firebase_core/firebase_core.dart';
import 'lib/modules/vie_eglise/services/pour_vous_action_service.dart';
import 'lib/firebase_options.dart';

/// Script pour initialiser les actions "Pour vous" par défaut
void main() async {
  try {
    print('🚀 Initialisation Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialisé');

    print('📝 Initialisation des actions "Pour vous"...');
    final service = PourVousActionService();
    
    // Vérifier et créer les actions par défaut si nécessaire
    await service.ensureDefaultActionsExist();
    
    // Récupérer les statistiques
    final stats = await service.getActionsStats();
    print('📊 Statistiques des actions:');
    print('  - Total: ${stats['total']}');
    print('  - Actives: ${stats['active']}');
    print('  - Inactives: ${stats['inactive']}');
    
    print('✅ Initialisation terminée avec succès');
  } catch (e) {
    print('❌ Erreur lors de l\'initialisation: $e');
  }
}