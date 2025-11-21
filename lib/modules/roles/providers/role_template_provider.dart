import 'package:flutter/material.dart';
import '../models/role_template_model.dart';
import '../services/role_template_service.dart';

/// Provider pour la gestion de l'état des templates de rôles
class RoleTemplateProvider extends ChangeNotifier {
  // État des templates
  List<RoleTemplate> _templates = [];
  Map<String, List<RoleTemplate>> _templatesByCategory = {};
  Map<String, dynamic> _usageStats = {};
  
  // États de chargement
  bool _isLoading = false;
  bool _isInitialized = false;
  
  // Filtres et recherche
  String _searchQuery = '';
  String _selectedCategory = '';
  bool _showInactive = false;
  
  // Cache
  DateTime? _lastRefresh;
  static const Duration _cacheValidityDuration = Duration(minutes: 5);

  // Getters
  List<RoleTemplate> get templates => _getFilteredTemplates();
  List<RoleTemplate> get allTemplates => _templates;
  Map<String, List<RoleTemplate>> get templatesByCategory => _templatesByCategory;
  Map<String, dynamic> get usageStats => _usageStats;
  
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get needsRefresh => _lastRefresh == null || 
      DateTime.now().difference(_lastRefresh!) > _cacheValidityDuration;
  
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  bool get showInactive => _showInactive;
  
  /// Templates par catégorie avec compteurs
  Map<String, int> get categoryStats {
    final stats = <String, int>{};
    for (final template in _templates) {
      if (template.isActive || _showInactive) {
        stats[template.category] = (stats[template.category] ?? 0) + 1;
      }
    }
    return stats;
  }
  
  /// Templates système
  List<RoleTemplate> get systemTemplates => _templates
      .where((template) => template.isSystemTemplate)
      .toList();
  
  /// Templates personnalisés
  List<RoleTemplate> get customTemplates => _templates
      .where((template) => !template.isSystemTemplate)
      .toList();
  
  /// Templates actifs
  List<RoleTemplate> get activeTemplates => _templates
      .where((template) => template.isActive)
      .toList();

  /// Initialiser le provider
  Future<void> initialize() async {
    if (_isInitialized && !needsRefresh) return;
    
    _setLoading(true);
    
    try {
      // Essayer d'initialiser les templates système Firebase
      try {
        await RoleTemplateService.initializeSystemTemplates();
      } catch (e) {
        print('Firebase non disponible, mode local activé: $e');
      }
      
      // Charger les données
      await Future.wait([
        _loadTemplates(),
        _loadUsageStats(),
      ]);
      
      _isInitialized = true;
      _lastRefresh = DateTime.now();
      
    } catch (e) {
      print('Erreur lors de l\'initialisation du RoleTemplateProvider: $e');
      
      // Fallback ultime: charger uniquement les templates système
      _templates = List.from(RoleTemplate.systemTemplates);
      _groupTemplatesByCategory();
      _usageStats = {};
      _isInitialized = true;
      _lastRefresh = DateTime.now();
      
    } finally {
      _setLoading(false);
    }
  }

