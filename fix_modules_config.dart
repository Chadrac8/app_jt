// Script pour corriger la configuration des modules
import 'package:flutter/material.dart';
import 'lib/services/app_config_firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('=== Correction de la configuration des modules ===');
  
  try {
    // Récupérer la configuration actuelle
    final currentConfig = await AppConfigFirebaseService.getAppConfig();
    print('Configuration actuelle récupérée');
    print('Modules actuels: ${currentConfig.modules.length}');
    
    // Modules à ajouter/modifier
    final modulesToAdd = [
      {
        'id': 'groups',
        'name': 'Mes Groupes',
        'isPrimaryInBottomNav': true,
        'isEnabledForMembers': true,
        'order': 1,
      },
      {
        'id': 'events', 
        'name': 'Événements',
        'isPrimaryInBottomNav': true,
        'isEnabledForMembers': true,
        'order': 2,
      },
      {
        'id': 'prayers',
        'name': 'Mur de Prière', 
        'isPrimaryInBottomNav': true,
        'isEnabledForMembers': true,
        'order': 4,
      },
      {
        'id': 'reports',
        'name': 'Rapports',
        'isPrimaryInBottomNav': true, 
        'isEnabledForMembers': true,
        'order': 5,
      },
      {
        'id': 'dons',
        'name': 'Dons',
        'isPrimaryInBottomNav': true,
        'isEnabledForMembers': true, 
        'order': 6,
      },
    ];
    
    // Mettre à jour chaque module
    for (final moduleInfo in modulesToAdd) {
      print('Mise à jour du module: ${moduleInfo['name']}');
      
      await AppConfigFirebaseService.updateModuleConfig(
        moduleInfo['id'] as String,
        isPrimaryInBottomNav: moduleInfo['isPrimaryInBottomNav'] as bool,
        isEnabledForMembers: moduleInfo['isEnabledForMembers'] as bool,
        order: moduleInfo['order'] as int,
      );
      
      print('✅ Module ${moduleInfo['name']} mis à jour');
    }
    
    print('\n=== Configuration corrigée avec succès ===');
    
    // Vérifier la nouvelle configuration  
    final updatedConfig = await AppConfigFirebaseService.getAppConfig();
    print('Modules primaires après mise à jour:');
    final primaryModules = updatedConfig.primaryBottomNavModules;
    for (int i = 0; i < primaryModules.length; i++) {
      final module = primaryModules[i];
      print('  ${i + 1}. ${module.name} (${module.id}) - ordre: ${module.order}');
    }
    
  } catch (e) {
    print('❌ Erreur lors de la correction: $e');
  }
}
