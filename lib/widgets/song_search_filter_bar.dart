import 'package:flutter/material.dart';
import '../modules/songs/models/song_model.dart';
import '../../theme.dart';

/// Widget de recherche et filtrage pour les chants
class SongSearchFilterBar extends StatefulWidget {
  final Function(String) onSearchChanged;
  final Function(String?) onStyleChanged;
  final Function(String?) onKeyChanged;
  final Function(String?) onStatusChanged;
  final Function(List<String>) onTagsChanged;
  final bool showStatusFilter;
  final String? initialSearch;
  final String? initialStyle;
  final String? initialKey;
  final String? initialStatus;

  const SongSearchFilterBar({
    super.key,
    required this.onSearchChanged,
    required this.onStyleChanged,
    required this.onKeyChanged,
    required this.onStatusChanged,
    required this.onTagsChanged,
    this.showStatusFilter = false,
    this.initialSearch,
    this.initialStyle,
    this.initialKey,
    this.initialStatus,
  });

  @override
  State<SongSearchFilterBar> createState() => _SongSearchFilterBarState();
}

class _SongSearchFilterBarState extends State<SongSearchFilterBar> {
  late TextEditingController _searchController;
  final FocusNode _searchFocusNode = FocusNode();
  List<String> _suggestions = [];
  bool _showSuggestions = false;
  // Pour la recherche avancée avec opérateurs logiques
  String _advancedQuery = '';
  String? _selectedStyle;
  String? _selectedKey;
  String? _selectedStatus;
  List<String> _selectedTags = [];
  bool _showFilters = false;

