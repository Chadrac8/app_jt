import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sermons_provider.dart';
import '../models/wb_sermon.dart';
import '../models/search_filter.dart';
import '../widgets/sermon_card.dart';
import '../widgets/sermon_filters_sheet.dart';
import '../services/wb_sermon_firestore_service.dart';

/// Vue de l'onglet "Sermons"
class SermonsTabView extends StatefulWidget {
  final bool isAdmin;
  
  const SermonsTabView({super.key, this.isAdmin = false});

  @override
  State<SermonsTabView> createState() => _SermonsTabViewState();
}

class _SermonsTabViewState extends State<SermonsTabView>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  String _selectedLanguage = 'fr'; // Par défaut: français
  bool _languageFilterInitialized = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Consumer<SermonsProvider>(
      builder: (context, provider, child) {
        // Initialiser la langue au premier chargement
        if (!_languageFilterInitialized && provider.filteredSermons.isNotEmpty) {
          _languageFilterInitialized = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            provider.setLanguage(_selectedLanguage);
          });
        }

        if (provider.isLoading && provider.filteredSermons.isEmpty) {
          return const Center(child: CircularProgressIndicator());
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
                  onPressed: () => provider.loadSermons(forceRefresh: true),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            _buildSearchBar(provider),
            _buildFilterChips(provider),
            Expanded(
              child: _buildSermonsList(provider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar(SermonsProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un sermon...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _applySearchFilter(provider, '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              onChanged: (value) => _applySearchFilter(provider, value),
            ),
          ),
          const SizedBox(width: 8),
          // Dropdown pour la langue
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: _selectedLanguage,
              underline: const SizedBox(),
              isDense: true,
              items: const [
                DropdownMenuItem(
                  value: 'fr',
                  child: Text('FR'),
                ),
                DropdownMenuItem(
                  value: 'en',
                  child: Text('EN'),
                ),
              ],
              onChanged: (String? newLanguage) {
                if (newLanguage != null) {
                  setState(() {
                    _selectedLanguage = newLanguage;
                  });
                  // Changer la langue (indépendant des filtres)
                  provider.setLanguage(newLanguage);
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Badge(
              label: Text('${provider.currentFilter.activeFilterCount}'),
              isLabelVisible: provider.currentFilter.hasActiveFilters,
              child: const Icon(Icons.filter_list),
            ),
            onPressed: () => _showFiltersSheet(provider),
            tooltip: 'Filtres',
          ),
        ],
      ),
    );
  }

  void _applySearchFilter(SermonsProvider provider, String query) {
    provider.applyFilter(
      provider.currentFilter.copyWith(query: query),
    );
  }

  Widget _buildFilterChips(SermonsProvider provider) {
    final filter = provider.currentFilter;
    
    if (!filter.hasActiveFilters) {
      return const SizedBox.shrink();
    }

    final chips = <Widget>[];

    // Ne pas afficher le chip de langue (géré par le dropdown)
    
    // Chip pour les années
    if (filter.years.isNotEmpty) {
      chips.add(Chip(
        label: Text('Années: ${filter.years.join(", ")}'),
        onDeleted: () {
          provider.applyFilter(filter.copyWith(years: []));
        },
      ));
    }

    // Chip pour les séries
    if (filter.series.isNotEmpty) {
      chips.add(Chip(
        label: Text('Séries: ${filter.series.length}'),
        onDeleted: () {
          provider.applyFilter(filter.copyWith(series: []));
        },
      ));
    }

    // Bouton pour tout réinitialiser
    if (chips.isNotEmpty) {
      chips.add(ActionChip(
        label: const Text('Tout effacer'),
        onPressed: provider.resetFilter,
      ));
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      width: double.infinity,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: chips,
      ),
    );
  }

  Widget _buildSermonsList(SermonsProvider provider) {
    if (provider.filteredSermons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.library_books_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              provider.currentFilter.hasActiveFilters
                  ? 'Aucun sermon trouvé avec ces filtres'
                  : 'Aucun sermon disponible',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            if (provider.currentFilter.hasActiveFilters) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: provider.resetFilter,
                child: const Text('Réinitialiser les filtres'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadSermons(forceRefresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.filteredSermons.length,
        itemBuilder: (context, index) {
          final sermon = provider.filteredSermons[index];
          return SermonCard(
            sermon: sermon,
            onTap: () => _navigateToSermon(sermon),
            onFavoriteToggle: () => provider.toggleFavorite(sermon.id),
            showAdminActions: widget.isAdmin,
            onEdit: widget.isAdmin ? () => _editSermon(sermon) : null,
            onDelete: widget.isAdmin ? () => _deleteSermon(sermon) : null,
          );
        },
      ),
    );
  }

  void _showFiltersSheet(SermonsProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SermonFiltersSheet(
        currentFilter: provider.currentFilter,
        availableLanguages: provider.availableLanguages.toList(),
        availableYears: provider.availableYears.toList()..sort((a, b) => b.compareTo(a)),
        availableSeries: provider.availableSeries.toList()..sort(),
        onApply: (filter) {
          provider.applyFilter(filter);
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _editSermon(WBSermon sermon) async {
    final result = await Navigator.pushNamed(
      context,
      '/search/edit-sermon',
      arguments: sermon,
    );
    
    if (result == true && mounted) {
      // Recharger les sermons après modification
      final provider = context.read<SermonsProvider>();
      await provider.loadSermons(forceRefresh: true);
    }
  }

  Future<void> _deleteSermon(WBSermon sermon) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le sermon'),
        content: Text('Voulez-vous vraiment supprimer "${sermon.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await WBSermonFirestoreService.deleteSermon(sermon.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sermon supprimé avec succès'),
              backgroundColor: Colors.green,
            ),
          );
          // Recharger les sermons
          final provider = context.read<SermonsProvider>();
          await provider.loadSermons(forceRefresh: true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _navigateToSermon(WBSermon sermon) {
    Navigator.pushNamed(
      context,
      '/search/sermon',
      arguments: sermon,
    );
  }
}
