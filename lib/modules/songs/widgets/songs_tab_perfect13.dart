import 'package:flutter/material.dart';
import '../models/song_model.dart';
import '../services/songs_firebase_service.dart';
import '../../../widgets/song_lyrics_viewer.dart';
import '../../../pages/song_projection_page.dart';

/// Onglet Chants - Reproduction exacte de Perfect 13
class SongsTabPerfect13 extends StatefulWidget {
  const SongsTabPerfect13({super.key});

  @override
  State<SongsTabPerfect13> createState() => _SongsTabPerfect13State();
}

class _SongsTabPerfect13State extends State<SongsTabPerfect13> {
  List<SongModel> allSongs = [];
  List<SongModel> filteredSongs = [];
  bool isLoading = true;
  String searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  void _loadSongs() async {
    try {
      setState(() => isLoading = true);
      
      // Charger tous les chants
      final songs = await SongsFirebaseService.getAllSongs();
      if (mounted) {
        setState(() {
          allSongs = songs;
          _updateSongNumbers();
          _filterSongs();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _updateSongNumbers() {
    // Trier par titre pour la numérotation alphabétique
    allSongs.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    
    // Note: Le modèle SongModel n'a pas de propriété number modifiable
    // La numérotation sera calculée dynamiquement avec _getSongNumber
  }

  void _filterSongs() {
    if (searchQuery.isEmpty) {
      filteredSongs = List.from(allSongs);
    } else {
      filteredSongs = allSongs.where((song) {
        return song.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
               song.authors.toLowerCase().contains(searchQuery.toLowerCase()) ||
               song.lyrics.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    }
  }

  int _getSongNumber(SongModel song) {
    // Trouver la position du chant dans la liste triée alphabétiquement
    final sortedSongs = List<SongModel>.from(allSongs);
    sortedSongs.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    
    for (int i = 0; i < sortedSongs.length; i++) {
      if (sortedSongs[i].id == song.id) {
        return i + 1;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (filteredSongs.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Liste des chants
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredSongs.length,
            itemBuilder: (context, index) {
              final song = filteredSongs[index];
              return _buildEnhancedSongCard(song, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedSongCard(SongModel song, int index) {
    final songNumber = _getSongNumber(song);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showSongDetails(song),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Numéro du chant dans un cercle
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withOpacity(0.8),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      songNumber.toString(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Informations du chant
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (song.authors.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          song.authors,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Note: isFavorite n'existe pas dans SongModel
                    // On pourrait ajouter cette fonctionnalité plus tard
                    Icon(
                      Icons.chevron_right,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_music_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            searchQuery.isEmpty 
                ? 'Aucun chant disponible'
                : 'Aucun chant trouvé',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          if (searchQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Essayez avec d\'autres mots-clés',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showSongDetails(SongModel song) {
    // Incrémenter le compteur d'utilisation
    // SongsFirebaseService.incrementSongUsage(song.id);

    // Variable pour contrôler l'affichage du lecteur audio
    bool showAudioPlayer = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => StatefulBuilder(
        builder: (context, setStateBottomSheet) => DraggableScrollableSheet(
        initialChildSize: 1.0, // Prend tout l'écran
        minChildSize: 1.0,      // Taille minimale plein écran
        maxChildSize: 1.0,     // Taille maximale plein écran
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, -5)),
            ]),
          child: Column(
            children: [
              // Handle de la bottomsheet
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2))),
              
              // En-tête moderne avec design bottomsheet
              Container(
                padding: const EdgeInsets.fromLTRB(24, 8, 20, 20),
                child: Row(
                  children: [
                    // Icône moderne du chant
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.primaryContainer,
                          ]),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2)),
                        ]),
                      child: Icon(
                        Icons.music_note_rounded,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 20)),
                    
                    const SizedBox(width: 12),
                    
                    // Informations du chant
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                              letterSpacing: 0.5),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                          if (song.authors.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Par: ${song.authors}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          ],
                          const SizedBox(height: 6),
                          // Badges d'information
                          Wrap(
                            spacing: 4,
                            runSpacing: 3,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(8)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.music_off_rounded,
                                      size: 12,
                                      color: Theme.of(context).colorScheme.onSecondaryContainer),
                                    const SizedBox(width: 3),
                                    Text(
                                      song.originalKey,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.onSecondaryContainer)),
                                  ])),
                              // Tags masqués pour le module Cantiques
                              // if (song.tags.isNotEmpty)
                              //   Container(
                              //     padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              //     decoration: BoxDecoration(
                              //       color: Theme.of(context).colorScheme.tertiaryContainer,
                              //       borderRadius: BorderRadius.circular(8),
                              //     ),
                              //     child: Text(
                              //       song.tags.first,
                              //       style: TextStyle(
                              //         fontSize: 10,
                              //         fontWeight: FontWeight.w600,
                              //         color: Theme.of(context).colorScheme.onTertiaryContainer,
                              //       ),
                              //     ),
                              //   ),
                            ]),
                        ])),
                    
                    // Actions modernisées pour bottomsheet
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Bouton play audio (si audio disponible)
                        if (song.audioUrl != null && song.audioUrl!.isNotEmpty) ...[
                          Container(
                            decoration: BoxDecoration(
                              color: showAudioPlayer 
                                ? Theme.of(context).colorScheme.secondary
                                : Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: showAudioPlayer ? [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2)),
                              ] : null),
                            child: IconButton(
                              icon: Icon(
                                showAudioPlayer ? Icons.music_off_rounded : Icons.play_arrow_rounded,
                                color: showAudioPlayer 
                                  ? Theme.of(context).colorScheme.onSecondary
                                  : Theme.of(context).colorScheme.onSurfaceVariant),
                              onPressed: () {
                                setStateBottomSheet(() {
                                  showAudioPlayer = !showAudioPlayer;
                                });
                              },
                              tooltip: showAudioPlayer ? 'Masquer lecteur audio' : 'Afficher lecteur audio')),
                          const SizedBox(width: 12),
                        ],
                        // Bouton projection
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2)),
                            ]),
                          child: IconButton(
                            icon: Icon(
                              Icons.present_to_all_rounded,
                              color: Theme.of(context).colorScheme.onPrimary),
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SongProjectionPage(song: song)));
                            },
                            tooltip: 'Mode projection')),
                        const SizedBox(width: 12),
                        // Bouton fermer
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16)),
                          child: IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              color: Theme.of(context).colorScheme.onSurfaceVariant),
                            onPressed: () => Navigator.pop(context),
                            tooltip: 'Fermer')),
                      ]),
                  ])),
              
              // Lecteur audio si disponible et activé
              if (showAudioPlayer && song.audioUrl != null && song.audioUrl!.isNotEmpty)
                _buildAudioPlayerWidget(song),
              
              // Contenu des paroles avec design bottomsheet
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16)),
                      child: song.lyrics.isNotEmpty
                          ? SongLyricsViewer(
                              song: song,
                              showChords: true,
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.music_note_outlined,
                                    size: 48,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Paroles non disponibles',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    )))),
            ])))));
  }

  Widget _buildAudioPlayerWidget(SongModel song) {
    // Widget simple pour le lecteur audio - peut être étendu plus tard
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.audiotrack_rounded,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Lecteur audio - ${song.title}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.play_arrow_rounded,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
            onPressed: () {
              // Implémentation du lecteur audio
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Lecteur audio bientôt disponible'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