  // Tags prédéfinis disponibles
  final List<String> _availableTags = [
    'Noël', 'Pâques', 'Baptême', 'Communion', 'Mariage', 'Funérailles',
    'Enfants', 'Jeunes', 'Prière du matin', 'Prière du soir', 'Intercession',
    'Action de grâce', 'Repentance', 'Guérison', 'Évangélisation', 'Mission',
    'Francophone', 'Anglophone', 'Traditionnel', 'Contemporain', 'Gospel',
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialSearch);
    _selectedStyle = widget.initialStyle;
    _selectedKey = widget.initialKey;
    _selectedStatus = widget.initialStatus;
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus) {
        setState(() => _showSuggestions = false);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    setState(() {
      _advancedQuery = query;
      _showSuggestions = query.isNotEmpty;
      _suggestions = _getSuggestions(query);
    });
    widget.onSearchChanged(query);
  }

  List<String> _getSuggestions(String query) {
    // Suggestions sur titres, auteurs, tags (simple, à améliorer selon vos données)
    final lower = query.toLowerCase();
    final all = <String>{
      ...SongModel.availableStyles,
      ...SongModel.availableKeys,
      ...SongModel.availableStatuses,
      ..._availableTags,
    };
    return all.where((s) => s.toLowerCase().contains(lower)).take(8).toList();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedStyle = null;
      _selectedKey = null;
      _selectedStatus = null;
      _selectedTags.clear();
    });
    
    widget.onSearchChanged('');
    widget.onStyleChanged(null);
    widget.onKeyChanged(null);
    widget.onStatusChanged(null);
    widget.onTagsChanged([]);
  }

  bool get _hasActiveFilters {
    return _searchController.text.isNotEmpty ||
           _selectedStyle != null ||
           _selectedKey != null ||
           _selectedStatus != null ||
           _selectedTags.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000), // 10% opacity black
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Barre de recherche principale
          Row(
            children: [
              // Champ de recherche avancée avec suggestions
              Expanded(
                child: Stack(
                  children: [
                    TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Recherche avancée (ex: "louange" AND "paix" OR tag:Gospel)',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  widget.onSearchChanged('');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onChanged: (_) {},
                    ),
                    if (_showSuggestions && _suggestions.isNotEmpty)
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 48,
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          child: ListView(
                            shrinkWrap: true,
                            children: _suggestions.map((s) => ListTile(
                              title: Text(s),
                              onTap: () {
                                _searchController.text = s;
                                _searchController.selection = TextSelection.fromPosition(TextPosition(offset: s.length));
                                setState(() {
                                  _showSuggestions = false;
                                });
                                widget.onSearchChanged(s);
                              },
                            )).toList(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Bouton filtres
              IconButton(
                icon: Badge(
                  isLabelVisible: _hasActiveFilters,
                  child: Icon(
                    _showFilters ? Icons.filter_list : Icons.tune,
                    color: _hasActiveFilters ? Theme.of(context).primaryColor : null,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _showFilters = !_showFilters;
                  });
                },
              ),
              // Bouton effacer les filtres
              if (_hasActiveFilters)
                IconButton(
                  icon: const Icon(Icons.clear_all),
                  onPressed: _clearFilters,
                  tooltip: 'Effacer tous les filtres',
                ),
            ],
          ),
          // Affichage des filtres actifs sous forme de chips
          if (_hasActiveFilters)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
              child: Wrap(
                spacing: 8,
                children: [
                  if (_searchController.text.isNotEmpty)
                    Chip(
                      label: Text('Recherche: "${_searchController.text}"'),
                      onDeleted: () {
                        _searchController.clear();
                        widget.onSearchChanged('');
                      },
                    ),
                  if (_selectedStyle != null)
                    Chip(
                      label: Text('Style: $_selectedStyle'),
                      onDeleted: () {
                        setState(() => _selectedStyle = null);
                        widget.onStyleChanged(null);
                      },
                    ),
                  if (_selectedKey != null)
                    Chip(
                      label: Text('Tonalité: $_selectedKey'),
                      onDeleted: () {
                        setState(() => _selectedKey = null);
                        widget.onKeyChanged(null);
                      },
                    ),
                  if (_selectedStatus != null)
                    Chip(
                      label: Text('Statut: ${_getStatusDisplayName(_selectedStatus!)}'),
                      onDeleted: () {
                        setState(() => _selectedStatus = null);
                        widget.onStatusChanged(null);
                      },
                    ),
                  ..._selectedTags.map((tag) => Chip(
                        label: Text('Tag: $tag'),
                        onDeleted: () {
                          setState(() => _selectedTags.remove(tag));
                          widget.onTagsChanged(_selectedTags);
                        },
                      )),
                ],
              ),
            ),
          // Panneau de filtres détaillés
          if (_showFilters) ...[
            const SizedBox(height: 16),
            _buildFiltersPanel(),
          ],
        ],
      ),
    );
  }

  Widget _buildFiltersPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0x0D1976D2), // 5% opacity of primaryColor (#1976D2)
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtres avancés',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: AppTheme.fontBold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Première ligne: Style et Tonalité
          Row(
            children: [
              // Filtre par style
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Style',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedStyle,
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Tous les styles'),
                    ),
                    ...SongModel.availableStyles.map((style) =>
                      DropdownMenuItem<String>(
                        value: style,
                        child: Text(style),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedStyle = value;
                    });
                    widget.onStyleChanged(value);
                  },
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Filtre par tonalité
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Tonalité',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedKey,
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Toutes les tonalités'),
                    ),
                    ...SongModel.availableKeys.map((key) =>
                      DropdownMenuItem<String>(
                        value: key,
                        child: Text(key),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedKey = value;
                    });
                    widget.onKeyChanged(value);
                  },
                ),
              ),
            ],
          ),
          
          // Deuxième ligne: Statut (si affiché)
          if (widget.showStatusFilter) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Statut',
                border: OutlineInputBorder(),
              ),
              value: _selectedStatus,
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Tous les statuts'),
                ),
                ...SongModel.availableStatuses.map((status) =>
                  DropdownMenuItem<String>(
                    value: status,
                    child: Text(_getStatusDisplayName(status)),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value;
                });
                widget.onStatusChanged(value);
              },
            ),
          ],
          
          // Tags
          const SizedBox(height: 16),
          Text(
            'Tags',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: AppTheme.fontSemiBold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableTags.map((tag) {
              final isSelected = _selectedTags.contains(tag);
              return FilterChip(
                label: Text(tag),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedTags.add(tag);
                    } else {
                      _selectedTags.remove(tag);
                    }
                  });
                  widget.onTagsChanged(_selectedTags);
                },
                backgroundColor: Theme.of(context).chipTheme.backgroundColor,
                selectedColor: Color(0x331976D2), // 20% opacity of primaryColor (#1976D2)
                checkmarkColor: Theme.of(context).primaryColor,
              );
            }).toList(),
          ),
          
          const SizedBox(height: 16),
          
          // Boutons d'action
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Effacer tout'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showFilters = false;
                  });
                },
                child: const Text('Appliquer'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'published':
        return 'Publié';
      case 'draft':
        return 'Brouillon';
      case 'archived':
        return 'Archivé';
      default:
        return status;
    }
  }
}