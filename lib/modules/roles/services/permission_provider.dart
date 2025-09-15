import 'package:flutter/foundation.dart';
import '../models/permission_model.dart';
import '../services/permission_service.dart';

class PermissionProvider with ChangeNotifier {
  List<Permission> _permissions = [];
  List<Role> _roles = [];
  List<UserRole> _userRoles = [];
  Map<String, List<Permission>> _permissionsByModule = {};
  Map<String, List<String>> _userPermissions = {};
  
  bool _isLoading = false;
  String? _error;
  String? _currentUserId;

  // Getters
  List<Permission> get permissions => _permissions;
  List<Role> get roles => _roles;
  List<UserRole> get userRoles => _userRoles;
  Map<String, List<Permission>> get permissionsByModule => _permissionsByModule;
  Map<String, List<String>> get userPermissions => _userPermissions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentUserId => _currentUserId;

  /// Initialise le provider avec l'ID de l'utilisateur courant
  void initialize(String userId) {
    _currentUserId = userId;
    loadUserData();
  }

  /// Charge toutes les données nécessaires
  Future<void> loadUserData() async {
    if (_currentUserId == null) return;
    
    setLoading(true);
    try {
      await Future.wait([
        loadPermissions(),
        loadRoles(),
        loadUserRoles(_currentUserId!),
        loadUserPermissions(_currentUserId!),
      ]);
      clearError();
    } catch (e) {
      setError('Erreur lors du chargement des données: $e');
    } finally {
      setLoading(false);
    }
  }

  /// Charge toutes les permissions
  Future<void> loadPermissions() async {
    try {
      final permissionsStream = PermissionService.getAllPermissions();
      await for (final permissions in permissionsStream.take(1)) {
        _permissions = permissions;
        _organizePermissionsByModule();
        break;
      }
    } catch (e) {
      setError('Erreur lors du chargement des permissions: $e');
    }
  }

  /// Charge tous les rôles
  Future<void> loadRoles() async {
    try {
      final rolesStream = PermissionService.getAllRoles();
      await for (final roles in rolesStream.take(1)) {
        _roles = roles;
        break;
      }
    } catch (e) {
      setError('Erreur lors du chargement des rôles: $e');
    }
  }

  /// Charge les rôles d'un utilisateur
  Future<void> loadUserRoles(String userId) async {
    try {
      final userRolesStream = PermissionService.getUserRoles(userId);
      await for (final userRoles in userRolesStream.take(1)) {
        _userRoles = userRoles;
        break;
      }
    } catch (e) {
      setError('Erreur lors du chargement des rôles utilisateur: $e');
    }
  }

  /// Charge les permissions d'un utilisateur
  Future<void> loadUserPermissions(String userId) async {
    try {
      final permissions = await PermissionService.getUserPermissions(userId);
      _userPermissions[userId] = permissions;
    } catch (e) {
      setError('Erreur lors du chargement des permissions utilisateur: $e');
    }
  }

  /// Organise les permissions par module
  void _organizePermissionsByModule() {
    _permissionsByModule.clear();
    for (final permission in _permissions) {
      if (!_permissionsByModule.containsKey(permission.module)) {
        _permissionsByModule[permission.module] = [];
      }
      _permissionsByModule[permission.module]!.add(permission);
    }
  }