  /// Actualiser les données
  Future<void> refresh() async {
    _setLoading(true);
    
    try {
      await Future.wait([
        _loadTemplates(),
        _loadUsageStats(),
      ]);
      
      _lastRefresh = DateTime.now();
      
    } catch (e) {
      print('Erreur lors de l\'actualisation: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Charger les templates
  Future<void> _loadTemplates() async {
    try {
      // Essayer de charger depuis Firebase
      _templates = await RoleTemplateService.getAllTemplates(
        includeInactive: _showInactive,
      );
      
      // Si Firebase ne retourne rien, utiliser les templates système en fallback
      if (_templates.isEmpty) {
        print('Firebase non disponible, utilisation des templates système locaux');
        _templates = List.from(RoleTemplate.systemTemplates);
      }
      
      _groupTemplatesByCategory();
      
    } catch (e) {
      print('Erreur lors du chargement des templates: $e');
      print('Utilisation des templates système locaux en fallback');
      
      // Fallback: utiliser directement les templates système
      _templates = List.from(RoleTemplate.systemTemplates);
      _groupTemplatesByCategory();
    }
  }

  /// Charger les statistiques d'utilisation
  Future<void> _loadUsageStats() async {
    try {
      _usageStats = await RoleTemplateService.getTemplateUsageStats();
    } catch (e) {
      print('Erreur lors du chargement des statistiques: $e');
      
      // Fallback: statistiques simulées
      _usageStats = _generateFallbackStats();
    }
  }
  
  /// Générer des statistiques fallback pour le mode test
  Map<String, dynamic> _generateFallbackStats() {
    final stats = <String, dynamic>{
      'totalTemplates': _templates.length,
      'systemTemplates': _templates.where((t) => t.isSystemTemplate).length,
      'customTemplates': _templates.where((t) => !t.isSystemTemplate).length,
      'activeTemplates': _templates.where((t) => t.isActive).length,
      'templateUsage': <String, int>{},
      'categoryDistribution': <String, int>{},
    };
    
    // Statistiques simulées d'utilisation
    for (final template in _templates) {
      stats['templateUsage'][template.id] = 
          template.isSystemTemplate ? (5 + template.id.hashCode % 20) : 1;
      stats['categoryDistribution'][template.category] = 
          (stats['categoryDistribution'][template.category] ?? 0) + 1;
    }
    
    return stats;
  }

  /// Grouper les templates par catégorie
  void _groupTemplatesByCategory() {
    _templatesByCategory.clear();
    
    for (final template in _templates) {
      if (!_templatesByCategory.containsKey(template.category)) {
        _templatesByCategory[template.category] = [];
      }
      _templatesByCategory[template.category]!.add(template);
    }
    
    // Trier chaque catégorie
    for (final category in _templatesByCategory.keys) {
      _templatesByCategory[category]!.sort((a, b) => a.name.compareTo(b.name));
    }
  }

  /// Obtenir les templates filtrés
  List<RoleTemplate> _getFilteredTemplates() {
    var filtered = List<RoleTemplate>.from(_templates);
    
    // Filtre par catégorie
    if (_selectedCategory.isNotEmpty) {
      filtered = filtered
          .where((template) => template.category == _selectedCategory)
          .toList();
    }
    
    // Filtre par recherche
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((template) {
        return template.name.toLowerCase().contains(query) ||
               template.description.toLowerCase().contains(query) ||
               template.permissionIds.any((perm) => 
                   perm.toLowerCase().contains(query));
      }).toList();
    }
    
    // Filtre par statut actif
    if (!_showInactive) {
      filtered = filtered.where((template) => template.isActive).toList();
    }
    
    return filtered;
  }

  /// Définir l'état de chargement
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// Mettre à jour la requête de recherche
  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }

  /// Mettre à jour la catégorie sélectionnée
  void setSelectedCategory(String category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      notifyListeners();
    }
  }

  /// Basculer l'affichage des templates inactifs
  void toggleShowInactive() {
    _showInactive = !_showInactive;
    _loadTemplates().then((_) => notifyListeners());
  }

  /// Réinitialiser les filtres
  void resetFilters() {
    bool hasChanges = false;
    
    if (_searchQuery.isNotEmpty) {
      _searchQuery = '';
      hasChanges = true;
    }
    
    if (_selectedCategory.isNotEmpty) {
      _selectedCategory = '';
      hasChanges = true;
    }
    
    if (_showInactive) {
      _showInactive = false;
      hasChanges = true;
    }
    
    if (hasChanges) {
      _loadTemplates().then((_) => notifyListeners());
    }
  }

  /// Obtenir un template par ID
  RoleTemplate? getTemplate(String templateId) {
    try {
      return _templates.firstWhere((template) => template.id == templateId);
    } catch (e) {
      return null;
    }
  }

