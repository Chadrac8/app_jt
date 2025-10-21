import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:just_audio/just_audio.dart';
// import 'package:webview_flutter/webview_flutter.dart';
import 'youtube_service.dart';
import 'soundcloud_service.dart';
import '../../theme.dart';

/// Service pour gérer les lecteurs de médias intégrés
class MediaPlayerService {
  
  /// Crée un lecteur YouTube intégré
  static Widget buildYouTubePlayer({
    required String url,
    bool autoPlay = false,
    bool mute = false,
    bool showControls = true,
    bool loop = false,
  }) {
    final urlInfo = YouTubeService.parseYouTubeUrl(url);
    
    if (!urlInfo.isValid || urlInfo.videoId.isEmpty) {
      return _buildErrorWidget('URL YouTube invalide', Icons.error);
    }
    
    return YouTubePlayerWidget(
      videoId: urlInfo.videoId,
      autoPlay: autoPlay,
      mute: mute,
      showControls: showControls,
      loop: loop,
    );
  }
  
  /// Crée un lecteur SoundCloud intégré via WebView
  static Widget buildSoundCloudPlayer({
    required String url,
    bool autoPlay = false,
    bool showComments = true,
    String color = 'ff5500',
  }) {
    final urlInfo = SoundCloudService.parseSoundCloudUrl(url);
    
    if (!urlInfo.isValid) {
      return _buildErrorWidget('URL SoundCloud invalide', Icons.error);
    }
    
    return SoundCloudPlayerWidget(
      url: url,
      autoPlay: autoPlay,
      showComments: showComments,
      color: color,
    );
  }
  
  /// Crée un lecteur audio pour fichiers directs
  static Widget buildAudioFilePlayer({
    required String url,
    String? title,
    String? artist,
    bool autoPlay = false,
  }) {
    return AudioFilePlayerWidget(
      url: url,
      title: title,
      artist: artist,
      autoPlay: autoPlay,
    );
  }
  
