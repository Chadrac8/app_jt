import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../modules/songs/models/song_model.dart';
import '../../theme.dart';

/// Carte de setlist Material Design 3 - Version complète avec animations
class SetlistCardPerfect13 extends StatefulWidget {
  final SetlistModel setlist;
  final VoidCallback? onTap;
  final VoidCallback? onMusicianMode;
  final VoidCallback? onConductorMode;

  const SetlistCardPerfect13({
    super.key,
    required this.setlist,
    this.onTap,
    this.onMusicianMode,
    this.onConductorMode,
  });

  @override
  State<SetlistCardPerfect13> createState() => _SetlistCardPerfect13State();
}

class _SetlistCardPerfect13State extends State<SetlistCardPerfect13>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _elevationAnimation = Tween<double>(
      begin: 1.0,
      end: 4.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _buildSetlistProgress(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final diff = widget.setlist.serviceDate.difference(now).inDays;
    
    if (diff > 7) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceSmall, vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: Text(
          'Planifiée',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: AppTheme.fontSemiBold,
            color: colorScheme.onPrimaryContainer,
            letterSpacing: 0.1,
          ),
        ),
      );
    } else if (diff >= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceSmall, vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: Text(
          'Bientôt',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: AppTheme.fontSemiBold,
            color: colorScheme.onTertiaryContainer,
            letterSpacing: 0.1,
          ),
        ),
      );
    } else if (diff >= -1) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceSmall, vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: Text(
          'Actuelle',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: AppTheme.fontSemiBold,
            color: colorScheme.onSecondaryContainer,
            letterSpacing: 0.1,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceMedium,
              vertical: AppTheme.spaceSmall,
            ),
            child: Card(
              elevation: _elevationAnimation.value,
              surfaceTintColor: colorScheme.surfaceTint,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onTap?.call();
                },
                onTapDown: (_) => _animationController.forward(),
                onTapUp: (_) => _animationController.reverse(),
                onTapCancel: () => _animationController.reverse(),
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spaceMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // En-tête avec icône et actions
                      Row(
                        children: [
                          // Icône moderne avec Material Design 3
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            ),
                            child: Icon(
                              Icons.queue_music,
                              color: colorScheme.onPrimaryContainer,
                              size: 24,
                            ),
                          ),
                          
                          const SizedBox(width: AppTheme.spaceMedium),
                          
                          // Titre et infos
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.setlist.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: AppTheme.fontSemiBold,
                                    color: colorScheme.onSurface,
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (widget.setlist.serviceType != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.setlist.serviceType!,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: AppTheme.fontMedium,
                                      color: colorScheme.primary,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          
                          // Actions rapides avec Material Design 3
                          _buildActionButtons(colorScheme),
                        ],
                      ),
                      
                      const SizedBox(height: AppTheme.spaceMedium),
                      
                      // Description si présente
                      if (widget.setlist.description.isNotEmpty) ...[
                        Text(
                          widget.setlist.description,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: AppTheme.fontRegular,
                            color: colorScheme.onSurfaceVariant,
                            height: 1.4,
                            letterSpacing: 0.1,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppTheme.spaceMedium),
                      ],
                      
                      // Informations détaillées avec badges Material Design 3
                      Row(
                        children: [
                          // Badge de date
                          _buildInfoChip(
                            context,
                            icon: Icons.calendar_today_outlined,
                            label: _formatDate(widget.setlist.serviceDate),
                            color: colorScheme.secondaryContainer,
                            onColor: colorScheme.onSecondaryContainer,
                          ),
                          
                          const SizedBox(width: AppTheme.spaceSmall),
                          
                          // Badge nombre de chants
                          _buildInfoChip(
                            context,
                            icon: Icons.music_note_outlined,
                            label: '${widget.setlist.songIds.length} chant${widget.setlist.songIds.length > 1 ? 's' : ''}',
                            color: colorScheme.tertiaryContainer,
                            onColor: colorScheme.onTertiaryContainer,
                          ),
                          
                          const Spacer(),
                          
                          // Indicateur de progression
                          _buildSetlistProgress(context),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Bouton mode musicien
        if (widget.onMusicianMode != null)
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onMusicianMode?.call();
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                ),
                child: Icon(
                  Icons.piano,
                  color: colorScheme.onTertiaryContainer,
                  size: 20,
                ),
              ),
            ),
          ),
        
        if (widget.onMusicianMode != null && widget.onConductorMode != null)
          const SizedBox(width: AppTheme.spaceSmall),
        
        // Bouton mode conducteur
        if (widget.onConductorMode != null)
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onConductorMode?.call();
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                ),
                child: Icon(
                  Icons.music_video,
                  color: colorScheme.onPrimaryContainer,
                  size: 20,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required Color onColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceSmall,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: onColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: AppTheme.fontMedium,
              color: onColor,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}