import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme.dart';
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

class _BibleSearchPageState extends State<BibleSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  List<BibleVerse> _searchResults = [];
  bool _isSearching = false;
  String _currentQuery = '';
  String? _selectedBookFilter;
  
  @override
  void initState() {
    super.initState();
    // Auto-focus sur le champ de recherche
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _currentQuery = '';
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
        limit: 100,
      );
      
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _searchResults = [];
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la recherche: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.surfaceColor,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppTheme.primaryColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Recherche Biblique',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Barre de recherche
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
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
                TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Rechercher dans la Bible...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _performSearch('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: (value) {
                    setState(() {});
                    if (value.length >= 3) {
                      _performSearch(value);
                    } else if (value.isEmpty) {
                      _performSearch('');
                    }
                  },
                  onSubmitted: _performSearch,
                ),
                
                // Filtre par livre (optionnel)
                if (_selectedBookFilter != null)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        Chip(
                          label: Text(_selectedBookFilter!),
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: () {
                            setState(() {
                              _selectedBookFilter = null;
                            });
                            if (_currentQuery.isNotEmpty) {
                              _performSearch(_currentQuery);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          // Résultats de recherche
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_currentQuery.isEmpty) {
      return _buildSearchSuggestions();
    }

    if (_searchResults.isEmpty) {
      return _buildNoResults();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final verse = _searchResults[index];
        return _buildSearchResultCard(verse);
      },
    );
  }

  Widget _buildSearchSuggestions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suggestions de recherche',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildSuggestionCategory(
            'Mots-clés populaires',
            [
              'amour',
              'foi',
              'espérance',
              'paix',
              'joie',
              'grâce',
              'miséricorde',
              'salut',
            ],
          ),
          
          const SizedBox(height: 24),
          
          _buildSuggestionCategory(
            'Thèmes spirituels',
            [
              'prière',
              'pardon',
              'royaume',
              'éternel',
              'saint',
              'justice',
              'vérité',
              'lumière',
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCategory(String title, List<String> suggestions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
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
              },
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              labelStyle: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun résultat trouvé',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez avec d\'autres mots-clés',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _searchController.clear();
              _performSearch('');
              _searchFocusNode.requestFocus();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Nouvelle recherche'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultCard(BibleVerse verse) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _selectVerse(verse),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Référence du verset
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      verse.reference,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.bookmark_add, size: 20),
                    onPressed: () => _bookmarkVerse(verse),
                    color: Colors.grey[600],
                  ),
                  IconButton(
                    icon: const Icon(Icons.share, size: 20),
                    onPressed: () => _shareVerse(verse),
                    color: Colors.grey[600],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Texte du verset avec mise en surbrillance
              RichText(
                text: _highlightSearchTerms(verse.text, _currentQuery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextSpan _highlightSearchTerms(String text, String query) {
    if (query.isEmpty) {
      return TextSpan(
        text: text,
        style: GoogleFonts.crimsonText(
          fontSize: 16,
          color: Colors.black87,
          height: 1.4,
        ),
      );
    }

    final lowercaseText = text.toLowerCase();
    final lowercaseQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    
    int start = 0;
    int index = lowercaseText.indexOf(lowercaseQuery);
    
    while (index != -1) {
      // Texte avant la correspondance
      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: GoogleFonts.crimsonText(
            fontSize: 16,
            color: Colors.black87,
            height: 1.4,
          ),
        ));
      }
      
      // Texte en surbrillance
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: GoogleFonts.crimsonText(
          fontSize: 16,
          color: Colors.black87,
          height: 1.4,
          backgroundColor: Colors.yellow.withOpacity(0.3),
          fontWeight: FontWeight.bold,
        ),
      ));
      
      start = index + query.length;
      index = lowercaseText.indexOf(lowercaseQuery, start);
    }
    
    // Texte restant
    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: GoogleFonts.crimsonText(
          fontSize: 16,
          color: Colors.black87,
          height: 1.4,
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
    });
  }

  void _bookmarkVerse(BibleVerse verse) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Signet ajouté: ${verse.reference}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareVerse(BibleVerse verse) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Partage de: ${verse.reference}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
