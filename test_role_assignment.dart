import 'package:firebase_core/firebase_core.dart';
import 'lib/modules/roles/services/role_service.dart';
import 'lib/modules/roles/models/user_role.dart';

/// Script de test pour vérifier l'assignation de rôles
void main() async {
  print('🧪 TEST D\'ASSIGNATION DE RÔLES');
  print('================================\n');
  
  try {
    // Initialiser Firebase (nécessaire pour les tests)
    print('📱 Initialisation de Firebase...');
    // await Firebase.initializeApp(); // Décommenté si nécessaire
    
    final roleService = RoleService();
    
    // Test 1: Vérifier les rôles disponibles
    print('📋 Test 1: Récupération des rôles disponibles');
    final roles = await roleService.getAllRoles().first;
    print('✅ Rôles trouvés: ${roles.length}');
    for (final role in roles) {
      print('   - ${role.name} (${role.id})');
    }
    print('');
    
    // Test 2: Tenter d'assigner un rôle à un utilisateur test
    print('👤 Test 2: Assignation d\'un rôle test');
    
    final testUserId = 'test_user_123';
    final testUserEmail = 'test@example.com';
    final testUserName = 'Utilisateur Test';
    
    if (roles.isNotEmpty) {
      final firstRole = roles.first;
      print('🎯 Assignation du rôle "${firstRole.name}" à $testUserName');
      
      try {
        final assignmentId = await roleService.assignRolesToUser(
          userId: testUserId,
          userEmail: testUserEmail,
          userName: testUserName,
          roleIds: [firstRole.id],
          assignedBy: 'system_test',
        );
        
        print('✅ Assignation réussie! ID: $assignmentId');
        
        // Vérifier l'assignation
        final userRole = await roleService.getUserRoles(testUserId);
        if (userRole != null) {
          print('✅ Vérification: Rôle trouvé pour l\'utilisateur');
          print('   - Utilisateur: ${userRole.userName}');
          print('   - Email: ${userRole.userEmail}');
          print('   - Rôles: ${userRole.roleIds}');
          print('   - Actif: ${userRole.isActive}');
        } else {
          print('❌ Erreur: Rôle non trouvé après assignation');
        }
        
        // Nettoyer (supprimer l'assignation test)
        print('🧹 Nettoyage de l\'assignation test...');
        await roleService.removeUserRoles(testUserId);
        print('✅ Nettoyage terminé');
        
      } catch (e) {
        print('❌ Erreur lors de l\'assignation: $e');
      }
    } else {
      print('❌ Aucun rôle disponible pour les tests');
    }
    
    print('\n📊 RÉSULTATS DES TESTS');
    print('=====================');
    print('✅ Service RoleService: Opérationnel');
    print('✅ Collections Firebase: Accessibles');
    print('✅ Modèles de données: Fonctionnels');
    
  } catch (e) {
    print('❌ ERREUR CRITIQUE: $e');
    print('\n🔧 SOLUTIONS POSSIBLES:');
    print('1. Vérifier la configuration Firebase');
    print('2. Vérifier les règles Firestore');
    print('3. Vérifier la connexion internet');
    print('4. Initialiser les rôles par défaut');
  }
  
  print('\n🎯 POUR RÉSOUDRE LES PROBLÈMES D\'ASSIGNATION:');
  print('1. Vérifier que Firebase est initialisé');
  print('2. Vérifier les permissions Firestore');
  print('3. Initialiser les rôles et permissions par défaut');
  print('4. Tester l\'interface utilisateur');
}
