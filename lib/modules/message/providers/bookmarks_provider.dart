import 'package:flutter/foundation.dart';
import '../models/sermon_bookmark.dart';
import '../services/bookmarks_service.dart';

/// Provider pour gérer les signets
class BookmarksProvider with ChangeNotifier {
  List<SermonBookmark> _bookmarks = [];
  bool _isLoading = false;
  String? _error;

  List<SermonBookmark> get bookmarks => _bookmarks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  BookmarksProvider() {
    _loadBookmarks();
  }

  /// Charge tous les signets
  Future<void> _loadBookmarks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _bookmarks = await BookmarksService.getAllBookmarks();
    } catch (e) {
      _error = 'Erreur chargement signets: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Recharge les signets
  Future<void> refresh() async {
    await _loadBookmarks();
  }

  /// Récupère les signets pour un sermon
  List<SermonBookmark> getBookmarksForSermon(String sermonId) {
    return _bookmarks.where((bm) => bm.sermonId == sermonId).toList()
      ..sort((a, b) => a.pageNumber.compareTo(b.pageNumber));
  }

  /// Ajoute un nouveau signet
  Future<void> addBookmark(SermonBookmark bookmark) async {
    try {
      await BookmarksService.saveBookmark(bookmark);
      _bookmarks.add(bookmark);
      notifyListeners();
    } catch (e) {
      _error = 'Erreur ajout signet: $e';
      debugPrint(_error);
      rethrow;
    }
  }

  /// Met à jour un signet
  Future<void> updateBookmark(SermonBookmark bookmark) async {
    try {
      await BookmarksService.saveBookmark(bookmark);
      final index = _bookmarks.indexWhere((bm) => bm.id == bookmark.id);
      if (index >= 0) {
        _bookmarks[index] = bookmark;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Erreur mise à jour signet: $e';
      debugPrint(_error);
      rethrow;
    }
  }

  /// Supprime un signet
  Future<void> deleteBookmark(String bookmarkId) async {
    try {
      await BookmarksService.deleteBookmark(bookmarkId);
      _bookmarks.removeWhere((bm) => bm.id == bookmarkId);
      notifyListeners();
    } catch (e) {
      _error = 'Erreur suppression signet: $e';
      debugPrint(_error);
      rethrow;
    }
  }

  /// Compte les signets par sermon
  Map<String, int> getBookmarksCountBySermon() {
    final Map<String, int> counts = {};
    for (final bookmark in _bookmarks) {
      counts[bookmark.sermonId] = (counts[bookmark.sermonId] ?? 0) + 1;
    }
    return counts;
  }

  /// Recherche dans les signets
  List<SermonBookmark> searchBookmarks(String query) {
    if (query.trim().isEmpty) return _bookmarks;

    final lowerQuery = query.toLowerCase();
    return _bookmarks.where((bookmark) {
      return bookmark.title.toLowerCase().contains(lowerQuery) ||
          (bookmark.description?.toLowerCase().contains(lowerQuery) ?? false) ||
          bookmark.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  /// Vérifie si un signet existe pour une page spécifique
  bool hasBookmarkAtPage(String sermonId, int pageNumber) {
    return _bookmarks.any(
      (bm) => bm.sermonId == sermonId && bm.pageNumber == pageNumber,
    );
  }

  /// Récupère le signet à une page spécifique
  SermonBookmark? getBookmarkAtPage(String sermonId, int pageNumber) {
    try {
      return _bookmarks.firstWhere(
        (bm) => bm.sermonId == sermonId && bm.pageNumber == pageNumber,
      );
    } catch (e) {
      return null;
    }
  }

  /// Exporte les données
  Future<String> exportData() async {
    return await BookmarksService.exportData();
  }

  /// Importe les données
  Future<void> importData(String jsonData) async {
    await BookmarksService.importData(jsonData);
    await _loadBookmarks();
  }

  /// Vide tous les signets
  Future<void> clearAll() async {
    await BookmarksService.clearAll();
    _bookmarks = [];
    notifyListeners();
  }
}
