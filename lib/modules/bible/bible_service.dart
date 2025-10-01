import 'dart:convert';
import 'package:flutter/services.dart';
import 'bible_model.dart';

/// Service pour charger et rechercher dans la Bible (texte local JSON)
class BibleService {
  List<BibleBook>? _books;

  Future<void> loadBible() async {
    final String data = await rootBundle.loadString('assets/bible/lsg1910.json');
    final List<dynamic> jsonData = json.decode(data);
    _books = jsonData.map((b) => BibleBook(
      name: b['name'],
      chapters: List<List<String>>.from(
        b['chapters'].map<List<String>>((c) => List<String>.from(c)),
      ),
    )).toList();
  }

  List<BibleBook> get books => _books ?? [];

  BibleVerse? getVerse(String book, int chapter, int verse) {
    final b = _books?.firstWhere((bk) => bk.name == book, orElse: () => BibleBook(name: '', chapters: []));
    if (b == null || b.chapters.isEmpty) return null;
    if (chapter < 1 || chapter > b.chapters.length) return null;
    final ch = b.chapters[chapter - 1];
    if (verse < 1 || verse > ch.length) return null;
    return BibleVerse(book: book, chapter: chapter, verse: verse, text: ch[verse - 1]);
  }

  // Recherche simple (texte)
  List<BibleVerse> search(String query) {
    final List<BibleVerse> results = [];
    for (final book in books) {
      for (int c = 0; c < book.chapters.length; c++) {
        for (int v = 0; v < book.chapters[c].length; v++) {
          if (book.chapters[c][v].toLowerCase().contains(query.toLowerCase())) {
            results.add(BibleVerse(
              book: book.name,
              chapter: c + 1,
              verse: v + 1,
              text: book.chapters[c][v],
            ));
          }
        }
      }
    }
    return results;
  }
  
  // Recherche avancée avec filtres
  Future<List<BibleVerse>> advancedSearch({
    required String query,
    String? book,
    bool exactMatch = false,
    bool caseSensitive = false,
  }) async {
    final List<BibleVerse> results = [];
    
    // Préparation de la requête selon les options
    String searchQuery = caseSensitive ? query : query.toLowerCase();
    
    // Filtrer les livres selon la sélection
    List<BibleBook> booksToSearch = books;
    if (book != null && book.isNotEmpty) {
      booksToSearch = books.where((b) => b.name == book).toList();
    }
    
    for (final bibleBook in booksToSearch) {
      for (int c = 0; c < bibleBook.chapters.length; c++) {
        for (int v = 0; v < bibleBook.chapters[c].length; v++) {
          String verseText = caseSensitive ? bibleBook.chapters[c][v] : bibleBook.chapters[c][v].toLowerCase();
          
          bool matches = false;
          
          if (exactMatch) {
            // Correspondance exacte: chercher le terme entier
            final regex = RegExp(r'\b' + RegExp.escape(searchQuery) + r'\b', 
                caseSensitive: caseSensitive);
            matches = regex.hasMatch(verseText);
          } else {
            // Correspondance partielle
            matches = verseText.contains(searchQuery);
          }
          
          if (matches) {
            results.add(BibleVerse(
              book: bibleBook.name,
              chapter: c + 1,
              verse: v + 1,
              text: bibleBook.chapters[c][v],
            ));
          }
        }
      }
    }
    
    return results;
  }
  
  // Obtenir un chapitre complet
  List<BibleVerse> getChapter(String bookName, int chapter) {
    final book = books.firstWhere(
      (b) => b.name == bookName,
      orElse: () => BibleBook(name: '', chapters: []),
    );
    
    if (book.chapters.isEmpty || chapter < 1 || chapter > book.chapters.length) {
      return [];
    }
    
    final chapterVerses = book.chapters[chapter - 1];
    return List.generate(
      chapterVerses.length,
      (index) => BibleVerse(
        book: bookName,
        chapter: chapter,
        verse: index + 1,
        text: chapterVerses[index],
      ),
    );
  }
  
  // Obtenir des versets aléatoires pour inspiration
  List<BibleVerse> getRandomVerses(int count) {
    final List<BibleVerse> allVerses = [];
    
    // Collecter tous les versets
    for (final book in books) {
      for (int c = 0; c < book.chapters.length; c++) {
        for (int v = 0; v < book.chapters[c].length; v++) {
          allVerses.add(BibleVerse(
            book: book.name,
            chapter: c + 1,
            verse: v + 1,
            text: book.chapters[c][v],
          ));
        }
      }
    }
    
    // Mélanger et prendre les premiers
    allVerses.shuffle();
    return allVerses.take(count).toList();
  }
  
  // Recherche par mots-clés multiples
  List<BibleVerse> searchMultipleKeywords(List<String> keywords, {bool requireAll = false}) {
    final List<BibleVerse> results = [];
    
    for (final book in books) {
      for (int c = 0; c < book.chapters.length; c++) {
        for (int v = 0; v < book.chapters[c].length; v++) {
          final verseText = book.chapters[c][v].toLowerCase();
          
          bool matches = false;
          if (requireAll) {
            // Tous les mots-clés doivent être présents
            matches = keywords.every((keyword) => verseText.contains(keyword.toLowerCase()));
          } else {
            // Au moins un mot-clé doit être présent
            matches = keywords.any((keyword) => verseText.contains(keyword.toLowerCase()));
          }
          
          if (matches) {
            results.add(BibleVerse(
              book: book.name,
              chapter: c + 1,
              verse: v + 1,
              text: book.chapters[c][v],
            ));
          }
        }
      }
    }
    
    return results;
  }
  
  // Obtenir les statistiques de la Bible
  Map<String, dynamic> getBibleStats() {
    int totalChapters = 0;
    int totalVerses = 0;
    
    for (final book in books) {
      totalChapters += book.chapters.length;
      for (final chapter in book.chapters) {
        totalVerses += chapter.length;
      }
    }
    
    return {
      'totalBooks': books.length,
      'totalChapters': totalChapters,
      'totalVerses': totalVerses,
      'oldTestament': books.take(39).length, // Généralement les 39 premiers livres
      'newTestament': books.skip(39).length,
    };
  }
}
