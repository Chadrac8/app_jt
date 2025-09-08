#!/usr/bin/env dart

import 'dart:io';

void main() async {
  print('''
🔍 ANALYSE DU PROBLÈME DES RÔLES UTILISATEURS

Le problème identifié:
- L'onglet "Utilisateurs" dans la gestion des rôles est vide
- Le RoleProvider utilise la collection 'user_roles' pour afficher les utilisateurs
- Mais les rôles sont actuellement stockés dans 'persons.roles'

Solutions possibles:

1. 📦 MIGRATION DES DONNÉES (recommandée)
   Migrer les données de 'persons.roles' vers 'user_roles'
   
2. 🔄 ADAPTER LE CODE
   Modifier le RoleProvider pour lire depuis 'persons'
   
3. 🔧 SYNCHRONISATION
   Créer un système qui synchronise les deux collections

══════════════════════════════════════════════════════════════

COMMANDES POUR DIAGNOSTIQUER:

1. Vérifier les données persons avec rôles:
   firebase firestore:dump --only-collections persons --output-format json | grep -A5 -B5 '"roles"'

2. Vérifier la collection user_roles:
   firebase firestore:dump --only-collections user_roles --output-format json

3. Compter les personnes avec des rôles:
   firebase firestore:dump --only-collections persons --output-format json | grep -c '"roles"'

══════════════════════════════════════════════════════════════

ÉTAPES DE MIGRATION:

1. Créer un script Flutter pour migrer les données
2. Lire toutes les personnes avec des rôles depuis 'persons'
3. Créer des documents correspondants dans 'user_roles'
4. Tester l'affichage dans l'onglet Utilisateurs

Voulez-vous procéder avec la migration automatique? (y/n)
''');

  final input = stdin.readLineSync();
  if (input?.toLowerCase() == 'y' || input?.toLowerCase() == 'yes') {
    print('\n📝 Création du script de migration...');
    await createMigrationScript();
  } else {
    print('\n❌ Migration annulée. Vous pouvez utiliser les commandes ci-dessus pour analyser manuellement.');
  }
}

Future<void> createMigrationScript() async {
  final migrationScript = '''
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  print('🚀 Démarrage de la migration des rôles utilisateurs...');
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  final firestore = FirebaseFirestore.instance;
  
  try {
    // 1. Lire toutes les personnes avec des rôles
    print('📖 Lecture des personnes avec des rôles...');
    final personsSnapshot = await firestore
        .collection('persons')
        .where('roles', isNotEqualTo: [])
        .get();
    
    print('✅ Trouvé \${personsSnapshot.docs.length} personnes avec des rôles');
    
    // 2. Vérifier les user_roles existants
    final existingUserRoles = await firestore
        .collection('user_roles')
        .get();
    
    print('📋 \${existingUserRoles.docs.length} entrées user_roles existantes');
    
    // 3. Migrer chaque personne vers user_roles
    int migrated = 0;
    int skipped = 0;
    
    for (final personDoc in personsSnapshot.docs) {
      final personData = personDoc.data();
      final personId = personDoc.id;
      final roles = List<String>.from(personData['roles'] ?? []);
      
      if (roles.isEmpty) {
        skipped++;
        continue;
      }
      
      // Vérifier si cette personne a déjà un user_role actif
      final existingUserRole = await firestore
          .collection('user_roles')
          .where('userId', isEqualTo: personId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      
      if (existingUserRole.docs.isNotEmpty) {
        print('⏭️  Personne \${personData['firstName']} \${personData['lastName']} a déjà des user_roles');
        skipped++;
        continue;
      }
      
      // Créer le user_role
      final userRoleData = {
        'userId': personId,
        'userEmail': personData['email'] ?? '',
        'userName': '\${personData['firstName'] ?? ''} \${personData['lastName'] ?? ''}',
        'roleIds': roles,
        'isActive': true,
        'assignedAt': FieldValue.serverTimestamp(),
        'assignedBy': 'migration_script',
        'expiresAt': null,
      };
      
      await firestore
          .collection('user_roles')
          .add(userRoleData);
      
      print('✅ Migré: \${userRoleData['userName']} avec \${roles.length} rôles');
      migrated++;
    }
    
    print('''
🎉 MIGRATION TERMINÉE!

📊 Résultats:
   - Personnes migrées: \$migrated
   - Personnes ignorées: \$skipped
   - Total traité: \${migrated + skipped}

✅ L'onglet Utilisateurs devrait maintenant afficher tous les utilisateurs avec leurs rôles.
''');
    
  } catch (e) {
    print('❌ Erreur lors de la migration: \$e');
  }
}
''';

  // Écrire le script de migration
  final file = File('/Users/chadracntsouassouani/Downloads/app_jubile_tabernacle/lib/scripts/migrate_user_roles.dart');
  await file.parent.create(recursive: true);
  await file.writeAsString(migrationScript);
  
  print('✅ Script de migration créé: ${file.path}');
  print('''
📋 PROCHAINES ÉTAPES:

1. Exécuter le script de migration:
   cd /Users/chadracntsouassouani/Downloads/app_jubile_tabernacle
   dart lib/scripts/migrate_user_roles.dart

2. Vérifier les résultats dans l'app
3. Tester l'onglet Utilisateurs dans la gestion des rôles

⚠️  IMPORTANT: Ce script va créer des entrées dans 'user_roles' 
   basées sur les rôles existants dans 'persons'. Aucune donnée 
   existante ne sera supprimée.
''');
}
''');
