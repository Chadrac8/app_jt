// import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme.dart';
import 'dart:convert';
import 'services/bible_service.dart';
import 'models/bible_book.dart';
import 'models/bible_verse.dart';
import 'views/bible_reading_view.dart';
import 'views/bible_home_view.dart';

import 'services/apple_notes_share_service.dart';

class BiblePage extends StatefulWidget {
  final TabController?
  tabController; // MD3: TabController fourni par le wrapper

  const BiblePage({Key? key, this.tabController}) : super(key: key);

  @override
  State<BiblePage> createState() => _BiblePageState();
}

class _BiblePageState extends State<BiblePage>
    with SingleTickerProviderStateMixin {
  final BibleService _bibleService = BibleService();
  bool _isLoading = true;
  String? _selectedBook;
  int? _selectedChapter;
  String _searchQuery = '';
  List<BibleVerse> _searchResults = [];
  TabController?
  _internalTabController; // TabController interne (si non fourni)

  // MD3: Getter pour obtenir le TabController (externe ou interne)
  TabController get _tabController =>
      widget.tabController ?? _internalTabController!;

  Set<String> _favorites = {};
  Map<String, Color> _highlights = {};
  double _fontSize = 16.0;
  bool _isDarkMode = false;
  Map<String, String> _notes = {}; // notes par clé de verset
  double _lineHeight = 1.5;
  String _fontFamily = '';
  Color? _customBgColor;
  // Ajout d'une variable pour suivre le verset sélectionné
  String? _selectedVerseKey;

  // Variables pour la navigation cible depuis les notes
  String? _targetBook;
  int? _targetChapter;
  int? _targetVerse;

  // Index de l'onglet actuel (géré par TabController)

  // Variables pour l'onglet Notes - reproduction exacte de perfect 13
  String _currentFilter = 'all'; // 'all', 'notes', 'highlights'
  String _notesSearchQuery = '';
  final TextEditingController _notesSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // MD3: Créer un TabController interne seulement si non fourni par le wrapper
    if (widget.tabController == null) {
      _internalTabController = TabController(length: 3, vsync: this);
    }
    final tabController = _tabController; // Utiliser le getter
    tabController.addListener(() {
      // Forcer le rechargement des préférences quand on change d'onglet
      if (tabController.index == 3) {
        // Onglet Notes (index 3)
        print(
          'DEBUG: Changement vers onglet Notes, rechargement des préférences...',
        );
        _forceReloadPrefs();
      } else if (tabController.index == 0) {
        // Onglet Lecture (index 0)
        print(
          'DEBUG: Changement vers onglet Lecture, rechargement des préférences...',
        );
        _forceReloadPrefs();
      }
    });
    _loadBible();
    _loadPrefs();
  }

  @override
  void dispose() {
    // MD3: Disposer uniquement le TabController interne (pas celui du wrapper)
    _internalTabController?.dispose();
    super.dispose();
  }

  // Méthodes utilitaires pour l'historique et les marque-pages
  Future<List<Map<String, dynamic>>> _getReadingHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyString = prefs.getString('bible_reading_history') ?? '[]';
    List<dynamic> history = jsonDecode(historyString);

    // Trier par timestamp décroissant (plus récent en premier)
    history.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

    // Limiter à 50 entrées
    if (history.length > 50) {
      history = history.take(50).toList();
      await prefs.setString('bible_reading_history', jsonEncode(history));
    }

    return history.cast<Map<String, dynamic>>();
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} jour${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} heure${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'À l\'instant';
    }
  }

  Future<void> _clearReadingHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('bible_reading_history');
  }

  void _showBookmarks() {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        ),
        title: Row(
          children: [
            Icon(Icons.bookmarks_rounded, color: colorScheme.primary, size: 24),
            const SizedBox(width: AppTheme.space12),
            Text(
              'Mes marque-pages',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize20,
                fontWeight: AppTheme.fontSemiBold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _getBookmarks(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: colorScheme.primary),
                );
              }

              final bookmarks = snapshot.data ?? [];

              if (bookmarks.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bookmarks_rounded,
                        size: 64,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceMedium),
                      Text(
                        'Aucun marque-page',
                        style: GoogleFonts.inter(
                          fontSize: AppTheme.fontSize18,
                          fontWeight: AppTheme.fontSemiBold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceSmall),
                      Text(
                        'Vos chapitres favoris apparaîtront ici',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: AppTheme.fontSize14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: bookmarks.length,
                itemBuilder: (context, index) {
                  final bookmark = bookmarks[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: 1,
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.3,
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(AppTheme.spaceSmall),
                        decoration: BoxDecoration(
                          color: colorScheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMedium,
                          ),
                        ),
                        child: Icon(
                          Icons.bookmark_rounded,
                          color: colorScheme.onTertiaryContainer,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        '${bookmark['book']} ${bookmark['chapter']}',
                        style: GoogleFonts.inter(
                          fontSize: AppTheme.fontSize16,
                          fontWeight: AppTheme.fontSemiBold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: colorScheme.error,
                          size: 20,
                        ),
                        onPressed: () async {
                          await _removeBookmark(bookmark['key']);
                          Navigator.of(context).pop();
                          _showBookmarks(); // Rafraîchir
                        },
                      ),
                      onTap: () {
                        setState(() {
                          _selectedBook = bookmark['book'];
                          _selectedChapter = bookmark['chapter'];
                          _tabController.index = 0; // Aller à l'onglet lecture
                        });
                        Navigator.of(context).pop();
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Fermer',
              style: GoogleFonts.inter(
                fontWeight: AppTheme.fontMedium,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarksString = prefs.getString('bible_bookmarks') ?? '[]';
    return List<Map<String, dynamic>>.from(jsonDecode(bookmarksString));
  }

  Future<void> _removeBookmark(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarksString = prefs.getString('bible_bookmarks') ?? '[]';
    List<dynamic> bookmarks = jsonDecode(bookmarksString);

    bookmarks.removeWhere((b) => b['key'] == key);
    await prefs.setString('bible_bookmarks', jsonEncode(bookmarks));
  }

  // Méthode pour montrer un hint la première fois
  void _showFirstTimeHint() {
    const String hintKey = 'first_time_verse_hint_shown';
    SharedPreferences.getInstance().then((prefs) {
      if (!(prefs.getBool(hintKey) ?? false)) {
        prefs.setBool(hintKey, true);

        // Petite animation pour attirer l'attention
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: AppTheme.warning,
                      size: 20,
                    ),
                    const SizedBox(width: AppTheme.spaceSmall),
                    Expanded(
                      child: Text(
                        'Tapez sur un verset pour accéder aux notes, favoris et surlignements !',
                        style: GoogleFonts.inter(
                          fontSize: AppTheme.fontSize13,
                          fontWeight: AppTheme.fontMedium,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppTheme.primaryColor,
                duration: const Duration(seconds: 4),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                margin: const EdgeInsets.all(AppTheme.spaceLarge),
              ),
            );
          }
        });
      }
    });
  }

  void _performAdvancedSearch(
    String query,
    String selectedBook,
    bool exactMatch,
    bool caseSensitive,
  ) async {
    final colorScheme = Theme.of(context).colorScheme;

    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: colorScheme.primary),
            const SizedBox(height: AppTheme.spaceMedium),
            Text(
              'Recherche en cours...',
              style: GoogleFonts.inter(color: colorScheme.onSurface),
            ),
          ],
        ),
      ),
    );

    try {
      // Pour l'instant, utilisation de la recherche basique jusqu'à ce que advancedSearch soit implémentée
      final results = await _bibleService.search(query);

      Navigator.of(context).pop(); // Fermer le loading

      // Afficher les résultats
      _showSearchResults(query, results);
    } catch (e) {
      Navigator.of(context).pop(); // Fermer le loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur de recherche: $e',
            style: GoogleFonts.inter(
              fontWeight: AppTheme.fontMedium,
              color: colorScheme.onError,
            ),
          ),
          backgroundColor: colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        ),
      );
    }
  }

  void _showSearchResults(String query, List<BibleVerse> results) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        ),
        title: Row(
          children: [
            Icon(Icons.search_rounded, color: colorScheme.primary, size: 24),
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: Text(
                'Résultats pour "$query"',
                style: GoogleFonts.inter(
                  fontSize: AppTheme.fontSize18,
                  fontWeight: AppTheme.fontSemiBold,
                  color: colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 500,
          child: results.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 64,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceMedium),
                      Text(
                        'Aucun résultat',
                        style: GoogleFonts.inter(
                          fontSize: AppTheme.fontSize18,
                          fontWeight: AppTheme.fontSemiBold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceSmall),
                      Text(
                        'Essayez avec d\'autres termes',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: AppTheme.fontSize14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        '${results.length} résultat${results.length > 1 ? 's' : ''} trouvé${results.length > 1 ? 's' : ''}',
                        style: GoogleFonts.inter(
                          fontSize: AppTheme.fontSize14,
                          fontWeight: AppTheme.fontMedium,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final verse = results[index];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 1,
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            child: Padding(
                              padding: const EdgeInsets.all(
                                AppTheme.spaceMedium,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colorScheme.primaryContainer,
                                          borderRadius: BorderRadius.circular(
                                            AppTheme.radiusSmall,
                                          ),
                                        ),
                                        child: Text(
                                          '${verse.book} ${verse.chapter}:${verse.verse}',
                                          style: GoogleFonts.inter(
                                            fontSize: AppTheme.fontSize12,
                                            fontWeight: AppTheme.fontMedium,
                                            color:
                                                colorScheme.onPrimaryContainer,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        icon: Icon(
                                          Icons.share_rounded,
                                          color: colorScheme.primary,
                                          size: 18,
                                        ),
                                        onPressed: () => _shareVerse(verse),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppTheme.spaceSmall),
                                  Text(
                                    verse.text,
                                    style: GoogleFonts.inter(
                                      fontSize: AppTheme.fontSize14,
                                      height: 1.4,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Fermer',
              style: GoogleFonts.inter(
                fontWeight: AppTheme.fontMedium,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadBible() async {
    await _bibleService.getBooks();
    _pickVerseOfTheDay();
    setState(() {
      _isLoading = false;
    });
  }

  // Enregistrer dans l'historique de lecture
  Future<void> _addToReadingHistory(String book, int chapter) async {
    final prefs = await SharedPreferences.getInstance();
    final historyString = prefs.getString('bible_reading_history') ?? '[]';
    List<dynamic> history = jsonDecode(historyString);

    // Supprimer les entrées existantes pour ce chapitre
    history.removeWhere(
      (item) => item['book'] == book && item['chapter'] == chapter,
    );

    // Ajouter la nouvelle entrée au début
    history.insert(0, {
      'book': book,
      'chapter': chapter,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    // Limiter à 50 entrées
    if (history.length > 50) {
      history = history.take(50).toList();
    }

    await prefs.setString('bible_reading_history', jsonEncode(history));
  }

  Future<void> _loadPrefs() async {
    print('DEBUG: Chargement des préférences...');
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favorites = prefs.getStringList('bible_favorites')?.toSet() ?? {};

      // Charger les surlignements avec couleurs
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
          _highlights[highlight] = Colors.yellow;
        }
      }

      _fontSize = prefs.getDouble('bible_font_size') ?? 16.0;
      _isDarkMode = prefs.getBool('bible_dark_mode') ?? false;
      final notesString = prefs.getString('bible_notes') ?? '{}';
      _notes = Map<String, String>.from(jsonDecode(notesString));
      _lineHeight = prefs.getDouble('bible_line_height') ?? 1.5;
      _fontFamily = prefs.getString('bible_font_family') ?? '';
      final colorValue = prefs.getInt('bible_custom_bg_color');
      _customBgColor = colorValue != null ? Color(colorValue) : null;
    });
    print(
      'DEBUG: Préférences chargées - Favoris: ${_favorites.length}, Surlignements: ${_highlights.length}, Notes: ${_notes.length}',
    );
  }

  Future<void> _savePrefs() async {
    print('DEBUG: Sauvegarde des préférences...');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('bible_favorites', _favorites.toList());

    // Sauvegarder les surlignements avec leurs couleurs
    final highlightsList = _highlights.entries
        .map((entry) => '${entry.key}:${entry.value.value}')
        .toList();
    await prefs.setStringList('bible_highlights', highlightsList);

    await prefs.setDouble('bible_font_size', _fontSize);
    await prefs.setBool('bible_dark_mode', _isDarkMode);
    await prefs.setString('bible_font_family', _fontFamily);
    await prefs.setDouble('bible_line_height', _lineHeight);
    await prefs.setString('bible_notes', jsonEncode(_notes));
    if (_customBgColor != null) {
      await prefs.setInt('bible_custom_bg_color', _customBgColor!.value);
    }
    print(
      'DEBUG: Préférences sauvegardées - Favoris: ${_favorites.length}, Surlignements: ${_highlights.length}, Notes: ${_notes.length}',
    );
  }

  void _editNoteDialog(BibleVerse v) {
    final key = _verseKey(v);
    final controller = TextEditingController(text: _notes[key] ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Note pour ${v.book} ${v.chapter}:${v.verse}'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: TextField(
            controller: controller,
            maxLines: 4,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Écris ta note ici...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide(color: AppTheme.primaryColor),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: AppTheme.white100,
            ),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _onSearch(String query) async {
    setState(() {
      _searchQuery = query;
    });

    // Recherche avancée :
    final refReg = RegExp(r'^(\w+)\s*(\d+):(\d+)$');
    final match = refReg.firstMatch(query.trim());
    if (match != null) {
      // Recherche par référence (ex: Jean 3:16)
      final book = match.group(1)!;
      final chapter = int.tryParse(match.group(2)!);
      final verse = int.tryParse(match.group(3)!);
      if (chapter != null && verse != null) {
        final found = _bibleService.books
            .where((b) => b.name.toLowerCase().contains(book.toLowerCase()))
            .toList();
        if (found.isNotEmpty) {
          final b = found.first;
          if (chapter > 0 &&
              chapter <= b.chapters.length &&
              verse > 0 &&
              verse <= b.chapters[chapter - 1].length) {
            setState(() {
              _searchResults = [
                BibleVerse(
                  book: b.name,
                  chapter: chapter,
                  verse: verse,
                  text: b.chapters[chapter - 1][verse - 1],
                ),
              ];
            });
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
      final results = await _bibleService.search(phrase);
      setState(() {
        _searchResults = results.where((v) => v.text.contains(phrase)).toList();
      });
      return;
    }
    // Recherche par mot-clé classique
    final results = await _bibleService.search(query);
    setState(() {
      _searchResults = results;
    });
  }

  void _toggleFavorite(BibleVerse v) async {
    final key = _verseKey(v);
    print('DEBUG _toggleFavorite: $key');
    print('DEBUG: Favorites avant toggle: ${_favorites.toList()}');

    setState(() {
      if (_favorites.contains(key)) {
        _favorites.remove(key);
        print('DEBUG: Favori retiré: $key');
      } else {
        _favorites.add(key);
        print('DEBUG: Favori ajouté: $key');
      }
    });
    print('DEBUG: Total favoris après toggle: ${_favorites.length}');
    print('DEBUG: Favorites après toggle: ${_favorites.toList()}');

    // Forcer la sauvegarde immédiate
    await _savePrefs();

    // Vérifier que la sauvegarde a bien fonctionné
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('bible_favorites') ?? [];
    print('DEBUG: Favorites sauvegardés dans SharedPreferences: $saved');
  }

  void _toggleHighlight(BibleVerse v) async {
    final key = _verseKey(v);
    print('DEBUG _toggleHighlight: $key');
    print('DEBUG: Highlights avant toggle: ${_highlights.keys.toList()}');

    setState(() {
      if (_highlights.containsKey(key)) {
        _highlights.remove(key);
        print('DEBUG: Surlignement retiré: $key');
      } else {
        _highlights[key] = Colors.yellow; // Couleur par défaut
        print('DEBUG: Surlignement ajouté: $key');
      }
    });
    print('DEBUG: Total surlignements après toggle: ${_highlights.length}');
    print('DEBUG: Highlights après toggle: ${_highlights.keys.toList()}');

    // Forcer la sauvegarde immédiate
    await _savePrefs();

    // Vérifier que la sauvegarde a bien fonctionné
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('bible_highlights') ?? [];
    print('DEBUG: Highlights sauvegardés dans SharedPreferences: $saved');
  }

  void _pickVerseOfTheDay() {
    final allVerses = <BibleVerse>[];
    for (final book in _bibleService.books) {
      for (int c = 0; c < book.chapters.length; c++) {
        for (int v = 0; v < book.chapters[c].length; v++) {
          allVerses.add(
            BibleVerse(
              book: book.name,
              chapter: c + 1,
              verse: v + 1,
              text: book.chapters[c][v],
            ),
          );
        }
      }
    }
    // Code for verse of the day removed - feature not used
  }

  String _verseKey(BibleVerse v) => '${v.book}_${v.chapter}_${v.verse}';

  // Méthode pour forcer le rechargement des données depuis SharedPreferences
  Future<void> _forceReloadPrefs() async {
    print('DEBUG: Force reload des préférences...');
    await _loadPrefs();
    print(
      'DEBUG: Après force reload - Favoris: ${_favorites.length}, Surlignements: ${_highlights.length}, Notes: ${_notes.length}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = _isDarkMode
        ? ThemeData.dark().copyWith(
            colorScheme: AppTheme.lightTheme.colorScheme.copyWith(
              brightness: Brightness.dark,
            ),
            textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
          )
        : AppTheme.lightTheme;
    if (_isLoading) {
      // Shimmer premium sur l’accueil Bible
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: Center(
          child: Shimmer.fromColors(
            baseColor: theme.colorScheme.surfaceContainerHighest,
            highlightColor: theme.colorScheme.primary.withValues(alpha: 0.12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 220,
                  height: 32,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                const SizedBox(height: AppTheme.space18),
                Container(
                  width: 320,
                  height: 120,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(
                      AppTheme.radiusCircular,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.space18),
                Container(
                  width: 180,
                  height: 18,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Theme(data: theme, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    // MD3: Si TabController fourni par wrapper, pas besoin de Scaffold
    final body = Column(
      children: [
        // MD3: Afficher le TabBar seulement si non fourni par le wrapper
        if (widget.tabController == null) ...[
          // TabBar intégrée - Style MD3 avec fond Surface (clair)
          Container(
            color: AppTheme.surface, // MD3: Fond clair comme l'AppBar
            child: TabBar(
              controller: _tabController,
              // Les couleurs sont héritées du TabBarTheme (primaryColor pour actif, gris pour inactif)
              tabs: const [
                Tab(icon: Icon(Icons.menu_book_rounded), text: 'La Bible'),
                Tab(
                  icon: Icon(Icons.library_books_rounded),
                  text: 'Ressources',
                ),
                Tab(icon: Icon(Icons.bookmark_rounded), text: 'Notes'),
              ],
            ),
          ),

          // Divider subtil MD3
          Divider(
            height: 1,
            thickness: 1,
            color: AppTheme.grey300.withOpacity(0.5),
          ),
        ],
        // TabBarView - Style identique au module Vie de l'église
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              BibleReadingView(
                isAdminMode: false,
                targetBook: _targetBook,
                targetChapter: _targetChapter,
                targetVerse: _targetVerse,
              ),
              _buildHomeTab(),
              _buildNotesAndHighlightsTab(),
            ],
          ),
        ),
      ],
    );

    // MD3: Si dans le wrapper, retourner directement le body
    if (widget.tabController != null) {
      return body;
    }

    // MD3: Si standalone, envelopper dans Scaffold (déjà fait au-dessus)
    return body;
  }

  Widget _buildHomeTab() {
    return const BibleHomeView();
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
          color: isActive ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? color.withValues(alpha: 0.3)
                : AppTheme.grey500.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? color : AppTheme.grey600, size: 16),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: AppTheme.fontMedium,
                color: isActive ? color : AppTheme.grey600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Méthodes d'actions supplémentaires
  void _showReadingSettings() {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        ),
        title: Row(
          children: [
            Icon(Icons.settings_rounded, color: colorScheme.primary, size: 24),
            const SizedBox(width: AppTheme.space12),
            Text(
              'Paramètres de lecture',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize20,
                fontWeight: AppTheme.fontSemiBold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Taille de police
              Text(
                'Taille de police',
                style: GoogleFonts.inter(
                  fontSize: AppTheme.fontSize16,
                  fontWeight: AppTheme.fontSemiBold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppTheme.spaceSmall),
              Row(
                children: [
                  Text(
                    'A',
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: _fontSize,
                      min: 12.0,
                      max: 24.0,
                      divisions: 12,
                      activeColor: colorScheme.primary,
                      onChanged: (value) {
                        setState(() {
                          _fontSize = value;
                        });
                        _savePrefs();
                      },
                    ),
                  ),
                  Text(
                    'A',
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceMedium),

              // Interligne
              Text(
                'Interligne',
                style: GoogleFonts.inter(
                  fontSize: AppTheme.fontSize16,
                  fontWeight: AppTheme.fontSemiBold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppTheme.spaceSmall),
              Slider(
                value: _lineHeight,
                min: 1.0,
                max: 2.5,
                divisions: 15,
                activeColor: colorScheme.primary,
                label: _lineHeight.toStringAsFixed(1),
                onChanged: (value) {
                  setState(() {
                    _lineHeight = value;
                  });
                  _savePrefs();
                },
              ),
              const SizedBox(height: AppTheme.spaceMedium),

              // Mode sombre
              SwitchListTile(
                title: Text(
                  'Mode sombre',
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize16,
                    fontWeight: AppTheme.fontMedium,
                    color: colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  'Interface sombre pour la lecture',
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                value: _isDarkMode,
                activeThumbColor: colorScheme.primary,
                onChanged: (value) {
                  setState(() {
                    _isDarkMode = value;
                  });
                  _savePrefs();
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Fermer',
              style: GoogleFonts.inter(
                fontWeight: AppTheme.fontMedium,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReadingHistory() {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        ),
        title: Row(
          children: [
            Icon(Icons.history_rounded, color: colorScheme.primary, size: 24),
            const SizedBox(width: AppTheme.space12),
            Text(
              'Historique de lecture',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize20,
                fontWeight: AppTheme.fontSemiBold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _getReadingHistory(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: colorScheme.primary),
                );
              }

              final history = snapshot.data ?? [];

              if (history.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 64,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceMedium),
                      Text(
                        'Aucun historique',
                        style: GoogleFonts.inter(
                          fontSize: AppTheme.fontSize18,
                          fontWeight: AppTheme.fontSemiBold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceSmall),
                      Text(
                        'Vos lectures récentes apparaîtront ici',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: AppTheme.fontSize14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final item = history[index];
                  final timestamp = DateTime.fromMillisecondsSinceEpoch(
                    item['timestamp'],
                  );
                  final timeAgo = _getTimeAgo(timestamp);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: 1,
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.3,
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(AppTheme.spaceSmall),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMedium,
                          ),
                        ),
                        child: Icon(
                          Icons.menu_book_rounded,
                          color: colorScheme.onPrimaryContainer,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        '${item['book']} ${item['chapter']}',
                        style: GoogleFonts.inter(
                          fontSize: AppTheme.fontSize16,
                          fontWeight: AppTheme.fontSemiBold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        timeAgo,
                        style: GoogleFonts.inter(
                          fontSize: AppTheme.fontSize14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: colorScheme.onSurfaceVariant,
                        size: 16,
                      ),
                      onTap: () {
                        setState(() {
                          _selectedBook = item['book'];
                          _selectedChapter = item['chapter'];
                          _tabController.index = 0; // Aller à l'onglet lecture
                        });
                        Navigator.of(context).pop();
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _clearReadingHistory();
              Navigator.of(context).pop();
            },
            child: Text(
              'Effacer tout',
              style: GoogleFonts.inter(
                fontWeight: AppTheme.fontMedium,
                color: colorScheme.error,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Fermer',
              style: GoogleFonts.inter(
                fontWeight: AppTheme.fontMedium,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _bookmarkCurrentChapter() async {
    if (_selectedBook != null && _selectedChapter != null) {
      final colorScheme = Theme.of(context).colorScheme;
      final prefs = await SharedPreferences.getInstance();

      // Récupérer les marque-pages existants
      final bookmarksString = prefs.getString('bible_bookmarks') ?? '[]';
      List<dynamic> bookmarks = jsonDecode(bookmarksString);

      final bookmarkKey = '${_selectedBook}_$_selectedChapter';
      final bookmarkExists = bookmarks.any((b) => b['key'] == bookmarkKey);

      if (bookmarkExists) {
        // Supprimer le marque-page
        bookmarks.removeWhere((b) => b['key'] == bookmarkKey);
        await prefs.setString('bible_bookmarks', jsonEncode(bookmarks));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.bookmark_remove_rounded,
                  color: colorScheme.onInverseSurface,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.spaceSmall),
                Text(
                  'Marque-page supprimé',
                  style: GoogleFonts.inter(
                    fontWeight: AppTheme.fontMedium,
                    color: colorScheme.onInverseSurface,
                  ),
                ),
              ],
            ),
            backgroundColor: colorScheme.inverseSurface,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
          ),
        );
      } else {
        // Ajouter le marque-page
        final newBookmark = {
          'key': bookmarkKey,
          'book': _selectedBook,
          'chapter': _selectedChapter,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };

        bookmarks.add(newBookmark);
        await prefs.setString('bible_bookmarks', jsonEncode(bookmarks));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.bookmark_add_rounded,
                  color: colorScheme.onInverseSurface,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.spaceSmall),
                Text(
                  'Chapitre $_selectedBook $_selectedChapter marqué',
                  style: GoogleFonts.inter(
                    fontWeight: AppTheme.fontMedium,
                    color: colorScheme.onInverseSurface,
                  ),
                ),
              ],
            ),
            backgroundColor: colorScheme.inverseSurface,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            action: SnackBarAction(
              label: 'Voir tous',
              textColor: colorScheme.primary,
              onPressed: _showBookmarks,
            ),
          ),
        );
      }
    }
  }

  void _shareVerse(BibleVerse verse) async {
    try {
      final colorScheme = Theme.of(context).colorScheme;

      // Formatage du texte à partager
      final shareText =
          '''"${verse.text}"

${verse.book} ${verse.chapter}:${verse.verse}

Partagé depuis l'app Jubilé Tabernacle''';

      // Utilisation du Clipboard pour copier (alternative au share_plus)
      await Clipboard.setData(ClipboardData(text: shareText));

      // Affichage d'une confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.content_copy_rounded,
                color: colorScheme.onInverseSurface,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spaceSmall),
              Expanded(
                child: Text(
                  'Verset copié dans le presse-papiers',
                  style: GoogleFonts.inter(
                    fontWeight: AppTheme.fontMedium,
                    color: colorScheme.onInverseSurface,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: colorScheme.inverseSurface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      // Alternative: utiliser le partage natif si share_plus est disponible
      /*
      import 'package:share_plus/share_plus.dart';
      
      await Share.share(
        shareText,
        subject: '${verse.book} ${verse.chapter}:${verse.verse}',
      );
      */
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur lors du partage: $e',
            style: GoogleFonts.inter(
              fontWeight: AppTheme.fontMedium,
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        ),
      );
    }
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.white100,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  border: Border.all(
                    color: AppTheme.grey500.withValues(alpha: 0.2),
                  ),
                ),
                child: DropdownButton<String>(
                  value: _selectedBookFilter,
                  hint: Row(
                    children: [
                      Icon(Icons.book, color: AppTheme.grey600, size: 20),
                      const SizedBox(width: AppTheme.spaceSmall),
                      Text(
                        'Tous les livres',
                        style: GoogleFonts.inter(
                          fontSize: AppTheme.fontSize14,
                          color: AppTheme.grey600,
                          fontWeight: AppTheme.fontMedium,
                        ),
                      ),
                    ],
                  ),
                  underline: const SizedBox(),
                  isExpanded: true,
                  icon: Icon(Icons.arrow_drop_down, color: AppTheme.grey600),
                  items: [
                    DropdownMenuItem<String>(
                      value: '',
                      child: Row(
                        children: [
                          const Icon(Icons.all_inclusive, size: 20),
                          const SizedBox(width: AppTheme.spaceSmall),
                          Text(
                            'Tous les livres',
                            style: GoogleFonts.inter(
                              fontSize: AppTheme.fontSize14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ..._bibleService.books
                        .map(
                          (book) => DropdownMenuItem<String>(
                            value: book.name,
                            child: Text(
                              book.name,
                              style: GoogleFonts.inter(
                                fontSize: AppTheme.fontSize14,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ],
                  onChanged: (value) {
                    setStateSB(() {
                      _selectedBookFilter = (value != null && value.isNotEmpty)
                          ? value
                          : null;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(width: AppTheme.space12),

            // Bouton de recherche avancée
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.grey500, AppTheme.grey600],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.blueStandard.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  onTap: () => _showAdvancedSearchDialog(),
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.space12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.tune,
                          color: AppTheme.white100,
                          size: 20,
                        ),
                        const SizedBox(width: AppTheme.spaceSmall),
                        Text(
                          'Avancé',
                          style: GoogleFonts.inter(
                            fontSize: AppTheme.fontSize14,
                            color: AppTheme.white100,
                            fontWeight: AppTheme.fontSemiBold,
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
      {'text': 'amour', 'icon': Icons.favorite, 'color': AppTheme.redStandard},
      {'text': 'paix', 'icon': Icons.spa, 'color': AppTheme.greenStandard},
      {
        'text': 'sagesse',
        'icon': Icons.psychology,
        'color': AppTheme.primaryColor,
      },
      {'text': 'espoir', 'icon': Icons.star, 'color': AppTheme.warningColor},
      {
        'text': 'Jean 3:16',
        'icon': Icons.auto_stories,
        'color': AppTheme.blueStandard,
      },
      {
        'text': 'Psaume 23',
        'icon': Icons.music_note,
        'color': AppTheme.orangeStandard,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppTheme.spaceMedium),
        Text(
          'Suggestions de recherche',
          style: GoogleFonts.poppins(
            fontSize: AppTheme.fontSize16,
            fontWeight: AppTheme.fontSemiBold,
            color: AppTheme.grey700,
          ),
        ),
        const SizedBox(height: AppTheme.space12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestions
              .map(
                (suggestion) => InkWell(
                  onTap: () => _onSearch(suggestion['text'] as String),
                  borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: (suggestion['color'] as Color).withValues(
                        alpha: 0.1,
                      ),
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusXLarge,
                      ),
                      border: Border.all(
                        color: (suggestion['color'] as Color).withValues(
                          alpha: 0.3,
                        ),
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
                        const SizedBox(width: AppTheme.space6),
                        Text(
                          suggestion['text'] as String,
                          style: GoogleFonts.inter(
                            fontSize: AppTheme.fontSize13,
                            fontWeight: AppTheme.fontMedium,
                            color: suggestion['color'] as Color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildQuickSearchCards() {
    final quickSearches = [
      {
        'title': 'Versets célèbres',
        'description': 'Jean 3:16, Psaume 23:1',
        'icon': Icons.star,
        'color': AppTheme.warningColor,
        'searches': ['Jean 3:16', 'Psaume 23:1', 'Matthieu 5:3-12'],
      },
      {
        'title': 'Thèmes spirituels',
        'description': 'Amour, paix, espoir',
        'icon': Icons.favorite,
        'color': AppTheme.redStandard,
        'searches': ['amour', 'paix', 'espoir', 'foi'],
      },
      {
        'title': 'Sagesse',
        'description': 'Proverbes et conseils',
        'icon': Icons.psychology,
        'color': AppTheme.primaryColor,
        'searches': ['sagesse', 'conseil', 'prudence'],
      },
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: quickSearches
          .map(
            (search) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: InkWell(
                  onTap: () {
                    final searches = search['searches'] as List<String>;
                    _onSearch(searches.first);
                  },
                  borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                  child: Container(
                    padding: const EdgeInsets.all(AppTheme.space20),
                    decoration: BoxDecoration(
                      color: (search['color'] as Color).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusXLarge,
                      ),
                      border: Border.all(
                        color: (search['color'] as Color).withValues(
                          alpha: 0.2,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppTheme.space12),
                          decoration: BoxDecoration(
                            color: search['color'] as Color,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusLarge,
                            ),
                          ),
                          child: Icon(
                            search['icon'] as IconData,
                            color: AppTheme.white100,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: AppTheme.space12),
                        Text(
                          search['title'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: AppTheme.fontSize14,
                            fontWeight: AppTheme.fontSemiBold,
                            color: AppTheme.grey700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppTheme.spaceXSmall),
                        Text(
                          search['description'] as String,
                          style: GoogleFonts.inter(
                            fontSize: AppTheme.fontSize12,
                            color: AppTheme.grey500,
                            height: 1.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildModernVerseCard(BibleVerse verse, int index) {
    final key = _verseKey(verse);
    final isFav = _favorites.contains(key);
    final isHighlight = _highlights.containsKey(key);
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
              ? AppTheme.primaryColor.withValues(alpha: 0.08)
              : AppTheme.white100,
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          border: isHighlight
              ? Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  width: 2,
                )
              : Border.all(color: AppTheme.grey500.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.black100.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              _selectedVerseKey = (_selectedVerseKey == key) ? null : key;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête du verset
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Numéro du verset
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.grey400, AppTheme.grey500],
                        ),
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMedium,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.blueStandard.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '${verse.verse}',
                        style: GoogleFonts.poppins(
                          fontSize: AppTheme.fontSize14,
                          fontWeight: AppTheme.fontBold,
                          color: AppTheme.white100,
                        ),
                      ),
                    ),

                    const SizedBox(width: AppTheme.spaceMedium),

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
                                    fontWeight: AppTheme.fontMedium,
                                    color: AppTheme.grey800,
                                  )
                                : GoogleFonts.crimsonText(
                                    fontSize: _fontSize + 2,
                                    height: _lineHeight,
                                    fontWeight: AppTheme.fontMedium,
                                    color: AppTheme.grey800,
                                  ),
                          ),

                          const SizedBox(height: AppTheme.space12),

                          // Référence avec badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.blueStandard.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusXLarge,
                              ),
                            ),
                            child: Text(
                              '${verse.book} ${verse.chapter}:${verse.verse}',
                              style: GoogleFonts.inter(
                                fontSize: AppTheme.fontSize12,
                                color: AppTheme.grey700,
                                fontWeight: AppTheme.fontSemiBold,
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
                            padding: const EdgeInsets.all(AppTheme.space6),
                            decoration: BoxDecoration(
                              color: AppTheme.warning.withAlpha(25),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.star,
                              size: 16,
                              color: AppTheme.warning,
                            ),
                          ),
                        if (note != null && note.isNotEmpty) ...[
                          const SizedBox(height: AppTheme.spaceXSmall),
                          Container(
                            padding: const EdgeInsets.all(AppTheme.space6),
                            decoration: BoxDecoration(
                              color: AppTheme.greenStandard.withValues(
                                alpha: 0.1,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.sticky_note_2,
                              size: 16,
                              color: AppTheme.grey700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),

                // Note si présente
                if (note != null && note.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spaceMedium),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppTheme.spaceMedium),
                    decoration: BoxDecoration(
                      color: AppTheme.greenStandard.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusMedium,
                      ),
                      border: Border.all(
                        color: AppTheme.greenStandard.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.sticky_note_2,
                          color: AppTheme.grey700,
                          size: 18,
                        ),
                        const SizedBox(width: AppTheme.space12),
                        Expanded(
                          child: Text(
                            note,
                            style: GoogleFonts.inter(
                              fontSize: AppTheme.fontSize14,
                              color: AppTheme.grey700,
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
                  const SizedBox(height: AppTheme.space20),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spaceMedium),
                    decoration: BoxDecoration(
                      color: AppTheme.grey500.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildVerseAction(
                          icon: isFav ? Icons.star : Icons.star_border,
                          label: isFav ? 'Favori' : 'Favoris',
                          color: AppTheme.warning,
                          isActive: isFav,
                          onTap: () => _toggleFavorite(verse),
                        ),
                        _buildVerseAction(
                          icon: isHighlight
                              ? Icons.highlight_off
                              : Icons.highlight,
                          label: isHighlight ? 'Surligné' : 'Surligner',
                          color: AppTheme.primaryColor,
                          isActive: isHighlight,
                          onTap: () => _toggleHighlight(verse),
                        ),
                        _buildVerseAction(
                          icon: Icons.sticky_note_2,
                          label: note != null && note.isNotEmpty
                              ? 'Éditer'
                              : 'Note',
                          color: AppTheme.grey700,
                          isActive: note != null && note.isNotEmpty,
                          onTap: () => _editNoteDialog(verse),
                        ),
                        _buildVerseAction(
                          icon: Icons.share,
                          label: 'Partager',
                          color: AppTheme.grey700,
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
            padding: const EdgeInsets.all(AppTheme.spaceLarge),
            decoration: BoxDecoration(
              color: AppTheme.orangeStandard.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.search_off, size: 64, color: AppTheme.grey300),
          ),
          const SizedBox(height: AppTheme.spaceLarge),
          Text(
            'Aucun résultat trouvé',
            style: GoogleFonts.poppins(
              fontSize: AppTheme.fontSize24,
              fontWeight: AppTheme.fontBold,
              color: AppTheme.grey700,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Text(
            'Essayez avec d\'autres mots-clés\nou vérifiez l\'orthographe',
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize16,
              color: AppTheme.grey500,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spaceXLarge),
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
              backgroundColor: AppTheme.grey600,
              foregroundColor: AppTheme.white100,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAdvancedSearchDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    String searchQuery = '';
    String selectedBook = 'Tous les livres';
    bool exactMatch = false;
    bool caseSensitive = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          ),
          title: Row(
            children: [
              Icon(Icons.search_rounded, color: colorScheme.primary, size: 24),
              const SizedBox(width: AppTheme.space12),
              Text(
                'Recherche avancée',
                style: GoogleFonts.inter(
                  fontSize: AppTheme.fontSize20,
                  fontWeight: AppTheme.fontSemiBold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Champ de recherche
                TextField(
                  onChanged: (value) => searchQuery = value,
                  style: GoogleFonts.inter(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Terme à rechercher',
                    labelStyle: GoogleFonts.inter(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    hintText: 'Ex: amour, foi, espérance...',
                    hintStyle: GoogleFonts.inter(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.6,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusMedium,
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceMedium),

                // Sélection du livre
                Text(
                  'Livre',
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize16,
                    fontWeight: AppTheme.fontSemiBold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceSmall),
                DropdownButtonFormField<String>(
                  initialValue: selectedBook,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusMedium,
                      ),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 'Tous les livres',
                      child: Text('Tous les livres'),
                    ),
                    ...(_bibleService.books
                        .map(
                          (book) => DropdownMenuItem(
                            value: book.name,
                            child: Text(book.name),
                          ),
                        )
                        .toList()),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedBook = value ?? 'Tous les livres';
                    });
                  },
                ),
                const SizedBox(height: AppTheme.spaceMedium),

                // Options de recherche
                Text(
                  'Options',
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize16,
                    fontWeight: AppTheme.fontSemiBold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceSmall),

                CheckboxListTile(
                  title: Text(
                    'Correspondance exacte',
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize14,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    'Rechercher le terme exact uniquement',
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  value: exactMatch,
                  activeColor: colorScheme.primary,
                  onChanged: (value) {
                    setDialogState(() {
                      exactMatch = value ?? false;
                    });
                  },
                ),

                CheckboxListTile(
                  title: Text(
                    'Respecter la casse',
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize14,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    'Différencier majuscules et minuscules',
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  value: caseSensitive,
                  activeColor: colorScheme.primary,
                  onChanged: (value) {
                    setDialogState(() {
                      caseSensitive = value ?? false;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Annuler',
                style: GoogleFonts.inter(
                  fontWeight: AppTheme.fontMedium,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            FilledButton(
              onPressed: searchQuery.trim().isEmpty
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      _performAdvancedSearch(
                        searchQuery.trim(),
                        selectedBook,
                        exactMatch,
                        caseSensitive,
                      );
                    },
              child: Text(
                'Rechercher',
                style: GoogleFonts.inter(fontWeight: AppTheme.fontMedium),
              ),
            ),
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
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.white100.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: AppTheme.white100.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.white100, size: 20),
            const SizedBox(height: AppTheme.spaceXSmall),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize11,
                color: AppTheme.white100.withValues(alpha: 0.9),
                fontWeight: AppTheme.fontMedium,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoveryCards() {
    final discoveries = [
      {
        'title': 'Explorer la Bible',
        'description': 'Découvrez des versets\ninspirantes',
        'icon': Icons.explore,
        'color': AppTheme.blueStandard,
        'onTap': () => _tabController.animateTo(1),
      },
      {
        'title': 'Rechercher',
        'description': 'Trouvez des passages\npar thème',
        'icon': Icons.search,
        'color': AppTheme.greenStandard,
        'onTap': () => _tabController.animateTo(2),
      },
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: discoveries
          .map(
            (discovery) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                child: InkWell(
                  onTap: discovery['onTap'] as VoidCallback,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                  child: Container(
                    padding: const EdgeInsets.all(AppTheme.spaceLarge),
                    decoration: BoxDecoration(
                      color: (discovery['color'] as Color).withValues(
                        alpha: 0.1,
                      ),
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusXLarge,
                      ),
                      border: Border.all(
                        color: (discovery['color'] as Color).withValues(
                          alpha: 0.2,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (discovery['color'] as Color).withValues(
                            alpha: 0.1,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spaceMedium),
                          decoration: BoxDecoration(
                            color: discovery['color'] as Color,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusLarge,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (discovery['color'] as Color).withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            discovery['icon'] as IconData,
                            color: AppTheme.white100,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceMedium),
                        Text(
                          discovery['title'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: AppTheme.fontSize16,
                            fontWeight: AppTheme.fontSemiBold,
                            color: AppTheme.grey700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppTheme.spaceSmall),
                        Text(
                          discovery['description'] as String,
                          style: GoogleFonts.inter(
                            fontSize: AppTheme.fontSize13,
                            color: AppTheme.grey500,
                            height: 1.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildModernFavoriteCard(BibleVerse verse, int index) {
    final key = _verseKey(verse);
    final isHighlight = _highlights.containsKey(key);
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
            colors: [AppTheme.white100, AppTheme.warningColor.withAlpha(25)],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          border: Border.all(
            color: AppTheme.warningColor.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.warningColor.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              _selectedVerseKey = (_selectedVerseKey == key) ? null : key;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec étoile dorée
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge favori doré
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spaceSmall),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.warningColor,
                            AppTheme.orangeStandard,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMedium,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.warningColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.star,
                        color: AppTheme.white100,
                        size: 20,
                      ),
                    ),

                    const SizedBox(width: AppTheme.spaceMedium),

                    // Numéro du verset
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.warningColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMedium,
                        ),
                      ),
                      child: Text(
                        '${verse.verse}',
                        style: GoogleFonts.poppins(
                          fontSize: AppTheme.fontSize14,
                          fontWeight: AppTheme.fontBold,
                          color: AppTheme.warning,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Indicateurs
                    Column(
                      children: [
                        if (isHighlight)
                          Container(
                            padding: const EdgeInsets.all(AppTheme.space6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.1,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.highlight,
                              size: 16,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        if (note != null && note.isNotEmpty) ...[
                          if (isHighlight)
                            const SizedBox(height: AppTheme.spaceXSmall),
                          Container(
                            padding: const EdgeInsets.all(AppTheme.space6),
                            decoration: BoxDecoration(
                              color: AppTheme.greenStandard.withValues(
                                alpha: 0.1,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.sticky_note_2,
                              size: 16,
                              color: AppTheme.grey700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: AppTheme.spaceMedium),

                // Texte du verset avec style élégant
                Container(
                  padding: const EdgeInsets.all(AppTheme.space20),
                  decoration: BoxDecoration(
                    color: AppTheme.white100,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    border: Border.all(
                      color: AppTheme.warningColor.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icône de citation
                      Icon(
                        Icons.format_quote,
                        color: AppTheme.warning.withAlpha(153),
                        size: 24,
                      ),
                      const SizedBox(height: AppTheme.spaceSmall),
                      Text(
                        verse.text,
                        style: _fontFamily.isNotEmpty
                            ? GoogleFonts.getFont(
                                _fontFamily,
                                fontSize: _fontSize + 2,
                                height: _lineHeight,
                                fontWeight: AppTheme.fontMedium,
                                color: AppTheme.grey800,
                              )
                            : GoogleFonts.crimsonText(
                                fontSize: _fontSize + 4,
                                height: _lineHeight,
                                fontWeight: AppTheme.fontMedium,
                                color: AppTheme.grey800,
                                fontStyle: FontStyle.italic,
                              ),
                      ),
                      const SizedBox(height: AppTheme.spaceMedium),
                      // Référence avec style
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.warning.withAlpha(51),
                                AppTheme.grey100,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusXLarge,
                            ),
                          ),
                          child: Text(
                            '${verse.book} ${verse.chapter}:${verse.verse}',
                            style: GoogleFonts.inter(
                              fontSize: AppTheme.fontSize13,
                              color: AppTheme.warning,
                              fontWeight: AppTheme.fontSemiBold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Note si présente
                if (note != null && note.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spaceMedium),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppTheme.spaceMedium),
                    decoration: BoxDecoration(
                      color: AppTheme.greenStandard.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusMedium,
                      ),
                      border: Border.all(
                        color: AppTheme.greenStandard.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.sticky_note_2,
                          color: AppTheme.grey700,
                          size: 18,
                        ),
                        const SizedBox(width: AppTheme.space12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ma note personnelle',
                                style: GoogleFonts.poppins(
                                  fontSize: AppTheme.fontSize12,
                                  fontWeight: AppTheme.fontSemiBold,
                                  color: AppTheme.grey700,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spaceXSmall),
                              Text(
                                note,
                                style: GoogleFonts.inter(
                                  fontSize: AppTheme.fontSize14,
                                  color: AppTheme.grey600,
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
                  const SizedBox(height: AppTheme.space20),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spaceMedium),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.warning.withAlpha(25),
                          AppTheme.grey50,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildVerseAction(
                          icon: Icons.star,
                          label: 'Retirer',
                          color: AppTheme.grey600,
                          isActive: true,
                          onTap: () => _toggleFavorite(verse),
                        ),
                        _buildVerseAction(
                          icon: isHighlight
                              ? Icons.highlight_off
                              : Icons.highlight,
                          label: isHighlight ? 'Surligné' : 'Surligner',
                          color: AppTheme.primaryColor,
                          isActive: isHighlight,
                          onTap: () => _toggleHighlight(verse),
                        ),
                        _buildVerseAction(
                          icon: Icons.sticky_note_2,
                          label: note != null && note.isNotEmpty
                              ? 'Éditer'
                              : 'Note',
                          color: AppTheme.grey700,
                          isActive: note != null && note.isNotEmpty,
                          onTap: () => _editNoteDialog(verse),
                        ),
                        _buildVerseAction(
                          icon: Icons.share,
                          label: 'Partager',
                          color: AppTheme.grey700,
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
        content: Text(
          'Partage de $count verset${count > 1 ? 's' : ''} favori${count > 1 ? 's' : ''}',
        ),
        backgroundColor: AppTheme.warningColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
      ),
    );
  }

  void _exportFavorites() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Export des favoris (bientôt disponible)'),
        backgroundColor: AppTheme.orangeStandard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.white100,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(AppTheme.space20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.grey300,
                borderRadius: BorderRadius.circular(AppTheme.radius2),
              ),
            ),
            const SizedBox(height: AppTheme.space20),
            Text(
              'Options de tri',
              style: GoogleFonts.poppins(
                fontSize: AppTheme.fontSize18,
                fontWeight: AppTheme.fontBold,
              ),
            ),
            const SizedBox(height: AppTheme.space20),
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

    // Debug: imprimer les données pour diagnostic
    print(
      'DEBUG - Notes count: $totalNotes, Highlights: $totalHighlights, Favorites: $totalFavorites',
    );
    print('DEBUG - Notes keys: ${_notes.keys.toList()}');
    print('DEBUG - Highlights: ${_highlights.keys.toList()}');
    print('DEBUG - Favorites: ${_favorites.toList()}');

    // Filtrer les versets en fonction du filtre et de la recherche actuels
    List<String> filteredVerseKeys = [];

    if (_currentFilter == 'notes') {
      filteredVerseKeys = _notes.keys
          .where((key) => _notes[key]!.isNotEmpty)
          .where(
            (key) =>
                _notesSearchQuery.isEmpty ||
                _getVerseDisplayText(
                  key,
                ).toLowerCase().contains(_notesSearchQuery.toLowerCase()) ||
                _notes[key]!.toLowerCase().contains(
                  _notesSearchQuery.toLowerCase(),
                ),
          )
          .toList();
    } else if (_currentFilter == 'highlights') {
      filteredVerseKeys = _highlights.keys
          .where(
            (key) =>
                _notesSearchQuery.isEmpty ||
                _getVerseDisplayText(
                  key,
                ).toLowerCase().contains(_notesSearchQuery.toLowerCase()),
          )
          .toList();
    } else if (_currentFilter == 'favorites') {
      filteredVerseKeys = _favorites
          .where(
            (key) =>
                _notesSearchQuery.isEmpty ||
                _getVerseDisplayText(
                  key,
                ).toLowerCase().contains(_notesSearchQuery.toLowerCase()),
          )
          .toList();
    } else {
      // Tous
      final noteKeys = _notes.keys.where((key) => _notes[key]!.isNotEmpty);
      final allKeys = {
        ...noteKeys,
        ..._highlights.keys,
        ..._favorites,
      }.toList();
      filteredVerseKeys = allKeys
          .where(
            (key) =>
                _notesSearchQuery.isEmpty ||
                _getVerseDisplayText(
                  key,
                ).toLowerCase().contains(_notesSearchQuery.toLowerCase()) ||
                (_notes[key] ?? '').toLowerCase().contains(
                  _notesSearchQuery.toLowerCase(),
                ),
          )
          .toList();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surface,
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
                    const SizedBox(width: AppTheme.spaceSmall),
                    _buildCompactFilterChip(
                      'notes',
                      'Notes',
                      Icons.note_alt_outlined,
                      totalNotes,
                    ),
                    const SizedBox(width: AppTheme.spaceSmall),
                    _buildCompactFilterChip(
                      'highlights',
                      'Surlignés',
                      Icons.highlight,
                      totalHighlights,
                    ),
                    const SizedBox(width: AppTheme.spaceSmall),
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
              child: SearchBar(
                controller: _notesSearchController,
                onChanged: (value) {
                  setState(() {
                    _notesSearchQuery = value;
                  });
                },
                hintText: 'Rechercher dans vos notes...',
                hintStyle: WidgetStateProperty.all(
                  GoogleFonts.inter(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: AppTheme.fontSize14,
                  ),
                ),
                textStyle: WidgetStateProperty.all(
                  GoogleFonts.inter(
                    color: colorScheme.onSurface,
                    fontSize: AppTheme.fontSize14,
                  ),
                ),
                leading: Icon(
                  Icons.search_rounded,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                trailing: _notesSearchQuery.isNotEmpty
                    ? [
                        IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            color: colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          onPressed: () {
                            _notesSearchController.clear();
                            setState(() {
                              _notesSearchQuery = '';
                            });
                          },
                        ),
                      ]
                    : null,
                backgroundColor: WidgetStateProperty.all(
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                ),
                shadowColor: WidgetStateProperty.all(Colors.transparent),
                elevation: WidgetStateProperty.all(0),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
              ),
            ),
          ),

          // Actions rapides pour les notes
          if (totalNotes > 0 || totalHighlights > 0 || totalFavorites > 0)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: _buildNotesQuickActions(),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: AppTheme.space12)),

          // Liste des versets
          filteredVerseKeys.isEmpty
              ? SliverFillRemaining(child: _buildEmptyNotesState())
              : SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final verseKey = filteredVerseKeys[index];
                    return _buildNoteCard(verseKey);
                  }, childCount: filteredVerseKeys.length),
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

  Widget _buildCompactFilterChip(
    String filterKey,
    String label,
    IconData icon,
    int count,
  ) {
    final isSelected = _currentFilter == filterKey;

    Color getFilterColor(ColorScheme colorScheme) {
      switch (filterKey) {
        case 'notes':
          return colorScheme.tertiary;
        case 'highlights':
          return colorScheme.secondary;
        case 'favorites':
          return colorScheme.error;
        default:
          return colorScheme.primary;
      }
    }

    final colorScheme = Theme.of(context).colorScheme;
    final filterColor = getFilterColor(colorScheme);

    return FilterChip(
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _currentFilter = filterKey;
        });
      },
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected
            ? colorScheme.onSecondaryContainer
            : colorScheme.onSurfaceVariant,
      ),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize13,
              fontWeight: AppTheme.fontSemiBold,
            ),
          ),
          if (count > 0) ...[
            const SizedBox(width: AppTheme.spaceXSmall),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.onSecondaryContainer.withValues(alpha: 0.2)
                    : filterColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: GoogleFonts.inter(
                  fontSize: AppTheme.fontSize11,
                  fontWeight: AppTheme.fontSemiBold,
                  color: isSelected
                      ? colorScheme.onSecondaryContainer
                      : filterColor,
                ),
              ),
            ),
          ],
        ],
      ),
      backgroundColor: colorScheme.surface,
      selectedColor: colorScheme.secondaryContainer,
      checkmarkColor: colorScheme.onSecondaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        side: BorderSide(
          color: isSelected ? filterColor : colorScheme.outline,
          width: 1,
        ),
      ),
    );
  }

  Widget _buildEmptyNotesState() {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _notesSearchQuery.isNotEmpty
                ? Icons.search_off_rounded
                : Icons.sticky_note_2_outlined,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          Text(
            _notesSearchQuery.isNotEmpty
                ? 'Aucun résultat pour "${_notesSearchQuery}"'
                : 'Aucun élément trouvé',
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize18,
              fontWeight: AppTheme.fontSemiBold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Text(
            _notesSearchQuery.isNotEmpty
                ? 'Essayez avec d\'autres mots-clés ou vérifiez l\'orthographe'
                : 'Commencez à prendre des notes ou surligner des versets',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppTheme.spaceLarge),
          // Guide étape par étape
          if (_notesSearchQuery.isEmpty) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(AppTheme.space20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.touch_app_rounded,
                    color: colorScheme.primary,
                    size: 32,
                  ),
                  const SizedBox(height: AppTheme.space12),
                  Text(
                    'Comment créer des notes :',
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize16,
                      fontWeight: AppTheme.fontSemiBold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space12),
                  Text(
                    '1. Allez dans l\'onglet Lecture\n2. Tapez sur un verset\n3. Choisissez "Note", "Favoris" ou "Surligner"\n4. Vos éléments apparaîtront ici !',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize13,
                      height: 1.4,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoteCard(String verseKey) {
    final hasNote =
        _notes.containsKey(verseKey) && _notes[verseKey]!.isNotEmpty;
    final hasHighlight = _highlights.containsKey(verseKey);
    final isFavorite = _favorites.contains(verseKey);

    final colorScheme = Theme.of(context).colorScheme;

    // Couleur principale selon le type - Material Design 3
    Color getCardAccentColor() {
      if (hasNote) return colorScheme.tertiary;
      if (hasHighlight) return colorScheme.secondary;
      if (isFavorite) return colorScheme.error;
      return colorScheme.primary;
    }

    return GestureDetector(
      onTap: () => _goToVerseFromNotes(verseKey),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        elevation: 1,
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          side: BorderSide(
            color: getCardAccentColor().withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec référence et badges
            Container(
              padding: const EdgeInsets.all(AppTheme.space20),
              decoration: BoxDecoration(
                color: getCardAccentColor().withValues(alpha: 0.05),
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
                        fontSize: AppTheme.fontSize16,
                        fontWeight: AppTheme.fontBold,
                        color: getCardAccentColor(),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      if (hasNote)
                        Container(
                          padding: const EdgeInsets.all(AppTheme.space6),
                          decoration: BoxDecoration(
                            color: colorScheme.tertiaryContainer,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusSmall,
                            ),
                          ),
                          child: Icon(
                            Icons.sticky_note_2_rounded,
                            size: 16,
                            color: colorScheme.onTertiaryContainer,
                          ),
                        ),
                      if (hasHighlight) ...[
                        if (hasNote) const SizedBox(width: AppTheme.spaceSmall),
                        Container(
                          padding: const EdgeInsets.all(AppTheme.space6),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusSmall,
                            ),
                          ),
                          child: Icon(
                            Icons.highlight_rounded,
                            size: 16,
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ],
                      if (isFavorite) ...[
                        if (hasNote || hasHighlight)
                          const SizedBox(width: AppTheme.spaceSmall),
                        Container(
                          padding: const EdgeInsets.all(AppTheme.space6),
                          decoration: BoxDecoration(
                            color: colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusSmall,
                            ),
                          ),
                          child: Icon(
                            Icons.favorite_rounded,
                            size: 16,
                            color: colorScheme.onErrorContainer,
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
                  fontSize: AppTheme.fontSize14,
                  color: colorScheme.onSurface,
                  height: 1.5,
                ),
              ),
            ),

            // Note utilisateur si présente
            if (hasNote && _notes[verseKey]!.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                padding: const EdgeInsets.all(AppTheme.spaceMedium),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(
                    color: colorScheme.tertiary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.sticky_note_2_rounded,
                          size: 16,
                          color: colorScheme.tertiary,
                        ),
                        const SizedBox(width: AppTheme.spaceSmall),
                        Text(
                          'Ma note',
                          style: GoogleFonts.inter(
                            fontSize: AppTheme.fontSize12,
                            fontWeight: AppTheme.fontSemiBold,
                            color: colorScheme.tertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spaceSmall),
                    Text(
                      _notes[verseKey]!,
                      style: GoogleFonts.inter(
                        fontSize: AppTheme.fontSize14,
                        color: colorScheme.onSurface,
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
        orElse: () => BibleBook(
          name: bookName,
          abbreviation: '',
          testament: '',
          bookNumber: 0,
          category: '',
          chapters: [],
        ),
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
        _targetBook = bookName;
        _targetChapter = chapterNum;
        _targetVerse = verseNum;
        _tabController.index = 0; // Aller à l'onglet lecture (index 0)
      });

      // Réinitialiser les cibles après un délai pour éviter les conflits futurs
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _targetBook = null;
          _targetChapter = null;
          _targetVerse = null;
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Navigation vers $bookName $chapterNum:$verseNum',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onInverseSurface,
              fontWeight: AppTheme.fontMedium,
            ),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: Theme.of(context).colorScheme.inverseSurface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        ),
      );
    }
  }

  Widget _buildNotesQuickActions() {
    if (_notes.isEmpty && _highlights.isEmpty && _favorites.isEmpty) {
      return const SizedBox.shrink(); // Ne rien afficher s'il n'y a pas d'annotations
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceMedium),
      child: Card(
        elevation: 2,
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.12),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.ios_share_outlined,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: AppTheme.spaceSmall),
                  Text(
                    'Synchronisation Apple Notes',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: AppTheme.fontMedium,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceSmall),
              Text(
                'Partagez vos notes et surlignements avec l\'app Apple Notes',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          final shareService = AppleNotesShareService();
                          // Convertir les highlights (Map<String, Color>) en Map<String, String>
                          final highlightsAsStrings = _highlights.map(
                            (key, value) =>
                                MapEntry(key, value.value.toRadixString(16)),
                          );

                          // Obtenir la position du bouton pour le sharePositionOrigin (iPad)
                          final RenderBox? box =
                              context.findRenderObject() as RenderBox?;
                          final Rect? sharePositionOrigin = box != null
                              ? Rect.fromLTWH(
                                  0,
                                  0,
                                  box.size.width,
                                  box.size.height,
                                )
                              : null;

                          await shareService.shareAllNotesToAppleNotes(
                            notes: _notes,
                            highlights: highlightsAsStrings,
                            favorites: _favorites,
                            sharePositionOrigin: sharePositionOrigin,
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onInverseSurface,
                                      size: 20,
                                    ),
                                    const SizedBox(width: AppTheme.spaceSmall),
                                    Expanded(
                                      child: Text(
                                        'Notes partagées avec succès !',
                                        style: GoogleFonts.inter(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onInverseSurface,
                                          fontWeight: AppTheme.fontMedium,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                duration: const Duration(seconds: 3),
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.inverseSurface,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMedium,
                                  ),
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onError,
                                      size: 20,
                                    ),
                                    const SizedBox(width: AppTheme.spaceSmall),
                                    Expanded(
                                      child: Text(
                                        'Erreur lors du partage: $e',
                                        style: GoogleFonts.inter(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onError,
                                          fontWeight: AppTheme.fontMedium,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                duration: const Duration(seconds: 4),
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.error,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMedium,
                                  ),
                                ),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.ios_share, size: 16),
                      label: Text(
                        'Partager',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: AppTheme.fontMedium,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spaceMedium,
                          vertical: AppTheme.spaceSmall,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSmall,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
