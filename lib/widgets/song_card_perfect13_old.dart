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
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
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
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
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
                      widget.songNumber.toString(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: AppTheme.fontBold,
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
                        widget.song.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: AppTheme.fontSemiBold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.song.authors.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.song.authors,
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
                
                // Icône favori
                Container(
                  margin: const EdgeInsets.only(left: 8, right: 8),
                  child: Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: _toggleFavorite,
                      customBorder: const CircleBorder(),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorite 
                              ? AppTheme.redStandard 
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Actions
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
