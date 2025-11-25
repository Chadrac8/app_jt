import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/search_result.dart';
import '../models/search_filter.dart';
import '../services/wb_sermon_search_service.dart';

/// Provider pour la recherche avancée dans les sermons
class SearchProvider extends ChangeNotifier {
  List<SearchResult> _results = [];
  SearchFilter _filter = const SearchFilter();
  
  bool _isSearching = false;
  String? _error;
  
  // Historique des recherches
  List<String> _searchHistory = [];
  static const int _maxHistorySize = 20;

  SearchProvider() {
    _loadHistory();
  }

  // Getters
  List<SearchResult> get results => _results;
  SearchFilter get filter => _filter;
  bool get isSearching => _isSearching;
  String? get error => _error;
  List<String> get searchHistory => _searchHistory;
  bool get hasResults => _results.isNotEmpty;

  /// Effectue une recherche
  Future<void> search({required SearchFilter filter}) async {
    if (filter.query == null || filter.query!.trim().isEmpty) {
      _results = [];
      _error = null;
      notifyListeners();
      return;
    }

    _isSearching = true;
    _error = null;
    _filter = filter;
    notifyListeners();

    try {
      _results = await WBSermonSearchService.searchSermons(filter: filter);
      
      // Ajouter à l'historique
      _addToHistory(filter.query!);
      
      _isSearching = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors de la recherche: $e';
      _results = [];
      _isSearching = false;
      notifyListeners();
    }
  }

  /// Recherche rapide (juste une query, sans filtres)
  Future<void> quickSearch(String query) async {
    await search(filter: SearchFilter(query: query));
  }

  /// Met à jour le filtre et relance la recherche
  Future<void> updateFilter(SearchFilter filter) async {
    await search(filter: filter);
  }

  /// Ajoute une query à l'historique
  void _addToHistory(String query) {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return;

    // Supprimer les doublons
    _searchHistory.remove(trimmedQuery);
    
    // Ajouter en tête
    _searchHistory.insert(0, trimmedQuery);
    
    // Limiter la taille
    if (_searchHistory.length > _maxHistorySize) {
      _searchHistory = _searchHistory.take(_maxHistorySize).toList();
    }
    
    // Sauvegarder en local storage
    _saveHistory();
  }

  /// Supprime une entrée de l'historique
  void removeFromHistory(String query) {
    _searchHistory.remove(query);
    notifyListeners();
    _saveHistory();
  }

  /// Vide l'historique
  void clearHistory() {
    _searchHistory.clear();
    notifyListeners();
    _saveHistory();
  }

  /// Réinitialise la recherche
  void reset() {
    _results = [];
    _filter = const SearchFilter();
    _error = null;
    notifyListeners();
  }

  /// Charge un résultat de recherche par son index
  SearchResult? getResultAt(int index) {
    if (index >= 0 && index < _results.length) {
      return _results[index];
    }
    return null;
  }

  /// Filtre les résultats par score de pertinence minimum
  List<SearchResult> getResultsByMinRelevance(double minScore) {
    return _results.where((r) => r.relevanceScore >= minScore).toList();
  }

  /// Groupe les résultats par sermon
  Map<String, List<SearchResult>> getResultsGroupedBySermon() {
    final grouped = <String, List<SearchResult>>{};
    
    for (final result in _results) {
      if (!grouped.containsKey(result.sermonId)) {
        grouped[result.sermonId] = [];
      }
      grouped[result.sermonId]!.add(result);
    }
    
    return grouped;
  }

  /// Compte le nombre de résultats par sermon
  Map<String, int> getResultCountBySermon() {
    final counts = <String, int>{};
    
    for (final result in _results) {
      counts[result.sermonId] = (counts[result.sermonId] ?? 0) + 1;
    }
    
    return counts;
  }

  /// Charge l'historique depuis SharedPreferences
  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _searchHistory = prefs.getStringList('wb_search_history') ?? [];
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur chargement historique: $e');
    }
  }

  /// Sauvegarde l'historique dans SharedPreferences
  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('wb_search_history', _searchHistory);
    } catch (e) {
      debugPrint('Erreur sauvegarde historique: $e');
    }
  }
}
