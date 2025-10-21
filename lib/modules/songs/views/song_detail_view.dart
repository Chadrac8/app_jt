import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/widgets/base_page.dart';
import '../../../shared/widgets/custom_card.dart';
import '../models/song.dart';
import '../services/songs_service.dart';
import '../../../auth/auth_service.dart';
import '../../../../theme.dart';

/// Vue de détail d'un chant
class SongDetailView extends StatefulWidget {
  final Song song;

  const SongDetailView({
    Key? key,
    required this.song,
  }) : super(key: key);

  @override
  State<SongDetailView> createState() => _SongDetailViewState();
}

class _SongDetailViewState extends State<SongDetailView> {
  final SongsService _songsService = SongsService();
  late Song _song;
  bool _isFavorite = false;
  double _fontSize = 16.0;
  
  @override
  void initState() {
    super.initState();
    _song = widget.song;
    final userId = AuthService.currentUser?.uid;
    _isFavorite = userId != null ? _song.isFavoriteBy(userId) : false;
    _incrementViews();
  }

  Future<void> _incrementViews() async {
    try {
      await _songsService.incrementViews(_song.id!);
    } catch (e) {
      // L'erreur ne doit pas bloquer l'affichage
      print('Erreur lors de l\'incrémentation des vues: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      final userId = AuthService.currentUser?.uid;
      if (userId == null) throw Exception('Utilisateur non connecté');
      await _songsService.toggleFavorite(_song.id!, userId);
      setState(() {
        _isFavorite = !_isFavorite;
        if (_isFavorite) {
          _song = _song.copyWith(
            favorites: [..._song.favorites, userId],
          );
        } else {
          _song = _song.copyWith(
            favorites: _song.favorites.where((id) => id != userId).toList(),
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _shareSheet() {
    final shareText = '''
${_song.title}
${_song.subtitle?.isNotEmpty == true ? 'Sous-titre: ${_song.subtitle}' : ''}
${_song.author?.isNotEmpty == true ? 'Auteur: ${_song.author}' : ''}
${_song.composer?.isNotEmpty == true ? 'Compositeur: ${_song.composer}' : ''}
${_song.categories.isNotEmpty ? 'Catégories: ${_song.categories.join(', ')}' : ''}

--- PAROLES ---
${_song.lyrics}

--- Partagé depuis l'app Jubilé Tabernacle ---
''';

    Share.share(
      shareText,
      subject: 'Cantique: ${_song.title}',
    );
  }

  void _copyLyrics() {
    Clipboard.setData(ClipboardData(text: _song.lyrics));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Paroles copiées dans le presse-papiers')),
    );
  }

  Future<void> _playAudio() async {
    if (_song.audioUrl == null) return;
    
    try {
      final Uri audioUri = Uri.parse(_song.audioUrl!);
      if (await canLaunchUrl(audioUri)) {
        await launchUrl(
          audioUri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossible de lancer le lecteur audio')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la lecture audio: $e')),
        );
      }
    }
  }

  Future<void> _playVideo() async {
    if (_song.videoUrl == null) return;
    
    try {
      final Uri videoUri = Uri.parse(_song.videoUrl!);
      if (await canLaunchUrl(videoUri)) {
        await launchUrl(
          videoUri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossible de lancer le lecteur vidéo')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la lecture vidéo: $e')),
        );
      }
    }
  }

  Future<void> _showMusicSheet() async {
    if (_song.musicSheet == null) return;
    
    try {
      final Uri sheetUri = Uri.parse(_song.musicSheet!);
      if (await canLaunchUrl(sheetUri)) {
        await launchUrl(
          sheetUri,
          mode: LaunchMode.inAppWebView,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossible d\'afficher la partition')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'affichage de la partition: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: _song.title,
      actions: [
        IconButton(
          icon: Icon(
            _isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _isFavorite ? AppTheme.redStandard : null,
          ),
          onPressed: _toggleFavorite,
          tooltip: _isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
        ),
        PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'copy',
              child: ListTile(
                leading: Icon(Icons.copy),
                title: Text('Copier les paroles'),
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: ListTile(
                leading: Icon(Icons.share),
                title: Text('Partager'),
              ),
            ),
            const PopupMenuItem(
              value: 'font_size',
              child: ListTile(
                leading: Icon(Icons.text_fields),
                title: Text('Taille du texte'),
              ),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'copy':
                _copyLyrics();
                break;
              case 'share':
                _shareSheet();
                break;
              case 'font_size':
                _showFontSizeDialog();
                break;
            }
          },
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête du chant
            _buildSongHeader(),
            const SizedBox(height: AppTheme.spaceLarge),

            // Informations techniques
            if (_song.tonality != null || _song.tempo != null || _song.estimatedDuration != 'Non spécifiée')
              _buildTechnicalInfo(),

            // Catégories et tags
            if (_song.categories.isNotEmpty || _song.tags.isNotEmpty)
              _buildCategoriesAndTags(),

            // Paroles
            _buildLyrics(),

            // Médias
            if (_song.audioUrl != null || _song.videoUrl != null || _song.musicSheet != null)
              _buildMediaSection(),

            // Statistiques
            _buildStatistics(),

            const SizedBox(height: AppTheme.spaceXLarge),
          ],
        ),
      ),
    );
  }

