import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme.dart';
import '../models/branham_sermon_model.dart';
import '../services/admin_branham_sermon_service.dart';
import '../services/branham_audio_player_service.dart';

/// Onglet "Écouter Le Message" - Interface moderne de prédications audio
class AudioPlayerTab extends StatefulWidget {
  const AudioPlayerTab({Key? key}) : super(key: key);

  @override
  State<AudioPlayerTab> createState() => _AudioPlayerTabState();
}

class _AudioPlayerTabState extends State<AudioPlayerTab>
    with TickerProviderStateMixin {
  final BranhamAudioPlayerService _audioPlayer = BranhamAudioPlayerService();
  
  List<BranhamSermon> _allSermons = [];
  BranhamSermon? _currentSermon;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  double _playbackSpeed = 1.0;
  
  // Filtres et recherche
  String _searchQuery = '';
  int? _selectedYear;
  String? _selectedSeries;
  final TextEditingController _searchController = TextEditingController();
  
  // Animations
  late AnimationController _waveController;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadSermons();
    _setupAudioListeners();
  }

  void _setupAnimations() {
    _waveController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeController.forward();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _fadeController.dispose();
    _searchController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadSermons({bool forceRefresh = false}) async {
    if (!mounted) return;
    
    try {
      
      List<BranhamSermon> sermons = [];
      
      try {
        final adminSermons = await AdminBranhamSermonService.getAllSermons();
        sermons = adminSermons.map((adminSermon) => BranhamSermon(
          id: adminSermon.id,
          title: adminSermon.title,
          date: adminSermon.date,
          location: adminSermon.location,
          duration: adminSermon.duration ?? Duration.zero,
          audioStreamUrl: adminSermon.audioUrl,
          audioDownloadUrl: adminSermon.audioDownloadUrl ?? adminSermon.audioUrl,
          year: int.tryParse(adminSermon.date.substring(0, 2)) != null 
            ? 1900 + int.parse(adminSermon.date.substring(0, 2))
            : DateTime.now().year,
          keywords: adminSermon.keywords,
          createdAt: adminSermon.createdAt,
          series: adminSermon.series,
        )).toList();
      } catch (e) {
        print('Erreur chargement sermons admin: $e');
        sermons = await _loadDemoSermons();
      }
      
      if (mounted) {
        setState(() {
          _allSermons = sermons;
          
          if (_currentSermon == null && sermons.isNotEmpty) {
            final filteredSermons = _filteredSermons;
            if (filteredSermons.isNotEmpty) {
              _currentSermon = filteredSermons.first;
              print('📻 Prédication auto-sélectionnée: ${_currentSermon!.title}');
            }
          }
        });
      }
      
      if (sermons.isEmpty) {
        print('⚠️ Aucune prédication trouvée.');
      } else {
        print('✅ ${sermons.length} prédications chargées');
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement: $e'),
            backgroundColor: AppTheme.redStandard,
            action: SnackBarAction(
              label: 'Réessayer',
              textColor: AppTheme.white100,
              onPressed: () => _loadSermons(forceRefresh: true),
            ),
          ),
        );
      }
    }
  }

  void _setupAudioListeners() {
    _audioPlayer.positionStream.listen((position) {
      if (mounted) {
        setState(() => _currentPosition = position);
      }
    });
    
    _audioPlayer.durationStream.listen((duration) {
      if (mounted) {
        setState(() => _totalDuration = duration ?? Duration.zero);
      }
    });
    
    _audioPlayer.playingStream.listen((playing) {
      if (mounted) {
        setState(() => _isPlaying = playing);
      }
    });

    _audioPlayer.speedStream.listen((speed) {
      if (mounted) {
        setState(() => _playbackSpeed = speed);
      }
    });
  }

  Future<List<BranhamSermon>> _loadDemoSermons() async {
    return [
      BranhamSermon(
        id: 'demo1',
        title: 'La Foi qui était une fois donnée aux Saints',
        date: '63-0714',
        location: 'Branham Tabernacle, Jeffersonville IN',
        duration: const Duration(hours: 2, minutes: 15),
        audioStreamUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
        audioDownloadUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
        year: 1963,
        keywords: ['foi', 'saints', 'révélation'],
        createdAt: DateTime.now(),
        series: 'Doctrine Fondamentale',
      ),
      BranhamSermon(
        id: 'demo2', 
        title: 'Les Noces de l\'Agneau',
        date: '65-1221',
        location: 'Branham Tabernacle, Jeffersonville IN',
        duration: const Duration(hours: 1, minutes: 45),
        audioStreamUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
        audioDownloadUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
        year: 1965,
        keywords: ['noces', 'agneau', 'épouse'],
        createdAt: DateTime.now(),
        series: 'Prophétie Finale',
      ),
      BranhamSermon(
        id: 'demo3',
        title: 'La Révélation des Sept Sceaux',
        date: '63-0317',
        location: 'Jeffersonville IN',
        duration: const Duration(hours: 2, minutes: 30),
        audioStreamUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
        audioDownloadUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
        year: 1963,
        keywords: ['sceaux', 'révélation', 'prophétie'],
        createdAt: DateTime.now(),
        series: 'Sept Sceaux',
      ),
    ];
  }

  // Méthodes de filtrage
  List<BranhamSermon> get _filteredSermons {
    var filtered = _allSermons.where((sermon) {
      // Filtre par recherche textuelle
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!sermon.title.toLowerCase().contains(query) &&
            !sermon.location.toLowerCase().contains(query) &&
            !sermon.keywords.any((k) => k.toLowerCase().contains(query))) {
          return false;
        }
      }
      
      // Filtre par année
      if (_selectedYear != null && sermon.year != _selectedYear) {
        return false;
      }
      
      // Filtre par série
      if (_selectedSeries != null && sermon.series != _selectedSeries) {
        return false;
      }
      
      return true;
    }).toList();
    
    // Tri par date (plus récent en premier)
    filtered.sort((a, b) => (b.year ?? 0).compareTo(a.year ?? 0));
    return filtered;
  }



  // Méthodes de contrôle audio
  void _togglePlayPause() async {
    if (_currentSermon == null) return;
    
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.playSermon(_currentSermon!);
    }
  }

  void _seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  void _playPrevious() {
    final currentIndex = _filteredSermons.indexOf(_currentSermon!);
    if (currentIndex > 0) {
      _selectSermon(_filteredSermons[currentIndex - 1]);
    }
  }

  void _playNext() {
    final currentIndex = _filteredSermons.indexOf(_currentSermon!);
    if (currentIndex < _filteredSermons.length - 1) {
      _selectSermon(_filteredSermons[currentIndex + 1]);
    }
  }

  void _selectSermon(BranhamSermon sermon) {
    setState(() {
      _currentSermon = sermon;
    });
    
    if (_isPlaying) {
      _audioPlayer.playSermon(sermon);
    }
  }

  void _showPlaylistBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPlaylistBottomSheet(),
    );
  }

  void _showSpeedSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildSpeedSelector(),
    );
  }

  void _showSleepTimer() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildSleepTimer(),
    );
  }

  void _shareCurrentSermon() {
    if (_currentSermon != null) {
      // Implémentation du partage
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Partage de "${_currentSermon!.title}"'),
        ),
      );
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (duration.inHours > 0) {
      return "${duration.inHours}:$twoDigitMinutes:$twoDigitSeconds";
    } else {
      return "$twoDigitMinutes:$twoDigitSeconds";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Column(
        children: [
          // En-tête moderne avec gradient
          _buildModernHeader(),
          
          // Lecteur principal moderne qui prend tout l'espace
          Expanded(
            child: _buildModernAudioPlayer(),
          ),
        ],
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.1),
            AppTheme.white100,
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black100.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.8)],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.headphones_rounded,
              color: AppTheme.white100,
              size: 32,
            ),
          ),
          const SizedBox(width: AppTheme.space20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Écouter le Message',
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: AppTheme.fontExtraBold,
                    color: AppTheme.grey800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceXSmall),
                Text(
                  'Prédications audio de William Branham',
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize15,
                    color: AppTheme.grey600,
                    fontWeight: AppTheme.fontMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernAudioPlayer() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0A0A0A),
            Color(0xFF1A1A1A),
            Color(0xFF0F0F0F),
          ],
        ),
      ),
      child: Column(
        children: [
          // Artwork et info principale
          Expanded(
            flex: 3,
            child: _buildArtworkSection(),
          ),
          
          // Contrôles de lecture
          _buildPlaybackControls(),
          
          // Barre de progression
          _buildProgressBar(),
          
          // Contrôles secondaires
          _buildSecondaryControls(),
          
          const SizedBox(height: AppTheme.spaceXLarge),
        ],
      ),
    );
  }

  Widget _buildArtworkSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Artwork avec effet de profondeur
          Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.width * 0.8,
            constraints: const BoxConstraints(
              maxWidth: 320,
              maxHeight: 320,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusRound),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 40,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: AppTheme.black100.withValues(alpha: 0.6),
                  blurRadius: 60,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusRound),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor.withValues(alpha: 0.8),
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withValues(alpha: 0.9),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Effet de vinyle
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _waveController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _isPlaying ? _waveController.value * 6.28 : 0,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(AppTheme.radiusRound),
                                border: Border.all(
                                  color: AppTheme.white100.withValues(alpha: 0.1),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.album_rounded,
                                color: AppTheme.white100.withValues(alpha: 0.8),
                                size: 120,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    // Icône centrale
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(AppTheme.spaceLarge),
                        decoration: BoxDecoration(
                          color: AppTheme.black100.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.music_note_rounded,
                          color: AppTheme.white100,
                          size: 48,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: AppTheme.spaceXLarge),
          
          // Informations de la prédication
          _buildTrackInfo(),
          
          const SizedBox(height: AppTheme.space20),
          
          // Bouton pour ouvrir la liste des prédications
          _buildPlaylistButton(),
        ],
      ),
    );
  }

  Widget _buildTrackInfo() {
    return Column(
      children: [
        Text(
          _currentSermon?.title ?? 'Aucune prédication sélectionnée',
          style: GoogleFonts.poppins(
            fontSize: AppTheme.fontSize22,
            fontWeight: AppTheme.fontBold,
            color: AppTheme.white100,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppTheme.spaceSmall),
        Text(
          _currentSermon?.date ?? '',
          style: GoogleFonts.inter(
            fontSize: AppTheme.fontSize16,
            color: AppTheme.white100.withValues(alpha: 0.7),
            fontWeight: AppTheme.fontMedium,
          ),
        ),
        if (_currentSermon?.location != null) ...[
          const SizedBox(height: AppTheme.spaceXSmall),
          Text(
            _currentSermon!.location,
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize14,
              color: AppTheme.white100.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildPlaylistButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        gradient: LinearGradient(
          colors: [
            AppTheme.white100.withValues(alpha: 0.1),
            AppTheme.white100.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(
          color: AppTheme.white100.withValues(alpha: 0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          onTap: _showPlaylistBottomSheet,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.queue_music_rounded,
                  color: AppTheme.white100.withValues(alpha: 0.9),
                  size: 20,
                ),
                const SizedBox(width: AppTheme.spaceSmall),
                Text(
                  'Choisir une prédication',
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize14,
                    color: AppTheme.white100.withValues(alpha: 0.9),
                    fontWeight: AppTheme.fontSemiBold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaybackControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Bouton précédent
          _buildControlButton(
            icon: Icons.skip_previous_rounded,
            size: 40,
            onTap: _playPrevious,
          ),
          
          // Bouton reculer 30s
          _buildControlButton(
            icon: Icons.replay_30_rounded,
            size: 32,
            onTap: () => _seek(_currentPosition - const Duration(seconds: 30)),
          ),
          
          // Bouton play/pause principal
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withValues(alpha: 0.8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(40),
                onTap: _togglePlayPause,
                child: Icon(
                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: AppTheme.white100,
                  size: 36,
                ),
              ),
            ),
          ),
          
          // Bouton avancer 30s
          _buildControlButton(
            icon: Icons.forward_30_rounded,
            size: 32,
            onTap: () => _seek(_currentPosition + const Duration(seconds: 30)),
          ),
          
          // Bouton suivant
          _buildControlButton(
            icon: Icons.skip_next_rounded,
            size: 40,
            onTap: _playNext,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required double size,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.white100.withValues(alpha: 0.1),
        border: Border.all(
          color: AppTheme.white100.withValues(alpha: 0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Icon(
            icon,
            color: AppTheme.white100.withValues(alpha: 0.9),
            size: size,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        children: [
          // Barre de progression
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.primaryColor,
              inactiveTrackColor: AppTheme.white100.withValues(alpha: 0.2),
              thumbColor: AppTheme.primaryColor,
              overlayColor: AppTheme.primaryColor.withValues(alpha: 0.3),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              trackHeight: 4,
            ),
            child: Slider(
              value: _totalDuration.inMilliseconds > 0
                  ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds
                  : 0.0,
              onChanged: (value) {
                final position = Duration(
                  milliseconds: (value * _totalDuration.inMilliseconds).round(),
                );
                _seek(position);
              },
            ),
          ),
          
          // Temps
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(_currentPosition),
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize12,
                    color: AppTheme.white100.withValues(alpha: 0.7),
                    fontWeight: AppTheme.fontMedium,
                  ),
                ),
                Text(
                  _formatDuration(_totalDuration),
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize12,
                    color: AppTheme.white100.withValues(alpha: 0.7),
                    fontWeight: AppTheme.fontMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Bouton vitesse
          _buildSecondaryButton(
            icon: Icons.speed_rounded,
            text: '${_playbackSpeed}x',
            onTap: _showSpeedSelector,
          ),
          
          // Bouton minuteur
          _buildSecondaryButton(
            icon: Icons.timer_rounded,
            text: 'Timer',
            onTap: _showSleepTimer,
          ),
          
          // Bouton partage
          _buildSecondaryButton(
            icon: Icons.share_rounded,
            text: 'Partager',
            onTap: _shareCurrentSermon,
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: AppTheme.white100.withValues(alpha: 0.7),
                size: 24,
              ),
              const SizedBox(height: AppTheme.spaceXSmall),
              Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: AppTheme.fontSize11,
                  color: AppTheme.white100.withValues(alpha: 0.7),
                  fontWeight: AppTheme.fontMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widgets bottom sheets simplifiés
  Widget _buildPlaylistBottomSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AppTheme.white100,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.grey300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Prédications disponibles',
              style: GoogleFonts.poppins(
                fontSize: AppTheme.fontSize18,
                fontWeight: AppTheme.fontBold,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredSermons.length,
              itemBuilder: (context, index) {
                final sermon = _filteredSermons[index];
                return ListTile(
                  title: Text(sermon.title),
                  subtitle: Text(sermon.date),
                  selected: sermon == _currentSermon,
                  onTap: () {
                    _selectSermon(sermon);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedSelector() {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Vitesse de lecture',
            style: GoogleFonts.poppins(
              fontSize: AppTheme.fontSize18,
              fontWeight: AppTheme.fontBold,
            ),
          ),
          const SizedBox(height: 20),
          ...speeds.map((speed) => ListTile(
            title: Text('${speed}x'),
            selected: _playbackSpeed == speed,
            onTap: () {
              _audioPlayer.setSpeed(speed);
              Navigator.pop(context);
            },
          )),
        ],
      ),
    );
  }

  Widget _buildSleepTimer() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Minuteur de veille',
            style: GoogleFonts.poppins(
              fontSize: AppTheme.fontSize18,
              fontWeight: AppTheme.fontBold,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Fonctionnalité à venir',
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize14,
              color: AppTheme.grey600,
            ),
          ),
        ],
      ),
    );
  }
}