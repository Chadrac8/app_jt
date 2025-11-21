import 'dart:io';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'bible_service.dart';

class AppleNotesShareService {
  static AppleNotesShareService? _instance;
  final BibleService _bibleService = BibleService();
  
  AppleNotesShareService._internal();
  
  factory AppleNotesShareService() {
    _instance ??= AppleNotesShareService._internal();
    return _instance!;
  }

  /// Obtenir le texte du verset via BibleService
  Future<String> _getVerseText(String book, int chapter, int verse) async {
    try {
      // Utiliser BibleService pour récupérer le texte du verset
      final verseData = await _bibleService.getVerse(book, chapter, verse);
      return verseData?.text ?? '';
    } catch (e) {
      print('Erreur lors de la récupération du verset $book $chapter:$verse: $e');
      return '';
    }
  }

  /// Partager une note vers Apple Notes via le système de partage iOS
  Future<void> shareNoteToAppleNotes({
    required String verseReference,
    required String noteContent,
    String? highlightInfo,
    bool isFavorite = false,
    Rect? sharePositionOrigin,
  }) async {
    try {
      // Parser la référence pour récupérer le texte du verset
      String? verseText;
      try {
        final parts = verseReference.split(' ');
        if (parts.length >= 2) {
          final book = parts[0];
          final chapterVerse = parts.sublist(1).join(' ');
          final chapterVerseParts = chapterVerse.split(':');
          
          if (chapterVerseParts.length == 2) {
            final chapter = int.tryParse(chapterVerseParts[0]);
            final verse = int.tryParse(chapterVerseParts[1]);
            
            if (chapter != null && verse != null) {
              verseText = await _getVerseText(book, chapter, verse);
            }
          }
        }
      } catch (e) {
        print('Erreur lors de la récupération du texte pour $verseReference: $e');
      }
      
      // Construire le contenu formaté
      final formattedContent = _buildFormattedNote(
        verseReference: verseReference,
        verseText: verseText,
        noteContent: noteContent,
        highlightInfo: highlightInfo,
        isFavorite: isFavorite,
      );
      
      // Utiliser Share Plus pour partager vers Apple Notes
      await Share.share(
        formattedContent,
        subject: '📖 $verseReference - Bible',
        sharePositionOrigin: sharePositionOrigin,
      );
      
    } catch (e) {
      print('Erreur lors du partage vers Apple Notes: $e');
      rethrow;
    }
  }

  /// Partager toutes les notes en une seule fois
  Future<void> shareAllNotesToAppleNotes({
    required Map<String, String> notes,
    required Map<String, String> highlights,
    required Set<String> favorites,
    Rect? sharePositionOrigin,
  }) async {
    try {
      // Grouper toutes les notes par livre biblique
      final notesByBook = <String, List<Map<String, dynamic>>>{};
      
      // Traiter toutes les annotations
      final allKeys = {...notes.keys, ...highlights.keys, ...favorites};
      
      for (final verseKey in allKeys) {
        final parts = verseKey.split('_');
        if (parts.length != 3) continue;
        
        final book = parts[0];
        final chapter = int.tryParse(parts[1]) ?? 1;
        final verse = int.tryParse(parts[2]) ?? 1;
        
        // Récupérer le texte du verset
        final verseText = await _getVerseText(book, chapter, verse);
        
        if (!notesByBook.containsKey(book)) {
          notesByBook[book] = [];
        }
        
        notesByBook[book]!.add({
          'reference': '$book $chapter:$verse',
          'verseText': verseText,
          'note': notes[verseKey] ?? '',
          'highlight': highlights[verseKey],
          'isFavorite': favorites.contains(verseKey),
        });
      }
      
      // Créer un fichier de sauvegarde complet
      final content = _buildCompleteNotesFile(notesByBook);
      
      // Créer un fichier temporaire
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/mes_notes_bibliques.txt');
      await file.writeAsString(content);
      
      // Partager le contenu directement (évite l'erreur sharePositionOrigin)
      await Share.share(
        content,
        subject: '📖 Mes Notes Bibliques - App Jubilé Tabernacle',
        sharePositionOrigin: sharePositionOrigin,
      );
      
      // Nettoyer le fichier temporaire
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (deleteError) {
        print('Erreur lors de la suppression du fichier temporaire: $deleteError');
      }
      
    } catch (e) {
      print('Erreur lors de l\'export complet: $e');
      rethrow;
    }
  }

