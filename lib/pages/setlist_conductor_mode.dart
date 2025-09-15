import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../modules/songs/models/song_model.dart';
import '../modules/songs/models/song.dart';
import '../modules/songs/services/songs_service.dart';
import 'song_projection_page.dart';

class SetlistConductorMode extends StatefulWidget {
  final SetlistModel setlist;

  const SetlistConductorMode({
    Key? key,
    required this.setlist,
  }) : super(key: key);

  @override
  _SetlistConductorModeState createState() => _SetlistConductorModeState();
}

class _SetlistConductorModeState extends State<SetlistConductorMode>
    with TickerProviderStateMixin {
  final SongsService _songsService = SongsService();
  List<Song> _songs = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _showLyrics = true; // Démarrer avec les paroles affichées
  bool _isProjecting = false;

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadSongs();
  }

  void _initAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadSongs() async {
    try {
      setState(() {
        _isLoading = true;
      });

      List<Song> songs = [];
      for (String songId in widget.setlist.songIds) {
        final song = await _songsService.getById(songId);
        if (song != null) {
          songs.add(song);
        }
      }

      if (mounted) {
        setState(() {
          _songs = songs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Theme.of(context).colorScheme.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.surface))
          : _songs.isEmpty
              ? _buildEmptyState()
              : _buildConductorInterface());
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_off_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.surface.withOpacity(0.7)),
          const SizedBox(height: 20),
          Text(
            'Aucun chant dans cette setlist',
            style: TextStyle(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
              fontSize: 20,
              fontWeight: FontWeight.w500)),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Retour'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.surface)),
        ]));
  }

  Widget _buildConductorInterface() {
    final currentSong = _songs[_currentIndex];
    
    return Stack(
      children: [
        // Arrière-plan simplifié pour maximiser la lisibilité
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.grey.shade900,
                Colors.black,
              ]))),
        
        // Interface principale optimisée pour les paroles
        SafeArea(
          child: Column(
            children: [
              _buildCompactHeader(currentSong),
              Expanded(
                child: _showLyrics
                    ? _buildMaximizedLyricsView(currentSong)
                    : _buildCompactSongInfo(currentSong)),
              _buildMinimalNavigationControls(),
            ])),
        
        // Indicateur de projection compact
        if (_isProjecting)
          Positioned(
            top: 50,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                    blurRadius: 4,
                    spreadRadius: 1),
                ]),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.live_tv,
                    color: Theme.of(context).colorScheme.surface,
                    size: 12),
                  const SizedBox(width: 4),
                  Text(
                    'LIVE',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.surface,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
                ]))),
      ]);
  }

  // Header compact pour maximiser l'espace des paroles
  Widget _buildCompactHeader(Song song) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.6),
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
          ]),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16)),
      ),
      child: Row(
        children: [
          // Bouton retour compact
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8)),
            child: IconButton(
              icon: Icon(Icons.close, 
                color: Theme.of(context).colorScheme.surface, size: 20),
              onPressed: () => Navigator.pop(context),
              padding: const EdgeInsets.all(8))),
          
          const SizedBox(width: 12),
          
          // Info setlist compacte
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  song.title,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.surface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
                Text(
                  '${_currentIndex + 1}/${_songs.length} • ${widget.setlist.name}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                    fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              ])),
          
          // Contrôles d'affichage compacts
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(_showLyrics ? 0.3 : 0.1),
                  borderRadius: BorderRadius.circular(6)),
                child: IconButton(
                  icon: Icon(
                    _showLyrics ? Icons.lyrics : Icons.info_outline,
                    color: Theme.of(context).colorScheme.surface,
                    size: 18),
                  onPressed: () {
                    setState(() {
                      _showLyrics = !_showLyrics;
                    });
                  },
                  padding: const EdgeInsets.all(6))),
              const SizedBox(width: 6),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(_isProjecting ? 0.3 : 0.1),
                  borderRadius: BorderRadius.circular(6)),
                child: IconButton(
                  icon: Icon(
                    _isProjecting ? Icons.stop_screen_share : Icons.screen_share,
                    color: Theme.of(context).colorScheme.surface,
                    size: 18),
                  onPressed: _toggleProjection,
                  padding: const EdgeInsets.all(6))),
            ]),
        ]));
  }

  // Vue des paroles maximisée pour la meilleure lisibilité
  Widget _buildMaximizedLyricsView(Song song) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.98),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2)),
        ]),
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Text(
            song.lyrics.isEmpty ? 'Aucune parole disponible' : song.lyrics,
            style: TextStyle(
              fontSize: 20, // Taille de police augmentée pour les conducteurs
              height: 1.8, // Espacement de ligne augmenté pour la lisibilité
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.3),
            textAlign: TextAlign.left))));
  }

  // Informations du chant en version compacte
  Widget _buildCompactSongInfo(Song song) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.98),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2)),
        ]),
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informations essentielles seulement
              if (song.tonality != null && song.tonality!.isNotEmpty) ...[
                _buildCompactInfoRow('Tonalité', song.tonality!),
                const SizedBox(height: 8),
              ],
              
              if (song.author != null && song.author!.isNotEmpty) ...[
                _buildCompactInfoRow('Auteur', song.author!),
                const SizedBox(height: 8),
              ],
              
              if (song.tempo != null) ...[
                _buildCompactInfoRow('Tempo', '${song.tempo} BPM'),
                const SizedBox(height: 8),
              ],
              
              // Aperçu des paroles optimisé
              if (song.lyrics.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Aperçu des paroles:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    song.lyrics.length > 300 
                        ? '${song.lyrics.substring(0, 300)}...'
                        : song.lyrics,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: Theme.of(context).colorScheme.onSurface))),
              ],
            ]))));
  }

  Widget _buildCompactInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)))),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface))),
      ]);
  }

  // Contrôles de navigation minimalistes pour économiser l'espace
  Widget _buildMinimalNavigationControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.6),
          ])),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicateur de progression compact
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: List.generate(_songs.length, (index) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 0.5),
                    height: 3,
                    decoration: BoxDecoration(
                      color: index <= _currentIndex
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surface.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(1.5))));
              }))),
          
          // Contrôles principaux en ligne
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Précédent
              _buildMinimalControlButton(
                icon: Icons.skip_previous_rounded,
                onPressed: _currentIndex > 0 ? _goToPrevious : null,
                size: 48),
              
              // Options
              _buildMinimalControlButton(
                icon: Icons.more_vert,
                onPressed: _showOptions,
                size: 40),
              
              // Projection
              _buildMinimalControlButton(
                icon: Icons.fullscreen,
                onPressed: _openProjection,
                size: 44,
                isPrimary: true),
              
              // Liste
              _buildMinimalControlButton(
                icon: Icons.list_rounded,
                onPressed: _showSongList,
                size: 40),
              
              // Suivant
              _buildMinimalControlButton(
                icon: Icons.skip_next_rounded,
                onPressed: _currentIndex < _songs.length - 1 ? _goToNext : null,
                size: 48),
            ]),
        ]));
  }

  Widget _buildMinimalControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required double size,
    bool isPrimary = false,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: isPrimary
            ? LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primaryContainer,
                ])
            : null,
        color: isPrimary 
            ? null 
            : (onPressed != null 
                ? Theme.of(context).colorScheme.surface.withOpacity(0.15)
                : Theme.of(context).colorScheme.surface.withOpacity(0.05)),
        shape: BoxShape.circle,
        boxShadow: isPrimary ? [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2)),
        ] : null),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: onPressed != null
              ? Theme.of(context).colorScheme.surface
              : Theme.of(context).colorScheme.surface.withOpacity(0.4),
          size: size * 0.35),
        splashRadius: size / 2));
  }

  void _goToPrevious() {
    if (_currentIndex > 0) {
      HapticFeedback.lightImpact();
      _slideController.reset();
      setState(() {
        _currentIndex--;
      });
      _slideController.forward();
    }
  }

  void _goToNext() {
    if (_currentIndex < _songs.length - 1) {
      HapticFeedback.lightImpact();
      _slideController.reset();
      setState(() {
        _currentIndex++;
      });
      _slideController.forward();
    }
  }

  void _toggleProjection() {
    setState(() {
      _isProjecting = !_isProjecting;
    });
    
    if (_isProjecting) {
      _openProjection();
    }
  }

  void _openProjection() {
    if (_songs.isNotEmpty) {
      final currentSong = _songs[_currentIndex];
      // Convertir Song en SongModel pour la projection
      final songModel = SongModel(
        id: currentSong.id ?? '',
        title: currentSong.title,
        authors: currentSong.author ?? '',
        lyrics: currentSong.lyrics,
        originalKey: currentSong.tonality ?? '',
        currentKey: currentSong.tonality,
        style: '',
        tags: currentSong.tags,
        bibleReferences: [],
        tempo: currentSong.tempo,
        audioUrl: currentSong.audioUrl,
        attachmentUrls: [],
        status: 'active',
        visibility: currentSong.isPublic ? 'public' : 'private',
        privateNotes: null,
        usageCount: currentSong.views,
        lastUsedAt: null,
        createdAt: currentSong.createdAt,
        updatedAt: currentSong.updatedAt,
        createdBy: currentSong.createdBy,
        modifiedBy: null,
        metadata: currentSong.metadata,
      );
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SongProjectionPage(song: songModel)));
    }
  }

  void _showSongList() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2))),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Liste des chants',
                style: Theme.of(context).textTheme.titleLarge)),
            
            Expanded(
              child: ListView.builder(
                itemCount: _songs.length,
                itemBuilder: (context, index) {
                  final song = _songs[index];
                  final isCurrentSong = index == _currentIndex;
                  
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isCurrentSong 
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: isCurrentSong 
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold))),
                    title: Text(
                      song.title,
                      style: TextStyle(
                        fontWeight: isCurrentSong ? FontWeight.bold : FontWeight.normal)),
                    subtitle: Text(song.author ?? 'Auteur inconnu'),
                    trailing: isCurrentSong 
                        ? Icon(Icons.play_arrow, 
                            color: Theme.of(context).colorScheme.primary)
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      _goToSong(index);
                    });
                })),
          ])));
  }

  void _goToSong(int index) {
    if (index != _currentIndex && index >= 0 && index < _songs.length) {
      HapticFeedback.selectionClick();
      _slideController.reset();
      setState(() {
        _currentIndex = index;
      });
      _slideController.forward();
    }
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2))),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Options du conducteur',
                style: Theme.of(context).textTheme.titleLarge)),
            
            ListTile(
              leading: Icon(Icons.lyrics),
              title: Text('Afficher les paroles'),
              trailing: Switch(
                value: _showLyrics,
                onChanged: (value) {
                  setState(() {
                    _showLyrics = value;
                  });
                  Navigator.pop(context);
                })),
            
            ListTile(
              leading: Icon(Icons.screen_share),
              title: Text('Mode projection'),
              trailing: Switch(
                value: _isProjecting,
                onChanged: (value) {
                  _toggleProjection();
                  Navigator.pop(context);
                })),
            
            const SizedBox(height: 20),
          ])));
  }
}
