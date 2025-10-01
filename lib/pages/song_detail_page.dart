import 'package:flutter/material.dart';
import '../../theme.dart';
import '../modules/songs/models/song_model.dart';
import '../widgets/song_lyrics_viewer.dart';
import 'song_form_page.dart';
import 'song_projection_page.dart';

/// Page de détail d'un chant
class SongDetailPage extends StatefulWidget {
  final SongModel song;

  const SongDetailPage({
    super.key,
    required this.song,
  });

  @override
  State<SongDetailPage> createState() => _SongDetailPageState();
}

class _SongDetailPageState extends State<SongDetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.song.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.present_to_all),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SongProjectionPage(song: widget.song)));
            },
            tooltip: 'Mode projection'),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SongFormPage(song: widget.song)));
            },
            tooltip: 'Modifier'),
        ]),
      body: Column(
        children: [
          // En-tête avec informations du chant
          _buildHeader(),
          
          // Contenu des paroles
          Expanded(
            child: SongLyricsViewer(
              song: widget.song,
              onToggleProjection: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SongProjectionPage(song: widget.song)));
              })),
        ]));
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: AppTheme.black100.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2)),
        ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre et auteurs
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.song.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: AppTheme.fontBold)),
                    if (widget.song.authors.isNotEmpty) ...[
                      const SizedBox(height: AppTheme.spaceXSmall),
                      Text(
                        'Par: ${widget.song.authors}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: AppTheme.textTertiaryColor)),
                    ],
                  ])),
              
              // Statut
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getStatusIcon(),
                      size: 16,
                      color: _getStatusColor()),
                    const SizedBox(width: AppTheme.spaceXSmall),
                    Text(
                      _getStatusText(),
                      style: TextStyle(
                        fontSize: AppTheme.fontSize12,
                        color: _getStatusColor(),
                        fontWeight: AppTheme.fontBold)),
                  ])),
            ]),
          
          const SizedBox(height: AppTheme.spaceMedium),
          
          // Informations musicales et tags
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Tonalité
              _buildInfoChip(
                widget.song.originalKey,
                Theme.of(context).primaryColor,
                Icons.music_note),
              
              // Tempo (si disponible)
              if (widget.song.tempo != null)
                _buildInfoChip(
                  '${widget.song.tempo} BPM',
                  AppTheme.successColor,
                  Icons.speed),
              
              // Visibilité
              _buildInfoChip(
                _getVisibilityDisplayName(widget.song.visibility),
                AppTheme.warningColor,
                Icons.visibility),
            ]),
          
          // Tags
          if (widget.song.tags.isNotEmpty) ...[
            const SizedBox(height: AppTheme.space12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: widget.song.tags.map((tag) => Chip(
                label: Text(
                  tag,
                  style: const TextStyle(fontSize: AppTheme.fontSize12)),
                backgroundColor: AppTheme.textTertiaryColor.withOpacity(0.2))).toList()),
          ],
          
          // Statistiques
          if (widget.song.usageCount > 0 || widget.song.lastUsedAt != null) ...[
            const SizedBox(height: AppTheme.space12),
            Row(
              children: [
                if (widget.song.usageCount > 0) ...[
                  Icon(
                    Icons.play_arrow,
                    size: 16,
                    color: AppTheme.textTertiaryColor),
                  const SizedBox(width: AppTheme.spaceXSmall),
                  Text(
                    '${widget.song.usageCount} utilisations',
                    style: TextStyle(
                      fontSize: AppTheme.fontSize12,
                      color: AppTheme.textTertiaryColor)),
                ],
                
                if (widget.song.lastUsedAt != null) ...[
                  if (widget.song.usageCount > 0) const SizedBox(width: AppTheme.spaceMedium),
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppTheme.textTertiaryColor),
                  const SizedBox(width: AppTheme.spaceXSmall),
                  Text(
                    'Utilisé le ${_formatDate(widget.song.lastUsedAt!)}',
                    style: TextStyle(
                      fontSize: AppTheme.fontSize12,
                      color: AppTheme.textTertiaryColor)),
                ],
              ]),
          ],
          
          // Références bibliques
          if (widget.song.bibleReferences.isNotEmpty) ...[
            const SizedBox(height: AppTheme.space12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.space12),
              decoration: BoxDecoration(
                color: AppTheme.blueStandard.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.menu_book,
                        size: 16,
                        color: AppTheme.blueStandard),
                      const SizedBox(width: AppTheme.spaceXSmall),
                      Text(
                        'Références bibliques:',
                        style: TextStyle(
                          fontSize: AppTheme.fontSize12,
                          fontWeight: AppTheme.fontBold,
                          color: AppTheme.grey700)),
                    ]),
                  const SizedBox(height: AppTheme.spaceXSmall),
                  Text(
                    widget.song.bibleReferences.join(', '),
                    style: TextStyle(
                      fontSize: AppTheme.fontSize12,
                      color: AppTheme.grey700)),
                ])),
          ],
          
          // Notes privées (pour les administrateurs)
          if (widget.song.privateNotes != null && widget.song.privateNotes!.isNotEmpty) ...[
            const SizedBox(height: AppTheme.space12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.space12),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.lock,
                        size: 16,
                        color: AppTheme.warningColor),
                      const SizedBox(width: AppTheme.spaceXSmall),
                      Text(
                        'Notes privées:',
                        style: TextStyle(
                          fontSize: AppTheme.fontSize12,
                          fontWeight: AppTheme.fontBold,
                          color: AppTheme.warning)),
                    ]),
                  const SizedBox(height: AppTheme.spaceXSmall),
                  Text(
                    widget.song.privateNotes!,
                    style: TextStyle(
                      fontSize: AppTheme.fontSize12,
                      color: AppTheme.warning)),
                ])),
          ],
          
          // Audio/Vidéo
          if (widget.song.audioUrl != null) ...[
            const SizedBox(height: AppTheme.space12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.space12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
              child: Row(
                children: [
                  Icon(
                    Icons.audiotrack,
                    size: 16,
                    color: AppTheme.primaryColor),
                  const SizedBox(width: AppTheme.spaceSmall),
                  Expanded(
                    child: Text(
                      'Média disponible',
                      style: TextStyle(
                        fontSize: AppTheme.fontSize12,
                        fontWeight: AppTheme.fontBold,
                        color: AppTheme.primaryColor))),
                  TextButton(
                    onPressed: () {
                      // TODO: Ouvrir le lien audio/vidéo
                    },
                    child: const Text('Écouter')),
                ])),
          ],
        ]));
  }

  Widget _buildInfoChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppTheme.spaceXSmall),
          Text(
            label,
            style: TextStyle(
              fontSize: AppTheme.fontSize12,
              fontWeight: AppTheme.fontBold,
              color: color)),
        ]));
  }

  Color _getStatusColor() {
    switch (widget.song.status) {
      case 'published':
        return AppTheme.successColor;
      case 'draft':
        return AppTheme.warningColor;
      case 'archived':
        return AppTheme.textTertiaryColor;
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

  String _getVisibilityDisplayName(String visibility) {
    switch (visibility) {
      case 'public':
        return 'Public';
      case 'private':
        return 'Privé';
      case 'members_only':
        return 'Membres uniquement';
      default:
        return visibility;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}