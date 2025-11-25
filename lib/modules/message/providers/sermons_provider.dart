import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/wb_sermon.dart';
import '../models/search_filter.dart';
import '../services/wb_sermon_search_service.dart';

/// Provider pour la gestion des sermons
class SermonsProvider extends ChangeNotifier {
  List<WBSermon> _allSermons = [];
  List<WBSermon> _filteredSermons = [];
  SearchFilter _currentFilter = const SearchFilter();
  String _selectedLanguage = 'fr'; // Langue sélectionnée indépendamment des filtres
  
  bool _isLoading = false;
  String? _error;

  // Données pour les filtres
  Set<String> _availableLanguages = {};
  Set<int> _availableYears = {};
  Set<String> _availableSeries = {};

  // Getters
  List<WBSermon> get allSermons => _allSermons;
  List<WBSermon> get filteredSermons => _filteredSermons;
  SearchFilter get currentFilter => _currentFilter;
  String get selectedLanguage => _selectedLanguage;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Set<String> get availableLanguages => _availableLanguages;
  Set<int> get availableYears => _availableYears;
  Set<String> get availableSeries => _availableSeries;

  /// Charge tous les sermons
  Future<void> loadSermons({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _allSermons = await WBSermonSearchService.getAllSermons(
        forceRefresh: forceRefresh,
      );
      
      // Charger les favoris sauvegardés
      await _loadFavorites();
      
      _updateAvailableFilters();
      _applyCurrentFilter();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors du chargement des sermons: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Met à jour les options disponibles pour les filtres
  void _updateAvailableFilters() {
    _availableLanguages = _allSermons.map((s) => s.language).toSet();
    _availableYears = _allSermons.map((s) => s.year).toSet();
    
    _availableSeries.clear();
    for (final sermon in _allSermons) {
      _availableSeries.addAll(sermon.series);
    }
  }

  /// Applique un filtre
  void applyFilter(SearchFilter filter) {
    _currentFilter = filter;
    _applyCurrentFilter();
    notifyListeners();
  }

  /// Change la langue sélectionnée (indépendant des filtres)
  void setLanguage(String language) {
    _selectedLanguage = language;
    _applyCurrentFilter();
    notifyListeners();
  }

  /// Applique le filtre actuel à la liste
  void _applyCurrentFilter() {
    _filteredSermons = _allSermons.where((sermon) {
      // Filtre par langue sélectionnée (toujours actif)
      if (sermon.language != _selectedLanguage) {
        return false;
      }

      // Filtre par années
      if (_currentFilter.years.isNotEmpty && 
          !_currentFilter.years.contains(sermon.year)) {
        return false;
      }

      // Filtre par séries
      if (_currentFilter.series.isNotEmpty) {
        final hasMatchingSeries = sermon.series.any(
          (s) => _currentFilter.series.contains(s)
        );
        if (!hasMatchingSeries) return false;
      }

      // Filtre par ressources disponibles
      if (_currentFilter.hasAudio == true && sermon.audioUrl == null) {
        return false;
      }
      if (_currentFilter.hasVideo == true && sermon.videoUrl == null) {
        return false;
      }
      if (_currentFilter.hasPdf == true && sermon.pdfUrl == null) {
        return false;
      }
      if (_currentFilter.hasText == true && sermon.textContent == null) {
        return false;
      }

      // Filtre par favoris
      if (_currentFilter.isFavorite == true && !sermon.isFavorite) {
        return false;
      }

      // Filtre par query texte
      if (_currentFilter.query != null && _currentFilter.query!.isNotEmpty) {
        final query = _currentFilter.query!.toLowerCase();
        final matchesTitle = sermon.title.toLowerCase().contains(query);
        final matchesDesc = sermon.description?.toLowerCase().contains(query) ?? false;
        final matchesLocation = sermon.location.toLowerCase().contains(query);
        
        if (!matchesTitle && !matchesDesc && !matchesLocation) {
          return false;
        }
      }

      return true;
    }).toList();

    // Tri
    _sortSermons();
  }

  /// Trie les sermons selon le filtre actuel
  void _sortSermons() {
    switch (_currentFilter.sortBy) {
      case SortOption.date:
        _filteredSermons.sort((a, b) {
          final comparison = a.date.compareTo(b.date);
          return _currentFilter.sortAscending ? comparison : -comparison;
        });
        break;
      
      case SortOption.title:
        _filteredSermons.sort((a, b) {
          final comparison = a.title.compareTo(b.title);
          return _currentFilter.sortAscending ? comparison : -comparison;
        });
        break;
      
      case SortOption.duration:
        _filteredSermons.sort((a, b) {
          final durationA = a.durationMinutes ?? 0;
          final durationB = b.durationMinutes ?? 0;
          final comparison = durationA.compareTo(durationB);
          return _currentFilter.sortAscending ? comparison : -comparison;
        });
        break;
      
      case SortOption.relevance:
        // Pour la pertinence, on garde l'ordre par défaut
        break;
    }
  }

  /// Réinitialise les filtres (garde la langue)
  void resetFilter() {
    _currentFilter = const SearchFilter();
    _applyCurrentFilter();
    notifyListeners();
  }

  /// Toggle favori pour un sermon
  Future<void> toggleFavorite(String sermonId) async {
    final index = _allSermons.indexWhere((s) => s.id == sermonId);
    if (index >= 0) {
      _allSermons[index] = _allSermons[index].copyWith(
        isFavorite: !_allSermons[index].isFavorite,
      );
      _applyCurrentFilter();
      notifyListeners();
      
      // Sauvegarder en local storage
      await _saveFavorites();
    }
  }

  /// Charge les favoris depuis SharedPreferences
  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoriteIds = prefs.getStringList('wb_search_favorites') ?? [];
      
      // Marquer les sermons favoris
      for (int i = 0; i < _allSermons.length; i++) {
        if (favoriteIds.contains(_allSermons[i].id)) {
          _allSermons[i] = _allSermons[i].copyWith(isFavorite: true);
        }
      }
    } catch (e) {
      debugPrint('Erreur chargement favoris: $e');
    }
  }

  /// Sauvegarde les favoris dans SharedPreferences
  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoriteIds = _allSermons
          .where((s) => s.isFavorite)
          .map((s) => s.id)
          .toList();
      
      await prefs.setStringList('wb_search_favorites', favoriteIds);
    } catch (e) {
      debugPrint('Erreur sauvegarde favoris: $e');
    }
  }

  /// Vide le cache
  Future<void> clearCache() async {
    await WBSermonSearchService.clearCache();
    _allSermons = [];
    _filteredSermons = [];
    _availableLanguages = {};
    _availableYears = {};
    _availableSeries = {};
    notifyListeners();
  }
}
