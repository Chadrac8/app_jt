import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sermon_note.dart';
import '../models/sermon_highlight.dart';

/// Service pour gérer les notes et surlignements locaux
class NotesHighlightsService {
  static const String _notesKey = 'wb_search_notes';
  static const String _highlightsKey = 'wb_search_highlights';

  // Cache mémoire
  static List<SermonNote>? _cachedNotes;
  static List<SermonHighlight>? _cachedHighlights;

  /// Récupère toutes les notes
  static Future<List<SermonNote>> getAllNotes({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedNotes != null) {
      return _cachedNotes!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getString(_notesKey);
      
      if (notesJson != null) {
        final List<dynamic> jsonList = json.decode(notesJson);
        _cachedNotes = jsonList
            .map((json) => SermonNote.fromJson(json as Map<String, dynamic>))
            .toList();
        return _cachedNotes!;
      }
    } catch (e) {
      debugPrint('Erreur lecture notes: $e');
    }

    _cachedNotes = [];
    return [];
  }

  /// Récupère toutes les notes pour un sermon spécifique
  static Future<List<SermonNote>> getNotesForSermon(String sermonId) async {
    final allNotes = await getAllNotes();
    return allNotes.where((note) => note.sermonId == sermonId).toList();
  }

  /// Ajoute ou met à jour une note
  static Future<void> saveNote(SermonNote note) async {
    final notes = await getAllNotes();
    final existingIndex = notes.indexWhere((n) => n.id == note.id);

    if (existingIndex >= 0) {
      notes[existingIndex] = note.copyWith(updatedAt: DateTime.now());
    } else {
      notes.add(note);
    }

    await _saveNotes(notes);
  }

  /// Supprime une note
  static Future<void> deleteNote(String noteId) async {
    final notes = await getAllNotes();
    notes.removeWhere((note) => note.id == noteId);
    await _saveNotes(notes);
  }

  /// Sauvegarde les notes en local
  static Future<void> _saveNotes(List<SermonNote> notes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = notes.map((n) => n.toJson()).toList();
      await prefs.setString(_notesKey, json.encode(jsonList));
      _cachedNotes = notes;
    } catch (e) {
      debugPrint('Erreur sauvegarde notes: $e');
      rethrow;
    }
  }

  /// Sauvegarde toutes les notes (méthode publique pour sync)
  static Future<void> saveAllNotes(List<SermonNote> notes) async {
    await _saveNotes(notes);
  }

  /// Récupère tous les surlignements
  static Future<List<SermonHighlight>> getAllHighlights({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedHighlights != null) {
      return _cachedHighlights!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final highlightsJson = prefs.getString(_highlightsKey);
      
      if (highlightsJson != null) {
        final List<dynamic> jsonList = json.decode(highlightsJson);
        _cachedHighlights = jsonList
            .map((json) => SermonHighlight.fromJson(json as Map<String, dynamic>))
            .toList();
        return _cachedHighlights!;
      }
    } catch (e) {
      debugPrint('Erreur lecture surlignements: $e');
    }

    _cachedHighlights = [];
    return [];
  }

  /// Récupère tous les surlignements pour un sermon spécifique
  static Future<List<SermonHighlight>> getHighlightsForSermon(String sermonId) async {
    final allHighlights = await getAllHighlights();
    return allHighlights.where((h) => h.sermonId == sermonId).toList();
  }

  /// Ajoute ou met à jour un surlignement
  static Future<void> saveHighlight(SermonHighlight highlight) async {
    final highlights = await getAllHighlights();
    final existingIndex = highlights.indexWhere((h) => h.id == highlight.id);

    if (existingIndex >= 0) {
      highlights[existingIndex] = highlight.copyWith(updatedAt: DateTime.now());
    } else {
      highlights.add(highlight);
    }

    await _saveHighlights(highlights);
  }

  /// Supprime un surlignement
  static Future<void> deleteHighlight(String highlightId) async {
    final highlights = await getAllHighlights();
    highlights.removeWhere((h) => h.id == highlightId);
    await _saveHighlights(highlights);
  }

  /// Sauvegarde les surlignements en local
  static Future<void> _saveHighlights(List<SermonHighlight> highlights) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = highlights.map((h) => h.toJson()).toList();
      await prefs.setString(_highlightsKey, json.encode(jsonList));
      _cachedHighlights = highlights;
    } catch (e) {
      debugPrint('Erreur sauvegarde surlignements: $e');
      rethrow;
    }
  }

  /// Sauvegarde tous les surlignements (méthode publique pour sync)
  static Future<void> saveAllHighlights(List<SermonHighlight> highlights) async {
    await _saveHighlights(highlights);
  }

  /// Recherche dans les notes
  static Future<List<SermonNote>> searchNotes(String query) async {
    final notes = await getAllNotes();
    final lowerQuery = query.toLowerCase();
    
    return notes.where((note) {
      return note.title.toLowerCase().contains(lowerQuery) ||
          note.content.toLowerCase().contains(lowerQuery) ||
          note.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  /// Recherche dans les surlignements
  static Future<List<SermonHighlight>> searchHighlights(String query) async {
    final highlights = await getAllHighlights();
    final lowerQuery = query.toLowerCase();
    
    return highlights.where((h) {
      return h.text.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Compte les notes par sermon
  static Future<Map<String, int>> getNotesCountBySermon() async {
    final notes = await getAllNotes();
    final counts = <String, int>{};
    
    for (final note in notes) {
      counts[note.sermonId] = (counts[note.sermonId] ?? 0) + 1;
    }
    
    return counts;
  }

  /// Compte les surlignements par sermon
  static Future<Map<String, int>> getHighlightsCountBySermon() async {
    final highlights = await getAllHighlights();
    final counts = <String, int>{};
    
    for (final highlight in highlights) {
      counts[highlight.sermonId] = (counts[highlight.sermonId] ?? 0) + 1;
    }
    
    return counts;
  }

  /// Vide toutes les données
  static Future<void> clearAll() async {
    _cachedNotes = null;
    _cachedHighlights = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_notesKey);
    await prefs.remove(_highlightsKey);
  }

  /// Exporte toutes les notes et surlignements en JSON
  static Future<String> exportData() async {
    final notes = await getAllNotes();
    final highlights = await getAllHighlights();
    
    final data = {
      'notes': notes.map((n) => n.toJson()).toList(),
      'highlights': highlights.map((h) => h.toJson()).toList(),
      'exportDate': DateTime.now().toIso8601String(),
    };
    
    return json.encode(data);
  }

  /// Importe des notes et surlignements depuis JSON
  static Future<void> importData(String jsonData) async {
    try {
      final data = json.decode(jsonData) as Map<String, dynamic>;
      
      final notes = (data['notes'] as List<dynamic>)
          .map((json) => SermonNote.fromJson(json as Map<String, dynamic>))
          .toList();
      
      final highlights = (data['highlights'] as List<dynamic>)
          .map((json) => SermonHighlight.fromJson(json as Map<String, dynamic>))
          .toList();
      
      await _saveNotes(notes);
      await _saveHighlights(highlights);
    } catch (e) {
      debugPrint('Erreur import données: $e');
      rethrow;
    }
  }
}
