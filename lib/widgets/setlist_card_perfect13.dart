import 'package:flutter/material.dart';
import '../modules/songs/models/song_model.dart';

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
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6)),
        child: Text(
          'Planifiée',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.blue.shade700)));
    } else if (diff >= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6)),
        child: Text(
          'Bientôt',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.orange)));
    } else if (diff >= -1) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6)),
        child: Text(
          'Actuelle',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.green)));
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2)),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec icône et actions
                Row(
                  children: [
                    // Icône moderne
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.primaryContainer,
                          ]),
                        borderRadius: BorderRadius.circular(12),
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
                    
                    const SizedBox(width: 12),
                    
                    // Titre et infos
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            setlist.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                          if (setlist.serviceType != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              setlist.serviceType!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500)),
                          ],
                        ])),
                    
                    // Bouton mode musicien rapide
                    if (onMusicianMode != null)
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8)),
                          child: const Icon(
                            Icons.piano,
                            color: Colors.orange,
                            size: 20)),
                        tooltip: 'Mode Musicien',
                        onPressed: onMusicianMode),
                    
                    // Bouton mode conducteur rapide
                    if (onConductorMode != null)
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8)),
                          child: const Icon(
                            Icons.music_video_rounded,
                            color: Colors.green,
                            size: 20)),
                        tooltip: 'Mode Conducteur',
                        onPressed: onConductorMode),
                  ]),
                
                const SizedBox(height: 12),
                
                // Description si présente
                if (setlist.description.isNotEmpty) ...[
                  Text(
                    setlist.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),
                ],
                
                // Informations détaillées
                Row(
                  children: [
                    // Badge de date
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 12,
                            color: Theme.of(context).colorScheme.onSecondaryContainer),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(setlist.serviceDate),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSecondaryContainer)),
                        ])),
                    
                    const SizedBox(width: 8),
                    
                    // Badge nombre de chants
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.music_note_rounded,
                            size: 12,
                            color: Theme.of(context).colorScheme.onTertiaryContainer),
                          const SizedBox(width: 4),
                          Text(
                            '${setlist.songIds.length} chant${setlist.songIds.length > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onTertiaryContainer)),
                        ])),
                    
                    const Spacer(),
                    
                    // Indicateur de progression si applicable
                    _buildSetlistProgress(context),
                  ]),
              ])))));
  }
}