  /// Créer une note Apple Notes via URL Scheme (iOS uniquement)
  Future<bool> createAppleNoteViaUrlScheme({
    required String title,
    required String content,
  }) async {
    if (!Platform.isIOS) return false;
    
    try {
      const platform = MethodChannel('app_jubile_tabernacle/apple_notes');
      
      final fullContent = '$title\n\n$content';
      final encodedContent = Uri.encodeComponent(fullContent);
      
      // Essayer d'utiliser l'URL scheme de Notes
      final result = await platform.invokeMethod('openNotesWithContent', {
        'content': encodedContent,
      });
      
      return result == true;
    } catch (e) {
      print('Erreur URL Scheme Notes: $e');
      return false;
    }
  }

  /// Construire une note formatée individuelle
  String _buildFormattedNote({
    required String verseReference,
    String? verseText,
    required String noteContent,
    String? highlightInfo,
    bool isFavorite = false,
  }) {
    final buffer = StringBuffer();
    
    // Titre avec emoji au format titre Apple Notes
    buffer.writeln('# 📖 **$verseReference**');
    buffer.writeln('');
    
    // Badges de statut
    final badges = <String>[];
    if (isFavorite) badges.add('⭐ Favori');
    if (highlightInfo != null) badges.add('🎨 Surligné');
    
    if (badges.isNotEmpty) {
      buffer.writeln(badges.join(' • '));
      buffer.writeln('');
    }
    
    // Texte du verset en citation
    if (verseText != null && verseText.isNotEmpty) {
      buffer.writeln('## 📖 Texte biblique');
      buffer.writeln('> "$verseText"');
      buffer.writeln('');
    }
    
    // Contenu de la note
    if (noteContent.isNotEmpty) {
      buffer.writeln('## 📝 **MA RÉFLEXION**');
      buffer.writeln(noteContent);
      buffer.writeln('');
    }
    
    // Métadonnées
    buffer.writeln('---');
    buffer.writeln('*Créé avec App Jubilé Tabernacle*');
    buffer.writeln('*${DateTime.now().toString().substring(0, 19)}*');
    
    return buffer.toString();
  }

  /// Construire un fichier complet de toutes les notes
  String _buildCompleteNotesFile(Map<String, List<Map<String, dynamic>>> notesByBook) {
    final buffer = StringBuffer();
    
    // En-tête du fichier avec format titre Apple Notes
    buffer.writeln('# 📖 MES NOTES BIBLIQUES');
    buffer.writeln('*App Jubilé Tabernacle*');
    buffer.writeln('*Export du ${DateTime.now().toString().substring(0, 19)}*');
    buffer.writeln('');
    buffer.writeln('---');
    buffer.writeln('');
    
    // Statistiques
    int totalNotes = 0;
    int totalFavorites = 0;
    int totalHighlights = 0;
    
    for (final bookEntries in notesByBook.values) {
      for (final entry in bookEntries) {
        if ((entry['note'] as String).isNotEmpty) totalNotes++;
        if (entry['isFavorite'] == true) totalFavorites++;
        if (entry['highlight'] != null) totalHighlights++;
      }
    }
    
    buffer.writeln('## 📊 STATISTIQUES');
    buffer.writeln('- **Notes:** $totalNotes');
    buffer.writeln('- **Favoris:** $totalFavorites');  
    buffer.writeln('- **Surlignements:** $totalHighlights');
    buffer.writeln('- **Livres annotés:** ${notesByBook.length}');
    buffer.writeln('');
    
    // Contenu par livre
    final sortedBooks = notesByBook.keys.toList()..sort();
    
    for (final book in sortedBooks) {
      final entries = notesByBook[book]!;
      
      buffer.writeln('# 📚 **${book.toUpperCase()}**');
      buffer.writeln('');
      
      // Trier les entrées par référence
      entries.sort((a, b) => a['reference'].compareTo(b['reference']));
      
      for (final entry in entries) {
        buffer.writeln('## 📍 **${entry['reference']}**');
        
        // Badges
        final badges = <String>[];
        if (entry['isFavorite'] == true) badges.add('⭐');
        if (entry['highlight'] != null) badges.add('🎨');
        
        if (badges.isNotEmpty) {
          buffer.writeln('${badges.join(' ')}');
          buffer.writeln('');
        }
        
        // Texte du verset
        final verseText = entry['verseText'] as String? ?? '';
        if (verseText.isNotEmpty) {
          buffer.writeln('> "$verseText"');
          buffer.writeln('');
        }
        
        // Note
        final note = entry['note'] as String;
        if (note.isNotEmpty) {
          buffer.writeln('**📝 MA RÉFLEXION:**');
          buffer.writeln('$note');
          buffer.writeln('');
        }
        
        buffer.writeln('---');
        buffer.writeln('');
      }
      
      buffer.writeln('');
    }
    
    // Pied de page
    buffer.writeln('---');
    buffer.writeln('');
    buffer.writeln('## 💡 COMMENT UTILISER CES NOTES');
    buffer.writeln('');
    buffer.writeln('1. Vous pouvez copier ce texte dans Apple Notes');
    buffer.writeln('2. Créer un dossier **"Bible"** dans Notes');
    buffer.writeln('3. Diviser en notes séparées par livre si souhaité');
    buffer.writeln('4. Utiliser la recherche de Notes pour retrouver vos réflexions');
    buffer.writeln('');
    buffer.writeln('### 🔄 Pour réimporter dans l\'app');
    buffer.writeln('Utilisez la fonction d\'import dans les paramètres Bible');
    
    return buffer.toString();
  }

