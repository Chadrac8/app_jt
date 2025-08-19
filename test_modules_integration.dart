import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'lib/modules/pour_vous/services/pour_vous_service.dart';
import 'lib/modules/ressources/services/ressources_service.dart';

void main() {
  group('Modules Test', () {
    test('Test Pour Vous Service initialization', () async {
      try {
        print('🔄 Test de l\'initialisation PourVousService...');
        await PourVousService.initializeDefaultActions();
        print('✅ PourVousService initialisé avec succès');
      } catch (e) {
        print('❌ Erreur PourVousService: $e');
      }
    });

    test('Test Ressources Service initialization', () async {
      try {
        print('🔄 Test de l\'initialisation RessourcesService...');
        await RessourcesService.initializeDefaultResources();
        print('✅ RessourcesService initialisé avec succès');
      } catch (e) {
        print('❌ Erreur RessourcesService: $e');
      }
    });

    test('Test streams availability', () async {
      try {
        print('🔄 Test des streams...');
        
        // Test PourVous stream
        final actionsStream = PourVousService.getActiveActionsStream();
        final actions = await actionsStream.first.timeout(Duration(seconds: 5));
        print('✅ Actions stream fonctionne: ${actions.length} actions trouvées');
        
        // Test Ressources stream
        final resourcesStream = RessourcesService.getActiveResourcesStream();
        final resources = await resourcesStream.first.timeout(Duration(seconds: 5));
        print('✅ Resources stream fonctionne: ${resources.length} ressources trouvées');
        
      } catch (e) {
        print('❌ Erreur streams: $e');
      }
    });
  });
}
