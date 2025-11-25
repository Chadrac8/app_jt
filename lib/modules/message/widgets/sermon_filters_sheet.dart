import 'package:flutter/material.dart';
import '../models/search_filter.dart';

/// Bottom sheet pour les filtres de sermons
class SermonFiltersSheet extends StatefulWidget {
  final SearchFilter currentFilter;
  final List<String> availableLanguages;
  final List<int> availableYears;
  final List<String> availableSeries;
  final Function(SearchFilter) onApply;

  const SermonFiltersSheet({
    super.key,
    required this.currentFilter,
    required this.availableLanguages,
    required this.availableYears,
    required this.availableSeries,
    required this.onApply,
  });

  @override
  State<SermonFiltersSheet> createState() => _SermonFiltersSheetState();
}

class _SermonFiltersSheetState extends State<SermonFiltersSheet> {
  late SearchFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.currentFilter;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
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
                    'Filtres',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _filter = const SearchFilter();
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
                    _buildYearFilter(),
                    const SizedBox(height: 16),
                    _buildSeriesFilter(),
                    const SizedBox(height: 16),
                    _buildResourcesFilter(),
                    const SizedBox(height: 16),
                    _buildSortOptions(),
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
                    child: Text('Appliquer les filtres'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildYearFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Années',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: widget.availableYears.length,
            itemBuilder: (context, index) {
              final year = widget.availableYears[index];
              final isSelected = _filter.years.contains(year);
              return FilterChip(
                label: Text(year.toString()),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    final years = List<int>.from(_filter.years);
                    if (selected) {
                      years.add(year);
                    } else {
                      years.remove(year);
                    }
                    _filter = _filter.copyWith(years: years);
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSeriesFilter() {
    if (widget.availableSeries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Séries',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.availableSeries.take(20).map((series) {
            final isSelected = _filter.series.contains(series);
            return FilterChip(
              label: Text(series),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  final seriesList = List<String>.from(_filter.series);
                  if (selected) {
                    seriesList.add(series);
                  } else {
                    seriesList.remove(series);
                  }
                  _filter = _filter.copyWith(series: seriesList);
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

  Widget _buildSortOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tri',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<SortOption>(
          value: _filter.sortBy,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Trier par',
          ),
          items: const [
            DropdownMenuItem(
              value: SortOption.date,
              child: Text('Date'),
            ),
            DropdownMenuItem(
              value: SortOption.title,
              child: Text('Titre'),
            ),
            DropdownMenuItem(
              value: SortOption.duration,
              child: Text('Durée'),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _filter = _filter.copyWith(sortBy: value);
              });
            }
          },
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          title: const Text('Ordre croissant'),
          value: _filter.sortAscending,
          onChanged: (value) {
            setState(() {
              _filter = _filter.copyWith(sortAscending: value == true);
            });
          },
          dense: true,
        ),
      ],
    );
  }
}
