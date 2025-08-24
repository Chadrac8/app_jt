import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/bible_book.dart';
import '../models/bible_verse.dart';

class BibleService {
  static BibleService? _instance;
  
  BibleService._internal();
  
  factory BibleService() {
    _instance ??= BibleService._internal();
    return _instance!;
  }

  // Cache pour les livres
  List<BibleBook>? _cachedBooks;
  bool _isLoading = false;
  
  Future<List<BibleBook>> getBooks() async {
    if (_cachedBooks != null) {
      return _cachedBooks!;
    }
    
    if (_isLoading) {
      // Attendre que le chargement en cours se termine
      while (_isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _cachedBooks ?? [];
    }
    
    _isLoading = true;
    
    try {
      // Charger les vraies données bibliques depuis le fichier JSON
      final String data = await rootBundle.loadString('assets/bible/lsg1910.json');
      final List<dynamic> jsonData = json.decode(data);
      
      _cachedBooks = jsonData.asMap().entries.map((entry) {
        int index = entry.key;
        Map<String, dynamic> bookData = entry.value;
        
        return BibleBook(
          name: bookData['name'],
          abbreviation: _getBookAbbreviation(bookData['name']),
          testament: index < 39 ? 'old' : 'new', // 39 premiers livres = AT
          bookNumber: index + 1,
          category: _getBookCategory(bookData['name'], index),
          description: _getBookDescription(bookData['name']),
          chapters: List<List<String>>.from(
            bookData['chapters'].map<List<String>>((c) => List<String>.from(c)),
          ),
        );
      }).toList();
      
    } catch (e) {
      print('Erreur lors du chargement de la Bible: $e');
      _cachedBooks = [];
    } finally {
      _isLoading = false;
    }
    
    return _cachedBooks!;
  }

  List<BibleBook> get books => _cachedBooks ?? [];

  Future<BibleVerse?> getVerse(String bookName, int chapter, int verse) async {
    final books = await getBooks();
    final book = books.firstWhere(
      (b) => b.name == bookName, 
      orElse: () => BibleBook(
        name: '', 
        abbreviation: '', 
        testament: '', 
        bookNumber: 0, 
        category: '', 
        description: '', 
        chapters: []
      )
    );
    
    if (book.chapters.isEmpty) return null;
    if (chapter < 1 || chapter > book.chapters.length) return null;
    
    final chapterVerses = book.chapters[chapter - 1];
    if (verse < 1 || verse > chapterVerses.length) return null;
    
    return BibleVerse(
      book: book.name,
      chapter: chapter,
      verse: verse,
      text: chapterVerses[verse - 1],
    );
  }

  Future<List<BibleVerse>> getChapterVerses(String bookName, int chapter) async {
    final books = await getBooks();
    final book = books.firstWhere(
      (b) => b.name == bookName,
      orElse: () => BibleBook(
        name: '', 
        abbreviation: '', 
        testament: '', 
        bookNumber: 0, 
        category: '', 
        description: '', 
        chapters: []
      )
    );
    
    if (book.chapters.isEmpty || chapter < 1 || chapter > book.chapters.length) {
      return [];
    }
    
    final chapterVerses = book.chapters[chapter - 1];
    return chapterVerses.asMap().entries.map((entry) {
      int verseNumber = entry.key + 1;
      String verseText = entry.value;
      
      return BibleVerse(
        book: book.name,
        chapter: chapter,
        verse: verseNumber,
        text: verseText,
      );
    }).toList();
  }

  Future<List<BibleVerse>> search(String query) async {
    if (query.trim().isEmpty) return [];
    
    final books = await getBooks();
    final List<BibleVerse> results = [];
    final searchTerm = query.toLowerCase();
    
    for (final book in books) {
      for (int chapterIndex = 0; chapterIndex < book.chapters.length; chapterIndex++) {
        final chapter = book.chapters[chapterIndex];
        for (int verseIndex = 0; verseIndex < chapter.length; verseIndex++) {
          final verseText = chapter[verseIndex];
          if (verseText.toLowerCase().contains(searchTerm)) {
            results.add(BibleVerse(
              book: book.name,
              chapter: chapterIndex + 1,
              verse: verseIndex + 1,
              text: verseText,
            ));
            
            // Limiter les résultats pour éviter la surcharge
            if (results.length >= 100) {
              return results;
            }
          }
        }
      }
    }
    
    return results;
  }

  // Méthode de recherche avancée avec filtres (pour compatibilité avec les widgets)
  Future<List<BibleVerse>> searchVerses(
    String query, {
    String? bookFilter,
    int limit = 100,
  }) async {
    if (query.trim().isEmpty) return [];
    
    final books = await getBooks();
    final List<BibleVerse> results = [];
    final searchTerm = query.toLowerCase();
    
    // Filtrer les livres si un filtre est spécifié
    List<BibleBook> filteredBooks = books;
    if (bookFilter != null && bookFilter.isNotEmpty) {
      filteredBooks = books.where((book) => 
        book.name.toLowerCase().contains(bookFilter.toLowerCase()) ||
        book.abbreviation.toLowerCase().contains(bookFilter.toLowerCase())
      ).toList();
    }
    
    for (final book in filteredBooks) {
      for (int chapterIndex = 0; chapterIndex < book.chapters.length; chapterIndex++) {
        final chapter = book.chapters[chapterIndex];
        for (int verseIndex = 0; verseIndex < chapter.length; verseIndex++) {
          final verseText = chapter[verseIndex];
          if (verseText.toLowerCase().contains(searchTerm)) {
            results.add(BibleVerse(
              book: book.name,
              chapter: chapterIndex + 1,
              verse: verseIndex + 1,
              text: verseText,
            ));
            
            // Limiter les résultats selon le paramètre limit
            if (results.length >= limit) {
              return results;
            }
          }
        }
      }
    }
    
    return results;
  }

  // Méthodes utilitaires pour obtenir les métadonnées des livres
  String _getBookAbbreviation(String name) {
    final abbreviations = {
      'Genèse': 'Gn',
      'Exode': 'Ex',
      'Lévitique': 'Lv',
      'Nombres': 'Nb',
      'Deutéronome': 'Dt',
      'Josué': 'Jos',
      'Juges': 'Jg',
      'Ruth': 'Rt',
      '1 Samuel': '1S',
      '2 Samuel': '2S',
      '1 Rois': '1R',
      '2 Rois': '2R',
      '1 Chroniques': '1Ch',
      '2 Chroniques': '2Ch',
      'Esdras': 'Esd',
      'Néhémie': 'Né',
      'Esther': 'Est',
      'Job': 'Jb',
      'Psaumes': 'Ps',
      'Proverbes': 'Pr',
      'Ecclésiaste': 'Ec',
      'Cantique des cantiques': 'Ct',
      'Ésaïe': 'Es',
      'Jérémie': 'Jr',
      'Lamentations': 'Lm',
      'Ézéchiel': 'Ez',
      'Daniel': 'Dn',
      'Osée': 'Os',
      'Joël': 'Jl',
      'Amos': 'Am',
      'Abdias': 'Ab',
      'Jonas': 'Jon',
      'Michée': 'Mi',
      'Nahum': 'Na',
      'Habacuc': 'Ha',
      'Sophonie': 'So',
      'Aggée': 'Ag',
      'Zacharie': 'Za',
      'Malachie': 'Ml',
      'Matthieu': 'Mt',
      'Marc': 'Mc',
      'Luc': 'Lc',
      'Jean': 'Jn',
      'Actes': 'Ac',
      'Romains': 'Rm',
      '1 Corinthiens': '1Co',
      '2 Corinthiens': '2Co',
      'Galates': 'Ga',
      'Éphésiens': 'Ep',
      'Philippiens': 'Ph',
      'Colossiens': 'Col',
      '1 Thessaloniciens': '1Th',
      '2 Thessaloniciens': '2Th',
      '1 Timothée': '1Ti',
      '2 Timothée': '2Ti',
      'Tite': 'Tt',
      'Philémon': 'Phm',
      'Hébreux': 'Hé',
      'Jacques': 'Jc',
      '1 Pierre': '1P',
      '2 Pierre': '2P',
      '1 Jean': '1Jn',
      '2 Jean': '2Jn',
      '3 Jean': '3Jn',
      'Jude': 'Jud',
      'Apocalypse': 'Ap',
    };
    return abbreviations[name] ?? name.substring(0, 2);
  }

  String _getBookCategory(String name, int index) {
    if (index < 5) return 'Pentateuque';
    if (index < 12) return 'Historiques';
    if (index < 17) return 'Poétiques';
    if (index < 22) return 'Grands prophètes';
    if (index < 39) return 'Petits prophètes';
    if (index < 43) return 'Évangiles';
    if (index == 43) return 'Histoire';
    if (index < 57) return 'Épîtres pauliniennes';
    if (index < 65) return 'Épîtres générales';
    return 'Prophétie';
  }

  String _getBookDescription(String name) {
    final descriptions = {
      'Genèse': 'Le livre des commencements',
      'Exode': 'La libération d\'Égypte',
      'Matthieu': 'L\'Évangile du Royaume',
      'Marc': 'L\'Évangile de l\'action',
      'Luc': 'L\'Évangile de la grâce',
      'Jean': 'L\'Évangile de l\'amour',
      'Psaumes': 'Le livre de prières d\'Israël',
      'Proverbes': 'La sagesse pratique',
      'Apocalypse': 'La révélation de Jésus-Christ',
    };
    return descriptions[name] ?? 'Livre biblique';
  }
}
