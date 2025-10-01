import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/song_model.dart';
import '../services/songs_firebase_service.dart';
import '../widgets/setlists_tab_perfect13.dart';
import '../../../widgets/song_lyrics_viewer.dart';
import '../../../pages/song_projection_page.dart';
import '../../../theme.dart';

/// Page des cantiques pour les membres - Material Design 3
class MemberSongsPage extends StatefulWidget {
  const MemberSongsPage({super.key});

  @override
  State<MemberSongsPage> createState() => _MemberSongsPageState();
}

class _MemberSongsPageState extends State<MemberSongsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _cardAnimationController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Démarrer l'animation des cartes
    _cardAnimationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // TabBar modernisée sous l'AppBar principale
        _buildTabBar(),
        
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
    );
  }

  Widget _buildTabBar() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor, // Couleur primaire cohérente
        borderRadius: BorderRadius.circular(28),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: AppTheme.onPrimaryColor.withOpacity(0.2), // Indicateur blanc semi-transparent
          borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(AppTheme.spaceXSmall),
        labelStyle: GoogleFonts.inter(
          fontSize: AppTheme.fontSize14,
          fontWeight: AppTheme.fontSemiBold,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: AppTheme.fontSize14,
          fontWeight: AppTheme.fontMedium,
        ),
        labelColor: AppTheme.onPrimaryColor, // Texte blanc
        unselectedLabelColor: AppTheme.onPrimaryColor.withOpacity(0.7), // Texte blanc semi-transparent
        tabs: const [
          Tab(text: 'Cantiques'),
          Tab(text: 'Favoris'),
          Tab(text: 'Setlists'),
        ],
      ),
    );
  }

  Widget _buildSongsTab() {
    return Column(
      children: [
        // Liste des chants
        Expanded(
          child: FutureBuilder<List<SongModel>>(
            future: SongsFirebaseService.getAllSongs(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingState();
              }

              if (snapshot.hasError) {
                return _buildErrorState(snapshot.error.toString());
              }

              final songs = snapshot.data ?? [];
              // Trier par titre pour maintenir la numérotation alphabétique
              songs.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

              if (songs.isEmpty) {
                return _buildEmptyState();
              }

              return _buildSongsList(songs);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchOptions() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Text(
            'Rechercher dans:',
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize14,
              fontWeight: AppTheme.fontMedium,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: AppTheme.spaceMedium),
          
          // Chip Titre
          FilterChip(
            label: Text('Titre'),
            selected: !_searchInLyrics,
            onSelected: (selected) {
              setState(() {
                _searchInLyrics = false;
              });
            },
            backgroundColor: colorScheme.surfaceContainer,
            selectedColor: colorScheme.secondaryContainer,
            labelStyle: GoogleFonts.inter(
              fontSize: AppTheme.fontSize13,
              fontWeight: AppTheme.fontMedium,
              color: !_searchInLyrics 
                  ? colorScheme.onSecondaryContainer 
                  : colorScheme.onSurfaceVariant,
            ),
            side: BorderSide(
              color: !_searchInLyrics 
                  ? colorScheme.secondary 
                  : colorScheme.outline,
              width: 1,
            ),
          ),
          
          const SizedBox(width: AppTheme.spaceSmall),
          
          // Chip Paroles
          FilterChip(
            label: Text('Paroles'),
            selected: _searchInLyrics,
            onSelected: (selected) {
              setState(() {
                _searchInLyrics = true;
              });
            },
            backgroundColor: colorScheme.surfaceContainer,
            selectedColor: colorScheme.secondaryContainer,
            labelStyle: GoogleFonts.inter(
              fontSize: AppTheme.fontSize13,
              fontWeight: AppTheme.fontMedium,
              color: _searchInLyrics 
                  ? colorScheme.onSecondaryContainer 
                  : colorScheme.onSurfaceVariant,
            ),
            side: BorderSide(
              color: _searchInLyrics 
                  ? colorScheme.secondary 
                  : colorScheme.outline,
              width: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: colorScheme.primary,
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          Text(
            'Chargement des cantiques...',
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize16,
              fontWeight: AppTheme.fontMedium,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceXLarge),
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
              'Erreur de chargement',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize20,
                fontWeight: AppTheme.fontSemiBold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppTheme.spaceSmall),
            Text(
              error,
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize14,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty ? Icons.search_off_rounded : Icons.music_note_rounded,
              size: 64,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            Text(
              _searchQuery.isNotEmpty ? 'Aucun résultat' : 'Aucun cantique',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize20,
                fontWeight: AppTheme.fontSemiBold,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppTheme.spaceSmall),
            Text(
              _searchQuery.isNotEmpty 
                  ? 'Essayez avec d\'autres mots-clés'
                  : 'Les cantiques apparaîtront ici',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize14,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongsList(List<SongModel> songs) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return AnimatedBuilder(
          animation: _cardAnimationController,
          builder: (context, child) {
            final offset = index * 0.1;
            
            return FadeTransition(
              opacity: Tween<double>(begin: 0, end: 1).animate(
                CurvedAnimation(
                  parent: _cardAnimationController,
                  curve: Interval(offset, (offset + 0.3).clamp(0.0, 1.0), curve: Curves.easeOut),
                ),
              ),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _cardAnimationController,
                    curve: Interval(offset, (offset + 0.3).clamp(0.0, 1.0), curve: Curves.easeOutCubic),
                  ),
                ),
                child: _buildSongCard(song, _getSongNumber(song, songs), index),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSongCard(SongModel song, int songNumber, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        elevation: 0,
        child: InkWell(
          onTap: () => _showSongDetails(song),
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Numéro du cantique
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  ),
                  child: Center(
                    child: Text(
                      '$songNumber',
                      style: GoogleFonts.inter(
                        fontSize: AppTheme.fontSize16,
                        fontWeight: AppTheme.fontBold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: AppTheme.spaceMedium),
                
                // Informations du cantique
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        style: GoogleFonts.inter(
                          fontSize: AppTheme.fontSize16,
                          fontWeight: AppTheme.fontSemiBold,
                          color: colorScheme.onSurface,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      if (song.authors.isNotEmpty) ...[
                        const SizedBox(height: AppTheme.spaceXSmall),
                        Text(
                          'Par ${song.authors}',
                          style: GoogleFonts.inter(
                            fontSize: AppTheme.fontSize13,
                            fontWeight: AppTheme.fontMedium,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      
                      if (song.lyrics.isNotEmpty) ...[
                        const SizedBox(height: AppTheme.space6),
                        Text(
                          _getPreviewText(song.lyrics),
                          style: GoogleFonts.inter(
                            fontSize: AppTheme.fontSize12,
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Bouton favoris
                const SizedBox(width: AppTheme.spaceSmall),
                StreamBuilder<List<String>>(
                  stream: SongsFirebaseService.getUserFavorites(),
                  builder: (context, snapshot) {
                    final favoriteSongIds = snapshot.data ?? [];
                    final isFavorite = favoriteSongIds.contains(song.id);
                    
                    return IconButton(
                      onPressed: () async {
                        if (isFavorite) {
                          await SongsFirebaseService.removeFromFavorites(song.id);
                        } else {
                          await SongsFirebaseService.addToFavorites(song.id);
                        }
                      },
                      icon: Icon(
                        isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isFavorite ? colorScheme.error : colorScheme.onSurface.withValues(alpha: 0.5),
                        size: 20,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFavoritesTab() {
    return StreamBuilder<List<SongModel>>(
      stream: SongsFirebaseService.getFavoriteSongs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final favorites = snapshot.data ?? [];
        // Trier par titre pour maintenir la numérotation alphabétique
        favorites.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

        if (favorites.isEmpty) {
          return _buildFavoritesEmptyState();
        }

        return _buildSongsList(favorites);
      },
    );
  }

  Widget _buildFavoritesEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 64,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            Text(
              _searchQuery.isNotEmpty ? 'Aucun favori trouvé' : 'Aucun cantique favori',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize20,
                fontWeight: AppTheme.fontSemiBold,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppTheme.spaceSmall),
            Text(
              _searchQuery.isNotEmpty 
                  ? 'Essayez avec d\'autres mots-clés'
                  : 'Ajoutez des cantiques à vos favoris\nen touchant le cœur',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize14,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetlistsTab() {
    return const SetlistsTabPerfect13();
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

  String _getPreviewText(String lyrics) {
    // Prendre les premiers mots des paroles pour l'aperçu
    final words = lyrics.trim().split(RegExp(r'\s+'));
    if (words.length <= 8) return lyrics;
    return '${words.take(8).join(' ')}...';
  }

  void _showSongDetails(SongModel song) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Incrémenter le compteur d'utilisation
    SongsFirebaseService.incrementSongUsage(song.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.95,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Poignée de déplacement
              Container(
                width: 32,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(AppTheme.radius2),
                ),
              ),
              
              // En-tête avec actions
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            style: GoogleFonts.inter(
                              fontSize: AppTheme.fontSize20,
                              fontWeight: AppTheme.fontBold,
                              color: colorScheme.onSurface,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (song.authors.isNotEmpty) ...[
                            const SizedBox(height: AppTheme.spaceXSmall),
                            Text(
                              'Par ${song.authors}',
                              style: GoogleFonts.inter(
                                fontSize: AppTheme.fontSize14,
                                fontWeight: AppTheme.fontMedium,
                                color: colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // Actions
                    Row(
                      children: [
                        // Bouton favoris
                        StreamBuilder<List<String>>(
                          stream: SongsFirebaseService.getUserFavorites(),
                          builder: (context, snapshot) {
                            final favoriteSongIds = snapshot.data ?? [];
                            final isFavorite = favoriteSongIds.contains(song.id);
                            
                            return FilledButton.tonal(
                              onPressed: () async {
                                if (isFavorite) {
                                  await SongsFirebaseService.removeFromFavorites(song.id);
                                } else {
                                  await SongsFirebaseService.addToFavorites(song.id);
                                }
                              },
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(48, 48),
                                padding: EdgeInsets.zero,
                                backgroundColor: isFavorite 
                                    ? colorScheme.errorContainer 
                                    : colorScheme.surfaceContainer,
                              ),
                              child: Icon(
                                isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                color: isFavorite 
                                    ? colorScheme.error 
                                    : colorScheme.onSurfaceVariant,
                                size: 20,
                              ),
                            );
                          },
                        ),
                        
                        const SizedBox(width: AppTheme.spaceSmall),
                        
                        // Bouton projection
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SongProjectionPage(song: song),
                              ),
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                          ),
                          icon: const Icon(Icons.present_to_all_rounded, size: 18),
                          label: Text(
                            'Projeter',
                            style: GoogleFonts.inter(
                              fontSize: AppTheme.fontSize14,
                              fontWeight: AppTheme.fontSemiBold,
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: AppTheme.spaceSmall),
                        
                        // Bouton fermer
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.close_rounded,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              Divider(
                color: colorScheme.outline.withValues(alpha: 0.2),
                height: 1,
              ),
              
              // Contenu des paroles
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
    );
  }

  int _getSongNumber(SongModel song, List<SongModel> allSongs) {
    // Trier par titre pour la numérotation alphabétique
    final sortedSongs = List<SongModel>.from(allSongs);
    sortedSongs.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    
    for (int i = 0; i < sortedSongs.length; i++) {
      if (sortedSongs[i].id == song.id) {
        return i + 1;
      }
    }
    return 0;
  }
}