  /// Créer un export au format Markdown pour une meilleure compatibilité
  Future<void> exportToMarkdown({
    required Map<String, String> notes,
    required Map<String, String> highlights,
    required Set<String> favorites,
  }) async {
    try {
      final buffer = StringBuffer();
      
      // En-tête Markdown
      buffer.writeln('# 📖 Mes Notes Bibliques');
      buffer.writeln('');
      buffer.writeln('*Export depuis App Jubilé Tabernacle*  ');
      buffer.writeln('*${DateTime.now().toString().substring(0, 19)}*');
      buffer.writeln('');
      
      // Grouper par livre
      final notesByBook = <String, List<Map<String, dynamic>>>{};
      final allKeys = {...notes.keys, ...highlights.keys, ...favorites};
      
      for (final verseKey in allKeys) {
        final parts = verseKey.split('_');
        if (parts.length != 3) continue;
        
        final book = parts[0];
        final chapter = int.tryParse(parts[1]) ?? 1;
        final verse = int.tryParse(parts[2]) ?? 1;
        
        if (!notesByBook.containsKey(book)) {
          notesByBook[book] = [];
        }
        
        notesByBook[book]!.add({
          'reference': '$book $chapter:$verse',
          'verseKey': verseKey,
          'note': notes[verseKey] ?? '',
          'highlight': highlights[verseKey],
          'isFavorite': favorites.contains(verseKey),
        });
      }
      
      // Contenu Markdown par livre
      final sortedBooks = notesByBook.keys.toList()..sort();
      
      for (final book in sortedBooks) {
        buffer.writeln('## $book');
        buffer.writeln('');
        
        final entries = notesByBook[book]!;
        entries.sort((a, b) => a['reference'].compareTo(b['reference']));
        
        for (final entry in entries) {
          buffer.writeln('### ${entry['reference']}');
          
          // Badges avec emojis
          final badges = <String>[];
          if (entry['isFavorite'] == true) badges.add('⭐ **Favori**');
          if (entry['highlight'] != null) badges.add('🎨 **Surligné**');
          
          if (badges.isNotEmpty) {
            buffer.writeln('${badges.join(' • ')}');
            buffer.writeln('');
          }
          
          // Note
          final note = entry['note'] as String;
          if (note.isNotEmpty) {
            buffer.writeln('> $note');
          }
          
          buffer.writeln('');
          buffer.writeln('---');
          buffer.writeln('');
        }
      }
      
      // Créer le fichier
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/mes_notes_bibliques.md');
      await file.writeAsString(buffer.toString());
      
      // Partager
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: '📖 Mes Notes Bibliques (Markdown)',
        text: 'Export de mes notes bibliques au format Markdown',
      );
      
    } catch (e) {
      print('Erreur export Markdown: $e');
      rethrow;
    }
  }
}