import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme.dart';
import '../models/bible_verse.dart';
import '../services/bible_service.dart';
import '../../../theme.dart';

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
            backgroundColor: AppTheme.redStandard,
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
            fontWeight: AppTheme.fontBold,
            color: AppTheme.primaryColor,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Barre de recherche
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            decoration: BoxDecoration(
              color: AppTheme.white100,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.black100.withOpacity(0.05),
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
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppTheme.grey100,
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
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final verse = _searchResults[index];
        return _buildSearchResultCard(verse);
      },
    );
  }

  Widget _buildSearchSuggestions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suggestions de recherche',
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize18,
              fontWeight: AppTheme.fontBold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          
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
          
          const SizedBox(height: AppTheme.spaceLarge),
          
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
            fontSize: AppTheme.fontSize16,
            fontWeight: AppTheme.fontSemiBold,
            color: AppTheme.grey700,
          ),
        ),
        const SizedBox(height: AppTheme.space12),
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
                fontWeight: AppTheme.fontMedium,
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
            color: AppTheme.grey400,
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          Text(
            'Aucun résultat trouvé',
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize18,
              fontWeight: AppTheme.fontSemiBold,
              color: AppTheme.grey600,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Text(
            'Essayez avec d\'autres mots-clés',
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize14,
              color: AppTheme.grey500,
            ),
          ),
          const SizedBox(height: AppTheme.spaceLarge),
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
              foregroundColor: AppTheme.white100,
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
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
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
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    child: Text(
                      verse.reference,
                      style: GoogleFonts.inter(
                        fontSize: AppTheme.fontSize12,
                        fontWeight: AppTheme.fontBold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.bookmark_add, size: 20),
                    onPressed: () => _bookmarkVerse(verse),
                    color: AppTheme.grey600,
                  ),
                  IconButton(
                    icon: const Icon(Icons.share, size: 20),
                    onPressed: () => _shareVerse(verse),
                    color: AppTheme.grey600,
                  ),
                ],
              ),
              
              const SizedBox(height: AppTheme.space12),
              
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
          fontSize: AppTheme.fontSize16,
          color: AppTheme.black100.withOpacity(0.87),
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
            fontSize: AppTheme.fontSize16,
            color: AppTheme.black100.withOpacity(0.87),
            height: 1.4,
          ),
        ));
      }
      
      // Texte en surbrillance
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: GoogleFonts.crimsonText(
          fontSize: AppTheme.fontSize16,
          color: AppTheme.black100.withOpacity(0.87),
          height: 1.4,
          backgroundColor: Colors.yellow.withOpacity(0.3),
          fontWeight: AppTheme.fontBold,
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
          fontSize: AppTheme.fontSize16,
          color: AppTheme.black100.withOpacity(0.87),
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
