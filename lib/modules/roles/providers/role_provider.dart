import 'package:flutter/foundation.dart';
import '../models/role.dart';
import '../models/user_role.dart';
import '../models/permission.dart';
import '../services/role_service.dart';

class RoleProvider with ChangeNotifier {
  final RoleService _roleService = RoleService();

  // ========== ÉTAT LOCAL ==========
  
  List<Role> _roles = [];
  List<Permission> _permissions = [];
  List<UserRole> _userRoles = [];
  UserRole? _currentUserRole;
  
  bool _isLoading = false;
  String? _error;
  
  // Filtres et recherche
  String _searchQuery = '';
  String? _selectedRoleFilter;
  String? _selectedModuleFilter;

  // ========== GETTERS ==========
  
  List<Role> get roles => _roles;
  List<Permission> get permissions => _permissions;
  List<UserRole> get userRoles => _userRoles;
  UserRole? get currentUserRole => _currentUserRole;
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  String get searchQuery => _searchQuery;
  String? get selectedRoleFilter => _selectedRoleFilter;
  String? get selectedModuleFilter => _selectedModuleFilter;

  // Getters calculés
  List<Role> get activeRoles => _roles.where((role) => role.isActive).toList();
  
  List<UserRole> get filteredUserRoles {
    var filtered = _userRoles.where((userRole) => userRole.isActive).toList();
    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((userRole) =>
          userRole.userEmail.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          userRole.userName.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    
    if (_selectedRoleFilter != null) {
      filtered = filtered.where((userRole) =>
          userRole.roleIds.contains(_selectedRoleFilter)).toList();
    }
    
    return filtered;
  }

  List<Permission> get filteredPermissions {
    var filtered = _permissions;
    
    if (_selectedModuleFilter != null) {
      filtered = filtered.where((permission) =>
          permission.module == _selectedModuleFilter).toList();
    }
    
    return filtered;
  }

  Map<String, List<Permission>> get permissionsByModule {
    final Map<String, List<Permission>> grouped = {};
    for (final permission in _permissions) {
      if (!grouped.containsKey(permission.module)) {
        grouped[permission.module] = [];
      }
      grouped[permission.module]!.add(permission);
    }
    return grouped;
  }

  List<String> get availableModules {
    return _permissions.map((p) => p.module).toSet().toList()..sort();
  }

  // ========== MÉTHODES PUBLIQUES ==========

  /// Initialiser le provider
  Future<void> initialize() async {
    await _setLoading(true);
    try {
      await _roleService.initializeDefaultRolesAndPermissions();
      await loadAllData();
      _clearError();
    } catch (e) {
      _setError('Erreur lors de l\'initialisation: $e');
    } finally {
      await _setLoading(false);
    }
  }

  /// Charger toutes les données
  Future<void> loadAllData() async {
    await Future.wait([
      loadRoles(),
      loadPermissions(),
      loadUserRoles(),
    ]);
  }

  /// Charger les rôles
  Future<void> loadRoles() async {
    try {
      _roleService.getAllRoles().listen((roles) {
        _roles = roles;
        notifyListeners();
      });
    } catch (e) {
      _setError('Erreur lors du chargement des rôles: $e');
    }
  }

  /// Charger les permissions
  Future<void> loadPermissions() async {
    try {
      _roleService.getAllPermissions().listen((permissions) {
        _permissions = permissions;
        notifyListeners();
      });
    } catch (e) {
      _setError('Erreur lors du chargement des permissions: $e');
    }
  }

  /// Charger les rôles d'utilisateurs
  Future<void> loadUserRoles() async {
    try {
      _roleService.getAllUserRoles().listen((userRoles) {
        _userRoles = userRoles;
        notifyListeners();
      });
    } catch (e) {
      _setError('Erreur lors du chargement des rôles utilisateur: $e');
    }
  }

  /// Charger les rôles de l'utilisateur actuel
  Future<void> loadCurrentUserRole(String userId) async {
    try {
      _roleService.getUserRolesStream(userId).listen((userRole) {
        _currentUserRole = userRole;
        notifyListeners();
      });
    } catch (e) {
      _setError('Erreur lors du chargement des rôles utilisateur: $e');
    }
  }

  // ========== GESTION DES RÔLES ==========

  /// Créer un nouveau rôle
  Future<bool> createRole(Role role) async {
    await _setLoading(true);
    try {
      await _roleService.createRole(role);
      _clearError();
      return true;
    } catch (e) {
      _setError('Erreur lors de la création du rôle: $e');
      return false;
    } finally {
      await _setLoading(false);
    }
  }

  /// Mettre à jour un rôle
  Future<bool> updateRole(String roleId, Role role) async {
    await _setLoading(true);
    try {
      await _roleService.updateRole(roleId, role);
      _clearError();
      return true;
    } catch (e) {
      _setError('Erreur lors de la mise à jour du rôle: $e');
      return false;
    } finally {
      await _setLoading(false);
    }
  }

  /// Supprimer un rôle
  Future<bool> deleteRole(String roleId) async {
    await _setLoading(true);
    try {
      await _roleService.deleteRole(roleId);
      _clearError();
      return true;
    } catch (e) {
      _setError('Erreur lors de la suppression du rôle: $e');
      return false;
    } finally {
      await _setLoading(false);
    }
  }

  // ========== GESTION DES ASSIGNATIONS ==========

  /// Assigner des rôles à un utilisateur
  Future<bool> assignRolesToUser({
    required String userId,
    required String userEmail,
    required String userName,
    required List<String> roleIds,
    String? assignedBy,
    DateTime? expiresAt,
  }) async {
    await _setLoading(true);
    try {
      // Désactiver les anciens rôles
      await _roleService.deactivateUserRoles(userId);
      
      // Assigner les nouveaux rôles
      await _roleService.assignRolesToUser(
        userId: userId,
        userEmail: userEmail,
        userName: userName,
        roleIds: roleIds,
        assignedBy: assignedBy,
        expiresAt: expiresAt,
      );
      
      _clearError();
      return true;
    } catch (e) {
      _setError('Erreur lors de l\'assignation: $e');
      return false;
    } finally {
      await _setLoading(false);
    }
  }

  /// Mettre à jour les rôles d'un utilisateur
  Future<bool> updateUserRoles(String userRoleId, UserRole userRole) async {
    await _setLoading(true);
    try {
      await _roleService.updateUserRoles(userRoleId, userRole);
      _clearError();
      return true;
    } catch (e) {
      _setError('Erreur lors de la mise à jour: $e');
      return false;
    } finally {
      await _setLoading(false);
    }
  }

  /// Désactiver les rôles d'un utilisateur
  Future<bool> deactivateUserRoles(String userId) async {
    await _setLoading(true);
    try {
      await _roleService.deactivateUserRoles(userId);
      _clearError();
      return true;
    } catch (e) {
      _setError('Erreur lors de la désactivation: $e');
      return false;
    } finally {
      await _setLoading(false);
    }
  }

  /// Supprimer les rôles d'un utilisateur
  Future<bool> removeUserRoles(String userId) async {
    await _setLoading(true);
    try {
      await _roleService.removeUserRoles(userId);
      _clearError();
      return true;
    } catch (e) {
      _setError('Erreur lors de la suppression: $e');
      return false;
    } finally {
      await _setLoading(false);
    }
  }

  // ========== VÉRIFICATIONS DE PERMISSIONS ==========

  /// Vérifier si l'utilisateur actuel a une permission
  bool hasPermission(String permissionId) {
    if (_currentUserRole == null || !_currentUserRole!.isActive || _currentUserRole!.isExpired) {
      return false;
    }

    return _currentUserRole!.roleIds.any((roleId) {
      final role = _roles.firstWhere(
        (r) => r.id == roleId,
        orElse: () => Role(
          id: '',
          name: '',
          description: '',
          permissions: [],
        ),
      );
      return role.isActive && role.hasPermission(permissionId);
    });
  }

  /// Obtenir toutes les permissions de l'utilisateur actuel
  List<String> getCurrentUserPermissions() {
    if (_currentUserRole == null || !_currentUserRole!.isActive || _currentUserRole!.isExpired) {
      return [];
    }

    final permissions = <String>{};
    for (final roleId in _currentUserRole!.roleIds) {
      final role = _roles.firstWhere(
        (r) => r.id == roleId,
        orElse: () => Role(
          id: '',
          name: '',
          description: '',
          permissions: [],
        ),
      );
      if (role.isActive) {
        permissions.addAll(role.permissions);
      }
    }
    return permissions.toList();
  }

  /// Vérifier si un utilisateur a une permission spécifique
  Future<bool> userHasPermission(String userId, String permissionId) async {
    return await _roleService.userHasPermission(userId, permissionId);
  }

  // ========== RECHERCHE ET FILTRES ==========

  /// Mettre à jour la requête de recherche
  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Mettre à jour le filtre de rôle
  void updateRoleFilter(String? roleId) {
    _selectedRoleFilter = roleId;
    notifyListeners();
  }

  /// Mettre à jour le filtre de module
  void updateModuleFilter(String? module) {
    _selectedModuleFilter = module;
    notifyListeners();
  }

  /// Effacer tous les filtres
  void clearFilters() {
    _searchQuery = '';
    _selectedRoleFilter = null;
    _selectedModuleFilter = null;
    notifyListeners();
  }

  // ========== STATISTIQUES ==========

  /// Obtenir les statistiques des rôles
  Future<Map<String, int>> getRoleStatistics() async {
    try {
      return await _roleService.getRoleStatistics();
    } catch (e) {
      _setError('Erreur lors du calcul des statistiques: $e');
      return {};
    }
  }

  /// Obtenir le nombre d'utilisateurs par rôle
  Map<String, int> getUserCountByRole() {
    final counts = <String, int>{};
    
    for (final role in _roles) {
      final count = _userRoles
          .where((userRole) => 
              userRole.isActive && 
              userRole.roleIds.contains(role.id))
          .length;
      counts[role.name] = count;
    }
    
    return counts;
  }

  // ========== UTILITAIRES ==========

  /// Obtenir un rôle par ID
  Role? getRoleById(String roleId) {
    try {
      return _roles.firstWhere((role) => role.id == roleId);
    } catch (e) {
      return null;
    }
  }

  /// Obtenir une permission par ID
  Permission? getPermissionById(String permissionId) {
    try {
      return _permissions.firstWhere((permission) => permission.id == permissionId);
    } catch (e) {
      return null;
    }
  }

  /// Obtenir les rôles d'un utilisateur par ID
  UserRole? getUserRoleById(String userId) {
    try {
      return _userRoles.firstWhere(
        (userRole) => userRole.userId == userId && userRole.isActive,
      );
    } catch (e) {
      return null;
    }
  }

  /// Obtenir les noms des rôles d'un utilisateur
  List<String> getUserRoleNames(String userId) {
    final userRole = getUserRoleById(userId);
    if (userRole == null) return [];

    return userRole.roleIds
        .map((roleId) => getRoleById(roleId)?.name)
        .where((name) => name != null)
        .cast<String>()
        .toList();
  }

  // ========== MIGRATION ==========

  /// Migrer les rôles depuis persons vers user_roles
  Future<Map<String, dynamic>> migratePersonsRolesToUserRoles() async {
    await _setLoading(true);
    try {
      final result = await _roleService.migratePersonsRolesToUserRoles();
      
      // Recharger les données après migration
      await loadUserRoles();
      
      _clearError();
      return result;
    } catch (e) {
      _setError('Erreur lors de la migration: $e');
      throw e;
    } finally {
      await _setLoading(false);
    }
  }

  // ========== MÉTHODES PRIVÉES ==========

  Future<void> _setLoading(bool loading) async {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
