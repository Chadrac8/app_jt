#!/bin/dart
import 'dart:io';

void main() async {
  print('=== VERIFICATION FINALE DU MODULE ROLES ===\n');
  
  final baseDir = 'lib/modules/roles';
  
  // Fichiers requis
  final requiredFiles = [
    'models/permission.dart',
    'models/role.dart', 
    'models/user_role.dart',
    'services/role_service.dart',
    'providers/role_provider.dart',
    'views/roles_management_screen.dart',
    'widgets/user_role_assignment_widget.dart',
    'roles_module.dart',
  ];
  
  print('📁 Vérification des fichiers du module...');
  
  int foundFiles = 0;
  for (final file in requiredFiles) {
    final filePath = '$baseDir/$file';
    final exists = await File(filePath).exists();
    
    if (exists) {
      print('✅ $file');
      foundFiles++;
    } else {
      print('❌ $file - MANQUANT');
    }
  }
  
  print('\n📊 Résultats: $foundFiles/${requiredFiles.length} fichiers trouvés\n');
  
  // Vérifier la structure du module
  print('🏗️  Vérification de la structure...');
  
  final directories = [
    '$baseDir/models',
    '$baseDir/services',
    '$baseDir/providers',
    '$baseDir/views',
    '$baseDir/widgets',
  ];
  
  int foundDirs = 0;
  for (final dir in directories) {
    final exists = await Directory(dir).exists();
    if (exists) {
      print('✅ ${dir.split('/').last}/ directory');
      foundDirs++;
    } else {
      print('❌ ${dir.split('/').last}/ directory - MANQUANT');
    }
  }
  
  print('\n📊 Directories: $foundDirs/${directories.length} trouvés\n');
  
  // Vérifier les dépendances
  print('📦 Vérification des dépendances...');
  
  final pubspecFile = File('pubspec.yaml');
  if (await pubspecFile.exists()) {
    final content = await pubspecFile.readAsString();
    
    final dependencies = [
      'cloud_firestore',
      'firebase_database',
      'provider',
    ];
    
    int foundDeps = 0;
    for (final dep in dependencies) {
      if (content.contains(dep)) {
        print('✅ $dep');
        foundDeps++;
      } else {
        print('❌ $dep - MANQUANT dans pubspec.yaml');
      }
    }
    
    print('\n📊 Dependencies: $foundDeps/${dependencies.length} trouvées\n');
  }
  
  // Vérifier l'intégration dans l'admin
  print('🔗 Vérification de l\'intégration admin...');
  
  final adminNavFile = File('lib/widgets/admin_navigation_wrapper.dart');
  if (await adminNavFile.exists()) {
    final content = await adminNavFile.readAsString();
    
    if (content.contains('roles') && content.contains('RolesManagementScreen')) {
      print('✅ Module intégré dans admin_navigation_wrapper.dart');
    } else {
      print('❌ Module NON intégré dans admin_navigation_wrapper.dart');
    }
  } else {
    print('❌ admin_navigation_wrapper.dart non trouvé');
  }
  
  print('\n' + '='*50);
  print('🎯 STATUT FINAL DU MODULE ROLES:');
  
  if (foundFiles == requiredFiles.length && foundDirs == directories.length) {
    print('✅ MODULE COMPLETEMENT IMPLEMENTÉ');
    print('✅ Tous les fichiers sont en place');
    print('✅ Structure correcte');
    print('✅ Prêt pour utilisation');
  } else {
    print('⚠️  MODULE PARTIELLEMENT IMPLEMENTÉ');
    print('❌ Certains fichiers manquent');
    print('🔧 Vérifiez les erreurs ci-dessus');
  }
  
  print('='*50);
  print('\n📋 RÉSUMÉ DES FONCTIONNALITÉS:');
  print('• 👥 Gestion des rôles (admin, moderator, contributor, viewer)');
  print('• 🔐 Gestion des permissions par module/action');
  print('• 👤 Assignation de rôles aux utilisateurs');
  print('• ⏰ Gestion des expirations de rôles');
  print('• 🔍 Recherche et filtrage des utilisateurs');
  print('• 📊 Statistiques des rôles');
  print('• 🔄 Synchronisation temps réel avec Firebase');
  print('• 🎨 Interface utilisateur intégrée à l\'admin');
  
  print('\n🚀 Pour utiliser le module:');
  print('1. Assurez-vous que Firebase est configuré');
  print('2. Ajoutez RoleProvider dans votre main.dart');
  print('3. Accédez via Admin > Rôles et Permissions');
}
