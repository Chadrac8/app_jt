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
  
  Future<List<BibleBook>> getBooks() async {
    if (_cachedBooks != null) {
      return _cachedBooks!;
    }
    
    // Simulation du chargement des livres - dans une vraie app, ceci viendrait d'une API ou base de données
    await Future.delayed(const Duration(milliseconds: 500));
    
    _cachedBooks = [
      // Ancien Testament
      BibleBook(
        name: 'Genèse',
        abbreviation: 'Gn',
        testament: 'old',
        bookNumber: 1,
        category: 'Pentateuque',
        description: 'Le livre des commencements',
        chapters: _generateGenesisChapters(),
      ),
      BibleBook(
        name: 'Exode',
        abbreviation: 'Ex',
        testament: 'old',
        bookNumber: 2,
        category: 'Pentateuque',
        description: 'La libération d\'Égypte',
        chapters: _generateExodusChapters(),
      ),
      BibleBook(
        name: 'Psaumes',
        abbreviation: 'Ps',
        testament: 'old',
        bookNumber: 19,
        category: 'Poétiques',
        description: 'Louanges et prières',
        chapters: _generatePsalmsChapters(),
      ),
      BibleBook(
        name: 'Proverbes',
        abbreviation: 'Pr',
        testament: 'old',
        bookNumber: 20,
        category: 'Poétiques',
        description: 'Sagesse pratique',
        chapters: _generateProverbsChapters(),
      ),
      BibleBook(
        name: 'Ésaïe',
        abbreviation: 'Es',
        testament: 'old',
        bookNumber: 23,
        category: 'Prophètes majeurs',
        description: 'Prophéties messianiques',
        chapters: _generateIsaiahChapters(),
      ),
      
      // Nouveau Testament
      BibleBook(
        name: 'Matthieu',
        abbreviation: 'Mt',
        testament: 'new',
        bookNumber: 40,
        category: 'Évangiles',
        description: 'L\'Évangile du Royaume',
        chapters: _generateMatthewChapters(),
      ),
      BibleBook(
        name: 'Marc',
        abbreviation: 'Mc',
        testament: 'new',
        bookNumber: 41,
        category: 'Évangiles',
        description: 'L\'Évangile de l\'action',
        chapters: _generateMarkChapters(),
      ),
      BibleBook(
        name: 'Luc',
        abbreviation: 'Lc',
        testament: 'new',
        bookNumber: 42,
        category: 'Évangiles',
        description: 'L\'Évangile de la grâce',
        chapters: _generateLukeChapters(),
      ),
      BibleBook(
        name: 'Jean',
        abbreviation: 'Jn',
        testament: 'new',
        bookNumber: 43,
        category: 'Évangiles',
        description: 'L\'Évangile de l\'amour',
        chapters: _generateJohnChapters(),
      ),
      BibleBook(
        name: 'Actes',
        abbreviation: 'Ac',
        testament: 'new',
        bookNumber: 44,
        category: 'Histoire',
        description: 'L\'histoire de l\'Église primitive',
        chapters: _generateActsChapters(),
      ),
      BibleBook(
        name: 'Romains',
        abbreviation: 'Rm',
        testament: 'new',
        bookNumber: 45,
        category: 'Épîtres pauliniennes',
        description: 'La justification par la foi',
        chapters: _generateRomansChapters(),
      ),
      BibleBook(
        name: '1 Corinthiens',
        abbreviation: '1Co',
        testament: 'new',
        bookNumber: 46,
        category: 'Épîtres pauliniennes',
        description: 'L\'ordre dans l\'Église',
        chapters: _generate1CorinthiansChapters(),
      ),
      BibleBook(
        name: 'Galates',
        abbreviation: 'Ga',
        testament: 'new',
        bookNumber: 48,
        category: 'Épîtres pauliniennes',
        description: 'La liberté chrétienne',
        chapters: _generateGalatiansChapters(),
      ),
      BibleBook(
        name: 'Éphésiens',
        abbreviation: 'Ep',
        testament: 'new',
        bookNumber: 49,
        category: 'Épîtres pauliniennes',
        description: 'L\'unité de l\'Église',
        chapters: _generateEphesiansChapters(),
      ),
      BibleBook(
        name: 'Apocalypse',
        abbreviation: 'Ap',
        testament: 'new',
        bookNumber: 66,
        category: 'Prophétique',
        description: 'La révélation de Jésus-Christ',
        chapters: _generateRevelationChapters(),
      ),
    ];
    
    return _cachedBooks!;
  }

  Future<BibleBook?> getBookByName(String name) async {
    final books = await getBooks();
    try {
      return books.firstWhere((book) => book.name == name || book.abbreviation == name);
    } catch (e) {
      return null;
    }
  }

  Future<List<BibleBook>> getOldTestamentBooks() async {
    final books = await getBooks();
    return books.where((book) => book.isOldTestament).toList();
  }

  Future<List<BibleBook>> getNewTestamentBooks() async {
    final books = await getBooks();
    return books.where((book) => book.isNewTestament).toList();
  }

  Future<List<BibleBook>> getBooksByCategory(String category) async {
    final books = await getBooks();
    return books.where((book) => book.category == category).toList();
  }

  Future<List<String>> getCategories() async {
    final books = await getBooks();
    return books.map((book) => book.category).toSet().toList();
  }

  Future<List<BibleVerse>> searchVerses(String query, {
    String? bookFilter,
    int? chapterFilter,
    int limit = 50,
  }) async {
    if (query.isEmpty) return [];
    
    final books = await getBooks();
    final results = <BibleVerse>[];
    
    for (final book in books) {
      if (bookFilter != null && book.name != bookFilter) continue;
      
      for (int chapterIndex = 0; chapterIndex < book.chapters.length; chapterIndex++) {
        final chapterNumber = chapterIndex + 1;
        if (chapterFilter != null && chapterNumber != chapterFilter) continue;
        
        final verses = book.chapters[chapterIndex];
        for (int verseIndex = 0; verseIndex < verses.length; verseIndex++) {
          final verseNumber = verseIndex + 1;
          final verseText = verses[verseIndex];
          
          if (verseText.toLowerCase().contains(query.toLowerCase())) {
            results.add(BibleVerse(
              book: book.name,
              chapter: chapterNumber,
              verse: verseNumber,
              text: verseText,
            ));
            
            if (results.length >= limit) {
              return results;
            }
          }
        }
      }
    }
    
    return results;
  }

  Future<BibleVerse?> getVerse(String bookName, int chapter, int verse) async {
    final book = await getBookByName(bookName);
    if (book == null) return null;
    
    final verseText = book.getVerse(chapter, verse);
    if (verseText == null) return null;
    
    return BibleVerse(
      book: book.name,
      chapter: chapter,
      verse: verse,
      text: verseText,
    );
  }

  Future<List<BibleVerse>> getChapterVerses(String bookName, int chapter) async {
    final book = await getBookByName(bookName);
    if (book == null) return [];
    
    final chapterVerses = book.getChapter(chapter);
    if (chapterVerses == null) return [];
    
    return chapterVerses.asMap().entries.map((entry) {
      return BibleVerse(
        book: book.name,
        chapter: chapter,
        verse: entry.key + 1,
        text: entry.value,
      );
    }).toList();
  }

  Future<List<BibleVerse>> getRandomVerses(int count) async {
    final books = await getBooks();
    final verses = <BibleVerse>[];
    
    for (int i = 0; i < count; i++) {
      final randomBook = books[DateTime.now().millisecondsSinceEpoch % books.length];
      final randomChapter = (DateTime.now().millisecondsSinceEpoch + i) % randomBook.chapters.length;
      final chapterVerses = randomBook.chapters[randomChapter];
      final randomVerse = (DateTime.now().millisecondsSinceEpoch + i * 2) % chapterVerses.length;
      
      verses.add(BibleVerse(
        book: randomBook.name,
        chapter: randomChapter + 1,
        verse: randomVerse + 1,
        text: chapterVerses[randomVerse],
      ));
    }
    
    return verses;
  }

  // Méthodes privées pour générer des données de test
  List<List<String>> _generateGenesisChapters() {
    return List.generate(50, (chapterIndex) {
      return List.generate(30 + (chapterIndex % 10), (verseIndex) {
        return 'Verset ${verseIndex + 1} du chapitre ${chapterIndex + 1} de la Genèse. Ceci est un texte d\'exemple pour les tests de l\'application.';
      });
    });
  }

  List<List<String>> _generateExodusChapters() {
    return List.generate(40, (chapterIndex) {
      return List.generate(25 + (chapterIndex % 15), (verseIndex) {
        return 'Verset ${verseIndex + 1} du chapitre ${chapterIndex + 1} de l\'Exode. Texte d\'exemple pour la lecture biblique.';
      });
    });
  }

  List<List<String>> _generatePsalmsChapters() {
    return List.generate(150, (chapterIndex) {
      return List.generate(10 + (chapterIndex % 20), (verseIndex) {
        return 'Verset ${verseIndex + 1} du Psaume ${chapterIndex + 1}. Louez l\'Éternel car il est bon et sa miséricorde dure à toujours.';
      });
    });
  }

  List<List<String>> _generateProverbsChapters() {
    return List.generate(31, (chapterIndex) {
      return List.generate(20 + (chapterIndex % 15), (verseIndex) {
        return 'Verset ${verseIndex + 1} du chapitre ${chapterIndex + 1} des Proverbes. La sagesse commence par la crainte de l\'Éternel.';
      });
    });
  }

  List<List<String>> _generateIsaiahChapters() {
    return List.generate(66, (chapterIndex) {
      return List.generate(20 + (chapterIndex % 25), (verseIndex) {
        return 'Verset ${verseIndex + 1} du chapitre ${chapterIndex + 1} d\'Ésaïe. Prophétie concernant le Messie et son royaume.';
      });
    });
  }

  List<List<String>> _generateMatthewChapters() {
    return List.generate(28, (chapterIndex) {
      return List.generate(25 + (chapterIndex % 20), (verseIndex) {
        return 'Verset ${verseIndex + 1} du chapitre ${chapterIndex + 1} de Matthieu. Évangile du Royaume des cieux selon Matthieu.';
      });
    });
  }

  List<List<String>> _generateMarkChapters() {
    return List.generate(16, (chapterIndex) {
      return List.generate(30 + (chapterIndex % 15), (verseIndex) {
        return 'Verset ${verseIndex + 1} du chapitre ${chapterIndex + 1} de Marc. Évangile de l\'action et des miracles de Jésus.';
      });
    });
  }

  List<List<String>> _generateLukeChapters() {
    return List.generate(24, (chapterIndex) {
      return List.generate(35 + (chapterIndex % 18), (verseIndex) {
        return 'Verset ${verseIndex + 1} du chapitre ${chapterIndex + 1} de Luc. Évangile de la grâce et de la compassion de Jésus.';
      });
    });
  }

  List<List<String>> _generateJohnChapters() {
    return List.generate(21, (chapterIndex) {
      return List.generate(25 + (chapterIndex % 20), (verseIndex) {
        if (chapterIndex == 2 && verseIndex == 15) {
          return 'Car Dieu a tant aimé le monde qu\'il a donné son Fils unique, afin que quiconque croit en lui ne périsse point, mais qu\'il ait la vie éternelle.';
        }
        return 'Verset ${verseIndex + 1} du chapitre ${chapterIndex + 1} de Jean. Évangile de l\'amour divin et de la vie éternelle.';
      });
    });
  }

  List<List<String>> _generateActsChapters() {
    return List.generate(28, (chapterIndex) {
      return List.generate(30 + (chapterIndex % 16), (verseIndex) {
        return 'Verset ${verseIndex + 1} du chapitre ${chapterIndex + 1} des Actes. Histoire de l\'Église primitive et de l\'expansion de l\'Évangile.';
      });
    });
  }

  List<List<String>> _generateRomansChapters() {
    return List.generate(16, (chapterIndex) {
      return List.generate(25 + (chapterIndex % 14), (verseIndex) {
        return 'Verset ${verseIndex + 1} du chapitre ${chapterIndex + 1} de Romains. Épître sur la justification par la foi en Jésus-Christ.';
      });
    });
  }

  List<List<String>> _generate1CorinthiansChapters() {
    return List.generate(16, (chapterIndex) {
      return List.generate(20 + (chapterIndex % 18), (verseIndex) {
        if (chapterIndex == 12 && verseIndex == 12) {
          return 'L\'amour est patient, l\'amour est bon; il n\'est point envieux; l\'amour ne se vante point, il ne s\'enfle point d\'orgueil.';
        }
        return 'Verset ${verseIndex + 1} du chapitre ${chapterIndex + 1} de 1 Corinthiens. Enseignements sur l\'ordre dans l\'Église.';
      });
    });
  }

  List<List<String>> _generateGalatiansChapters() {
    return List.generate(6, (chapterIndex) {
      return List.generate(18 + (chapterIndex % 12), (verseIndex) {
        return 'Verset ${verseIndex + 1} du chapitre ${chapterIndex + 1} de Galates. Épître sur la liberté chrétienne et la grâce.';
      });
    });
  }

  List<List<String>> _generateEphesiansChapters() {
    return List.generate(6, (chapterIndex) {
      return List.generate(20 + (chapterIndex % 14), (verseIndex) {
        return 'Verset ${verseIndex + 1} du chapitre ${chapterIndex + 1} d\'Éphésiens. Épître sur l\'unité de l\'Église et la vie chrétienne.';
      });
    });
  }

  List<List<String>> _generateRevelationChapters() {
    return List.generate(22, (chapterIndex) {
      return List.generate(15 + (chapterIndex % 20), (verseIndex) {
        return 'Verset ${verseIndex + 1} du chapitre ${chapterIndex + 1} de l\'Apocalypse. Révélation de Jésus-Christ et des temps de la fin.';
      });
    });
  }

  // Méthodes utilitaires
  void clearCache() {
    _cachedBooks = null;
  }

  Future<Map<String, int>> getStatistics() async {
    final books = await getBooks();
    
    final oldTestamentBooks = books.where((b) => b.isOldTestament).length;
    final newTestamentBooks = books.where((b) => b.isNewTestament).length;
    final totalChapters = books.fold(0, (sum, book) => sum + book.totalChapters);
    final totalVerses = books.fold(0, (sum, book) => sum + book.totalVerses);
    
    return {
      'totalBooks': books.length,
      'oldTestamentBooks': oldTestamentBooks,
      'newTestamentBooks': newTestamentBooks,
      'totalChapters': totalChapters,
      'totalVerses': totalVerses,
    };
  }
}
