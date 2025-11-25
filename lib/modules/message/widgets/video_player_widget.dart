import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../models/wb_sermon.dart';

/// Widget de lecteur vidéo avec contrôles complets
class VideoPlayerWidget extends StatefulWidget {
  final WBSermon sermon;
  final Function(Duration)? onPositionChanged;

  const VideoPlayerWidget({
    super.key,
    required this.sermon,
    this.onPositionChanged,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initVideoPlayer();
  }

  Future<void> _initVideoPlayer() async {
    if (widget.sermon.videoUrl == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Aucune vidéo disponible pour ce sermon';
      });
      return;
    }

    try {
      // Initialiser le contrôleur vidéo
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.sermon.videoUrl!),
      );

      await _videoController.initialize();

      // Créer le contrôleur Chewie avec options personnalisées
      _chewieController = ChewieController(
        videoPlayerController: _videoController,
        autoPlay: false,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: Theme.of(context).primaryColor,
          handleColor: Theme.of(context).primaryColor,
          bufferedColor: Theme.of(context).primaryColor.withOpacity(0.3),
          backgroundColor: Colors.grey.withOpacity(0.3),
        ),
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Erreur de lecture\n$errorMessage',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
        // Options de sous-titres (si disponible)
        // subtitleBuilder: (context, subtitle) => Container(
        //   padding: const EdgeInsets.all(10.0),
        //   child: Text(
        //     subtitle,
        //     style: const TextStyle(color: Colors.white),
        //   ),
        // ),
      );

      // Écouter les changements de position
      _videoController.addListener(() {
        if (_videoController.value.isInitialized) {
          widget.onPositionChanged?.call(_videoController.value.position);
        }
      });

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur de chargement: ${e.toString()}';
      });
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    _chewieController?.dispose();
    // Remettre l'orientation en portrait au retour
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _initVideoPlayer();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_chewieController == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      children: [
        // Lecteur vidéo
        Expanded(
          child: Container(
            color: Colors.black,
            child: Center(
              child: AspectRatio(
                aspectRatio: _videoController.value.aspectRatio,
                child: Chewie(controller: _chewieController!),
              ),
            ),
          ),
        ),
        
        // Informations et contrôles supplémentaires
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre du sermon
              Text(
                widget.sermon.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              
              // Date et lieu
              Text(
                '${widget.sermon.date} • ${widget.sermon.location}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 16),
              
              // Boutons d'action
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Plein écran
                  ActionChip(
                    avatar: const Icon(Icons.fullscreen, size: 18),
                    label: const Text('Plein écran'),
                    onPressed: () {
                      _chewieController?.enterFullScreen();
                    },
                  ),
                  
                  // Vitesse de lecture
                  ActionChip(
                    avatar: const Icon(Icons.speed, size: 18),
                    label: Text(
                      'Vitesse: ${_videoController.value.playbackSpeed}x',
                    ),
                    onPressed: () => _showPlaybackSpeedDialog(),
                  ),
                  
                  // Qualité (placeholder - nécessite implémentation backend)
                  ActionChip(
                    avatar: const Icon(Icons.hd, size: 18),
                    label: const Text('Qualité: Auto'),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Sélection de qualité non disponible',
                          ),
                        ),
                      );
                    },
                  ),
                  
                  // Picture-in-Picture (Android uniquement)
                  if (Theme.of(context).platform == TargetPlatform.android)
                    ActionChip(
                      avatar: const Icon(Icons.picture_in_picture_alt, size: 18),
                      label: const Text('PiP'),
                      onPressed: () {
                        // Note: Nécessite configuration dans AndroidManifest.xml
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Picture-in-Picture nécessite configuration',
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
              
              // Statistiques de lecture
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatChip(
                    Icons.timer,
                    'Durée',
                    _formatDuration(_videoController.value.duration),
                  ),
                  _buildStatChip(
                    Icons.signal_cellular_alt,
                    'Buffer',
                    '${(_videoController.value.buffered.isNotEmpty ? (_videoController.value.buffered.last.end.inSeconds / _videoController.value.duration.inSeconds * 100) : 0).toStringAsFixed(0)}%',
                  ),
                  _buildStatChip(
                    Icons.aspect_ratio,
                    'Ratio',
                    _videoController.value.aspectRatio.toStringAsFixed(2),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showPlaybackSpeedDialog() {
    final speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
    final currentSpeed = _videoController.value.playbackSpeed;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vitesse de lecture'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: speeds.map((speed) {
            return RadioListTile<double>(
              title: Text('${speed}x'),
              value: speed,
              groupValue: currentSpeed,
              onChanged: (value) {
                if (value != null) {
                  _videoController.setPlaybackSpeed(value);
                  Navigator.pop(context);
                  setState(() {});
                }
              },
            );
          }).toList(),
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

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }
}