  /// Crée un nouveau rôle
  Future<bool> createRole(Role role) async {
    setLoading(true);
    try {
      final roleId = await PermissionService.createRole(role);
      final newRole = role.copyWith(id: roleId);
      _roles.add(newRole);
      notifyListeners();
      clearError();
      return true;
    } catch (e) {
      setError('Erreur lors de la création du rôle: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  /// Met à jour un rôle
  Future<bool> updateRole(String roleId, Role role) async {
    setLoading(true);
    try {
      await PermissionService.updateRole(roleId, role);
      final index = _roles.indexWhere((r) => r.id == roleId);
      if (index != -1) {
        _roles[index] = role.copyWith(id: roleId);
        notifyListeners();
      }
      clearError();
      return true;
    } catch (e) {
      setError('Erreur lors de la mise à jour du rôle: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  /// Supprime un rôle
  Future<bool> deleteRole(String roleId) async {
    setLoading(true);
    try {
      await PermissionService.deleteRole(roleId);
      _roles.removeWhere((role) => role.id == roleId);
      notifyListeners();
      clearError();
      return true;
    } catch (e) {
      setError('Erreur lors de la suppression du rôle: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  /// Assigne un rôle à un utilisateur
  Future<bool> assignRoleToUser({
    required String userId,
    required String roleId,
    required String assignedBy,
    DateTime? expiresAt,
    Map<String, dynamic>? metadata,
  }) async {
    setLoading(true);
    try {
      await PermissionService.assignRoleToUser(
        userId: userId,
        roleId: roleId,
        assignedBy: assignedBy,
        expiresAt: expiresAt,
        metadata: metadata,
      );

      // Recharger les données utilisateur si c'est l'utilisateur courant
      if (userId == _currentUserId) {
        await loadUserRoles(userId);
        await loadUserPermissions(userId);
      }

      clearError();
      return true;
    } catch (e) {
      setError('Erreur lors de l\'assignation du rôle: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  /// Révoque un rôle d'un utilisateur
  Future<bool> revokeRoleFromUser(String userId, String roleId) async {
    setLoading(true);
    try {
      await PermissionService.revokeRoleFromUser(userId, roleId);

      // Recharger les données utilisateur si c'est l'utilisateur courant
      if (userId == _currentUserId) {
        await loadUserRoles(userId);
        await loadUserPermissions(userId);
      }

      clearError();
      return true;
    } catch (e) {
      setError('Erreur lors de la révocation du rôle: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  /// Vérifie si l'utilisateur courant a une permission
  bool hasPermission(String permissionId) {
    if (_currentUserId == null) return false;
    final userPerms = _userPermissions[_currentUserId!] ?? [];
    return userPerms.contains(permissionId);
  }

  /// Vérifie si l'utilisateur courant a accès à un module
  bool hasModuleAccess(String moduleId) {
    if (_currentUserId == null) return false;
    final userPerms = _userPermissions[_currentUserId!] ?? [];
    return userPerms.any((perm) => perm.startsWith('${moduleId}_'));
  }

  /// Vérifie si l'utilisateur courant a une permission de niveau spécifique pour un module
  bool hasModulePermissionLevel(String moduleId, PermissionLevel level) {
    if (_currentUserId == null) return false;
    final userPerms = _userPermissions[_currentUserId!] ?? [];
    return userPerms.any((perm) => perm.startsWith('${moduleId}_') && perm.endsWith('_${level.name}'));
  }

  /// Vérifie si l'utilisateur courant peut effectuer une action sur une catégorie
  bool canPerformAction(String moduleId, String category, PermissionLevel level) {
    if (_currentUserId == null) return false;
    final permissionId = '${moduleId}_${category.toLowerCase()}_${level.name}';
    return hasPermission(permissionId);
  }

  /// Vérifie si l'utilisateur courant a un rôle administrateur
  bool hasAdminRole() {
    if (_currentUserId == null) return false;
    
    final userRolesList = _userRoles.where((ur) => 
      ur.userId == _currentUserId && 
      ur.isActive && 
      !ur.isExpired
    ).toList();
    
    if (userRolesList.isEmpty) return false;
    
    // Vérifier si l'utilisateur a un rôle admin ou super_admin
    for (final userRole in userRolesList) {
      final role = _roles.where((r) => r.id == userRole.roleId).firstOrNull;
      if (role != null && role.isActive) {
        final roleName = role.name.toLowerCase();
        final roleId = role.id.toLowerCase();
        if (roleId == 'admin' || 
            roleId == 'super_admin' || 
            roleName.contains('admin') || 
            roleName.contains('administrateur')) {
          return true;
        }
      }
    }
    
    return false;
  }

  /// Vérifie si un utilisateur spécifique a un rôle administrateur
  bool userHasAdminRole(String userId) {
    final userRolesList = _userRoles.where((ur) => 
      ur.userId == userId && 
      ur.isActive && 
      !ur.isExpired
    ).toList();
    
    if (userRolesList.isEmpty) return false;
    
    // Vérifier si l'utilisateur a un rôle admin ou super_admin
    for (final userRole in userRolesList) {
      final role = _roles.where((r) => r.id == userRole.roleId).firstOrNull;
      if (role != null && role.isActive) {
        final roleName = role.name.toLowerCase();
        final roleId = role.id.toLowerCase();
        if (roleId == 'admin' || 
            roleId == 'super_admin' || 
            roleName.contains('admin') || 
            roleName.contains('administrateur')) {
          return true;
        }
      }
    }
    
    return false;
  }

  /// Obtient les permissions de l'utilisateur courant pour un module
  List<String> getUserModulePermissions(String moduleId) {
    if (_currentUserId == null) return [];
    final userPerms = _userPermissions[_currentUserId!] ?? [];
    return userPerms.where((perm) => perm.startsWith('${moduleId}_')).toList();
  }

  /// Obtient les rôles de l'utilisateur courant
  List<Role> getCurrentUserRoles() {
    if (_currentUserId == null) return [];
    final userRoleIds = _userRoles.map((ur) => ur.roleId).toList();
    return _roles.where((role) => userRoleIds.contains(role.id)).toList();
  }

  /// Obtient un rôle par ID
  Role? getRoleById(String roleId) {
    try {
      return _roles.firstWhere((role) => role.id == roleId);
    } catch (e) {
      return null;
    }
  }

  /// Obtient une permission par ID
  Permission? getPermissionById(String permissionId) {
    try {
      return _permissions.firstWhere((perm) => perm.id == permissionId);
    } catch (e) {
      return null;
    }
  }

  /// Obtient les rôles disponibles (actifs et non système)
  List<Role> getAvailableRoles() {
    return _roles.where((role) => role.isActive && !role.isSystemRole).toList();
  }

  /// Obtient les rôles système
  List<Role> getSystemRoles() {
    return _roles.where((role) => role.isSystemRole).toList();
  }

  /// Filtre les permissions par module
  List<Permission> getPermissionsForModule(String moduleId) {
    return _permissionsByModule[moduleId] ?? [];
  }

  /// Filtre les permissions par catégorie
  List<Permission> getPermissionsForCategory(String category) {
    return _permissions.where((perm) => perm.category == category).toList();
  }

  /// Obtient les modules disponibles avec leurs permissions
  Map<AppModule, List<Permission>> getModulesWithPermissions() {
    final result = <AppModule, List<Permission>>{};
    for (final module in AppModule.allModules) {
      final modulePermissions = getPermissionsForModule(module.id);
      if (modulePermissions.isNotEmpty) {
        result[module] = modulePermissions;
      }
    }
    return result;
  }

  /// Initialise les permissions et rôles par défaut
  Future<bool> initializeDefaultData() async {
    setLoading(true);
    try {
      await PermissionService.initializeDefaultPermissions();
      await PermissionService.initializeDefaultRoles();
      await loadUserData();
      clearError();
      return true;
    } catch (e) {
      setError('Erreur lors de l\'initialisation: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  /// Nettoie les rôles expirés
  Future<void> cleanupExpiredRoles() async {
    try {
      await PermissionService.cleanupExpiredRoles();
      if (_currentUserId != null) {
        await loadUserRoles(_currentUserId!);
        await loadUserPermissions(_currentUserId!);
      }
    } catch (e) {
      setError('Erreur lors du nettoyage: $e');
    }
  }

  /// Exporte la configuration
  Future<Map<String, dynamic>?> exportConfiguration() async {
    try {
      return await PermissionService.exportConfiguration();
    } catch (e) {
      setError('Erreur lors de l\'exportation: $e');
      return null;
    }
  }

  /// Importe la configuration
  Future<bool> importConfiguration(Map<String, dynamic> config) async {
    setLoading(true);
    try {
      await PermissionService.importConfiguration(config);
      await loadUserData();
      clearError();
      return true;
    } catch (e) {
      setError('Erreur lors de l\'importation: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  /// Recherche dans les rôles
  List<Role> searchRoles(String query) {
    if (query.isEmpty) return _roles;
    final lowercaseQuery = query.toLowerCase();
    return _roles.where((role) =>
        role.name.toLowerCase().contains(lowercaseQuery) ||
        role.description.toLowerCase().contains(lowercaseQuery)
    ).toList();
  }

  /// Recherche dans les permissions
  List<Permission> searchPermissions(String query) {
    if (query.isEmpty) return _permissions;
    final lowercaseQuery = query.toLowerCase();
    return _permissions.where((perm) =>
        perm.name.toLowerCase().contains(lowercaseQuery) ||
        perm.description.toLowerCase().contains(lowercaseQuery) ||
        perm.module.toLowerCase().contains(lowercaseQuery) ||
        perm.category.toLowerCase().contains(lowercaseQuery)
    ).toList();
  }

  /// Méthodes utilitaires pour la gestion d'état
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _permissions.clear();
    _roles.clear();
    _userRoles.clear();
    _permissionsByModule.clear();
    _userPermissions.clear();
    super.dispose();
  }
}
