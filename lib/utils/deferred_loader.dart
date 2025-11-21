/// Configuration pour le lazy loading des modules
/// Utilise deferred loading pour réduire la taille initiale de l'app

// Modules lourds chargés en différé
library deferred_modules;

// Module Cantiques (songs) - Lourd avec base de données
import '../modules/songs/songs_module.dart' deferred as songs_module;

// Module Bible - Très lourd avec tous les livres
import '../modules/bible/bible_module.dart' deferred as bible_module;

// Module Messages Branham - Lourd avec scraping
import '../modules/message/message_module.dart' deferred as message_module;

// Module Vie Eglise - Lourd avec médias
import '../modules/vie_eglise/vie_eglise_module.dart' deferred as vie_eglise_module;

// Module Offrandes - Moins utilisé
import '../modules/offrandes/offrandes_module.dart' deferred as offrandes_module;

// Module Rôles - Admin only
import '../modules/roles/roles_module.dart' deferred as roles_module;

/// Helper pour charger un module avec indicateur
class DeferredLoader {
  static final Map<String, bool> _loadedModules = {};
  
  /// Charger le module Cantiques
  static Future<bool> loadSongsModule() async {
    if (_loadedModules['songs'] == true) return true;
    
    try {
      await songs_module.loadLibrary();
      _loadedModules['songs'] = true;
      return true;
    } catch (e) {
      print('❌ Erreur chargement module Cantiques: $e');
      return false;
    }
  }
  
  /// Charger le module Bible
  static Future<bool> loadBibleModule() async {
    if (_loadedModules['bible'] == true) return true;
    
    try {
      await bible_module.loadLibrary();
      _loadedModules['bible'] = true;
      return true;
    } catch (e) {
      print('❌ Erreur chargement module Bible: $e');
      return false;
    }
  }
  
  /// Charger le module Messages
  static Future<bool> loadMessageModule() async {
    if (_loadedModules['message'] == true) return true;
    
    try {
      await message_module.loadLibrary();
      _loadedModules['message'] = true;
      return true;
    } catch (e) {
      print('❌ Erreur chargement module Messages: $e');
      return false;
    }
  }
  
  /// Charger le module Vie Eglise
  static Future<bool> loadVieEgliseModule() async {
    if (_loadedModules['vie_eglise'] == true) return true;
    
    try {
      await vie_eglise_module.loadLibrary();
      _loadedModules['vie_eglise'] = true;
      return true;
    } catch (e) {
      print('❌ Erreur chargement module Vie Eglise: $e');
      return false;
    }
  }
  
  /// Charger le module Offrandes
  static Future<bool> loadOffrandesModule() async {
    if (_loadedModules['offrandes'] == true) return true;
    
    try {
      await offrandes_module.loadLibrary();
      _loadedModules['offrandes'] = true;
      return true;
    } catch (e) {
      print('❌ Erreur chargement module Offrandes: $e');
      return false;
    }
  }
  
  /// Charger le module Rôles (Admin)
  static Future<bool> loadRolesModule() async {
    if (_loadedModules['roles'] == true) return true;
    
    try {
      await roles_module.loadLibrary();
      _loadedModules['roles'] = true;
      return true;
    } catch (e) {
      print('❌ Erreur chargement module Rôles: $e');
      return false;
    }
  }
  
  /// Précharger les modules critiques en arrière-plan
  static Future<void> preloadCriticalModules() async {
    // Charger en parallèle les modules souvent utilisés
    await Future.wait([
      loadBibleModule(),
      loadSongsModule(),
    ]);
  }
  
  /// Vérifier si un module est chargé
  static bool isModuleLoaded(String moduleName) {
    return _loadedModules[moduleName] == true;
  }
  
  /// Obtenir les stats de chargement
  static Map<String, bool> getLoadedModulesStats() {
    return Map.from(_loadedModules);
  }
}
