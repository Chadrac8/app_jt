import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/song_model.dart';
import '../services/songs_firebase_service.dart';
import '../../../widgets/song_card_perfect13.dart';
import '../../../widgets/song_lyrics_viewer.dart';
import '../../../pages/song_projection_page.dart';
import '../../../widgets/setlist_card_perfect13.dart';
import '../../../pages/setlist_detail_page.dart';
import '../../../../theme.dart';
import '../../../theme.dart';

/// Page des chants pour les membres
class MemberSongsPage extends StatefulWidget {
  final Function(VoidCallback)? onToggleSearchChanged;

  const MemberSongsPage({super.key, this.onToggleSearchChanged});

  @override
  State<MemberSongsPage> createState() => _MemberSongsPageState();
}

class _MemberSongsPageState extends State<MemberSongsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  bool _searchInLyrics = false;
  bool _isSearchVisible = false;
  final TextEditingController _searchController = TextEditingController();
  
  // Variables pour les setlists
  String _setlistSearchQuery = '';
  String? _selectedSetlistFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Enregistrer le callback pour le bouton de recherche de l'AppBar
    widget.onToggleSearchChanged?.call(toggleSearch);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Méthode publique pour contrôler la recherche depuis l'AppBar
  void toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (!_isSearchVisible) {
        _searchQuery = '';
        _searchController.clear();
      }
    });
  }

  void toggleSearchMode() {
    setState(() {
      _searchInLyrics = !_searchInLyrics;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          // Barre de recherche (visible conditionnellement)
          if (_isSearchVisible) _buildSearchBar(),
          
          // TabBar en haut - Material Design 3 conforme
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor, // Couleur primaire cohérente
              boxShadow: [
                BoxShadow(
                  color: AppTheme.black100.withOpacity(0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: TabBar(
                controller: _tabController,
                labelColor: AppTheme.onPrimaryColor, // Texte blanc
                unselectedLabelColor: AppTheme.onPrimaryColor.withOpacity(0.7), // Texte blanc semi-transparent
                indicatorColor: AppTheme.onPrimaryColor, // Indicateur blanc
                indicatorWeight: 3.0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                labelStyle: GoogleFonts.inter(
                  fontSize: AppTheme.fontSize14,
                  fontWeight: AppTheme.fontSemiBold,
                ),
                unselectedLabelStyle: GoogleFonts.inter(
                  fontSize: AppTheme.fontSize14,
                  fontWeight: AppTheme.fontMedium,
                ),
                tabs: const [
                  Tab(
                    text: 'Chants',
                    iconMargin: EdgeInsets.only(bottom: 4),
                  ),
                  Tab(
                    text: 'Favoris',
                    iconMargin: EdgeInsets.only(bottom: 4),
                  ),
                  Tab(
                    text: 'Setlists',
                    iconMargin: EdgeInsets.only(bottom: 4),
                  ),
                ],
              ),
            ),
          ),
          
          // Contenu des onglets
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSongsTab(),
                  _buildFavoriteSongsTab(),
                  _buildSetlistsTab(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: _searchInLyrics 
                  ? 'Rechercher dans les paroles...' 
                  : 'Rechercher dans les titres...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppTheme.grey500),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppTheme.grey500),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppTheme.primaryColor),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: AppTheme.space12),
          Row(
            children: [
              const Text('Rechercher dans: '),
              const SizedBox(width: AppTheme.space12),
              ChoiceChip(
                label: const Text('Titre'),
                selected: !_searchInLyrics,
                onSelected: (selected) {
                  setState(() {
                    _searchInLyrics = false;
                  });
                },
                selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: !_searchInLyrics ? AppTheme.primaryColor : null,
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              ChoiceChip(
                label: const Text('Paroles'),
                selected: _searchInLyrics,
                onSelected: (selected) {
                  setState(() {
                    _searchInLyrics = true;
                  });
                },
                selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: _searchInLyrics ? AppTheme.primaryColor : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSongsTab() {
    return FutureBuilder<List<SongModel>>(
      future: SongsFirebaseService.getAllSongs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: AppTheme.redStandard),
                const SizedBox(height: AppTheme.spaceMedium),
                Text('Erreur: ${snapshot.error}'),
              ],
            ),
          );
        }

        final songs = _filterSongs(snapshot.data ?? []);
        songs.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

        if (songs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.music_note, size: 64, color: AppTheme.grey500),
                SizedBox(height: AppTheme.spaceMedium),
                Text(
                  'Aucun chant trouvé',
                  style: TextStyle(fontSize: AppTheme.fontSize18, color: AppTheme.grey500),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            return SongCardPerfect13(
              song: song,
              songNumber: _getSongNumber(song, snapshot.data ?? []),
              onTap: () => _showSongDetails(song),
            );
          },
        );
      },
    );
  }

  Widget _buildFavoriteSongsTab() {
    return StreamBuilder<List<SongModel>>(
      stream: SongsFirebaseService.getFavoriteSongs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: AppTheme.redStandard),
                const SizedBox(height: AppTheme.spaceMedium),
                Text('Erreur: ${snapshot.error}'),
              ],
            ),
          );
        }

        final songs = _filterSongs(snapshot.data ?? []);
        songs.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

        if (songs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border, size: 64, color: AppTheme.grey500),
                SizedBox(height: AppTheme.spaceMedium),
                Text(
                  'Aucun chant favori trouvé',
                  style: TextStyle(fontSize: AppTheme.fontSize18, color: AppTheme.grey500),
                ),
                SizedBox(height: AppTheme.spaceSmall),
                Text(
                  'Ajoutez des chants à vos favoris en touchant le cœur',
                  style: TextStyle(color: AppTheme.grey500),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            return SongCardPerfect13(
              song: song,
              songNumber: _getSongNumber(song, snapshot.data ?? []),
              onTap: () => _showSongDetails(song),
            );
          },
        );
      },
    );
  }

  Widget _buildSetlistsTab() {
    return Column(
      children: [
        // Barre de recherche et filtres pour setlists
        Container(
          padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
          child: Column(
            children: [
              // Recherche de setlists
              TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher une setlist...',
                  prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppTheme.grey500)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppTheme.grey500)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppTheme.primaryColor)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                onChanged: (value) {
                  setState(() {
                    _setlistSearchQuery = value;
                  });
                }),
              
              const SizedBox(height: AppTheme.space12),
              
              // Filtres rapides
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildSetlistFilterChip('Tous', null),
                    const SizedBox(width: AppTheme.spaceSmall),
                    _buildSetlistFilterChip('Cette semaine', 'week'),
                    const SizedBox(width: AppTheme.spaceSmall),
                    _buildSetlistFilterChip('Ce mois', 'month'),
                    const SizedBox(width: AppTheme.spaceSmall),
                    _buildSetlistFilterChip('Favoris', 'favorites'),
                    const SizedBox(width: AppTheme.spaceSmall),
                    _buildSetlistFilterChip('Récents', 'recent'),
                  ])),
            ])),
        
        // Liste des setlists
        Expanded(
          child: StreamBuilder<List<dynamic>>(
            stream: SongsFirebaseService.getSetlists(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.error),
                      const SizedBox(height: AppTheme.spaceMedium),
                      Text(
                        'Erreur de chargement',
                        style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: AppTheme.spaceSmall),
                      Text(
                        'Impossible de charger les setlists',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      const SizedBox(height: AppTheme.spaceMedium),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {});
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Réessayer')),
                    ]));
              }

              final allSetlists = snapshot.data ?? [];
              final filteredSetlists = _filterSetlists(allSetlists);

              if (filteredSetlists.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.playlist_play_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(height: AppTheme.spaceMedium),
                      Text(
                        allSetlists.isEmpty ? 'Aucune setlist disponible' : 'Aucun résultat',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      const SizedBox(height: AppTheme.spaceSmall),
                      Text(
                        allSetlists.isEmpty 
                          ? 'Les setlists créées apparaîtront ici'
                          : 'Essayez de modifier votre recherche',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ]));
              }

              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {});
                },
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: filteredSetlists.length,
                  itemBuilder: (context, index) {
                    final setlist = filteredSetlists[index];
                    return SetlistCardPerfect13(
                      setlist: setlist,
                      onTap: () => _showSetlistDetails(setlist),
                      onMusicianMode: () => _startMusicianMode(setlist),
                      onConductorMode: () => _startConductorMode(setlist),
                    );
                  }));
            })),
      ]);
  }

  List<SongModel> _filterSongs(List<SongModel> songs) {
    if (_searchQuery.isEmpty) {
      return songs;
    }

    return songs.where((song) {
      final query = _searchQuery.toLowerCase();
      if (_searchInLyrics) {
        return song.lyrics.toLowerCase().contains(query);
      } else {
        return song.title.toLowerCase().contains(query) ||
               song.authors.toLowerCase().contains(query);
      }
    }).toList();
  }

  void _showSongDetails(SongModel song) {
    SongsFirebaseService.incrementSongUsage(song.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 1.0,
          minChildSize: 1.0,
          maxChildSize: 1.0,
          expand: false,
          builder: (context, scrollController) => Container(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(AppTheme.radius2),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          song.title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: AppTheme.fontBold,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceSmall),
                      
                      StreamBuilder<List<String>>(
                        stream: SongsFirebaseService.getUserFavorites(),
                        builder: (context, snapshot) {
                          final favoriteSongIds = snapshot.data ?? [];
                          final isFavorite = favoriteSongIds.contains(song.id);
                          
                          return IconButton(
                            icon: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: isFavorite ? AppTheme.redStandard : null,
                            ),
                            onPressed: () async {
                              if (isFavorite) {
                                await SongsFirebaseService.removeFromFavorites(song.id);
                              } else {
                                await SongsFirebaseService.addToFavorites(song.id);
                              }
                            },
                            tooltip: isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
                          );
                        },
                      ),
                      
                      IconButton(
                        icon: const Icon(Icons.present_to_all),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SongProjectionPage(song: song),
                            ),
                          );
                        },
                        tooltip: 'Mode projection',
                      ),
                      
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              
              const Divider(),
              
              Expanded(
                child: SongLyricsViewer(
                  song: song,
                  onToggleProjection: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SongProjectionPage(song: song),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  int _getSongNumber(SongModel song, List<SongModel> allSongs) {
    // Utiliser le numéro du chant s'il existe, sinon calculer basé sur la position
    if (song.number != null && song.number! > 0) {
      return song.number!;
    }
    
    final sortedSongs = List<SongModel>.from(allSongs);
    sortedSongs.sort((a, b) {
      // Tri par numéro d'abord, puis par titre
      if (a.number != null && b.number != null) {
        return a.number!.compareTo(b.number!);
      } else if (a.number != null) {
        return -1; // a avec numéro avant b sans numéro
      } else if (b.number != null) {
        return 1; // b avec numéro avant a sans numéro
      } else {
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      }
    });
    
    for (int i = 0; i < sortedSongs.length; i++) {
      if (sortedSongs[i].id == song.id) {
        return sortedSongs[i].number ?? (i + 1);
      }
    }
    return song.number ?? 0;
  }

  // Méthodes pour les setlists
  Widget _buildSetlistFilterChip(String label, String? filterType) {
    final isSelected = _selectedSetlistFilter == filterType;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedSetlistFilter = selected ? filterType : null;
        });
      },
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: isSelected 
          ? Theme.of(context).colorScheme.onPrimaryContainer
          : Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal));
  }

  List<dynamic> _filterSetlists(List<dynamic> setlists) {
    var filtered = setlists.where((setlist) {
      if (_setlistSearchQuery.isNotEmpty) {
        final name = setlist.name?.toString().toLowerCase() ?? '';
        final description = setlist.description?.toString().toLowerCase() ?? '';
        final query = _setlistSearchQuery.toLowerCase();
        if (!name.contains(query) && !description.contains(query)) {
          return false;
        }
      }

      if (_selectedSetlistFilter != null) {
        switch (_selectedSetlistFilter) {
          case 'week':
            final weekAgo = DateTime.now().subtract(const Duration(days: 7));
            return setlist.createdAt?.isAfter(weekAgo) ?? false;
          case 'month':
            final monthAgo = DateTime.now().subtract(const Duration(days: 30));
            return setlist.createdAt?.isAfter(monthAgo) ?? false;
          case 'favorites':
            return setlist.isFavorite ?? false;
          case 'recent':
            final recentLimit = DateTime.now().subtract(const Duration(days: 14));
            return setlist.lastUsed?.isAfter(recentLimit) ?? false;
        }
      }

      return true;
    }).toList();

    return filtered;
  }

  void _showSetlistDetails(dynamic setlist) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SetlistDetailPage(setlist: setlist),
      ),
    );
  }

  void _startMusicianMode(dynamic setlist) {
    // Navigation vers le mode musicien
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mode musicien - Fonctionnalité en cours de développement')),
    );
  }

  void _startConductorMode(dynamic setlist) {
    // Navigation vers le mode chef de chœur
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mode chef de chœur - Fonctionnalité en cours de développement')),
    );
  }
}