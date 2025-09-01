import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../modules/songs/models/song_model.dart';
import '../modules/songs/services/songs_firebase_service.dart';
import '../pages/song_projection_page.dart';

/// Mode musicien pour jouer une setlist de chants
/// Interface spécialisée avec transposition et contrôles musicaux - Reproduction exacte de Perfect 13
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
  int _currentIndex = 0;
  List<SongModel> _songs = [];
  bool _isLoading = true;
  String _error = '';
  
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
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _slideController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _setupAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic));
  }

  Future<void> _loadSongs() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final songs = <SongModel>[];
      for (final songId in widget.setlist.songIds) {
        final song = await SongsFirebaseService.getSong(songId);
        if (song != null) {
          songs.add(song);
        }
      }

      setState(() {
        _songs = songs;
        _isLoading = false;
      });
      
      _slideController.forward();
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement: $e';
        _isLoading = false;
      });
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
    
    // Simple chord transposition logic
    for (int i = 0; i < _notes.length; i++) {
      if (chord.startsWith(_notes[i])) {
        int newIndex = (i + _transposeSteps) % _notes.length;
        if (newIndex < 0) newIndex += _notes.length;
        return chord.replaceFirst(_notes[i], _notes[newIndex]);
      }
    }
    return chord;
  }

  String _getTransposedKey(String originalKey) {
    return _transposeChord(originalKey);
  }

  void _openProjection() {
    if (_songs.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SongProjectionPage(
            song: _songs[_currentIndex])));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary)));
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text(_error,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.surface,
                  fontSize: 16),
                textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadSongs,
                child: const Text('Réessayer')),
            ])));
    }

    if (_songs.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.music_off_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.surface.withOpacity(0.7)),
              const SizedBox(height: 16),
              Text('Aucun chant dans cette setlist',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.surface,
                  fontSize: 16)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Retour')),
            ])));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black,
                  Colors.grey[900]!,
                  Colors.black,
                ]))),
          
          // Main content
          Column(
            children: [
              _buildTopBar(),
              Expanded(child: _buildSongContent()),
              _buildMusicianControls(),
            ]),
        ]));
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16))),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.close, 
                color: Theme.of(context).colorScheme.surface),
              tooltip: 'Fermer'),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.setlist.name,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.surface,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                  Text(
                    'Mode Musicien 🎸',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
                ])),
            
            // Projection button
            IconButton(
              onPressed: _openProjection,
              icon: Icon(Icons.screen_share, 
                color: Theme.of(context).colorScheme.surface),
              tooltip: 'Projection'),
          ])));
  }

  Widget _buildSongContent() {
    if (_songs.isEmpty) return const SizedBox();
    
    final currentSong = _songs[_currentIndex];
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Song header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  Theme.of(context).colorScheme.primaryContainer.withOpacity(0.6),
                ]),
              borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentSong.title,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.surface,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                          if (currentSong.authors.isNotEmpty)
                            Text(
                              currentSong.authors,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                                fontSize: 14)),
                        ])),
                    
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${_currentIndex + 1}/${_songs.length}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.surface,
                            fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8)),
                          child: Text(
                            _transposeSteps == 0 
                                ? currentSong.originalKey
                                : _getTransposedKey(currentSong.originalKey),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.surface,
                              fontSize: 12,
                              fontWeight: FontWeight.bold))),
                      ]),
                  ]),
              ])),
          
          const SizedBox(height: 16),
          
          // Song content based on view mode
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16)),
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildContentForViewMode(currentSong)))),
        ]));
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
      child: Text(
        song.lyrics.isEmpty ? 'Aucune parole disponible' : song.lyrics,
        style: TextStyle(
          fontSize: 16,
          height: 1.6,
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w400)));
  }

  Widget _buildChordsOnlyView(SongModel song) {
    // Extraction simplifiée des accords (peut être améliorée)
    final chords = <String>[];
    final lines = song.lyrics.split('\n');
    
    for (final line in lines) {
      // Recherche des accords entre crochets [Am], [C], etc.
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 16),
          
          if (chords.isEmpty)
            Text(
              'Aucun accord détecté dans ce chant',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)))
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: chords.map((chord) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8)),
                child: Text(
                  _transposeChord(chord),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer)))).toList()),
          
          const SizedBox(height: 24),
          
          Text(
            'Paroles avec accords:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 16),
          
          Text(
            song.lyrics.isEmpty ? 'Aucune parole disponible' : song.lyrics,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Theme.of(context).colorScheme.onSurface)),
        ]));
  }

  Widget _buildStructureOnlyView(SongModel song) {
    // Analyse simplifiée de la structure (peut être améliorée)
    final lines = song.lyrics.split('\n');
    final structure = <String>[];
    String currentSection = '';
    
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;
      
      // Détection des sections (patterns courants)
      if (trimmedLine.toLowerCase().contains('verse') ||
          trimmedLine.toLowerCase().contains('couplet')) {
        currentSection = 'Couplet';
        if (!structure.contains(currentSection)) structure.add(currentSection);
      } else if (trimmedLine.toLowerCase().contains('chorus') ||
                 trimmedLine.toLowerCase().contains('refrain')) {
        currentSection = 'Refrain';
        if (!structure.contains(currentSection)) structure.add(currentSection);
      } else if (trimmedLine.toLowerCase().contains('bridge') ||
                 trimmedLine.toLowerCase().contains('pont')) {
        currentSection = 'Pont';
        if (!structure.contains(currentSection)) structure.add(currentSection);
      }
    }
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Structure du chant:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 16),
          
          if (structure.isEmpty)
            Text(
              'Structure non détectée',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)))
          else
            ...structure.map((section) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8)),
              child: Text(
                section,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSecondaryContainer)))),
          
          const SizedBox(height: 24),
          
          Text(
            'Paroles complètes:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 16),
          
          Text(
            song.lyrics.isEmpty ? 'Aucune parole disponible' : song.lyrics,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Theme.of(context).colorScheme.onSurface)),
        ]));
  }

  Widget _buildMusicianControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // View mode toggle
            Row(
              children: [
                Expanded(
                  child: _buildToggleButton(
                    'Complet',
                    _viewMode == 'full',
                    () => setState(() => _viewMode = 'full'))),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildToggleButton(
                    'Accords',
                    _viewMode == 'chords_only',
                    () => setState(() => _viewMode = 'chords_only'))),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildToggleButton(
                    'Structure',
                    _viewMode == 'structure_only',
                    () => setState(() => _viewMode = 'structure_only'))),
              ]),
            
            const SizedBox(height: 12),
            
            // Transpose and BPM controls
            Row(
              children: [
                // Transpose
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => setState(() => _transposeSteps--),
                          icon: Icon(Icons.remove, 
                            color: Theme.of(context).colorScheme.surface),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero),
                        Column(
                          children: [
                            Text(
                              'Transpose',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.surface, 
                                fontSize: 10)),
                            Text(
                              _transposeSteps == 0 ? 'Original' : '${_transposeSteps > 0 ? '+' : ''}$_transposeSteps',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.surface, 
                                fontWeight: FontWeight.bold)),
                          ]),
                        IconButton(
                          onPressed: () => setState(() => _transposeSteps++),
                          icon: Icon(Icons.add, 
                            color: Theme.of(context).colorScheme.surface),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero),
                      ]))),
                
                const SizedBox(width: 12),
                
                // BPM
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => setState(() => _bpm = (_bpm - 5).clamp(60, 200)),
                          icon: Icon(Icons.remove, 
                            color: Theme.of(context).colorScheme.surface),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero),
                        Column(
                          children: [
                            Text(
                              'BPM',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.surface, 
                                fontSize: 10)),
                            Text(
                              '$_bpm',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.surface, 
                                fontWeight: FontWeight.bold)),
                          ]),
                        IconButton(
                          onPressed: () => setState(() => _bpm = (_bpm + 5).clamp(60, 200)),
                          icon: Icon(Icons.add, 
                            color: Theme.of(context).colorScheme.surface),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero),
                      ]))),
              ]),
            
            const SizedBox(height: 16),
            
            // Navigation controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavButton(
                  icon: Icons.skip_previous,
                  onPressed: _currentIndex > 0 ? _previousSong : null),
                
                _buildNavButton(
                  icon: Icons.list,
                  onPressed: _showSongList),
                
                _buildNavButton(
                  icon: Icons.skip_next,
                  onPressed: _currentIndex < _songs.length - 1 ? _nextSong : null),
              ]),
          ])));
  }

  Widget _buildToggleButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8)),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected 
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.surface,
            fontWeight: FontWeight.w600,
            fontSize: 12))));
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: onPressed != null 
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surface.withOpacity(0.1),
        shape: BoxShape.circle),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: onPressed != null 
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.surface.withOpacity(0.4))));
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
                    subtitle: Text('${song.authors} • ${song.originalKey}'),
                    trailing: isCurrentSong 
                        ? Icon(Icons.music_note, 
                            color: Theme.of(context).colorScheme.primary)
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      _goToSong(index);
                    });
                })),
          ])));
  }
}
