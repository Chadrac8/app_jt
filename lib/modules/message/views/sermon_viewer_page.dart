import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/wb_sermon.dart';
import '../models/sermon_note.dart';
import '../models/sermon_highlight.dart';
import '../providers/notes_highlights_provider.dart';
import '../widgets/note_form_dialog.dart';
import '../widgets/sermon_text_viewer_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';

/// Page de lecture d'un sermon avec texte et lecteur audio en bas
/// Inspiré de La Table Voix de Dieu
class SermonViewerPage extends StatefulWidget {
  final WBSermon sermon;
  final int? initialPage;
  final String? highlightId;

  const SermonViewerPage({
    super.key,
    required this.sermon,
    this.initialPage,
    this.highlightId,
  });

  @override
  State<SermonViewerPage> createState() => _SermonViewerPageState();
}

class _SermonViewerPageState extends State<SermonViewerPage> {
  // État de lecture
  bool _isFavorite = false;
  List<SermonNote> _notes = [];
  List<SermonHighlight> _highlights = [];

  // Lecteur audio
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isAudioLoading = false;
  bool _hasAudioError = false;
  bool _showAudioPlayer = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.sermon.isFavorite;
    _loadNotesAndHighlights();
    
    // Initialiser l'audio si disponible
    if (widget.sermon.audioUrl != null) {
      _initAudio();
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  /// Initialise le lecteur audio
  Future<void> _initAudio() async {
    if (widget.sermon.audioUrl == null) return;

    setState(() {
      _isAudioLoading = true;
      _hasAudioError = false;
    });

    try {
      await _audioPlayer.setUrl(widget.sermon.audioUrl!);
      setState(() {
        _isAudioLoading = false;
        _showAudioPlayer = true;
      });
    } catch (e) {
      setState(() {
        _isAudioLoading = false;
        _hasAudioError = true;
      });
      debugPrint('Erreur chargement audio: $e');
    }
  }

  /// Charge les notes et surlignements pour ce sermon
  Future<void> _loadNotesAndHighlights() async {
    final provider = context.read<NotesHighlightsProvider>();
    await provider.loadForSermon(widget.sermon.id);
    
    setState(() {
      _notes = provider.allNotes;
      _highlights = provider.allHighlights;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.sermon.title,
              style: const TextStyle(fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              widget.sermon.date,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
            onPressed: _toggleFavorite,
            tooltip: 'Favori',
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share),
                    SizedBox(width: 8),
                    Text('Partager'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'download',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Télécharger'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'info',
                child: Row(
                  children: [
                    Icon(Icons.info),
                    SizedBox(width: 8),
                    Text('Informations'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Texte du sermon (prend tout l'espace disponible)
          // Le widget essaie toujours de charger, même si textUrl est null
          // car il peut avoir un fichier local dans assets
          Expanded(
            child: SermonTextViewerWidget(
              sermon: widget.sermon,
              onCreateNote: _createNote,
            ),
          ),
          
          // Lecteur audio en bas (si disponible)
          if (_showAudioPlayer && widget.sermon.audioUrl != null)
            _buildBottomAudioPlayer(),
        ],
      ),
    );
  }

  /// Message quand pas de texte disponible
  Widget _buildNoTextAvailable() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.text_fields_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Texte non disponible',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Ce sermon n\'a pas de version texte',
            style: TextStyle(color: Colors.grey[600]),
          ),
          if (widget.sermon.pdfUrl != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _openExternal(widget.sermon.pdfUrl!),
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Ouvrir le PDF'),
            ),
          ],
        ],
      ),
    );
  }

  /// Lecteur audio fixé en bas de page
  Widget _buildBottomAudioPlayer() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 24,
            offset: const Offset(0, -2),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // En-tête compact avec titre
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
              child: Row(
                children: [
                  // Icône audio élégante
                  StreamBuilder<PlayerState>(
                    stream: _audioPlayer.playerStateStream,
                    builder: (context, snapshot) {
                      final isPlaying = snapshot.data?.playing ?? false;
                      return Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Theme.of(context).primaryColor.withOpacity(0.15),
                              Theme.of(context).primaryColor.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isPlaying ? Icons.graphic_eq_rounded : Icons.audiotrack_rounded,
                          color: Theme.of(context).primaryColor,
                          size: 16,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.sermon.title,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                            letterSpacing: -0.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Vitesse de lecture élégante
                  StreamBuilder<double>(
                    stream: _audioPlayer.speedStream,
                    builder: (context, snapshot) {
                      final speed = snapshot.data ?? 1.0;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showSpeedMenu(speed),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).primaryColor.withOpacity(0.08),
                                  Theme.of(context).primaryColor.withOpacity(0.04),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).primaryColor.withOpacity(0.15),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              '${speed}x',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).primaryColor,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Timeline élégante
            StreamBuilder<Duration?>(
              stream: _audioPlayer.positionStream,
              builder: (context, positionSnapshot) {
                final position = positionSnapshot.data ?? Duration.zero;
                final duration = _audioPlayer.duration ?? Duration.zero;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 3,
                      thumbShape: RoundSliderThumbShape(
                        enabledThumbRadius: 5,
                        elevation: 2,
                        pressedElevation: 4,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 14,
                      ),
                      activeTrackColor: Theme.of(context).primaryColor,
                      inactiveTrackColor: Theme.of(context).primaryColor.withOpacity(0.12),
                      thumbColor: Theme.of(context).primaryColor,
                      overlayColor: Theme.of(context).primaryColor.withOpacity(0.15),
                      trackShape: RoundedRectSliderTrackShape(),
                    ),
                    child: Slider(
                      value: duration.inMilliseconds > 0
                          ? position.inMilliseconds.toDouble().clamp(0, duration.inMilliseconds.toDouble())
                          : 0,
                      max: duration.inMilliseconds.toDouble() > 0 
                          ? duration.inMilliseconds.toDouble() 
                          : 1.0,
                      onChanged: (value) {
                        _audioPlayer.seek(Duration(milliseconds: value.toInt()));
                      },
                    ),
                  ),
                );
              },
            ),

            // Contrôles compacts
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Spacer gauche pour centrer les contrôles principaux
                  SizedBox(width: 32),

                  // Reculer 10s
                  _buildControlButton(
                    icon: Icons.replay_10_rounded,
                    onPressed: () {
                      final newPosition = _audioPlayer.position - const Duration(seconds: 10);
                      _audioPlayer.seek(newPosition);
                    },
                    size: 32,
                  ),

                  const SizedBox(width: 16),

                  // Play/Pause compact
                  StreamBuilder<PlayerState>(
                    stream: _audioPlayer.playerStateStream,
                    builder: (context, snapshot) {
                      final playerState = snapshot.data;
                      final isPlaying = playerState?.playing ?? false;
                      final processingState = playerState?.processingState;

                      if (processingState == ProcessingState.loading ||
                          processingState == ProcessingState.buffering) {
                        return Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Theme.of(context).primaryColor,
                                Theme.of(context).primaryColor.withOpacity(0.85),
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).primaryColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        );
                      }

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            if (isPlaying) {
                              _audioPlayer.pause();
                            } else {
                              _audioPlayer.play();
                            }
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Theme.of(context).primaryColor,
                                  Theme.of(context).primaryColor.withOpacity(0.85),
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(width: 16),

                  // Avancer 10s
                  _buildControlButton(
                    icon: Icons.forward_10_rounded,
                    onPressed: () {
                      final newPosition = _audioPlayer.position + const Duration(seconds: 10);
                      _audioPlayer.seek(newPosition);
                    },
                    size: 32,
                  ),

                  // Menu options
                  _buildControlButton(
                    icon: Icons.more_vert_rounded,
                    onPressed: _showAudioOptionsMenu,
                    size: 32,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    double size = 40,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor.withOpacity(0.08),
                Theme.of(context).primaryColor.withOpacity(0.04),
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).primaryColor.withOpacity(0.2),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Theme.of(context).primaryColor,
            size: size * 0.5,
          ),
        ),
      ),
    );
  }

  void _showAudioOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.tune_rounded, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 12),
                      const Text(
                        'Options audio',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    shrinkWrap: true,
                    children: [
                      ListTile(
                        leading: Icon(Icons.timer_outlined, color: Theme.of(context).primaryColor),
                        title: const Text('Minuteur d\'arrêt'),
                        subtitle: const Text('Arrêter la lecture après un délai'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () {
                          Navigator.pop(context);
                          _showSleepTimerDialog();
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.skip_next_rounded, color: Theme.of(context).primaryColor),
                        title: const Text('Lecture automatique'),
                        subtitle: const Text('Lire le sermon suivant'),
                        trailing: Switch(
                          value: false, // TODO: Implement state management
                          onChanged: (value) {
                            // TODO: Implement auto-play toggle
                          },
                        ),
                        onTap: () {
                          // Toggle handled by Switch
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.repeat_rounded, color: Theme.of(context).primaryColor),
                        title: const Text('Mode répétition'),
                        subtitle: const Text('Répéter ce sermon'),
                        trailing: Switch(
                          value: false, // TODO: Implement state management
                          onChanged: (value) {
                            _audioPlayer.setLoopMode(value ? LoopMode.one : LoopMode.off);
                          },
                        ),
                        onTap: () {
                          // Toggle handled by Switch
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.download_rounded, color: Theme.of(context).primaryColor),
                        title: const Text('Télécharger l\'audio'),
                        subtitle: const Text('Écouter hors ligne'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Téléchargement audio - Fonctionnalité à venir')),
                          );
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.picture_as_pdf_rounded, color: Theme.of(context).primaryColor),
                        title: const Text('Télécharger le PDF'),
                        subtitle: const Text('Version imprimable'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () {
                          Navigator.pop(context);
                          if (widget.sermon.pdfUrl != null && widget.sermon.pdfUrl!.isNotEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Téléchargement PDF - Fonctionnalité à venir')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('PDF non disponible pour ce sermon')),
                            );
                          }
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.share_rounded, color: Theme.of(context).primaryColor),
                        title: const Text('Partager'),
                        subtitle: const Text('Partager ce sermon'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Partage - Fonctionnalité à venir')),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSleepTimerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.timer_outlined, color: Theme.of(context).primaryColor),
            const SizedBox(width: 12),
            const Text('Minuteur d\'arrêt'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Arrêter la lecture après :'),
            const SizedBox(height: 16),
            ...[
              (5, '5 minutes'),
              (10, '10 minutes'),
              (15, '15 minutes'),
              (30, '30 minutes'),
              (60, '1 heure'),
            ].map((entry) => ListTile(
              title: Text(entry.$2),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Minuteur d\'arrêt réglé sur ${entry.$2}')),
                );
                // TODO: Implement sleep timer logic
              },
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _showSpeedMenu(double currentSpeed) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Vitesse de lecture',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ...([0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0].map((speed) {
                final isSelected = (currentSpeed - speed).abs() < 0.01;
                return ListTile(
                  leading: Radio<double>(
                    value: speed,
                    groupValue: currentSpeed,
                    onChanged: (value) {
                      if (value != null) {
                        _audioPlayer.setSpeed(value);
                        Navigator.pop(context);
                      }
                    },
                  ),
                  title: Text(
                    speed == 1.0 ? '${speed}x (Normal)' : '${speed}x',
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  onTap: () {
                    _audioPlayer.setSpeed(speed);
                    Navigator.pop(context);
                  },
                );
              }).toList()),
              const SizedBox(height: 16),
            ],
          ),
        ),
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
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    // TODO: Sauvegarder dans SermonsProvider
  }

  void _createNote() {
    showDialog(
      context: context,
      builder: (context) => NoteFormDialog(
        onSave: (note) async {
          final newNote = note.copyWith(sermonId: widget.sermon.id);
          final provider = context.read<NotesHighlightsProvider>();
          await provider.saveNote(newNote);
          await _loadNotesAndHighlights();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Note créée')),
            );
          }
        },
      ),
    );
  }

  void _showNotesList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Mes notes',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: _notes.isEmpty
                      ? const Center(
                          child: Text('Aucune note pour ce sermon'),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: _notes.length,
                          itemBuilder: (context, index) {
                            final note = _notes[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(note.title),
                                subtitle: Text(
                                  note.preview,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _editNote(note);
                                      },
                                      tooltip: 'Modifier',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      color: Colors.red,
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _deleteNote(note);
                                      },
                                      tooltip: 'Supprimer',
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _editNote(SermonNote note) {
    showDialog(
      context: context,
      builder: (context) => NoteFormDialog(
        note: note,
        onSave: (updatedNote) async {
          final provider = context.read<NotesHighlightsProvider>();
          await provider.saveNote(updatedNote);
          await _loadNotesAndHighlights();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Note mise à jour')),
            );
          }
        },
      ),
    );
  }

  Future<void> _deleteNote(SermonNote note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la note'),
        content: Text('Voulez-vous vraiment supprimer la note "${note.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final provider = context.read<NotesHighlightsProvider>();
      await provider.deleteNote(note.id);
      await _loadNotesAndHighlights();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note supprimée')),
        );
      }
    }
  }

  Future<void> _openExternal(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible d\'ouvrir: $url')),
        );
      }
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'share':
        _shareSermon();
        break;
      case 'download':
        _downloadSermon();
        break;
      case 'info':
        _showSermonInfo();
        break;
    }
  }

  void _shareSermon() {
    // TODO: Implémenter le partage avec share_plus
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Partage à implémenter (share_plus)')),
    );
  }

  void _downloadSermon() {
    // TODO: Implémenter le téléchargement
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Téléchargement à implémenter')),
    );
  }

  void _showSermonInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informations'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(Icons.calendar_today, 'Date', widget.sermon.date),
              _buildInfoRow(Icons.location_on, 'Lieu', widget.sermon.location),
              if (widget.sermon.durationMinutes != null)
                _buildInfoRow(
                  Icons.access_time,
                  'Durée',
                  '${widget.sermon.durationMinutes} min',
                ),
              _buildInfoRow(Icons.language, 'Langue', widget.sermon.language),
              if (widget.sermon.series.isNotEmpty)
                _buildInfoRow(
                  Icons.collections_bookmark,
                  'Séries',
                  widget.sermon.series.join(', '),
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
}
