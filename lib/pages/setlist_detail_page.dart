import 'package:flutter/material.dart';
import '../modules/songs/models/song_model.dart';
import '../modules/songs/services/songs_firebase_service.dart';
import '../widgets/song_card_perfect13.dart';
import 'setlist_form_page.dart';
import 'song_detail_page.dart';
import 'setlist_conductor_mode.dart';
import 'setlist_musician_mode.dart';
import '../../theme.dart';

/// Page de détail d'une setlist
class SetlistDetailPage extends StatefulWidget {
  final SetlistModel setlist;

  const SetlistDetailPage({
    super.key,
    required this.setlist,
  });

  @override
  State<SetlistDetailPage> createState() => _SetlistDetailPageState();
}

class _SetlistDetailPageState extends State<SetlistDetailPage> {
  List<SongModel> _songs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  void _loadSongs() async {
    try {
      final songs = await SongsFirebaseService.getSetlistSongs(widget.setlist.songIds);
      if (mounted) {
        setState(() {
          _songs = songs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des chants: $e'),
            backgroundColor: AppTheme.redStandard,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.setlist.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SetlistFormPage(setlist: widget.setlist),
                ),
              ).then((_) => _loadSongs()); // Recharger après modification
            },
            tooltip: 'Modifier',
          ),
        ],
      ),
      body: Column(
        children: [
          // En-tête avec informations de la setlist
          _buildHeader(),
          
          // Liste des chants
          Expanded(
            child: _buildSongsList(),
          ),
        ],
      ),
    );
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
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre et description
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.space12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Icon(
                  Icons.playlist_play,
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
              ),
              
              const SizedBox(width: AppTheme.spaceMedium),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.setlist.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: AppTheme.fontBold,
                      ),
                    ),
                    if (widget.setlist.description.isNotEmpty) ...[
                      const SizedBox(height: AppTheme.spaceXSmall),
                      Text(
                        widget.setlist.description,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.grey600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spaceMedium),
          
          // Informations sur le service
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              // Date du service
              _buildInfoChip(
                _formatDate(widget.setlist.serviceDate),
                AppTheme.blueStandard,
                Icons.calendar_today,
              ),
              
              // Type de service
              if (widget.setlist.serviceType != null)
                _buildInfoChip(
                  widget.setlist.serviceType!,
                  AppTheme.greenStandard,
                  Icons.event,
                ),
              
              // Nombre de chants
              _buildInfoChip(
                '${widget.setlist.songIds.length} chant${widget.setlist.songIds.length > 1 ? 's' : ''}',
                AppTheme.primaryColor,
                Icons.music_note,
              ),
            ],
          ),
          
          // Notes (si présentes)
          if (widget.setlist.notes != null && widget.setlist.notes!.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spaceMedium),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.space12),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.note,
                        size: 16,
                        color: AppTheme.warningColor,
                      ),
                      const SizedBox(width: AppTheme.spaceXSmall),
                      Text(
                        'Notes:',
                        style: TextStyle(
                          fontSize: AppTheme.fontSize12,
                          fontWeight: AppTheme.fontBold,
                          color: AppTheme.warning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceXSmall),
                  Text(
                    widget.setlist.notes!,
                    style: TextStyle(
                      fontSize: AppTheme.fontSize12,
                      color: AppTheme.warning,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Informations de création
          const SizedBox(height: AppTheme.space12),
          Text(
            'Créé le ${_formatDate(widget.setlist.createdAt)}',
            style: TextStyle(
              fontSize: AppTheme.fontSize12,
              color: AppTheme.grey600,
            ),
          ),
          
          // Boutons des modes (reproduction exacte de Perfect 13)
          const SizedBox(height: AppTheme.spaceMedium),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _songs.isNotEmpty ? _openConductorMode : null,
                  icon: const Icon(Icons.spatial_audio_off, size: 20),
                  label: const Text('Mode Conducteur'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: AppTheme.white100,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _songs.isNotEmpty ? _openMusicianMode : null,
                  icon: const Icon(Icons.music_note, size: 20),
                  label: const Text('Mode Musicien'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.warningColor,
                    foregroundColor: AppTheme.black100,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppTheme.space6),
          Text(
            label,
            style: TextStyle(
              fontSize: AppTheme.fontSize12,
              fontWeight: AppTheme.fontBold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_songs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.music_off,
              size: 64,
              color: AppTheme.grey500,
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            const Text(
              'Aucun chant dans cette setlist',
              style: TextStyle(fontSize: AppTheme.fontSize18, color: AppTheme.grey500),
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SetlistFormPage(setlist: widget.setlist),
                  ),
                ).then((_) => _loadSongs());
              },
              child: const Text('Ajouter des chants'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(
        left: AppTheme.spaceMedium,
        right: AppTheme.spaceMedium,
        top: AppTheme.spaceSmall,
        bottom: AppTheme.spaceXXLarge,
      ),
      itemCount: _songs.length,
      itemBuilder: (context, index) {
        final song = _songs[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spaceSmall),
          child: SongCardPerfect13(
            song: song,
            songNumber: index + 1,
            onTap: () {
              // Incrémenter le compteur d'utilisation
              SongsFirebaseService.incrementSongUsage(song.id);
              
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SongDetailPage(song: song),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _openConductorMode() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SetlistConductorMode(setlist: widget.setlist),
      ),
    );
  }

  void _openMusicianMode() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SetlistMusicianMode(setlist: widget.setlist),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}