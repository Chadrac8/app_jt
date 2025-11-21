import '../services/app_config_firebase_service.dart';

/// Utilitaire pour forcer la mise à jour de la configuration avec les nouveaux modules
class ConfigUpdater {
  
  /// Force la mise à jour de la configuration avec les nouveaux modules
  static Future<void> forceUpdateConfig() async {
    try {
      print('🔄 Début de la mise à jour forcée de la configuration...');
      
      // Appel de la méthode d'initialisation qui va détecter et ajouter les nouveaux modules
      await AppConfigFirebaseService.initializeDefaultConfig();
      
      print('✅ Configuration mise à jour avec succès !');
      print('📱 Les modules "Pour vous" et "Ressources" sont maintenant disponibles');
      
    } catch (e) {
      print('❌ Erreur lors de la mise à jour: $e');
      rethrow;
    }
  }
  
  /// Vérifie si les nouveaux modules sont présents dans la configuration
  /// Vérifier si les modules sont présents (plus pertinent après suppression)
  static Future<bool> checkNewModulesPresent() async {
    try {
      final config = await AppConfigFirebaseService.getAppConfig();
      final moduleIds = config.modules.map((m) => m.id).toSet();
      
      // Les modules "pour_vous", "ressources" et "dons" ont été supprimés
      final hasRemovedModules = !moduleIds.contains('pour_vous') && 
                               !moduleIds.contains('ressources') && 
                               !moduleIds.contains('dons');
      
      print('🔍 Vérification des modules supprimés:');
      print('  - Pour vous: ${!moduleIds.contains('pour_vous') ? '✅ Supprimé' : '❌ Présent'}');
      print('  - Ressources: ${!moduleIds.contains('ressources') ? '✅ Supprimé' : '❌ Présent'}');
      print('  - Dons: ${!moduleIds.contains('dons') ? '✅ Supprimé' : '❌ Présent'}');
      
      return hasRemovedModules;
    } catch (e) {
      print('❌ Erreur lors de la vérification: $e');
      return false;
    }
  }
  
  /// Affiche la liste complète des modules configurés
  static Future<void> listAllModules() async {
    try {
      final config = await AppConfigFirebaseService.getAppConfig();
      
      print('📋 Modules configurés (${config.modules.length}):');
      for (final module in config.modules) {
        print('  - ${module.name} (${module.id}) - ${module.isEnabledForMembers ? "✅" : "❌"}');
      }
    } catch (e) {
      print('❌ Erreur lors de la récupération des modules: $e');
    }
  }
}