  /// Obtenir les templates par catégorie
  List<RoleTemplate> getTemplatesByCategory(String category) {
    return _templatesByCategory[category] ?? [];
  }

  /// Créer un nouveau template
  Future<String> createTemplate(RoleTemplate template) async {
    _setLoading(true);
    
    try {
      final templateId = await RoleTemplateService.createTemplate(template);
      
      // Recharger les données
      await _loadTemplates();
      await _loadUsageStats();
      
      return templateId;
      
    } catch (e) {
      print('Erreur lors de la création du template: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Mettre à jour un template
  Future<void> updateTemplate(RoleTemplate template) async {
    _setLoading(true);
    
    try {
      await RoleTemplateService.updateTemplate(template);
      
      // Mettre à jour localement
      final index = _templates.indexWhere((t) => t.id == template.id);
      if (index != -1) {
        _templates[index] = template;
        _groupTemplatesByCategory();
        notifyListeners();
      }
      
      await _loadUsageStats();
      
    } catch (e) {
      print('Erreur lors de la mise à jour du template: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Supprimer un template
  Future<void> deleteTemplate(String templateId, String deletedBy) async {
    _setLoading(true);
    
    try {
      await RoleTemplateService.deleteTemplate(templateId, deletedBy);
      
      // Supprimer localement
      _templates.removeWhere((template) => template.id == templateId);
      _groupTemplatesByCategory();
      
      await _loadUsageStats();
      
    } catch (e) {
      print('Erreur lors de la suppression du template: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Dupliquer un template
  Future<String> duplicateTemplate(
    String templateId,
    String newName,
    String createdBy,
  ) async {
    _setLoading(true);
    
    try {
      final newTemplateId = await RoleTemplateService.duplicateTemplate(
        templateId,
        newName,
        createdBy,
      );
      
      // Recharger les données
      await _loadTemplates();
      await _loadUsageStats();
      
      return newTemplateId;
      
    } catch (e) {
      print('Erreur lors de la duplication du template: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Rechercher des templates
  Future<List<RoleTemplate>> searchTemplates(
    String query, {
    String? category,
  }) async {
    try {
      return await RoleTemplateService.searchTemplates(
        query,
        category: category,
        includeInactive: _showInactive,
      );
    } catch (e) {
      print('Erreur lors de la recherche de templates: $e');
      return [];
    }
  }

  /// Valider un template
  Future<Map<String, dynamic>> validateTemplate(String templateId) async {
    try {
      return await RoleTemplateService.validateTemplateForRole(templateId);
    } catch (e) {
      print('Erreur lors de la validation du template: $e');
      return {
        'isValid': false,
        'errors': ['Erreur lors de la validation: $e'],
      };
    }
  }

  /// Créer un rôle à partir d'un template
  Future<String> createRoleFromTemplate(
    String templateId, {
    String? customName,
    String? customDescription,
    Map<String, dynamic>? additionalConfig,
    required String createdBy,
  }) async {
    try {
      final roleId = await RoleTemplateService.createRoleFromTemplate(
        templateId,
        customName: customName,
        customDescription: customDescription,
        additionalConfig: additionalConfig,
        createdBy: createdBy,
      );
      
      // Recharger les statistiques
      await _loadUsageStats();
      
      return roleId;
      
    } catch (e) {
      print('Erreur lors de la création du rôle: $e');
      rethrow;
    }
  }

  /// Synchroniser un rôle avec son template
  Future<void> syncRoleWithTemplate(String roleId) async {
    try {
      await RoleTemplateService.syncRoleWithTemplate(roleId);
      
      // Recharger les statistiques
      await _loadUsageStats();
      
    } catch (e) {
      print('Erreur lors de la synchronisation: $e');
      rethrow;
    }
  }

  /// Exporter des templates
  Future<Map<String, dynamic>> exportTemplates({
    List<String>? templateIds,
    String? category,
  }) async {
    try {
      return await RoleTemplateService.exportTemplates(
        templateIds: templateIds,
        category: category,
      );
    } catch (e) {
      print('Erreur lors de l\'export: $e');
      rethrow;
    }
  }

  /// Importer des templates
  Future<List<String>> importTemplates(
    Map<String, dynamic> importData,
    String importedBy,
  ) async {
    _setLoading(true);
    
    try {
      final importedIds = await RoleTemplateService.importTemplates(
        importData,
        importedBy,
      );
      
      // Recharger les données
      await _loadTemplates();
      await _loadUsageStats();
      
      return importedIds;
      
    } catch (e) {
      print('Erreur lors de l\'import: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Nettoyer les templates obsolètes
  Future<int> cleanupObsoleteTemplates() async {
    try {
      final cleanedCount = await RoleTemplateService.cleanupObsoleteTemplates();
      
      if (cleanedCount > 0) {
        // Recharger les données
        await _loadTemplates();
        await _loadUsageStats();
      }
      
      return cleanedCount;
      
    } catch (e) {
      print('Erreur lors du nettoyage: $e');
      return 0;
    }
  }

  /// Obtenir les templates les plus utilisés
  List<MapEntry<String, int>> get mostUsedTemplates {
    final usage = _usageStats['templatesUsage'] as Map<String, dynamic>? ?? {};
    
    final entries = <MapEntry<String, int>>[];
    
    for (final entry in usage.entries) {
      if (entry.value is int) {
        entries.add(MapEntry(entry.key, entry.value as int));
      }
    }
    
    entries.sort((a, b) => b.value.compareTo(a.value));
    
    return entries.take(5).toList();
  }

  /// Obtenir les templates inutilisés
  List<RoleTemplate> get unusedTemplates {
    final unusedIds = _usageStats['unusedTemplates'] as List<dynamic>? ?? [];
    
    return _templates
        .where((template) => unusedIds.contains(template.id))
        .toList();
  }

  /// Obtenir les recommandations d'optimisation
  List<Map<String, dynamic>> get optimizationRecommendations {
    final recommendations = <Map<String, dynamic>>[];
    
    // Templates inutilisés
    if (unusedTemplates.isNotEmpty) {
      recommendations.add({
        'type': 'unused_templates',
        'title': 'Templates inutilisés',
        'description': '${unusedTemplates.length} template(s) ne sont utilisés par aucun rôle',
        'severity': 'info',
        'action': 'Considérez supprimer ou archiver ces templates',
        'count': unusedTemplates.length,
      });
    }
    
    // Templates avec trop de permissions
    final complexTemplates = _templates.where((t) => t.permissionIds.length > 20).toList();
    if (complexTemplates.isNotEmpty) {
      recommendations.add({
        'type': 'complex_templates',
        'title': 'Templates complexes',
        'description': '${complexTemplates.length} template(s) ont plus de 20 permissions',
        'severity': 'warning',
        'action': 'Considérez diviser ces templates en plusieurs rôles plus spécifiques',
        'count': complexTemplates.length,
      });
    }
    
    // Templates système modifiés
    final modifiedSystemTemplates = systemTemplates
        .where((t) => t.updatedAt != null)
        .toList();
    if (modifiedSystemTemplates.isNotEmpty) {
      recommendations.add({
        'type': 'modified_system_templates',
        'title': 'Templates système modifiés',
        'description': '${modifiedSystemTemplates.length} template(s) système ont été modifiés',
        'severity': 'error',
        'action': 'Les templates système ne devraient pas être modifiés',
        'count': modifiedSystemTemplates.length,
      });
    }
    
    return recommendations;
  }

  /// Stream pour écouter les changements en temps réel
  Stream<List<RoleTemplate>> getTemplatesStream({String? category}) {
    return RoleTemplateService.getTemplatesStream(
      category: category,
      includeInactive: _showInactive,
    );
  }

  /// Invalider le cache
  void invalidateCache() {
    _lastRefresh = null;
  }

  @override
  void dispose() {
    super.dispose();
  }
}