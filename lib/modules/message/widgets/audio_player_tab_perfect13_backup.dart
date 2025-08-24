import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/branham_sermon_model.dart';
import '../services/admin_branham_sermon_service.dart';
import '../services/branham_audio_player_service.dart';
import 'dart:async';
import 'dart:math' as math;

// Primary color for the app theme
const Color _primaryColor = Color(0xFF6B73FF);

// Classe pour les particules animées
class Particle {
  double x;
  double y;
  double size;
  double opacity;
  double speed;
  Color color;
  
  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.speed,
    required this.color,
  });
}

/// Lecteur audio Branham style Perfect 13
class AudioPlayerTabPerfect13 extends StatefulWidget {
  const AudioPlayerTabPerfect13({super.key});

  @override
  State<AudioPlayerTabPerfect13> createState() => _AudioPlayerTabPerfect13State();
}

class _AudioPlayerTabPerfect13State extends State<AudioPlayerTabPerfect13> 
    with TickerProviderStateMixin {
  final BranhamAudioPlayerService _audioPlayer = BranhamAudioPlayerService();
  
  List<BranhamSermon> _allSermons = [];
  BranhamSermon? _currentSermon;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isPlaying = false;
  bool _isLoading = true;
  
  // Filtres et recherche
  String _searchQuery = '';
  int? _selectedYear;
  final TextEditingController _searchController = TextEditingController();

  // Variables pour les contrôles avancés
  double _playbackSpeed = 1.0;
  bool _isLoopEnabled = false;
  bool _isShuffleEnabled = false;
  double _volume = 1.0;
  bool _showEqualizer = false;
  int _sleepTimerMinutes = 0;
  Timer? _sleepTimer;
  Timer? _speedDebounceTimer;

  // Animation controllers pour l'arrière-plan professionnel
  late AnimationController _backgroundController;
  late AnimationController _particleController;
  late AnimationController _pulseController;
  late AnimationController _titleScrollController;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _titleScrollAnimation;
  
  // Variables pour les particules animées
  List<Particle> _particles = [];
  Timer? _particleTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupAudioListeners();
    _loadSermons();
    _createParticles();
  }
  
  void _initializeAnimations() {
    // Contrôleur pour l'arrière-plan gradient animé
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this);
    
    // Contrôleur pour les particules
    _particleController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this);
    
    // Contrôleur pour l'effet de pulsation
    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this);
    
    // Contrôleur pour le défilement du titre
    _titleScrollController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this);
    
    // Animations
    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut));
    
    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0).animate(CurvedAnimation(
      parent: _particleController,
      curve: Curves.linear));
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut));
    
    _titleScrollAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0).animate(CurvedAnimation(
      parent: _titleScrollController,
      curve: Curves.linear));
    
    // Démarrer les animations
    _backgroundController.repeat();
    _particleController.repeat();
    _pulseController.repeat(reverse: true);
    _titleScrollController.repeat();
    
    // Timer pour mettre à jour les particules
    _particleTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      _updateParticles();
    });
  }
  
  void _createParticles() {
    _particles.clear();
    final random = math.Random();
    
    for (int i = 0; i < 25; i++) {
      _particles.add(Particle(
        x: random.nextDouble() * 400,
        y: random.nextDouble() * 800,
        size: random.nextDouble() * 3 + 1,
        opacity: random.nextDouble() * 0.6 + 0.1,
        speed: random.nextDouble() * 2 + 0.5,
        color: _primaryColor.withOpacity(random.nextDouble() * 0.3 + 0.1)));
    }
  }
  
  void _updateParticles() {
    if (mounted) {
      setState(() {
        for (var particle in _particles) {
          particle.y -= particle.speed;
          
          // Reset particle when it goes off screen
          if (particle.y < -10) {
            particle.y = 810;
            particle.x = math.Random().nextDouble() * 400;
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    
    // Dispose des animations
    _backgroundController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    _titleScrollController.dispose();
    _particleTimer?.cancel();
    
    super.dispose();
  }

  void _setupAudioListeners() {
    _audioPlayer.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    });

    _audioPlayer.durationStream.listen((duration) {
      if (mounted) {
        setState(() {
          _totalDuration = duration ?? Duration.zero;
        });
      }
    });

    _audioPlayer.playingStream.listen((isPlaying) {
      if (mounted) {
        setState(() {
          _isPlaying = isPlaying;
        });
      }
    });
  }

  Future<void> _loadSermons() async {
    try {
      setState(() => _isLoading = true);
      
      var sermons = await AdminBranhamSermonService.getActiveSermons();
      
      if (sermons.isEmpty) {
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
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<List<BranhamSermon>> _loadDemoSermons() async {
    return [
      BranhamSermon(
        id: 'demo_1',
        title: 'La communion par la rédemption',
        date: '2023-12-25',
        location: 'Jeffersonville, IN',
        audioStreamUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
        createdAt: DateTime.now()),
      BranhamSermon(
        id: 'demo_2',
        title: 'Le message de l\'heure',
        date: '2023-11-15',
        location: 'Branham Tabernacle',
        audioStreamUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
        createdAt: DateTime.now()),
    ];
  }

  List<BranhamSermon> get _filteredSermons {
    var filtered = _allSermons.toList();
    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((sermon) =>
        sermon.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        sermon.location.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    if (_selectedYear != null) {
      filtered = filtered.where((sermon) =>
        DateTime.tryParse(sermon.date)?.year == _selectedYear
      ).toList();
    }
    
    return filtered;
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  void _togglePlayPause() {
    if (_currentSermon == null) {
      _showSermonsBottomSheet();
      return;
    }
    
    if (_isPlaying) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.resume();
    }
  }

  void _nextSermon() {
    if (_allSermons.isEmpty) return;
    
    final currentIndex = _allSermons.indexWhere((s) => s.id == _currentSermon?.id);
    if (currentIndex != -1 && currentIndex < _allSermons.length - 1) {
      _selectSermon(_allSermons[currentIndex + 1]);
    } else if (_allSermons.isNotEmpty) {
      _selectSermon(_allSermons.first);
    }
  }

  void _previousSermon() {
    if (_allSermons.isEmpty) return;
    
    final currentIndex = _allSermons.indexWhere((s) => s.id == _currentSermon?.id);
    if (currentIndex > 0) {
      _selectSermon(_allSermons[currentIndex - 1]);
    } else if (_allSermons.isNotEmpty) {
      _selectSermon(_allSermons.last);
    }
  }

  void _selectSermon(BranhamSermon sermon) {
    setState(() {
      _currentSermon = sermon;
    });
    
    // Vérifier si on a une URL audio valide
    final url = sermon.audioStreamUrl ?? sermon.audioDownloadUrl;
    if (url == null || url.isEmpty) {
      _showMessage('Aucune URL audio disponible pour cette prédication');
      return;
    }
    
    _audioPlayer.playSermon(sermon).catchError((error) {
      _showMessage('Erreur lors de la lecture: $error');
    });
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          backgroundColor: _primaryColor));
    }
  }

  void _showSermonsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildSermonsBottomSheet());
  }

  // Méthodes pour les contrôles avancés
  void _showAdvancedControls() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => _buildAdvancedControlsSheet(setModalState)));
  }

  Future<void> _setPlaybackSpeed(double speed, [StateSetter? setModalState]) async {
    setState(() {
      _playbackSpeed = speed;
    });
    setModalState?.call(() {}); // Mise à jour immédiate du modal
    _showMessage('Vitesse: ${speed}x');
  }

  void _toggleLoop([StateSetter? setModalState]) {
    setState(() {
      _isLoopEnabled = !_isLoopEnabled;
    });
    setModalState?.call(() {}); // Mise à jour immédiate du modal
    _showMessage(_isLoopEnabled ? 'Lecture en boucle activée' : 'Lecture en boucle désactivée');
  }

  void _toggleShuffle([StateSetter? setModalState]) {
    setState(() {
      _isShuffleEnabled = !_isShuffleEnabled;
    });
    setModalState?.call(() {}); // Mise à jour immédiate du modal
    _showMessage(_isShuffleEnabled ? 'Lecture aléatoire activée' : 'Lecture aléatoire désactivée');
  }

  Future<void> _setVolume(double volume, [StateSetter? setModalState]) async {
    setState(() {
      _volume = volume;
    });
    setModalState?.call(() {}); // Mise à jour immédiate du modal
    _showMessage('Volume: ${(volume * 100).round()}%');
  }

  void _toggleEqualizer([StateSetter? setModalState]) {
    setState(() {
      _showEqualizer = !_showEqualizer;
    });
    setModalState?.call(() {}); // Mise à jour immédiate du modal
  }

  void _setSleepTimer(int minutes, [StateSetter? setModalState]) {
    setState(() {
      _sleepTimerMinutes = minutes;
    });
    setModalState?.call(() {}); // Mise à jour immédiate du modal
    
    // Annuler le timer précédent
    _sleepTimer?.cancel();
    
    if (minutes > 0) {
      _sleepTimer = Timer(Duration(minutes: minutes), () {
        _audioPlayer.pause();
        _showMessage('Minuterie de sommeil activée - Lecture mise en pause');
        setState(() {
          _sleepTimerMinutes = 0;
        });
      });
      _showMessage('Minuterie de sommeil: ${minutes}min');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1E1E2E),
              const Color(0xFF2A1B3D),
              const Color(0xFF44318D).withOpacity(0.7),
            ])),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_primaryColor))));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBuilder(
        animation: Listenable.merge([_backgroundAnimation, _particleAnimation]),
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(
                    const Color(0xFF1E1E2E),
                    const Color(0xFF2A1B3D),
                    _backgroundAnimation.value)!,
                  Color.lerp(
                    const Color(0xFF2A1B3D),
                    const Color(0xFF44318D),
                    _backgroundAnimation.value * 0.7)!,
                  Color.lerp(
                    const Color(0xFF1E1E2E),
                    const Color(0xFF6B73FF).withOpacity(0.1),
                    _backgroundAnimation.value * 0.3)!,
                ],
                stops: const [0.0, 0.5, 1.0])),
            child: Stack(
              children: [
                // Particules animées en arrière-plan
                ..._buildAnimatedParticles(),
                
                // Effet de pulsation pour la musique
                if (_isPlaying)
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment.center,
                              radius: _pulseAnimation.value * 0.8,
                              colors: [
                                _primaryColor.withOpacity(0.05 * _pulseAnimation.value),
                                Colors.transparent,
                              ]))));
                    }),
                
                // Interface principale
                SafeArea(
                  child: Column(
                    children: [
                      // Header simple avec bouton liste
                      _buildSimpleHeader(),
                      
                      // Player central avec espacement adaptatif
                      Expanded(
                        child: SingleChildScrollView(
                          child: _buildSimplePlayer())),
                      
                      // Controls en bas
                      _buildSimpleControls(),
                      
                      const SizedBox(height: 20),
                    ])),
              ]));
        }));
  }
  
  List<Widget> _buildAnimatedParticles() {
    return _particles.map((particle) {
      return Positioned(
        left: particle.x,
        top: particle.y,
        child: Container(
          width: particle.size,
          height: particle.size,
          decoration: BoxDecoration(
            color: particle.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: particle.color.withOpacity(0.5),
                blurRadius: particle.size * 2,
                spreadRadius: particle.size * 0.5),
            ])));
    }).toList();
  }

  // Header simple avec titre centré défilant
  Widget _buildSimpleHeader() {
    const String mainTitle = 'Mais qu\'aux jours de la voix du septième ange';
    const String fallbackTitle = 'William Marrion Branham';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      height: 60,
      child: Row(
        children: [
          // Titre défilant au centre
          Expanded(
            child: AnimatedBuilder(
              animation: _titleScrollAnimation,
              builder: (context, child) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    // Calculer la largeur du texte principal
                    final textPainter = TextPainter(
                      text: TextSpan(
                        text: mainTitle,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                      textDirection: TextDirection.ltr);
                    textPainter.layout();
                    
                    final textWidth = textPainter.size.width;
                    final containerWidth = constraints.maxWidth;
                    
                    // Si le texte tient dans le conteneur, pas besoin de défiler
                    if (textWidth <= containerWidth) {
                      return Center(
                        child: Text(
                          mainTitle,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center));
                    }
                    
                    // Phase de défilement
                    if (_titleScrollAnimation.value <= 0.05 || _titleScrollAnimation.value >= 0.95) {
                      return Center(
                        child: Text(
                          fallbackTitle,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center));
                    }
                    
                    final scrollProgress = (_titleScrollAnimation.value - 0.05) / 0.9;
                    final totalScrollDistance = textWidth + containerWidth;
                    final scrollPosition = scrollProgress * totalScrollDistance - containerWidth;
                    
                    return ClipRect(
                      child: OverflowBox(
                        maxWidth: textWidth,
                        child: Transform.translate(
                          offset: Offset(-scrollPosition, 0),
                          child: Text(
                            mainTitle,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.visible))));
                  });
              })),
          
          // Bouton playlist
          IconButton(
            onPressed: _showSermonsBottomSheet,
            icon: const Icon(Icons.playlist_play, color: Colors.white, size: 28),
            tooltip: 'Liste des prédications'),
        ]));
  }

  // Player central simple et efficace
  Widget _buildSimplePlayer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Artwork avec photo de Branham et effets visuels
          AnimatedBuilder(
            animation: Listenable.merge([_pulseAnimation, _backgroundAnimation]),
            builder: (context, child) {
              return SizedBox(
                width: 220,
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Cercles pulsants en arrière-plan
                    if (_isPlaying) ...[
                      Container(
                        width: 220 * _pulseAnimation.value,
                        height: 220 * _pulseAnimation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _primaryColor.withOpacity(0.3 / _pulseAnimation.value),
                            width: 2))),
                      Container(
                        width: 240 * _pulseAnimation.value,
                        height: 240 * _pulseAnimation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _primaryColor.withOpacity(0.2 / _pulseAnimation.value),
                            width: 1))),
                      Container(
                        width: 260 * _pulseAnimation.value,
                        height: 260 * _pulseAnimation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _primaryColor.withOpacity(0.1 / _pulseAnimation.value),
                            width: 0.5))),
                    ],
                    
                    // Image principale avec effets
                    Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryColor.withOpacity(_isPlaying ? 0.4 : 0.3),
                            blurRadius: _isPlaying ? 25 : 20,
                            spreadRadius: _isPlaying ? 8 : 5),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 10)),
                        ]),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          children: [
                            // Image de base
                            Container(
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage('assets/branham.jpg'),
                                  fit: BoxFit.cover))),
                            
                            // Overlay gradient animé
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    _primaryColor.withOpacity(0.1 * _backgroundAnimation.value),
                                    Colors.transparent,
                                    _primaryColor.withOpacity(0.05 * _backgroundAnimation.value),
                                  ]))),
                            
                            // Effet de brillance si en lecture
                            if (_isPlaying)
                              Positioned(
                                top: -50,
                                left: -50 + (100 * _backgroundAnimation.value),
                                child: Transform.rotate(
                                  angle: math.pi / 4,
                                  child: Container(
                                    width: 100,
                                    height: 400,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          Colors.white.withOpacity(0.1),
                                          Colors.transparent,
                                        ]))))),
                          ]))),
                  ]));
            }),
          
          const SizedBox(height: 18),
          
          // Informations de la prédication avec espacement réduit
          if (_currentSermon != null) ...[
            Container(
              constraints: const BoxConstraints(minHeight: 40),
              child: Text(
                _currentSermon!.title,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  height: 1.1),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis)),
            
            const SizedBox(height: 4),
            
            // Informations date et lieu avec wrapping amélioré
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 4,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: Colors.white.withOpacity(0.7),
                      size: 14),
                    const SizedBox(width: 6),
                    Text(
                      _currentSermon!.date,
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13)),
                  ]),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on,
                      color: Colors.white.withOpacity(0.7),
                      size: 14),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _currentSermon!.location,
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 13),
                        overflow: TextOverflow.ellipsis)),
                  ]),
              ]),
          ] else ...[
            Container(
              constraints: const BoxConstraints(minHeight: 50),
              child: Text(
                'Aucune prédication sélectionnée',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16),
                textAlign: TextAlign.center)),
            
            const SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: _showSermonsBottomSheet,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25))),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.playlist_play, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Choisir une prédication',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
                ])),
          ],
        ]));
  }

  // Controls simples en bas avec animations
  Widget _buildSimpleControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.1),
          ])),
      child: Column(
        children: [
          // Barre de progression avec effet lumineux
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Text(
                  _formatDuration(_currentPosition),
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: _primaryColor,
                        inactiveTrackColor: Colors.white.withOpacity(0.2),
                        thumbColor: _primaryColor,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                        overlayColor: _primaryColor.withOpacity(0.2),
                        trackHeight: 4),
                      child: Slider(
                        value: _totalDuration.inMilliseconds > 0
                            ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds
                            : 0.0,
                        onChanged: (value) {
                          if (_totalDuration.inMilliseconds > 0) {
                            final position = Duration(
                              milliseconds: (value * _totalDuration.inMilliseconds).round());
                            _audioPlayer.seek(position);
                          }
                        })))),
                Text(
                  _formatDuration(_totalDuration),
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
              ])),
          
          const SizedBox(height: 20),
          
          // Boutons de contrôle principal avec animations
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Bouton précédent
                  _buildControlButton(
                    Icons.skip_previous,
                    onPressed: _previousSermon,
                    size: 40),
                  
                  // Bouton rewind
                  _buildControlButton(
                    Icons.replay_10,
                    onPressed: () => _audioPlayer.seek(_currentPosition - const Duration(seconds: 10)),
                    size: 35),
                  
                  // Bouton play/pause principal
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _primaryColor,
                          _primaryColor.withOpacity(0.8),
                        ]),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryColor.withOpacity(0.5),
                          blurRadius: _isPlaying ? 20 : 15,
                          spreadRadius: _isPlaying ? 5 : 2),
                      ]),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(40),
                        onTap: _togglePlayPause,
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              key: ValueKey(_isPlaying),
                              color: Colors.white,
                              size: 36)))))),
                  
                  // Bouton forward
                  _buildControlButton(
                    Icons.forward_30,
                    onPressed: () => _audioPlayer.seek(_currentPosition + const Duration(seconds: 30)),
                    size: 35),
                  
                  // Bouton suivant
                  _buildControlButton(
                    Icons.skip_next,
                    onPressed: _nextSermon,
                    size: 40),
                  
                  const SizedBox(width: 8),
                  
                  // Bouton contrôles avancés
                  _buildControlButton(
                    Icons.tune,
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => StatefulBuilder(
                          builder: (context, setModalState) {
                            return _buildAdvancedControlsSheet(setModalState);
                          }));
                    },
                    size: 35),
                ],
              );
            }),
        ]));
  }

  Widget _buildControlButton(IconData icon, {required VoidCallback onPressed, double size = 24}) {
    return Container(
      width: size + 10,
      height: size + 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.1)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular((size + 10) / 2),
          onTap: onPressed,
          child: Center(
            child: Icon(
              icon,
              color: Colors.white.withOpacity(0.8),
              size: size * 0.6)))));
  }

  Widget _buildSermonsBottomSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(
        children: [
          // Header du bottom sheet
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                Text(
                  'Prédications Audio',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                // Barre de recherche
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Rechercher...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.5)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1)),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  }),
              ])),
          
          // Liste des prédications
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredSermons.length,
              itemBuilder: (context, index) {
                final sermon = _filteredSermons[index];
                final isSelected = _currentSermon?.id == sermon.id;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? _primaryColor.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected ? Border.all(color: _primaryColor, width: 1) : null),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8)),
                      child: Icon(
                        isSelected && _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: _primaryColor,
                        size: 24)),
                    title: Text(
                      sermon.title,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, color: Colors.white.withOpacity(0.5), size: 12),
                            const SizedBox(width: 4),
                            Text(
                              sermon.date,
                              style: GoogleFonts.inter(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12)),
                          ]),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.white.withOpacity(0.5), size: 12),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                sermon.location,
                                style: GoogleFonts.inter(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12),
                                overflow: TextOverflow.ellipsis)),
                          ]),
                      ]),
                    onTap: () {
                      _selectSermon(sermon);
                      Navigator.pop(context);
                    }));
              })),
        ]));
  }

  Widget _buildAdvancedControlsSheet(StateSetter setModalState) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(
        children: [
          // Header du bottom sheet
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                Text(
                  'Contrôles Avancés',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
              ]),
          
          // Contrôles
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vitesse de lecture
                  Text(
                    'Vitesse de lecture',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        '0.5x',
                        style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                      Expanded(
                        child: Slider(
                          value: _playbackSpeed,
                          min: 0.5,
                          max: 2.0,
                          divisions: 6,
                          activeColor: _primaryColor,
                          inactiveColor: Colors.white.withOpacity(0.2),
                          onChanged: (value) {
                            setModalState(() {
                              _playbackSpeed = value;
                            });
                            _setPlaybackSpeed(value, setModalState);
                          })),
                      Text(
                        '2.0x',
                        style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                    ]),
                  Center(
                    child: Text(
                      '${_playbackSpeed}x',
                      style: GoogleFonts.inter(
                        color: _primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600))),
                  
                  const SizedBox(height: 24),
                  
                  // Volume
                  Text(
                    'Volume',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.volume_down, color: Colors.white70, size: 20),
                      Expanded(
                        child: Slider(
                          value: _volume,
                          min: 0.0,
                          max: 1.0,
                          activeColor: _primaryColor,
                          inactiveColor: Colors.white.withOpacity(0.2),
                          onChanged: (value) {
                            setModalState(() {
                              _volume = value;
                            });
                            _setVolume(value, setModalState);
                          })),
                      Icon(Icons.volume_up, color: Colors.white70, size: 20),
                    ]),
                  Center(
                    child: Text(
                      '${(_volume * 100).round()}%',
                      style: GoogleFonts.inter(
                        color: _primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600))),
                  
                  const SizedBox(height: 24),
                  
                  // Options de lecture
                  Text(
                    'Options de lecture',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  
                  // Lecture en boucle
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: Icon(
                        Icons.repeat,
                        color: _isLoopEnabled ? _primaryColor : Colors.white70),
                      title: Text(
                        'Lecture en boucle',
                        style: GoogleFonts.inter(color: Colors.white)),
                      trailing: Switch(
                        value: _isLoopEnabled,
                        activeColor: _primaryColor,
                        onChanged: (value) {
                          _toggleLoop(setModalState);
                        }))),
                  
                  const SizedBox(height: 8),
                  
                  // Lecture aléatoire
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: Icon(
                        Icons.shuffle,
                        color: _isShuffleEnabled ? _primaryColor : Colors.white70),
                      title: Text(
                        'Lecture aléatoire',
                        style: GoogleFonts.inter(color: Colors.white)),
                      trailing: Switch(
                        value: _isShuffleEnabled,
                        activeColor: _primaryColor,
                        onChanged: (value) {
                          _toggleShuffle(setModalState);
                        }))),
                  
                  const SizedBox(height: 24),
                  
                  // Minuterie de sommeil
                  Text(
                    'Minuterie de sommeil',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [0, 15, 30, 45, 60, 90].map((minutes) {
                      final isSelected = _sleepTimerMinutes == minutes;
                      return InkWell(
                        onTap: () {
                          _setSleepTimer(minutes, setModalState);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? _primaryColor : Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20)),
                          child: Text(
                            minutes == 0 ? 'Off' : '${minutes}min',
                            style: GoogleFonts.inter(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal))));
                    }).toList()),
                ])),
        ]));
  }
}
