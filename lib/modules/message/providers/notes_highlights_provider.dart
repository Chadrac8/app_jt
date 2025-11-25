import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/sermon_note.dart';
import '../models/sermon_highlight.dart';
import '../services/notes_highlights_service.dart';
import '../services/notes_highlights_cloud_service.dart';

/// Provider pour gérer les notes et surlignements
class NotesHighlightsProvider extends ChangeNotifier {
  List<SermonNote> _notes = [];
  List<SermonHighlight> _highlights = [];
  
  bool _isLoading = false;
  String? _error;
  
  // Filtres
  String _searchQuery = '';
  List<String> _selectedTags = [];
  
  // Synchronisation cloud
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  String? _syncError;
  bool _autoSyncEnabled = true;
  
  NotesHighlightsProvider() {
    _initCloudSync();
  }

  // Getters
  List<SermonNote> get notes => _getFilteredNotes();
  List<SermonHighlight> get highlights => _getFilteredHighlights();
  List<SermonNote> get allNotes => _notes;
  List<SermonHighlight> get allHighlights => _highlights;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  List<String> get selectedTags => _selectedTags;
  
  // Getters synchronisation
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get syncError => _syncError;
  bool get autoSyncEnabled => _autoSyncEnabled;
  bool get isCloudAvailable => NotesHighlightsCloudService.isAuthenticated;

