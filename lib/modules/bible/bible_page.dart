// import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';
import 'dart:convert';
import 'bible_service.dart';
import 'bible_model.dart';
import 'widgets/reading_plan_home_widget.dart';
import 'widgets/bible_study_home_widget.dart';
import 'widgets/bible_article_home_widget.dart';
import 'widgets/thematic_passages_home_widget.dart';
import 'views/bible_reading_view.dart';
import 'views/bible_home_view.dart';

class BiblePage extends StatefulWidget {
  const BiblePage({Key? key}) : super(key: key);

  @override
  State<BiblePage> createState() => _BiblePageState();
}

class _BiblePageState extends State<BiblePage> with SingleTickerProviderStateMixin {
  final BibleService _bibleService = BibleService();
  bool _isLoading = true;
  String? _selectedBook;
  int? _selectedChapter;
  String _searchQuery = '';
  List<BibleVerse> _searchResults = [];
  late TabController _tabController;
  Set<String> _favorites = {};
  Set<String> _highlights = {};
  double _fontSize = 16.0;
  bool _isDarkMode = false;
  BibleVerse? _verseOfTheDay;
  Map<String, String> _notes = {}; // notes par clé de verset
  double _lineHeight = 1.5;
  String _fontFamily = '';
  Color? _customBgColor;
  // Ajout d'une variable pour suivre le verset sélectionné
  String? _selectedVerseKey;
  
  // Variables pour les statistiques de l'accueil
  int _readingStreak = 7; // Nombre de jours consécutifs de lecture
  int _readingTimeToday = 25; // Temps de lecture aujourd'hui en minutes
  
  // Index de l'onglet actuel
  int _currentTabIndex = 0;
  
