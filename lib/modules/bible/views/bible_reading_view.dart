import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../theme.dart';
import '../models/bible_book.dart';
import '../models/bible_verse.dart';
import '../services/bible_service.dart';
import '../widgets/bible_search_page.dart';
import '../widgets/book_chapter_selector.dart';
import '../widgets/verse_actions_dialog.dart';
import '../widgets/reading_settings_dialog.dart';

class BibleReadingView extends StatefulWidget {
  final bool isAdminMode;
  
  const BibleReadingView({
    Key? key,
    this.isAdminMode = false,
  }) : super(key: key);

  @override
  State<BibleReadingView> createState() => _BibleReadingViewState();
}

class _BibleReadingViewState extends State<BibleReadingView> {
  final BibleService _bibleService = BibleService();
  final ScrollController _readingScrollController = ScrollController();
  
  // État de lecture
  String? _selectedBook;
  int? _selectedChapter;
  List<BibleBook> _books = [];
  bool _isLoading = true;
  
  // Paramètres de lecture
  double _fontSize = 16.0;
  bool _isDarkMode = false;
  double _lineHeight = 1.5;
  String _fontFamily = '';
  bool _showVerseNumbers = true;
  bool _versePerLine = false;
  double _paragraphSpacing = 16.0;
  bool _showNavigationButtons = true;
  
