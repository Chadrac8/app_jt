import 'package:flutter/material.dart';
import '../modules/songs/models/song_model.dart';
import '../../theme.dart';

/// Widget pour afficher une setlist dans une liste
class SetlistCard extends StatelessWidget {
  final SetlistModel setlist;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;

  const SetlistCard({
    super.key,
    required this.setlist,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec titre et actions
              Row(
                children: [
                  // Icône de setlist
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spaceSmall),
                    decoration: BoxDecoration(
                      color: Color(0x1A1976D2), // 10% opacity of primaryColor (#1976D2)
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Icon(
                      Icons.playlist_play,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                  ),
                  
                  const SizedBox(width: AppTheme.space12),
                  
                  // Titre et description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          setlist.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: AppTheme.fontBold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (setlist.description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            setlist.description,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.grey600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Menu d'actions
                  if (showActions)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            onEdit?.call();
                            break;
                          case 'delete':
                            onDelete?.call();
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
              
              const SizedBox(height: AppTheme.space12),
              
              // Informations sur le service
              Row(
                children: [
                  // Date du service
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(0x1A2196F3), // 10% opacity of blue (#2196F3)
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: AppTheme.blueStandard),
                        const SizedBox(width: AppTheme.spaceXSmall),
                        Text(
                          _formatDate(setlist.serviceDate),
                          style: const TextStyle(
                            fontSize: AppTheme.fontSize12,
                            fontWeight: AppTheme.fontBold,
                            color: AppTheme.blueStandard,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Type de service (si spécifié)
                  if (setlist.serviceType != null) ...[
                    const SizedBox(width: AppTheme.spaceSmall),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(0x1A4CAF50), // 10% opacity of green (#4CAF50)
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      child: Text(
                        setlist.serviceType!,
                        style: const TextStyle(
                          fontSize: AppTheme.fontSize12,
                          fontWeight: AppTheme.fontBold,
                          color: AppTheme.greenStandard,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: AppTheme.space12),
              
              // Nombre de chants et aperçu
              Row(
                children: [
                  Icon(
                    Icons.music_note,
                    size: 16,
                    color: AppTheme.grey600,
                  ),
                  const SizedBox(width: AppTheme.spaceXSmall),
                  Text(
                    '${setlist.songIds.length} chant${setlist.songIds.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: AppTheme.fontSize14,
                      fontWeight: AppTheme.fontMedium,
                      color: AppTheme.grey700,
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Indicateur de notes
                  if (setlist.notes != null && setlist.notes!.isNotEmpty) ...[
                    Icon(
                      Icons.note,
                      size: 16,
                      color: AppTheme.grey600,
                    ),
                    const SizedBox(width: AppTheme.spaceXSmall),
                    Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: AppTheme.fontSize12,
                        color: AppTheme.grey600,
                      ),
                    ),
                  ],
                ],
              ),
              
              // Date de création
              const SizedBox(height: AppTheme.spaceSmall),
              Text(
                'Créé le ${_formatDate(setlist.createdAt)}',
                style: TextStyle(
                  fontSize: AppTheme.fontSize11,
                  color: AppTheme.grey500,
                ),
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