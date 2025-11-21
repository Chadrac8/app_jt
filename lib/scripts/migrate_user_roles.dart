import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

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
    
    print('✅ Trouvé ${personsSnapshot.docs.length} personnes avec des rôles');
    
    // 2. Vérifier les user_roles existants
    final existingUserRoles = await firestore
        .collection('user_roles')
        .get();
    
    print('📋 ${existingUserRoles.docs.length} entrées user_roles existantes');
    
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
        print('⏭️  Personne ${personData['firstName']} ${personData['lastName']} a déjà des user_roles');
        skipped++;
        continue;
      }
      
      // Créer le user_role
      final userRoleData = {
        'userId': personId,
        'userEmail': personData['email'] ?? '',
        'userName': '${personData['firstName'] ?? ''} ${personData['lastName'] ?? ''}',
        'roleIds': roles,
        'isActive': true,
        'assignedAt': FieldValue.serverTimestamp(),
        'assignedBy': 'migration_script',
        'expiresAt': null,
      };
      
      await firestore
          .collection('user_roles')
          .add(userRoleData);
      
      print('✅ Migré: ${userRoleData['userName']} avec ${roles.length} rôles');
      migrated++;
    }
    
    print('\n🎉 MIGRATION TERMINÉE!');
    print('\n📊 Résultats:');
    print('   - Personnes migrées: $migrated');
    print('   - Personnes ignorées: $skipped');
    print('   - Total traité: ${migrated + skipped}');
    print('\n✅ L\'onglet Utilisateurs devrait maintenant afficher tous les utilisateurs avec leurs rôles.');
    
  } catch (e) {
    print('❌ Erreur lors de la migration: $e');
  }
}
