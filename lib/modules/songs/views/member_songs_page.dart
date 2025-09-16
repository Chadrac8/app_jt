import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/song_model.dart';
import '../services/songs_firebase_service.dart';
import '../widgets/setlists_tab_perfect13.dart';
import '../../../widgets/song_card_perfect13.dart';
import '../../../widgets/song_lyrics_viewer.dart';
import '../../../pages/song_projection_page.dart';
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
  bool _searchInLyrics = false; // false = titre, true = paroles
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // 3 onglets maintenant
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: Column(
        children: [
          // TabBar en haut
          Container(
            height: 42, // Hauteur réduite de la TabBar
            decoration: BoxDecoration(
              color: const Color(0xFF860505), // Rouge bordeaux comme l'AppBar
              boxShadow: [
                BoxShadow(
                  color: AppTheme.textTertiaryColor.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.white, // Texte blanc pour onglet sélectionné
                unselectedLabelColor: Colors.white.withOpacity(0.7), // Texte blanc semi-transparent pour onglets non sélectionnés
                indicatorColor: Colors.white, // Indicateur blanc
                indicatorWeight: 3,
                labelStyle: GoogleFonts.poppins(
                  fontSize: 13, // Taille de police légèrement réduite
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: GoogleFonts.poppins(
                  fontSize: 13, // Taille de police légèrement réduite
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(
                    text: 'Chants',
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
          ),
          
          // Contenu des onglets
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSongsTabWithSearch(), // Onglet Chants avec recherche
                  _buildFavoriteSongsTabWithSearch(), // Onglet Favoris avec recherche
                  const SetlistsTabPerfect13(), // Reproduction exacte de Perfect 13
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
              hintText: _searchInLyrics ? 'Rechercher dans les paroles...' : 'Rechercher dans les titres...',
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
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
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
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Rechercher dans: '),
              const SizedBox(width: 12),
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
              const SizedBox(width: 12),
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

  Widget _buildSongsTabWithSearch() {
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: FutureBuilder<List<SongModel>>(
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
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Erreur: ${snapshot.error}'),
                    ],
                  ),
                );
              }

              final songs = _filterSongs(snapshot.data ?? []);
              // Trier par titre pour maintenir la numérotation alphabétique
              songs.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

              if (songs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.music_note, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Aucun chant trouvé',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
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
          ),
        ),
      ],
    );
  }

  Widget _buildFavoriteSongsTabWithSearch() {
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: StreamBuilder<List<SongModel>>(
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
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Erreur: ${snapshot.error}'),
                    ],
                  ),
                );
              }

              final songs = _filterSongs(snapshot.data ?? []);
              // Trier par titre pour maintenir la numérotation alphabétique
              songs.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

              if (songs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Aucun chant favori trouvé',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Ajoutez des chants à vos favoris en touchant le cœur',
                        style: TextStyle(color: Colors.grey),
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
          ),
        ),
      ],
    );
  }

  List<SongModel> _filterSongs(List<SongModel> songs) {
    if (_searchQuery.isEmpty) {
      return songs;
    }

    return songs.where((song) {
      final query = _searchQuery.toLowerCase();
      if (_searchInLyrics) {
        // Rechercher dans les paroles
        return song.lyrics.toLowerCase().contains(query);
      } else {
        // Rechercher dans le titre
        return song.title.toLowerCase().contains(query);
      }
    }).toList();
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
                    borderRadius: BorderRadius.circular(2),
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
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      
                      // Bouton favoris
                      StreamBuilder<List<String>>(
                        stream: SongsFirebaseService.getUserFavorites(),
                        builder: (context, snapshot) {
                          final favoriteSongIds = snapshot.data ?? [];
                          final isFavorite = favoriteSongIds.contains(song.id);
                          
                          return IconButton(
                            icon: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: isFavorite ? Colors.red : null,
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

  /// Calcule le numéro d'un chant basé sur l'ordre alphabétique
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