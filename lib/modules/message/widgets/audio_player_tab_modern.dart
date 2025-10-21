import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme.dart';
import '../models/branham_sermon_model.dart';
import '../services/admin_branham_sermon_service.dart';
import '../services/branham_audio_player_service.dart';

/// Onglet "Écouter Le Message" - Interface moderne de prédications audio
class AudioPlayerTabModern extends StatefulWidget {
  const AudioPlayerTabModern({Key? key}) : super(key: key);

  @override
  State<AudioPlayerTabModern> createState() => _AudioPlayerTabModernState();
}

class _AudioPlayerTabModernState extends State<AudioPlayerTabModern>
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
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _fadeController.dispose();
    _searchController.dispose();
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
        keywords: ['révélation', 'sceaux', 'prophétie'],
        createdAt: DateTime.now(),
        series: 'Apocalypse',
      ),
    ];
  }

  List<BranhamSermon> get _filteredSermons {
    List<BranhamSermon> filtered = List.from(_allSermons);
    
    // Filtre par recherche
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((sermon) {
        return sermon.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               sermon.date.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               sermon.location.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               sermon.keywords.any((keyword) => keyword.toLowerCase().contains(_searchQuery.toLowerCase()));
      }).toList();
    }
    
    // Filtre par année
    if (_selectedYear != null) {
      filtered = filtered.where((sermon) => sermon.year == _selectedYear).toList();
    }
    
    // Filtre par série
    if (_selectedSeries != null && _selectedSeries!.isNotEmpty) {
      filtered = filtered.where((sermon) => sermon.series == _selectedSeries).toList();
    }
    
    // Tri par date (plus récent en premier)
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return filtered;
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF232526),
            const Color(0xFF414345),
            const Color(0xFF232526),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusRound),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black100.withOpacity(0.18),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // Artwork et info principale
          Expanded(
            flex: 3,
            child: _buildArtworkSection(),
          ),
          // Barre de progression avec effet de profondeur
          Container(
            margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: AppTheme.white100.withOpacity(0.04),
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.black100.withOpacity(0.10),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _buildProgressBar(),
          ),
          // Contrôles de lecture (bouton play/pause, etc.)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            child: SizedBox(
              height: 60,
              child: _buildPlaybackControls(),
            ),
          ),
          // Espace final réduit
          const SizedBox(height: AppTheme.spaceMedium),
        ],
      ),
    );
  }

  Widget _buildArtworkSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Artwork avec effet de profondeur
            Container(
              width: MediaQuery.of(context).size.width * 0.55,
              height: MediaQuery.of(context).size.width * 0.55,
              constraints: const BoxConstraints(
                maxWidth: 180,
                maxHeight: 180,
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
            const SizedBox(height: AppTheme.spaceMedium),
            // Informations de la prédication
            _buildTrackInfo(),
            const SizedBox(height: AppTheme.space20),
            // Bouton pour ouvrir la liste des prédications
            _buildPlaylistButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppTheme.spaceXSmall),
        if (_currentSermon != null && (_currentSermon!.date.isNotEmpty || _currentSermon!.location.isNotEmpty))
          Text(
            '${_currentSermon!.date}${_currentSermon!.location.isNotEmpty ? ' - ' + _currentSermon!.location : ''}',
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize13,
              color: AppTheme.white100.withOpacity(0.7),
              fontWeight: AppTheme.fontMedium,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Bouton précédent
          _buildControlButton(
            icon: Icons.skip_previous_rounded,
            size: 38,
            onTap: _playPrevious,
          ),
          const SizedBox(width: AppTheme.space18),
          // Bouton reculer 30s
          _buildControlButton(
            icon: Icons.replay_30_rounded,
            size: 30,
            onTap: () => _seek(_currentPosition - const Duration(seconds: 30)),
          ),
          const SizedBox(width: AppTheme.space18),
          // Bouton play/pause principal
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withOpacity(0.85),
                  AppTheme.white100.withOpacity(0.18),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.35),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(42),
                onTap: _togglePlayPause,
                child: Icon(
                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: AppTheme.white100,
                  size: 44,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.space18),
          // Bouton avancer 30s
          _buildControlButton(
            icon: Icons.forward_30_rounded,
            size: 30,
            onTap: () => _seek(_currentPosition + const Duration(seconds: 30)),
          ),
          const SizedBox(width: AppTheme.space18),
          // Bouton suivant
          _buildControlButton(
            icon: Icons.skip_next_rounded,
            size: 38,
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
      width: size + 18,
      height: size + 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppTheme.white100.withOpacity(0.08),
            AppTheme.primaryColor.withOpacity(0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black100.withOpacity(0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppTheme.white100.withOpacity(0.13),
          width: 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular((size + 18) / 2),
          onTap: onTap,
          child: Icon(
            icon,
            color: AppTheme.white100,
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



  // Méthodes de contrôle audio
  void _togglePlayPause() async {
    if (_currentSermon == null) return;
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.resume();
      }
    } catch (e) {
      _showErrorSnackBar('Erreur de lecture: $e');
    }
  }

  void _playPrevious() {
    final filteredSermons = _filteredSermons;
    if (filteredSermons.isEmpty || _currentSermon == null) return;
    
    final currentIndex = filteredSermons.indexWhere((s) => s.id == _currentSermon!.id);
    if (currentIndex > 0) {
      _selectSermon(filteredSermons[currentIndex - 1]);
    }
  }

  void _playNext() {
    final filteredSermons = _filteredSermons;
    if (filteredSermons.isEmpty || _currentSermon == null) return;
    
    final currentIndex = filteredSermons.indexWhere((s) => s.id == _currentSermon!.id);
    if (currentIndex >= 0 && currentIndex < filteredSermons.length - 1) {
      _selectSermon(filteredSermons[currentIndex + 1]);
    }
  }

  void _seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  void _selectSermon(BranhamSermon sermon) {
    setState(() {
      _currentSermon = sermon;
    });
    HapticFeedback.lightImpact();
    // Charger et démarrer l'audio du sermon sélectionné
    _audioPlayer.playSermon(sermon);
  }

  // BottomSheet pour la liste des prédications
  void _showPlaylistBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPlaylistBottomSheet(),
    );
  }

  Widget _buildPlaylistBottomSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          // Poignée
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.white100.withOpacity(0.3),
              borderRadius: BorderRadius.circular(AppTheme.radius2),
            ),
          ),
          
          // En-tête
          Padding(
            padding: const EdgeInsets.all(AppTheme.space20),
            child: Row(
              children: [
                Icon(
                  Icons.queue_music_rounded,
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
                const SizedBox(width: AppTheme.space12),
                Text(
                  'Prédications disponibles',
                  style: GoogleFonts.poppins(
                    fontSize: AppTheme.fontSize20,
                    fontWeight: AppTheme.fontBold,
                    color: AppTheme.white100,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppTheme.white100,
                  ),
                ),
              ],
            ),
          ),
          
          // Barre de recherche
          _buildSearchBar(),
          
          // Liste des prédications
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredSermons.length,
                    itemBuilder: (context, index) {
                      final sermon = _filteredSermons[index];
                      return _buildSermonListItem(sermon);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.white100.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: AppTheme.white100.withOpacity(0.2),
          ),
        ),
        child: TextField(
          controller: _searchController,
          style: GoogleFonts.inter(
            color: AppTheme.white100,
            fontSize: AppTheme.fontSize16,
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'Rechercher une prédication...',
            hintStyle: GoogleFonts.inter(
              color: AppTheme.white100.withOpacity(0.5),
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: AppTheme.white100.withOpacity(0.7),
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                    icon: Icon(
                      Icons.clear_rounded,
                      color: AppTheme.white100.withOpacity(0.7),
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSermonListItem(BranhamSermon sermon) {
    final isCurrentSermon = _currentSermon?.id == sermon.id;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isCurrentSermon 
            ? AppTheme.primaryColor.withOpacity(0.2)
            : AppTheme.white100.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: isCurrentSermon 
              ? AppTheme.primaryColor.withOpacity(0.5)
              : Colors.transparent,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          onTap: () {
            _selectSermon(sermon);
            Navigator.pop(context);
            if (!_isPlaying) {
              _togglePlayPause();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            child: Row(
              children: [
                // Icône de lecture
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isCurrentSermon 
                        ? AppTheme.primaryColor 
                        : AppTheme.white100.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCurrentSermon && _isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: AppTheme.white100,
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: AppTheme.spaceMedium),
                
                // Informations
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sermon.title,
                        style: GoogleFonts.poppins(
                          fontSize: AppTheme.fontSize16,
                          fontWeight: AppTheme.fontSemiBold,
                          color: AppTheme.white100,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppTheme.spaceXSmall),
                      Text(
                        sermon.date,
                        style: GoogleFonts.inter(
                          fontSize: AppTheme.fontSize14,
                          color: AppTheme.white100.withOpacity(0.7),
                        ),
                      ),
                      if (sermon.location.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          sermon.location,
                          style: GoogleFonts.inter(
                            fontSize: AppTheme.fontSize12,
                            color: AppTheme.white100.withOpacity(0.5),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Durée
                if (sermon.duration != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.white100.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Text(
                      _formatDuration(sermon.duration!),
                      style: GoogleFonts.inter(
                        fontSize: AppTheme.fontSize12,
                        color: AppTheme.white100.withOpacity(0.7),
                        fontWeight: AppTheme.fontMedium,
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

  // Méthodes utilitaires
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    } else {
      return '${minutes}:${seconds.toString().padLeft(2, '0')}';
    }
  }




  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.redStandard,
      ),
    );
  }
}
