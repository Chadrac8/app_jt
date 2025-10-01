/// Configuration des permissions administrateur
/// Définit quelles permissions donnent accès à la vue admin
class AdminPermissionsConfig {
  // Permissions qui donnent un accès complet à l'administration
  static const List<String> superAdminPermissions = [
    'system_admin',
    'super_admin',
    'full_admin_access',
  ];

  // Permissions qui donnent accès à des sections spécifiques de l'admin
  static const List<String> adminPermissions = [
    'admin_panel_access',
    'manage_roles',
    'manage_users',
    'manage_permissions',
    'view_admin_dashboard',
    'system_configuration',
    'manage_modules',
    'view_audit_logs',
    'manage_content',
    'system_maintenance',
  ];

  // Modules avec niveau administrateur qui donnent accès
  static const List<String> adminModules = [
    'administration',
    'system',
    'user_management',
    'role_management',
    'security',
  ];

  /// Vérifie si une permission est considérée comme administrative
  static bool isAdminPermission(String permissionId) {
    return superAdminPermissions.contains(permissionId) ||
           adminPermissions.contains(permissionId);
  }

  /// Vérifie si un module est considéré comme administratif
  static bool isAdminModule(String moduleId) {
    return adminModules.contains(moduleId);
  }

  /// Retourne toutes les permissions qui donnent accès à l'admin
  static List<String> getAllAdminPermissions() {
    return [...superAdminPermissions, ...adminPermissions];
  }

  /// Retourne les permissions par catégorie
  static Map<String, List<String>> getPermissionsByCategory() {
    return {
      'super_admin': superAdminPermissions,
      'admin': adminPermissions,
      'modules': adminModules,
    };
  }
}