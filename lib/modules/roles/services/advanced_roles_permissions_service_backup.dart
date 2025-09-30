import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/role.dart';
import '../models/permission.dart';

/// Service avancé pour la gestion des rôles et permissions
class AdvancedRolesPermissionsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _rolesCollection = 'roles';
  static const String _permissionsCollection = 'permissions';
  static const String _userRolesCollection = 'user_roles';
  static const String _auditLogsCollection = 'audit_logs';
  static const String _settingsCollection = 'app_settings';
  
  /// Initialise complètement le système de rôles et permissions
  static Future<void> initializeSystem() async {
    try {
      await _initializeDefaultRoles();
      await _initializeDefaultPermissions();
      await _initializeSystemSettings();
      await _createAuditLog('system_initialization', 'Initialisation complète du système', null);
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation du système: $e');
      rethrow;
    }
  }

  /// Initialise les rôles par défaut
  static Future<void> _initializeDefaultRoles() async {
    final defaultRoles = _getDefaultRoles();
    
    for (final role in defaultRoles) {
      await _firestore
          .collection(_rolesCollection)
          .doc(role.id)
          .set(role.toMap(), SetOptions(merge: true));
    }
  }

  /// Initialise les permissions par défaut
  static Future<void> _initializeDefaultPermissions() async {
    final defaultPermissions = _getDefaultPermissions();
    
    for (final permission in defaultPermissions) {
      await _firestore
          .collection(_permissionsCollection)
          .doc(permission.id)
          .set(permission.toMap(), SetOptions(merge: true));
    }
  }

  /// Initialise les paramètres système
  static Future<void> _initializeSystemSettings() async {
    final defaultSettings = {
      'role_expiration_enabled': false,
      'role_expiration_days': 365,
      'auto_cleanup_enabled': false,
      'notifications_enabled': true,
      'email_notifications': false,
      'audit_log_enabled': true,
      'backup_enabled': false,
      'strict_permission_check': true,
      'default_role_color': '#4CAF50',
      'created_at': FieldValue.serverTimestamp(),
      'version': '1.0.0',
    };

    await _firestore
        .collection(_settingsCollection)
        .doc('roles_permissions')
        .set(defaultSettings, SetOptions(merge: true));
  }

  /// Crée un nouveau rôle personnalisé
  static Future<Role> createCustomRole({
    required String name,
    required String description,
    required List<String> permissions,
    String color = '#4CAF50',
    String icon = 'admin_panel_settings',
    bool isActive = true,
  }) async {
    final roleId = _firestore.collection(_rolesCollection).doc().id;
    
    final role = Role(
      id: roleId,
      name: name,
      description: description,
      permissions: permissions,
      isActive: isActive,
      color: color,
      icon: icon,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: 'current_user_id', // TODO: Récupérer l'ID utilisateur actuel
    );

    await _firestore
        .collection(_rolesCollection)
        .doc(roleId)
        .set(role.toMap());

    await _createAuditLog(
      'role_created',
      'Création du rôle $name',
      {'role_id': roleId, 'permissions_count': permissions.length},
    );

    return role;
  }

  /// Met à jour un rôle existant
  static Future<void> updateRole(String roleId, Map<String, dynamic> updates) async {
    updates['updated_at'] = FieldValue.serverTimestamp();
    updates['updated_by'] = 'current_user_id'; // TODO: Récupérer l'ID utilisateur actuel

    await _firestore
        .collection(_rolesCollection)
        .doc(roleId)
        .update(updates);

    await _createAuditLog(
      'role_updated',
      'Mise à jour du rôle $roleId',
      {'role_id': roleId, 'updated_fields': updates.keys.toList()},
    );
  }

  /// Supprime un rôle personnalisé (pas les rôles système)
  static Future<void> deleteCustomRole(String roleId) async {
    // Vérifier que ce n'est pas un rôle système
    final roleDoc = await _firestore.collection(_rolesCollection).doc(roleId).get();
    if (!roleDoc.exists) {
      throw Exception('Rôle non trouvé');
    }

    final roleData = roleDoc.data() as Map<String, dynamic>;
    if (roleData['is_system_role'] == true) {
      throw Exception('Impossible de supprimer un rôle système');
    }

    // Supprimer toutes les assignations de ce rôle
    final userRolesQuery = await _firestore
        .collection(_userRolesCollection)
        .where('role_id', isEqualTo: roleId)
        .get();

    final batch = _firestore.batch();
    
    for (final doc in userRolesQuery.docs) {
      batch.delete(doc.reference);
    }

    // Supprimer le rôle
    batch.delete(_firestore.collection(_rolesCollection).doc(roleId));
    
    await batch.commit();

    await _createAuditLog(
      'role_deleted',
      'Suppression du rôle ${roleData['name']}',
      {'role_id': roleId, 'affected_users': userRolesQuery.docs.length},
    );
  }

  /// Assigne un rôle à un utilisateur avec expiration optionnelle
  static Future<void> assignRoleToUser({
    required String userId,
    required String roleId,
    DateTime? expiresAt,
    String? assignedBy,
    String? note,
  }) async {
    final userRoleId = _firestore.collection(_userRolesCollection).doc().id;
    
    final userRole = UserRole(
      id: userRoleId,
      userId: userId,
      roleId: roleId,
      assignedAt: DateTime.now(),
      assignedBy: assignedBy ?? 'current_user_id',
      expiresAt: expiresAt,
      note: note,
      isActive: true,
    );

    await _firestore
        .collection(_userRolesCollection)
        .doc(userRoleId)
        .set(userRole.toMap());

    await _createAuditLog(
      'role_assigned',
      'Assignation de rôle à un utilisateur',
      {
        'user_id': userId,
        'role_id': roleId,
        'expires_at': expiresAt?.toIso8601String(),
        'assigned_by': assignedBy,
      },
    );
  }

  /// Révoque un rôle d'un utilisateur
  static Future<void> revokeRoleFromUser({
    required String userId,
    required String roleId,
    String? revokedBy,
    String? reason,
  }) async {
    final userRoleQuery = await _firestore
        .collection(_userRolesCollection)
        .where('user_id', isEqualTo: userId)
        .where('role_id', isEqualTo: roleId)
        .where('is_active', isEqualTo: true)
        .get();

    if (userRoleQuery.docs.isEmpty) {
      throw Exception('Assignation de rôle non trouvée');
    }

    final batch = _firestore.batch();
    
    for (final doc in userRoleQuery.docs) {
      batch.update(doc.reference, {
        'is_active': false,
        'revoked_at': FieldValue.serverTimestamp(),
        'revoked_by': revokedBy ?? 'current_user_id',
        'revocation_reason': reason,
      });
    }
    
    await batch.commit();

    await _createAuditLog(
      'role_revoked',
      'Révocation de rôle d\'un utilisateur',
      {
        'user_id': userId,
        'role_id': roleId,
        'reason': reason,
        'revoked_by': revokedBy,
      },
    );
  }

  /// Vérifie si un utilisateur a une permission spécifique
  static Future<bool> userHasPermission(String userId, String permissionId) async {
    try {
      // Récupérer tous les rôles actifs de l'utilisateur
      final userRolesQuery = await _firestore
          .collection(_userRolesCollection)
          .where('user_id', isEqualTo: userId)
          .where('is_active', isEqualTo: true)
          .get();

      if (userRolesQuery.docs.isEmpty) {
        return false;
      }

      // Vérifier si les rôles sont expirés
      final now = DateTime.now();
      final activeRoleIds = <String>[];
      
      for (final doc in userRolesQuery.docs) {
        final data = doc.data();
        final expiresAt = data['expires_at'] as Timestamp?;
        
        if (expiresAt == null || expiresAt.toDate().isAfter(now)) {
          activeRoleIds.add(data['role_id'] as String);
        }
      }

      if (activeRoleIds.isEmpty) {
        return false;
      }

      // Vérifier si l'un des rôles a la permission
      final rolesQuery = await _firestore
          .collection(_rolesCollection)
          .where(FieldPath.documentId, whereIn: activeRoleIds)
          .where('is_active', isEqualTo: true)
          .get();

      for (final doc in rolesQuery.docs) {
        final data = doc.data();
        final permissions = List<String>.from(data['permissions'] ?? []);
        if (permissions.contains(permissionId)) {
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('Erreur lors de la vérification des permissions: $e');
      return false;
    }
  }

  /// Récupère toutes les permissions d'un utilisateur
  static Future<List<String>> getUserPermissions(String userId) async {
    try {
      final userRolesQuery = await _firestore
          .collection(_userRolesCollection)
          .where('user_id', isEqualTo: userId)
          .where('is_active', isEqualTo: true)
          .get();

      if (userRolesQuery.docs.isEmpty) {
        return [];
      }

      // Vérifier si les rôles sont expirés
      final now = DateTime.now();
      final activeRoleIds = <String>[];
      
      for (final doc in userRolesQuery.docs) {
        final data = doc.data();
        final expiresAt = data['expires_at'] as Timestamp?;
        
        if (expiresAt == null || expiresAt.toDate().isAfter(now)) {
          activeRoleIds.add(data['role_id'] as String);
        }
      }

      if (activeRoleIds.isEmpty) {
        return [];
      }

      // Récupérer toutes les permissions des rôles actifs
      final rolesQuery = await _firestore
          .collection(_rolesCollection)
          .where(FieldPath.documentId, whereIn: activeRoleIds)
          .where('is_active', isEqualTo: true)
          .get();

      final permissions = <String>{};
      
      for (final doc in rolesQuery.docs) {
        final data = doc.data();
        final rolePermissions = List<String>.from(data['permissions'] ?? []);
        permissions.addAll(rolePermissions);
      }

      return permissions.toList();
    } catch (e) {
      debugPrint('Erreur lors de la récupération des permissions: $e');
      return [];
    }
  }

  /// Nettoie les rôles expirés
  static Future<int> cleanupExpiredRoles() async {
    try {
      final now = Timestamp.now();
      
      final expiredRolesQuery = await _firestore
          .collection(_userRolesCollection)
          .where('expires_at', isLessThan: now)
          .where('is_active', isEqualTo: true)
          .get();

      if (expiredRolesQuery.docs.isEmpty) {
        return 0;
      }

      final batch = _firestore.batch();
      
      for (final doc in expiredRolesQuery.docs) {
        batch.update(doc.reference, {
          'is_active': false,
          'expired_at': FieldValue.serverTimestamp(),
          'expired_by': 'system_cleanup',
        });
      }
      
      await batch.commit();

      await _createAuditLog(
        'roles_cleanup',
        'Nettoyage automatique des rôles expirés',
        {'cleaned_roles': expiredRolesQuery.docs.length},
      );

      return expiredRolesQuery.docs.length;
    } catch (e) {
      debugPrint('Erreur lors du nettoyage des rôles expirés: $e');
      return 0;
    }
  }

  /// Exporte la configuration complète des rôles et permissions
  static Future<Map<String, dynamic>> exportConfiguration() async {
    try {
      final roles = await _firestore.collection(_rolesCollection).get();
      final permissions = await _firestore.collection(_permissionsCollection).get();
      final userRoles = await _firestore.collection(_userRolesCollection).get();
      final settings = await _firestore.collection(_settingsCollection).doc('roles_permissions').get();

      return {
        'export_date': DateTime.now().toIso8601String(),
        'version': '1.0.0',
        'roles': roles.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList(),
        'permissions': permissions.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList(),
        'user_roles': userRoles.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList(),
        'settings': settings.exists ? settings.data() : {},
      };
    } catch (e) {
      debugPrint('Erreur lors de l\'export: $e');
      rethrow;
    }
  }

  /// Importe une configuration de rôles et permissions
  static Future<void> importConfiguration(Map<String, dynamic> config) async {
    try {
      final batch = _firestore.batch();

      // Importer les rôles
      if (config['roles'] != null) {
        for (final roleData in config['roles']) {
          final roleId = roleData['id'] as String;
          roleData.remove('id');
          batch.set(
            _firestore.collection(_rolesCollection).doc(roleId),
            roleData,
            SetOptions(merge: true),
          );
        }
      }

      // Importer les permissions
      if (config['permissions'] != null) {
        for (final permissionData in config['permissions']) {
          final permissionId = permissionData['id'] as String;
          permissionData.remove('id');
          batch.set(
            _firestore.collection(_permissionsCollection).doc(permissionId),
            permissionData,
            SetOptions(merge: true),
          );
        }
      }

      // Importer les paramètres
      if (config['settings'] != null) {
        batch.set(
          _firestore.collection(_settingsCollection).doc('roles_permissions'),
          config['settings'],
          SetOptions(merge: true),
        );
      }

      await batch.commit();

      await _createAuditLog(
        'configuration_imported',
        'Import de configuration des rôles et permissions',
        {
          'roles_count': config['roles']?.length ?? 0,
          'permissions_count': config['permissions']?.length ?? 0,
          'import_version': config['version'],
        },
      );
    } catch (e) {
      debugPrint('Erreur lors de l\'import: $e');
      rethrow;
    }
  }

  /// Récupère les statistiques des rôles
  static Future<Map<String, dynamic>> getRolesStatistics() async {
    try {
      final rolesSnapshot = await _firestore.collection(_rolesCollection).get();
      final userRolesSnapshot = await _firestore.collection(_userRolesCollection).get();
      
      final now = DateTime.now();
      var activeUserRoles = 0;
      var expiredUserRoles = 0;
      
      for (final doc in userRolesSnapshot.docs) {
        final data = doc.data();
        if (data['is_active'] == true) {
          final expiresAt = data['expires_at'] as Timestamp?;
          if (expiresAt == null || expiresAt.toDate().isAfter(now)) {
            activeUserRoles++;
          } else {
            expiredUserRoles++;
          }
        }
      }

      final totalRoles = rolesSnapshot.docs.length;
      final systemRoles = rolesSnapshot.docs
          .where((doc) => doc.data()['is_system_role'] == true)
          .length;
      final customRoles = totalRoles - systemRoles;
      final activeRoles = rolesSnapshot.docs
          .where((doc) => doc.data()['is_active'] == true)
          .length;

      return {
        'total_roles': totalRoles,
        'system_roles': systemRoles,
        'custom_roles': customRoles,
        'active_roles': activeRoles,
        'inactive_roles': totalRoles - activeRoles,
        'total_user_roles': userRolesSnapshot.docs.length,
        'active_user_roles': activeUserRoles,
        'expired_user_roles': expiredUserRoles,
      };
    } catch (e) {
      debugPrint('Erreur lors de la récupération des statistiques: $e');
      return {};
    }
  }

  /// Crée une entrée dans le journal d'audit
  static Future<void> _createAuditLog(
    String action,
    String description,
    Map<String, dynamic>? details,
  ) async {
    try {
      await _firestore.collection(_auditLogsCollection).add({
        'action': action,
        'description': description,
        'details': details ?? {},
        'user_id': 'current_user_id', // TODO: Récupérer l'ID utilisateur actuel
        'timestamp': FieldValue.serverTimestamp(),
        'module': 'roles_permissions',
      });
    } catch (e) {
      debugPrint('Erreur lors de la création du log d\'audit: $e');
    }
  }

  /// Récupère les rôles par défaut
  static List<Role> _getDefaultRoles() {
    return [
      Role(
        id: 'super_admin',
        name: 'Super Administrateur',
        description: 'Accès complet à toutes les fonctionnalités du système',
        color: '#F44336',
        icon: 'security',
        isActive: true,
        permissions: _getAllPermissionIds(),
        createdAt: DateTime.now(),
        createdBy: 'system',
      ),
      Role(
        id: 'admin',
        name: 'Administrateur',
        description: 'Accès administrateur avec restrictions sur la gestion des utilisateurs',
        color: '#FF9800',
        icon: 'admin_panel_settings',
        isActive: true,
        permissions: _getAdminPermissionIds(),
        createdAt: DateTime.now(),
        createdBy: 'system',
      ),
      Role(
        id: 'moderator',
        name: 'Modérateur',
        description: 'Accès modéré pour la gestion du contenu',
        color: '#2196F3',
        icon: 'supervisor_account',
        isSystemRole: true,
        isActive: true,
        permissions: _getModeratorPermissionIds(),
        createdAt: DateTime.now(),
      ),
      Role(
        id: 'contributor',
        name: 'Contributeur',
        description: 'Accès pour créer et modifier du contenu',
        color: '#4CAF50',
        icon: 'edit',
        isSystemRole: true,
        isActive: true,
        permissions: _getContributorPermissionIds(),
        createdAt: DateTime.now(),
      ),
      Role(
        id: 'viewer',
        name: 'Lecteur',
        description: 'Accès en lecture seule',
        color: '#9E9E9E',
        icon: 'visibility',
        isSystemRole: true,
        isActive: true,
        permissions: _getViewerPermissionIds(),
        createdAt: DateTime.now(),
      ),
    ];
  }

  /// Récupère les permissions par défaut
  static List<Permission> _getDefaultPermissions() {
    return [
      // Permissions Dashboard
      Permission(
        id: 'dashboard_view',
        name: 'Voir le tableau de bord',
        description: 'Accès au tableau de bord principal',
        module: 'dashboard',
        level: PermissionLevel.read,
      ),
      
      // Permissions Rôles
      Permission(
        id: 'roles_view',
        name: 'Voir les rôles',
        description: 'Voir la liste des rôles',
        module: 'roles',
        level: PermissionLevel.read,
      ),
      Permission(
        id: 'roles_create',
        name: 'Créer des rôles',
        description: 'Créer de nouveaux rôles',
        module: 'roles',
        level: PermissionLevel.create,
      ),
      Permission(
        id: 'roles_edit',
        name: 'Modifier les rôles',
        description: 'Modifier les rôles existants',
        module: 'roles',
        level: PermissionLevel.write,
      ),
      Permission(
        id: 'roles_delete',
        name: 'Supprimer les rôles',
        description: 'Supprimer des rôles',
        module: 'roles',
        level: PermissionLevel.delete,
      ),
      Permission(
        id: 'roles_assign',
        name: 'Assigner des rôles',
        description: 'Assigner des rôles aux utilisateurs',
        module: 'roles',
        level: PermissionLevel.admin,
      ),
      
      // Permissions Utilisateurs
      Permission(
        id: 'users_view',
        name: 'Voir les utilisateurs',
        description: 'Voir la liste des utilisateurs',
        module: 'users',
        level: PermissionLevel.read,
      ),
      Permission(
        id: 'users_create',
        name: 'Créer des utilisateurs',
        description: 'Créer de nouveaux utilisateurs',
        module: 'users',
        level: PermissionLevel.create,
      ),
      Permission(
        id: 'users_edit',
        name: 'Modifier les utilisateurs',
        description: 'Modifier les profils utilisateurs',
        module: 'users',
        level: PermissionLevel.write,
      ),
      Permission(
        id: 'users_delete',
        name: 'Supprimer les utilisateurs',
        description: 'Supprimer des utilisateurs',
        module: 'users',
        level: PermissionLevel.delete,
      ),
      
      // Permissions Contenu
      Permission(
        id: 'content_view',
        name: 'Voir le contenu',
        description: 'Accès au contenu',
        module: 'content',
        level: PermissionLevel.read,
      ),
      Permission(
        id: 'content_create',
        name: 'Créer du contenu',
        description: 'Créer du nouveau contenu',
        module: 'content',
        level: PermissionLevel.create,
      ),
      Permission(
        id: 'content_edit',
        name: 'Modifier le contenu',
        description: 'Modifier le contenu existant',
        module: 'content',
        level: PermissionLevel.write,
      ),
      Permission(
        id: 'content_delete',
        name: 'Supprimer le contenu',
        description: 'Supprimer du contenu',
        module: 'content',
        level: PermissionLevel.delete,
      ),
      
      // Permissions Paramètres
      Permission(
        id: 'settings_view',
        name: 'Voir les paramètres',
        description: 'Accès aux paramètres',
        module: 'settings',
        level: PermissionLevel.read,
      ),
      Permission(
        id: 'settings_edit',
        name: 'Modifier les paramètres',
        description: 'Modifier les paramètres système',
        module: 'settings',
        level: PermissionLevel.admin,
      ),
    ];
  }

  // Méthodes d'aide pour les permissions par rôle
  static List<String> _getAllPermissionIds() {
    return _getDefaultPermissions().map((p) => p.id).toList();
  }

  static List<String> _getAdminPermissionIds() {
    return [
      'dashboard_view',
      'roles_view', 'roles_create', 'roles_edit', 'roles_assign',
      'users_view', 'users_create', 'users_edit',
      'content_view', 'content_create', 'content_edit', 'content_delete',
      'settings_view',
    ];
  }

  static List<String> _getModeratorPermissionIds() {
    return [
      'dashboard_view',
      'roles_view',
      'users_view',
      'content_view', 'content_create', 'content_edit', 'content_delete',
    ];
  }

  static List<String> _getContributorPermissionIds() {
    return [
      'dashboard_view',
      'content_view', 'content_create', 'content_edit',
    ];
  }

  static List<String> _getViewerPermissionIds() {
    return [
      'dashboard_view',
      'content_view',
    ];
  }
}