  Widget _buildSongHeader() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre et sous-titre
            Text(
              _song.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: AppTheme.fontBold,
              ),
            ),
            if (_song.subtitle != null) ...[
              const SizedBox(height: AppTheme.spaceSmall),
              Text(
                _song.subtitle!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.grey600,
                ),
              ),
            ],

            const SizedBox(height: AppTheme.spaceMedium),

            // Auteur et compositeur
            if (_song.author != null || _song.composer != null) ...[
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: AppTheme.grey600),
                  const SizedBox(width: AppTheme.spaceSmall),
                  Expanded(
                    child: Text(
                      [
                        if (_song.author != null) 'Auteur: ${_song.author}',
                        if (_song.composer != null) 'Compositeur: ${_song.composer}',
                      ].join(' • '),
                      style: TextStyle(color: AppTheme.grey600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceSmall),
            ],

            // Statut d'approbation
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _song.isApproved ? AppTheme.greenStandard : AppTheme.orangeStandard,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Text(
                    _song.isApproved ? 'Approuvé' : 'En attente',
                    style: const TextStyle(
                      color: AppTheme.white100,
                      fontSize: AppTheme.fontSize12,
                      fontWeight: AppTheme.fontBold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Créé le ${_song.createdAt.day}/${_song.createdAt.month}/${_song.createdAt.year}',
                  style: TextStyle(
                    color: AppTheme.grey600,
                    fontSize: AppTheme.fontSize12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicalInfo() {
    return Column(
      children: [
        CustomCard(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informations techniques',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: AppTheme.fontBold,
                  ),
                ),
                const SizedBox(height: AppTheme.space12),
                Row(
                  children: [
                    if (_song.tonality != null) ...[
                      _buildInfoChip('Tonalité', _song.tonality!, Icons.music_note),
                      const SizedBox(width: AppTheme.space12),
                    ],
                    if (_song.tempo != null) ...[
                      _buildInfoChip('Tempo', '${_song.tempo} BPM', Icons.speed),
                      const SizedBox(width: AppTheme.space12),
                    ],
                    if (_song.estimatedDuration != 'Non spécifiée')
                      _buildInfoChip('Durée', _song.estimatedDuration, Icons.access_time),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
      ],
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).primaryColor),
          const SizedBox(width: AppTheme.spaceXSmall),
          Text(
            '$label: $value',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: AppTheme.fontBold,
              fontSize: AppTheme.fontSize12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesAndTags() {
    return Column(
      children: [
        CustomCard(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Classification',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: AppTheme.fontBold,
                  ),
                ),
                const SizedBox(height: AppTheme.space12),
                
                if (_song.categories.isNotEmpty) ...[
                  const Text('Catégories:', style: TextStyle(fontWeight: AppTheme.fontMedium)),
                  const SizedBox(height: AppTheme.spaceSmall),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _song.categories.map((category) => Chip(
                      label: Text(category),
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    )).toList(),
                  ),
                ],

                if (_song.categories.isNotEmpty && _song.tags.isNotEmpty)
                  const SizedBox(height: AppTheme.spaceMedium),

                if (_song.tags.isNotEmpty) ...[
                  const Text('Mots-clés:', style: TextStyle(fontWeight: AppTheme.fontMedium)),
                  const SizedBox(height: AppTheme.spaceSmall),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _song.tags.map((tag) => Chip(
                      label: Text('#$tag'),
                      backgroundColor: AppTheme.grey200,
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
      ],
    );
  }

  Widget _buildLyrics() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Paroles',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: AppTheme.fontBold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.text_fields),
                  onPressed: _showFontSizeDialog,
                  tooltip: 'Ajuster la taille du texte',
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            _buildFormattedLyricsText(),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaSection() {
    return Column(
      children: [
        const SizedBox(height: AppTheme.spaceMedium),
        CustomCard(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Médias',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: AppTheme.fontBold,
                  ),
                ),
                const SizedBox(height: AppTheme.space12),
                
                if (_song.audioUrl != null) ...[
                  ListTile(
                    leading: const Icon(Icons.audiotrack),
                    title: const Text('Audio'),
                    subtitle: const Text('Écouter le chant'),
                    trailing: const Icon(Icons.play_arrow),
                    onTap: () {
                      _playAudio();
                    },
                  ),
                ],

                if (_song.videoUrl != null) ...[
                  ListTile(
                    leading: const Icon(Icons.video_library),
                    title: const Text('Vidéo'),
                    subtitle: const Text('Regarder le chant'),
                    trailing: const Icon(Icons.play_arrow),
                    onTap: () {
                      _playVideo();
                    },
                  ),
                ],

                if (_song.musicSheet != null) ...[
                  ListTile(
                    leading: const Icon(Icons.library_music),
                    title: const Text('Partition'),
                    subtitle: const Text('Voir la partition'),
                    trailing: const Icon(Icons.visibility),
                    onTap: () {
                      _showMusicSheet();
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatistics() {
    return Column(
      children: [
        const SizedBox(height: AppTheme.spaceMedium),
        CustomCard(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Icon(Icons.visibility, color: AppTheme.grey600),
                      const SizedBox(height: AppTheme.spaceXSmall),
                      Text(
                        _song.views.toString(),
                        style: const TextStyle(
                          fontWeight: AppTheme.fontBold,
                          fontSize: AppTheme.fontSize18,
                        ),
                      ),
                      Text(
                        'Vues',
                        style: TextStyle(
                          color: AppTheme.grey600,
                          fontSize: AppTheme.fontSize12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppTheme.grey300,
                ),
                Expanded(
                  child: Column(
                    children: [
                      Icon(Icons.favorite, color: AppTheme.grey600),
                      const SizedBox(height: AppTheme.spaceXSmall),
                      Text(
                        _song.favorites.length.toString(),
                        style: const TextStyle(
                          fontWeight: AppTheme.fontBold,
                          fontSize: AppTheme.fontSize18,
                        ),
                      ),
                      Text(
                        'Favoris',
                        style: TextStyle(
                          color: AppTheme.grey600,
                          fontSize: AppTheme.fontSize12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showFontSizeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Taille du texte'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Taille: ${_fontSize.round()}px'),
              Slider(
                value: _fontSize,
                min: 12,
                max: 24,
                divisions: 12,
                onChanged: (value) {
                  setState(() {
                    _fontSize = value;
                  });
                  this.setState(() {
                    _fontSize = value;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  /// Construit le texte formaté des paroles avec style spécial pour chorus
  Widget _buildFormattedLyricsText() {
    final lines = _song.lyrics.split('\n');
    bool inChorusSection = false;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        // Détecter le début d'une section chorus
        if (line.toLowerCase().contains('chorus') || line.toLowerCase().contains('refrain')) {
          inChorusSection = true;
        }
        
        // Si la ligne est vide, on sort de la section chorus
        if (line.trim().isEmpty && inChorusSection) {
          inChorusSection = false;
        }
        
        final isChorusLine = line.toLowerCase().contains('chorus') || 
                           line.toLowerCase().contains('refrain') || 
                           inChorusSection;
        
        return Container(
          margin: EdgeInsets.only(
            left: isChorusLine ? 16.0 : 0.0, // Retrait réduit pour chorus
            bottom: 4.0,
          ),
          child: SelectableText(
            line,
            style: TextStyle(
              fontSize: _fontSize,
              height: 1.6,
              fontStyle: isChorusLine ? FontStyle.italic : FontStyle.normal, // Italique pour chorus
            ),
          ),
        );
      }).toList(),
    );
  }
}