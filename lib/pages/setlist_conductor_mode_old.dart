import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../modules/songs/models/song_model.dart';
import '../modules/songs/services/songs_firebase_service.dart';
import '../pages/song_projection_page.dart';

/// Mode conducteur pour diriger une setlist de chants
/// Navigation séquentielle avec contrôles simplifiés
class SetlistConductorMode extends StatefulWidget {
  final SetlistModel setlist;
  final int? startIndex;

  const SetlistConductorMode({
    super.key,
    required this.setlist,
    this.startIndex,
  });

  @override
  State<SetlistConductorMode> createState() => _SetlistConductorModeState();
}

class _SetlistConductorModeState extends State<SetlistConductorMode>
    with TickerProviderStateMixin {
  List<SongModel> _songs = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _showLyrics = true;
  bool _isProjecting = false;
  
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.startIndex ?? 0;
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this);
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this);
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn));
    
    _loadSongs();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _loadSongs() async {
    try {
      final songs = await SongsFirebaseService.getSetlistSongs(widget.setlist.songIds);
      if (mounted) {
        setState(() {
          _songs = songs;
          _isLoading = false;
        });
        _fadeController.forward();
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
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white))
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
            color: Colors.white.withOpacity(0.7)),
          const SizedBox(height: 20),
          Text(
            'Aucun chant dans cette setlist',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 20,
              fontWeight: FontWeight.w500)),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Retour'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white)),
        ]));
  }

  Widget _buildConductorInterface() {
    final currentSong = _songs[_currentIndex];
    
    return Stack(
      children: [
        // Arrière-plan avec gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black,
                Color(0xFF1A1A1A),
                Colors.black,
              ]))),
        
        // Interface principale
        SafeArea(
          child: Column(
            children: [
              _buildHeader(currentSong),
              Expanded(
                child: _showLyrics
                    ? _buildLyricsView(currentSong)
                    : _buildSongInfo(currentSong)),
              _buildNavigationControls(),
            ])),
        
        // Indicateur de projection
        if (_isProjecting)
          Positioned(
            top: 60,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2),
                ]),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.live_tv,
                    color: Colors.white,
                    size: 16),
                  SizedBox(width: 4),
                  Text(
                    'EN PROJECTION',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
                ]))),
      ]);
  }

  Widget _buildHeader(SongModel song) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.6),
          ]),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5)),
        ]),
      child: Column(
        children: [
          // Ligne supérieure : contrôles et infos
          Row(
            children: [
              // Bouton retour
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12)),
                child: IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: () => Navigator.pop(context))),
              
              const SizedBox(width: 16),
              
              // Info setlist
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.setlist.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                    Text(
                      'Chant ${_currentIndex + 1} sur ${_songs.length}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12)),
                  ])),
              
              // Contrôles d'affichage
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(_showLyrics ? 0.3 : 0.1),
                      borderRadius: BorderRadius.circular(8)),
                    child: IconButton(
                      icon: Icon(
                        _showLyrics ? Icons.lyrics : Icons.info_outline,
                        color: Colors.white,
                        size: 20),
                      onPressed: () {
                        setState(() {
                          _showLyrics = !_showLyrics;
                        });
                      })),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(_isProjecting ? 0.3 : 0.1),
                      borderRadius: BorderRadius.circular(8)),
                    child: IconButton(
                      icon: Icon(
                        _isProjecting ? Icons.stop_screen_share : Icons.screen_share,
                        color: Colors.white,
                        size: 20),
                      onPressed: _toggleProjection)),
                ]),
            ]),
          
          const SizedBox(height: 16),
          
          // Titre du chant actuel
          FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              song.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis)),
          
          if (song.authors.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              song.authors,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14),
              textAlign: TextAlign.center),
          ],
          
          if (song.originalKey.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12)),
              child: Text(
                'Tonalité: ${song.originalKey}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500))),
          ],
        ]));
  }

  Widget _buildLyricsView(SongModel song) {

  Widget _buildConductorInterface() {
    final currentSong = _songs[_currentIndex];
    
    return Stack(
      children: [
        // Arrière-plan avec gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black,
                Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                Colors.black,
              ]))),
        
        // Interface principale
        SafeArea(
          child: Column(
            children: [
              _buildHeader(currentSong),
              Expanded(
                child: _showLyrics
                    ? _buildLyricsView(currentSong)
                    : _buildSongInfo(currentSong)),
              _buildNavigationControls(),
            ])),
        
        // Indicateur de projection
        if (_isProjecting)
          Positioned(
            top: 60,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2),
                ]),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.live_tv,
                    color: Theme.of(context).colorScheme.surface,
                    size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'EN PROJECTION',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.surface,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
                ]))),
      ]);
  }

  Widget _buildHeader(SongModel song) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.6),
          ]),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5)),
        ]),
      child: Column(
        children: [
          // Ligne supérieure : contrôles et infos
          Row(
            children: [
              // Bouton retour
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12)),
                child: IconButton(
                  icon: Icon(Icons.close, 
                    color: Theme.of(context).colorScheme.surface),
                  onPressed: () => Navigator.pop(context))),
              
              const SizedBox(width: 16),
              
              // Info setlist
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                      'Chant ${_currentIndex + 1} sur ${_songs.length}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                        fontSize: 12)),
                  ])),
              
              // Contrôles d'affichage
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withOpacity(_showLyrics ? 0.3 : 0.1),
                      borderRadius: BorderRadius.circular(8)),
                    child: IconButton(
                      icon: Icon(
                        _showLyrics ? Icons.lyrics : Icons.info_outline,
                        color: Theme.of(context).colorScheme.surface,
                        size: 20),
                      onPressed: () {
                        setState(() {
                          _showLyrics = !_showLyrics;
                        });
                      })),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withOpacity(_isProjecting ? 0.3 : 0.1),
                      borderRadius: BorderRadius.circular(8)),
                    child: IconButton(
                      icon: Icon(
                        _isProjecting ? Icons.stop_screen_share : Icons.screen_share,
                        color: Theme.of(context).colorScheme.surface,
                        size: 20),
                      onPressed: _toggleProjection)),
                ]),
            ]),
          
          const SizedBox(height: 16),
          
          // Titre du chant actuel
          FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              song.title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.surface,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis)),
          
          if (song.authors.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              song.authors,
              style: TextStyle(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                fontSize: 14),
              textAlign: TextAlign.center),
          ],
          
          if (song.originalKey.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12)),
              child: Text(
                'Tonalité: ${song.originalKey}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.surface,
                  fontSize: 12,
                  fontWeight: FontWeight.w500))),
          ],
        ]));
  }

  Widget _buildLyricsView(SongModel song) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5)),
        ]),
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          child: Text(
            song.lyrics.isEmpty ? 'Aucune parole disponible' : song.lyrics,
            style: TextStyle(
              fontSize: 18,
              height: 1.6,
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w400),
            textAlign: TextAlign.left))));
  }

  Widget _buildSongInfo(SongModel song) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5)),
        ]),
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informations du chant
            if (song.originalKey.isNotEmpty) ...[
              _buildInfoRow('Tonalité originale', song.originalKey),
              const SizedBox(height: 12),
            ],
            
            if (song.tempo != null) ...[
              _buildInfoRow('Tempo', '${song.tempo} BPM'),
              const SizedBox(height: 12),
            ],
            
            if (song.tags.isNotEmpty) ...[
              _buildInfoRow('Tags', song.tags.join(', ')),
              const SizedBox(height: 12),
            ],
            
            if (song.bibleReferences.isNotEmpty) ...[
              _buildInfoRow('Références bibliques', song.bibleReferences.join(', ')),
              const SizedBox(height: 12),
            ],
            
            // Aperçu des paroles
            if (song.lyrics.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Aperçu des paroles:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12)),
                child: Text(
                  song.lyrics.length > 200 
                      ? '${song.lyrics.substring(0, 200)}...'
                      : song.lyrics,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Theme.of(context).colorScheme.onSurface))),
            ],
          ])));
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface))),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface))),
      ]);
  }

  Widget _buildNavigationControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.8),
          ])),
      child: Column(
        children: [
          // Indicateur de progression
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: Row(
              children: List.generate(_songs.length, (index) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    height: 4,
                    decoration: BoxDecoration(
                      color: index <= _currentIndex
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surface.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2))));
              }))),
          
          // Contrôles principaux
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Précédent
              _buildControlButton(
                icon: Icons.skip_previous_rounded,
                label: 'Précédent',
                onPressed: _currentIndex > 0 ? _goToPrevious : null,
                size: 60),
              
              // Pause/Play (optionnel)
              _buildControlButton(
                icon: Icons.pause_rounded,
                label: 'Pause',
                onPressed: () {
                  // Implémenter pause si nécessaire
                  HapticFeedback.mediumImpact();
                },
                size: 70,
                isPrimary: true),
              
              // Suivant
              _buildControlButton(
                icon: Icons.skip_next_rounded,
                label: 'Suivant',
                onPressed: _currentIndex < _songs.length - 1 ? _goToNext : null,
                size: 60),
            ]),
          
          const SizedBox(height: 16),
          
          // Actions secondaires
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSecondaryButton(
                icon: Icons.list_rounded,
                label: 'Liste',
                onPressed: _showSongList),
              
              _buildSecondaryButton(
                icon: Icons.fullscreen,
                label: 'Projection',
                onPressed: _openProjection),
              
              _buildSecondaryButton(
                icon: Icons.settings,
                label: 'Options',
                onPressed: _showOptions),
            ]),
        ]));
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required double size,
    bool isPrimary = false,
  }) {
    return Column(
      children: [
        Container(
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
                    ? Theme.of(context).colorScheme.surface.withOpacity(0.2)
                    : Theme.of(context).colorScheme.surface.withOpacity(0.1)),
            shape: BoxShape.circle,
            boxShadow: isPrimary ? [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 4)),
            ] : null),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(
              icon,
              color: onPressed != null
                  ? Theme.of(context).colorScheme.surface
                  : Theme.of(context).colorScheme.surface.withOpacity(0.4),
              size: size * 0.4),
            splashRadius: size / 2)),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: onPressed != null
                ? Theme.of(context).colorScheme.surface
                : Theme.of(context).colorScheme.surface.withOpacity(0.4),
            fontSize: 12,
            fontWeight: FontWeight.w500)),
      ]);
  }

  Widget _buildSecondaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.surface,
              size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.surface,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
          ])));
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
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SongProjectionPage(song: _songs[_currentIndex])));
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
                    subtitle: Text(song.authors),
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
