import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/song_model.dart';
import '../services/songs_firebase_service.dart';
import '../../../widgets/song_card_perfect13.dart';
import '../../../theme.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    
    return Theme.of(context).copyWith(
      appBarTheme: Theme.of(context).appBarTheme.copyWith(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        surfaceTintColor: colorScheme.surfaceTint,
        shadowColor: colorScheme.shadow,
        systemOverlayStyle: Theme.of(context).appBarTheme.systemOverlayStyle,
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: GoogleFonts.inter(
          color: colorScheme.onSurfaceVariant,
          fontSize: 16,
          fontWeight: AppTheme.fontRegular,
          letterSpacing: 0.1,
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceMedium,
          vertical: AppTheme.spaceSmall,
        ),
      ),
      textTheme: Theme.of(context).textTheme.copyWith(
        titleLarge: GoogleFonts.inter(
          color: colorScheme.onSurface,
          fontSize: 18,
          fontWeight: AppTheme.fontMedium,
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return [
      // Bouton effacer avec Material Design 3
      if (query.isNotEmpty)
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            onTap: () {
              HapticFeedback.selectionClick();
              query = '';
              showSuggestions(context);
            },
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spaceSmall),
              child: Icon(
                Icons.clear,
                color: colorScheme.onSurfaceVariant,
                size: 24,
              ),
            ),
          ),
        ),
      
      // Bouton mode de recherche avec Material Design 3
      Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          onTap: () {
            HapticFeedback.selectionClick();
            searchInLyrics = !searchInLyrics;
            onSearchModeChanged(searchInLyrics);
            
            // Rafraîchir les résultats avec animation
            if (query.isNotEmpty) {
              showResults(context);
            } else {
              showSuggestions(context);
            }
          },
          child: Container(
            margin: const EdgeInsets.all(4),
            padding: const EdgeInsets.all(AppTheme.spaceSmall),
            decoration: BoxDecoration(
              color: searchInLyrics 
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            ),
            child: Icon(
              searchInLyrics ? Icons.lyrics : Icons.title,
              color: searchInLyrics 
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ),
        ),
      ),
      
      const SizedBox(width: AppTheme.spaceSmall),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        onTap: () {
          HapticFeedback.selectionClick();
          close(context, null);
        },
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceSmall),
          child: Icon(
            Icons.arrow_back,
            color: colorScheme.onSurface,
            size: 24,
          ),
        ),
      ),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) {
      return _buildEmptyState(
        context: context,
        icon: Icons.search,
        title: 'Commencez à taper',
        subtitle: 'Tapez quelques lettres pour rechercher un cantique',
      );
    }

    return FutureBuilder<List<SongModel>>(
      future: SongsFirebaseService.getAllSongs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState(context);
        }

        if (snapshot.hasError) {
          return _buildEmptyState(
            context: context,
            icon: Icons.error,
            title: 'Erreur',
            subtitle: 'Impossible de charger les cantiques',
          );
        }

        final songs = snapshot.data ?? [];
        final filteredSongs = _filterSongs(songs, query);

        if (filteredSongs.isEmpty) {
          return _buildEmptyState(
            context: context,
            icon: Icons.music_off,
            title: 'Aucun résultat',
            subtitle: searchInLyrics 
                ? 'Aucun cantique ne contient "$query" dans ses paroles'
                : 'Aucun cantique ne contient "$query" dans son titre',
          );
        }

        return _buildResultsList(context, filteredSongs, songs);
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
          return _buildLoadingState(context);
        }

        final songs = snapshot.data ?? [];
        final suggestions = _getSuggestions(songs, query);

        if (suggestions.isEmpty) {
          return _buildEmptyState(
            context: context,
            icon: Icons.search_off,
            title: 'Aucune suggestion',
            subtitle: 'Essayez avec d\'autres mots-clés',
          );
        }

        return _buildSuggestionsList(context, suggestions);
      },
    );
  }

  Widget _buildLoadingState(BuildContext context) {
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
            'Recherche en cours...',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: AppTheme.fontMedium,
              color: colorScheme.onSurfaceVariant,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(BuildContext context, List<SongModel> filteredSongs, List<SongModel> allSongs) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMedium,
        AppTheme.spaceSmall,
        AppTheme.spaceMedium,
        AppTheme.spaceMedium,
      ),
      itemCount: filteredSongs.length,
      itemBuilder: (context, index) {
        final song = filteredSongs[index];
        return AnimatedContainer(
          duration: Duration(milliseconds: 100 + (index * 50)),
          curve: Curves.easeOutCubic,
          child: SongCardPerfect13(
            song: song,
            songNumber: index + 1, // Numéroter séquentiellement à partir de 1 pour les résultats de recherche
            onTap: () {
              HapticFeedback.selectionClick();
              onSongSelected(song);
              close(context, song);
            },
          ),
        );
      },
    );
  }

  Widget _buildSuggestionsList(BuildContext context, List<SongModel> suggestions) {
    final colorScheme = Theme.of(context).colorScheme;
    final maxSuggestions = suggestions.length > 8 ? 8 : suggestions.length;
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceSmall),
      itemCount: maxSuggestions,
      itemBuilder: (context, index) {
        final song = suggestions[index];
        
        return AnimatedContainer(
          duration: Duration(milliseconds: 100 + (index * 30)),
          curve: Curves.easeOutCubic,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                query = song.title;
                showResults(context);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceMedium,
                  vertical: AppTheme.spaceSmall,
                ),
                child: Row(
                  children: [
                    // Icône moderne
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                      ),
                      child: Icon(
                        Icons.music_note,
                        color: colorScheme.onPrimaryContainer,
                        size: 20,
                      ),
                    ),
                    
                    const SizedBox(width: AppTheme.spaceMedium),
                    
                    // Contenu de la suggestion
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            style: GoogleFonts.inter(
                              fontWeight: AppTheme.fontMedium,
                              fontSize: 16,
                              color: colorScheme.onSurface,
                              letterSpacing: -0.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (song.authors.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              song.authors,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: colorScheme.onSurfaceVariant,
                                letterSpacing: 0.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // Flèche de suggestion
                    Icon(
                      Icons.north_west,
                      color: colorScheme.onSurfaceVariant,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
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
              color: colorScheme.outline,
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: AppTheme.fontSemiBold,
                color: colorScheme.onSurfaceVariant,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: AppTheme.spaceSmall),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
                letterSpacing: 0.1,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSuggestions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête des conseils
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Icon(
                    Icons.tips_and_updates,
                    color: colorScheme.onPrimaryContainer,
                    size: 16,
                  ),
                ),
                const SizedBox(width: AppTheme.spaceSmall),
                Text(
                  'Conseils de recherche',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: AppTheme.fontSemiBold,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppTheme.spaceMedium),
          
          // Liste des conseils avec Material Design 3
          _buildSearchTip(
            context,
            'Par titre',
            'Rechercher "Amazing Grace", "Seigneur", etc.',
            Icons.title,
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          _buildSearchTip(
            context,
            'Par auteur',
            'Rechercher "John Newton", "Chris Tomlin", etc.',
            Icons.person,
          ),
          const SizedBox(height: AppTheme.spaceSmall),
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
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceSmall),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(
          color: colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: colorScheme.primary,
            size: 16,
          ),
          const SizedBox(width: AppTheme.spaceSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: AppTheme.fontMedium,
                    color: colorScheme.onSurface,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                    letterSpacing: 0.1,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
}