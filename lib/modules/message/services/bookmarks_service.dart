import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sermon_bookmark.dart';

/// Service pour gérer les signets locaux
class BookmarksService {
  static const String _bookmarksKey = 'wb_search_bookmarks';

  // Cache mémoire
  static List<SermonBookmark>? _cachedBookmarks;

  /// Récupère tous les signets
  static Future<List<SermonBookmark>> getAllBookmarks({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedBookmarks != null) {
      return _cachedBookmarks!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = prefs.getString(_bookmarksKey);
      
      if (bookmarksJson != null) {
        final List<dynamic> jsonList = json.decode(bookmarksJson);
        _cachedBookmarks = jsonList
            .map((json) => SermonBookmark.fromJson(json as Map<String, dynamic>))
            .toList();
        return _cachedBookmarks!;
      }
    } catch (e) {
      debugPrint('Erreur lecture bookmarks: $e');
    }

    _cachedBookmarks = [];
    return [];
  }

  /// Récupère tous les signets pour un sermon spécifique
  static Future<List<SermonBookmark>> getBookmarksForSermon(String sermonId) async {
    final allBookmarks = await getAllBookmarks();
    return allBookmarks.where((bm) => bm.sermonId == sermonId).toList();
  }

  /// Ajoute ou met à jour un signet
  static Future<void> saveBookmark(SermonBookmark bookmark) async {
    final bookmarks = await getAllBookmarks();
    final existingIndex = bookmarks.indexWhere((bm) => bm.id == bookmark.id);

    if (existingIndex >= 0) {
      bookmarks[existingIndex] = bookmark.copyWith(updatedAt: DateTime.now());
    } else {
      bookmarks.add(bookmark);
    }

    await _saveBookmarks(bookmarks);
  }

  /// Supprime un signet
  static Future<void> deleteBookmark(String bookmarkId) async {
    final bookmarks = await getAllBookmarks();
    bookmarks.removeWhere((bm) => bm.id == bookmarkId);
    await _saveBookmarks(bookmarks);
  }

  /// Sauvegarde les signets en local
  static Future<void> _saveBookmarks(List<SermonBookmark> bookmarks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = bookmarks.map((bm) => bm.toJson()).toList();
      await prefs.setString(_bookmarksKey, json.encode(jsonList));
      _cachedBookmarks = bookmarks;
    } catch (e) {
      debugPrint('Erreur sauvegarde bookmarks: $e');
      rethrow;
    }
  }

  /// Sauvegarde tous les signets (méthode publique pour sync)
  static Future<void> saveAllBookmarks(List<SermonBookmark> bookmarks) async {
    await _saveBookmarks(bookmarks);
  }

  /// Compte les signets par sermon
  static Future<Map<String, int>> getBookmarksCountBySermon() async {
    final bookmarks = await getAllBookmarks();
    final Map<String, int> counts = {};
    
    for (final bookmark in bookmarks) {
      counts[bookmark.sermonId] = (counts[bookmark.sermonId] ?? 0) + 1;
    }
    
    return counts;
  }

  /// Recherche dans les signets
  static Future<List<SermonBookmark>> searchBookmarks(String query) async {
    final bookmarks = await getAllBookmarks();
    final lowerQuery = query.toLowerCase();
    
    return bookmarks.where((bookmark) {
      return bookmark.title.toLowerCase().contains(lowerQuery) ||
          (bookmark.description?.toLowerCase().contains(lowerQuery) ?? false) ||
          bookmark.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  /// Exporte tous les signets en JSON
  static Future<String> exportData() async {
    final bookmarks = await getAllBookmarks();
    final data = {
      'bookmarks': bookmarks.map((bm) => bm.toJson()).toList(),
      'exportDate': DateTime.now().toIso8601String(),
      'version': '1.0',
    };
    return json.encode(data);
  }

  /// Importe des signets depuis JSON
  static Future<void> importData(String jsonData) async {
    try {
      final Map<String, dynamic> data = json.decode(jsonData);
      final List<dynamic> bookmarksJson = data['bookmarks'];
      
      final bookmarks = bookmarksJson
          .map((json) => SermonBookmark.fromJson(json as Map<String, dynamic>))
          .toList();
      
      await _saveBookmarks(bookmarks);
    } catch (e) {
      debugPrint('Erreur import bookmarks: $e');
      rethrow;
    }
  }

  /// Vide tous les signets
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_bookmarksKey);
    _cachedBookmarks = [];
  }
}
