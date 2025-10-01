import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme.dart';
import '../models/branham_sermon_model.dart';
import '../services/admin_branham_sermon_service.dart';
import '../services/branham_audio_player_service.dart';
import '../../../theme.dart';

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
  bool _isLoading = true;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  double _playbackSpeed = 1.0;
  
  // Filtres et recherche
  String _searchQuery = '';
  int? _selectedYear;
  String? _selectedSeries;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  
  // Animations
  late AnimationController _waveController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadSermons();
    _setupAudioListeners();
  }

  void _setupAnimations() {
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

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
    if (mounted) {
      setState(() => _isLoading = true);
    }
    
    try {
      print('🔄 Chargement des prédications audio...');
      
      var sermons = await AdminBranhamSermonService.getActiveSermons();
      
      // Si aucune prédication admin n'est trouvée, utiliser les données de démonstration
      if (sermons.isEmpty) {
        print('⚠️ Aucune prédication admin trouvée, chargement des données de démonstration...');
        final demoSermons = await _loadDemoSermons();
        sermons = demoSermons;
      }
      
      if (mounted) {
        setState(() {
          _allSermons = sermons;
          _isLoading = false;
          
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
        setState(() => _isLoading = false);
      }
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

  /// Charge les données de démonstration si aucune prédication admin n'est disponible
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
      BranhamSermon(
        id: 'demo4',
        title: 'L\'Esprit de Vérité',
        date: '63-0118',
        location: 'Phoenix AZ',
        duration: const Duration(hours: 1, minutes: 30),
        audioStreamUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
        audioDownloadUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
        year: 1963,
        keywords: ['esprit', 'vérité', 'révélation'],
        createdAt: DateTime.now(),
        series: 'Doctrine Fondamentale',
      ),
      BranhamSermon(
        id: 'demo5',
        title: 'La Puissance de la Transformation',
        date: '65-1031',
        location: 'Prescott AZ',
        duration: const Duration(hours: 2, minutes: 0),
        audioStreamUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
        audioDownloadUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
        year: 1965,
        keywords: ['transformation', 'puissance', 'changement'],
        createdAt: DateTime.now(),
        series: 'Temps de la Fin',
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

  void _updateSearchQuery(String query) {
    if (mounted) {
      setState(() {
        _searchQuery = query;
      });
    }
  }

  void _updateYearFilter(int? year) {
    if (mounted) {
      setState(() {
        _selectedYear = year;
      });
    }
  }

  void _updateSeriesFilter(String? series) {
    if (mounted) {
      setState(() {
        _selectedSeries = series;
      });
    }
  }

  void _clearAllFilters() {
    if (mounted) {
      setState(() {
        _searchQuery = '';
        _selectedYear = null;
        _selectedSeries = null;
        _isSearching = false;
      });
    }
    _searchController.clear();
  }

  void _enterSearchMode() {
    if (mounted) {
      setState(() {
        _isSearching = true;
      });
    }
  }

  void _exitSearchMode() {
    if (mounted) {
      setState(() {
        _isSearching = false;
        _searchQuery = '';
      });
    }
    _searchController.clear();
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
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.white100,
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black100.withOpacity(0.08),
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
                colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0A0A0A),
            const Color(0xFF1A1A1A),
            const Color(0xFF0F0F0F),
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
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 40,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: AppTheme.black100.withOpacity(0.6),
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
                      AppTheme.primaryColor.withOpacity(0.8),
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withOpacity(0.9),
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
                                  color: AppTheme.white100.withOpacity(0.1),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.album_rounded,
                                color: AppTheme.white100.withOpacity(0.8),
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
                          color: AppTheme.black100.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
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
            color: AppTheme.white100.withOpacity(0.7),
            fontWeight: AppTheme.fontMedium,
          ),
        ),
        if (_currentSermon?.location != null) ...[
          const SizedBox(height: AppTheme.spaceXSmall),
          Text(
            _currentSermon!.location!,
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize14,
              color: AppTheme.white100.withOpacity(0.5),
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
            AppTheme.white100.withOpacity(0.1),
            AppTheme.white100.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: AppTheme.white100.withOpacity(0.2),
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
                  color: AppTheme.white100.withOpacity(0.9),
                  size: 20,
                ),
                const SizedBox(width: AppTheme.spaceSmall),
                Text(
                  'Choisir une prédication',
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize14,
                    color: AppTheme.white100.withOpacity(0.9),
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
                  AppTheme.primaryColor.withOpacity(0.8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.4),
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
        color: AppTheme.white100.withOpacity(0.1),
        border: Border.all(
          color: AppTheme.white100.withOpacity(0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Icon(
            icon,
            color: AppTheme.white100.withOpacity(0.9),
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
              inactiveTrackColor: AppTheme.white100.withOpacity(0.2),
              thumbColor: AppTheme.primaryColor,
              overlayColor: AppTheme.primaryColor.withOpacity(0.3),
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
                    color: AppTheme.white100.withOpacity(0.7),
                    fontWeight: AppTheme.fontMedium,
                  ),
                ),
                Text(
                  _formatDuration(_totalDuration),
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize12,
                    color: AppTheme.white100.withOpacity(0.7),
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
                color: AppTheme.white100.withOpacity(0.7),
                size: 24,
              ),
              const SizedBox(height: AppTheme.spaceXSmall),
              Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: AppTheme.fontSize11,
                  color: AppTheme.white100.withOpacity(0.7),
                  fontWeight: AppTheme.fontMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
                      ),
                    ),
                  ],
                ),
              ),
              if (!_isLoading && _allSermons.isNotEmpty)
                PopupMenuButton<String>(
                  icon: Container(
                    padding: const EdgeInsets.all(AppTheme.spaceSmall),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    child: Icon(
                      Icons.more_vert,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'search':
                        _enterSearchMode();
                        break;
                      case 'filter_year':
                        _showYearFilterDialog();
                        break;
                      case 'filter_series':
                        _showSeriesFilterDialog();
                        break;
                      case 'stats':
                        _showStatsDialog();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'search',
                      child: Row(
                        children: [
                          Icon(
                            Icons.search,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: AppTheme.space12),
                          Text(
                            'Rechercher',
                            style: GoogleFonts.inter(
                              fontSize: AppTheme.fontSize14,
                              fontWeight: AppTheme.fontMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'filter_year',
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_month,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: AppTheme.space12),
                          Text(
                            'Filtrer par année',
                            style: GoogleFonts.inter(
                              fontSize: AppTheme.fontSize14,
                              fontWeight: AppTheme.fontMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'filter_series',
                      child: Row(
                        children: [
                          Icon(
                            Icons.library_books,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: AppTheme.space12),
                          Text(
                            'Filtrer par série',
                            style: GoogleFonts.inter(
                              fontSize: AppTheme.fontSize14,
                              fontWeight: AppTheme.fontMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'stats',
                      child: Row(
                        children: [
                          Icon(
                            Icons.headset_mic,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: AppTheme.space12),
                          Text(
                            'Statistiques',
                            style: GoogleFonts.inter(
                              fontSize: AppTheme.fontSize14,
                              fontWeight: AppTheme.fontMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainPlayer() {
    if (_currentSermon == null) {
      return Container(
        margin: const EdgeInsets.all(AppTheme.space20),
        padding: const EdgeInsets.all(AppTheme.spaceLarge),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.white100,
              AppTheme.grey500.withOpacity(0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          boxShadow: [
            BoxShadow(
              color: AppTheme.black100.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.queue_music,
              size: 64,
              color: AppTheme.grey400,
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            Text(
              'Aucune prédication sélectionnée',
              style: GoogleFonts.poppins(
                fontSize: AppTheme.fontSize18,
                fontWeight: AppTheme.fontSemiBold,
                color: AppTheme.grey700,
              ),
            ),
            const SizedBox(height: AppTheme.spaceSmall),
            Text(
              'Sélectionnez une prédication ci-dessous pour commencer l\'écoute',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize14,
                color: AppTheme.grey600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.05),
            AppTheme.white100,
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLarge),
        child: Column(
          children: [
            // Infos de la prédication
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    _isPlaying ? Icons.graphic_eq : Icons.play_arrow,
                    color: AppTheme.white100,
                    size: 32,
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentSermon!.title,
                        style: GoogleFonts.crimsonText(
                          fontSize: AppTheme.fontSize18,
                          fontWeight: AppTheme.fontBold,
                          color: AppTheme.primaryColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppTheme.spaceXSmall),
                      Text(
                        '${_currentSermon!.location} • ${_currentSermon!.year}',
                        style: GoogleFonts.inter(
                          fontSize: AppTheme.fontSize14,
                          color: AppTheme.grey600,
                          fontWeight: AppTheme.fontMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.spaceLarge),
            
            // Barre de progression
            Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                    activeTrackColor: AppTheme.primaryColor,
                    inactiveTrackColor: AppTheme.grey300,
                    thumbColor: AppTheme.primaryColor,
                    overlayColor: AppTheme.primaryColor.withOpacity(0.2),
                  ),
                  child: Slider(
                    value: _totalDuration.inSeconds > 0
                        ? _currentPosition.inSeconds / _totalDuration.inSeconds
                        : 0.0,
                    onChanged: (value) {
                      final position = Duration(
                        seconds: (value * _totalDuration.inSeconds).round(),
                      );
                      _audioPlayer.seek(position);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_currentPosition),
                        style: GoogleFonts.inter(
                          fontSize: AppTheme.fontSize12,
                          color: AppTheme.grey600,
                          fontWeight: AppTheme.fontMedium,
                        ),
                      ),
                      Text(
                        _formatDuration(_totalDuration),
                        style: GoogleFonts.inter(
                          fontSize: AppTheme.fontSize12,
                          color: AppTheme.grey600,
                          fontWeight: AppTheme.fontMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.spaceLarge),
            
            // Contrôles de lecture
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: () => _audioPlayer.skipBackward30(),
                  icon: const Icon(Icons.replay_30),
                  iconSize: 32,
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.grey100,
                    foregroundColor: AppTheme.grey700,
                    padding: const EdgeInsets.all(AppTheme.space12),
                  ),
                ),
                
                // Bouton play/pause principal
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withOpacity(0.8),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _togglePlayPause,
                    icon: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 36,
                    ),
                    color: AppTheme.white100,
                    iconSize: 36,
                    padding: const EdgeInsets.all(AppTheme.spaceMedium),
                  ),
                ),
                
                IconButton(
                  onPressed: () => _audioPlayer.skipForward30(),
                  icon: const Icon(Icons.forward_30),
                  iconSize: 32,
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.grey100,
                    foregroundColor: AppTheme.grey700,
                    padding: const EdgeInsets.all(AppTheme.space12),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.spaceMedium),
            
            // Vitesse de lecture
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.speed,
                  size: 16,
                  color: AppTheme.grey600,
                ),
                const SizedBox(width: AppTheme.spaceSmall),
                DropdownButton<double>(
                  value: _playbackSpeed,
                  onChanged: (speed) {
                    if (speed != null) {
                      _audioPlayer.setSpeed(speed);
                    }
                  },
                  underline: Container(),
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize14,
                    color: AppTheme.grey700,
                    fontWeight: AppTheme.fontMedium,
                  ),
                  items: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((speed) {
                    return DropdownMenuItem(
                      value: speed,
                      child: Text('${speed}x'),
                    );
                  }).toList(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space20),
      child: Column(
        children: [
          if (_isSearching) ...[
            // Mode recherche
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.white100,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      onChanged: _updateSearchQuery,
                      decoration: InputDecoration(
                        hintText: 'Rechercher une prédication...',
                        hintStyle: GoogleFonts.inter(
                          color: AppTheme.grey500,
                          fontSize: AppTheme.fontSize14,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppTheme.primaryColor,
                        ),
                        suffixIcon: IconButton(
                          onPressed: _exitSearchMode,
                          icon: const Icon(Icons.close),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (_searchQuery.isNotEmpty || _selectedYear != null || _selectedSeries != null) ...[
            // Affichage des filtres actifs
            Container(
              padding: const EdgeInsets.all(AppTheme.space12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_alt,
                    color: AppTheme.primaryColor,
                    size: 16,
                  ),
                  const SizedBox(width: AppTheme.spaceSmall),
                  Expanded(
                    child: Text(
                      _buildActiveFiltersText(),
                      style: GoogleFonts.inter(
                        fontSize: AppTheme.fontSize12,
                        color: AppTheme.primaryColor,
                        fontWeight: AppTheme.fontMedium,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _clearAllFilters,
                    icon: const Icon(Icons.clear, size: 16),
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.white100,
                      padding: const EdgeInsets.all(AppTheme.spaceXSmall),
                      minimumSize: const Size(24, 24),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.space20),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: AppTheme.spaceLarge),
          Text(
            'Chargement des prédications...',
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize16,
              color: AppTheme.grey600,
              fontWeight: AppTheme.fontMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSermonsList() {
    final filteredSermons = _filteredSermons;
    
    if (filteredSermons.isEmpty) {
      return _buildEmptyState();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        itemCount: filteredSermons.length,
        itemBuilder: (context, index) {
          final sermon = filteredSermons[index];
          return _buildSermonCard(sermon, index);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spaceXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceLarge),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.1),
                    AppTheme.primaryColor.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _searchQuery.isNotEmpty ? Icons.search_off : Icons.headphones_outlined,
                size: 64,
                color: AppTheme.primaryColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Aucune prédication trouvée'
                  : _selectedYear != null || _selectedSeries != null
                      ? 'Aucune prédication pour ce filtre'
                      : 'Aucune prédication disponible',
              style: GoogleFonts.poppins(
                fontSize: AppTheme.fontSize20,
                fontWeight: AppTheme.fontSemiBold,
                color: AppTheme.grey700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.space12),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Essayez avec d\'autres termes de recherche'
                  : _selectedYear != null || _selectedSeries != null
                      ? 'Changez de filtre ou réinitialisez la recherche'
                      : 'Les prédications apparaîtront ici une fois ajoutées',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize14,
                color: AppTheme.grey600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spaceXLarge),
            ElevatedButton.icon(
              onPressed: _clearAllFilters,
              icon: const Icon(Icons.refresh),
              label: const Text('Réinitialiser'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: AppTheme.white100,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSermonCard(BranhamSermon sermon, int index) {
    final isCurrentSermon = _currentSermon?.id == sermon.id;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          side: BorderSide(
            color: isCurrentSermon 
                ? AppTheme.primaryColor.withOpacity(0.3)
                : AppTheme.grey500.withOpacity(0.1),
            width: isCurrentSermon ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          onTap: () => _playSermon(sermon),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  isCurrentSermon 
                      ? AppTheme.primaryColor.withOpacity(0.05)
                      : AppTheme.white100,
                  AppTheme.grey500.withOpacity(0.02),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.space20),
              child: Row(
                children: [
                  // Icône de statut
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isCurrentSermon 
                          ? AppTheme.primaryColor.withOpacity(0.1)
                          : AppTheme.grey500.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    child: Icon(
                      isCurrentSermon && _isPlaying
                          ? Icons.graphic_eq
                          : Icons.headphones,
                      color: isCurrentSermon ? AppTheme.primaryColor : AppTheme.grey600,
                    ),
                  ),
                  
                  const SizedBox(width: AppTheme.spaceMedium),
                  
                  // Informations de la prédication
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sermon.title,
                          style: GoogleFonts.crimsonText(
                            fontSize: AppTheme.fontSize16,
                            fontWeight: AppTheme.fontBold,
                            color: isCurrentSermon ? AppTheme.primaryColor : AppTheme.grey800,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppTheme.spaceXSmall),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: AppTheme.grey500,
                            ),
                            const SizedBox(width: AppTheme.spaceXSmall),
                            Text(
                              '${sermon.year}',
                              style: GoogleFonts.inter(
                                fontSize: AppTheme.fontSize12,
                                color: AppTheme.grey600,
                                fontWeight: AppTheme.fontMedium,
                              ),
                            ),
                            const SizedBox(width: AppTheme.space12),
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: AppTheme.grey500,
                            ),
                            const SizedBox(width: AppTheme.spaceXSmall),
                            Flexible(
                              child: Text(
                                sermon.location,
                                style: GoogleFonts.inter(
                                  fontSize: AppTheme.fontSize12,
                                  color: AppTheme.grey600,
                                  fontWeight: AppTheme.fontMedium,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (sermon.duration != null) ...[
                          const SizedBox(height: AppTheme.spaceXSmall),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: AppTheme.grey500,
                              ),
                              const SizedBox(width: AppTheme.spaceXSmall),
                              Text(
                                _formatDuration(sermon.duration!),
                                style: GoogleFonts.inter(
                                  fontSize: AppTheme.fontSize12,
                                  color: AppTheme.grey600,
                                  fontWeight: AppTheme.fontMedium,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Bouton d'action
                  IconButton(
                    onPressed: () => _playSermon(sermon),
                    icon: Icon(
                      isCurrentSermon && _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: isCurrentSermon ? AppTheme.primaryColor : AppTheme.grey600,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: isCurrentSermon 
                          ? AppTheme.primaryColor.withOpacity(0.1)
                          : AppTheme.grey100,
                      padding: const EdgeInsets.all(AppTheme.spaceSmall),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _playSermon(BranhamSermon sermon) async {
    try {
      if (!mounted) return;
      
      if (mounted) {
        setState(() {
          _currentSermon = sermon;
          _isLoading = true;
        });
      }

      HapticFeedback.lightImpact();
      
      if (_isPlaying && _currentSermon?.id == sermon.id) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.playSermon(sermon);
      }
      
      if (mounted) {
        setState(() => _isLoading = false);
      }
      
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de lecture: $e'),
            backgroundColor: AppTheme.redStandard,
          ),
        );
      }
    }
  }

  Future<void> _togglePlayPause() async {
    if (_currentSermon == null) return;
    
    try {
      HapticFeedback.lightImpact();
      
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.resume();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.redStandard,
          ),
        );
      }
    }
  }

  Future<void> _showYearFilterDialog() async {
    final availableYears = _allSermons
        .map((s) => s.year)
        .where((year) => year != null)
        .cast<int>()
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    
    final result = await showDialog<int?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Filtrer par année',
          style: GoogleFonts.poppins(
            fontWeight: AppTheme.fontSemiBold,
          ),
        ),
        content: SizedBox(
          width: double.minPositive,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: const Text('Toutes les années'),
                leading: Radio<int?>(
                  value: null,
                  groupValue: _selectedYear,
                  onChanged: (value) => Navigator.of(context).pop(value),
                ),
                onTap: () => Navigator.of(context).pop(null),
              ),
              ...availableYears.map((year) => ListTile(
                title: Text(year.toString()),
                leading: Radio<int?>(
                  value: year,
                  groupValue: _selectedYear,
                  onChanged: (value) => Navigator.of(context).pop(value),
                ),
                onTap: () => Navigator.of(context).pop(year),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
    
    if (result != _selectedYear) {
      _updateYearFilter(result);
    }
  }

  Future<void> _showSeriesFilterDialog() async {
    final availableSeries = _allSermons
        .map((s) => s.series)
        .where((s) => s != null && s.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList()
      ..sort();
    
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Filtrer par série',
          style: GoogleFonts.poppins(
            fontWeight: AppTheme.fontSemiBold,
          ),
        ),
        content: SizedBox(
          width: double.minPositive,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: const Text('Toutes les séries'),
                leading: Radio<String?>(
                  value: null,
                  groupValue: _selectedSeries,
                  onChanged: (value) => Navigator.of(context).pop(value),
                ),
                onTap: () => Navigator.of(context).pop(null),
              ),
              ...availableSeries.map((series) => ListTile(
                title: Text(series),
                leading: Radio<String?>(
                  value: series,
                  groupValue: _selectedSeries,
                  onChanged: (value) => Navigator.of(context).pop(value),
                ),
                onTap: () => Navigator.of(context).pop(series),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
    
    if (result != _selectedSeries) {
      _updateSeriesFilter(result);
    }
  }

  Future<void> _showStatsDialog() async {
    final totalSermons = _allSermons.length;
    final filteredSermons = _filteredSermons.length;
    final years = _allSermons
        .map((s) => s.year)
        .where((year) => year != null)
        .cast<int>()
        .toSet()
        .length;
    final series = _allSermons
        .map((s) => s.series)
        .where((s) => s != null && s.isNotEmpty)
        .cast<String>()
        .toSet()
        .length;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.headphones,
              color: AppTheme.primaryColor,
              size: 24,
            ),
            const SizedBox(width: AppTheme.spaceSmall),
            Text(
              'Statistiques audio',
              style: GoogleFonts.poppins(
                fontWeight: AppTheme.fontSemiBold,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatItem('Total des prédications', totalSermons.toString()),
            const SizedBox(height: AppTheme.space12),
            _buildStatItem('Prédications affichées', filteredSermons.toString()),
            const SizedBox(height: AppTheme.space12),
            _buildStatItem('Années disponibles', years.toString()),
            const SizedBox(height: AppTheme.space12),
            _buildStatItem('Séries disponibles', series.toString()),
            if (_selectedYear != null) ...[
              const SizedBox(height: AppTheme.space12),
              _buildStatItem('Année sélectionnée', _selectedYear.toString()),
            ],
            if (_selectedSeries != null) ...[
              const SizedBox(height: AppTheme.space12),
              _buildStatItem('Série sélectionnée', _selectedSeries!),
            ],
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: AppTheme.space12),
              _buildStatItem('Recherche active', '"$_searchQuery"'),
            ],
            if (_currentSermon != null) ...[
              const SizedBox(height: AppTheme.space12),
              _buildStatItem('En cours d\'écoute', _currentSermon!.title),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Fermer',
              style: GoogleFonts.inter(
                color: AppTheme.primaryColor,
                fontWeight: AppTheme.fontSemiBold,
              ),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize14,
              color: AppTheme.grey700,
              fontWeight: AppTheme.fontMedium,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: AppTheme.fontSize14,
              color: AppTheme.primaryColor,
              fontWeight: AppTheme.fontSemiBold,
            ),
          ),
        ),
      ],
    );
  }

  String _buildActiveFiltersText() {
    final filters = <String>[];
    
    if (_searchQuery.isNotEmpty) {
      filters.add('Recherche: "$_searchQuery"');
    }
    
    if (_selectedYear != null) {
      filters.add('Année: $_selectedYear');
    }
    
    if (_selectedSeries != null) {
      filters.add('Série: $_selectedSeries');
    }
    
    return filters.join(' • ');
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
}
