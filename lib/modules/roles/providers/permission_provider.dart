import 'package:flutter/foundation.dart';
import '../models/permission_model.dart';
import '../services/roles_permissions_service.dart';

/// Provider pour la gestion d'état des rôles et permissions avec fonctionnalités avancées
class PermissionProvider with ChangeNotifier {
  // ========== ÉTAT LOCAL ==========
  
  List<Permission> _permissions = [];
  List<Role> _roles = [];
  Map<String, List<Permission>> _permissionsByModule = {};
  Map<String, List<String>> _userPermissions = {};
  Map<String, bool> _permissionCache = {};
  
  bool _isLoading = false;
  String? _error;
  String? _currentUserId;
  DateTime? _lastCacheUpdate;

  // Durée de validité du cache (5 minutes)
  static const Duration _cacheValidityDuration = Duration(minutes: 5);

  // ========== GETTERS ==========
  
  List<Permission> get permissions => List.unmodifiable(_permissions);
  List<Role> get roles => List.unmodifiable(_roles);
  Map<String, List<Permission>> get permissionsByModule => Map.unmodifiable(_permissionsByModule);
  Map<String, List<String>> get userPermissions => Map.unmodifiable(_userPermissions);
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentUserId => _currentUserId;
  bool get isInitialized => _currentUserId != null;

  // ========== INITIALISATION ==========

  /// Initialise le provider avec l'ID de l'utilisateur courant
  Future<void> initialize(String userId) async {
    if (_currentUserId == userId && _isCacheValid()) {
      // Déjà initialisé avec le même utilisateur et cache valide
      return;
    }

    _currentUserId = userId;
    await loadUserData();
  }

  /// Charge toutes les données nécessaires pour l'utilisateur
  Future<void> loadUserData() async {
    if (_currentUserId == null) return;
    
    setLoading(true);
    try {
      await Future.wait([
        loadPermissions(),
        loadRoles(),
        loadUserPermissions(_currentUserId!),
      ]);
      
      _lastCacheUpdate = DateTime.now();
      clearError();
    } catch (e) {
      setError('Erreur lors du chargement des données: $e');
      debugPrint('❌ Erreur PermissionProvider.loadUserData: $e');
    } finally {
      setLoading(false);
    }
  }

  /// Charge toutes les permissions système
  Future<void> loadPermissions() async {
    try {
      final permissionsStream = RolesPermissionsService.getPermissions();
      await for (final permissions in permissionsStream.take(1)) {
        _permissions = permissions;
        _organizePermissionsByModule();
        notifyListeners();
        break;
      }
    } catch (e) {
      setError('Erreur lors du chargement des permissions: $e');
      debugPrint('❌ Erreur PermissionProvider.loadPermissions: $e');
    }
  }

  /// Charge tous les rôles actifs
  Future<void> loadRoles() async {
    try {
      final rolesStream = RolesPermissionsService.getRoles(activeOnly: true);
      await for (final roles in rolesStream.take(1)) {
        _roles = roles;
        notifyListeners();
        break;
      }
    } catch (e) {
      setError('Erreur lors du chargement des rôles: $e');
      debugPrint('❌ Erreur PermissionProvider.loadRoles: $e');
    }
  }

  /// Charge les permissions d'un utilisateur spécifique
  Future<void> loadUserPermissions(String userId) async {
    try {
      // Ici nous devrions implémenter la logique pour récupérer les permissions utilisateur
      // via le service. Pour l'instant, on utilise une approche simplifiée.
      _userPermissions[userId] = [];
      notifyListeners();
    } catch (e) {
      setError('Erreur lors du chargement des permissions utilisateur: $e');
      debugPrint('❌ Erreur PermissionProvider.loadUserPermissions: $e');
    }
  }

  // ========== VÉRIFICATIONS DE PERMISSIONS ==========

