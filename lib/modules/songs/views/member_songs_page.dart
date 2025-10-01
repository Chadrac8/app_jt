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

/// Page des chants pour les membres - Material Design 3
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
  bool _isSetlistSearchMode = false;

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

  // Méthodes publiques pour contrôler la recherche depuis l'AppBar
  void toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      _isSetlistSearchMode = _tabController.index == 2; // Index 2 = onglet Setlists
      
      if (!_isSearchVisible) {
        _searchQuery = '';
        _setlistSearchQuery = '';
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
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          // TabBar - Style MD3 moderne avec couleur primaire cohérente
          Material(
            color: AppTheme.primaryColor, // Couleur primaire identique à l'AppBar
            elevation: 0,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.onPrimaryColor, // Texte blanc sur fond primaire
              unselectedLabelColor: AppTheme.onPrimaryColor.withOpacity(0.7), // Texte blanc semi-transparent
              indicatorColor: AppTheme.onPrimaryColor, // Indicateur blanc sur fond primaire
              indicatorSize: TabBarIndicatorSize.label,
              indicatorWeight: 3.0,
              labelStyle: GoogleFonts.inter(
                fontSize: AppTheme.fontSize14,
                fontWeight: AppTheme.fontSemiBold,
                letterSpacing: 0.1,
              ),
              unselectedLabelStyle: GoogleFonts.inter(
                fontSize: AppTheme.fontSize14,
                fontWeight: AppTheme.fontMedium,
                letterSpacing: 0.1,
              ),
              splashFactory: InkRipple.splashFactory,
              overlayColor: WidgetStateProperty.resolveWith<Color?>(
                (Set<WidgetState> states) {
                  if (states.contains(WidgetState.pressed)) {
                    return AppTheme.onPrimaryColor.withOpacity(0.12); // Effet blanc sur fond primaire
                  }
                  if (states.contains(WidgetState.hovered)) {
                    return AppTheme.onPrimaryColor.withOpacity(0.08); // Effet blanc sur fond primaire
                  }
                  return null;
                },
              ),
              tabs: const [
                Tab(
                  text: 'Cantiques',
                ),
                Tab(
                  text: 'Favoris',
                ),
                Tab(
                  text: 'Setlists',
                ),
              ],
            ),
          ),
          
          // Divider subtil MD3
          Divider(
            height: 1,
            thickness: 1,
            color: colorScheme.outlineVariant,
          ),
          
          // Barre de recherche locale (conditionnelle) - MD3
          if (_isSearchVisible) _buildSearchBar(),
          
          // Contenu des onglets
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSongsTab(),
                _buildFavoritesTab(),
                _buildSetlistsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMedium, 
        AppTheme.spaceSmall, 
        AppTheme.spaceMedium, 
        AppTheme.spaceSmall
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Champ de recherche MD3
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: _isSetlistSearchMode ? 'Rechercher une setlist...' : 'Rechercher des cantiques...',
              hintStyle: GoogleFonts.inter(
                color: colorScheme.onSurfaceVariant,
                fontSize: AppTheme.fontSize16,
                letterSpacing: 0.15,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: colorScheme.onSurfaceVariant,
                size: 24,
              ),
              suffixIcon: (_isSetlistSearchMode ? _setlistSearchQuery.isNotEmpty : _searchQuery.isNotEmpty)
                  ? IconButton(
                      icon: Icon(
                        Icons.clear_rounded,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () {
                        setState(() {
                          if (_isSetlistSearchMode) {
                            _setlistSearchQuery = '';
                          } else {
                            _searchQuery = '';
                          }
                          _searchController.clear();
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusXXLarge),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusXXLarge),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusXXLarge),
                borderSide: BorderSide(
                  color: colorScheme.primary,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceMedium,
                vertical: AppTheme.spaceMedium,
              ),
            ),
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize16,
              color: colorScheme.onSurface,
              letterSpacing: 0.15,
            ),
            onChanged: (value) {
              setState(() {
                if (_isSetlistSearchMode) {
                  _setlistSearchQuery = value;
                } else {
                  _searchQuery = value;
                }
              });
            },
          ),
          
          const SizedBox(height: AppTheme.spaceSmall),
          
          // Chips de mode de recherche MD3 (seulement pour les cantiques et favoris)
          if (!_isSetlistSearchMode) Row(
            children: [
              Text(
                'Rechercher dans :',
                style: GoogleFonts.inter(
                  fontSize: AppTheme.fontSize12,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: AppTheme.fontMedium,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(width: AppTheme.spaceSmall),
              ChoiceChip(
                label: Text(
                  'Titres',
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize12,
                    fontWeight: AppTheme.fontMedium,
                    letterSpacing: 0.1,
                  ),
                ),
                selected: !_searchInLyrics,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _searchInLyrics = false;
                    });
                  }
                },
                backgroundColor: colorScheme.surfaceContainerHigh,
                selectedColor: colorScheme.secondaryContainer,
                labelStyle: TextStyle(
                  color: !_searchInLyrics 
                      ? colorScheme.onSecondaryContainer 
                      : colorScheme.onSurfaceVariant,
                ),
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceSmall),
              ),
              const SizedBox(width: AppTheme.spaceSmall),
              ChoiceChip(
                label: Text(
                  'Paroles',
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize12,
                    fontWeight: AppTheme.fontMedium,
                    letterSpacing: 0.1,
                  ),
                ),
                selected: _searchInLyrics,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _searchInLyrics = true;
                    });
                  }
                },
                backgroundColor: colorScheme.surfaceContainerHigh,
                selectedColor: colorScheme.secondaryContainer,
                labelStyle: TextStyle(
                  color: _searchInLyrics 
                      ? colorScheme.onSecondaryContainer 
                      : colorScheme.onSurfaceVariant,
                ),
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceSmall),
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
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorState('Erreur de chargement des cantiques', 
              'Impossible de charger les cantiques');
        }

        final allSongs = snapshot.data ?? [];
        final filteredSongs = _filterSongs(allSongs);

        if (filteredSongs.isEmpty) {
          return _buildEmptyState(
            Icons.library_music_outlined,
            allSongs.isEmpty ? 'Aucun cantique disponible' : 'Aucun résultat',
            allSongs.isEmpty 
                ? 'Les cantiques apparaîtront ici une fois ajoutés'
                : 'Essayez de modifier votre recherche'
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          color: Theme.of(context).colorScheme.primary,
          child: ListView.builder(
            padding: const EdgeInsets.only(
              left: AppTheme.spaceMedium,
              right: AppTheme.spaceMedium,
              top: AppTheme.spaceSmall,
              bottom: AppTheme.spaceXXLarge,
            ),
            itemCount: filteredSongs.length,
            itemBuilder: (context, index) {
              final song = filteredSongs[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spaceSmall),
                child: SongCardPerfect13(
                  song: song,
                  songNumber: _getSongNumber(song, allSongs),
                  onTap: () => _showSongDetails(song, allSongs),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFavoritesTab() {
    return FutureBuilder<List<SongModel>>(
      future: SongsFirebaseService.getAllSongs(),
      builder: (context, allSongsSnapshot) {
        if (allSongsSnapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        }

        final allSongs = allSongsSnapshot.data ?? [];

        return StreamBuilder<List<SongModel>>(
          stream: SongsFirebaseService.getFavoriteSongs(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              );
            }

            if (snapshot.hasError) {
              return _buildErrorState('Erreur de chargement des favoris',
                  'Impossible de charger vos cantiques favoris');
            }

            final favoriteSongs = snapshot.data ?? [];
            final filteredSongs = _filterSongs(favoriteSongs);

            if (filteredSongs.isEmpty) {
              return _buildEmptyState(
                Icons.favorite_outline_rounded,
                favoriteSongs.isEmpty ? 'Aucun favori' : 'Aucun résultat',
                favoriteSongs.isEmpty
                    ? 'Ajoutez des cantiques à vos favoris en appuyant sur ♥'
                    : 'Essayez de modifier votre recherche'
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                setState(() {});
              },
              color: Theme.of(context).colorScheme.primary,
              child: ListView.builder(
                padding: const EdgeInsets.only(
                  left: AppTheme.spaceMedium,
                  right: AppTheme.spaceMedium,
                  top: AppTheme.spaceSmall,
                  bottom: AppTheme.spaceXXLarge,
                ),
                itemCount: filteredSongs.length,
                itemBuilder: (context, index) {
                  final song = filteredSongs[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spaceSmall),
                    child: SongCardPerfect13(
                      song: song,
                      songNumber: _getSongNumber(song, allSongs),
                      onTap: () => _showSongDetails(song, allSongs),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSetlistsTab() {
    return StreamBuilder<List<dynamic>>(
      stream: SongsFirebaseService.getSetlists().map((list) => list.cast<dynamic>()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorState('Erreur de chargement des setlists',
              'Impossible de charger les setlists');
        }

        final allSetlists = snapshot.data ?? [];
        final filteredSetlists = _filterSetlists(allSetlists);

        if (filteredSetlists.isEmpty) {
          return _buildEmptyState(
            Icons.playlist_play_outlined,
            allSetlists.isEmpty ? 'Aucune setlist disponible' : 'Aucun résultat',
            allSetlists.isEmpty 
                ? 'Les setlists créées apparaîtront ici'
                : 'Essayez de modifier votre recherche'
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          color: Theme.of(context).colorScheme.primary,
          child: ListView.builder(
            padding: const EdgeInsets.only(
              left: AppTheme.spaceMedium,
              right: AppTheme.spaceMedium,
              top: AppTheme.spaceSmall,
              bottom: AppTheme.spaceXXLarge,
            ),
            itemCount: filteredSetlists.length,
            itemBuilder: (context, index) {
              final setlist = filteredSetlists[index];
              return SetlistCardPerfect13(
                  setlist: setlist,
                  onTap: () => _showSetlistDetails(setlist),
                  onMusicianMode: () => _startMusicianMode(setlist),
                  onConductorMode: () => _startConductorMode(setlist),
                );
            },
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String title, String message) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize18,
                fontWeight: AppTheme.fontSemiBold,
                color: colorScheme.onSurface,
                letterSpacing: 0.15,
              ),
            ),
            const SizedBox(height: AppTheme.spaceSmall),
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize14,
                color: colorScheme.onSurfaceVariant,
                letterSpacing: 0.25,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            FilledButton.icon(
              onPressed: () {
                setState(() {});
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String message) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize18,
                fontWeight: AppTheme.fontSemiBold,
                color: colorScheme.onSurface,
                letterSpacing: 0.15,
              ),
            ),
            const SizedBox(height: AppTheme.spaceSmall),
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize14,
                color: colorScheme.onSurfaceVariant,
                letterSpacing: 0.25,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showSongDetails(SongModel song, List<SongModel> allSongs) {
    final colorScheme = Theme.of(context).colorScheme;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 1.0,
          minChildSize: 1.0,
          maxChildSize: 1.0,
          builder: (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusLarge),
              ),
            ),
            child: Column(
              children: [
                // En-tête avec titre et actions MD3
                Container(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spaceSmall,
                    AppTheme.spaceSmall,
                    AppTheme.spaceSmall,
                    0,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                        style: IconButton.styleFrom(
                          foregroundColor: colorScheme.onSurface,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.title,
                              style: GoogleFonts.inter(
                                fontSize: AppTheme.fontSize20,
                                fontWeight: AppTheme.fontSemiBold,
                                color: colorScheme.onSurface,
                                letterSpacing: 0.15,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (allSongs.isNotEmpty)
                              Text(
                                'Cantique n°${_getSongNumber(song, allSongs)}',
                                style: GoogleFonts.inter(
                                  fontSize: AppTheme.fontSize12,
                                  color: colorScheme.onSurfaceVariant,
                                  letterSpacing: 0.4,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.fullscreen_rounded),
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
                        style: IconButton.styleFrom(
                          foregroundColor: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                Divider(
                  height: 1,
                  color: colorScheme.outlineVariant,
                ),
                
                // Visualiseur de paroles
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

  List<SongModel> _filterSongs(List<SongModel> songs) {
    List<SongModel> filteredSongs;
    
    if (_searchQuery.isEmpty) {
      filteredSongs = songs;
    } else {
      final query = _searchQuery.toLowerCase().trim();
      // Diviser la requête en mots individuels
      final searchWords = query.split(RegExp(r'\s+'));
      
      filteredSongs = songs.where((song) {
        if (_searchInLyrics) {
          final titleLower = song.title.toLowerCase();
          final lyricsLower = song.lyrics.toLowerCase();
          
          // Tous les mots doivent être trouvés soit dans le titre soit dans les paroles
          return searchWords.every((word) => 
            titleLower.contains(word) || lyricsLower.contains(word)
          );
        } else {
          final titleLower = song.title.toLowerCase();
          
          // Tous les mots doivent être trouvés dans le titre
          return searchWords.every((word) => titleLower.contains(word));
        }
      }).toList();
    }

    // Tri alphabétique par titre
    filteredSongs.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    
    return filteredSongs;
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Mode musicien - Fonctionnalité en cours de développement',
          style: GoogleFonts.inter(letterSpacing: 0.25),
        ),
        backgroundColor: Theme.of(context).colorScheme.inverseSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
      ),
    );
  }

  void _startConductorMode(dynamic setlist) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Mode chef de chœur - Fonctionnalité en cours de développement',
          style: GoogleFonts.inter(letterSpacing: 0.25),
        ),
        backgroundColor: Theme.of(context).colorScheme.inverseSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
      ),
    );
  }
}