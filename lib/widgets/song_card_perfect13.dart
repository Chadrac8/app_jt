import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../modules/songs/models/song_model.dart';
import '../../theme.dart';

/// Carte de cantique - Material Design 3
class SongCardPerfect13 extends StatelessWidget {
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
        onTap: onTap,
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
                    songNumber.toString(),
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
                      song.title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: AppTheme.fontSemiBold,
                        color: colorScheme.onSurface,
                        letterSpacing: 0.15,
                        height: 1.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: AppTheme.spaceXSmall),
                    
                    // Extrait des paroles
                    if (song.lyrics.isNotEmpty) ...[
                      Text(
                        _getFirstLyricsLine(song.lyrics),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                          letterSpacing: 0.25,
                          height: 1.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppTheme.spaceSmall),
                    ],
                    

                  ],
                ),
              ),
              
              const SizedBox(width: AppTheme.spaceMedium),
              
              // Indicateur de navigation - Design Material 3 optimisé
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: colorScheme.onSurfaceVariant.withOpacity(0.9),
                    size: 18,
                  ),
                ),
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