import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/role.dart';
import '../models/user_role.dart';
import '../models/permission.dart';

class RoleService {
  static final RoleService _instance = RoleService._internal();
  factory RoleService() => _instance;
  RoleService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  String get rolesCollection => 'roles';
  String get userRolesCollection => 'user_roles';
  String get permissionsCollection => 'permissions';

  // ========== ROLES ==========

  /// Créer un nouveau rôle
  Future<String> createRole(Role role) async {
    try {
      final docRef = await _firestore
          .collection(rolesCollection)
          .add(role.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création du rôle: $e');
    }
  }

  /// Obtenir un rôle par ID
  Future<Role?> getRole(String roleId) async {
    try {
      final doc = await _firestore
          .collection(rolesCollection)
          .doc(roleId)
          .get();
      
      if (doc.exists) {
        return Role.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération du rôle: $e');
    }
  }

  /// Obtenir tous les rôles
  Stream<List<Role>> getAllRoles() {
    return _firestore
        .collection(rolesCollection)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Role.fromFirestore(doc))
            .toList());
  }

  /// Obtenir les rôles actifs
  Stream<List<Role>> getActiveRoles() {
    return _firestore
        .collection(rolesCollection)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Role.fromFirestore(doc))
            .toList());
  }

  /// Mettre à jour un rôle
  Future<void> updateRole(String roleId, Role role) async {
    try {
      await _firestore
          .collection(rolesCollection)
          .doc(roleId)
          .update(role.toMap());
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du rôle: $e');
    }
  }

  /// Supprimer un rôle
  Future<void> deleteRole(String roleId) async {
    try {
      // Vérifier si le rôle est assigné à des utilisateurs
      final userRoles = await _firestore
          .collection(userRolesCollection)
          .where('roleIds', arrayContains: roleId)
          .get();

      if (userRoles.docs.isNotEmpty) {
        throw Exception('Impossible de supprimer un rôle assigné à des utilisateurs');
      }

      await _firestore
          .collection(rolesCollection)
          .doc(roleId)
          .delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression du rôle: $e');
    }
  }

  // ========== USER ROLES ==========

  /// Assigner des rôles à un utilisateur
  Future<String> assignRolesToUser({
    required String userId,
    required String userEmail,
    required String userName,
    required List<String> roleIds,
    String? assignedBy,
    DateTime? expiresAt,
  }) async {
    try {
      final userRole = UserRole(
        id: '',
        userId: userId,
        userEmail: userEmail,
        userName: userName,
        roleIds: roleIds,
        assignedBy: assignedBy,
        expiresAt: expiresAt,
      );

      final docRef = await _firestore
          .collection(userRolesCollection)
          .add(userRole.toMap());
      
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de l\'assignation des rôles: $e');
    }
  }

  /// Obtenir les rôles d'un utilisateur
  Future<UserRole?> getUserRoles(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(userRolesCollection)
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return UserRole.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des rôles utilisateur: $e');
    }
  }

  /// Stream des rôles d'un utilisateur
  Stream<UserRole?> getUserRolesStream(String userId) {
    return _firestore
        .collection(userRolesCollection)
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            return UserRole.fromFirestore(snapshot.docs.first);
          }
          return null;
        });
  }

  /// Obtenir tous les utilisateurs avec leurs rôles
  Stream<List<UserRole>> getAllUserRoles() {
    return _firestore
        .collection(userRolesCollection)
        .where('isActive', isEqualTo: true)
        .orderBy('userName')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserRole.fromFirestore(doc))
            .toList());
  }

  /// Mettre à jour les rôles d'un utilisateur
  Future<void> updateUserRoles(String userRoleId, UserRole userRole) async {
    try {
      await _firestore
          .collection(userRolesCollection)
          .doc(userRoleId)
          .update(userRole.toMap());
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour des rôles utilisateur: $e');
    }
  }

  /// Désactiver les rôles d'un utilisateur
  Future<void> deactivateUserRoles(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(userRolesCollection)
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isActive': false});
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Erreur lors de la désactivation des rôles: $e');
    }
  }

  /// Supprimer complètement les rôles d'un utilisateur
  Future<void> removeUserRoles(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(userRolesCollection)
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Erreur lors de la suppression des rôles: $e');
    }
  }

  // ========== PERMISSIONS ==========

  /// Créer une permission
  Future<String> createPermission(Permission permission) async {
    try {
      final docRef = await _firestore
          .collection(permissionsCollection)
          .add(permission.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création de la permission: $e');
    }
  }

  /// Obtenir toutes les permissions
  Stream<List<Permission>> getAllPermissions() {
    return _firestore
        .collection(permissionsCollection)
        .orderBy('module')
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Permission.fromFirestore(doc))
            .toList());
  }

  /// Obtenir les permissions par module
  Stream<List<Permission>> getPermissionsByModule(String module) {
    return _firestore
        .collection(permissionsCollection)
        .where('module', isEqualTo: module)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Permission.fromFirestore(doc))
            .toList());
  }

  /// Vérifier si un utilisateur a une permission
  Future<bool> userHasPermission(String userId, String permissionId) async {
    try {
      final userRole = await getUserRoles(userId);
      if (userRole == null || !userRole.isActive || userRole.isExpired) {
        return false;
      }

      // Récupérer tous les rôles de l'utilisateur
      final roles = await Future.wait(
        userRole.roleIds.map((roleId) => getRole(roleId))
      );

      // Vérifier si au moins un rôle a la permission
      return roles.any((role) => 
        role != null && 
        role.isActive && 
        role.hasPermission(permissionId)
      );
    } catch (e) {
      return false;
    }
  }

  /// Obtenir toutes les permissions d'un utilisateur
  Future<List<String>> getUserPermissions(String userId) async {
    try {
      final userRole = await getUserRoles(userId);
      if (userRole == null || !userRole.isActive || userRole.isExpired) {
        return [];
      }

      // Récupérer tous les rôles de l'utilisateur
      final roles = await Future.wait(
        userRole.roleIds.map((roleId) => getRole(roleId))
      );

      // Collecter toutes les permissions
      final permissions = <String>{};
      for (final role in roles) {
        if (role != null && role.isActive) {
          permissions.addAll(role.permissions);
        }
      }

      return permissions.toList();
    } catch (e) {
      return [];
    }
  }

  // ========== RECHERCHE ET FILTRES ==========

  /// Rechercher des utilisateurs par email/nom
  Stream<List<UserRole>> searchUsers(String query) {
    if (query.isEmpty) {
      return getAllUserRoles();
    }

    return _firestore
        .collection(userRolesCollection)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserRole.fromFirestore(doc))
            .where((userRole) =>
                userRole.userEmail.toLowerCase().contains(query.toLowerCase()) ||
                userRole.userName.toLowerCase().contains(query.toLowerCase()))
            .toList());
  }

  /// Obtenir les utilisateurs par rôle
  Stream<List<UserRole>> getUsersByRole(String roleId) {
    return _firestore
        .collection(userRolesCollection)
        .where('isActive', isEqualTo: true)
        .where('roleIds', arrayContains: roleId)
        .orderBy('userName')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserRole.fromFirestore(doc))
            .toList());
  }

  // ========== STATISTIQUES ==========

  /// Obtenir les statistiques des rôles
  Future<Map<String, int>> getRoleStatistics() async {
    try {
      final allUserRoles = await _firestore
          .collection(userRolesCollection)
          .where('isActive', isEqualTo: true)
          .get();

      final allRoles = await _firestore
          .collection(rolesCollection)
          .where('isActive', isEqualTo: true)
          .get();

      // Exécuter calcul en isolate si >100 rôles
      if (allRoles.docs.length > 100) {
        final data = {
          'userRoles': allUserRoles.docs.map((d) => d.data()).toList(),
          'roles': allRoles.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
        };
        return await compute(_calculateRoleStats, data);
      }

      final statistics = <String, int>{};
      
      // Compter les utilisateurs par rôle
      for (final role in allRoles.docs) {
        final roleId = role.id;
        final roleName = role.data()['name'] as String;
        
        final count = allUserRoles.docs
            .where((userRole) {
              final roleIds = List<String>.from(userRole.data()['roleIds'] ?? []);
              return roleIds.contains(roleId);
            })
            .length;
            
        statistics[roleName] = count;
      }

      return statistics;
    } catch (e) {
      throw Exception('Erreur lors du calcul des statistiques: $e');
    }
  }

  // Fonction isolée pour calculs statistiques
  static Map<String, int> _calculateRoleStats(Map<String, dynamic> data) {
    final userRoles = data['userRoles'] as List<dynamic>;
    final roles = data['roles'] as List<dynamic>;
    final statistics = <String, int>{};
    
    for (final role in roles) {
      final roleId = role['id'] as String;
      final roleName = role['name'] as String;
      
      final count = userRoles.where((userRole) {
        final roleIds = List<String>.from(userRole['roleIds'] ?? []);
        return roleIds.contains(roleId);
      }).length;
      
      statistics[roleName] = count;
    }
    
    return statistics;
  }

  // ========== UTILITAIRES ==========

  /// Initialiser les rôles et permissions par défaut
  Future<void> initializeDefaultRolesAndPermissions() async {
    try {
      // Créer les permissions par défaut si elles n'existent pas
      final defaultPermissions = [
        Permission(
          id: 'users.read',
          name: 'Lire les utilisateurs',
          description: 'Voir la liste des utilisateurs',
          module: 'users',
          action: 'read',
        ),
        Permission(
          id: 'users.write',
          name: 'Modifier les utilisateurs',
          description: 'Créer et modifier les utilisateurs',
          module: 'users',
          action: 'write',
        ),
        Permission(
          id: 'users.delete',
          name: 'Supprimer les utilisateurs',
          description: 'Supprimer des utilisateurs',
          module: 'users',
          action: 'delete',
        ),
        Permission(
          id: 'roles.read',
          name: 'Lire les rôles',
          description: 'Voir la liste des rôles',
          module: 'roles',
          action: 'read',
        ),
        Permission(
          id: 'roles.write',
          name: 'Modifier les rôles',
          description: 'Créer et modifier les rôles',
          module: 'roles',
          action: 'write',
        ),
        Permission(
          id: 'roles.delete',
          name: 'Supprimer les rôles',
          description: 'Supprimer des rôles',
          module: 'roles',
          action: 'delete',
        ),
        Permission(
          id: 'content.read',
          name: 'Lire le contenu',
          description: 'Voir le contenu',
          module: 'content',
          action: 'read',
        ),
        Permission(
          id: 'content.write',
          name: 'Modifier le contenu',
          description: 'Créer et modifier le contenu',
          module: 'content',
          action: 'write',
        ),
        Permission(
          id: 'content.delete',
          name: 'Supprimer le contenu',
          description: 'Supprimer du contenu',
          module: 'content',
          action: 'delete',
        ),
        Permission(
          id: 'settings.read',
          name: 'Lire les paramètres',
          description: 'Voir les paramètres',
          module: 'settings',
          action: 'read',
        ),
        Permission(
          id: 'settings.write',
          name: 'Modifier les paramètres',
          description: 'Modifier les paramètres',
          module: 'settings',
          action: 'write',
        ),
      ];

      final batch = _firestore.batch();

      for (final permission in defaultPermissions) {
        final doc = await _firestore
            .collection(permissionsCollection)
            .doc(permission.id)
            .get();
        
        if (!doc.exists) {
          batch.set(
            _firestore.collection(permissionsCollection).doc(permission.id),
            permission.toMap(),
          );
        }
      }

      // Créer les rôles par défaut
      for (final role in Role.predefinedRoles) {
        final doc = await _firestore
            .collection(rolesCollection)
            .doc(role.id)
            .get();
        
        if (!doc.exists) {
          batch.set(
            _firestore.collection(rolesCollection).doc(role.id),
            role.toMap(),
          );
        }
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Erreur lors de l\'initialisation: $e');
    }
  }

  // ========== MIGRATION ==========

  /// Migrer les rôles depuis la collection persons vers user_roles
  Future<Map<String, dynamic>> migratePersonsRolesToUserRoles() async {
    try {
      print('🔄 Début de la migration des rôles...');
      
      // 1. Lire toutes les personnes avec des rôles
      final personsSnapshot = await _firestore
          .collection('persons')
          .where('roles', isNotEqualTo: [])
          .get();
      
      print('📖 Trouvé ${personsSnapshot.docs.length} personnes avec des rôles');
      
      // 2. Vérifier les user_roles existants
      final existingUserRoles = await _firestore
          .collection(userRolesCollection)
          .get();
      
      print('📋 ${existingUserRoles.docs.length} entrées user_roles existantes');
      
      int migrated = 0;
      int skipped = 0;
      int errors = 0;
      
      // 3. Migrer chaque personne vers user_roles
      for (final personDoc in personsSnapshot.docs) {
        try {
          final personData = personDoc.data();
          final personId = personDoc.id;
          final roles = List<String>.from(personData['roles'] ?? []);
          
          if (roles.isEmpty) {
            skipped++;
            continue;
          }
          
          // Vérifier si cette personne a déjà un user_role actif
          final existingUserRole = await _firestore
              .collection(userRolesCollection)
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
          
          await _firestore
              .collection(userRolesCollection)
              .add(userRoleData);
          
          print('✅ Migré: ${userRoleData['userName']} avec ${roles.length} rôles');
          migrated++;
          
        } catch (e) {
          print('❌ Erreur pour la personne ${personDoc.id}: $e');
          errors++;
        }
      }
      
      final result = {
        'migrated': migrated,
        'skipped': skipped,
        'errors': errors,
        'total': personsSnapshot.docs.length,
      };
      
      print('\n🎉 MIGRATION TERMINÉE!');
      print('📊 Résultats: $result');
      
      return result;
      
    } catch (e) {
      throw Exception('Erreur lors de la migration: $e');
    }
  }
}
