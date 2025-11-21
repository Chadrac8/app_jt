import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BibleAnnotationService {
  static BibleAnnotationService? _instance;
  
  BibleAnnotationService._internal();
  
  factory BibleAnnotationService() {
    _instance ??= BibleAnnotationService._internal();
    return _instance!;
  }


  
  // Cache des données
  Set<String> _favorites = {};
  Map<String, Color> _highlights = {};
  Map<String, String> _notes = {};
  
  // Getters pour accéder aux données
  Set<String> get favorites => _favorites;
  Map<String, Color> get highlights => _highlights;
  Map<String, String> get notes => _notes;

  /// Initialiser le service d'annotation
  Future<void> initialize() async {
    await loadAnnotations();

  }

  /// Charger toutes les annotations depuis SharedPreferences
  Future<void> loadAnnotations() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Charger les favoris
    final favoritesList = prefs.getStringList('bible_favorites') ?? [];
    _favorites = favoritesList.toSet();
    
    // Charger les surlignements
    final highlightsList = prefs.getStringList('bible_highlights') ?? [];
    _highlights.clear();
    for (final highlight in highlightsList) {
      if (highlight.contains(':')) {
        final parts = highlight.split(':');
        if (parts.length == 2) {
          final verseKey = parts[0];
          final colorValue = int.tryParse(parts[1]);
          if (colorValue != null) {
            _highlights[verseKey] = Color(colorValue);
          }
        }
      } else {
        // Ancien format, utiliser couleur par défaut
        _highlights[highlight] = const Color(0xFFFFE066);
      }
    }
    
    // Charger les notes
    final notesString = prefs.getString('bible_notes') ?? '{}';
    try {
      final notesMap = jsonDecode(notesString) as Map<String, dynamic>;
      _notes = Map<String, String>.from(notesMap);
    } catch (e) {
      print('Erreur lors du chargement des notes: $e');
      _notes.clear();
    }
    
    print('BibleAnnotationService: Annotations chargées - Favoris: ${_favorites.length}, Surlignements: ${_highlights.length}, Notes: ${_notes.length}');
  }

  /// Sauvegarder toutes les annotations
  Future<void> saveAnnotations() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Sauvegarder les favoris
    await prefs.setStringList('bible_favorites', _favorites.toList());
    
    // Sauvegarder les surlignements avec couleurs
    final highlightsList = _highlights.entries
        .map((entry) => '${entry.key}:${entry.value.value}')
        .toList();
    await prefs.setStringList('bible_highlights', highlightsList);
    
    // Sauvegarder les notes
    await prefs.setString('bible_notes', jsonEncode(_notes));
    
    print('BibleAnnotationService: Annotations sauvegardées');
  }

  /// Ajouter/retirer un favori
  Future<void> toggleFavorite(String verseKey) async {
    if (_favorites.contains(verseKey)) {
      _favorites.remove(verseKey);
    } else {
      _favorites.add(verseKey);
    }
    
    await saveAnnotations();
  }

  /// Ajouter/modifier un surlignement
  Future<void> setHighlight(String verseKey, Color color) async {
    _highlights[verseKey] = color;
    await saveAnnotations();
  }

  /// Supprimer un surlignement
  Future<void> removeHighlight(String verseKey) async {
    _highlights.remove(verseKey);
    await saveAnnotations();
  }

  /// Basculer le surlignement avec couleur par défaut
  Future<void> toggleHighlight(String verseKey, {Color? color}) async {
    if (_highlights.containsKey(verseKey)) {
      await removeHighlight(verseKey);
    } else {
      await setHighlight(verseKey, color ?? const Color(0xFFFFE066));
    }
  }

  /// Ajouter/modifier une note
  Future<void> setNote(String verseKey, String noteText) async {
    if (noteText.trim().isEmpty) {
      _notes.remove(verseKey);
    } else {
      _notes[verseKey] = noteText.trim();
    }
    
    await saveAnnotations();
  }

  /// Supprimer une note
  Future<void> removeNote(String verseKey) async {
    _notes.remove(verseKey);
    await saveAnnotations();
  }

  /// Supprimer toutes les annotations d'un verset
  Future<void> clearVerseAnnotations(String verseKey) async {
    _favorites.remove(verseKey);
    _highlights.remove(verseKey);
    _notes.remove(verseKey);
    
    await saveAnnotations();
    

  }

  /// Vérifier si un verset a des annotations
  bool hasAnnotations(String verseKey) {
    return _favorites.contains(verseKey) ||
           _highlights.containsKey(verseKey) ||
           (_notes.containsKey(verseKey) && _notes[verseKey]!.isNotEmpty);
  }

  /// Obtenir le résumé des annotations d'un verset
  Map<String, dynamic> getVerseAnnotationSummary(String verseKey) {
    return {
      'isFavorite': _favorites.contains(verseKey),
      'hasHighlight': _highlights.containsKey(verseKey),
      'highlightColor': _highlights[verseKey],
      'hasNote': _notes.containsKey(verseKey) && _notes[verseKey]!.isNotEmpty,
      'noteText': _notes[verseKey] ?? '',
    };
  }

  /// Obtenir toutes les clés de versets annotés
  List<String> getAllAnnotatedVerseKeys() {
    final allKeys = <String>{};
    allKeys.addAll(_favorites);
    allKeys.addAll(_highlights.keys);
    allKeys.addAll(_notes.keys.where((key) => _notes[key]!.isNotEmpty));
    return allKeys.toList();
  }

  /// Rechercher dans les notes
  List<String> searchInNotes(String query) {
    if (query.trim().isEmpty) return [];
    
    final queryLower = query.toLowerCase();
    return _notes.entries
        .where((entry) => 
            entry.value.toLowerCase().contains(queryLower) ||
            _getVerseDisplayText(entry.key).toLowerCase().contains(queryLower))
        .map((entry) => entry.key)
        .toList();
  }



  /// Obtenir les statistiques des annotations
  Map<String, int> getAnnotationStats() {
    return {
      'favorites': _favorites.length,
      'highlights': _highlights.length,
      'notes': _notes.values.where((note) => note.isNotEmpty).length,
      'total': getAllAnnotatedVerseKeys().length,
    };
  }

  /// Synchroniser vers Apple Notes si activé et en mode auto


  /// Obtenir le texte d'affichage d'une référence de verset
  String _getVerseDisplayText(String verseKey) {
    final parts = verseKey.split('_');
    if (parts.length != 3) return verseKey;
    
    final book = parts[0];
    final chapter = parts[1];
    final verse = parts[2];
    
    return '$book $chapter:$verse';
  }

  /// Nettoyer toutes les annotations (avec confirmation)
  Future<void> clearAllAnnotations() async {
    _favorites.clear();
    _highlights.clear();
    _notes.clear();
    
    await saveAnnotations();
    
    print('BibleAnnotationService: Toutes les annotations ont été supprimées');
  }

  /// Importer des annotations depuis un autre format
  Future<void> importAnnotations({
    List<String>? favorites,
    Map<String, Color>? highlights,
    Map<String, String>? notes,
    bool merge = true,
  }) async {
    if (!merge) {
      _favorites.clear();
      _highlights.clear();
      _notes.clear();
    }
    
    if (favorites != null) {
      _favorites.addAll(favorites);
    }
    
    if (highlights != null) {
      _highlights.addAll(highlights);
    }
    
    if (notes != null) {
      _notes.addAll(notes);
    }
    
    await saveAnnotations();
    

    
    print('BibleAnnotationService: Annotations importées');
  }
}