import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../theme.dart';
import '../models/bible_book.dart';
import '../models/bible_verse.dart';
import '../services/bible_service.dart';
import '../widgets/bible_search_page.dart';
import '../widgets/book_chapter_selector.dart';
import '../widgets/verse_actions_dialog.dart';
import '../widgets/reading_settings_dialog.dart';

// Classe pour les résultats de recherche
class SearchResult {
  final String bookName;
  final int chapter;
  final int verse;
  final String text;
  final String verseKey;
  final int startIndex;
  final int endIndex;

  SearchResult({
    required this.bookName,
    required this.chapter,
    required this.verse,
    required this.text,
    required this.verseKey,
    required this.startIndex,
    required this.endIndex,
  });
}

class BibleReadingView extends StatefulWidget {
  final bool isAdminMode;
  
  const BibleReadingView({
    Key? key,
    this.isAdminMode = false,
  }) : super(key: key);

  @override
  State<BibleReadingView> createState() => _BibleReadingViewState();
}

class _BibleReadingViewState extends State<BibleReadingView> 
    with TickerProviderStateMixin {
  final BibleService _bibleService = BibleService();
  final ScrollController _readingScrollController = ScrollController();
  
  // Animation Controllers pour MD3/HIG
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late AnimationController _navigationAnimationController;
  
  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _navigationAnimation;
  
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
  
  // Gestion de la recherche
  List<SearchResult> _searchResults = [];
  int _currentSearchIndex = -1;
  String _currentSearchTerm = '';
  bool _isSearchActive = false;
  List<String> _searchHistory = [];
  final ScrollController _searchScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadData();
    _loadPreferences();
    _loadSearchHistory();
    _readingScrollController.addListener(_onScrollChanged);
  }

  void _setupAnimations() {
    // Animation pour les fade-in/fade-out (MD3)
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Animation pour les slides (HIG)
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Animation pour la navigation (boutons flottants)
    _navigationAnimationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeOutCubic, // MD3 recommended curve
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _navigationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _navigationAnimationController,
      curve: Curves.easeInOutCubic,
    ));

    // Démarrer les animations
    _fadeAnimationController.forward();
    _slideAnimationController.forward();
    _navigationAnimationController.forward();
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    _navigationAnimationController.dispose();
    _readingScrollController.dispose();
    _searchScrollController.dispose();
    super.dispose();
  }

  // Méthode améliorée pour l'auto-masquage avec animations fluides
  void _onScrollChanged() {
    if (_readingScrollController.position.userScrollDirection == ScrollDirection.reverse) {
      // L'utilisateur scroll vers le bas - masquer les boutons avec animation
      if (_showNavigationButtons) {
        _navigationAnimationController.reverse();
        setState(() {
          _showNavigationButtons = false;
        });
      }
    } else if (_readingScrollController.position.userScrollDirection == ScrollDirection.forward) {
      // L'utilisateur scroll vers le haut - afficher les boutons avec animation
      if (!_showNavigationButtons) {
        setState(() {
          _showNavigationButtons = true;
        });
        _navigationAnimationController.forward();
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Scaffold(
              backgroundColor: colorScheme.surface,
              body: _isLoading
                  ? _buildModernLoadingState(colorScheme)
                  : _selectedBook == null || _selectedChapter == null
                      ? _buildModernPlaceholder(colorScheme, textTheme)
                      : _buildProfessionalReadingInterface(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfessionalReadingInterface() {
    if (_selectedBook == null || _selectedChapter == null) {
      return _buildModernPlaceholder(
        Theme.of(context).colorScheme, 
        Theme.of(context).textTheme
      );
    }

    final book = _books.firstWhere((b) => b.name == _selectedBook!);
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          // En-tête moderne MD3/HIG
          _buildProfessionalHeader(book, colorScheme),
          
          // Contenu de lecture avec animations
          Expanded(
            child: Stack(
              children: [
                // Texte biblique avec animations fluides
                _buildAnimatedReadingContent(book, _selectedChapter!),
                
                // Boutons de navigation flottants MD3
                AnimatedBuilder(
                  animation: _navigationAnimation,
                  builder: (context, child) {
                    return _buildModernNavigationButtons(book);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernLoadingState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.space20),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              strokeWidth: 3,
              strokeCap: StrokeCap.round, // MD3 style
            ),
          ),
          const SizedBox(height: AppTheme.space20),
          Text(
            'Chargement de la Bible...',
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize16,
              fontWeight: AppTheme.fontMedium,
              color: colorScheme.onSurfaceVariant,
              letterSpacing: AppTheme.isApplePlatform ? -0.24 : 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernPlaceholder(ColorScheme colorScheme, TextTheme textTheme) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppTheme.spaceLarge),
        padding: const EdgeInsets.all(AppTheme.spaceXLarge),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.12),
            width: AppTheme.isApplePlatform ? 0.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              ),
              child: Icon(
                Icons.menu_book_rounded,
                size: 48,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppTheme.space20),
            Text(
              'Bible de Lecture',
              style: textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                letterSpacing: AppTheme.isApplePlatform ? -0.25 : 0,
              ),
            ),
            const SizedBox(height: AppTheme.space12),
            Text(
              'Sélectionnez un livre et un chapitre pour commencer votre lecture',
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _showBookChapterSelector,
              icon: const Icon(Icons.library_books_outlined, size: 20),
              label: const Text('Choisir un passage'),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space20,
                  vertical: AppTheme.space14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppTheme.isApplePlatform ? AppTheme.radiusMedium : AppTheme.radiusLarge
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalHeader(BibleBook book, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withOpacity(0.05),
            colorScheme.surface,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Livre et chapitre - style moderne
            Expanded(
              child: GestureDetector(
                onTap: _showBookChapterSelector,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        color: colorScheme.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${book.displayName} ${_selectedChapter}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Actions MD3
            _buildModernHeaderActions(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeaderActions(ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Recherche
        IconButton.filledTonal(
          onPressed: _showSearchDialog,
          icon: const Icon(Icons.search),
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Menu options
        PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
          onSelected: _handleHeaderMenuAction,
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
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
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
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
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
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
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'reading_mode',
              child: Row(
                children: [
                  Icon(
                    Icons.auto_stories_outlined,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Mode de lecture',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
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
                    Icons.settings_outlined,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Paramètres',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnimatedReadingContent(BibleBook book, int chapter) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.05),
            end: Offset.zero,
          ).animate(_slideAnimationController),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: _buildScrollableContent(book, chapter),
          ),
        );
      },
    );
  }

  Widget _buildScrollableContent(BibleBook book, int chapter) {
    return CustomScrollView(
      controller: _readingScrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: _buildContinuousTextContent(
              book.chapters[chapter - 1],
              book,
              chapter,
            ),
          ),
        ),
        
        // Espace pour les boutons de navigation
        const SliverToBoxAdapter(
          child: SizedBox(height: 80),
        ),
      ],
    );
  }

  Widget _buildModernNavigationButtons(BibleBook book) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Transform.translate(
        offset: Offset(0, _navigationAnimation.value * 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacity(0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colorScheme.outlineVariant,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Chapitre précédent
              Expanded(
                child: _buildNavButton(
                  icon: Icons.chevron_left_rounded,
                  label: _getPreviousChapter(book),
                  onTap: _canGoPrevious(book) ? _goToPreviousChapter : null,
                  colorScheme: colorScheme,
                ),
              ),
              
              Container(
                width: 1,
                height: 32,
                color: colorScheme.outline.withOpacity(0.3),
              ),
              
              // Chapitre suivant
              Expanded(
                child: _buildNavButton(
                  icon: Icons.chevron_right_rounded,
                  label: _getNextChapter(book),
                  onTap: _canGoNext(book) ? _goToNextChapter : null,
                  colorScheme: colorScheme,
                  isNext: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required ColorScheme colorScheme,
    bool isNext = false,
  }) {
    final isEnabled = onTap != null;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isNext) ...[
                Icon(
                  icon,
                  size: 20,
                  color: isEnabled 
                    ? colorScheme.primary 
                    : colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
                const SizedBox(width: 4),
              ],
              
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isEnabled 
                      ? colorScheme.onSurfaceVariant 
                      : colorScheme.onSurfaceVariant.withOpacity(0.5),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: isNext ? TextAlign.end : TextAlign.start,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              if (isNext) ...[
                const SizedBox(width: 4),
                Icon(
                  icon,
                  size: 20,
                  color: isEnabled 
                    ? colorScheme.primary 
                    : colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
              ],
            ],
          ),
        ),
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
                      fontSize: AppTheme.fontSize18,
                      fontWeight: AppTheme.fontSemiBold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceSmall),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$_selectedChapter',
                      style: GoogleFonts.inter(
                        fontSize: AppTheme.fontSize16,
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
                        const SizedBox(width: AppTheme.space12),
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
                        const SizedBox(width: AppTheme.space12),
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
                        const SizedBox(width: AppTheme.space12),
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
                        const SizedBox(width: AppTheme.space12),
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
            fontSize: AppTheme.fontSize18,
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
          color: _isDarkMode ? AppTheme.darkModeBackground : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: AppTheme.black100.withOpacity(_isDarkMode ? 0.2 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppTheme.spaceLarge),
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
              fontSize: AppTheme.fontSize14,
              fontWeight: AppTheme.fontSemiBold,
              color: colorScheme.primary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Text(
            'Chapitre $chapter',
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize32,
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
              borderRadius: BorderRadius.circular(AppTheme.radius2),
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
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
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
                        padding: const EdgeInsets.all(AppTheme.space6),
                        decoration: BoxDecoration(
                          color: AppTheme.successColorBright.withAlpha((255 * AppTheme.opacity15).round()),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          border: Border.all(
                            color: AppTheme.successColorBright.withAlpha((255 * AppTheme.opacityLow).round()),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.sticky_note_2_rounded,
                          size: 16,
                          color: AppTheme.successColorBright,
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
      padding: const EdgeInsets.all(AppTheme.spaceSmall),
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
                          color: AppTheme.warningColor.withOpacity(0.3),
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
                  borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
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
                  borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
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
      case 'reading_mode':
        _showReadingModeDialog();
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
              const SizedBox(width: AppTheme.spaceSmall),
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

  void _showReadingModeDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: colorScheme.outline.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_stories_rounded,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Mode de lecture',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Affichage section
                      Text(
                        'Affichage des versets',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Mode verset par ligne
                      Card(
                        margin: EdgeInsets.zero,
                        child: SwitchListTile(
                          value: _versePerLine,
                          onChanged: (value) {
                            setState(() {
                              _versePerLine = value;
                            });
                            this.setState(() {});
                            _savePreferences();
                          },
                          title: const Text('Un verset par ligne'),
                          subtitle: const Text('Affiche chaque verset sur une ligne séparée'),
                          secondary: Icon(
                            Icons.format_list_numbered,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Numéros de versets
                      Card(
                        margin: EdgeInsets.zero,
                        child: SwitchListTile(
                          value: _showVerseNumbers,
                          onChanged: (value) {
                            setState(() {
                              _showVerseNumbers = value;
                            });
                            this.setState(() {});
                            _savePreferences();
                          },
                          title: const Text('Numéros de versets'),
                          subtitle: const Text('Affiche les numéros des versets'),
                          secondary: Icon(
                            Icons.format_list_numbered_outlined,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Navigation section
                      Text(
                        'Navigation',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Boutons de navigation
                      Card(
                        margin: EdgeInsets.zero,
                        child: SwitchListTile(
                          value: _showNavigationButtons,
                          onChanged: (value) {
                            setState(() {
                              _showNavigationButtons = value;
                            });
                            this.setState(() {});
                            _savePreferences();
                          },
                          title: const Text('Boutons de navigation'),
                          subtitle: const Text('Affiche les boutons précédent/suivant'),
                          secondary: Icon(
                            Icons.navigate_next,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Typographie section
                      Text(
                        'Typographie',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Taille de police
                      Card(
                        margin: EdgeInsets.zero,
                        child: ListTile(
                          leading: Icon(
                            Icons.text_fields,
                            color: colorScheme.primary,
                          ),
                          title: const Text('Taille du texte'),
                          subtitle: Text('${_fontSize.toStringAsFixed(0)}pt'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: _fontSize > 12 ? () {
                                  setState(() {
                                    _fontSize = (_fontSize - 1).clamp(12, 28);
                                  });
                                  this.setState(() {});
                                  _savePreferences();
                                } : null,
                                icon: const Icon(Icons.remove),
                              ),
                              IconButton(
                                onPressed: _fontSize < 28 ? () {
                                  setState(() {
                                    _fontSize = (_fontSize + 1).clamp(12, 28);
                                  });
                                  this.setState(() {});
                                  _savePreferences();
                                } : null,
                                icon: const Icon(Icons.add),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Interligne
                      Card(
                        margin: EdgeInsets.zero,
                        child: ListTile(
                          leading: Icon(
                            Icons.format_line_spacing,
                            color: colorScheme.primary,
                          ),
                          title: const Text('Interligne'),
                          subtitle: Text('${_lineHeight.toStringAsFixed(1)}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: _lineHeight > 1.0 ? () {
                                  setState(() {
                                    _lineHeight = (_lineHeight - 0.1).clamp(1.0, 2.0);
                                  });
                                  this.setState(() {});
                                  _savePreferences();
                                } : null,
                                icon: const Icon(Icons.remove),
                              ),
                              IconButton(
                                onPressed: _lineHeight < 2.0 ? () {
                                  setState(() {
                                    _lineHeight = (_lineHeight + 0.1).clamp(1.0, 2.0);
                                  });
                                  this.setState(() {});
                                  _savePreferences();
                                } : null,
                                icon: const Icon(Icons.add),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Actions rapides
                      Text(
                        'Actions rapides',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _showBookmarks();
                              },
                              icon: const Icon(Icons.bookmark),
                              label: const Text('Signets'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _showReadingSettings();
                              },
                              icon: const Icon(Icons.settings),
                              label: const Text('Paramètres'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Footer
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Terminé'),
                  ),
                ),
              ),
            ],
          ),
        ),
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

  // === MÉTHODES DE RECHERCHE ===
  
  void _showSearchDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.outline.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Rechercher dans la Bible',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            
            // Champ de recherche
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Rechercher des mots, expressions...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _currentSearchTerm.isNotEmpty 
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: _clearSearch,
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: _performSearch,
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    _addToSearchHistory(value);
                  }
                },
              ),
            ),
            
            // Options de recherche
            if (_currentSearchTerm.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSearchOptions(),
            ],
            
            // Résultats de recherche
            Expanded(
              child: _buildSearchResults(),
            ),
            
            // Navigation des résultats
            if (_searchResults.isNotEmpty)
              _buildSearchNavigation(),
          ],
        ),
      ),
    );
  }

  void _performSearch(String query) {
    setState(() {
      _currentSearchTerm = query;
      _currentSearchIndex = -1;
      _searchResults.clear();
    });

    if (query.trim().isEmpty) {
      setState(() {
        _isSearchActive = false;
      });
      return;
    }

    setState(() {
      _isSearchActive = true;
    });

    // Recherche dans les versets du chapitre actuel
    _searchInCurrentChapter(query);
  }

  void _searchInCurrentChapter(String query) {
    if (_selectedBook == null || _selectedChapter == null) return;

    final searchTerm = query.toLowerCase().trim();
    final results = <SearchResult>[];

    // Récupérer les versets du chapitre actuel
    final book = _books.firstWhere((b) => b.name == _selectedBook!);
    final verses = book.chapters[_selectedChapter! - 1];
    
    for (int i = 0; i < verses.length; i++) {
      final verse = verses[i];
      final verseText = verse.toLowerCase();
      final verseKey = '${book.name}_${_selectedChapter}_${i + 1}';
      
      // Recherche simple par occurrence
      int startIndex = 0;
      while (true) {
        final index = verseText.indexOf(searchTerm, startIndex);
        if (index == -1) break;
        
        results.add(SearchResult(
          bookName: book.name,
          chapter: _selectedChapter!,
          verse: i + 1,
          text: verse,
          verseKey: verseKey,
          startIndex: index,
          endIndex: index + searchTerm.length,
        ));
        
        startIndex = index + 1;
      }
    }

    setState(() {
      _searchResults = results;
      if (results.isNotEmpty) {
        _currentSearchIndex = 0;
      }
    });
  }

  Widget _buildSearchOptions() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(
            '${_searchResults.length} résultat${_searchResults.length > 1 ? 's' : ''}',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          if (_searchResults.isNotEmpty)
            Text(
              '${_currentSearchIndex + 1}/${_searchResults.length}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_currentSearchTerm.isEmpty) {
      return _buildSearchHistory();
    }

    if (_searchResults.isEmpty && _isSearchActive) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun résultat trouvé',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez avec d\'autres mots-clés',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _searchScrollController,
      padding: const EdgeInsets.all(20),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        final isCurrentResult = index == _currentSearchIndex;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isCurrentResult 
                ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCurrentResult 
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline.withOpacity(0.2),
              width: isCurrentResult ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${result.bookName} ${result.chapter}:${result.verse}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (isCurrentResult)
                    Icon(
                      Icons.my_location,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              RichText(
                text: _buildHighlightedText(result),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchHistory() {
    if (_searchHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Historique de recherche vide',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vos recherches précédentes apparaîtront ici',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _searchHistory.length,
      itemBuilder: (context, index) {
        final searchTerm = _searchHistory[_searchHistory.length - 1 - index];
        
        return ListTile(
          leading: const Icon(Icons.history),
          title: Text(searchTerm),
          trailing: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _removeFromSearchHistory(searchTerm),
          ),
          onTap: () => _performSearch(searchTerm),
        );
      },
    );
  }

  TextSpan _buildHighlightedText(SearchResult result) {
    final text = result.text;
    final searchTerm = _currentSearchTerm.toLowerCase();
    final lowerText = text.toLowerCase();
    
    final spans = <TextSpan>[];
    int lastIndex = 0;
    
    int searchIndex = 0;
    while (searchIndex < lowerText.length) {
      final index = lowerText.indexOf(searchTerm, searchIndex);
      if (index == -1) break;
      
      // Ajouter le texte avant la correspondance
      if (index > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, index),
          style: GoogleFonts.crimsonText(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ));
      }
      
      // Ajouter le texte en surbrillance
      spans.add(TextSpan(
        text: text.substring(index, index + searchTerm.length),
        style: GoogleFonts.crimsonText(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ));
      
      lastIndex = index + searchTerm.length;
      searchIndex = lastIndex;
    }
    
    // Ajouter le reste du texte
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: GoogleFonts.crimsonText(
          fontSize: 16,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ));
    }
    
    return TextSpan(children: spans);
  }

  Widget _buildSearchNavigation() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _currentSearchIndex > 0 ? _goToPreviousResult : null,
              icon: const Icon(Icons.keyboard_arrow_up),
              label: const Text('Précédent'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _currentSearchIndex < _searchResults.length - 1 
                  ? _goToNextResult 
                  : null,
              icon: const Icon(Icons.keyboard_arrow_down),
              label: const Text('Suivant'),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              if (_searchResults.isNotEmpty && _currentSearchIndex >= 0) {
                _navigateToSearchResult(_searchResults[_currentSearchIndex]);
              }
            },
            icon: const Icon(Icons.visibility),
            label: const Text('Voir'),
          ),
        ],
      ),
    );
  }

  void _goToPreviousResult() {
    if (_currentSearchIndex > 0) {
      setState(() {
        _currentSearchIndex--;
      });
      _scrollToCurrentResult();
    }
  }

  void _goToNextResult() {
    if (_currentSearchIndex < _searchResults.length - 1) {
      setState(() {
        _currentSearchIndex++;
      });
      _scrollToCurrentResult();
    }
  }

  void _scrollToCurrentResult() {
    if (_currentSearchIndex >= 0 && _currentSearchIndex < _searchResults.length) {
      final itemHeight = 100.0; // Estimation de la hauteur d'un item
      final targetOffset = _currentSearchIndex * itemHeight;
      
      _searchScrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _navigateToSearchResult(SearchResult result) {
    // Ici on pourrait naviguer vers le verset spécifique
    // Pour l'instant, on ferme juste la recherche
    _clearSearch();
  }

  void _clearSearch() {
    setState(() {
      _currentSearchTerm = '';
      _searchResults.clear();
      _currentSearchIndex = -1;
      _isSearchActive = false;
    });
  }

  void _addToSearchHistory(String searchTerm) {
    if (searchTerm.trim().isEmpty) return;
    
    setState(() {
      _searchHistory.remove(searchTerm); // Éviter les doublons
      _searchHistory.add(searchTerm);
      
      // Garder seulement les 10 dernières recherches
      if (_searchHistory.length > 10) {
        _searchHistory.removeAt(0);
      }
    });
    
    _saveSearchHistory();
  }

  void _removeFromSearchHistory(String searchTerm) {
    setState(() {
      _searchHistory.remove(searchTerm);
    });
    _saveSearchHistory();
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('bible_search_history') ?? [];
    setState(() {
      _searchHistory = history;
    });
  }

  Future<void> _saveSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('bible_search_history', _searchHistory);
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

  void _shareChapter() async {
    if (_selectedBook == null || _selectedChapter == null) return;
    
    try {
      final book = _books.firstWhere((b) => b.name == _selectedBook!);
      final chapterIndex = _selectedChapter! - 1;
      
      if (chapterIndex < 0 || chapterIndex >= book.chapters.length) return;
      
      final verses = book.chapters[chapterIndex];
      
      // Construire le texte du chapitre
      final StringBuffer chapterText = StringBuffer();
      chapterText.writeln('${book.displayName} ${_selectedChapter}');
      chapterText.writeln('=' * 40);
      chapterText.writeln();
      
      for (int i = 0; i < verses.length; i++) {
        final verseNumber = i + 1;
        final verseText = verses[i];
        if (_showVerseNumbers) {
          chapterText.writeln('$verseNumber. $verseText');
        } else {
          chapterText.writeln(verseText);
        }
        if (_versePerLine) {
          chapterText.writeln();
        }
      }
      
      chapterText.writeln();
      chapterText.writeln('Partagé depuis Jubilé Tabernacle France');
      
      // Partager via Share Plus
      await Share.share(
        chapterText.toString(),
        subject: '${book.displayName} ${_selectedChapter}',
      );
      
      // Feedback haptique
      HapticFeedback.lightImpact();
      
    } catch (e) {
      // Afficher une erreur si le partage échoue
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Erreur lors du partage'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _bookmarkCurrentChapter() async {
    if (_selectedBook == null || _selectedChapter == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarkKey = 'bookmark_${_selectedBook}_${_selectedChapter}';
      final bookmarksKey = 'bible_bookmarks';
      
      // Récupérer les signets existants
      final List<String> bookmarks = prefs.getStringList(bookmarksKey) ?? [];
      
      final book = _books.firstWhere((b) => b.name == _selectedBook!);
      final bookmarkValue = '${book.displayName} ${_selectedChapter}';
      
      // Vérifier si le signet existe déjà
      final existingBookmark = bookmarks.firstWhere(
        (bookmark) => bookmark.contains('${book.displayName} ${_selectedChapter}'),
        orElse: () => '',
      );
      
      if (existingBookmark.isNotEmpty) {
        // Le signet existe déjà - le supprimer
        bookmarks.remove(existingBookmark);
        await prefs.setStringList(bookmarksKey, bookmarks);
        await prefs.remove(bookmarkKey);
        
        // Feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.bookmark_remove,
                  color: Theme.of(context).colorScheme.onInverseSurface,
                ),
                const SizedBox(width: 8),
                Text('Signet supprimé: $bookmarkValue'),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.inverseSurface,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        // Ajouter le nouveau signet
        final timestamp = DateTime.now().toIso8601String();
        final bookmarkData = '$bookmarkValue|$timestamp';
        bookmarks.insert(0, bookmarkData); // Insérer au début
        
        // Limiter à 20 signets maximum
        if (bookmarks.length > 20) {
          bookmarks.removeRange(20, bookmarks.length);
        }
        
        await prefs.setStringList(bookmarksKey, bookmarks);
        await prefs.setBool(bookmarkKey, true);
        
        // Feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.bookmark_add,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Text('Signet ajouté: $bookmarkValue'),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'Voir',
              onPressed: _showBookmarks,
              textColor: Theme.of(context).colorScheme.primary,
            ),
          ),
        );
      }
      
      // Feedback haptique
      HapticFeedback.lightImpact();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Erreur lors de la gestion du signet'),
          backgroundColor: Theme.of(context).colorScheme.error,
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

  void _showBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> bookmarks = prefs.getStringList('bible_bookmarks') ?? [];
    
    if (bookmarks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun signet trouvé'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.bookmark,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Mes Signets',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${bookmarks.length}/20',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1),
            
            // Bookmarks list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: bookmarks.length,
                itemBuilder: (context, index) {
                  final bookmark = bookmarks[index];
                  final parts = bookmark.split('|');
                  final title = parts[0];
                  final timestamp = parts.length > 1 ? parts[1] : '';
                  
                  DateTime? date;
                  if (timestamp.isNotEmpty) {
                    try {
                      date = DateTime.parse(timestamp);
                    } catch (e) {
                      // Ignore parsing errors
                    }
                  }
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Icon(
                          Icons.bookmark,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      subtitle: date != null 
                        ? Text(
                            'Ajouté le ${date.day}/${date.month}/${date.year}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          )
                        : null,
                      trailing: PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        onSelected: (action) async {
                          if (action == 'delete') {
                            bookmarks.removeAt(index);
                            await prefs.setStringList('bible_bookmarks', bookmarks);
                            Navigator.pop(context);
                            _showBookmarks(); // Refresh
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                const SizedBox(width: 8),
                                const Text('Supprimer'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToBookmark(title);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToBookmark(String bookmarkTitle) {
    try {
      // Parser le titre du signet (ex: "Genèse 1" ou "1 Corinthiens 13")
      final parts = bookmarkTitle.trim().split(' ');
      if (parts.length < 2) return;
      
      final chapterStr = parts.last;
      final chapter = int.tryParse(chapterStr);
      if (chapter == null) return;
      
      // Reconstruire le nom du livre (tout sauf le dernier élément)
      final bookDisplayName = parts.sublist(0, parts.length - 1).join(' ');
      
      // Trouver le livre correspondant
      BibleBook? targetBook;
      for (final book in _books) {
        if (book.displayName == bookDisplayName) {
          targetBook = book;
          break;
        }
      }
      
      if (targetBook == null) return;
      
      // Vérifier que le chapitre existe
      if (chapter < 1 || chapter > targetBook.chapters.length) return;
      
      // Naviguer vers le signet
      setState(() {
        _selectedBook = targetBook!.name;
        _selectedChapter = chapter;
      });
      
      // Sauvegarder la position
      _saveLastReadingPosition();
      
      // Feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Navigation vers $bookmarkTitle'),
          duration: const Duration(seconds: 1),
        ),
      );
      
      // Feedback haptique
      HapticFeedback.lightImpact();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Erreur lors de la navigation'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  // Méthodes de navigation modernes
  String _getPreviousChapter(BibleBook book) {
    if (_selectedChapter == null) return 'Précédent';
    
    if (_selectedChapter! > 1) {
      return 'Chapitre ${_selectedChapter! - 1}';
    } else {
      // Livre précédent
      final currentBookIndex = _books.indexWhere((b) => b.name == book.name);
      if (currentBookIndex > 0) {
        final previousBook = _books[currentBookIndex - 1];
        return '${previousBook.displayName} ${previousBook.chapters.length}';
      }
    }
    return 'Précédent';
  }

  String _getNextChapter(BibleBook book) {
    if (_selectedChapter == null) return 'Suivant';
    
    if (_selectedChapter! < book.chapters.length) {
      return 'Chapitre ${_selectedChapter! + 1}';
    } else {
      // Livre suivant
      final currentBookIndex = _books.indexWhere((b) => b.name == book.name);
      if (currentBookIndex < _books.length - 1) {
        final nextBook = _books[currentBookIndex + 1];
        return '${nextBook.displayName} 1';
      }
    }
    return 'Suivant';
  }

  bool _canGoPrevious(BibleBook book) {
    if (_selectedChapter == null) return false;
    
    // Si on peut aller au chapitre précédent du même livre
    if (_selectedChapter! > 1) return true;
    
    // Si on peut aller au livre précédent
    final currentBookIndex = _books.indexWhere((b) => b.name == book.name);
    return currentBookIndex > 0;
  }

  bool _canGoNext(BibleBook book) {
    if (_selectedChapter == null) return false;
    
    // Si on peut aller au chapitre suivant du même livre
    if (_selectedChapter! < book.chapters.length) return true;
    
    // Si on peut aller au livre suivant
    final currentBookIndex = _books.indexWhere((b) => b.name == book.name);
    return currentBookIndex < _books.length - 1;
  }
}
