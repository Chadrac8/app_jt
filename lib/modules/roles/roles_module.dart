// Module Roles et Permissions - Point d'entree principal
library roles_module;

import 'package:flutter/material.dart';
import 'models/permission.dart';
import 'models/role.dart';
import 'models/user_role.dart';
import 'services/role_service.dart';
import 'providers/role_provider.dart';
import '../../../theme.dart';

// Modeles
export 'models/permission.dart';
export 'models/role.dart';
export 'models/user_role.dart';

// Services
export 'services/role_service.dart';

// Providers
export 'providers/role_provider.dart';

// Vues
export 'views/roles_management_screen.dart';

// Widgets
export 'widgets/user_role_assignment_widget.dart';

// Utilitaires et helpers
class RolesModule {
  static const String moduleName = 'Roles et Permissions';
  static const String moduleId = 'roles';
  static const String moduleVersion = '1.0.0';
  
  static final RoleService _roleService = RoleService();
  
  /// Initialise le module de roles et permissions
  static Future<void> initialize() async {
    try {
      await _roleService.initializeDefaultRolesAndPermissions();
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation du module roles: $e');
    }
  }
  
  /// Verifie si un utilisateur a une permission specifique
  static Future<bool> checkPermission(String userId, String permissionId) async {
    try {
      return await _roleService.userHasPermission(userId, permissionId);
    } catch (e) {
      debugPrint('Erreur lors de la verification de permission: $e');
      return false;
    }
  }
  
  /// Obtient toutes les permissions d'un utilisateur
  static Future<List<String>> getUserPermissions(String userId) async {
    try {
      return await _roleService.getUserPermissions(userId);
    } catch (e) {
      debugPrint('Erreur lors de la recuperation des permissions: $e');
      return [];
    }
  }
  
  /// Obtient les roles d'un utilisateur
  static Future<UserRole?> getUserRoles(String userId) async {
    try {
      return await _roleService.getUserRoles(userId);
    } catch (e) {
      debugPrint('Erreur lors de la recuperation des roles utilisateur: $e');
      return null;
    }
  }
  
  /// Obtient les statistiques des roles
  static Future<Map<String, int>> getStatistics() async {
    try {
      return await _roleService.getRoleStatistics();
    } catch (e) {
      debugPrint('Erreur lors du calcul des statistiques: $e');
      return {};
    }
  }
  
  /// Valide si un role peut etre supprime
  static Future<bool> canDeleteRole(String roleId) async {
    try {
      await _roleService.deleteRole(roleId);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Cree un provider pre-configure pour le module
  static RoleProvider createProvider() {
    return RoleProvider();
  }
  
  /// Obtient la liste des modules disponibles
  static List<String> getAvailableModules() {
    return [
      'users',
      'roles',
      'content',
      'settings',
      'notifications',
      'analytics',
      'reports',
    ];
  }
  
  /// Obtient les actions disponibles
  static List<String> getAvailableActions() {
    return [
      'read',
      'write',
      'delete',
      'create',
      'update',
      'manage',
    ];
  }
  
  /// Genere un ID de permission standardise
  static String generatePermissionId(String module, String action) {
    return '$module.$action';
  }
  
  /// Valide un ID de permission
  static bool isValidPermissionId(String permissionId) {
    final parts = permissionId.split('.');
    return parts.length == 2 && 
           parts[0].isNotEmpty && 
           parts[1].isNotEmpty;
  }
  
  /// Obtient la couleur associee a un module
  static Color getModuleColor(String module) {
    switch (module.toLowerCase()) {
      case 'users': return AppTheme.blueStandard;
      case 'roles': return AppTheme.primaryColor;
      case 'content': return AppTheme.greenStandard;
      case 'settings': return AppTheme.orangeStandard;
      case 'notifications': return AppTheme.redStandard;
      case 'analytics': return AppTheme.secondaryColor;
      case 'reports': return AppTheme.secondaryColor;
      default: return AppTheme.grey500;
    }
  }
  
  /// Obtient l'icone associee a un module
  static IconData getModuleIcon(String module) {
    switch (module.toLowerCase()) {
      case 'users': return Icons.people;
      case 'roles': return Icons.security;
      case 'content': return Icons.article;
      case 'settings': return Icons.settings;
      case 'notifications': return Icons.notifications;
      case 'analytics': return Icons.analytics;
      case 'reports': return Icons.assessment;
      default: return Icons.extension;
    }
  }
  
  /// Obtient l'icone associee a une action
  static IconData getActionIcon(String action) {
    switch (action.toLowerCase()) {
      case 'read': return Icons.visibility;
      case 'write': return Icons.edit;
      case 'delete': return Icons.delete;
      case 'create': return Icons.add;
      case 'update': return Icons.update;
      case 'manage': return Icons.admin_panel_settings;
      default: return Icons.help;
    }
  }
  
  /// Formate un nom de permission pour l'affichage
  static String formatPermissionName(String permissionId) {
    if (!isValidPermissionId(permissionId)) return permissionId;
    
    final parts = permissionId.split('.');
    final module = parts[0];
    final action = parts[1];
    
    return '${_capitalize(action)} ${_capitalize(module)}';
  }
  
  /// Formate un nom de role pour l'affichage
  static String formatRoleName(String roleName) {
    return roleName.split('_')
        .map((word) => _capitalize(word))
        .join(' ');
  }
  
  static String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
  
  /// Verifie si le module est correctement configure
  static Future<bool> isModuleHealthy() async {
    try {
      // Verifier la connexion au service
      final roles = await _roleService.getAllRoles().first;
      
      // Verifier qu'il y a au moins un role admin
      final hasAdmin = roles.any((role) => 
          role.id == 'admin' || role.name.toLowerCase().contains('admin'));
      
      return hasAdmin;
    } catch (e) {
      debugPrint('Module roles non fonctionnel: $e');
      return false;
    }
  }
  
  /// Obtient des informations de diagnostic du module
  static Future<Map<String, dynamic>> getDiagnostics() async {
    try {
      final roles = await _roleService.getAllRoles().first;
      final userRoles = await _roleService.getAllUserRoles().first;
      final permissions = await _roleService.getAllPermissions().first;
      
      return {
        'module_name': moduleName,
        'module_version': moduleVersion,
        'total_roles': roles.length,
        'active_roles': roles.where((r) => r.isActive).length,
        'total_users_with_roles': userRoles.length,
        'active_users_with_roles': userRoles.where((u) => u.isActive).length,
        'total_permissions': permissions.length,
        'last_check': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'module_name': moduleName,
        'module_version': moduleVersion,
        'error': e.toString(),
        'last_check': DateTime.now().toIso8601String(),
      };
    }
  }
}
