import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Script pour supprimer définitivement les modules "Pour vous", "Ressources" et "Dons"
/// de la configuration Firebase.
/// 
/// Usage: dart run cleanup_deleted_modules.dart

const String appConfigCollection = 'app_config';
const String configDocumentId = 'main_config';

void main() async {
  print('🗑️  Nettoyage des modules supprimés...');
  
  try {
    // Initialiser Firebase
    await Firebase.initializeApp();
    final firestore = FirebaseFirestore.instance;
    
    // Modules à supprimer définitivement
    final modulesToDelete = ['pour_vous', 'ressources', 'dons'];
    
    // Récupérer la configuration actuelle
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
    
    print('📊 Configuration actuelle trouvée avec ${modules.length} modules');
    
    // Afficher les modules avant suppression
    print('\n📋 Modules actuels:');
    for (var module in modules) {
      final id = module['id'] ?? 'unknown';
      final name = module['name'] ?? 'Unknown';
      final isEnabled = module['isEnabledForMembers'] ?? false;
      final isPrimary = module['isPrimaryInBottomNav'] ?? false;
      print('  - $id: "$name" (enabled: $isEnabled, primary: $isPrimary)');
    }
    
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
    
    // Afficher les modules restants
    print('\n📋 Modules restants:');
    for (var module in modules) {
      final id = module['id'] ?? 'unknown';
      final name = module['name'] ?? 'Unknown';
      final isEnabled = module['isEnabledForMembers'] ?? false;
      final isPrimary = module['isPrimaryInBottomNav'] ?? false;
      print('  - $id: "$name" (enabled: $isEnabled, primary: $isPrimary)');
    }
    
    print('\n🎉 Nettoyage terminé avec succès!');
    print('💡 Les modules supprimés ne devraient plus apparaître dans le menu "Plus".');
    
  } catch (e) {
    print('❌ Erreur lors du nettoyage: $e');
    exit(1);
  }
}