  // Variables pour l'onglet Notes - reproduction exacte de perfect 13
  String _currentFilter = 'all'; // 'all', 'notes', 'highlights'
  String _notesSearchQuery = '';
  final TextEditingController _notesSearchController = TextEditingController();


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
    _loadBible();
    _loadPrefs();
  }

  Future<void> _loadBible() async {
    await _bibleService.loadBible();
    _pickVerseOfTheDay();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favorites = prefs.getStringList('bible_favorites')?.toSet() ?? {};
      _highlights = prefs.getStringList('bible_highlights')?.toSet() ?? {};
      _fontSize = prefs.getDouble('bible_font_size') ?? 16.0;
      _isDarkMode = prefs.getBool('bible_dark_mode') ?? false;
      final notesString = prefs.getString('bible_notes') ?? '{}';
      _notes = Map<String, String>.from(jsonDecode(notesString));
      _lineHeight = prefs.getDouble('bible_line_height') ?? 1.5;
      _fontFamily = prefs.getString('bible_font_family') ?? '';
      final colorValue = prefs.getInt('bible_custom_bg_color');
      _customBgColor = colorValue != null ? Color(colorValue) : null;
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('bible_favorites', _favorites.toList());
    await prefs.setStringList('bible_highlights', _highlights.toList());
    await prefs.setDouble('bible_font_size', _fontSize);
    await prefs.setBool('bible_dark_mode', _isDarkMode);
    await prefs.setString('bible_font_family', _fontFamily);
    await prefs.setDouble('bible_line_height', _lineHeight);
    await prefs.setString('bible_notes', jsonEncode(_notes));
    if (_customBgColor != null) {
      await prefs.setInt('bible_custom_bg_color', _customBgColor!.value);
    }
  }

  Future<void> _saveFavorites() async {
    await _savePrefs();
  }

  Future<void> _saveNotes() async {
    await _savePrefs();
  }

  void _editNoteDialog(BibleVerse v) {
    final key = _verseKey(v);
    final controller = TextEditingController(text: _notes[key] ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Note pour ${v.book} ${v.chapter}:${v.verse}'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Écris ta note ici...'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                if (controller.text.trim().isEmpty) {
                  _notes.remove(key);
                } else {
                  _notes[key] = controller.text.trim();
                }
              });
              _savePrefs();
              Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
      // Recherche avancée :
      final refReg = RegExp(r'^(\w+)\s*(\d+):(\d+)$');
      final match = refReg.firstMatch(query.trim());
      if (match != null) {
        // Recherche par référence (ex: Jean 3:16)
        final book = match.group(1)!;
        final chapter = int.tryParse(match.group(2)!);
        final verse = int.tryParse(match.group(3)!);
        if (chapter != null && verse != null) {
          final found = _bibleService.books.where((b) => b.name.toLowerCase().contains(book.toLowerCase())).toList();
          if (found.isNotEmpty) {
            final b = found.first;
            if (chapter > 0 && chapter <= b.chapters.length && verse > 0 && verse <= b.chapters[chapter-1].length) {
              _searchResults = [BibleVerse(book: b.name, chapter: chapter, verse: verse, text: b.chapters[chapter-1][verse-1])];
              return;
            }
          }
        }
      }
      // Recherche par expression exacte entre guillemets
      final exactReg = RegExp(r'^"(.+)"$');
      final exactMatch = exactReg.firstMatch(query.trim());
      if (exactMatch != null) {
        final phrase = exactMatch.group(1)!;
        _searchResults = _bibleService.search(phrase).where((v) => v.text.contains(phrase)).toList();
        return;
      }
      // Recherche par mot-clé classique
      _searchResults = _bibleService.search(query);
    });
  }

  void _toggleFavorite(BibleVerse v) {
    final key = _verseKey(v);
    setState(() {
      if (_favorites.contains(key)) {
        _favorites.remove(key);
      } else {
        _favorites.add(key);
      }
    });
    _savePrefs();
  }

  void _toggleHighlight(BibleVerse v) {
    final key = _verseKey(v);
    setState(() {
      if (_highlights.contains(key)) {
        _highlights.remove(key);
      } else {
        _highlights.add(key);
      }
    });
    _savePrefs();
  }

  void _pickVerseOfTheDay() {
    final allVerses = <BibleVerse>[];
    for (final book in _bibleService.books) {
      for (int c = 0; c < book.chapters.length; c++) {
        for (int v = 0; v < book.chapters[c].length; v++) {
          allVerses.add(BibleVerse(book: book.name, chapter: c + 1, verse: v + 1, text: book.chapters[c][v]));
        }
      }
    }
    if (allVerses.isNotEmpty) {
      final now = DateTime.now();
      final index = (now.year * 10000 + now.month * 100 + now.day) % allVerses.length;
      _verseOfTheDay = allVerses[index];
    }
  }

  String _verseKey(BibleVerse v) => '${v.book}_${v.chapter}_${v.verse}';

  @override
  Widget build(BuildContext context) {
    final theme = _isDarkMode ? ThemeData.dark().copyWith(
      colorScheme: AppTheme.lightTheme.colorScheme.copyWith(brightness: Brightness.dark),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    ) : AppTheme.lightTheme;
    if (_isLoading) {
      // Shimmer premium sur l’accueil Bible
      return Scaffold(
        backgroundColor: theme.colorScheme.background,
        body: Center(
          child: Shimmer.fromColors(
            baseColor: theme.colorScheme.surface,
            highlightColor: theme.colorScheme.primary.withOpacity(0.13),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 220,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: 320,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: 180,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Theme(
      data: theme,
      child: Column(
        children: [
          // TabBar moderne - Style identique au module Vie de l'église
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.textTertiaryColor.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: AppTheme.textTertiaryColor,
              indicatorColor: AppTheme.primaryColor,
              indicatorWeight: 3,
              labelStyle: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.home, size: 20),
                  text: 'Accueil',
                ),
                Tab(
                  icon: Icon(Icons.menu_book, size: 20),
                  text: 'Lecture',
                ),
                Tab(
                  icon: Icon(Icons.note_alt, size: 20),
                  text: 'Notes',
                ),
              ],
            ),
          ),
          // TabBarView - Style identique au module Vie de l'église
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildHomeTab(),
                const BibleReadingView(isAdminMode: false),
                _buildNotesAndHighlightsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return const BibleHomeView();
  }

  Widget _buildHomeTab_old() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey[50]!,
            Colors.white,
          ],
        ),
      ),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // En-tête avec salutation et statistiques
          SliverToBoxAdapter(
            child: _buildModernHeader(),
          ),
          
          // Verset du jour
          if (_verseOfTheDay != null)
            SliverToBoxAdapter(
              child: _buildVerseOfTheDay(),
            ),
          
          // Actions rapides
          SliverToBoxAdapter(
            child: _buildQuickActions(),
          ),
          
          // Widgets de contenu
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 8),
                const ReadingPlanHomeWidget(),
                const SizedBox(height: 24),
                const BibleStudyHomeWidget(),
                const SizedBox(height: 24),
                const ThematicPassagesHomeWidget(),
                const SizedBox(height: 24),
                const BibleArticleHomeWidget(isAdmin: true),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.auto_stories,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Continuons notre lecture',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Statistiques
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.local_fire_department,
                  title: 'Jour consécutif',
                  value: '${_readingStreak}',
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.bookmark,
                  title: 'Favoris',
                  value: '${_favorites.length}',
                  color: Colors.amber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.schedule,
                  title: 'Temps de lecture',
                  value: '${_readingTimeToday}min',
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    int? count,
    String? label,
  }) {
    // Utiliser count et label si fournis, sinon value et title
    final displayValue = count != null ? count.toString() : value;
    final displayLabel = label ?? title;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            displayValue,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            displayLabel,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerseOfTheDay() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.amber[50]!,
            Colors.orange[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.amber.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber, Colors.orange],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.wb_sunny,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verset du jour',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[800],
                        ),
                      ),
                      Text(
                        _getCurrentDate(),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.amber[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _shareVerse(_verseOfTheDay!),
                  icon: const Icon(Icons.share),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.amber[700],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Quote container
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.format_quote,
                    color: Colors.amber[300],
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    child: Text(
                      _verseOfTheDay!.text,
                      key: ValueKey(_verseOfTheDay!.text),
                      style: GoogleFonts.crimsonText(
                        fontSize: _fontSize + 4,
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_verseOfTheDay!.book} ${_verseOfTheDay!.chapter}:${_verseOfTheDay!.verse}',
                        style: GoogleFonts.inter(
                          color: Colors.amber[800],
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 16),
            child: Text(
              'Actions rapides',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.play_circle_filled,
                  title: 'Continuer\nla lecture',
                  color: AppTheme.primaryColor,
                  onTap: () {
                    // Naviguer vers le dernier chapitre lu
                    setState(() => _currentTabIndex = 1);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.search,
                  title: 'Rechercher\nun passage',
                  color: Colors.blue,
                  onTap: () {
                    // Ouvrir la recherche
                    setState(() => _currentTabIndex = 2);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.star,
                  title: 'Mes\nfavoris',
                  color: Colors.amber,
                  onTap: () {
                    // Ouvrir les favoris
                    _showFavorites();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.note,
                  title: 'Mes\nnotes',
                  color: Colors.green,
                  onTap: () {
                    // Ouvrir les notes
                    _showNotes();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Méthodes utilitaires
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour !';
    if (hour < 17) return 'Bon après-midi !';
    return 'Bonsoir !';
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    final months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  void _showFavorites() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Mes Favoris',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: _favorites.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun verset favori',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Appuyez longuement sur un verset pour l\'ajouter aux favoris',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _favorites.length,
                  itemBuilder: (context, index) {
                    final verseKey = _favorites.elementAt(index);
                    final parts = verseKey.split(' ');
                    final book = parts[0];
                    final chapterVerse = parts[1].split(':');
                    final chapter = int.parse(chapterVerse[0]);
                    final verse = int.parse(chapterVerse[1]);
                    
                    final bibleVerse = _bibleService.getVerse(book, chapter, verse);
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: Icon(Icons.favorite, color: Colors.red),
                        title: Text(
                          verseKey,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        subtitle: Text(
                          bibleVerse?.text ?? 'Verset non trouvé',
                          style: GoogleFonts.plusJakartaSans(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _favorites.remove(verseKey);
                            });
                            _saveFavorites();
                            Navigator.of(context).pop();
                            _showFavorites(); // Réafficher pour actualiser
                          },
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          // Naviguer vers le verset
                          setState(() {
                            _selectedBook = book;
                            _selectedChapter = chapter;
                          });
                        },
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showNotes() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Mes Notes',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: _notes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.note_add_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune note',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Appuyez longuement sur un verset pour ajouter une note',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _notes.length,
                  itemBuilder: (context, index) {
                    final verseKey = _notes.keys.elementAt(index);
                    final note = _notes[verseKey]!;
                    final parts = verseKey.split(' ');
                    final book = parts[0];
                    final chapterVerse = parts[1].split(':');
                    final chapter = int.parse(chapterVerse[0]);
                    final verse = int.parse(chapterVerse[1]);
                    
                    final bibleVerse = _bibleService.getVerse(book, chapter, verse);
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: Icon(Icons.note, color: AppTheme.primaryColor),
                        title: Text(
                          verseKey,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bibleVerse?.text ?? 'Verset non trouvé',
                              style: GoogleFonts.plusJakartaSans(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                note,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit_outlined, color: AppTheme.primaryColor),
                              onPressed: () {
                                Navigator.of(context).pop();
                                // Ouvrir le dialogue d'édition
                                if (bibleVerse != null) {
                                  _editNoteDialog(bibleVerse);
                                }
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _notes.remove(verseKey);
                                });
                                _saveNotes();
                                Navigator.of(context).pop();
                                _showNotes(); // Réafficher pour actualiser
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          // Naviguer vers le verset
                          setState(() {
                            _selectedBook = book;
                            _selectedChapter = chapter;
                          });
                        },
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildModernReadingTab(List<BibleBook> books) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            Colors.grey.withOpacity(0.03),
          ],
        ),
      ),
      child: Column(
        children: [
          // En-tête moderne avec sélecteurs
          _buildModernReadingHeader(books),
          
          // Contenu principal
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _selectedBook != null && _selectedChapter != null
                  ? _buildModernVersesList(books.firstWhere((b) => b.name == _selectedBook!), _selectedChapter!)
                  : _buildReadingPlaceholder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernReadingHeader(List<BibleBook> books) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.withOpacity(0.05),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Titre et icône compacts
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.menu_book,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lecture Biblique',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      'Explorez les Saintes Écritures',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Menu d'options compact
              PopupMenuButton<String>(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.more_vert,
                    color: AppTheme.primaryColor,
                    size: 16,
                  ),
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'settings':
                      _showReadingSettings();
                      break;
                    case 'history':
                      _showReadingHistory();
                      break;
                    case 'bookmark':
                      _bookmarkCurrentChapter();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(
                          Icons.settings,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Paramètres de lecture',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'history',
                    child: Row(
                      children: [
                        Icon(
                          Icons.history,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Historique',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'bookmark',
                    child: Row(
                      children: [
                        Icon(
                          Icons.bookmark_add,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Marquer ce chapitre',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Sélecteurs compacts
          Row(
            children: [
              // Sélecteur de livre compact
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedBook != null 
                          ? AppTheme.primaryColor.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: DropdownButton<String>(
                    value: _selectedBook,
                    hint: Row(
                      children: [
                        Icon(
                          Icons.book,
                          color: Colors.grey[600],
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Livre',
                          style: GoogleFonts.inter(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    isExpanded: true,
                    underline: const SizedBox(),
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppTheme.primaryColor,
                      size: 18,
                    ),
                    style: GoogleFonts.inter(
                      color: AppTheme.primaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    items: books.map((b) => DropdownMenuItem(
                      value: b.name,
                      child: Row(
                        children: [
                          Icon(
                            Icons.book,
                            color: AppTheme.primaryColor,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              b.name,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                    onChanged: (v) => setState(() {
                      _selectedBook = v;
                      _selectedChapter = null;
                    }),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
              
              const SizedBox(width: 10),
              
              // Sélecteur de chapitre compact
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    color: _selectedBook != null ? Colors.white : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedChapter != null 
                          ? AppTheme.primaryColor.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.2),
                    ),
                    boxShadow: _selectedBook != null ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ] : [],
                  ),
                  child: DropdownButton<int>(
                    value: _selectedChapter,
                    hint: Row(
                      children: [
                        Icon(
                          Icons.format_list_numbered,
                          color: _selectedBook != null ? Colors.grey[600] : Colors.grey[400],
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Chap.',
                            style: GoogleFonts.inter(
                              color: _selectedBook != null ? Colors.grey[600] : Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    isExpanded: true,
                    underline: const SizedBox(),
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: _selectedBook != null ? AppTheme.primaryColor : Colors.grey[400],
                      size: 18,
                    ),
                    style: GoogleFonts.inter(
                      color: AppTheme.primaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    items: _selectedBook != null
                        ? List.generate(
                            books.firstWhere((b) => b.name == _selectedBook!).chapters.length,
                            (i) => DropdownMenuItem(
                              value: i + 1,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${i + 1}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : [],
                    onChanged: _selectedBook != null 
                        ? (v) => setState(() => _selectedChapter = v)
                        : null,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReadingPlaceholder() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.1),
                    AppTheme.primaryColor.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.menu_book_outlined,
                size: 80,
                color: AppTheme.primaryColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              _selectedBook == null
                  ? 'Choisissez un livre pour commencer'
                  : 'Sélectionnez un chapitre',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              _selectedBook == null
                  ? 'Explorez les 66 livres de la Bible et plongez dans la Parole de Dieu'
                  : 'Découvrez les versets du livre ${_selectedBook}',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (_selectedBook == null) ...[
              ElevatedButton.icon(
                onPressed: () {
                  // Suggestion de livre aléatoire
                  final suggestions = ['Jean', 'Psaumes', 'Proverbes', 'Matthieu', 'Romains'];
                  final random = suggestions[DateTime.now().millisecond % suggestions.length];
                  setState(() {
                    _selectedBook = random;
                  });
                },
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Suggestion aléatoire'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModernVersesList(BibleBook book, int chapter) {
    final theme = Theme.of(context);
    final verses = book.chapters[chapter - 1];
    
    if (_isLoading) {
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) => Shimmer.fromColors(
          baseColor: theme.colorScheme.surface,
          highlightColor: theme.colorScheme.primary.withOpacity(0.13),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      );
    }
    
    return Column(
      children: [
        // En-tête du chapitre compact
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor.withOpacity(0.08),
                AppTheme.primaryColor.withOpacity(0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.1),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.auto_stories,
                      color: AppTheme.primaryColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${book.name} ${chapter}',
                          style: GoogleFonts.crimsonText(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        Text(
                          '${verses.length} versets',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Navigation rapide compacte
                  Row(
                    children: [
                      if (chapter > 1)
                        IconButton(
                          onPressed: () => setState(() => _selectedChapter = chapter - 1),
                          icon: const Icon(Icons.navigate_before),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.all(6),
                            minimumSize: const Size(32, 32),
                          ),
                          tooltip: 'Chapitre précédent',
                        ),
                      const SizedBox(width: 6),
                      if (chapter < book.chapters.length)
                        IconButton(
                          onPressed: () => setState(() => _selectedChapter = chapter + 1),
                          icon: const Icon(Icons.navigate_next),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.all(6),
                            minimumSize: const Size(32, 32),
                          ),
                          tooltip: 'Chapitre suivant',
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Liste des versets optimisée
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: verses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, i) {
              final v = BibleVerse(book: book.name, chapter: chapter, verse: i + 1, text: verses[i]);
              final key = _verseKey(v);
              final isFav = _favorites.contains(key);
              final isHighlight = _highlights.contains(key);
              final note = _notes[key];
              
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 300 + (i * 15)),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: isHighlight
                        ? AppTheme.primaryColor.withOpacity(0.08)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: isHighlight 
                        ? Border.all(color: AppTheme.primaryColor.withOpacity(0.3), width: 1.5)
                        : Border.all(color: Colors.grey.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _selectedVerseKey = (_selectedVerseKey == key) ? null : key;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // En-tête du verset compact
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Numéro du verset compact
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppTheme.primaryColor.withOpacity(0.1),
                                      AppTheme.primaryColor.withOpacity(0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${v.verse}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                              
                              const SizedBox(width: 12),
                              
                              // Texte du verset
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      verses[i],
                                      style: _fontFamily.isNotEmpty
                                          ? GoogleFonts.getFont(
                                              _fontFamily,
                                              fontSize: _fontSize,
                                              height: _lineHeight,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey[800],
                                            )
                                          : GoogleFonts.crimsonText(
                                              fontSize: _fontSize,
                                              height: _lineHeight,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey[800],
                                            ),
                                    ),
                                    
                                    const SizedBox(height: 6),
                                    
                                    // Référence compacte
                                    Text(
                                      '${v.book} ${v.chapter}:${v.verse}',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: Colors.grey[500],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Indicateurs compacts
                              Column(
                                children: [
                                  if (isFav)
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.star,
                                        size: 12,
                                        color: Colors.amber[700],
                                      ),
                                    ),
                                  if (note != null && note.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.sticky_note_2,
                                        size: 12,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          
                          // Note si présente (compacte)
                          if (note != null && note.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.blue.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.sticky_note_2,
                                    color: Colors.blue[700],
                                    size: 14,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      note,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.blue[700],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          
                          // Actions compactes (quand le verset est sélectionné)
                          if (_selectedVerseKey == key) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildVerseAction(
                                    icon: isFav ? Icons.star : Icons.star_border,
                                    label: isFav ? 'Favori' : 'Favoris',
                                    color: Colors.amber[700]!,
                                    isActive: isFav,
                                    onTap: () => _toggleFavorite(v),
                                  ),
                                  _buildVerseAction(
                                    icon: isHighlight ? Icons.highlight_off : Icons.highlight,
                                    label: isHighlight ? 'Surligné' : 'Surligner',
                                    color: AppTheme.primaryColor,
                                    isActive: isHighlight,
                                    onTap: () => _toggleHighlight(v),
                                  ),
                                  _buildVerseAction(
                                    icon: Icons.sticky_note_2,
                                    label: note != null && note.isNotEmpty ? 'Éditer' : 'Note',
                                    color: Colors.blue[700]!,
                                    isActive: note != null && note.isNotEmpty,
                                    onTap: () => _editNoteDialog(v),
                                  ),
                                  _buildVerseAction(
                                    icon: Icons.share,
                                    label: 'Partager',
                                    color: Colors.green[700]!,
                                    isActive: false,
                                    onTap: () => _shareVerse(v),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVerseAction({
    required IconData icon,
    required String label,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? color.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? color : Colors.grey[600],
              size: 16,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: isActive ? color : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Méthodes d'actions supplémentaires
  void _showReadingSettings() {
    // TODO: Implémenter les paramètres de lecture
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Paramètres de lecture'),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showReadingHistory() {
    // TODO: Implémenter l'historique de lecture
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Historique de lecture'),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _bookmarkCurrentChapter() {
    if (_selectedBook != null && _selectedChapter != null) {
      // TODO: Implémenter le marque-page de chapitre
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chapitre $_selectedBook $_selectedChapter marqué'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _shareVerse(BibleVerse verse) {
    // TODO: Implémenter le partage de verset
    
    // Pour l'instant, on affiche un message de confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Verset partagé: ${verse.book} ${verse.chapter}:${verse.verse}'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    
    // TODO: Utiliser le package share_plus pour partager le texte
    // await Share.share(text);
  }

  Widget _buildSearchTab() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey[50]!,
            Colors.white,
          ],
        ),
      ),
      child: Column(
        children: [
          // En-tête moderne avec champ de recherche
          _buildModernSearchHeader(),
          
          // Contenu principal
          Expanded(
            child: _searchQuery.isEmpty
                ? _buildSearchEmptyState()
                : _buildModernSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSearchHeader() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // En-tête avec titre
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue[600]!,
                  Colors.blue[700]!,
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.search,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recherche Biblique',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Explorez les Écritures',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_searchResults.length} résultat${_searchResults.length > 1 ? 's' : ''}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Champ de recherche et filtres
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Champ de recherche principal
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.2),
                    ),
                  ),
                  child: TextField(
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un mot, "expression" ou référence (ex: Jean 3:16)',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(12),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.search,
                          color: Colors.blue[600],
                          size: 20,
                        ),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                  _searchResults.clear();
                                });
                              },
                              icon: const Icon(Icons.clear),
                              color: Colors.grey[500],
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                    ),
                    onChanged: (query) {
                      _onSearch(query);
                      setState(() {});
                    },
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Filtres de recherche
                _buildSearchFilters(),
                
                // Suggestions de recherche
                if (_searchQuery.isEmpty)
                  _buildSearchSuggestions(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchFilters() {
    return StatefulBuilder(
      builder: (context, setStateSB) {
        String? _selectedBookFilter;
        
        return Row(
          children: [
            // Filtre par livre
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.2),
                  ),
                ),
                child: DropdownButton<String>(
                  value: _selectedBookFilter,
                  hint: Row(
                    children: [
                      Icon(
                        Icons.book,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tous les livres',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  underline: const SizedBox(),
                  isExpanded: true,
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: Colors.grey[600],
                  ),
                  items: [
                    DropdownMenuItem<String>(
                      value: '',
                      child: Row(
                        children: [
                          const Icon(Icons.all_inclusive, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Tous les livres',
                            style: GoogleFonts.inter(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    ..._bibleService.books.map((book) => DropdownMenuItem<String>(
                      value: book.name,
                      child: Text(
                        book.name,
                        style: GoogleFonts.inter(fontSize: 14),
                      ),
                    )).toList(),
                  ],
                  onChanged: (value) {
                    setStateSB(() {
                      _selectedBookFilter = (value != null && value.isNotEmpty) ? value : null;
                    });
                  },
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Bouton de recherche avancée
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[500]!, Colors.blue[600]!],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _showAdvancedSearchDialog(),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.tune,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Avancé',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchSuggestions() {
    final suggestions = [
      {'text': 'amour', 'icon': Icons.favorite, 'color': Colors.red},
      {'text': 'paix', 'icon': Icons.spa, 'color': Colors.green},
      {'text': 'sagesse', 'icon': Icons.psychology, 'color': Colors.purple},
      {'text': 'espoir', 'icon': Icons.star, 'color': Colors.amber},
      {'text': 'Jean 3:16', 'icon': Icons.auto_stories, 'color': Colors.blue},
      {'text': 'Psaume 23', 'icon': Icons.music_note, 'color': Colors.orange},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Suggestions de recherche',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestions.map((suggestion) => InkWell(
            onTap: () => _onSearch(suggestion['text'] as String),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: (suggestion['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (suggestion['color'] as Color).withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    suggestion['icon'] as IconData,
                    size: 16,
                    color: suggestion['color'] as Color,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    suggestion['text'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: suggestion['color'] as Color,
                    ),
                  ),
                ],
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildSearchEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search,
              size: 64,
              color: Colors.blue[300],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Commencez votre recherche',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tapez un mot, une expression ou une référence\npour explorer les Écritures',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.grey[500],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildQuickSearchCards(),
        ],
      ),
    );
  }

  Widget _buildQuickSearchCards() {
    final quickSearches = [
      {
        'title': 'Versets célèbres',
        'description': 'Jean 3:16, Psaume 23:1',
        'icon': Icons.star,
        'color': Colors.amber,
        'searches': ['Jean 3:16', 'Psaume 23:1', 'Matthieu 5:3-12'],
      },
      {
        'title': 'Thèmes spirituels',
        'description': 'Amour, paix, espoir',
        'icon': Icons.favorite,
        'color': Colors.red,
        'searches': ['amour', 'paix', 'espoir', 'foi'],
      },
      {
        'title': 'Sagesse',
        'description': 'Proverbes et conseils',
        'icon': Icons.psychology,
        'color': Colors.purple,
        'searches': ['sagesse', 'conseil', 'prudence'],
      },
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: quickSearches.map((search) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: InkWell(
            onTap: () {
              final searches = search['searches'] as List<String>;
              _onSearch(searches.first);
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: (search['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (search['color'] as Color).withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: search['color'] as Color,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      search['icon'] as IconData,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    search['title'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    search['description'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[500],
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildModernSearchResults() {
    if (_searchResults.isEmpty) {
      return _buildNoResultsState();
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // En-tête des résultats
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.green[50]!,
                  Colors.blue[50]!,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.green.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_searchResults.length} résultat${_searchResults.length > 1 ? 's' : ''} trouvé${_searchResults.length > 1 ? 's' : ''}',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                      Text(
                        'Pour la recherche: "$_searchQuery"',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Liste des résultats
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final verse = _searchResults[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: _buildModernVerseCard(verse, index),
                );
              },
              childCount: _searchResults.length,
            ),
          ),
        ),

        // Espacement final
        const SliverToBoxAdapter(
          child: SizedBox(height: 20),
        ),
      ],
    );
  }

  Widget _buildModernVerseCard(BibleVerse verse, int index) {
    final key = _verseKey(verse);
    final isFav = _favorites.contains(key);
    final isHighlight = _highlights.contains(key);
    final note = _notes[key];

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: child,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isHighlight
              ? AppTheme.primaryColor.withOpacity(0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isHighlight 
              ? Border.all(color: AppTheme.primaryColor.withOpacity(0.3), width: 2)
              : Border.all(color: Colors.grey.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              _selectedVerseKey = (_selectedVerseKey == key) ? null : key;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête du verset
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Numéro du verset
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue[400]!, Colors.blue[500]!],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '${verse.verse}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Texte du verset
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            verse.text,
                            style: _fontFamily.isNotEmpty
                                ? GoogleFonts.getFont(
                                    _fontFamily,
                                    fontSize: _fontSize,
                                    height: _lineHeight,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[800],
                                  )
                                : GoogleFonts.crimsonText(
                                    fontSize: _fontSize + 2,
                                    height: _lineHeight,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[800],
                                  ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Référence avec badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${verse.book} ${verse.chapter}:${verse.verse}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Indicateurs
                    Column(
                      children: [
                        if (isFav)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber[700],
                            ),
                          ),
                        if (note != null && note.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.sticky_note_2,
                              size: 16,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                
                // Note si présente
                if (note != null && note.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.sticky_note_2,
                          color: Colors.green[700],
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            note,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.green[700],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Actions (quand le verset est sélectionné)
                if (_selectedVerseKey == key) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildVerseAction(
                          icon: isFav ? Icons.star : Icons.star_border,
                          label: isFav ? 'Favori' : 'Favoris',
                          color: Colors.amber[700]!,
                          isActive: isFav,
                          onTap: () => _toggleFavorite(verse),
                        ),
                        _buildVerseAction(
                          icon: isHighlight ? Icons.highlight_off : Icons.highlight,
                          label: isHighlight ? 'Surligné' : 'Surligner',
                          color: AppTheme.primaryColor,
                          isActive: isHighlight,
                          onTap: () => _toggleHighlight(verse),
                        ),
                        _buildVerseAction(
                          icon: Icons.sticky_note_2,
                          label: note != null && note.isNotEmpty ? 'Éditer' : 'Note',
                          color: Colors.green[700]!,
                          isActive: note != null && note.isNotEmpty,
                          onTap: () => _editNoteDialog(verse),
                        ),
                        _buildVerseAction(
                          icon: Icons.share,
                          label: 'Partager',
                          color: Colors.blue[700]!,
                          isActive: false,
                          onTap: () => _shareVerse(verse),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off,
              size: 64,
              color: Colors.orange[300],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Aucun résultat trouvé',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez avec d\'autres mots-clés\nou vérifiez l\'orthographe',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.grey[500],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _searchResults.clear();
              });
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Nouvelle recherche'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAdvancedSearchDialog() {
    // TODO: Implémenter la recherche avancée
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Recherche avancée (bientôt disponible)'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildFavoritesTab() {
    // Récupération des versets favoris
    final favVerses = <BibleVerse>[];
    for (final book in _bibleService.books) {
      for (int c = 0; c < book.chapters.length; c++) {
        for (int v = 0; v < book.chapters[c].length; v++) {
          final verse = BibleVerse(
            book: book.name, 
            chapter: c + 1, 
            verse: v + 1, 
            text: book.chapters[c][v]
          );
          if (_favorites.contains(_verseKey(verse))) {
            favVerses.add(verse);
          }
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.amber[50]!,
            Colors.white,
          ],
        ),
      ),
      child: Column(
        children: [
          // En-tête moderne
          _buildModernFavoritesHeader(favVerses.length),
          
          // Contenu principal
          Expanded(
            child: favVerses.isEmpty
                ? _buildFavoritesEmptyState()
                : _buildModernFavoritesList(favVerses),
          ),
        ],
      ),
    );
  }

  Widget _buildModernFavoritesHeader(int favoritesCount) {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.amber[600]!,
            Colors.orange[600]!,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.star,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mes Favoris',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        favoritesCount > 0 
                            ? '$favoritesCount verset${favoritesCount > 1 ? 's' : ''} précieux'
                            : 'Collection de versets inspirants',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (favoritesCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$favoritesCount',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            
            if (favoritesCount > 0) ...[
              const SizedBox(height: 20),
              
              // Actions rapides
              Row(
                children: [
                  Expanded(
                    child: _buildFavoriteActionButton(
                      icon: Icons.share,
                      label: 'Partager tout',
                      onTap: () => _shareAllFavorites(favoritesCount),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildFavoriteActionButton(
                      icon: Icons.download,
                      label: 'Exporter',
                      onTap: () => _exportFavorites(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildFavoriteActionButton(
                      icon: Icons.sort,
                      label: 'Trier',
                      onTap: () => _showSortOptions(),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber[100]!, Colors.orange[100]!],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.star_border,
              size: 64,
              color: Colors.amber[600],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Aucun favori pour le moment',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Commencez à créer votre collection\nde versets inspirants',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.grey[500],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildDiscoveryCards(),
        ],
      ),
    );
  }

  Widget _buildDiscoveryCards() {
    final discoveries = [
      {
        'title': 'Explorer la Bible',
        'description': 'Découvrez des versets\ninspirantes',
        'icon': Icons.explore,
        'color': Colors.blue,
        'onTap': () => setState(() => _currentTabIndex = 1),
      },
      {
        'title': 'Rechercher',
        'description': 'Trouvez des passages\npar thème',
        'icon': Icons.search,
        'color': Colors.green,
        'onTap': () => setState(() => _currentTabIndex = 2),
      },
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: discoveries.map((discovery) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          child: InkWell(
            onTap: discovery['onTap'] as VoidCallback,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: (discovery['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (discovery['color'] as Color).withOpacity(0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: (discovery['color'] as Color).withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: discovery['color'] as Color,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: (discovery['color'] as Color).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      discovery['icon'] as IconData,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    discovery['title'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    discovery['description'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey[500],
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildModernFavoritesList(List<BibleVerse> favVerses) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // En-tête de la liste avec statistiques
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber[50]!, Colors.orange[50]!],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.amber.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.auto_stories,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Collection personnelle',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[700],
                        ),
                      ),
                      Text(
                        'Vos versets précieux, toujours à portée de main',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.amber[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Liste des favoris
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final verse = favVerses[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: _buildModernFavoriteCard(verse, index),
                );
              },
              childCount: favVerses.length,
            ),
          ),
        ),

        // Espacement final
        const SliverToBoxAdapter(
          child: SizedBox(height: 20),
        ),
      ],
    );
  }

  Widget _buildModernFavoriteCard(BibleVerse verse, int index) {
    final key = _verseKey(verse);
    final isHighlight = _highlights.contains(key);
    final note = _notes[key];

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: child,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.amber[25]!,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.amber.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              _selectedVerseKey = (_selectedVerseKey == key) ? null : key;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec étoile dorée
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge favori doré
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.amber, Colors.orange],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.star,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Numéro du verset
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${verse.verse}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[700],
                        ),
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Indicateurs
                    Column(
                      children: [
                        if (isHighlight)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.highlight,
                              size: 16,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        if (note != null && note.isNotEmpty) ...[
                          if (isHighlight) const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.sticky_note_2,
                              size: 16,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Texte du verset avec style élégant
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.amber.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icône de citation
                      Icon(
                        Icons.format_quote,
                        color: Colors.amber[300],
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        verse.text,
                        style: _fontFamily.isNotEmpty
                            ? GoogleFonts.getFont(
                                _fontFamily,
                                fontSize: _fontSize + 2,
                                height: _lineHeight,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[800],
                              )
                            : GoogleFonts.crimsonText(
                                fontSize: _fontSize + 4,
                                height: _lineHeight,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[800],
                                fontStyle: FontStyle.italic,
                              ),
                      ),
                      const SizedBox(height: 16),
                      // Référence avec style
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.amber[100]!, Colors.orange[100]!],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${verse.book} ${verse.chapter}:${verse.verse}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.amber[800],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Note si présente
                if (note != null && note.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.sticky_note_2,
                          color: Colors.green[700],
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ma note personnelle',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green[700],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                note,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.green[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Actions (quand le verset est sélectionné)
                if (_selectedVerseKey == key) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.amber[50]!, Colors.orange[50]!],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildVerseAction(
                          icon: Icons.star,
                          label: 'Retirer',
                          color: Colors.red[600]!,
                          isActive: true,
                          onTap: () => _toggleFavorite(verse),
                        ),
                        _buildVerseAction(
                          icon: isHighlight ? Icons.highlight_off : Icons.highlight,
                          label: isHighlight ? 'Surligné' : 'Surligner',
                          color: AppTheme.primaryColor,
                          isActive: isHighlight,
                          onTap: () => _toggleHighlight(verse),
                        ),
                        _buildVerseAction(
                          icon: Icons.sticky_note_2,
                          label: note != null && note.isNotEmpty ? 'Éditer' : 'Note',
                          color: Colors.green[700]!,
                          isActive: note != null && note.isNotEmpty,
                          onTap: () => _editNoteDialog(verse),
                        ),
                        _buildVerseAction(
                          icon: Icons.share,
                          label: 'Partager',
                          color: Colors.blue[700]!,
                          isActive: false,
                          onTap: () => _shareVerse(verse),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Méthodes utilitaires pour les favoris
  void _shareAllFavorites(int count) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Partage de $count verset${count > 1 ? 's' : ''} favori${count > 1 ? 's' : ''}'),
        backgroundColor: Colors.amber,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _exportFavorites() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Export des favoris (bientôt disponible)'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Options de tri',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.sort_by_alpha),
              title: const Text('Par ordre alphabétique'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Par date d\'ajout'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text('Par livre biblique'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesAndHighlightsTab() {
    final totalNotes = _notes.values.where((note) => note.isNotEmpty).length;
    final totalHighlights = _highlights.length;
    final totalFavorites = _favorites.length;

    // Filtrer les versets en fonction du filtre et de la recherche actuels
    List<String> filteredVerseKeys = [];
    
    if (_currentFilter == 'notes') {
      filteredVerseKeys = _notes.keys
          .where((key) => _notes[key]!.isNotEmpty)
          .where((key) => _notesSearchQuery.isEmpty || 
              _getVerseDisplayText(key).toLowerCase().contains(_notesSearchQuery.toLowerCase()) ||
              _notes[key]!.toLowerCase().contains(_notesSearchQuery.toLowerCase()))
          .toList();
    } else if (_currentFilter == 'highlights') {
      filteredVerseKeys = _highlights
          .where((key) => _notesSearchQuery.isEmpty || 
              _getVerseDisplayText(key).toLowerCase().contains(_notesSearchQuery.toLowerCase()))
          .toList();
    } else if (_currentFilter == 'favorites') {
      filteredVerseKeys = _favorites
          .where((key) => _notesSearchQuery.isEmpty || 
              _getVerseDisplayText(key).toLowerCase().contains(_notesSearchQuery.toLowerCase()))
          .toList();
    } else {
      // Tous
      final noteKeys = _notes.keys.where((key) => _notes[key]!.isNotEmpty);
      final allKeys = {...noteKeys, ..._highlights, ..._favorites}.toList();
      filteredVerseKeys = allKeys
          .where((key) => _notesSearchQuery.isEmpty || 
              _getVerseDisplayText(key).toLowerCase().contains(_notesSearchQuery.toLowerCase()) ||
              (_notes[key] ?? '').toLowerCase().contains(_notesSearchQuery.toLowerCase()))
          .toList();
    }

    return Container(
      color: const Color(0xFFFAFAFA),
      child: CustomScrollView(
        slivers: [
          // Filtres compacts
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCompactFilterChip(
                      'all',
                      'Tous',
                      Icons.view_list,
                      totalNotes + totalHighlights + totalFavorites,
                    ),
                    const SizedBox(width: 8),
                    _buildCompactFilterChip(
                      'notes',
                      'Notes',
                      Icons.note_alt_outlined,
                      totalNotes,
                    ),
                    const SizedBox(width: 8),
                    _buildCompactFilterChip(
                      'highlights',
                      'Surlignés',
                      Icons.highlight,
                      totalHighlights,
                    ),
                    const SizedBox(width: 8),
                    _buildCompactFilterChip(
                      'favorites',
                      'Favoris',
                      Icons.favorite,
                      totalFavorites,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Barre de recherche
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _notesSearchController,
                onChanged: (value) {
                  setState(() {
                    _notesSearchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Rechercher dans vos notes...',
                  hintStyle: GoogleFonts.inter(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                  suffixIcon: _notesSearchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: Colors.grey[400],
                            size: 20,
                          ),
                          onPressed: () {
                            _notesSearchController.clear();
                            setState(() {
                              _notesSearchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // Liste des versets
          filteredVerseKeys.isEmpty
              ? SliverFillRemaining(
                  child: _buildEmptyNotesState(),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final verseKey = filteredVerseKeys[index];
                      return _buildNoteCard(verseKey);
                    },
                    childCount: filteredVerseKeys.length,
                  ),
                ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  String _getVerseDisplayText(String verseKey) {
    final parts = verseKey.split('_');
    if (parts.length >= 3) {
      final book = parts[0];
      final chapter = parts[1];
      final verse = parts[2];
      return '$book $chapter:$verse';
    }
    return verseKey;
  }

  Widget _buildCompactFilterChip(String filterKey, String label, IconData icon, int count) {
    final isSelected = _currentFilter == filterKey;
    
    Color getFilterColor() {
      switch (filterKey) {
        case 'notes':
          return const Color(0xFF10B981);
        case 'highlights':
          return const Color(0xFFF59E0B);
        case 'favorites':
          return const Color(0xFFEF4444);
        default:
          return const Color(0xFF6366F1);
      }
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentFilter = filterKey;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? getFilterColor() : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? getFilterColor() : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.2) : getFilterColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : getFilterColor(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyNotesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _notesSearchQuery.isNotEmpty ? Icons.search_off_rounded : Icons.sticky_note_2_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _notesSearchQuery.isNotEmpty 
                ? 'Aucun résultat pour "${_notesSearchQuery}"'
                : 'Aucun élément trouvé',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _notesSearchQuery.isNotEmpty
                ? 'Essayez avec d\'autres mots-clés ou vérifiez l\'orthographe'
                : 'Commencez à prendre des notes\nou surligner des versets',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(String verseKey) {
    final hasNote = _notes.containsKey(verseKey) && _notes[verseKey]!.isNotEmpty;
    final hasHighlight = _highlights.contains(verseKey);
    final isFavorite = _favorites.contains(verseKey);
    
    // Couleur principale selon le type
    Color getCardAccentColor() {
      if (hasNote) return const Color(0xFF10B981);
      if (hasHighlight) return const Color(0xFFF59E0B);
      if (isFavorite) return const Color(0xFFEF4444);
      return const Color(0xFF6366F1);
    }

    return GestureDetector(
      onTap: () => _goToVerseFromNotes(verseKey),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: getCardAccentColor().withOpacity(0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: getCardAccentColor().withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: const Color(0xFF000000).withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec référence et badges
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    getCardAccentColor().withOpacity(0.05),
                    getCardAccentColor().withOpacity(0.02),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _getVerseDisplayText(verseKey),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: getCardAccentColor(),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      if (hasNote)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.sticky_note_2,
                            size: 16,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      if (hasHighlight) ...[
                        if (hasNote) const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.highlight,
                            size: 16,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                      if (isFavorite) ...[
                        if (hasNote || hasHighlight) const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.favorite,
                            size: 16,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            
            // Contenu du verset
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                _getVerseText(verseKey),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF374151),
                  height: 1.5,
                ),
              ),
            ),
            
            // Note utilisateur si présente
            if (hasNote && _notes[verseKey]!.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF10B981).withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.sticky_note_2,
                          size: 16,
                          color: Color(0xFF10B981),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Ma note',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _notes[verseKey]!,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF374151),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getVerseText(String verseKey) {
    final parts = verseKey.split('_');
    if (parts.length >= 3) {
      final bookName = parts[0];
      final chapterNum = int.tryParse(parts[1]) ?? 1;
      final verseNum = int.tryParse(parts[2]) ?? 1;
      
      final book = _bibleService.books.firstWhere(
        (b) => b.name == bookName,
        orElse: () => BibleBook(name: bookName, chapters: []),
      );
      
      if (book.chapters.isNotEmpty && 
          chapterNum <= book.chapters.length && 
          chapterNum > 0) {
        final chapterVerses = book.chapters[chapterNum - 1];
        if (verseNum <= chapterVerses.length && verseNum > 0) {
          return chapterVerses[verseNum - 1];
        }
      }
    }
    return 'Texte non disponible';
  }

  void _goToVerseFromNotes(String verseKey) {
    final parts = verseKey.split('_');
    if (parts.length >= 3) {
      final bookName = parts[0];
      final chapterNum = int.tryParse(parts[1]) ?? 1;
      final verseNum = int.tryParse(parts[2]) ?? 1;
      
      setState(() {
        _selectedBook = bookName;
        _selectedChapter = chapterNum;
        _tabController.index = 1; // Aller à l'onglet lecture
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Navigation vers $bookName $chapterNum:$verseNum'),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF6366F1),
        ),
      );
    }
  }
}
