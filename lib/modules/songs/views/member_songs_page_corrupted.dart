import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/song_model.dart';
import '../services/songs_firebase_service.dart';
import '../../../widgets/song_card_perfect13.dart';
import '../../../widgets/song_lyrics_viewer.dart';
import '../../../pages/song_projection_page.dart';
import '../../../../theme.dart';
import '../../../theme.dart';

/// Page des chants pour les membres
class MemberSongsPage extends StatefulWidget {
  const MemberSongsPage({super.key});

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
  State<MemberSongsPage> createState() => _MemberSongsPageState();
}

class _MemberSongsPageState extends State<MemberSongsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // 3 onglets maintenant
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          // TabBar en haut - Material Design 3 conforme
          Container(
            height: 50, // Hauteur Material Design standard
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor, // Harmonisé avec AppBar transparente membre
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
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: AppTheme.textSecondaryColor,
                indicatorColor: AppTheme.primaryColor,
                indicatorWeight: 3.0, // Poids standard Material Design
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
                  _buildSongsTab(), // Onglet Chants sans recherche
                  _buildFavoriteSongsTab(), // Onglet Favoris sans recherche
                  _buildSetlistsTab(), // Onglet Setlists temporaire
                ],
              ),
            ),
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

        final songs = snapshot.data ?? [];
        // Trier par titre pour maintenir la numérotation alphabétique
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
              songNumber: _getSongNumber(song, songs),
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

        final songs = snapshot.data ?? [];
        // Trier par titre pour maintenir la numérotation alphabétique
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
              songNumber: _getSongNumber(song, songs),
              onTap: () => _showSongDetails(song),
            );
          },
        );
      },
    );
  }

  void _showSongDetails(SongModel song) {
    // Incrémenter le compteur d'utilisation
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
                // Poignée de déplacement
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(AppTheme.radius2),
                  ),
                ),
                
                // Barre d'actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // Titre avec gestion du débordement
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
                      
                      // Bouton favoris
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
                      
                      // Bouton projection
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
                      
                      // Bouton fermer
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              
              const Divider(),
              
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
      ),
    );
  }

  /// Calcule le numéro d'un chant basé sur le numéro assigné ou l'ordre alphabétique
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

  Widget _buildSetlistsTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.playlist_play, size: 64, color: AppTheme.grey500),
          SizedBox(height: AppTheme.spaceMedium),
          Text(
            'Setlists',
            style: TextStyle(fontSize: AppTheme.fontSize18, color: AppTheme.grey500),
          ),
          SizedBox(height: AppTheme.spaceSmall),
          Text(
            'Fonctionnalité en cours de développement',
            style: TextStyle(color: AppTheme.grey500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}