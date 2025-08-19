// Script pour diagnostiquer et corriger le problème d'affichage de l'image de couverture
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'lib/services/app_config_firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
    print('✅ Firebase initialisé');
    
    // Récupérer la configuration actuelle
    final config = await AppConfigFirebaseService.getAppConfig();
    print('\n🔍 Configuration actuelle:');
    
    // Chercher le module ressources
    final ressourcesModule = config.modules.firstWhere(
      (m) => m.route == 'ressources',
      orElse: () => throw Exception('Module ressources non trouvé'),
    );
    
    print('📦 Module Ressources trouvé:');
    print('  - ID: ${ressourcesModule.id}');
    print('  - Name: ${ressourcesModule.name}');
    print('  - ShowCoverImage: ${ressourcesModule.showCoverImage}');
    print('  - CoverImageUrl: ${ressourcesModule.coverImageUrl ?? "NULL"}');
    
    if (!ressourcesModule.showCoverImage && ressourcesModule.coverImageUrl == null) {
      print('\n⚠️  Problème détecté: Le module n\'a pas d\'image de couverture configurée');
      print('   Solutions:');
      print('   1. Aller dans Admin → Ressources → Configuration');
      print('   2. Activer "Afficher l\'image de couverture"');
      print('   3. Sélectionner une image');
      print('   4. Sauvegarder');
    } else if (ressourcesModule.showCoverImage && ressourcesModule.coverImageUrl != null) {
      print('\n✅ Configuration correcte - l\'image devrait s\'afficher');
    } else if (ressourcesModule.showCoverImage && ressourcesModule.coverImageUrl == null) {
      print('\n⚠️  Problème: showCoverImage=true mais pas d\'URL d\'image');
    }
    
  } catch (e) {
    print('❌ Erreur: $e');
  }
}
