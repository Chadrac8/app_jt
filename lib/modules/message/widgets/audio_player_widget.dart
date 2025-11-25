import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import '../models/wb_sermon.dart';

/// Widget de lecteur audio avec contrôles complets
class AudioPlayerWidget extends StatefulWidget {
  final WBSermon sermon;
  final Function(Duration)? onPositionChanged;

  const AudioPlayerWidget({
    super.key,
    required this.sermon,
    this.onPositionChanged,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late AudioPlayer _audioPlayer;
  bool _isLoading = true;
  String? _errorMessage;
  
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  Duration _bufferedPosition = Duration.zero;
  
  double _playbackSpeed = 1.0;
  final List<double> _speedOptions = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initAudioPlayer();
  }

  Future<void> _initAudioPlayer() async {
    if (widget.sermon.audioUrl == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Aucun audio disponible pour ce sermon';
      });
      return;
    }

    try {
      // Écouter les changements de durée
      _audioPlayer.durationStream.listen((duration) {
        if (duration != null) {
          setState(() {
            _duration = duration;
          });
        }
      });

      // Écouter les changements de position
      _audioPlayer.positionStream.listen((position) {
        setState(() {
          _position = position;
        });
        widget.onPositionChanged?.call(position);
      });

      // Écouter le buffer
      _audioPlayer.bufferedPositionStream.listen((bufferedPosition) {
        setState(() {
          _bufferedPosition = bufferedPosition;
        });
      });

      // Charger l'audio
      await _audioPlayer.setUrl(widget.sermon.audioUrl!);

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
    _audioPlayer.dispose();
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
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _initAudioPlayer();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Image de couverture
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _buildDefaultCover(),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Informations du sermon
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Text(
                  widget.sermon.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.sermon.date} • ${widget.sermon.location}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                
                // Barre de progression
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ProgressBar(
                    progress: _position,
                    buffered: _bufferedPosition,
                    total: _duration,
                    onSeek: (duration) {
                      _audioPlayer.seek(duration);
                    },
                    barHeight: 4,
                    thumbRadius: 8,
                    timeLabelTextStyle: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Contrôles de lecture
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Reculer de 15s
                    IconButton(
                      onPressed: () {
                        final newPosition = _position - const Duration(seconds: 15);
                        _audioPlayer.seek(
                          newPosition < Duration.zero ? Duration.zero : newPosition,
                        );
                      },
                      icon: const Icon(Icons.replay),
                      iconSize: 32,
                      tooltip: 'Reculer 15s',
                    ),
                    
                    // Play/Pause
                    StreamBuilder<PlayerState>(
                      stream: _audioPlayer.playerStateStream,
                      builder: (context, snapshot) {
                        final playerState = snapshot.data;
                        final isPlaying = playerState?.playing ?? false;
                        final processingState = playerState?.processingState;

                        if (processingState == ProcessingState.loading ||
                            processingState == ProcessingState.buffering) {
                          return Container(
                            width: 64,
                            height: 64,
                            margin: const EdgeInsets.all(8),
                            child: const CircularProgressIndicator(),
                          );
                        }

                        return Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).primaryColor,
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).primaryColor.withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: () {
                              if (isPlaying) {
                                _audioPlayer.pause();
                              } else {
                                _audioPlayer.play();
                              }
                            },
                            icon: Icon(
                              isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                            ),
                            iconSize: 48,
                          ),
                        );
                      },
                    ),
                    
                    // Avancer de 15s
                    IconButton(
                      onPressed: () {
                        final newPosition = _position + const Duration(seconds: 15);
                        _audioPlayer.seek(
                          newPosition > _duration ? _duration : newPosition,
                        );
                      },
                      icon: const Icon(Icons.forward),
                      iconSize: 32,
                      tooltip: 'Avancer 15s',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Contrôles secondaires
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Vitesse de lecture
                    PopupMenuButton<double>(
                      initialValue: _playbackSpeed,
                      onSelected: (speed) {
                        setState(() {
                          _playbackSpeed = speed;
                        });
                        _audioPlayer.setSpeed(speed);
                      },
                      icon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.speed),
                          const SizedBox(width: 4),
                          Text('${_playbackSpeed}x'),
                        ],
                      ),
                      itemBuilder: (context) {
                        return _speedOptions.map((speed) {
                          return PopupMenuItem<double>(
                            value: speed,
                            child: Row(
                              children: [
                                if (speed == _playbackSpeed)
                                  const Icon(Icons.check, size: 16)
                                else
                                  const SizedBox(width: 16),
                                const SizedBox(width: 8),
                                Text('${speed}x'),
                              ],
                            ),
                          );
                        }).toList();
                      },
                    ),
                    
                    // Loop
                    StreamBuilder<LoopMode>(
                      stream: _audioPlayer.loopModeStream,
                      builder: (context, snapshot) {
                        final loopMode = snapshot.data ?? LoopMode.off;
                        return IconButton(
                          onPressed: () {
                            if (loopMode == LoopMode.off) {
                              _audioPlayer.setLoopMode(LoopMode.one);
                            } else {
                              _audioPlayer.setLoopMode(LoopMode.off);
                            }
                          },
                          icon: Icon(
                            loopMode == LoopMode.one
                                ? Icons.repeat_one
                                : Icons.repeat,
                          ),
                          color: loopMode != LoopMode.off
                              ? Theme.of(context).primaryColor
                              : null,
                          tooltip: loopMode == LoopMode.one
                              ? 'Répétition activée'
                              : 'Répétition désactivée',
                        );
                      },
                    ),
                    
                    // Volume
                    StreamBuilder<double>(
                      stream: _audioPlayer.volumeStream,
                      builder: (context, snapshot) {
                        final volume = snapshot.data ?? 1.0;
                        return IconButton(
                          onPressed: () => _showVolumeDialog(volume),
                          icon: Icon(
                            volume == 0
                                ? Icons.volume_off
                                : volume < 0.5
                                    ? Icons.volume_down
                                    : Icons.volume_up,
                          ),
                          tooltip: 'Volume',
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultCover() {
    return Container(
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Center(
        child: Icon(
          Icons.audiotrack,
          size: 120,
          color: Theme.of(context).primaryColor.withOpacity(0.5),
        ),
      ),
    );
  }

  void _showVolumeDialog(double currentVolume) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Volume'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.volume_down),
                      Expanded(
                        child: Slider(
                          value: currentVolume,
                          onChanged: (value) {
                            _audioPlayer.setVolume(value);
                            setDialogState(() {});
                          },
                          min: 0,
                          max: 1,
                        ),
                      ),
                      const Icon(Icons.volume_up),
                    ],
                  ),
                  Text(
                    '${(currentVolume * 100).round()}%',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }
}
