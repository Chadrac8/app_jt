import 'package:flutter/material.dart';
import '../models/search_filter.dart';

/// Bottom sheet pour les filtres de recherche avancée
class SearchFiltersSheet extends StatefulWidget {
  final SearchFilter currentFilter;
  final Function(SearchFilter) onApply;

  const SearchFiltersSheet({
    super.key,
    required this.currentFilter,
    required this.onApply,
  });

  @override
  State<SearchFiltersSheet> createState() => _SearchFiltersSheetState();
}

class _SearchFiltersSheetState extends State<SearchFiltersSheet> {
  late SearchFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.currentFilter;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filtres avancés',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _filter = SearchFilter(query: _filter.query);
                      });
                    },
                    child: const Text('Réinitialiser'),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    const Text(
                      'Filtrer les résultats de recherche',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    _buildLanguageFilter(),
                    const SizedBox(height: 16),
                    _buildResourcesFilter(),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => widget.onApply(_filter),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Appliquer'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Langues',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ['fr', 'en', 'es', 'de'].map((lang) {
            final isSelected = _filter.languages.contains(lang);
            return FilterChip(
              label: Text(lang.toUpperCase()),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  final languages = List<String>.from(_filter.languages);
                  if (selected) {
                    languages.add(lang);
                  } else {
                    languages.remove(lang);
                  }
                  _filter = _filter.copyWith(languages: languages);
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildResourcesFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ressources disponibles',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          title: const Text('Audio'),
          value: _filter.hasAudio == true,
          onChanged: (value) {
            setState(() {
              _filter = _filter.copyWith(hasAudio: value == true ? true : null);
            });
          },
          dense: true,
        ),
        CheckboxListTile(
          title: const Text('Vidéo'),
          value: _filter.hasVideo == true,
          onChanged: (value) {
            setState(() {
              _filter = _filter.copyWith(hasVideo: value == true ? true : null);
            });
          },
          dense: true,
        ),
        CheckboxListTile(
          title: const Text('PDF'),
          value: _filter.hasPdf == true,
          onChanged: (value) {
            setState(() {
              _filter = _filter.copyWith(hasPdf: value == true ? true : null);
            });
          },
          dense: true,
        ),
        CheckboxListTile(
          title: const Text('Texte'),
          value: _filter.hasText == true,
          onChanged: (value) {
            setState(() {
              _filter = _filter.copyWith(hasText: value == true ? true : null);
            });
          },
          dense: true,
        ),
      ],
    );
  }
}
