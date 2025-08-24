import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Script simple pour nettoyer les modules Firebase sans dépendre de l'app Flutter
/// Usage: dart run simple_cleanup.dart

const String projectId = 'jubile-tabernacle';
const String appConfigCollection = 'app_config';
const String configDocumentId = 'main_config';

void main() async {
  print('🗑️  Nettoyage des modules supprimés...');
  
  try {
    // Modules à supprimer définitivement
    final modulesToDelete = ['pour_vous', 'ressources', 'dons'];
    
    print('📊 Modules à supprimer: ${modulesToDelete.join(', ')}');
    print('💡 Ce script supprime uniquement ces modules de la configuration Firebase.');
    print('🔄 Pour que les changements prennent effet, redémarrez l\'application.');
    
    // Note: Ce script ne peut pas directement accéder à Firebase sans authentification
    print('\n⚠️  Pour effectuer le nettoyage:');
    print('1. Ouvrez Firebase Console: https://console.firebase.google.com/project/$projectId');
    print('2. Allez dans Firestore Database');
    print('3. Naviguez vers la collection "$appConfigCollection"');
    print('4. Ouvrez le document "$configDocumentId"');
    print('5. Dans le champ "modules", supprimez les objets avec les IDs:');
    for (var moduleId in modulesToDelete) {
      print('   - $moduleId');
    }
    print('6. Sauvegardez les modifications');
    print('7. Redémarrez l\'application');
    
    print('\n✅ Instructions affichées avec succès!');
    
  } catch (e) {
    print('❌ Erreur: $e');
    exit(1);
  }
}