  // Gestion des versets
  Map<String, Color> _highlights = {};
  Set<String> _favorites = {};
  Map<String, String> _notes = {};
  Set<String> _selectedVerses = {};
  bool _isMultiSelectMode = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadPreferences();
    // Initialiser le ScrollController pour l'auto-masquage des boutons
    _readingScrollController.addListener(_onScrollChanged);
  }

  @override
  void dispose() {
    _readingScrollController.dispose();
    super.dispose();
  }

  // Méthode pour gérer l'auto-masquage des boutons selon le sens du scroll
  void _onScrollChanged() {
    if (_readingScrollController.position.userScrollDirection == ScrollDirection.reverse) {
      // L'utilisateur scroll vers le bas - masquer les boutons
      if (_showNavigationButtons) {
        setState(() {
          _showNavigationButtons = false;
        });
      }
    } else if (_readingScrollController.position.userScrollDirection == ScrollDirection.forward) {
      // L'utilisateur scroll vers le haut - afficher les boutons
      if (!_showNavigationButtons) {
        setState(() {
          _showNavigationButtons = true;
        });
      }
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final books = await _bibleService.getBooks();
      setState(() {
        _books = books;
        _isLoading = false;
      });
      
      // Charger la dernière position de lecture
      await _loadLastReadingPosition();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: AppTheme.redStandard,
          ),
        );
      }
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _fontSize = prefs.getDouble('bible_font_size') ?? 16.0;
        _isDarkMode = prefs.getBool('bible_dark_mode') ?? false;
        _lineHeight = prefs.getDouble('bible_line_height') ?? 1.5;
        _fontFamily = prefs.getString('bible_font_family') ?? '';
        _showVerseNumbers = prefs.getBool('bible_show_verse_numbers') ?? true;
        _versePerLine = prefs.getBool('bible_verse_per_line') ?? false;
        _paragraphSpacing = prefs.getDouble('bible_paragraph_spacing') ?? 16.0;
        _showNavigationButtons = prefs.getBool('bible_show_navigation') ?? true;
      });
    }
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('bible_font_size', _fontSize);
    await prefs.setBool('bible_dark_mode', _isDarkMode);
    await prefs.setDouble('bible_line_height', _lineHeight);
    await prefs.setString('bible_font_family', _fontFamily);
    await prefs.setBool('bible_show_verse_numbers', _showVerseNumbers);
    await prefs.setBool('bible_verse_per_line', _versePerLine);
    await prefs.setDouble('bible_paragraph_spacing', _paragraphSpacing);
    await prefs.setBool('bible_show_navigation', _showNavigationButtons);
  }

  Future<void> _loadLastReadingPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final lastBook = prefs.getString('last_book');
    final lastChapter = prefs.getInt('last_chapter');
    
    if (lastBook != null && lastChapter != null && _books.isNotEmpty) {
      final book = _books.firstWhere(
        (b) => b.name == lastBook,
        orElse: () => _books.first,
      );
      
      setState(() {
        _selectedBook = book.name;
        _selectedChapter = lastChapter.clamp(1, book.chapters.length);
      });
    } else if (_books.isNotEmpty) {
      setState(() {
        _selectedBook = _books.first.name;
        _selectedChapter = 1;
      });
    }
  }

  Future<void> _saveLastReadingPosition() async {
    if (_selectedBook != null && _selectedChapter != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_book', _selectedBook!);
      await prefs.setInt('last_chapter', _selectedChapter!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = _isDarkMode 
        ? theme.colorScheme.copyWith(brightness: Brightness.dark)
        : theme.colorScheme;
    
    return Theme(
      data: theme.copyWith(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: colorScheme.surface,
      ),
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              )
            : Column(
                children: [
                  // Contenu principal
                  Expanded(
                    child: _selectedBook == null || _selectedChapter == null
                        ? _buildReadingPlaceholder()
                        : _buildModernReadingTab(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildReadingPlaceholder() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 80,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 24),
          Text(
            'Sélectionnez un livre et un chapitre',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: AppTheme.fontMedium,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _showBookChapterSelector,
            icon: const Icon(Icons.library_books_outlined),
            label: const Text('Choisir un passage'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernReadingTab() {
    if (_selectedBook == null || _selectedChapter == null) {
      return _buildReadingPlaceholder();
    }

    final book = _books.firstWhere((b) => b.name == _selectedBook!);
    
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          // En-tête style YouVersion
          _buildYouVersionHeader(book),
          
          // Contenu de lecture
          Expanded(
            child: Stack(
              children: [
                // Texte biblique continu
                _buildContinuousText(book, _selectedChapter!),
                
                // Boutons de navigation (en bas)
                if (_showNavigationButtons)
                  _buildNavigationButtons(book),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYouVersionHeader(BibleBook book) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Livre et chapitre - cliquable
          Expanded(
            child: GestureDetector(
              onTap: _showBookChapterSelector,
              child: Row(
                children: [
                  Text(
                    book.name,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: AppTheme.fontSemiBold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$_selectedChapter',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: AppTheme.fontSemiBold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Icônes à droite
          Row(
            children: [
              // Icône de recherche
              IconButton(
                onPressed: _openSearch,
                icon: Icon(
                  Icons.search_rounded,
                  color: colorScheme.onSurfaceVariant,
                  size: 24,
                ),
                style: IconButton.styleFrom(
                  foregroundColor: colorScheme.onSurfaceVariant,
                ),
              ),
              
              // Menu avec 3 points
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: colorScheme.onSurfaceVariant,
                  size: 24,
                ),
                onSelected: _handleHeaderMenuAction,
                style: IconButton.styleFrom(
                  foregroundColor: colorScheme.onSurfaceVariant,
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'bookmark',
                    child: Row(
                      children: [
                        Icon(
                          Icons.bookmark_add_outlined,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Marquer ce chapitre',
                          style: GoogleFonts.inter(
                            color: colorScheme.onSurface,
                            fontWeight: AppTheme.fontMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(
                          Icons.share_outlined,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Partager',
                          style: GoogleFonts.inter(
                            color: colorScheme.onSurface,
                            fontWeight: AppTheme.fontMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'font_size',
                    child: Row(
                      children: [
                        Icon(
                          Icons.text_fields_outlined,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Taille du texte',
                          style: TextStyle(
                            color: _isDarkMode ? AppTheme.white100 : AppTheme.black100.withOpacity(0.87),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(
                          Icons.settings,
                          size: 20,
                          color: (_isDarkMode ? AppTheme.white100 : AppTheme.textTertiaryColor).withOpacity(0.8),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Paramètres',
                          style: TextStyle(
                            color: _isDarkMode ? AppTheme.white100 : AppTheme.black100.withOpacity(0.87),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContinuousText(BibleBook book, int chapter) {
    final chapterIndex = chapter - 1;
    if (chapterIndex < 0 || chapterIndex >= book.chapters.length) {
      return Center(
        child: Text(
          'Chapitre non trouvé',
          style: GoogleFonts.crimsonText(
            fontSize: 18,
            color: (_isDarkMode ? AppTheme.white100 : AppTheme.textTertiaryColor).withOpacity(0.8),
            fontWeight: AppTheme.fontMedium,
          ),
        ),
      );
    }

    final verses = book.chapters[chapterIndex];
    
    return SingleChildScrollView(
      controller: _readingScrollController,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
      child: Container(
        decoration: BoxDecoration(
          color: _isDarkMode ? const Color(0xFF1E1E1E) : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: AppTheme.black100.withOpacity(_isDarkMode ? 0.2 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête du chapitre avec style amélioré
            _buildChapterHeader(book, chapter),
            
            // Contenu des versets
            ..._buildVerseContent(verses, book, chapter),
          ],
        ),
      ),
    );
  }

  Widget _buildChapterHeader(BibleBook book, int chapter) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            book.name.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: AppTheme.fontSemiBold,
              color: colorScheme.primary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Chapitre $chapter',
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: AppTheme.fontBold,
              color: colorScheme.onSurface,
              height: 1.2,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 12),
            height: 3,
            width: 60,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildVerseContent(List<String> verses, BibleBook book, int chapter) {
    if (_versePerLine) {
      return verses.asMap().entries.map((entry) {
        final verseNumber = entry.key + 1;
        final verseText = entry.value;
        final verseKey = '${book.name}_${chapter}_$verseNumber';
        
        return _buildVerseCard(verseKey, verseNumber, verseText, book.name, chapter);
      }).toList();
    } else {
      return [_buildContinuousTextContent(verses, book, chapter)];
    }
  }

  Widget _buildVerseCard(String verseKey, int verseNumber, String verseText, String bookName, int chapter) {
    final colorScheme = Theme.of(context).colorScheme;
    final isHighlighted = _highlights.containsKey(verseKey);
    final isFavorite = _favorites.contains(verseKey);
    final hasNote = _notes.containsKey(verseKey) && _notes[verseKey]!.isNotEmpty;
    final isSelected = _selectedVerses.contains(verseKey);
    
    return Container(
      margin: EdgeInsets.only(bottom: _paragraphSpacing + 8),
      child: GestureDetector(
        onTap: () => _handleVerseTap(verseKey, verseNumber, verseText, bookName, chapter),
        onLongPress: () => _handleVerseLongPress(verseKey, verseNumber, verseText, bookName, chapter),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                : isHighlighted
                    ? _getHighlightColor(verseKey).withValues(alpha: 0.1)
                    : isFavorite
                        ? colorScheme.tertiaryContainer.withValues(alpha: 0.3)
                        : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary.withValues(alpha: 0.5)
                  : isHighlighted
                      ? _getHighlightColor(verseKey).withValues(alpha: 0.5)
                      : isFavorite
                          ? colorScheme.tertiary.withValues(alpha: 0.5)
                          : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.inter(
                fontSize: _fontSize + 4,
                color: colorScheme.onSurface,
                height: _lineHeight + 0.3,
                fontWeight: AppTheme.fontRegular,
              ),
              children: [
                // Numéro du verset
                if (_showVerseNumbers)
                  TextSpan(
                    text: '$verseNumber ',
                    style: GoogleFonts.inter(
                      fontSize: _fontSize,
                      fontWeight: AppTheme.fontBold,
                      color: AppTheme.primaryColor,
                      height: _lineHeight,
                    ),
                  ),
                // Texte du verset
                TextSpan(
                  text: verseText,
                  style: GoogleFonts.crimsonText(
                    fontWeight: isFavorite ? AppTheme.fontSemiBold : AppTheme.fontRegular,
                    color: isFavorite 
                        ? (_isDarkMode ? AppTheme.white100 : AppTheme.black100)
                        : (_isDarkMode ? AppTheme.white100.withOpacity(0.87) : AppTheme.black100.withOpacity(0.87)),
                  ),
                ),
                // Icône de note
                if (hasNote)
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: GestureDetector(
                      onTap: () => _showNotePopup(verseKey, _notes[verseKey]!),
                      child: Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          border: Border.all(
                            color: const Color(0xFF10B981).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.sticky_note_2_rounded,
                          size: 16,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContinuousTextContent(List<String> verses, BibleBook book, int chapter) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onLongPress: () {
          if (!_isMultiSelectMode && verses.isNotEmpty) {
            final firstVerseKey = '${book.name}_${chapter}_1';
            _handleVerseLongPress(firstVerseKey, 1, verses[0], book.name, chapter);
          }
        },
        child: RichText(
          textAlign: TextAlign.justify,
          text: TextSpan(
            style: GoogleFonts.crimsonText(
              fontSize: _fontSize + 6,
              color: _isDarkMode ? AppTheme.white100.withOpacity(0.87) : AppTheme.black100.withOpacity(0.87),
              height: _lineHeight + 0.4,
              fontWeight: AppTheme.fontRegular,
              letterSpacing: 0.3,
            ),
            children: verses.asMap().entries.map((entry) {
              final verseNumber = entry.key + 1;
              final verseText = entry.value;
              final verseKey = '${book.name}_${chapter}_$verseNumber';
              final isHighlighted = _highlights.containsKey(verseKey);
              final isFavorite = _favorites.contains(verseKey);
              
              return TextSpan(
                children: [
                  // Numéro du verset avec style amélioré
                  if (_showVerseNumbers)
                    TextSpan(
                      text: '$verseNumber ',
                      style: GoogleFonts.inter(
                        fontSize: _fontSize + 1,
                        fontWeight: AppTheme.fontBold,
                        color: AppTheme.primaryColor,
                        height: _lineHeight,
                      ),
                    ),
                  // Texte du verset avec effets visuels améliorés
                  TextSpan(
                    text: '$verseText ',
                    style: TextStyle(
                      backgroundColor: isHighlighted 
                          ? _getHighlightColor(verseKey).withOpacity(0.2)
                          : null,
                      decoration: _selectedVerses.contains(verseKey)
                          ? TextDecoration.underline
                          : null,
                      decorationColor: _selectedVerses.contains(verseKey)
                          ? AppTheme.primaryColor
                          : null,
                      decorationThickness: _selectedVerses.contains(verseKey)
                          ? 3.0
                          : null,
                      fontWeight: isFavorite 
                          ? AppTheme.fontSemiBold 
                          : AppTheme.fontRegular,
                      color: isFavorite 
                          ? (_isDarkMode ? AppTheme.white100 : AppTheme.black100)
                          : (_isDarkMode ? AppTheme.white100.withOpacity(0.87) : AppTheme.black100.withOpacity(0.87)),
                      shadows: isFavorite ? [
                        Shadow(
                          color: Colors.amber.withOpacity(0.3),
                          blurRadius: 2,
                        ),
                      ] : null,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        if (_isMultiSelectMode) {
                          _handleVerseTap(verseKey, verseNumber, verseText, book.name, chapter);
                        } else {
                          _showVerseActions(BibleVerse(
                            book: book.name,
                            chapter: chapter,
                            verse: verseNumber,
                            text: verseText,
                          ));
                        }
                      },
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(BibleBook book) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: AnimatedOpacity(
        opacity: _showNavigationButtons ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Bouton chapitre précédent
            if (_selectedChapter! > 1 || _canGoPreviousBook())
              FloatingActionButton(
                heroTag: "previous",
                onPressed: _goToPreviousChapter,
                backgroundColor: colorScheme.secondaryContainer,
                foregroundColor: colorScheme.onSecondaryContainer,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.chevron_left_rounded,
                  size: 28,
                ),
              )
            else
              const SizedBox(width: 56),
            
            // Bouton chapitre suivant  
            if (_selectedChapter! < book.chapters.length || _canGoNextBook())
              FloatingActionButton(
                heroTag: "next",
                onPressed: _goToNextChapter,
                backgroundColor: colorScheme.secondaryContainer,
                foregroundColor: colorScheme.onSecondaryContainer,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  size: 28,
                ),
              )
            else
              const SizedBox(width: 56),
          ],
        ),
      ),
    );
  }

  void _handleHeaderMenuAction(String action) {
    switch (action) {
      case 'bookmark':
        _bookmarkCurrentChapter();
        break;
      case 'share':
        _shareChapter();
        break;
      case 'font_size':
        _showFontSizeDialog();
        break;
      case 'settings':
        _showReadingSettings();
        break;
    }
  }

  Future<void> _openSearch() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BibleSearchPage(bibleService: _bibleService),
      ),
    );
    
    if (result != null && result is Map<String, dynamic>) {
      HapticFeedback.lightImpact();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: AppTheme.white100,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Navigation vers ${result['book']} ${result['chapter']}:${result['verse']}',
                style: GoogleFonts.inter(fontWeight: AppTheme.fontMedium),
              ),
            ],
          ),
          backgroundColor: AppTheme.greenStandard,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      
      setState(() {
        _selectedBook = result['book'];
        _selectedChapter = result['chapter'];
      });
      
      await _saveLastReadingPosition();
    }
  }

  void _showBookChapterSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookChapterSelector(
        books: _books,
        selectedBook: _selectedBook,
        selectedChapter: _selectedChapter,
        onBookChapterSelected: (book, chapter) {
          setState(() {
            _selectedBook = book;
            _selectedChapter = chapter;
          });
          _saveLastReadingPosition();
        },
      ),
    );
  }

  void _showReadingSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReadingSettingsDialog(
        fontSize: _fontSize,
        isDarkMode: _isDarkMode,
        lineHeight: _lineHeight,
        fontFamily: _fontFamily,
        showVerseNumbers: _showVerseNumbers,
        versePerLine: _versePerLine,
        paragraphSpacing: _paragraphSpacing,
        showNavigationButtons: _showNavigationButtons,
        onSettingsChanged: (settings) {
          setState(() {
            _fontSize = settings['fontSize'];
            _isDarkMode = settings['isDarkMode'];
            _lineHeight = settings['lineHeight'];
            _fontFamily = settings['fontFamily'];
            _showVerseNumbers = settings['showVerseNumbers'];
            _versePerLine = settings['versePerLine'];
            _paragraphSpacing = settings['paragraphSpacing'];
            _showNavigationButtons = settings['showNavigationButtons'];
          });
          _savePreferences();
        },
      ),
    );
  }

  void _showFontSizeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Taille du texte',
          style: GoogleFonts.inter(fontWeight: AppTheme.fontBold),
        ),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${_fontSize.toStringAsFixed(0)}pt'),
              Slider(
                value: _fontSize,
                min: 12,
                max: 28,
                divisions: 8,
                onChanged: (value) {
                  setState(() {
                    _fontSize = value;
                  });
                  this.setState(() {});
                  _savePreferences();
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _handleVerseTap(String verseKey, int verseNumber, String verseText, String bookName, int chapter) {
    if (_isMultiSelectMode) {
      setState(() {
        if (_selectedVerses.contains(verseKey)) {
          _selectedVerses.remove(verseKey);
        } else {
          _selectedVerses.add(verseKey);
        }
        
        if (_selectedVerses.isEmpty) {
          _isMultiSelectMode = false;
        }
      });
    } else {
      _showVerseActions(BibleVerse(
        book: bookName,
        chapter: chapter,
        verse: verseNumber,
        text: verseText,
      ));
    }
  }

  void _handleVerseLongPress(String verseKey, int verseNumber, String verseText, String bookName, int chapter) {
    HapticFeedback.mediumImpact();
    
    setState(() {
      _isMultiSelectMode = true;
      _selectedVerses.add(verseKey);
    });
  }

  void _showVerseActions(BibleVerse verse) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => VerseActionsDialog(
        verse: verse,
        onHighlight: (color) => _highlightVerse(verse, color),
        onFavorite: () => _toggleFavorite(verse),
        onNote: (note) => _addNote(verse, note),
        onShare: () => _shareVerse(verse),
      ),
    );
  }

  // Méthodes utilitaires
  Color _getHighlightColor(String verseKey) {
    return _highlights[verseKey] ?? Colors.yellow;
  }

  bool _canGoPreviousBook() {
    if (_selectedBook == null) return false;
    final currentIndex = _books.indexWhere((b) => b.name == _selectedBook);
    return currentIndex > 0;
  }

  bool _canGoNextBook() {
    if (_selectedBook == null) return false;
    final currentIndex = _books.indexWhere((b) => b.name == _selectedBook);
    return currentIndex < _books.length - 1;
  }

  void _goToPreviousChapter() {
    if (_selectedChapter! > 1) {
      setState(() {
        _selectedChapter = _selectedChapter! - 1;
      });
    } else if (_canGoPreviousBook()) {
      final currentIndex = _books.indexWhere((b) => b.name == _selectedBook);
      final previousBook = _books[currentIndex - 1];
      setState(() {
        _selectedBook = previousBook.name;
        _selectedChapter = previousBook.chapters.length;
      });
    }
    _saveLastReadingPosition();
  }

  void _goToNextChapter() {
    final book = _books.firstWhere((b) => b.name == _selectedBook!);
    
    if (_selectedChapter! < book.chapters.length) {
      setState(() {
        _selectedChapter = _selectedChapter! + 1;
      });
    } else if (_canGoNextBook()) {
      final currentIndex = _books.indexWhere((b) => b.name == _selectedBook);
      final nextBook = _books[currentIndex + 1];
      setState(() {
        _selectedBook = nextBook.name;
        _selectedChapter = 1;
      });
    }
    _saveLastReadingPosition();
  }

  // Méthodes d'action sur les versets
  void _highlightVerse(BibleVerse verse, Color color) {
    final verseKey = '${verse.book}_${verse.chapter}_${verse.verse}';
    setState(() {
      _highlights[verseKey] = color;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Verset ${verse.book} ${verse.chapter}:${verse.verse} surligné'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _toggleFavorite(BibleVerse verse) {
    final verseKey = '${verse.book}_${verse.chapter}_${verse.verse}';
    setState(() {
      if (_favorites.contains(verseKey)) {
        _favorites.remove(verseKey);
      } else {
        _favorites.add(verseKey);
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _favorites.contains(verseKey) 
              ? 'Verset ajouté aux favoris'
              : 'Verset retiré des favoris',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _addNote(BibleVerse verse, String note) {
    final verseKey = '${verse.book}_${verse.chapter}_${verse.verse}';
    setState(() {
      _notes[verseKey] = note;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Note ajoutée'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _shareVerse(BibleVerse verse) {
    // Implémentation du partage
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Partage de ${verse.book} ${verse.chapter}:${verse.verse}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _shareChapter() {
    if (_selectedBook != null && _selectedChapter != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Partage de $_selectedBook $_selectedChapter'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _bookmarkCurrentChapter() {
    if (_selectedBook != null && _selectedChapter != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Signet ajouté: $_selectedBook $_selectedChapter'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _showNotePopup(String verseKey, String note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Note'),
        content: Text(note),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
