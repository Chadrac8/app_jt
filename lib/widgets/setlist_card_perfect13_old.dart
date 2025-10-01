import 'package:flutter/material.dart';
import '../modules/songs/models/song_model.dart';
import '../../theme.dart';

/// Carte de setlist - Reproduction exacte du style Perfect 13
class SetlistCardPerfect13 extends StatelessWidget {
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _buildSetlistProgress(BuildContext context) {
    // Simuler un statut de progression basé sur la date
    final now = DateTime.now();
    final diff = setlist.serviceDate.difference(now).inDays;
    
    if (diff > 7) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppTheme.blueStandard.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6)),
        child: Text(
          'Planifiée',
          style: TextStyle(
            fontSize: AppTheme.fontSize10,
            fontWeight: AppTheme.fontSemiBold,
            color: AppTheme.blueStandard)));
    } else if (diff >= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppTheme.orangeStandard.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6)),
        child: Text(
          'Bientôt',
          style: TextStyle(
            fontSize: AppTheme.fontSize10,
            fontWeight: AppTheme.fontSemiBold,
            color: AppTheme.orangeStandard)));
    } else if (diff >= -1) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppTheme.greenStandard.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6)),
        child: Text(
          'Actuelle',
          style: TextStyle(
            fontSize: AppTheme.fontSize10,
            fontWeight: AppTheme.fontSemiBold,
            color: AppTheme.greenStandard)));
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.95),
          ]),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black100.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2)),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec icône et actions
                Row(
                  children: [
                    // Icône moderne
                    Container(
                      padding: const EdgeInsets.all(AppTheme.space10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.primaryContainer,
                          ]),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2)),
                        ]),
                      child: Icon(
                        Icons.playlist_play_rounded,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 20)),
                    
                    const SizedBox(width: AppTheme.space12),
                    
                    // Titre et infos
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            setlist.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: AppTheme.fontBold,
                              color: Theme.of(context).colorScheme.onSurface),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                          if (setlist.serviceType != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              setlist.serviceType!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: AppTheme.fontMedium)),
                          ],
                        ])),
                    
                    // Bouton mode musicien rapide
                    if (onMusicianMode != null)
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(AppTheme.space6),
                          decoration: BoxDecoration(
                            color: AppTheme.orangeStandard.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
                          child: const Icon(
                            Icons.piano,
                            color: AppTheme.orangeStandard,
                            size: 20)),
                        tooltip: 'Mode Musicien',
                        onPressed: onMusicianMode),
                    
                    // Bouton mode conducteur rapide
                    if (onConductorMode != null)
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(AppTheme.space6),
                          decoration: BoxDecoration(
                            color: AppTheme.greenStandard.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
                          child: const Icon(
                            Icons.music_video_rounded,
                            color: AppTheme.greenStandard,
                            size: 20)),
                        tooltip: 'Mode Conducteur',
                        onPressed: onConductorMode),
                  ]),
                
                const SizedBox(height: AppTheme.space12),
                
                // Description si présente
                if (setlist.description.isNotEmpty) ...[
                  Text(
                    setlist.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                  const SizedBox(height: AppTheme.space12),
                ],
                
                // Informations détaillées
                Row(
                  children: [
                    // Badge de date
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 12,
                            color: Theme.of(context).colorScheme.onSecondaryContainer),
                          const SizedBox(width: AppTheme.spaceXSmall),
                          Text(
                            _formatDate(setlist.serviceDate),
                            style: TextStyle(
                              fontSize: AppTheme.fontSize11,
                              fontWeight: AppTheme.fontSemiBold,
                              color: Theme.of(context).colorScheme.onSecondaryContainer)),
                        ])),
                    
                    const SizedBox(width: AppTheme.spaceSmall),
                    
                    // Badge nombre de chants
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.music_note_rounded,
                            size: 12,
                            color: Theme.of(context).colorScheme.onTertiaryContainer),
                          const SizedBox(width: AppTheme.spaceXSmall),
                          Text(
                            '${setlist.songIds.length} chant${setlist.songIds.length > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: AppTheme.fontSize11,
                              fontWeight: AppTheme.fontSemiBold,
                              color: Theme.of(context).colorScheme.onTertiaryContainer)),
                        ])),
                    
                    const Spacer(),
                    
                    // Indicateur de progression si applicable
                    _buildSetlistProgress(context),
                  ]),
              ])))));
  }
}
