import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../modules/songs/models/song_model.dart';
import '../modules/songs/services/songs_firebase_service.dart';
import '../services/chord_transposer.dart';
import '../../theme.dart';

/// Widget pour afficher les paroles d'un chant - Material Design 3
class SongLyricsViewer extends StatefulWidget {
  final SongModel song;
  final bool showChords;
  final bool isProjectionMode;
  final VoidCallback? onToggleProjection;

  const SongLyricsViewer({
    super.key,
    required this.song,
    this.showChords = true,
    this.isProjectionMode = false,
    this.onToggleProjection,
  });

  @override
  State<SongLyricsViewer> createState() => _SongLyricsViewerState();
}

class _SongLyricsViewerState extends State<SongLyricsViewer>
    with TickerProviderStateMixin {
  String _currentKey = '';
  bool _showChords = true;
  double _fontSize = 16.0;
  bool _isFavorite = false;
  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;

  // Contrôles d'accessibilité
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    _currentKey = widget.song.originalKey;
    _showChords = widget.showChords;
    
    // Animation pour les transitions
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    ));
    
    // Démarre l'animation
    _fadeAnimationController.forward();
    
    // Écouter le scroll pour le bouton "retour en haut"
    _scrollController.addListener(_onScroll);
    
    // Vérifier le statut des favoris
    _checkFavoriteStatus();
  }

  void _checkFavoriteStatus() async {
    SongsFirebaseService.getUserFavorites().listen((favorites) {
      if (mounted) {
        setState(() {
          _isFavorite = favorites.contains(widget.song.id);
        });
      }
    });
  }

  void _toggleFavorite() async {
    if (_isFavorite) {
      await SongsFirebaseService.removeFromFavorites(widget.song.id);
    } else {
      await SongsFirebaseService.addToFavorites(widget.song.id);
    }
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 500 && !_showScrollToTop) {
      setState(() {
        _showScrollToTop = true;
      });
    } else if (_scrollController.offset <= 500 && _showScrollToTop) {
      setState(() {
        _showScrollToTop = false;
      });
    }
  }

  String get _displayedLyrics {
    if (_currentKey == widget.song.originalKey) {
      return widget.song.lyrics;
    }
    return ChordTransposer.transposeLyrics(
      widget.song.lyrics,
      widget.song.originalKey,
      _currentKey,
    );
  }



  void _copyLyrics() {
    Clipboard.setData(ClipboardData(text: _displayedLyrics));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Paroles copiées dans le presse-papiers',
          style: GoogleFonts.inter(letterSpacing: 0.25),
        ),
        backgroundColor: Theme.of(context).colorScheme.inverseSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
      ),
    );
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Column(
          children: [
            // Barre d'outils MD3
            if (!widget.isProjectionMode) _buildToolbar(),
            
            // Contenu des paroles
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                  ),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppTheme.spaceLarge),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // En-tête avec informations sur le cantique
                        _buildSongHeader(),
                        
                        const SizedBox(height: AppTheme.spaceLarge),
                        
                        // Paroles avec accords
                        _buildLyricsContent(),
                        
                        const SizedBox(height: AppTheme.spaceXXLarge),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        
        // Bouton scroll to top
        if (_showScrollToTop)
          Positioned(
            bottom: AppTheme.spaceMedium,
            right: AppTheme.spaceMedium,
            child: FloatingActionButton.small(
              onPressed: _scrollToTop,
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
              child: const Icon(Icons.keyboard_arrow_up_rounded),
            ),
          ),
      ],
    );
  }

  Widget _buildToolbar() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceMedium,
        vertical: AppTheme.spaceSmall,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Taille de police
          Icon(
            Icons.text_fields_rounded,
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppTheme.spaceSmall),
          Expanded(
            child: Slider(
              value: _fontSize,
              min: 12.0,
              max: 24.0,
              divisions: 12,
              label: _fontSize.round().toString(),
              onChanged: (value) {
                setState(() {
                  _fontSize = value;
                });
              },
              activeColor: colorScheme.primary,
              inactiveColor: colorScheme.surfaceContainerHighest,
            ),
          ),
          
          const SizedBox(width: AppTheme.spaceSmall),
          
          // Toggle accords
          IconButton(
            onPressed: () {
              setState(() {
                _showChords = !_showChords;
              });
            },
            icon: Icon(
              _showChords ? Icons.music_note_rounded : Icons.music_off_rounded,
            ),
            style: IconButton.styleFrom(
              backgroundColor: _showChords 
                  ? colorScheme.primaryContainer 
                  : Colors.transparent,
              foregroundColor: _showChords 
                  ? colorScheme.onPrimaryContainer 
                  : colorScheme.onSurfaceVariant,
            ),
            tooltip: _showChords ? 'Masquer les accords' : 'Afficher les accords',
          ),
          
          const SizedBox(width: AppTheme.spaceXSmall),
          
          // Copier les paroles
          IconButton(
            onPressed: _copyLyrics,
            icon: const Icon(Icons.copy_rounded),
            style: IconButton.styleFrom(
              foregroundColor: colorScheme.onSurfaceVariant,
            ),
            tooltip: 'Copier les paroles',
          ),
          
          const SizedBox(width: AppTheme.spaceXSmall),
          
          // Bouton favori
          IconButton(
            onPressed: _toggleFavorite,
            icon: Icon(
              _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            ),
            style: IconButton.styleFrom(
              backgroundColor: _isFavorite 
                  ? colorScheme.errorContainer 
                  : colorScheme.tertiaryContainer,
              foregroundColor: _isFavorite 
                  ? colorScheme.onErrorContainer 
                  : colorScheme.onTertiaryContainer,
            ),
            tooltip: _isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
          ),
        ],
      ),
    );
  }

  Widget _buildSongHeader() {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre
        Text(
          widget.song.title,
          style: GoogleFonts.inter(
            fontSize: AppTheme.fontSize24,
            fontWeight: AppTheme.fontBold,
            color: colorScheme.onSurface,
            letterSpacing: 0.0,
            height: 1.3,
          ),
        ),
        
        const SizedBox(height: AppTheme.spaceSmall),
        
        // Auteurs et métadonnées
        Wrap(
          spacing: AppTheme.spaceMedium,
          runSpacing: AppTheme.spaceSmall,
          children: [
            if (widget.song.authors.isNotEmpty)
              _buildInfoChip(
                Icons.person_rounded,
                'Auteur: ${widget.song.authors}',
                colorScheme,
              ),
            if (widget.song.originalKey.isNotEmpty)
              _buildInfoChip(
                Icons.music_note_rounded,
                'Tonalité: ${widget.song.originalKey}',
                colorScheme,
              ),
            if (widget.song.style.isNotEmpty)
              _buildInfoChip(
                Icons.style_rounded,
                'Style: ${widget.song.style}',
                colorScheme,
              ),
          ],
        ),
        
        // Transposition si nécessaire
        if (_currentKey != widget.song.originalKey) ...[
          const SizedBox(height: AppTheme.spaceSmall),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceMedium,
              vertical: AppTheme.spaceSmall,
            ),
            decoration: BoxDecoration(
              color: colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.transform_rounded,
                  size: 16,
                  color: colorScheme.onTertiaryContainer,
                ),
                const SizedBox(width: AppTheme.spaceSmall),
                Text(
                  'Transposé de ${widget.song.originalKey} vers $_currentKey',
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize12,
                    color: colorScheme.onTertiaryContainer,
                    fontWeight: AppTheme.fontMedium,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceSmall,
        vertical: AppTheme.spaceXSmall,
      ),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: AppTheme.spaceXSmall),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize12,
              color: colorScheme.onSecondaryContainer,
              fontWeight: AppTheme.fontMedium,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLyricsContent() {
    final colorScheme = Theme.of(context).colorScheme;
    final lines = _displayedLyrics.split('\n');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        if (line.trim().isEmpty) {
          return const SizedBox(height: AppTheme.spaceMedium);
        }
        
        // Détection des sections (Refrain, Couplet, etc.)
        if (line.startsWith('[') && line.endsWith(']')) {
          return Padding(
            padding: const EdgeInsets.only(
              top: AppTheme.spaceLarge,
              bottom: AppTheme.spaceSmall,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceMedium,
                vertical: AppTheme.spaceSmall,
              ),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Text(
                line.replaceAll('[', '').replaceAll(']', ''),
                style: GoogleFonts.inter(
                  fontSize: AppTheme.fontSize14,
                  fontWeight: AppTheme.fontSemiBold,
                  color: colorScheme.onPrimaryContainer,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          );
        }
        
        // Ligne normale avec paroles (et éventuellement accords)
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spaceSmall),
          child: _buildLyricsLine(line, colorScheme),
        );
      }).toList(),
    );
  }

  Widget _buildLyricsLine(String line, ColorScheme colorScheme) {
    // Simple affichage pour l'instant - peut être étendu pour parser les accords
    return Text(
      line,
      style: GoogleFonts.inter(
        fontSize: _fontSize,
        color: colorScheme.onSurface,
        height: 1.6,
        letterSpacing: 0.15,
      ),
    );
  }
}