  /// Vérifie si l'utilisateur courant a une permission spécifique (avec cache)
  Future<bool> hasPermission(String permissionId) async {
    if (_currentUserId == null) return false;

    // Vérifier le cache d'abord
    final cacheKey = '${_currentUserId}_$permissionId';
    if (_permissionCache.containsKey(cacheKey) && _isCacheValid()) {
      return _permissionCache[cacheKey]!;
    }

    try {
      final hasPermission = await RolesPermissionsService.userHasPermission(
        _currentUserId!, 
        permissionId
      );
      
      // Mettre en cache le résultat
      _permissionCache[cacheKey] = hasPermission;
      
      return hasPermission;
    } catch (e) {
      debugPrint('❌ Erreur lors de la vérification de permission: $e');
      return false;
    }
  }

  /// Vérifie si l'utilisateur courant a accès à un module
  Future<bool> hasModuleAccess(String moduleId, {PermissionLevel? minimumLevel}) async {
    if (_currentUserId == null) return false;

    final cacheKey = '${_currentUserId}_module_${moduleId}_${minimumLevel?.name ?? 'any'}';
    if (_permissionCache.containsKey(cacheKey) && _isCacheValid()) {
      return _permissionCache[cacheKey]!;
    }

    try {
      final hasAccess = await RolesPermissionsService.userHasModuleAccess(
        _currentUserId!, 
        moduleId, 
        minimumLevel: minimumLevel
      );
      
      _permissionCache[cacheKey] = hasAccess;
      return hasAccess;
    } catch (e) {
      debugPrint('❌ Erreur lors de la vérification d\'accès au module: $e');
      return false;
    }
  }

  /// Vérifie plusieurs permissions en parallèle
  Future<Map<String, bool>> hasPermissions(List<String> permissionIds) async {
    if (_currentUserId == null) {
      return {for (String id in permissionIds) id: false};
    }

    try {
      final results = <String, bool>{};
      
      // Vérifier les permissions en parallèle
      await Future.wait(permissionIds.map((permissionId) async {
        results[permissionId] = await hasPermission(permissionId);
      }));
      
      return results;
    } catch (e) {
      debugPrint('❌ Erreur lors de la vérification de permissions multiples: $e');
      return {for (String id in permissionIds) id: false};
    }
  }

  // ========== GESTION DES RÔLES ==========

  /// Récupère les rôles système prédéfinis
  List<Role> get systemRoles => _roles.where((role) => role.isSystemRole).toList();

  /// Récupère les rôles personnalisés
  List<Role> get customRoles => _roles.where((role) => !role.isSystemRole).toList();

  /// Trouve un rôle par son ID
  Role? findRoleById(String roleId) {
    try {
      return _roles.firstWhere((role) => role.id == roleId);
    } catch (e) {
      return null;
    }
  }

  /// Récupère les rôles d'un utilisateur
  List<Role> getUserRoles(String userId) {
    // Cette méthode devrait être implementée pour récupérer les rôles réels de l'utilisateur
    // Pour l'instant, on retourne une liste vide
    return [];
  }

  // ========== GESTION DES PERMISSIONS PAR MODULE ==========

  /// Récupère les permissions d'un module spécifique
  List<Permission> getModulePermissions(String moduleId) {
    return _permissionsByModule[moduleId] ?? [];
  }

  /// Récupère les modules disponibles avec leurs permissions
  Map<AppModule, List<Permission>> getModulesWithPermissions() {
    final result = <AppModule, List<Permission>>{};
    
    for (final module in AppModule.allModules) {
      final modulePermissions = getModulePermissions(module.id);
      if (modulePermissions.isNotEmpty) {
        result[module] = modulePermissions;
      }
    }
    
    return result;
  }

  /// Récupère les permissions par niveau
  List<Permission> getPermissionsByLevel(PermissionLevel level) {
    return _permissions.where((permission) => permission.level == level).toList();
  }

  // ========== STATISTIQUES ET ANALYSES ==========

