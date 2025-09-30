import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import '../../modules/roles/models/permission_model.dart';
import '../../modules/roles/models/user_role_model.dart';
import '../../modules/roles/services/roles_permissions_service.dart';

/// Tests unitaires pour le module Rôles et Permissions
void main() {
  group('Permission Model Tests', () {
    test('Permission creation and properties', () {
      final permission = Permission(
        id: 'test_read',
        name: 'Test Read',
        description: 'Test reading permission',
        moduleId: 'test_module',
        level: PermissionLevel.read,
      );

      expect(permission.id, equals('test_read'));
      expect(permission.name, equals('Test Read'));
      expect(permission.level, equals(PermissionLevel.read));
      expect(permission.moduleId, equals('test_module'));
    });

    test('Permission level display names', () {
      expect(PermissionLevel.read.displayName, equals('Lecture'));
      expect(PermissionLevel.write.displayName, equals('Écriture'));
      expect(PermissionLevel.create.displayName, equals('Création'));
      expect(PermissionLevel.delete.displayName, equals('Suppression'));
      expect(PermissionLevel.admin.displayName, equals('Administration'));
    });

    test('Permission level priorities', () {
      expect(PermissionLevel.read.priority, equals(1));
      expect(PermissionLevel.write.priority, equals(2));
      expect(PermissionLevel.create.priority, equals(3));
      expect(PermissionLevel.delete.priority, equals(4));
      expect(PermissionLevel.admin.priority, equals(5));
    });
  });

  group('Role Model Tests', () {
    test('Role creation with valid data', () {
      final role = Role(
        id: 'test_role',
        name: 'Test Role',
        description: 'A test role',
        modulePermissions: {
          'users': {'users_read', 'users_write'},
          'events': {'events_read'},
        },
        color: '#FF5722',
        icon: 'person',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(role.id, equals('test_role'));
      expect(role.name, equals('Test Role'));
      expect(role.isActive, isTrue);
      expect(role.isSystemRole, isFalse);
      expect(role.modulePermissions.length, equals(2));
      expect(role.allPermissions.length, equals(3));
    });

    test('Role validation', () {
      // Test nom valide
      expect(Role.isValidName('Test Role'), isTrue);
      expect(Role.isValidName(''), isFalse);
      expect(Role.isValidName('A'), isFalse);

      // Test couleur valide
      expect(Role.isValidColor('#FF5722'), isTrue);
      expect(Role.isValidColor('#ff5722'), isTrue);
      expect(Role.isValidColor('FF5722'), isFalse);
      expect(Role.isValidColor('#GG5722'), isFalse);

      // Test validation complète
      final validRole = Role(
        id: 'valid',
        name: 'Valid Role',
        description: 'Valid description',
        modulePermissions: {'test': {'test_read'}},
        color: '#FF5722',
        icon: 'person',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final invalidRole = Role(
        id: '',
        name: 'A',
        description: '',
        modulePermissions: {},
        color: 'invalid',
        icon: '',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(validRole.isValid(), isTrue);
      expect(invalidRole.isValid(), isFalse);
    });
  });

  group('AppModule Tests', () {
    test('All modules are properly defined', () {
      expect(AppModule.allModules.isNotEmpty, isTrue);
      
      for (final module in AppModule.allModules) {
        expect(module.id.isNotEmpty, isTrue);
        expect(module.name.isNotEmpty, isTrue);
        expect(module.icon.isNotEmpty, isTrue);
        expect(module.permissions.isNotEmpty, isTrue);
      }
    });

    test('Module permissions are consistent', () {
      for (final module in AppModule.allModules) {
        for (final permission in module.permissions) {
          expect(permission.moduleId, equals(module.id));
          expect(permission.id.startsWith(module.id), isTrue);
        }
      }
    });

    test('Find module by ID', () {
      const testId = 'utilisateurs';
      final module = AppModule.allModules
          .where((m) => m.id == testId)
          .firstOrNull;
      
      expect(module, isNotNull);
      if (module != null) {
        expect(module.id, equals(testId));
      }
    });
  });

  group('UserRole Model Tests', () {
    test('UserRole creation and properties', () {
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(days: 30));
      
      final userRole = UserRole(
        id: 'ur_123',
        userId: 'user_123',
        roleId: 'role_123',
        assignedAt: now,
        assignedBy: 'admin_123',
        expiresAt: expiresAt,
      );

      expect(userRole.id, equals('ur_123'));
      expect(userRole.userId, equals('user_123'));
      expect(userRole.roleId, equals('role_123'));
      expect(userRole.expiresAt, equals(expiresAt));
      expect(userRole.isExpired(), isFalse);
      expect(userRole.isTemporary(), isTrue);
    });

    test('UserRole expiration logic', () {
      final now = DateTime.now();
      
      // Rôle expiré
      final expiredRole = UserRole(
        id: 'expired',
        userId: 'user1',
        roleId: 'role1',
        assignedAt: now.subtract(const Duration(days: 60)),
        assignedBy: 'admin',
        expiresAt: now.subtract(const Duration(days: 1)),
      );
      
      expect(expiredRole.isExpired(), isTrue);

      // Rôle permanent
      final permanentRole = UserRole(
        id: 'permanent',
        userId: 'user1',
        roleId: 'role1',
        assignedAt: now,
        assignedBy: 'admin',
      );
      
      expect(permanentRole.isTemporary(), isFalse);
      expect(permanentRole.isExpired(), isFalse);
    });

    test('UserRole statistics', () {
      final stats = UserRoleStats();
      
      // Ajouter des données de test
      stats.totalAssignments = 100;
      stats.activeAssignments = 85;
      stats.expiredAssignments = 15;
      stats.temporaryAssignments = 30;
      
      expect(stats.totalAssignments, equals(100));
      expect(stats.activeAssignments, equals(85));
      expect(stats.expiredAssignments, equals(15));
      expect(stats.temporaryAssignments, equals(30));
      expect(stats.permanentAssignments, equals(70));
    });
  });

  group('RolesPermissionsService Tests', () {
    test('System roles generation', () {
      final systemRoles = RolesPermissionsService.getSystemRoles();
      
      expect(systemRoles.isNotEmpty, isTrue);
      
      for (final role in systemRoles) {
        expect(role.isSystemRole, isTrue);
        expect(role.name.isNotEmpty, isTrue);
        expect(role.description.isNotEmpty, isTrue);
        expect(role.isValid(), isTrue);
      }
    });

    test('Permission validation', () {
      // Test permission valide
      expect(
        RolesPermissionsService.isValidPermission('users_read'),
        isTrue,
      );
      
      // Test permission invalide
      expect(
        RolesPermissionsService.isValidPermission('invalid_permission'),
        isFalse,
      );
      
      expect(
        RolesPermissionsService.isValidPermission(''),
        isFalse,
      );
    });

    test('Role conflict detection', () {
      final role1 = Role(
        id: 'role1',
        name: 'Role 1',
        description: 'First role',
        modulePermissions: {'users': {'users_read'}},
        color: '#FF5722',
        icon: 'person',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final role2 = Role(
        id: 'role2',
        name: 'Role 1', // Même nom
        description: 'Second role',
        modulePermissions: {'events': {'events_read'}},
        color: '#2196F3',
        icon: 'event',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(
        RolesPermissionsService.hasNameConflict(role1, [role2]),
        isTrue,
      );
    });
  });

  group('Integration Tests', () {
    test('Complete role lifecycle', () {
      // 1. Créer un rôle
      final role = Role(
        id: 'integration_test',
        name: 'Integration Test Role',
        description: 'Role for integration testing',
        modulePermissions: {
          'users': {'users_read', 'users_write'},
          'events': {'events_read'},
        },
        color: '#4CAF50',
        icon: 'verified_user',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(role.isValid(), isTrue);

      // 2. Assigner à un utilisateur
      final userRole = UserRole(
        id: 'ur_integration',
        userId: 'test_user',
        roleId: role.id,
        assignedAt: DateTime.now(),
        assignedBy: 'admin',
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );

      expect(userRole.isExpired(), isFalse);
      expect(userRole.isTemporary(), isTrue);

      // 3. Vérifier les permissions
      expect(role.hasPermission('users_read'), isTrue);
      expect(role.hasPermission('users_admin'), isFalse);
      expect(role.hasModulePermission('users', 'users_write'), isTrue);
      expect(role.hasModulePermission('settings', 'settings_read'), isFalse);
    });

    test('System initialization', () {
      final systemRoles = RolesPermissionsService.getSystemRoles();
      final allModules = AppModule.allModules;
      
      expect(systemRoles.length, greaterThan(0));
      expect(allModules.length, greaterThan(0));
      
      // Vérifier que l'administrateur a toutes les permissions
      final adminRole = systemRoles.firstWhere(
        (role) => role.name.toLowerCase().contains('administrateur'),
        orElse: () => systemRoles.first,
      );
      
      expect(adminRole.modulePermissions.isNotEmpty, isTrue);
      
      // Vérifier la cohérence des données
      for (final module in allModules) {
        expect(module.permissions.isNotEmpty, isTrue);
        for (final permission in module.permissions) {
          expect(permission.moduleId, equals(module.id));
        }
      }
    });
  });

  group('Performance Tests', () {
    test('Permission checking performance', () {
      final role = Role(
        id: 'perf_test',
        name: 'Performance Test',
        description: 'Test performance',
        modulePermissions: Map.fromEntries(
          AppModule.allModules.map((module) => MapEntry(
            module.id,
            Set.from(module.permissions.map((p) => p.id)),
          )),
        ),
        color: '#9C27B0',
        icon: 'speed',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final stopwatch = Stopwatch()..start();
      
      // Tester 1000 vérifications de permissions
      for (int i = 0; i < 1000; i++) {
        role.hasPermission('users_read');
        role.hasModulePermission('events', 'events_create');
      }
      
      stopwatch.stop();
      
      // Les vérifications doivent être rapides (moins de 100ms pour 1000 checks)
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    test('Role validation performance', () {
      final roles = List.generate(100, (i) => Role(
        id: 'role_$i',
        name: 'Role $i',
        description: 'Description $i',
        modulePermissions: {'users': {'users_read'}},
        color: '#FF5722',
        icon: 'person',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final stopwatch = Stopwatch()..start();
      
      for (final role in roles) {
        role.isValid();
      }
      
      stopwatch.stop();
      
      // Validation de 100 rôles doit être rapide
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
    });
  });
}

/// Helper class pour les tests
class TestHelpers {
  static Role createTestRole({
    String id = 'test_role',
    String name = 'Test Role',
    Map<String, Set<String>>? permissions,
    bool isActive = true,
  }) {
    return Role(
      id: id,
      name: name,
      description: 'Test role for unit testing',
      modulePermissions: permissions ?? {'users': {'users_read'}},
      color: '#2196F3',
      icon: 'person',
      isActive: isActive,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static UserRole createTestUserRole({
    String id = 'test_user_role',
    String userId = 'test_user',
    String roleId = 'test_role',
    DateTime? expiresAt,
  }) {
    return UserRole(
      id: id,
      userId: userId,
      roleId: roleId,
      assignedAt: DateTime.now(),
      assignedBy: 'test_admin',
      expiresAt: expiresAt,
    );
  }
}