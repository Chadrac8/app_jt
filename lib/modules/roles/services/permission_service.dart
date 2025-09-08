import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/permission_model.dart';

class PermissionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _permissionsCollection = 'permissions';
  static const String _rolesCollection = 'roles';
  static const String _userRolesCollection = 'user_roles';

  /// Initialise les permissions par défaut pour tous les modules
  static Future<void> initializeDefaultPermissions() async {
    final batch = _firestore.batch();

    for (final module in AppModule.allModules) {
      for (final category in module.categories) {
        for (final level in PermissionLevel.values) {
          final permissionId = '${module.id}_${category.toLowerCase()}_${level.name}';
          final permissionRef = _firestore.collection(_permissionsCollection).doc(permissionId);

          final permission = Permission(
            id: permissionId,
            name: '${level.displayName} - ${category}',
            description: '${level.description} pour ${category} dans ${module.name}',
            module: module.id,
            category: category,
            level: level,
            isSystemPermission: true,
            createdAt: DateTime.now(),
          );

          batch.set(permissionRef, permission.toFirestore());
        }
      }
    }

    await batch.commit();
  }

  /// Récupère toutes les permissions
  static Stream<List<Permission>> getAllPermissions() {
    return _firestore
        .collection(_permissionsCollection)
        .orderBy('module')
        .orderBy('category')
        .orderBy('level')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Permission.fromFirestore(doc))
            .toList());
  }

  /// Récupère les permissions par module
  static Stream<List<Permission>> getPermissionsByModule(String moduleId) {
    return _firestore
        .collection(_permissionsCollection)
        .where('module', isEqualTo: moduleId)
        .orderBy('category')
        .orderBy('level')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Permission.fromFirestore(doc))
            .toList());
  }

  /// Récupère les permissions par catégorie
  static Stream<List<Permission>> getPermissionsByCategory(String category) {
    return _firestore
        .collection(_permissionsCollection)
        .where('category', isEqualTo: category)
        .orderBy('module')
        .orderBy('level')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Permission.fromFirestore(doc))
            .toList());
  }

  /// Récupère une permission par ID
  static Future<Permission?> getPermissionById(String id) async {
    final doc = await _firestore.collection(_permissionsCollection).doc(id).get();
    if (doc.exists) {
      return Permission.fromFirestore(doc);
    }
    return null;
  }

  /// Crée une nouvelle permission personnalisée
  static Future<String> createCustomPermission(Permission permission) async {
    final doc = await _firestore.collection(_permissionsCollection).add(permission.toFirestore());
    return doc.id;
  }

  /// Met à jour une permission
  static Future<void> updatePermission(String id, Permission permission) async {
    await _firestore
        .collection(_permissionsCollection)
        .doc(id)
        .update(permission.copyWith(updatedAt: DateTime.now()).toFirestore());
  }

  /// Supprime une permission (seulement les permissions personnalisées)
  static Future<void> deletePermission(String id) async {
    final permission = await getPermissionById(id);
    if (permission != null && !permission.isSystemPermission) {
      await _firestore.collection(_permissionsCollection).doc(id).delete();
    } else {
      throw Exception('Impossible de supprimer une permission système');
    }
  }

  /// Crée un nouveau rôle
  static Future<String> createRole(Role role) async {
    final doc = await _firestore.collection(_rolesCollection).add(role.toFirestore());
    return doc.id;
  }

  /// Met à jour un rôle
  static Future<void> updateRole(String id, Role role) async {
    await _firestore
        .collection(_rolesCollection)
        .doc(id)
        .update(role.copyWith(updatedAt: DateTime.now()).toFirestore());
  }

  /// Supprime un rôle (seulement les rôles personnalisés)
  static Future<void> deleteRole(String id) async {
    final role = await getRoleById(id);
    if (role != null && !role.isSystemRole) {
      // Vérifier qu'aucun utilisateur n'a ce rôle
      final userRoles = await _firestore
          .collection(_userRolesCollection)
          .where('roleId', isEqualTo: id)
          .where('isActive', isEqualTo: true)
          .get();

      if (userRoles.docs.isNotEmpty) {
        throw Exception('Impossible de supprimer un rôle assigné à des utilisateurs');
      }

      await _firestore.collection(_rolesCollection).doc(id).delete();
    } else {
      throw Exception('Impossible de supprimer un rôle système');
    }
  }

  /// Récupère tous les rôles
  static Stream<List<Role>> getAllRoles() {
    return _firestore
        .collection(_rolesCollection)
        .orderBy('isSystemRole', descending: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Role.fromFirestore(doc))
            .toList());
  }

  /// Récupère les rôles actifs
  static Stream<List<Role>> getActiveRoles() {
    return _firestore
        .collection(_rolesCollection)
        .where('isActive', isEqualTo: true)
        .orderBy('isSystemRole', descending: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Role.fromFirestore(doc))
            .toList());
  }

  /// Récupère un rôle par ID
  static Future<Role?> getRoleById(String id) async {
    final doc = await _firestore.collection(_rolesCollection).doc(id).get();
    if (doc.exists) {
      return Role.fromFirestore(doc);
    }
    return null;
  }

  /// Assigne un rôle à un utilisateur
  static Future<String> assignRoleToUser({
    required String userId,
    required String roleId,
    required String assignedBy,
    DateTime? expiresAt,
    Map<String, dynamic>? metadata,
  }) async {
    // Vérifier que le rôle existe et est actif
    final role = await getRoleById(roleId);
    if (role == null || !role.isActive) {
      throw Exception('Rôle introuvable ou inactif');
    }

    // Vérifier si l'utilisateur a déjà ce rôle
    final existingAssignment = await _firestore
        .collection(_userRolesCollection)
        .where('userId', isEqualTo: userId)
        .where('roleId', isEqualTo: roleId)
        .where('isActive', isEqualTo: true)
        .get();

    if (existingAssignment.docs.isNotEmpty) {
      throw Exception('L\'utilisateur a déjà ce rôle');
    }

    final userRole = UserRole(
      id: '',
      userId: userId,
      roleId: roleId,
      assignedAt: DateTime.now(),
      assignedBy: assignedBy,
      expiresAt: expiresAt,
      metadata: metadata,
    );

    final doc = await _firestore.collection(_userRolesCollection).add(userRole.toFirestore());
    return doc.id;
  }

  /// Révoque un rôle d'un utilisateur
  static Future<void> revokeRoleFromUser(String userId, String roleId) async {
    final assignments = await _firestore
        .collection(_userRolesCollection)
        .where('userId', isEqualTo: userId)
        .where('roleId', isEqualTo: roleId)
        .where('isActive', isEqualTo: true)
        .get();

    final batch = _firestore.batch();
    for (final doc in assignments.docs) {
      batch.update(doc.reference, {'isActive': false});
    }
    await batch.commit();
  }

  /// Récupère les rôles d'un utilisateur
  static Stream<List<UserRole>> getUserRoles(String userId) {
    return _firestore
        .collection(_userRolesCollection)
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserRole.fromFirestore(doc))
            .where((userRole) => userRole.isValid)
            .toList());
  }

  /// Récupère les rôles détaillés d'un utilisateur
  static Future<List<Role>> getUserDetailedRoles(String userId) async {
    final userRoles = await _firestore
        .collection(_userRolesCollection)
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .get();

    final roleIds = userRoles.docs
        .map((doc) => UserRole.fromFirestore(doc))
        .where((userRole) => userRole.isValid)
        .map((userRole) => userRole.roleId)
        .toList();

    if (roleIds.isEmpty) return [];

    final roles = <Role>[];
    for (final roleId in roleIds) {
      final role = await getRoleById(roleId);
      if (role != null && role.isActive) {
        roles.add(role);
      }
    }

    return roles;
  }

  /// Vérifie si un utilisateur a une permission spécifique
  static Future<bool> userHasPermission(String userId, String permissionId) async {
    final userRoles = await getUserDetailedRoles(userId);
    return userRoles.any((role) => role.hasPermission(permissionId));
  }

  /// Vérifie si un utilisateur a accès à un module
  static Future<bool> userHasModuleAccess(String userId, String moduleId) async {
    final userRoles = await getUserDetailedRoles(userId);
    return userRoles.any((role) => role.hasModuleAccess(moduleId));
  }

  /// Récupère toutes les permissions d'un utilisateur
  static Future<List<String>> getUserPermissions(String userId) async {
    final userRoles = await getUserDetailedRoles(userId);
    final permissions = <String>{};
    
    for (final role in userRoles) {
      permissions.addAll(role.allPermissions);
    }
    
    return permissions.toList();
  }

  /// Récupère les permissions d'un utilisateur pour un module spécifique
  static Future<List<String>> getUserModulePermissions(String userId, String moduleId) async {
    final userRoles = await getUserDetailedRoles(userId);
    final permissions = <String>{};
    
    for (final role in userRoles) {
      permissions.addAll(role.getModulePermissions(moduleId));
    }
    
    return permissions.toList();
  }

  /// Récupère tous les utilisateurs avec un rôle spécifique
  static Stream<List<UserRole>> getUsersWithRole(String roleId) {
    return _firestore
        .collection(_userRolesCollection)
        .where('roleId', isEqualTo: roleId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserRole.fromFirestore(doc))
            .where((userRole) => userRole.isValid)
            .toList());
  }

  /// Initialise les rôles par défaut
  static Future<void> initializeDefaultRoles() async {
    final batch = _firestore.batch();

    // Rôle Super Admin
    final superAdminPermissions = <String, List<String>>{};
    for (final module in AppModule.allModules) {
      final modulePermissions = <String>[];
      for (final category in module.categories) {
        for (final level in PermissionLevel.values) {
          modulePermissions.add('${module.id}_${category.toLowerCase()}_${level.name}');
        }
      }
      superAdminPermissions[module.id] = modulePermissions;
    }

    final superAdminRole = Role(
      id: 'super_admin',
      name: 'Super Administrateur',
      description: 'Accès complet à toutes les fonctionnalités',
      color: '#D32F2F',
      icon: 'admin_panel_settings',
      modulePermissions: superAdminPermissions,
      isSystemRole: true,
      createdAt: DateTime.now(),
    );

    batch.set(
      _firestore.collection(_rolesCollection).doc('super_admin'),
      superAdminRole.toFirestore(),
    );

    // Rôle Administrateur
    final adminPermissions = <String, List<String>>{};
    for (final module in AppModule.allModules) {
      if (module.id != 'configuration') {
        final modulePermissions = <String>[];
        for (final category in module.categories) {
          for (final level in PermissionLevel.values) {
            if (level != PermissionLevel.admin) {
              modulePermissions.add('${module.id}_${category.toLowerCase()}_${level.name}');
            }
          }
        }
        adminPermissions[module.id] = modulePermissions;
      }
    }

    final adminRole = Role(
      id: 'admin',
      name: 'Administrateur',
      description: 'Accès administratif limité',
      color: '#FF9800',
      icon: 'supervisor_account',
      modulePermissions: adminPermissions,
      isSystemRole: true,
      createdAt: DateTime.now(),
    );

    batch.set(
      _firestore.collection(_rolesCollection).doc('admin'),
      adminRole.toFirestore(),
    );

    // Rôle Modérateur
    final moderatorModules = ['personnes', 'groupes', 'evenements', 'blog', 'vie_eglise'];
    final moderatorPermissions = <String, List<String>>{};
    for (final moduleId in moderatorModules) {
      final module = AppModule.findById(moduleId);
      if (module != null) {
        final modulePermissions = <String>[];
        for (final category in module.categories) {
          for (final level in [PermissionLevel.read, PermissionLevel.write, PermissionLevel.create]) {
            modulePermissions.add('${module.id}_${category.toLowerCase()}_${level.name}');
          }
        }
        moderatorPermissions[module.id] = modulePermissions;
      }
    }

    final moderatorRole = Role(
      id: 'moderator',
      name: 'Modérateur',
      description: 'Gestion des contenus et interactions',
      color: '#2196F3',
      icon: 'moderate',
      modulePermissions: moderatorPermissions,
      isSystemRole: true,
      createdAt: DateTime.now(),
    );

    batch.set(
      _firestore.collection(_rolesCollection).doc('moderator'),
      moderatorRole.toFirestore(),
    );

    // Rôle Utilisateur
    final userModules = ['dashboard', 'bible', 'chants', 'vie_eglise', 'blog'];
    final userPermissions = <String, List<String>>{};
    for (final moduleId in userModules) {
      final module = AppModule.findById(moduleId);
      if (module != null) {
        final modulePermissions = <String>[];
        for (final category in module.categories) {
          modulePermissions.add('${module.id}_${category.toLowerCase()}_read');
        }
        userPermissions[module.id] = modulePermissions;
      }
    }

    final userRole = Role(
      id: 'user',
      name: 'Utilisateur',
      description: 'Accès de base aux fonctionnalités',
      color: '#4CAF50',
      icon: 'person',
      modulePermissions: userPermissions,
      isSystemRole: true,
      createdAt: DateTime.now(),
    );

    batch.set(
      _firestore.collection(_rolesCollection).doc('user'),
      userRole.toFirestore(),
    );

    await batch.commit();
  }

  /// Nettoie les rôles expirés
  static Future<void> cleanupExpiredRoles() async {
    final expiredRoles = await _firestore
        .collection(_userRolesCollection)
        .where('isActive', isEqualTo: true)
        .where('expiresAt', isLessThan: Timestamp.now())
        .get();

    final batch = _firestore.batch();
    for (final doc in expiredRoles.docs) {
      batch.update(doc.reference, {'isActive': false});
    }
    await batch.commit();
  }

  /// Exporte la configuration des rôles et permissions
  static Future<Map<String, dynamic>> exportConfiguration() async {
    final permissions = await _firestore.collection(_permissionsCollection).get();
    final roles = await _firestore.collection(_rolesCollection).get();

    return {
      'permissions': permissions.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList(),
      'roles': roles.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList(),
      'modules': AppModule.allModules.map((module) => {
        'id': module.id,
        'name': module.name,
        'description': module.description,
        'icon': module.icon,
        'categories': module.categories,
        'isActive': module.isActive,
      }).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Importe la configuration des rôles et permissions
  static Future<void> importConfiguration(Map<String, dynamic> config) async {
    final batch = _firestore.batch();

    // Import permissions
    if (config['permissions'] != null) {
      for (final permissionData in config['permissions']) {
        final id = permissionData['id'];
        final data = Map<String, dynamic>.from(permissionData);
        data.remove('id');
        
        batch.set(_firestore.collection(_permissionsCollection).doc(id), data);
      }
    }

    // Import roles
    if (config['roles'] != null) {
      for (final roleData in config['roles']) {
        final id = roleData['id'];
        final data = Map<String, dynamic>.from(roleData);
        data.remove('id');
        
        batch.set(_firestore.collection(_rolesCollection).doc(id), data);
      }
    }

    await batch.commit();
  }
}
