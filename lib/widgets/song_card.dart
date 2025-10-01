import 'package:flutter/material.dart';
import '../modules/songs/models/song_model.dart';
import '../modules/songs/services/songs_firebase_service.dart';
import '../../theme.dart';

/// Widget pour afficher un chant dans une liste
class SongCard extends StatefulWidget {
  final SongModel song;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;
  final bool isSelected;
  final ValueChanged<bool>? onSelectionChanged;

  const SongCard({
    super.key,
    required this.song,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = false,
    this.isSelected = false,
    this.onSelectionChanged,
  });

  @override
  State<SongCard> createState() => _SongCardState();
}

class _SongCardState extends State<SongCard> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  void _checkFavoriteStatus() async {
    // Écouter les favoris de l'utilisateur
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

  Color _getStatusColor() {
    switch (widget.song.status) {
      case 'published':
        return AppTheme.greenStandard;
      case 'draft':
        return AppTheme.orangeStandard;
      case 'archived':
        return AppTheme.grey500;
      default:
        return AppTheme.blueStandard;
    }
  }

  IconData _getStatusIcon() {
    switch (widget.song.status) {
      case 'published':
        return Icons.check_circle;
      case 'draft':
        return Icons.edit;
      case 'archived':
        return Icons.archive;
      default:
        return Icons.music_note;
    }
  }

  String _getStatusText() {
    switch (widget.song.status) {
      case 'published':
        return 'Publié';
      case 'draft':
        return 'Brouillon';
      case 'archived':
        return 'Archivé';
      default:
        return 'Inconnu';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: widget.isSelected ? 4 : 1,
      color: widget.isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: widget.onSelectionChanged != null 
            ? () => widget.onSelectionChanged!(!widget.isSelected)
            : null,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec titre et actions
              Row(
                children: [
                  // Checkbox de sélection (si applicable)
                  if (widget.onSelectionChanged != null) ...[
                    Checkbox(
                      value: widget.isSelected,
                      onChanged: widget.onSelectionChanged != null
                          ? (bool? value) => widget.onSelectionChanged!(value ?? false)
                          : null,
                    ),
                    const SizedBox(width: AppTheme.spaceSmall),
                  ],
                  
                  // Titre du chant
                  Expanded(
                    child: Text(
                      widget.song.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: AppTheme.fontBold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  // Bouton favori
                  IconButton(
                    icon: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? AppTheme.redStandard : null,
                    ),
                    onPressed: _toggleFavorite,
                  ),
                  
                  // Menu d'actions
                  if (widget.showActions)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            widget.onEdit?.call();
                            break;
                          case 'delete':
                            widget.onDelete?.call();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit),
                              SizedBox(width: AppTheme.spaceSmall),
                              Text('Modifier'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: AppTheme.redStandard),
                              SizedBox(width: AppTheme.spaceSmall),
                              Text('Supprimer', style: TextStyle(color: AppTheme.redStandard)),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              
              // Auteurs
              if (widget.song.authors.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spaceSmall),
                Text(
                  'Par: ${widget.song.authors}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              
              const SizedBox(height: AppTheme.space12),
              
              // Informations musicales
              Row(
                children: [
                  // Tonalité
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    child: Text(
                      widget.song.originalKey,
                      style: const TextStyle(fontWeight: AppTheme.fontBold),
                    ),
                  ),
                  
                  // Tempo (si disponible)
                  if (widget.song.tempo != null) ...[
                    const SizedBox(width: AppTheme.spaceSmall),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.greenStandard.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      child: Text(
                        '${widget.song.tempo} BPM',
                        style: const TextStyle(fontSize: AppTheme.fontSize12),
                      ),
                    ),
                  ],
                  
                  const Spacer(),
                  
                  // Statut
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(),
                          size: 16,
                          color: _getStatusColor(),
                        ),
                        const SizedBox(width: AppTheme.spaceXSmall),
                        Text(
                          _getStatusText(),
                          style: TextStyle(
                            fontSize: AppTheme.fontSize12,
                            color: _getStatusColor(),
                            fontWeight: AppTheme.fontBold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Tags
              if (widget.song.tags.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spaceSmall),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: widget.song.tags.take(3).map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.grey500.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(fontSize: AppTheme.fontSize10),
                    ),
                  )).toList(),
                ),
              ],
              
              // Statistiques d'utilisation et audio
              const SizedBox(height: AppTheme.spaceSmall),
              Row(
                children: [
                  // Compteur d'utilisation
                  if (widget.song.usageCount > 0) ...[
                    Icon(
                      Icons.play_arrow,
                      size: 16,
                      color: AppTheme.grey600,
                    ),
                    const SizedBox(width: AppTheme.spaceXSmall),
                    Text(
                      '${widget.song.usageCount} utilisations',
                      style: TextStyle(
                        fontSize: AppTheme.fontSize12,
                        color: AppTheme.grey600,
                      ),
                    ),
                  ],
                  
                  // Indicateur audio
                  if (widget.song.audioUrl != null) ...[
                    if (widget.song.usageCount > 0) const SizedBox(width: AppTheme.spaceMedium),
                    Icon(
                      Icons.audiotrack,
                      size: 16,
                      color: AppTheme.grey600,
                    ),
                    const SizedBox(width: AppTheme.spaceXSmall),
                    Text(
                      'Audio',
                      style: TextStyle(
                        fontSize: AppTheme.fontSize12,
                        color: AppTheme.grey600,
                      ),
                    ),
                  ],
                  
                  // Indicateur pièces jointes
                  if (widget.song.attachmentUrls.isNotEmpty) ...[
                    if (widget.song.usageCount > 0 || widget.song.audioUrl != null) 
                      const SizedBox(width: AppTheme.spaceMedium),
                    Icon(
                      Icons.attachment,
                      size: 16,
                      color: AppTheme.grey600,
                    ),
                    const SizedBox(width: AppTheme.spaceXSmall),
                    Text(
                      '${widget.song.attachmentUrls.length} fichier(s)',
                      style: TextStyle(
                        fontSize: AppTheme.fontSize12,
                        color: AppTheme.grey600,
                      ),
                    ),
                  ],
                  
                  const Spacer(),
                  
                  // Date de dernière utilisation
                  if (widget.song.lastUsedAt != null)
                    Text(
                      'Utilisé le ${_formatDate(widget.song.lastUsedAt!)}',
                      style: TextStyle(
                        fontSize: AppTheme.fontSize12,
                        color: AppTheme.grey600,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}