  /// Widget d'erreur commun
  static Widget _buildErrorWidget(String message, IconData icon) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppTheme.grey50,
        border: Border.all(color: AppTheme.grey200),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: AppTheme.grey400),
            const SizedBox(height: AppTheme.spaceSmall),
            Text(
              message,
              style: TextStyle(color: AppTheme.grey600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget personnalisé pour le lecteur YouTube
class YouTubePlayerWidget extends StatefulWidget {
  final String videoId;
  final bool autoPlay;
  final bool mute;
  final bool showControls;
  final bool loop;
  
  const YouTubePlayerWidget({
    super.key,
    required this.videoId,
    this.autoPlay = false,
    this.mute = false,
    this.showControls = true,
    this.loop = false,
  });
  
  @override
  State<YouTubePlayerWidget> createState() => _YouTubePlayerWidgetState();
}

class _YouTubePlayerWidgetState extends State<YouTubePlayerWidget> {
  late YoutubePlayerController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: YoutubePlayerFlags(
        autoPlay: widget.autoPlay,
        mute: widget.mute,
        disableDragSeek: false,
        loop: widget.loop,
        isLive: false,
        forceHD: false,
        enableCaption: true,
        hideControls: !widget.showControls,
      ),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black100.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: YoutubePlayerBuilder(
          player: YoutubePlayer(
            controller: _controller,
            showVideoProgressIndicator: true,
            progressIndicatorColor: AppTheme.redStandard,
            topActions: <Widget>[
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  _controller.metadata.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: AppTheme.fontSize18,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          builder: (context, player) => player,
        ),
      ),
    );
  }
}

/// Widget simple pour SoundCloud (simulation pour démo)
class SoundCloudPlayerWidget extends StatelessWidget {
  final String url;
  final bool autoPlay;
  final bool showComments;
  final String color;
  
  const SoundCloudPlayerWidget({
    super.key,
    required this.url,
    this.autoPlay = false,
    this.showComments = true,
    this.color = 'ff5500',
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 166,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black100.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF5500), Color(0xFFFF7700)],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spaceMedium),
                  decoration: BoxDecoration(
                    color: AppTheme.white100.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    size: 32,
                    color: AppTheme.white100,
                  ),
                ),
                const SizedBox(height: AppTheme.space12),
                const Text(
                  'Lecteur SoundCloud Intégré',
                  style: TextStyle(
                    color: AppTheme.white100,
                    fontSize: AppTheme.fontSize16,
                    fontWeight: AppTheme.fontSemiBold,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceXSmall),
                Text(
                  autoPlay ? 'Lecture automatique activée' : 'Prêt à jouer',
                  style: TextStyle(
                    color: AppTheme.white100.withOpacity(0.8),
                    fontSize: AppTheme.fontSize12,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceMedium),
                // Barre de progression simulée
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.white100.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(AppTheme.radius2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: autoPlay ? 0.3 : 0.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.white100,
                        borderRadius: BorderRadius.circular(AppTheme.radius2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget pour lecteur audio de fichiers directs
class AudioFilePlayerWidget extends StatefulWidget {
  final String url;
  final String? title;
  final String? artist;
  final bool autoPlay;
  
  const AudioFilePlayerWidget({
    super.key,
    required this.url,
    this.title,
    this.artist,
    this.autoPlay = false,
  });
  
  @override
  State<AudioFilePlayerWidget> createState() => _AudioFilePlayerWidgetState();
}

class _AudioFilePlayerWidgetState extends State<AudioFilePlayerWidget> {
  late AudioPlayer _player;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    
    // Écouter les changements d'état
    _player.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          _isLoading = state.processingState == ProcessingState.loading ||
                     state.processingState == ProcessingState.buffering;
        });
      }
    });
    
    // Écouter la durée
    _player.durationStream.listen((duration) {
      if (mounted && duration != null) {
        setState(() {
          _duration = duration;
        });
      }
    });
    
    // Écouter la position
    _player.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });

    // Démarrage automatique si requis
    if (widget.autoPlay) {
      _loadAndPlay();
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _loadAndPlay() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      // Vérification du chemin
      if (widget.url.isEmpty) {
        throw Exception('Chemin du fichier audio vide');
      }
      await _player.setUrl(widget.url);
      await _player.play();
    } catch (e) {
      print('Erreur lors du chargement de l\'audio : $e');
      if (mounted) {
        setState(() {
          _error = 'Impossible de lire le fichier audio. Vérifiez le format ou le chemin.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _player.pause();
      } else {
        if (_player.audioSource == null) {
          await _loadAndPlay();
        } else {
          await _player.play();
        }
      }
    } catch (e) {
      print('Erreur lors de la lecture : $e');
    }
  }

  Future<void> _seek(Duration position) async {
    await _player.seek(position);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        decoration: BoxDecoration(
          color: AppTheme.grey50,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: AppTheme.grey200),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppTheme.redStandard, size: 32),
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: Text(_error!, style: const TextStyle(color: AppTheme.redStandard)),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: AppTheme.white100,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.grey200),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black100.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec informations du fichier
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.space12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Icon(
                  Icons.audiotrack,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title ?? 'Fichier Audio',
                      style: const TextStyle(
                        fontSize: AppTheme.fontSize16,
                        fontWeight: AppTheme.fontSemiBold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.artist != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.artist!,
                        style: TextStyle(
                          fontSize: AppTheme.fontSize14,
                          color: AppTheme.grey600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          // Contrôles de lecture
          Row(
            children: [
              // Bouton play/pause
              GestureDetector(
                onTap: _isLoading ? null : _togglePlayPause,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white100),
                          ),
                        )
                      : Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: AppTheme.white100,
                          size: 24,
                        ),
                ),
              ),
              const SizedBox(width: AppTheme.spaceMedium),
              // Barre de progression
              Expanded(
                child: Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: _duration.inMilliseconds > 0
                            ? _position.inMilliseconds.toDouble()
                            : 0.0,
                        max: _duration.inMilliseconds.toDouble(),
                        onChanged: (value) {
                          _seek(Duration(milliseconds: value.toInt()));
                        },
                        activeColor: Theme.of(context).primaryColor,
                        inactiveColor: AppTheme.grey300,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_position),
                            style: TextStyle(
                              fontSize: AppTheme.fontSize12,
                              color: AppTheme.grey600,
                            ),
                          ),
                          Text(
                            _formatDuration(_duration),
                            style: TextStyle(
                              fontSize: AppTheme.fontSize12,
                              color: AppTheme.grey600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}