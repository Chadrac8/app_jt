// Script de débogage pour diagnostiquer le problème du dashboard
import 'package:firebase_core/firebase_core.dart';
import 'lib/auth/auth_service.dart';
import 'lib/services/dashboard_firebase_service.dart';
import 'lib/models/dashboard_widget_model.dart';

void main() async {
  print('🔍 Démarrage du diagnostic du dashboard...');
  
  try {
    // Initialiser Firebase
    print('📱 Initialisation de Firebase...');
    await Firebase.initializeApp();
    print('✅ Firebase initialisé');
    
    // Vérifier l'état de l'authentification
    print('🔐 Vérification de l\'authentification...');
    final currentUser = AuthService.currentUser;
    if (currentUser == null) {
      print('❌ Aucun utilisateur connecté');
      print('Solution: Connectez-vous d\'abord');
      return;
    }
    
    print('✅ Utilisateur connecté: ${currentUser.email}');
    print('   UID: ${currentUser.uid}');
    
    // Vérifier si l'utilisateur a des widgets configurés
    print('📊 Vérification des widgets configurés...');
    final hasWidgets = await DashboardFirebaseService.hasConfiguredWidgets();
    print('   Widgets configurés: $hasWidgets');
    
    if (!hasWidgets) {
      print('🔧 Initialisation des widgets par défaut...');
      await DashboardFirebaseService.initializeDefaultWidgets();
      print('✅ Widgets par défaut créés');
    }
    
    // Récupérer et afficher les widgets
    print('📋 Récupération des widgets...');
    final widgets = await DashboardFirebaseService.getDashboardWidgets();
    print('   Nombre de widgets: ${widgets.length}');
    
    if (widgets.isEmpty) {
      print('❌ Aucun widget trouvé');
      print('🔧 Tentative de création manuelle des widgets par défaut...');
      
      // Créer manuellement les widgets par défaut
      final defaultWidgets = DefaultDashboardWidgets.getDefaultWidgets();
      print('   Widgets par défaut disponibles: ${defaultWidgets.length}');
      
      for (final widget in defaultWidgets) {
        print('   - ${widget.title} (${widget.type})');
      }
      
    } else {
      print('✅ Widgets trouvés:');
      for (final widget in widgets) {
        print('   - ${widget.title} (${widget.type}) - Visible: ${widget.isVisible}');
      }
    }
    
    // Vérifier les préférences
    print('⚙️ Vérification des préférences...');
    final preferences = await DashboardFirebaseService.getDashboardPreferences();
    print('   Préférences: $preferences');
    
    print('🎉 Diagnostic terminé avec succès!');
    
  } catch (e, stackTrace) {
    print('❌ Erreur pendant le diagnostic: $e');
    print('📄 Stack trace: $stackTrace');
  }
}
