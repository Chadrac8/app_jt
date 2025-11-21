import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme.dart';
import '../models/bible_book.dart';

class BookChapterSelector extends StatefulWidget {
  final List<BibleBook> books;
  final String? selectedBook;
  final int? selectedChapter;
  final int? selectedVerse;
  final Function(String book, int chapter, int? verse) onBookChapterVerseSelected;

  const BookChapterSelector({
    Key? key,
    required this.books,
    this.selectedBook,
    this.selectedChapter,
    this.selectedVerse,
    required this.onBookChapterVerseSelected,
  }) : super(key: key);

  @override
  State<BookChapterSelector> createState() => _BookChapterSelectorState();
}

class _BookChapterSelectorState extends State<BookChapterSelector>
    with TickerProviderStateMixin {
  late TabController _testamentTabController;
  String? _selectedBook;
  int? _selectedChapter;
  int? _selectedVerse;
  bool _showVerseSelection = false;
  
  @override
  void initState() {
    super.initState();
    _testamentTabController = TabController(length: 2, vsync: this);
    _selectedBook = widget.selectedBook;
    _selectedChapter = widget.selectedChapter;
  }

  @override
  void dispose() {
    _testamentTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: AppTheme.white100,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Poignée de glissement
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: AppTheme.grey300,
              borderRadius: BorderRadius.circular(AppTheme.radius2),
            ),
          ),
          
          // En-tête
          Padding(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            child: Row(
              children: [
                Text(
                  'Sélectionner un passage',
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize20,
                    fontWeight: AppTheme.fontBold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Onglets Testament
          Container(
            color: AppTheme.primaryColor, // Couleur primaire cohérente
            child: TabBar(
              controller: _testamentTabController,
              labelColor: AppTheme.onPrimaryColor, // Texte blanc
              unselectedLabelColor: AppTheme.onPrimaryColor.withOpacity(0.7), // Texte blanc semi-transparent
              indicatorColor: AppTheme.onPrimaryColor, // Indicateur blanc
            tabs: const [
              Tab(text: 'Ancien Testament'),
              Tab(text: 'Nouveau Testament'),
            ],
          ),
          ),
          
          // Contenu des onglets
          Expanded(
            child: _showVerseSelection 
                ? _buildVerseSelection() 
                : TabBarView(
                    controller: _testamentTabController,
                    children: [
                      _buildTestamentBooks('old'),
                      _buildTestamentBooks('new'),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestamentBooks(String testament) {
    final books = widget.books.where((book) => book.testament == testament).toList();
    
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        final isSelected = _selectedBook == book.name;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: isSelected ? 4 : 1,
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : null,
          child: ExpansionTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppTheme.primaryColor 
                    : AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Center(
                child: Text(
                  book.abbreviation,
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize12,
                    fontWeight: AppTheme.fontBold,
                    color: isSelected ? AppTheme.white100 : AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
            title: Text(
              book.name,
              style: GoogleFonts.inter(
                fontWeight: AppTheme.fontSemiBold,
                color: isSelected ? AppTheme.primaryColor : AppTheme.black100.withOpacity(0.87),
              ),
            ),
            subtitle: Text(
              '${book.totalChapters} chapitres',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize12,
                color: AppTheme.grey600,
              ),
            ),
            onExpansionChanged: (expanded) {
              if (expanded) {
                setState(() {
                  _selectedBook = book.name;
                  _selectedChapter = null;
                });
              }
            },
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sélectionner un chapitre:',
                      style: GoogleFonts.inter(
                        fontWeight: AppTheme.fontMedium,
                        color: AppTheme.grey700,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(book.totalChapters, (chapterIndex) {
                        final chapterNumber = chapterIndex + 1;
                        final isChapterSelected = _selectedChapter == chapterNumber && 
                                                _selectedBook == book.name;
                        
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedBook = book.name;
                              _selectedChapter = chapterNumber;
                              _showVerseSelection = true; // Afficher automatiquement la sélection de versets
                            });
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isChapterSelected 
                                  ? AppTheme.primaryColor 
                                  : AppTheme.grey100,
                              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                              border: Border.all(
                                color: isChapterSelected 
                                    ? AppTheme.primaryColor 
                                    : AppTheme.grey300,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '$chapterNumber',
                                style: GoogleFonts.inter(
                                  fontWeight: AppTheme.fontSemiBold,
                                  color: isChapterSelected 
                                      ? AppTheme.white100 
                                      : AppTheme.black100.withOpacity(0.87),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVerseSelection() {
    if (_selectedBook == null || _selectedChapter == null) {
      return const Center(child: Text('Aucun chapitre sélectionné'));
    }

    // Estimation du nombre de versets (plus tard, on pourrait avoir les données exactes)
    final estimatedVerses = _getEstimatedVerseCount(_selectedBook!, _selectedChapter!);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec bouton retour
          Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _showVerseSelection = false;
                    _selectedVerse = null;
                  });
                },
                icon: const Icon(Icons.arrow_back),
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Choisir un verset de $_selectedBook $_selectedChapter',
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize16,
                    fontWeight: AppTheme.fontSemiBold,
                    color: AppTheme.black100.withOpacity(0.87),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spaceMedium),
          
          // Grille de versets style YouVersion
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(estimatedVerses, (verseIndex) {
              final verseNumber = verseIndex + 1;
              final isVerseSelected = _selectedVerse == verseNumber;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedVerse = verseNumber;
                  });
                  // Navigation immédiate vers le verset sélectionné
                  widget.onBookChapterVerseSelected(_selectedBook!, _selectedChapter!, verseNumber);
                  Navigator.pop(context);
                },
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isVerseSelected 
                        ? AppTheme.primaryColor 
                        : AppTheme.grey50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isVerseSelected 
                          ? AppTheme.primaryColor 
                          : AppTheme.grey300,
                      width: isVerseSelected ? 2 : 1,
                    ),
                    boxShadow: isVerseSelected 
                        ? [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '$verseNumber',
                      style: GoogleFonts.inter(
                        fontSize: AppTheme.fontSize14,
                        fontWeight: AppTheme.fontSemiBold,
                        color: isVerseSelected 
                            ? AppTheme.white100 
                            : AppTheme.black100.withOpacity(0.87),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  int _getEstimatedVerseCount(String bookName, int chapter) {
    // Estimation basique du nombre de versets par chapitre
    // Dans une version complète, ces données seraient stockées dans la base de données
    final Map<String, Map<int, int>> verseData = {
      'Genèse': {1: 31, 2: 25, 3: 24, 4: 26, 5: 32},
      'Exode': {1: 22, 2: 25, 3: 22, 4: 31, 5: 23},
      'Matthieu': {1: 25, 2: 23, 3: 17, 4: 25, 5: 48},
      'Marc': {1: 45, 2: 28, 3: 35, 4: 41, 5: 43},
      'Luc': {1: 80, 2: 52, 3: 38, 4: 44, 5: 39},
      'Jean': {1: 51, 2: 25, 3: 36, 4: 54, 5: 47},
      // Plus de livres peuvent être ajoutés ici
    };

    final bookData = verseData[bookName];
    if (bookData != null && bookData.containsKey(chapter)) {
      return bookData[chapter]!;
    }

    // Estimation par défaut si on n'a pas les données exactes
    return 30; // Moyenne approximative
  }
}
