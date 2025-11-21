import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/permission_model.dart';

/// Service complet pour la gestion des permissions et rôles
class RolesPermissionsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _permissionsCollection = 'permissions';
  static const String _rolesCollection = 'roles';
  static const String _userRolesCollection = 'user_roles';
  static const String _auditLogCollection = 'roles_audit_log';

  // ========== INITIALISATION DU SYSTÈME ==========

  /// Initialise le système complet de rôles et permissions
  static Future<void> initializeSystem() async {
    try {
      await initializeSystemPermissions();
      await initializeSystemRoles();
      debugPrint('✅ Système de rôles et permissions initialisé avec succès');
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'initialisation du système: $e');
      rethrow;
    }
  }

  /// Initialise toutes les permissions par défaut du système
  static Future<void> initializeSystemPermissions() async {
    try {
      final batch = _firestore.batch();
      int operationCount = 0;

      for (final module in AppModule.allModules) {
        for (final category in module.categories) {
          for (final level in PermissionLevel.values) {
            if (operationCount >= 450) { // Limite Firebase batch
              await batch.commit();
              operationCount = 0;
            }

            final permissionId = '${module.id}_${category.toLowerCase().replaceAll(' ', '_')}_${level.name}';
            final permissionRef = _firestore.collection(_permissionsCollection).doc(permissionId);

            // Vérifier si la permission existe déjà
            final existingDoc = await permissionRef.get();
            if (!existingDoc.exists) {
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
              operationCount++;
            }
          }
        }
      }

      if (operationCount > 0) {
        await batch.commit();
      }

      await _logAuditEvent(
        action: 'system_permissions_initialized',
        details: {'modules_count': AppModule.allModules.length},
      );
    } catch (e) {
      await _logAuditEvent(
        action: 'system_permissions_initialization_failed',
        details: {'error': e.toString()},
      );
      rethrow;
    }
  }

  /// Initialise les rôles par défaut du système
  static Future<void> initializeSystemRoles() async {
    try {
      final systemRoles = _getSystemRolesDefinitions();
      final batch = _firestore.batch();

      for (final role in systemRoles) {
        final roleRef = _firestore.collection(_rolesCollection).doc(role.id);
        final existingDoc = await roleRef.get();
        
        if (!existingDoc.exists) {
          batch.set(roleRef, role.toFirestore());
        }
      }

      await batch.commit();
      await _logAuditEvent(
        action: 'system_roles_initialized',
        details: {'roles_count': systemRoles.length},
      );
    } catch (e) {
      await _logAuditEvent(
        action: 'system_roles_initialization_failed',
        details: {'error': e.toString()},
      );
      rethrow;
    }
  }

  // ========== GESTION DES PERMISSIONS ==========

  /// Récupère toutes les permissions avec filtres optionnels
  static Stream<List<Permission>> getPermissions({
    String? moduleId,
    String? category,
    PermissionLevel? level,
    bool? systemOnly,
  }) {
    Query query = _firestore.collection(_permissionsCollection);

    if (moduleId != null) {
      query = query.where('module', isEqualTo: moduleId);
    }
    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }
    if (level != null) {
      query = query.where('level', isEqualTo: level.name);
    }
    if (systemOnly != null) {
      query = query.where('isSystemPermission', isEqualTo: systemOnly);
    }

    return query
        .orderBy('module')
        .orderBy('category')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Permission.fromFirestore(doc))
            .toList());
  }

  /// Récupère une permission par ID
  static Future<Permission?> getPermissionById(String id) async {
    final doc = await _firestore.collection(_permissionsCollection).doc(id).get();
    return doc.exists ? Permission.fromFirestore(doc) : null;
  }

  // ========== GESTION DES RÔLES ==========

  /// Récupère tous les rôles avec filtres optionnels
  static Stream<List<Role>> getRoles({
    bool? activeOnly,
    bool? systemOnly,
    String? searchTerm,
  }) {
    Query query = _firestore.collection(_rolesCollection);

    if (activeOnly == true) {
      query = query.where('isActive', isEqualTo: true);
    }
    if (systemOnly != null) {
      query = query.where('isSystemRole', isEqualTo: systemOnly);
    }

    return query
        .orderBy('isSystemRole', descending: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
          var roles = snapshot.docs
              .map((doc) => Role.fromFirestore(doc))
              .toList();

          // Filtrage par terme de recherche
          if (searchTerm != null && searchTerm.isNotEmpty) {
            final term = searchTerm.toLowerCase();
            roles = roles.where((role) =>
                role.name.toLowerCase().contains(term) ||
                role.description.toLowerCase().contains(term)
            ).toList();
          }

          return roles;
        });
  }

  /// Récupère un rôle par ID
  static Future<Role?> getRoleById(String id) async {
    final doc = await _firestore.collection(_rolesCollection).doc(id).get();
    return doc.exists ? Role.fromFirestore(doc) : null;
  }

  /// Crée un nouveau rôle
  static Future<String> createRole(Role role, {required String createdBy}) async {
    final roleWithTimestamp = role.copyWith(
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: createdBy,
    );

    final doc = await _firestore.collection(_rolesCollection)
        .add(roleWithTimestamp.toFirestore());

    await _logAuditEvent(
      action: 'role_created',
      entityId: doc.id,
      userId: createdBy,
      details: {'role_name': role.name, 'permissions_count': role.allPermissions.length},
    );

    return doc.id;
  }

  /// Met à jour un rôle
  static Future<void> updateRole(String id, Role role, {required String updatedBy}) async {
    final updatedRole = role.copyWith(
      updatedAt: DateTime.now(),
      lastModifiedBy: updatedBy,
    );

    await _firestore.collection(_rolesCollection)
        .doc(id)
        .update(updatedRole.toFirestore());

    await _logAuditEvent(
      action: 'role_updated',
      entityId: id,
      userId: updatedBy,
      details: {'role_name': role.name},
    );
  }

  // ========== VÉRIFICATIONS DE PERMISSIONS ==========

  /// Vérifie si un utilisateur a une permission spécifique
  static Future<bool> userHasPermission(String userId, String permissionId) async {
    try {
      final userRolesSnapshot = await _firestore
          .collection(_userRolesCollection)
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      if (userRolesSnapshot.docs.isEmpty) return false;

      final roleIds = userRolesSnapshot.docs
          .map((doc) => doc.data()['roleId'] as String)
          .toList();

      final rolesSnapshot = await _firestore
          .collection(_rolesCollection)
          .where(FieldPath.documentId, whereIn: roleIds)
          .where('isActive', isEqualTo: true)
          .get();

      for (final roleDoc in rolesSnapshot.docs) {
        final role = Role.fromFirestore(roleDoc);
        if (role.hasPermission(permissionId)) {
          return true;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Vérifie si un utilisateur a accès à un module
  static Future<bool> userHasModuleAccess(String userId, String moduleId, {PermissionLevel? minimumLevel}) async {
    try {
      final userRolesSnapshot = await _firestore
          .collection(_userRolesCollection)
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      if (userRolesSnapshot.docs.isEmpty) return false;

      final roleIds = userRolesSnapshot.docs
          .map((doc) => doc.data()['roleId'] as String)
          .toList();

      final rolesSnapshot = await _firestore
          .collection(_rolesCollection)
          .where(FieldPath.documentId, whereIn: roleIds)
          .where('isActive', isEqualTo: true)
          .get();

      for (final roleDoc in rolesSnapshot.docs) {
        final role = Role.fromFirestore(roleDoc);
        if (role.hasModuleAccess(moduleId)) {
          if (minimumLevel == null) {
            return true;
          }

          // Vérifier le niveau minimum
          final modulePermissions = role.getModulePermissions(moduleId);
          final hasMinimumLevel = modulePermissions.any((permissionId) {
            final parts = permissionId.split('_');
            if (parts.length >= 3) {
              final levelName = parts.last;
              final level = PermissionLevel.values
                  .where((l) => l.name == levelName)
                  .firstOrNull;
              return level != null && level.index >= minimumLevel.index;
            }
            return false;
          });

          if (hasMinimumLevel) return true;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  // ========== MÉTHODES PRIVÉES ==========

  /// Enregistre un événement dans le log d'audit
  static Future<void> _logAuditEvent({
    required String action,
    String? userId,
    String? entityId,
    Map<String, dynamic>? details,
  }) async {
    try {
      await _firestore.collection(_auditLogCollection).add({
        'action': action,
        'userId': userId,
        'entityId': entityId,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Log silencieux, ne pas faire échouer l'opération principale
      debugPrint('Erreur lors de l\'enregistrement du log d\'audit: $e');
    }
  }

  /// Définit les rôles système par défaut
  static List<Role> _getSystemRolesDefinitions() {
    return [
      // Super Administrateur
      Role(
        id: 'super_admin',
        name: 'Super Administrateur',
        description: 'Accès complet à toutes les fonctionnalités du système',
        color: '#F44336',
        icon: 'admin_panel_settings',
        modulePermissions: _getAllModulePermissions(),
        isSystemRole: true,
        createdAt: DateTime.now(),
      ),

      // Administrateur
      Role(
        id: 'admin',
        name: 'Administrateur',
        description: 'Administration générale avec restrictions sur la configuration système',
        color: '#FF9800',
        icon: 'supervisor_account',
        modulePermissions: _getAdminPermissions(),
        isSystemRole: true,
        createdAt: DateTime.now(),
      ),

      // Modérateur
      Role(
        id: 'moderator',
        name: 'Modérateur',
        description: 'Gestion des contenus et supervision des activités',
        color: '#2196F3',
        icon: 'verified_user',
        modulePermissions: _getModeratorPermissions(),
        isSystemRole: true,
        createdAt: DateTime.now(),
      ),

      // Membre
      Role(
        id: 'member',
        name: 'Membre',
        description: 'Accès de base aux fonctionnalités membres',
        color: '#4CAF50',
        icon: 'person',
        modulePermissions: _getMemberPermissions(),
        isSystemRole: true,
        createdAt: DateTime.now(),
      ),
    ];
  }

  /// Génère toutes les permissions pour tous les modules (super admin)
  static Map<String, List<String>> _getAllModulePermissions() {
    final permissions = <String, List<String>>{};
    
    for (final module in AppModule.allModules) {
      final modulePermissions = <String>[];
      for (final category in module.categories) {
        for (final level in PermissionLevel.values) {
          modulePermissions.add('${module.id}_${category.toLowerCase().replaceAll(' ', '_')}_${level.name}');
        }
      }
      permissions[module.id] = modulePermissions;
    }
    
    return permissions;
  }

  /// Génère les permissions d'administrateur
  static Map<String, List<String>> _getAdminPermissions() {
    final permissions = <String, List<String>>{};
    final excludedModules = ['configuration']; // Exclure certains modules sensibles
    
    for (final module in AppModule.allModules) {
      if (excludedModules.contains(module.id)) continue;
      
      final modulePermissions = <String>[];
      for (final category in module.categories) {
        for (final level in PermissionLevel.values) {
          modulePermissions.add('${module.id}_${category.toLowerCase().replaceAll(' ', '_')}_${level.name}');
        }
      }
      permissions[module.id] = modulePermissions;
    }
    
    return permissions;
  }

  /// Génère les permissions de modérateur
  static Map<String, List<String>> _getModeratorPermissions() {
    final permissions = <String, List<String>>{};
    final allowedModules = ['personnes', 'chants', 'evenements', 'blog', 'vie_eglise'];
    final allowedLevels = [PermissionLevel.read, PermissionLevel.write, PermissionLevel.create];
    
    for (final module in AppModule.allModules) {
      if (!allowedModules.contains(module.id)) continue;
      
      final modulePermissions = <String>[];
      for (final category in module.categories) {
        for (final level in allowedLevels) {
          modulePermissions.add('${module.id}_${category.toLowerCase().replaceAll(' ', '_')}_${level.name}');
        }
      }
      if (modulePermissions.isNotEmpty) {
        permissions[module.id] = modulePermissions;
      }
    }
    
    return permissions;
  }

  /// Génère les permissions de membre
  static Map<String, List<String>> _getMemberPermissions() {
    final permissions = <String, List<String>>{};
    final allowedModules = ['chants', 'bible', 'evenements', 'blog', 'vie_eglise'];
    const allowedLevels = [PermissionLevel.read];
    
    for (final module in AppModule.allModules) {
      if (!allowedModules.contains(module.id)) continue;
      
      final modulePermissions = <String>[];
      for (final category in module.categories) {
        for (final level in allowedLevels) {
          modulePermissions.add('${module.id}_${category.toLowerCase().replaceAll(' ', '_')}_${level.name}');
        }
      }
      if (modulePermissions.isNotEmpty) {
        permissions[module.id] = modulePermissions;
      }
    }
    
    return permissions;
  }
}