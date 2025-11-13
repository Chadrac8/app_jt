import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../modules/songs/models/song_model.dart';
import '../modules/songs/services/songs_firebase_service.dart';
import '../pages/song_projection_page.dart';
import '../../theme.dart';

/// Mode musicien optimisé pour jouer une setlist de chants
/// Interface spécialisée avec transposition et contrôles musicaux - Version professionnelle
class SetlistMusicianMode extends StatefulWidget {
  final SetlistModel setlist;

  const SetlistMusicianMode({
    super.key,
    required this.setlist,
  });

  @override
  State<SetlistMusicianMode> createState() => _SetlistMusicianModeState();
}

class _SetlistMusicianModeState extends State<SetlistMusicianMode>
    with TickerProviderStateMixin {
  List<SongModel> _songs = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  
  // Animation controllers
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  
  // Musician specific features
  String _viewMode = 'full'; // 'full', 'chords_only', 'structure_only'
  int _bpm = 120;
  
  // Transpose
  int _transposeSteps = 0;
  final List<String> _notes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadSongs();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
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

  Future<void> _loadSongs() async {
    try {
      setState(() {
        _isLoading = true;
      });

      List<SongModel> songs = [];
      for (String songId in widget.setlist.songIds) {
        final song = await SongsFirebaseService.getSong(songId);
        if (song != null) {
          songs.add(song);
        }
      }

      if (mounted) {
        setState(() {
          _songs = songs;
          _isLoading = false;
          _updateBpmFromSong();
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

  void _nextSong() {
    if (_currentIndex < _songs.length - 1) {
      HapticFeedback.lightImpact();
      _slideController.reset();
      setState(() {
        _currentIndex++;
        _updateBpmFromSong();
      });
      _slideController.forward();
    }
  }

  void _previousSong() {
    if (_currentIndex > 0) {
      HapticFeedback.lightImpact();
      _slideController.reset();
      setState(() {
        _currentIndex--;
        _updateBpmFromSong();
      });
      _slideController.forward();
    }
  }

  void _goToSong(int index) {
    if (index != _currentIndex && index >= 0 && index < _songs.length) {
      HapticFeedback.selectionClick();
      _slideController.reset();
      setState(() {
        _currentIndex = index;
        _updateBpmFromSong();
      });
      _slideController.forward();
    }
  }

  void _updateBpmFromSong() {
    if (_songs.isNotEmpty && _currentIndex < _songs.length) {
      final currentSong = _songs[_currentIndex];
      if (currentSong.tempo != null) {
        setState(() {
          _bpm = currentSong.tempo!;
        });
      }
    }
  }

  String _transposeChord(String chord) {
    if (_transposeSteps == 0) return chord;
    
    for (int i = 0; i < _notes.length; i++) {
      if (chord.startsWith(_notes[i])) {
        int newIndex = (i + _transposeSteps) % _notes.length;
        if (newIndex < 0) newIndex += _notes.length;
        return chord.replaceFirst(_notes[i], _notes[newIndex]);
      }
    }
    return chord;
  }

  String _getTransposedKey(String? originalKey) {
    if (originalKey == null || originalKey.isEmpty) return '';
    return _transposeChord(originalKey);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.black100,
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.surface)));
    }

    if (_songs.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.black100,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.music_off_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.surface.withOpacity(0.7)),
              const SizedBox(height: AppTheme.spaceMedium),
              Text('Aucun chant dans cette setlist',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.surface,
                  fontSize: AppTheme.fontSize16)),
              const SizedBox(height: AppTheme.spaceLarge),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Retour')),
            ])));
    }

    return Scaffold(
      backgroundColor: AppTheme.black100,
      body: Stack(
        children: [
          // Arrière-plan simplifié pour maximiser la lisibilité
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.grey500,
                  AppTheme.black100,
                ]))),
          
          // Interface principale optimisée pour les musiciens
          SafeArea(
            child: Column(
              children: [
                _buildCompactMusicianHeader(_songs[_currentIndex]),
                Expanded(child: _buildMaximizedSongContent()),
                _buildMinimalMusicianControls(),
              ])),
        ]));
  }

  // Header compact spécialement conçu pour les musiciens
  Widget _buildCompactMusicianHeader(SongModel song) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.warningColor.withOpacity(0.6), // Couleur musicale
            AppTheme.orangeStandard.withOpacity(0.4),
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
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
            child: IconButton(
              icon: Icon(Icons.close, 
                color: Theme.of(context).colorScheme.surface, size: 20),
              onPressed: () => Navigator.pop(context),
              padding: const EdgeInsets.all(AppTheme.spaceSmall))),
          
          const SizedBox(width: AppTheme.space12),
          
          // Info compacte avec indication musicien
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        song.title,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.surface,
                          fontSize: AppTheme.fontSize16,
                          fontWeight: AppTheme.fontSemiBold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)),
                    Text(
                      '🎸',
                      style: TextStyle(fontSize: AppTheme.fontSize16)),
                  ]),
                Text(
                  '${_currentIndex + 1}/${_songs.length} • ${widget.setlist.name}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                    fontSize: AppTheme.fontSize11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              ])),
          
          // Contrôles essentiels compacts
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tonalité actuelle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6)),
                child: Text(
                  _transposeSteps == 0 
                      ? (song.originalKey.isNotEmpty ? song.originalKey : 'C')
                      : _getTransposedKey(song.originalKey.isNotEmpty ? song.originalKey : 'C'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.surface,
                    fontSize: AppTheme.fontSize12,
                    fontWeight: AppTheme.fontBold))),
              const SizedBox(width: AppTheme.space6),
              // Projection
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6)),
                child: IconButton(
                  icon: Icon(
                    Icons.screen_share,
                    color: Theme.of(context).colorScheme.surface,
                    size: 18),
                  onPressed: _openProjection,
                  padding: const EdgeInsets.all(AppTheme.space6))),
            ]),
        ]));
  }

  // Contenu maximisé pour les paroles et accords
  Widget _buildMaximizedSongContent() {
    if (_songs.isEmpty) return const SizedBox();
    
    final currentSong = _songs[_currentIndex];
    
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.98),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black100.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2)),
        ]),
      child: SlideTransition(
        position: _slideAnimation,
        child: _buildContentForViewMode(currentSong)));
  }

  Widget _buildContentForViewMode(SongModel song) {
    switch (_viewMode) {
      case 'chords_only':
        return _buildChordsOnlyView(song);
      case 'structure_only':
        return _buildStructureOnlyView(song);
      default:
        return _buildFullLyricsView(song);
    }
  }

  Widget _buildFullLyricsView(SongModel song) {
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Text(
        song.lyrics.isEmpty ? 'Aucune parole disponible' : song.lyrics,
        style: TextStyle(
          fontSize: AppTheme.fontSize18, // Taille optimisée pour les musiciens
          height: 1.7, // Espacement pour faciliter la lecture
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: AppTheme.fontRegular,
          letterSpacing: 0.2)));
  }

  Widget _buildChordsOnlyView(SongModel song) {
    final chords = <String>[];
    final lines = song.lyrics.split('\n');
    
    for (final line in lines) {
      final matches = RegExp(r'\[([^\]]+)\]').allMatches(line);
      for (final match in matches) {
        final chord = match.group(1);
        if (chord != null && !chords.contains(chord)) {
          chords.add(chord);
        }
      }
    }
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Accords utilisés:',
            style: TextStyle(
              fontSize: AppTheme.fontSize18,
              fontWeight: AppTheme.fontBold,
              color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: AppTheme.spaceMedium),
          
          if (chords.isEmpty)
            Text(
              'Aucun accord détecté dans ce chant',
              style: TextStyle(
                fontSize: AppTheme.fontSize14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)))
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: chords.map((chord) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.2),
                  border: Border.all(color: AppTheme.warningColor, width: 2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
                child: Text(
                  _transposeChord(chord),
                  style: TextStyle(
                    fontSize: AppTheme.fontSize18,
                    fontWeight: AppTheme.fontBold,
                    color: Theme.of(context).colorScheme.onSurface)))).toList()),
          
          const SizedBox(height: AppTheme.spaceLarge),
          
          Text(
            'Paroles avec accords:',
            style: TextStyle(
              fontSize: AppTheme.fontSize18,
              fontWeight: AppTheme.fontBold,
              color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: AppTheme.spaceMedium),
          
          Text(
            song.lyrics.isEmpty ? 'Aucune parole disponible' : song.lyrics,
            style: TextStyle(
              fontSize: AppTheme.fontSize16,
              height: 1.6,
              color: Theme.of(context).colorScheme.onSurface)),
        ]));
  }

  Widget _buildStructureOnlyView(SongModel song) {
    final structure = <String>[];
    final lines = song.lyrics.split('\n');
    
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.endsWith(':') && trimmed.length < 30) {
        structure.add(trimmed);
      }
    }
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Structure du chant:',
            style: TextStyle(
              fontSize: AppTheme.fontSize18,
              fontWeight: AppTheme.fontBold,
              color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: AppTheme.spaceMedium),
          
          if (structure.isEmpty)
            Text(
              'Structure non détectée',
              style: TextStyle(
                fontSize: AppTheme.fontSize14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)))
          else
            ...structure.map((section) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(AppTheme.space12),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
              child: Text(
                section,
                style: TextStyle(
                  fontSize: AppTheme.fontSize16,
                  fontWeight: AppTheme.fontSemiBold,
                  color: Theme.of(context).colorScheme.onSurface)))),
          
          const SizedBox(height: AppTheme.spaceLarge),
          
          Text(
            'Paroles complètes:',
            style: TextStyle(
              fontSize: AppTheme.fontSize18,
              fontWeight: AppTheme.fontBold,
              color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: AppTheme.spaceMedium),
          
          Text(
            song.lyrics.isEmpty ? 'Aucune parole disponible' : song.lyrics,
            style: TextStyle(
              fontSize: AppTheme.fontSize16,
              height: 1.6,
              color: Theme.of(context).colorScheme.onSurface)),
        ]));
  }

  // Contrôles musicaux compacts et professionnels
  Widget _buildMinimalMusicianControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            AppTheme.black100.withOpacity(0.7),
          ])),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mode d'affichage compact
          Row(
            children: [
              Expanded(
                child: _buildCompactToggleButton(
                  'Complet',
                  _viewMode == 'full',
                  () => setState(() => _viewMode = 'full'))),
              const SizedBox(width: AppTheme.space6),
              Expanded(
                child: _buildCompactToggleButton(
                  'Accords',
                  _viewMode == 'chords_only',
                  () => setState(() => _viewMode = 'chords_only'))),
              const SizedBox(width: AppTheme.space6),
              Expanded(
                child: _buildCompactToggleButton(
                  'Structure',
                  _viewMode == 'structure_only',
                  () => setState(() => _viewMode = 'structure_only'))),
            ]),
          
          const SizedBox(height: AppTheme.spaceSmall),
          
          // Contrôles musicaux en ligne
          Row(
            children: [
              // Navigation
              _buildMinimalNavButton(
                icon: Icons.skip_previous_rounded,
                onPressed: _currentIndex > 0 ? _previousSong : null),
              
              const SizedBox(width: AppTheme.spaceSmall),
              
              // Transposition
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _transposeSteps--),
                        child: Icon(Icons.remove, 
                          color: Theme.of(context).colorScheme.surface, size: 16)),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Transpose',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.surface, 
                              fontSize: 9)),
                          Text(
                            _transposeSteps == 0 ? 'Original' : '${_transposeSteps > 0 ? '+' : ''}$_transposeSteps',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.surface, 
                              fontWeight: AppTheme.fontBold,
                              fontSize: AppTheme.fontSize11)),
                        ]),
                      GestureDetector(
                        onTap: () => setState(() => _transposeSteps++),
                        child: Icon(Icons.add, 
                          color: Theme.of(context).colorScheme.surface, size: 16)),
                    ]))),
              
              const SizedBox(width: AppTheme.spaceSmall),
              
              // BPM
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _bpm = (_bpm - 5).clamp(60, 200)),
                        child: Icon(Icons.remove, 
                          color: Theme.of(context).colorScheme.surface, size: 16)),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'BPM',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.surface, 
                              fontSize: 9)),
                          Text(
                            '$_bpm',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.surface, 
                              fontWeight: AppTheme.fontBold,
                              fontSize: AppTheme.fontSize11)),
                        ]),
                      GestureDetector(
                        onTap: () => setState(() => _bpm = (_bpm + 5).clamp(60, 200)),
                        child: Icon(Icons.add, 
                          color: Theme.of(context).colorScheme.surface, size: 16)),
                    ]))),
              
              const SizedBox(width: AppTheme.spaceSmall),
              
              // Liste
              _buildMinimalNavButton(
                icon: Icons.list_rounded,
                onPressed: _showSongList),
              
              const SizedBox(width: AppTheme.spaceSmall),
              
              // Navigation suivante
              _buildMinimalNavButton(
                icon: Icons.skip_next_rounded,
                onPressed: _currentIndex < _songs.length - 1 ? _nextSong : null),
            ]),
        ]));
  }

  Widget _buildCompactToggleButton(String label, bool isActive, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive 
              ? AppTheme.warningColor.withOpacity(0.3)
              : Theme.of(context).colorScheme.surface.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6)),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isActive 
                ? AppTheme.warningColor
                : Theme.of(context).colorScheme.surface,
            fontWeight: isActive ? AppTheme.fontBold : AppTheme.fontMedium,
            fontSize: AppTheme.fontSize11))));
  }

  Widget _buildMinimalNavButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: onPressed != null 
            ? AppTheme.warningColor.withOpacity(0.2)
            : Theme.of(context).colorScheme.surface.withOpacity(0.05),
        shape: BoxShape.circle),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: onPressed != null 
              ? AppTheme.warningColor
              : Theme.of(context).colorScheme.surface.withOpacity(0.4),
          size: 20),
        padding: EdgeInsets.zero));
  }

  void _openProjection() {
    if (_songs.isNotEmpty) {
      final currentSong = _songs[_currentIndex];
      // Utiliser directement SongModel - pas de conversion nécessaire
      final songModel = SongModel(
        id: currentSong.id,
        title: currentSong.title,
        authors: currentSong.authors,
        lyrics: currentSong.lyrics,
        originalKey: currentSong.originalKey,
        currentKey: _transposeSteps == 0 ? currentSong.originalKey : _getTransposedKey(currentSong.originalKey),
        style: currentSong.style,
        tags: currentSong.tags,
        bibleReferences: currentSong.bibleReferences,
        tempo: _bpm,
        audioUrl: currentSong.audioUrl,
        attachmentUrls: currentSong.attachmentUrls,
        status: currentSong.status,
        visibility: currentSong.visibility,
        privateNotes: currentSong.privateNotes,
        usageCount: currentSong.usageCount,
        lastUsedAt: currentSong.lastUsedAt,
        createdAt: currentSong.createdAt,
        updatedAt: currentSong.updatedAt,
        createdBy: currentSong.createdBy,
        modifiedBy: currentSong.modifiedBy,
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
                borderRadius: BorderRadius.circular(AppTheme.radius2))),
            
            Padding(
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              child: Row(
                children: [
                  Icon(Icons.music_note, color: AppTheme.warningColor),
                  const SizedBox(width: AppTheme.spaceSmall),
                  Text(
                    'Mode Musicien - Liste des chants',
                    style: Theme.of(context).textTheme.titleLarge),
                ])),
            
            Expanded(
              child: ListView.builder(
                itemCount: _songs.length,
                itemBuilder: (context, index) {
                  final song = _songs[index];
                  final isCurrentSong = index == _currentIndex;
                  
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isCurrentSong 
                          ? AppTheme.warningColor
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: isCurrentSong 
                              ? AppTheme.black100
                              : Theme.of(context).colorScheme.onSurface,
                          fontWeight: AppTheme.fontBold))),
                    title: Text(
                      song.title,
                      style: TextStyle(
                        fontWeight: isCurrentSong ? AppTheme.fontBold : FontWeight.normal)),
                    subtitle: Text('${song.authors.isNotEmpty ? song.authors : 'Auteur inconnu'} • ${song.originalKey.isNotEmpty ? song.originalKey : 'C'}'),
                    trailing: isCurrentSong 
                        ? Icon(Icons.music_note, color: AppTheme.warningColor)
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      _goToSong(index);
                    });
                })),
          ])));
  }
}
