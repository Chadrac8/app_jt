import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../modules/songs/models/song_model.dart';
import '../modules/songs/services/songs_firebase_service.dart';
import '../../theme.dart';

/// Carte de cantique - Material Design 3
class SongCardPerfect13 extends StatefulWidget {
  final SongModel song;
  final int songNumber;
  final VoidCallback? onTap;

  const SongCardPerfect13({
    super.key,
    required this.song,
    required this.songNumber,
    this.onTap,
  });

  @override
  State<SongCardPerfect13> createState() => _SongCardPerfect13State();
}

class _SongCardPerfect13State extends State<SongCardPerfect13>
    with SingleTickerProviderStateMixin {
  bool _isFavorite = false;
  late AnimationController _favoriteAnimationController;
  late Animation<double> _favoriteAnimation;

  @override
  void initState() {
    super.initState();
    _favoriteAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _favoriteAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _favoriteAnimationController,
      curve: Curves.elasticOut,
    ));
    _checkFavoriteStatus();
  }

  @override
  void dispose() {
    _favoriteAnimationController.dispose();
    super.dispose();
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
    // Animation de pulsation
    _favoriteAnimationController.forward().then((_) {
      _favoriteAnimationController.reverse();
    });

    if (_isFavorite) {
      await SongsFirebaseService.removeFromFavorites(widget.song.id);
    } else {
      await SongsFirebaseService.addToFavorites(widget.song.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: AppTheme.elevation1,
      shadowColor: colorScheme.shadow.withOpacity(0.2),
      surfaceTintColor: colorScheme.surfaceTint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        splashFactory: InkRipple.splashFactory,
        overlayColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.pressed)) {
              return colorScheme.primary.withValues(alpha: 0.12);
            }
            if (states.contains(WidgetState.hovered)) {
              return colorScheme.primary.withValues(alpha: 0.08);
            }
            return null;
          },
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Numéro du cantique - Style MD3
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Center(
                  child: Text(
                    widget.songNumber.toString(),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: AppTheme.fontSemiBold,
                      color: colorScheme.onPrimaryContainer,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: AppTheme.spaceMedium),
              
              // Contenu principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre du cantique
                    Text(
                      widget.song.title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: AppTheme.fontSemiBold,
                        color: colorScheme.onSurface,
                        letterSpacing: 0.15,
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: AppTheme.spaceXSmall),
                    
                    // Extrait des paroles
                    if (widget.song.lyrics.isNotEmpty) ...[
                      Text(
                        _getFirstLyricsLine(widget.song.lyrics),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                          letterSpacing: 0.25,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppTheme.spaceSmall),
                    ],
                    
                    // Métadonnées
                    Row(
                      children: [
                        // Tags/Style
                        if (widget.song.style.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spaceSmall,
                              vertical: AppTheme.spaceXSmall,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            ),
                            child: Text(
                              widget.song.style,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: AppTheme.fontMedium,
                                color: colorScheme.onSecondaryContainer,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        
                        // Compteur d'utilisation
                        if (widget.song.usageCount > 0) ...[
                          Icon(
                            Icons.play_circle_outline_rounded,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppTheme.spaceXSmall),
                          Text(
                            '${widget.song.usageCount}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spaceSmall),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: AppTheme.spaceSmall),
              
              // Bouton favori avec animation
              AnimatedBuilder(
                animation: _favoriteAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _favoriteAnimation.value,
                    child: IconButton(
                      onPressed: _toggleFavorite,
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          key: ValueKey(_isFavorite),
                          color: _isFavorite ? colorScheme.error : colorScheme.onSurfaceVariant,
                          size: 24,
                        ),
                      ),
                      style: IconButton.styleFrom(
                        foregroundColor: _isFavorite ? colorScheme.error : colorScheme.onSurfaceVariant,
                        backgroundColor: Colors.transparent,
                        padding: const EdgeInsets.all(AppTheme.spaceSmall),
                        minimumSize: const Size(40, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                      ),
                      tooltip: _isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getFirstLyricsLine(String lyrics) {
    // Nettoyer et extraire la première ligne significative
    final lines = lyrics.split('\n');
    for (final line in lines) {
      final cleanLine = line.trim();
      if (cleanLine.isNotEmpty && 
          !cleanLine.startsWith('[') && 
          !cleanLine.startsWith('(') &&
          cleanLine.length > 3) {
        return cleanLine;
      }
    }
    return lyrics.length > 100 ? '${lyrics.substring(0, 100)}...' : lyrics;
  }
}