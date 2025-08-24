import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Test de connexion Firebase et nettoyage direct
/// Usage: dart run test_firebase_cleanup.dart

const String appConfigCollection = 'app_config';
const String configDocumentId = 'main_config';

void main() async {
  print('🔧 Test de nettoyage Firebase direct...');
  
  try {
    // Initialiser Firebase avec les options par défaut
    await Firebase.initializeApp();
    print('✅ Firebase initialisé');
    
    final firestore = FirebaseFirestore.instance;
    
    // Modules à supprimer
    final modulesToDelete = ['pour_vous', 'ressources', 'dons'];
    
    // Récupérer la configuration actuelle
    print('📥 Récupération de la configuration...');
    final configDoc = await firestore
        .collection(appConfigCollection)
        .doc(configDocumentId)
        .get();
    
    if (!configDoc.exists) {
      print('❌ Configuration non trouvée dans Firebase');
      return;
    }
    
    final configData = configDoc.data()!;
    final modules = List<Map<String, dynamic>>.from(configData['modules'] ?? []);
    
    print('📊 Configuration trouvée avec ${modules.length} modules');
    
    // Identifier les modules à supprimer
    final modulesBeforeCleanup = modules.length;
    final modulesToRemove = <Map<String, dynamic>>[];
    
    for (var module in modules) {
      final moduleId = module['id'];
      if (modulesToDelete.contains(moduleId)) {
        modulesToRemove.add(module);
        print('🎯 Module à supprimer trouvé: $moduleId - "${module['name']}"');
      }
    }
    
    if (modulesToRemove.isEmpty) {
      print('✅ Aucun module à supprimer trouvé. Nettoyage déjà effectué.');
      return;
    }
    
    // Supprimer les modules
    modules.removeWhere((module) => modulesToDelete.contains(module['id']));
    
    print('\n🗑️  Suppression de ${modulesToRemove.length} modules...');
    for (var module in modulesToRemove) {
      print('  ❌ Supprimé: ${module['id']} - "${module['name']}"');
    }
    
    // Mettre à jour la configuration
    configData['modules'] = modules;
    configData['lastUpdated'] = FieldValue.serverTimestamp();
    configData['lastUpdatedBy'] = 'cleanup_script';
    
    await firestore
        .collection(appConfigCollection)
        .doc(configDocumentId)
        .update(configData);
    
    print('\n✅ Configuration mise à jour avec succès!');
    print('📊 Modules avant: $modulesBeforeCleanup');
    print('📊 Modules après: ${modules.length}');
    print('🗑️  Modules supprimés: ${modulesToRemove.length}');
    
    print('\n🎉 Nettoyage terminé avec succès!');
    print('💡 Les modules supprimés ne devraient plus apparaître dans le menu "Plus".');
    print('🔄 Redémarrez l\'application pour voir les changements.');
    
  } catch (e) {
    print('❌ Erreur lors du nettoyage: $e');
    print('💡 Solution alternative: utiliser Firebase Console manuellement');
    print('   1. Ouvrez https://console.firebase.google.com');
    print('   2. Sélectionnez votre projet');
    print('   3. Allez dans Firestore Database');
    print('   4. Trouvez la collection "app_config" > document "main_config"');
    print('   5. Supprimez les modules avec les IDs: pour_vous, ressources, dons');
  }
}