  /// Récupère des statistiques sur les permissions
  Map<String, dynamic> getPermissionsStats() {
    final statsByModule = <String, int>{};
    final statsByLevel = <String, int>{};
    
    for (final permission in _permissions) {
      statsByModule[permission.module] = (statsByModule[permission.module] ?? 0) + 1;
      statsByLevel[permission.level.name] = (statsByLevel[permission.level.name] ?? 0) + 1;
    }
    
    return {
      'total_permissions': _permissions.length,
      'total_roles': _roles.length,
      'system_roles': systemRoles.length,
      'custom_roles': customRoles.length,
      'permissions_by_module': statsByModule,
      'permissions_by_level': statsByLevel,
      'active_modules': _permissionsByModule.length,
    };
  }

  /// Récupère des statistiques sur les rôles
  Map<String, dynamic> getRolesStats() {
    final activeRoles = _roles.where((role) => role.isActive).length;
    final inactiveRoles = _roles.length - activeRoles;
    
    return {
      'total_roles': _roles.length,
      'active_roles': activeRoles,
      'inactive_roles': inactiveRoles,
      'system_roles': systemRoles.length,
      'custom_roles': customRoles.length,
    };
  }

  // ========== MÉTHODES DE RECHERCHE ==========

  /// Recherche des permissions par terme
  List<Permission> searchPermissions(String searchTerm) {
    if (searchTerm.isEmpty) return _permissions;
    
    final term = searchTerm.toLowerCase();
    return _permissions.where((permission) =>
      permission.name.toLowerCase().contains(term) ||
      permission.description.toLowerCase().contains(term) ||
      permission.module.toLowerCase().contains(term) ||
      permission.category.toLowerCase().contains(term)
    ).toList();
  }

  /// Recherche des rôles par terme
  List<Role> searchRoles(String searchTerm) {
    if (searchTerm.isEmpty) return _roles;
    
    final term = searchTerm.toLowerCase();
    return _roles.where((role) =>
      role.name.toLowerCase().contains(term) ||
      role.description.toLowerCase().contains(term)
    ).toList();
  }

  // ========== MÉTHODES D'ACTUALISATION ==========

  /// Force le rechargement des données
  Future<void> refresh() async {
    _permissionCache.clear();
    await loadUserData();
  }

  /// Actualise les permissions seulement
  Future<void> refreshPermissions() async {
    await loadPermissions();
  }

  /// Actualise les rôles seulement
  Future<void> refreshRoles() async {
    await loadRoles();
  }

  /// Invalide le cache des permissions
  void invalidateCache() {
    _permissionCache.clear();
    _lastCacheUpdate = null;
  }

  // ========== MÉTHODES PRIVÉES ==========

  /// Organise les permissions par module
  void _organizePermissionsByModule() {
    _permissionsByModule.clear();
    
    for (final permission in _permissions) {
      if (!_permissionsByModule.containsKey(permission.module)) {
        _permissionsByModule[permission.module] = [];
      }
      _permissionsByModule[permission.module]!.add(permission);
    }
    
    // Trier les permissions dans chaque module
    for (final modulePermissions in _permissionsByModule.values) {
      modulePermissions.sort((a, b) {
        // Trier par catégorie puis par niveau
        final categoryComparison = a.category.compareTo(b.category);
        if (categoryComparison != 0) return categoryComparison;
        return a.level.index.compareTo(b.level.index);
      });
    }
  }

  /// Vérifie si le cache est toujours valide
  bool _isCacheValid() {
    if (_lastCacheUpdate == null) return false;
    final now = DateTime.now();
    return now.difference(_lastCacheUpdate!).compareTo(_cacheValidityDuration) < 0;
  }

  // ========== GESTION D'ÉTAT ==========

  /// Met le provider en état de chargement
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// Définit une erreur
  void setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// Efface l'erreur courante
  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  // ========== NETTOYAGE ==========

  /// Nettoie les ressources du provider
  @override
  void dispose() {
    _permissions.clear();
    _roles.clear();
    _permissionsByModule.clear();
    _userPermissions.clear();
    _permissionCache.clear();
    super.dispose();
  }

  /// Réinitialise complètement le provider
  void reset() {
    _permissions.clear();
    _roles.clear();
    _permissionsByModule.clear();
    _userPermissions.clear();
    _permissionCache.clear();
    _currentUserId = null;
    _lastCacheUpdate = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}