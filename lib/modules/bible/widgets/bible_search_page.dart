import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/bible_verse.dart';
import '../services/bible_service.dart';

class BibleSearchPage extends StatefulWidget {
  final BibleService bibleService;

  const BibleSearchPage({
    Key? key,
    required this.bibleService,
  }) : super(key: key);

  @override
  State<BibleSearchPage> createState() => _BibleSearchPageState();
}

class _BibleSearchPageState extends State<BibleSearchPage> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Search state
  List<BibleVerse> _searchResults = [];
  List<String> _searchHistory = [];
  bool _isSearching = false;
  String _currentQuery = '';
  String? _selectedBookFilter;
  int _selectedResultIndex = -1;
  
  // Advanced search options
  bool _showAdvancedOptions = false;
  bool _caseSensitive = false;
  bool _wholeWords = false;
  bool _useRegex = false;
  Map<String, dynamic>? _searchStats;
  

  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSearchHistory();
    
    // Auto-focus sur le champ de recherche avec délai pour l'animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _searchFocusNode.requestFocus();
        }
      });
    });
    
    // Listen to focus changes

  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // Debounce mechanism for search
  void _debounceSearch(String query) {
    if (query.length >= 2) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_searchController.text == query) {
          _performSearch(query);
        }
      });
    } else if (query.isEmpty) {
      _performSearch('');
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _currentQuery = '';
        _searchStats = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _currentQuery = query;
    });

    try {
      final results = await widget.bibleService.searchVerses(
        query,
        bookFilter: _selectedBookFilter,
        limit: 200,
        caseSensitive: _caseSensitive,
        wholeWords: _wholeWords,
        useRegex: _useRegex,
      );
      
      // Obtenir les statistiques de recherche
      final stats = await widget.bibleService.searchWithStats(query);
      
      if (mounted) {
        setState(() {
          _searchResults = results;
          _searchStats = stats;
          _isSearching = false;
        });
        
        // Scroll to top of results
        if (_scrollController.hasClients && results.isNotEmpty) {
          _scrollController.animateTo(
            200,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _searchResults = [];
          _searchStats = null;
        });
        
        _showErrorSnackBar('Erreur lors de la recherche: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Theme.of(context).colorScheme.onError,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // Search history management
  Future<void> _loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList('bible_search_history') ?? [];
      if (mounted) {
        setState(() {
          _searchHistory = history;
        });
      }
    } catch (e) {
      // Silently handle error
    }
  }

  Future<void> _addToSearchHistory(String query) async {
    if (query.trim().isEmpty || _searchHistory.contains(query)) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _searchHistory.insert(0, query);
      if (_searchHistory.length > 20) {
        _searchHistory = _searchHistory.take(20).toList();
      }
      await prefs.setStringList('bible_search_history', _searchHistory);
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // Silently handle error
    }
  }

  Future<void> _clearSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('bible_search_history');
      setState(() {
        _searchHistory.clear();
      });
    } catch (e) {
      // Silently handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Modern App Bar with search
              _buildModernAppBar(colorScheme),
              
              // Search content
              SliverFillRemaining(
                child: _buildSearchContent(colorScheme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernAppBar(ColorScheme colorScheme) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      snap: false,
      elevation: 0,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      leading: IconButton.filledTonal(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_rounded),
        style: IconButton.styleFrom(
          backgroundColor: colorScheme.secondaryContainer.withOpacity(0.3),
          foregroundColor: colorScheme.onSecondaryContainer,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.primaryContainer.withOpacity(0.1),
                colorScheme.surface,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
              child: _buildProfessionalSearchBar(colorScheme),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfessionalSearchBar(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        elevation: 0,
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.surfaceContainerHighest,
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: 'Rechercher dans les Écritures...',
            hintStyle: GoogleFonts.inter(
              fontSize: 16,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Container(
              padding: const EdgeInsets.all(12),
              child: Icon(
                Icons.search_rounded,
                color: colorScheme.primary,
                size: 24,
              ),
            ),
            suffixIcon: _currentQuery.isNotEmpty
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isSearching)
                        Container(
                          padding: const EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: colorScheme.primary,
                            ),
                          ),
                        )
                      else
                        IconButton(
                          onPressed: () {
                            _searchController.clear();
                            _performSearch('');
                          },
                          icon: Icon(
                            Icons.clear_rounded,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _showAdvancedOptions = !_showAdvancedOptions;
                          });
                          HapticFeedback.lightImpact();
                        },
                        icon: Icon(
                          _showAdvancedOptions 
                              ? Icons.tune_rounded 
                              : Icons.tune_outlined,
                          color: _showAdvancedOptions 
                              ? colorScheme.primary 
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  )
                : IconButton(
                    onPressed: () {
                      setState(() {
                        _showAdvancedOptions = !_showAdvancedOptions;
                      });
                      HapticFeedback.lightImpact();
                    },
                    icon: Icon(
                      Icons.tune_outlined,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 0,
              vertical: 16,
            ),
          ),
          onChanged: (value) {
            setState(() {});
            _debounceSearch(value);
          },
          onSubmitted: (value) {
            _performSearch(value);
            _addToSearchHistory(value);
          },
        ),
      ),
    );
  }

  Widget _buildSearchContent(ColorScheme colorScheme) {
    return Column(
      children: [
        // Advanced options panel
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          height: _showAdvancedOptions ? null : 0,
          child: _showAdvancedOptions ? _buildAdvancedOptionsPanel(colorScheme) : null,
        ),
        
        // Search stats
        if (_searchStats != null && _currentQuery.isNotEmpty)
          _buildSearchStats(colorScheme),
        
        // Main content
        Expanded(
          child: _buildMainContent(colorScheme),
        ),
      ],
    );
  }

  Widget _buildAdvancedOptionsPanel(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tune_rounded,
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Options de recherche avancée',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Options switches
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Switch.adaptive(
                      value: _caseSensitive,
                      onChanged: (value) {
                        setState(() {
                          _caseSensitive = value;
                        });
                        if (_currentQuery.isNotEmpty) {
                          _performSearch(_currentQuery);
                        }
                        HapticFeedback.selectionClick();
                      },
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Sensible à la casse',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  children: [
                    Switch.adaptive(
                      value: _wholeWords,
                      onChanged: (value) {
                        setState(() {
                          _wholeWords = value;
                        });
                        if (_currentQuery.isNotEmpty) {
                          _performSearch(_currentQuery);
                        }
                        HapticFeedback.selectionClick();
                      },
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Mots entiers',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Switch.adaptive(
                value: _useRegex,
                onChanged: (value) {
                  setState(() {
                    _useRegex = value;
                  });
                  if (_currentQuery.isNotEmpty) {
                    _performSearch(_currentQuery);
                  }
                  HapticFeedback.selectionClick();
                },
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Expression régulière',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const Spacer(),
              if (_useRegex)
                TextButton.icon(
                  onPressed: _showRegexHelp,
                  icon: Icon(
                    Icons.help_outline_rounded,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  label: Text(
                    'Aide',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchStats(ColorScheme colorScheme) {
    if (_searchStats == null) return const SizedBox.shrink();
    
    final total = _searchStats!['total'] ?? 0;
    final books = _searchStats!['books'] ?? 0;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 20,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$total résultat${total > 1 ? 's' : ''} trouvé${total > 1 ? 's' : ''} dans $books livre${books > 1 ? 's' : ''}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          if (_searchResults.isNotEmpty)
            IconButton.filledTonal(
              onPressed: _shareSearchResults,
              icon: const Icon(Icons.share_rounded, size: 18),
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.primaryContainer,
                foregroundColor: colorScheme.onPrimaryContainer,
                minimumSize: const Size(32, 32),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMainContent(ColorScheme colorScheme) {
    if (_isSearching) {
      return _buildLoadingState(colorScheme);
    }

    if (_currentQuery.isEmpty) {
      return _buildWelcomeState(colorScheme);
    }

    if (_searchResults.isEmpty) {
      return _buildEmptyState(colorScheme);
    }

    return _buildResultsList(colorScheme);
  }

  Widget _buildLoadingState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Recherche en cours...',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Exploration des Écritures',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeState(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primaryContainer.withOpacity(0.6),
                  colorScheme.secondaryContainer.withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.menu_book_rounded,
                  size: 48,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Explorez les Écritures',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Découvrez la richesse de la Parole de Dieu avec notre moteur de recherche avancé.',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Search suggestions
          _buildSearchSuggestions(colorScheme),
          
          const SizedBox(height: 32),
          
          // Search history
          if (_searchHistory.isNotEmpty)
            _buildSearchHistory(colorScheme),
        ],
      ),
    );
  }

  Widget _buildSearchSuggestions(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recherches populaires',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        
        _buildSuggestionCategory(
          colorScheme,
          'Thèmes spirituels',
          [
            'amour', 'foi', 'espérance', 'paix', 'joie',
            'grâce', 'miséricorde', 'salut', 'prière',
          ],
        ),
        
        const SizedBox(height: 24),
        
        _buildSuggestionCategory(
          colorScheme,
          'Personnages bibliques',
          [
            'Jésus', 'David', 'Moïse', 'Paul', 'Pierre',
            'Abraham', 'Marie', 'Jean', 'Matthieu',
          ],
        ),
      ],
    );
  }

  Widget _buildSuggestionCategory(ColorScheme colorScheme, String title, List<String> suggestions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestions.map((suggestion) {
            return ActionChip(
              label: Text(suggestion),
              onPressed: () {
                _searchController.text = suggestion;
                _performSearch(suggestion);
                _addToSearchHistory(suggestion);
                HapticFeedback.selectionClick();
              },
              backgroundColor: colorScheme.primaryContainer.withOpacity(0.3),
              labelStyle: GoogleFonts.inter(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSearchHistory(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Recherches récentes',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _clearSearchHistory,
              icon: Icon(
                Icons.clear_all_rounded,
                size: 18,
                color: colorScheme.error,
              ),
              label: Text(
                'Effacer',
                style: GoogleFonts.inter(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...(_searchHistory.take(5).map((query) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              Icons.history_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
            title: Text(
              query,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
            onTap: () {
              _searchController.text = query;
              _performSearch(query);
              HapticFeedback.selectionClick();
            },
          ),
        ))),
      ],
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Aucun résultat trouvé',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez avec des termes différents\nou utilisez les options avancées',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  _performSearch('');
                  _searchFocusNode.requestFocus();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Nouvelle recherche'),
              ),
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: () {
                  setState(() {
                    _showAdvancedOptions = true;
                  });
                  HapticFeedback.lightImpact();
                },
                icon: const Icon(Icons.tune_rounded),
                label: const Text('Options avancées'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(ColorScheme colorScheme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final verse = _searchResults[index];
        final isSelected = index == _selectedResultIndex;
        
        return _buildProfessionalResultCard(verse, index, isSelected, colorScheme);
      },
    );
  }

  Widget _buildProfessionalResultCard(BibleVerse verse, int index, bool isSelected, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        elevation: isSelected ? 8 : 2,
        borderRadius: BorderRadius.circular(16),
        color: isSelected 
            ? colorScheme.primaryContainer.withOpacity(0.3)
            : colorScheme.surface,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedResultIndex = index;
            });
            _selectVerse(verse);
            HapticFeedback.selectionClick();
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with reference and actions
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        verse.reference,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton.filledTonal(
                      onPressed: () => _bookmarkVerse(verse),
                      icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.secondaryContainer.withOpacity(0.5),
                        foregroundColor: colorScheme.onSecondaryContainer,
                        minimumSize: const Size(36, 36),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      onPressed: () => _shareVerse(verse),
                      icon: const Icon(Icons.share_outlined, size: 18),
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.secondaryContainer.withOpacity(0.5),
                        foregroundColor: colorScheme.onSecondaryContainer,
                        minimumSize: const Size(36, 36),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Verse text with highlighting
                RichText(
                  text: _highlightSearchTerms(verse.text, _currentQuery, colorScheme),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextSpan _highlightSearchTerms(String text, String query, ColorScheme colorScheme) {
    if (query.isEmpty) {
      return TextSpan(
        text: text,
        style: GoogleFonts.crimsonText(
          fontSize: 16,
          color: colorScheme.onSurface,
          height: 1.6,
          fontWeight: FontWeight.w400,
        ),
      );
    }

    final lowercaseText = text.toLowerCase();
    final lowercaseQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    
    int start = 0;
    int index = lowercaseText.indexOf(lowercaseQuery);
    
    while (index != -1) {
      // Text before match
      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: GoogleFonts.crimsonText(
            fontSize: 16,
            color: colorScheme.onSurface,
            height: 1.6,
            fontWeight: FontWeight.w400,
          ),
        ));
      }
      
      // Highlighted text
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: GoogleFonts.crimsonText(
          fontSize: 16,
          color: colorScheme.onSurface,
          height: 1.6,
          fontWeight: FontWeight.bold,
          backgroundColor: colorScheme.primary.withOpacity(0.2),
        ),
      ));
      
      start = index + query.length;
      index = lowercaseText.indexOf(lowercaseQuery, start);
    }
    
    // Remaining text
    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: GoogleFonts.crimsonText(
          fontSize: 16,
          color: colorScheme.onSurface,
          height: 1.6,
          fontWeight: FontWeight.w400,
        ),
      ));
    }
    
    return TextSpan(children: spans);
  }

  void _selectVerse(BibleVerse verse) {
    Navigator.pop(context, {
      'book': verse.book,
      'chapter': verse.chapter,
      'verse': verse.verse,
      'text': verse.text,
      'reference': verse.reference,
    });
  }

  void _bookmarkVerse(BibleVerse verse) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.bookmark_added_rounded,
              color: Theme.of(context).colorScheme.onInverseSurface,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Signet ajouté: ${verse.reference}',
                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _shareVerse(BibleVerse verse) async {
    try {
      await Share.share(
        '${verse.text}\n\n— ${verse.reference}',
        subject: 'Verset biblique - ${verse.reference}',
      );
      HapticFeedback.lightImpact();
    } catch (e) {
      _showErrorSnackBar('Erreur lors du partage');
    }
  }

  void _shareSearchResults() async {
    if (_searchResults.isEmpty) return;
    
    try {
      final buffer = StringBuffer();
      buffer.writeln('Résultats de recherche pour: "$_currentQuery"');
      buffer.writeln('=' * 50);
      buffer.writeln();
      
      for (int i = 0; i < _searchResults.length && i < 20; i++) {
        final verse = _searchResults[i];
        buffer.writeln('${i + 1}. ${verse.reference}');
        buffer.writeln(verse.text);
        buffer.writeln();
      }
      
      if (_searchResults.length > 20) {
        buffer.writeln('... et ${_searchResults.length - 20} autres résultats');
        buffer.writeln();
      }
      
      buffer.writeln('Partagé depuis Jubilé Tabernacle France');
      
      await Share.share(
        buffer.toString(),
        subject: 'Recherche biblique: $_currentQuery',
      );
      
      HapticFeedback.lightImpact();
    } catch (e) {
      _showErrorSnackBar('Erreur lors du partage des résultats');
    }
  }

  void _showRegexHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.help_outline_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            const Text('Aide Regex'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Exemples d\'expressions régulières :',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildRegexExample(r'Jésus.*Christ', 'Trouve "Jésus" suivi de "Christ"'),
              _buildRegexExample(r'\bDieu\b', 'Mot "Dieu" exact seulement'),
              _buildRegexExample(r'\d+', 'Trouve tous les nombres'),
              _buildRegexExample(r'(paix|joie)', 'Trouve "paix" ou "joie"'),
              _buildRegexExample(r'^Au commencement', 'Commence par "Au commencement"'),
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

  Widget _buildRegexExample(String pattern, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              pattern,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
