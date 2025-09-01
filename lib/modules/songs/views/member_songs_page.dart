import 'package:flutter/material.dart';
import '../models/song_model.dart';
import '../services/songs_firebase_service.dart';
import '../widgets/setlists_tab_perfect13.dart';
import '../widgets/songs_tab_perfect13.dart';
import '../../../widgets/song_card_perfect13.dart';
import '../../../widgets/song_search_filter_bar.dart';
import '../../../widgets/song_lyrics_viewer.dart';
import '../../../pages/song_projection_page.dart';

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
  String? _selectedStyle;
  String? _selectedKey;
  List<String> _selectedTags = [];

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
      appBar: AppBar(
        title: const Text('Cantiques'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.library_music), text: 'Chants'),
            Tab(icon: Icon(Icons.favorite), text: 'Favoris'),
            Tab(icon: Icon(Icons.playlist_play), text: 'Setlists'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Barre de recherche et filtres
          SongSearchFilterBar(
            onSearchChanged: (query) {
              setState(() {
                _searchQuery = query;
              });
            },
            onStyleChanged: (style) {
              setState(() {
                _selectedStyle = style;
              });
            },
            onKeyChanged: (key) {
              setState(() {
                _selectedKey = key;
              });
            },
            onStatusChanged: (status) {
              // Les membres ne filtrent pas par statut
            },
            onTagsChanged: (tags) {
              setState(() {
                _selectedTags = tags;
              });
            },
          ),
          
          // Contenu des onglets
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                const SongsTabPerfect13(), // Onglet Chants - reproduction exacte de Perfect 13
                _buildFavoriteSongsTab(),
                const SetlistsTabPerfect13(), // Reproduction exacte de Perfect 13
              ],
            ),
          ),
        ],
      ),
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
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Erreur: ${snapshot.error}'),
              ],
            ),
          );
        }

        final songs = _filterSongs(snapshot.data ?? []);

        if (songs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Aucun chant favori',
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
          padding: const EdgeInsets.all(16),
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

  List<SongModel> _filterSongs(List<SongModel> songs) {
    var filtered = songs;

    // Filtrer par recherche textuelle
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((song) =>
          song.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          song.authors.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          song.lyrics.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          song.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()))
      ).toList();
    }

    // Filtrer par style
    if (_selectedStyle != null && _selectedStyle!.isNotEmpty) {
      filtered = filtered.where((song) => song.style == _selectedStyle).toList();
    }

    // Filtrer par tonalité
    if (_selectedKey != null && _selectedKey!.isNotEmpty) {
      filtered = filtered.where((song) => song.originalKey == _selectedKey).toList();
    }

    // Filtrer par tags
    if (_selectedTags.isNotEmpty) {
      filtered = filtered.where((song) =>
          _selectedTags.any((tag) => song.tags.contains(tag))
      ).toList();
    }

    return filtered;
  }

  void _showSongDetails(SongModel song) {
    // Incrémenter le compteur d'utilisation
    SongsFirebaseService.incrementSongUsage(song.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
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
                    Text(
                      song.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
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