  /// Charge toutes les notes et surlignements
  Future<void> loadAll({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _notes = await NotesHighlightsService.getAllNotes(
        forceRefresh: forceRefresh,
      );
      _highlights = await NotesHighlightsService.getAllHighlights(
        forceRefresh: forceRefresh,
      );
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors du chargement: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charge les notes et surlignements pour un sermon
  Future<void> loadForSermon(String sermonId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _notes = await NotesHighlightsService.getNotesForSermon(sermonId);
      _highlights = await NotesHighlightsService.getHighlightsForSermon(sermonId);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors du chargement: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Ajoute ou met à jour une note
  Future<void> saveNote(SermonNote note) async {
    try {
      // Sauvegarder localement
      await NotesHighlightsService.saveNote(note);
      
      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index >= 0) {
        _notes[index] = note;
      } else {
        _notes.insert(0, note);
      }
      
      notifyListeners();
      
      // Synchroniser avec le cloud si activé
      if (_autoSyncEnabled && NotesHighlightsCloudService.isAuthenticated) {
        await NotesHighlightsCloudService.uploadNote(note);
      }
    } catch (e) {
      _error = 'Erreur lors de la sauvegarde: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Supprime une note
  Future<void> deleteNote(String noteId) async {
    try {
      // Supprimer localement
      await NotesHighlightsService.deleteNote(noteId);
      _notes.removeWhere((n) => n.id == noteId);
      notifyListeners();
      
      // Supprimer du cloud si disponible
      if (NotesHighlightsCloudService.isAuthenticated) {
        await NotesHighlightsCloudService.deleteNote(noteId);
      }
    } catch (e) {
      _error = 'Erreur lors de la suppression: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Ajoute ou met à jour un surlignement
  Future<void> saveHighlight(SermonHighlight highlight) async {
    try {
      // Sauvegarder localement
      await NotesHighlightsService.saveHighlight(highlight);
      
      final index = _highlights.indexWhere((h) => h.id == highlight.id);
      if (index >= 0) {
        _highlights[index] = highlight;
      } else {
        _highlights.insert(0, highlight);
      }
      
      notifyListeners();
      
      // Synchroniser avec le cloud si activé
      if (_autoSyncEnabled && NotesHighlightsCloudService.isAuthenticated) {
        await NotesHighlightsCloudService.uploadHighlight(highlight);
      }
    } catch (e) {
      _error = 'Erreur lors de la sauvegarde: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Supprime un surlignement
  Future<void> deleteHighlight(String highlightId) async {
    try {
      // Supprimer localement
      await NotesHighlightsService.deleteHighlight(highlightId);
      _highlights.removeWhere((h) => h.id == highlightId);
      notifyListeners();
      
      // Supprimer du cloud si disponible
      if (NotesHighlightsCloudService.isAuthenticated) {
        await NotesHighlightsCloudService.deleteHighlight(highlightId);
      }
    } catch (e) {
      _error = 'Erreur lors de la suppression: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Filtre par recherche
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Filtre par tags
  void setSelectedTags(List<String> tags) {
    _selectedTags = tags;
    notifyListeners();
  }

  /// Retourne les notes filtrées
  List<SermonNote> _getFilteredNotes() {
    var filtered = _notes;

    // Filtre par recherche
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((note) {
        return note.title.toLowerCase().contains(query) ||
            note.content.toLowerCase().contains(query) ||
            note.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    }

    // Filtre par tags
    if (_selectedTags.isNotEmpty) {
      filtered = filtered.where((note) {
        return note.tags.any((tag) => _selectedTags.contains(tag));
      }).toList();
    }

    return filtered;
  }

  /// Retourne les surlignements filtrés
  List<SermonHighlight> _getFilteredHighlights() {
    var filtered = _highlights;

    // Filtre par recherche
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((highlight) {
        return highlight.text.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  /// Récupère tous les tags utilisés
  Set<String> getAllTags() {
    final tags = <String>{};
    for (final note in _notes) {
      tags.addAll(note.tags);
    }
    return tags;
  }

  /// Compte les notes par sermon
  Future<Map<String, int>> getNotesCountBySermon() async {
    return NotesHighlightsService.getNotesCountBySermon();
  }

  /// Compte les surlignements par sermon
  Future<Map<String, int>> getHighlightsCountBySermon() async {
    return NotesHighlightsService.getHighlightsCountBySermon();
  }

  /// Exporte toutes les données
  Future<String> exportData() async {
    return NotesHighlightsService.exportData();
  }

  /// Importe des données
  Future<void> importData(String jsonData) async {
    try {
      await NotesHighlightsService.importData(jsonData);
      await loadAll(forceRefresh: true);
    } catch (e) {
      _error = 'Erreur lors de l\'import: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Vide toutes les données
  Future<void> clearAll() async {
    try {
      await NotesHighlightsService.clearAll();
      _notes = [];
      _highlights = [];
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors de la suppression: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Réinitialise les filtres
  void resetFilters() {
    _searchQuery = '';
    _selectedTags = [];
    notifyListeners();
  }
  
  // ==================== SYNCHRONISATION CLOUD ====================
  
  /// Initialise la synchronisation cloud
  void _initCloudSync() {
    // Écouter les changements d'authentification
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null && _autoSyncEnabled) {
        // Synchroniser automatiquement lors de la connexion
        syncFromCloud();
      }
    });
  }
  
  /// Active/désactive la synchronisation automatique
  void setAutoSync(bool enabled) {
    _autoSyncEnabled = enabled;
    notifyListeners();
  }
  
  /// Synchronise les données vers le cloud
  Future<void> syncToCloud() async {
    if (!NotesHighlightsCloudService.isAuthenticated) {
      _syncError = 'Utilisateur non authentifié';
      notifyListeners();
      return;
    }
    
    _isSyncing = true;
    _syncError = null;
    notifyListeners();
    
    try {
      await NotesHighlightsCloudService.syncToCloud(
        localNotes: _notes,
        localHighlights: _highlights,
      );
      
      _lastSyncTime = DateTime.now();
      _isSyncing = false;
      notifyListeners();
      
      debugPrint('✅ Sync vers cloud terminée');
    } catch (e) {
      _syncError = 'Erreur sync vers cloud: $e';
      _isSyncing = false;
      notifyListeners();
      debugPrint('❌ Erreur sync vers cloud: $e');
    }
  }
  
  /// Synchronise les données depuis le cloud
  Future<void> syncFromCloud() async {
    if (!NotesHighlightsCloudService.isAuthenticated) {
      _syncError = 'Utilisateur non authentifié';
      notifyListeners();
      return;
    }
    
    _isSyncing = true;
    _syncError = null;
    notifyListeners();
    
    try {
      final cloudData = await NotesHighlightsCloudService.syncFromCloud();
      
      // Remplacer les données locales par les données cloud
      _notes = cloudData.notes;
      _highlights = cloudData.highlights;
      
      // Sauvegarder localement
      await NotesHighlightsService.saveAllNotes(_notes);
      await NotesHighlightsService.saveAllHighlights(_highlights);
      
      _lastSyncTime = DateTime.now();
      _isSyncing = false;
      notifyListeners();
      
      debugPrint('✅ Sync depuis cloud terminée');
    } catch (e) {
      _syncError = 'Erreur sync depuis cloud: $e';
      _isSyncing = false;
      notifyListeners();
      debugPrint('❌ Erreur sync depuis cloud: $e');
    }
  }
  
  /// Synchronisation bidirectionnelle avec fusion intelligente
  Future<void> syncBidirectional() async {
    if (!NotesHighlightsCloudService.isAuthenticated) {
      _syncError = 'Utilisateur non authentifié';
      notifyListeners();
      return;
    }
    
    _isSyncing = true;
    _syncError = null;
    notifyListeners();
    
    try {
      final mergedData = await NotesHighlightsCloudService.syncBidirectional(
        localNotes: _notes,
        localHighlights: _highlights,
      );
      
      // Mettre à jour avec les données fusionnées
      _notes = mergedData.notes;
      _highlights = mergedData.highlights;
      
      // Sauvegarder localement
      await NotesHighlightsService.saveAllNotes(_notes);
      await NotesHighlightsService.saveAllHighlights(_highlights);
      
      _lastSyncTime = DateTime.now();
      _isSyncing = false;
      notifyListeners();
      
      debugPrint('✅ Sync bidirectionnelle terminée');
    } catch (e) {
      _syncError = 'Erreur sync bidirectionnelle: $e';
      _isSyncing = false;
      notifyListeners();
      debugPrint('❌ Erreur sync bidirectionnelle: $e');
    }
  }
  
  /// Obtient les statistiques de synchronisation
  Future<Map<String, dynamic>> getSyncStats() async {
    return await NotesHighlightsCloudService.getSyncStats();
  }
  
  /// Supprime toutes les données cloud
  Future<void> clearCloudData() async {
    if (!NotesHighlightsCloudService.isAuthenticated) {
      return;
    }
    
    try {
      await NotesHighlightsCloudService.clearCloudData();
      debugPrint('✅ Données cloud supprimées');
    } catch (e) {
      _syncError = 'Erreur suppression cloud: $e';
      notifyListeners();
      debugPrint('❌ Erreur suppression cloud: $e');
    }
  }
}
