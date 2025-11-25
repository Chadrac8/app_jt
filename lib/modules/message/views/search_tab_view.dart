import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/search_provider.dart';
import '../models/search_result.dart';
import '../widgets/search_result_card.dart';
import '../widgets/search_filters_sheet.dart';

/// Vue de l'onglet "Recherche"
class SearchTabView extends StatefulWidget {
  const SearchTabView({super.key});

  @override
  State<SearchTabView> createState() => _SearchTabViewState();
}

class _SearchTabViewState extends State<SearchTabView>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Consumer<SearchProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            _buildSearchBar(provider),
            if (provider.searchHistory.isNotEmpty && !_searchFocus.hasFocus)
              _buildSearchHistory(provider),
            Expanded(
              child: _buildSearchContent(provider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar(SearchProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              decoration: InputDecoration(
                hintText: 'Rechercher dans les sermons...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          provider.reset();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (query) => _performSearch(provider, query),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Badge(
              label: Text('${provider.filter.activeFilterCount}'),
              isLabelVisible: provider.filter.hasActiveFilters,
              child: const Icon(Icons.tune),
            ),
            onPressed: () => _showFiltersSheet(provider),
            tooltip: 'Filtres avancés',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHistory(SearchProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recherches récentes',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              TextButton(
                onPressed: provider.clearHistory,
                child: const Text('Effacer', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            children: provider.searchHistory.take(5).map((query) {
              return InputChip(
                label: Text(query),
                onPressed: () {
                  _searchController.text = query;
                  _performSearch(provider, query);
                },
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => provider.removeFromHistory(query),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchContent(SearchProvider provider) {
    if (provider.isSearching) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Recherche en cours...'),
          ],
        ),
      );
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              provider.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _performSearch(provider, _searchController.text),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (!provider.hasResults) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'Effectuez une recherche pour trouver des sermons'
                  : 'Aucun résultat trouvé',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            if (_searchController.text.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Essayez d\'utiliser d\'autres mots-clés ou filtres',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
      );
    }

    return _buildResults(provider);
  }

  Widget _buildResults(SearchProvider provider) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${provider.results.length} résultat(s)',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () => _groupBySermon(provider),
                icon: const Icon(Icons.group_work, size: 16),
                label: const Text('Grouper par sermon'),
                style: TextButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.results.length,
            itemBuilder: (context, index) {
              final result = provider.results[index];
              return SearchResultCard(
                result: result,
                searchQuery: provider.filter.query ?? '',
                onTap: () => _navigateToResult(result),
              );
            },
          ),
        ),
      ],
    );
  }

  void _performSearch(SearchProvider provider, String query) {
    if (query.trim().isEmpty) return;
    
    provider.quickSearch(query.trim());
    _searchFocus.unfocus();
  }

  void _showFiltersSheet(SearchProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SearchFiltersSheet(
        currentFilter: provider.filter,
        onApply: (filter) {
          provider.updateFilter(filter);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _groupBySermon(SearchProvider provider) {
    final grouped = provider.getResultsGroupedBySermon();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Résultats groupés par sermon',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: grouped.length,
                    itemBuilder: (context, index) {
                      final sermonId = grouped.keys.elementAt(index);
                      final results = grouped[sermonId]!;
                      final firstResult = results.first;

                      return ExpansionTile(
                        title: Text(firstResult.sermonTitle),
                        subtitle: Text(firstResult.sermonDate),
                        trailing: Chip(
                          label: Text('${results.length}'),
                        ),
                        children: results.map((result) {
                          return ListTile(
                            title: Text(
                              result.matchedText,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: result.pageNumber != null
                                ? Text('Page ${result.pageNumber}')
                                : null,
                            onTap: () {
                              Navigator.pop(context);
                              _navigateToResult(result);
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _navigateToResult(SearchResult result) {
    final searchProvider = context.read<SearchProvider>();
    Navigator.pushNamed(
      context,
      '/search/sermon',
      arguments: {
        'sermonId': result.sermonId,
        'pageNumber': result.pageNumber,
        'searchQuery': searchProvider.filter.query,
      },
    );
  }
}
