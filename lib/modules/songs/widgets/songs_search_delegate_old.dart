import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/song_model.dart';
import '../services/songs_firebase_service.dart';
import '../../../widgets/song_card_perfect13.dart';

/// SearchDelegate Material Design 3 pour la recherche des cantiques
class SongsSearchDelegate extends SearchDelegate<SongModel?> {
  bool searchInLyrics;
  final Function(SongModel) onSongSelected;
  final Function(bool) onSearchModeChanged;

  SongsSearchDelegate({
    this.searchInLyrics = false,
    required this.onSongSelected,
    required this.onSearchModeChanged,
  });

  @override
  String get searchFieldLabel => searchInLyrics 
      ? 'Rechercher dans les paroles...' 
      : 'Rechercher dans les titres...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: Theme.of(context).appBarTheme.copyWith(
        backgroundColor: Theme.of(context).colorScheme.primary, // #860505
        foregroundColor: Theme.of(context).colorScheme.onPrimary, // Blanc
        elevation: 0,
        systemOverlayStyle: Theme.of(context).appBarTheme.systemOverlayStyle,
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: GoogleFonts.inter(
          color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
      textTheme: Theme.of(context).textTheme.copyWith(
        titleLarge: GoogleFonts.inter(
          color: Theme.of(context).colorScheme.onPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: Icon(
            Icons.clear,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
          tooltip: 'Effacer',
        ),
      IconButton(
        icon: Icon(
          searchInLyrics ? Icons.lyrics : Icons.title,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
        onPressed: () {
          searchInLyrics = !searchInLyrics;
          onSearchModeChanged(searchInLyrics);
          // Rafraîchir les résultats
          if (query.isNotEmpty) {
            showResults(context);
          } else {
            showSuggestions(context);
          }
        },
        tooltip: searchInLyrics ? 'Recherche dans les paroles (actuel)' : 'Recherche dans les titres (actuel)',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.arrow_back,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
      onPressed: () => close(context, null),
      tooltip: 'Retour',
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search,
        title: 'Commencez à taper',
        subtitle: 'Tapez quelques lettres pour rechercher un cantique',
      );
    }

    return FutureBuilder<List<SongModel>>(
      future: SongsFirebaseService.getAllSongs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return _buildEmptyState(
            icon: Icons.error,
            title: 'Erreur',
            subtitle: 'Impossible de charger les cantiques',
          );
        }

        final songs = snapshot.data ?? [];
        final filteredSongs = _filterSongs(songs, query);

        if (filteredSongs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.music_off,
            title: 'Aucun résultat',
            subtitle: searchInLyrics 
                ? 'Aucun cantique ne contient "$query" dans ses paroles'
                : 'Aucun cantique ne contient "$query" dans son titre',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          itemCount: filteredSongs.length,
          itemBuilder: (context, index) {
            final song = filteredSongs[index];
            return SongCardPerfect13(
              song: song,
              songNumber: _getSongNumber(song, songs),
              onTap: () {
                onSongSelected(song);
                close(context, song);
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return _buildRecentSuggestions(context);
    }

    return FutureBuilder<List<SongModel>>(
      future: SongsFirebaseService.getAllSongs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final songs = snapshot.data ?? [];
        final suggestions = _getSuggestions(songs, query);

        if (suggestions.isEmpty) {
          return _buildEmptyState(
            icon: Icons.search_off,
            title: 'Aucune suggestion',
            subtitle: 'Essayez avec d\'autres mots-clés',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: suggestions.length > 8 ? 8 : suggestions.length, // Limiter à 8 suggestions
          itemBuilder: (context, index) {
            final song = suggestions[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  Icons.music_note,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 20,
                ),
              ),
              title: Text(
                song.title,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                song.authors,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Icon(
                Icons.north_west,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 16,
              ),
              onTap: () {
                query = song.title;
                showResults(context);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Builder(
      builder: (context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSuggestions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tips_and_updates,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Conseils de recherche',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSearchTip(
            context,
            'Par titre',
            'Rechercher "Amazing Grace", "Seigneur", etc.',
            Icons.title,
          ),
          const SizedBox(height: 8),
          _buildSearchTip(
            context,
            'Par auteur',
            'Rechercher "John Newton", "Chris Tomlin", etc.',
            Icons.person,
          ),
          const SizedBox(height: 8),
          _buildSearchTip(
            context,
            searchInLyrics ? 'Dans les paroles' : 'Changer le mode',
            searchInLyrics 
                ? 'Mode actuel : recherche dans les paroles'
                : 'Utilisez l\'icône pour rechercher dans les paroles',
            Icons.lyrics,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchTip(
    BuildContext context,
    String title,
    String description,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: 16,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<SongModel> _filterSongs(List<SongModel> songs, String query) {
    if (query.isEmpty) return songs;

    return songs.where((song) {
      final queryLower = query.toLowerCase();
      if (searchInLyrics) {
        return song.lyrics.toLowerCase().contains(queryLower);
      } else {
        return song.title.toLowerCase().contains(queryLower) ||
               song.authors.toLowerCase().contains(queryLower);
      }
    }).toList();
  }

  List<SongModel> _getSuggestions(List<SongModel> songs, String query) {
    if (query.isEmpty) return [];

    final suggestions = <SongModel>[];
    final queryLower = query.toLowerCase();

    // D'abord, chercher les titres qui commencent par la requête
    for (final song in songs) {
      if (song.title.toLowerCase().startsWith(queryLower)) {
        suggestions.add(song);
      }
    }

    // Ensuite, chercher les titres qui contiennent la requête
    for (final song in songs) {
      if (!suggestions.contains(song) && 
          song.title.toLowerCase().contains(queryLower)) {
        suggestions.add(song);
      }
    }

    // Enfin, chercher dans les auteurs
    if (!searchInLyrics) {
      for (final song in songs) {
        if (!suggestions.contains(song) && 
            song.authors.toLowerCase().contains(queryLower)) {
          suggestions.add(song);
        }
      }
    }

    return suggestions;
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
