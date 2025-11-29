import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'dart:io';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme.dart';
import 'visit_us_page.dart';
import '../models/home_config_model.dart';
import '../services/home_config_service.dart';
import '../widgets/latest_sermon_widget.dart';
import 'donations_page.dart';
import '../modules/pain_quotidien/widgets/daily_bread_preview_widget.dart';
import '../models/event_model.dart';
import '../services/events_firebase_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../services/contact_service.dart'; // Nouveau service pour les messages de contact
import 'member_events_page.dart';
import 'member_event_detail_page.dart';
import 'member_prayer_wall_page.dart';
import '../widgets/event_calendar_view.dart';

class MemberDashboardPage extends StatefulWidget {
  const MemberDashboardPage({super.key});

  @override
  State<MemberDashboardPage> createState() => _MemberDashboardPageState();
}

class _MemberDashboardPageState extends State<MemberDashboardPage> with TickerProviderStateMixin {
  void _openChurchCalendar() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text("Calendrier de l'église"),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          body: StreamBuilder<List<EventModel>>(
            stream: EventsFirebaseService.getEventsStream(limit: 200),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final events = snapshot.data ?? [];
              return EventCalendarView(
                events: events,
                onEventTap: (event) {},
                onEventLongPress: (event) {},
                isSelectionMode: false,
                selectedEvents: const [],
                onSelectionChanged: (event, selected) {},
              );
            },
          ),
        ),
      ),
    );
  }
  late AnimationController _animationController;
  late AnimationController _liveAnimationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _liveAnimation;
  Timer? _countdownTimer;
  
  // Variables pour le carrousel d'images
  late PageController _pageController;
  Timer? _carouselTimer;
  int _currentImageIndex = 0;
  late ValueNotifier<int> _currentImageNotifier;
  bool _isUserInteracting = false;
  bool _carouselTimerStarted = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _liveAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pageController = PageController();
    _currentImageNotifier = ValueNotifier<int>(0);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _liveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _liveAnimationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
    _liveAnimationController.repeat(reverse: true);
    
    // Démarrer le timer pour le compte à rebours
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _liveAnimationController.dispose();
    _countdownTimer?.cancel();
    _carouselTimer?.cancel();
    _pageController.dispose();
    _currentImageNotifier.dispose();
    super.dispose();
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Le rebuild sera géré par les StreamBuilders individuels, pas globalement
      // Removed setState to prevent unnecessary rebuilds
    });
  }

  void _startCarouselTimer(List<String> imageUrls) {
    if (_carouselTimerStarted || _isUserInteracting || imageUrls.length <= 1) return;
    
    _carouselTimerStarted = true;
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted || _isUserInteracting) {
        timer.cancel();
        _carouselTimerStarted = false;
        return;
      }
      
      final nextIndex = (_currentImageIndex + 1) % imageUrls.length;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: StreamBuilder<HomeConfigModel>(
        stream: HomeConfigService.getHomeConfigStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: AppTheme.spaceMedium),
                  Text(
                    'Chargement...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erreur lors du chargement de la configuration',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            );
          }

          final config = snapshot.data ?? HomeConfigModel.defaultConfig;

          // Démarrer le carrousel après le build si il y a plusieurs images
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (config.coverImageUrls.isNotEmpty && !_carouselTimerStarted) {
              _startCarouselTimer(config.coverImageUrls);
            }
          });

          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(), // Empêche l'effet de bounce au-dessus
            child: Column(
              children: [
                // Image de couverture qui scrolle avec le contenu
                _buildStaticCoverImage(config),

                // Pain quotidien (si activé)
                if (config.isDailyBreadActive)
                  SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 32, bottom: 32),
                      child: const DailyBreadPreviewWidget(),
                    ),
                  ),

                // Contenu principal
                SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 0.0, left: 20.0, right: 20.0, bottom: 20.0),
                    child: Column(
                            children: [
                              // Section Live (si activée)
                              if (config.isLiveActive)
                                _buildNextLiveSection(config),
                              if (config.isLiveActive)
                                const SizedBox(height: AppTheme.spaceXLarge),
                              
                              // Actions rapides (si activées)
                              if (config.areQuickActionsActive)
                                _buildQuickActionsSection(config),
                              if (config.areQuickActionsActive)
                                const SizedBox(height: AppTheme.spaceXLarge),
                              
                              // Dernières prédications (si activées)
                              if (config.isLastSermonActive)
                                LatestSermonWidget(key: ValueKey('latest_sermon_${config.sermonYouTubeUrl}')),
                              if (config.isLastSermonActive)
                                const SizedBox(height: AppTheme.spaceXLarge),
                              
                              // Événements à venir (si activés)
                              if (config.areEventsActive)
                                _buildUpcomingEventsSection(config),
                              if (config.areEventsActive)
                                const SizedBox(height: AppTheme.spaceXLarge),
                              
                              // Nous contacter (si activé)
                              if (config.isContactActive)
                                _buildContactUsSection(config),
                              if (config.isContactActive)
                                const SizedBox(height: AppTheme.spaceXLarge),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStaticCoverImage(HomeConfigModel config) {
    return Container(
      height: 230,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Media de couverture (carrousel ou image unique)
          _buildCoverMedia(config),
          
          // Overlay dégradé
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.black100.withOpacity(0.1),
                  AppTheme.black100.withOpacity(0.3),
                  AppTheme.black100.withOpacity(0.6),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverMedia(HomeConfigModel config) {
    // Priorité à la vidéo si useVideo est activé et coverVideoUrl est défini
    if (config.useVideo && config.coverVideoUrl != null && config.coverVideoUrl!.isNotEmpty) {
      return _buildCoverVideo(config.coverVideoUrl!);
    }
    
    // Gestion du carrousel d'images
    if (config.coverImageUrls.isNotEmpty) {
      return Stack(
        children: [
          GestureDetector(
            onPanStart: (_) {
              // L'utilisateur commence à faire défiler manuellement
              _isUserInteracting = true;
              _carouselTimer?.cancel();
              _carouselTimerStarted = false;
            },
            onPanEnd: (_) {
              // L'utilisateur a fini de faire défiler
              Timer(const Duration(seconds: 3), () {
                if (mounted) {
                  _isUserInteracting = false;
                  _startCarouselTimer(config.coverImageUrls);
                }
              });
            },
            onTap: () {
              _isUserInteracting = true;
              _carouselTimer?.cancel();
              _carouselTimerStarted = false;
              
              // Relancer le timer après 5 secondes d'inactivité
              Timer(const Duration(seconds: 5), () {
                if (mounted) {
                  _isUserInteracting = false;
                  _startCarouselTimer(config.coverImageUrls);
                }
              });
            },
            child: PageView.builder(
              controller: _pageController,
              itemCount: config.coverImageUrls.length,
              scrollDirection: Axis.horizontal,
              pageSnapping: true,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (index) {
                if (mounted) {
                  _currentImageIndex = index;
                  _currentImageNotifier.value = index;
                }
              },
              itemBuilder: (context, index) {
                return CachedNetworkImage(
                  imageUrl: config.coverImageUrls[index],
                  fit: BoxFit.cover,
                  fadeInDuration: const Duration(milliseconds: 300),
                  fadeOutDuration: const Duration(milliseconds: 100),
                  placeholder: (context, url) => Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => _buildDefaultCoverBackground(),
                );
              },
            ),
          ),
          // Indicateurs de pagination (dots)
          if (config.coverImageUrls.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: ValueListenableBuilder<int>(
                valueListenable: _currentImageNotifier,
                builder: (context, currentIndex, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      config.coverImageUrls.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: currentIndex == index
                              ? AppTheme.white100
                              : AppTheme.white100.withOpacity(0.4),
                          border: currentIndex == index
                              ? Border.all(color: AppTheme.white100, width: 1)
                              : null,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      );
    }
    
    // Image unique si coverImageUrl est défini
    if (config.coverImageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: config.coverImageUrl,
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 300),
        fadeOutDuration: const Duration(milliseconds: 100),
        placeholder: (context, url) => Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              strokeWidth: 2,
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildDefaultCoverBackground(),
      );
    }
    
    // Background par défaut
    return _buildDefaultCoverBackground();
  }

  Widget _buildCoverVideo(String videoUrl) {
    // Support pour les URLs YouTube
    final videoId = YoutubePlayer.convertUrlToId(videoUrl);
    if (videoId != null) {
      return YoutubePlayer(
        controller: YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: true,           // Lecture automatique
            mute: true,              // Son coupé pour éviter le bruit automatique
            enableCaption: false,    // Pas de sous-titres pour un affichage plus propre
            showLiveFullscreenButton: false, // Pas de plein écran pour garder l'effet diaporama
            hideControls: true,      // Masquer les contrôles pour un effet diaporama
            loop: true,              // Lecture en boucle
            forceHD: false,          // Pas forcer HD pour éviter les problèmes de chargement
            disableDragSeek: true,   // Désactiver le seek pour un comportement de diaporama
          ),
        ),
        showVideoProgressIndicator: true,
        progressIndicatorColor: AppTheme.primaryColor,
        progressColors: ProgressBarColors(
          playedColor: AppTheme.primaryColor,
          handleColor: AppTheme.primaryColor,
        ),
      );
    }
    
    // Pour les autres URLs vidéo (fichiers uploadés), créer un lecteur attrayant
    return _buildUploadedVideoPlayer(videoUrl);
  }

  Widget _buildUploadedVideoPlayer(String videoUrl) {
    return SizedBox(
      height: 250,
      child: AutoplayVideoPlayer(
        videoUrl: videoUrl,
      ),
    );
  }

  Widget _buildDefaultCoverBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
            Theme.of(context).colorScheme.secondary,
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
      ),
    );
  }

  Widget _buildNextLiveSection(HomeConfigModel config) {
    // Utiliser la configuration ou calculer le prochain dimanche
    final now = DateTime.now();
    final liveDateTime = config.liveDateTime ?? _getDefaultNextSundayDateTime();
    final duration = liveDateTime.difference(now);
    
    // Si c'est dans moins de 2 heures après le live, ne pas afficher
    if (duration.inHours < -2) {
      return const SizedBox.shrink();
    }
    
    final isLive = config.isLiveNow || (duration.inMinutes <= 0 && duration.inMinutes > -120);
    final isUpcoming = config.isLiveUpcoming || duration.inMinutes > 0;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLive
              ? [
                  const Color(0xFFFF5722),
                  const Color(0xFFE64A19),
                  const Color(0xFFD84315),
                ]
              : isUpcoming
                  ? [
                      const Color(0xFF2196F3),
                      const Color(0xFF1976D2),
                      const Color(0xFF1565C0),
                    ]
                  : [
                      const Color(0xFF607D8B),
                      const Color(0xFF546E7A),
                      const Color(0xFF455A64),
                    ],
        ),
        borderRadius: BorderRadius.zero,
        boxShadow: [
          BoxShadow(
            color: (isLive ? AppTheme.warningColor : isUpcoming ? AppTheme.blueStandard : AppTheme.grey500)
                .withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildLiveHeader(isLive, isUpcoming, duration, config),
          const SizedBox(height: AppTheme.spaceMedium),
          _buildLiveActionButtons(isLive, isUpcoming, config),
        ],
      ),
    );
  }

  DateTime _getDefaultNextSundayDateTime() {
    final now = DateTime.now();
    final daysUntilSunday = (7 - now.weekday) % 7;
    final nextSunday = daysUntilSunday == 0 && now.hour >= 12
        ? now.add(const Duration(days: 7))
        : now.add(Duration(days: daysUntilSunday == 0 ? 7 : daysUntilSunday));
    return DateTime(nextSunday.year, nextSunday.month, nextSunday.day, 10, 0);
  }

  Widget _buildLiveHeader(bool isLive, bool isUpcoming, Duration duration, HomeConfigModel config) {
    String statusText;
    
    if (isLive) {
      statusText = 'EN DIRECT MAINTENANT';
    } else if (isUpcoming) {
      statusText = config.liveDescription ?? 'Prochain culte dans';
    } else {
      statusText = 'Culte terminé';
    }
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLive) ...[
              AnimatedBuilder(
                animation: _liveAnimation,
                builder: (context, child) {
                  return Container(
                    width: 8 + (_liveAnimation.value * 4),
                    height: 8 + (_liveAnimation.value * 4),
                    decoration: BoxDecoration(
                      color: AppTheme.redStandard,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.redStandard.withOpacity(_liveAnimation.value * 0.8),
                          blurRadius: 8,
                          spreadRadius: _liveAnimation.value * 3,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: AppTheme.space12),
            ],
            Flexible(
              child: Text(
                statusText,
                style: const TextStyle(
                  color: AppTheme.white100,
                  fontSize: AppTheme.fontSize18,
                  fontWeight: AppTheme.fontBold,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        
        if (isUpcoming) ...[
          const SizedBox(height: AppTheme.spaceMedium),
          _buildElegantCountdown(duration),
        ],
      ],
    );
  }

  Widget _buildElegantCountdown(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.white100.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: AppTheme.white100.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black100.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (days > 0) ...[
              _buildTimeBlock(days.toString().padLeft(2, '0'), 'JOURS'),
              _buildTimeSeparator(),
            ],
            _buildTimeBlock(hours.toString().padLeft(2, '0'), 'H'),
            _buildTimeSeparator(),
            _buildTimeBlock(minutes.toString().padLeft(2, '0'), 'MIN'),
            _buildTimeSeparator(),
            _buildTimeBlock(seconds.toString().padLeft(2, '0'), 'SEC'),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeBlock(String value, String unit) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.white100.withOpacity(0.2),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            border: Border.all(
              color: AppTheme.white100.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: AppTheme.white100,
              fontSize: AppTheme.fontSize24,
              fontWeight: AppTheme.fontBold,
              fontFamily: 'monospace',
              letterSpacing: 1.0,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spaceXSmall),
        Text(
          unit,
          style: TextStyle(
            color: AppTheme.white100.withOpacity(0.9),
            fontSize: AppTheme.fontSize11,
            fontWeight: AppTheme.fontSemiBold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSeparator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        ':',
        style: TextStyle(
          color: AppTheme.white100.withOpacity(0.7),
          fontSize: AppTheme.fontSize20,
          fontWeight: AppTheme.fontBold,
        ),
      ),
    );
  }

  Widget _buildLiveActionButtons(bool isLive, bool isUpcoming, HomeConfigModel config) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showChurchInfo(),
            icon: const Icon(Icons.location_on_outlined),
            label: const Text('Nous visiter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.white100,
              foregroundColor: isLive 
                  ? const Color(0xFFFF5722)
                  : isUpcoming 
                      ? const Color(0xFF2196F3)
                      : const Color(0xFF607D8B),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              elevation: 4,
            ),
          ),
        ),
        
        const SizedBox(width: AppTheme.space12),
        
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isLive 
                ? () => _openLiveStream(config.liveUrl)
                : () => _addLiveToCalendar(),
            icon: Icon(isLive ? Icons.play_circle_filled : Icons.notifications_outlined),
            label: Text(isLive ? 'Rejoindre' : 'Rappel'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.white100.withOpacity(0.2),
              foregroundColor: AppTheme.white100,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                side: const BorderSide(color: AppTheme.white100, width: 1.5),
              ),
              elevation: 4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection(HomeConfigModel config) {
    final actions = config.quickActions.isNotEmpty 
        ? config.quickActions 
        : HomeConfigModel.defaultConfig.quickActions;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header - Style moderne comme Perfect 13
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceSmall),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Icon(
                Icons.flash_on_rounded,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
                size: 20,
              ),
            ),
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Liens rapides',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: AppTheme.fontBold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Accès rapide aux ressources',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space20),
        
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.0, // Cartes parfaitement carrées
          children: actions.map((action) => _buildQuickActionCardFromConfig(action)).toList(),
        ),
      ],
    );
  }

  Widget _buildQuickActionCardFromConfig(Map<String, dynamic> actionConfig) {
    final title = actionConfig['title'] ?? '';
    final description = actionConfig['description'] ?? '';
    final iconName = actionConfig['icon'] ?? 'help_outline';
    final colorValue = actionConfig['color'] ?? 0xFF9E9E9E;
    final iconColorValue = actionConfig['iconColor'];
    final backgroundColorValue = actionConfig['backgroundColor'] ?? colorValue;
    final textColorValue = actionConfig['textColor'];
    final backgroundImageUrl = actionConfig['backgroundImage'];
    final showIcon = actionConfig['showIcon'] ?? true;
    
    final backgroundColor = Color(backgroundColorValue);
    
    // Calcul automatique des couleurs si non spécifiées
    Color iconColor;
    Color textColor;
    
    if (iconColorValue != null) {
      iconColor = Color(iconColorValue);
    } else {
      // Auto: blanc sur fond sombre, noir sur fond clair
      final luminance = backgroundColor.computeLuminance();
      iconColor = luminance > 0.5 ? Colors.black : Colors.white;
    }
    
    if (textColorValue != null) {
      textColor = Color(textColorValue);
    } else {
      // Auto: contraste optimal basé sur la luminance
      textColor = _getTextColorForBackground(backgroundColor);
    }
    
    // Mapper les noms d'icônes aux IconData avec collection étendue
    IconData icon;
    switch (iconName) {
      // Icônes religieuses et spirituelles
      case 'church':
      case 'church_rounded':
        icon = Icons.church;
        break;
      case 'volunteer_activism_rounded':
        icon = Icons.volunteer_activism_rounded;
        break;
      case 'favorite_rounded':
        icon = Icons.favorite_rounded;
        break;
      case 'auto_stories':
      case 'bible':
        icon = Icons.auto_stories;
        break;
      case 'menu_book_rounded':
        icon = Icons.menu_book_rounded;
        break;
      case 'campaign':
      case 'prayer':
        icon = Icons.campaign;
        break;
      case 'celebration':
        icon = Icons.celebration;
        break;
      case 'temple_buddhist':
        icon = Icons.temple_buddhist;
        break;
        
      // Icônes de communauté et groupes
      case 'group':
        icon = Icons.group;
        break;
      case 'groups':
        icon = Icons.groups;
        break;
      case 'people':
        icon = Icons.people;
        break;
      case 'family_restroom':
      case 'family':
        icon = Icons.family_restroom;
        break;
      case 'diversity_3':
        icon = Icons.diversity_3;
        break;
      case 'handshake':
      case 'community':
        icon = Icons.handshake;
        break;
        
      // Icônes de calendrier et événements
      case 'calendar_today':
      case 'calendar':
        icon = Icons.calendar_today;
        break;
      case 'event':
        icon = Icons.event;
        break;
      case 'schedule':
        icon = Icons.schedule;
        break;
      case 'date_range':
        icon = Icons.date_range;
        break;
      case 'event_available':
        icon = Icons.event_available;
        break;
      case 'today':
        icon = Icons.today;
        break;
        
      // Icônes de communication
      case 'mail':
        icon = Icons.mail;
        break;
      case 'email':
        icon = Icons.email;
        break;
      case 'message':
        icon = Icons.message;
        break;
      case 'phone':
        icon = Icons.phone;
        break;
      case 'contact_phone':
        icon = Icons.contact_phone;
        break;
      case 'forum':
      case 'discussion':
        icon = Icons.forum;
        break;
      case 'chat':
        icon = Icons.chat;
        break;
        
      // Icônes de musique et louange
      case 'music_note':
      case 'worship':
        icon = Icons.music_note;
        break;
      case 'library_music':
        icon = Icons.library_music;
        break;
      case 'queue_music':
        icon = Icons.queue_music;
        break;
      case 'mic':
        icon = Icons.mic;
        break;
      case 'piano':
        icon = Icons.piano;
        break;
      case 'audiotrack':
        icon = Icons.audiotrack;
        break;
        
      // Icônes de dons et finances
      case 'card_giftcard_rounded':
        icon = Icons.card_giftcard_rounded;
        break;
      case 'volunteer_activism':
        icon = Icons.volunteer_activism;
        break;
      case 'monetization_on':
        icon = Icons.monetization_on;
        break;
      case 'account_balance_wallet':
        icon = Icons.account_balance_wallet;
        break;
      case 'savings':
        icon = Icons.savings;
        break;
        
      // Icônes de localisation
      case 'location_on':
      case 'location_on_rounded':
        icon = Icons.location_on;
        break;
      case 'place':
        icon = Icons.place;
        break;
      case 'map':
        icon = Icons.map;
        break;
      case 'directions':
        icon = Icons.directions;
        break;
      case 'home':
        icon = Icons.home;
        break;
        
      // Icônes d'éducation et formation
      case 'school':
      case 'formation':
        icon = Icons.school;
        break;
      case 'book':
        icon = Icons.book;
        break;
      case 'quiz':
        icon = Icons.quiz;
        break;
      case 'psychology':
        icon = Icons.psychology;
        break;
      case 'lightbulb':
        icon = Icons.lightbulb;
        break;
        
      // Icônes de service et ministère
      case 'work':
      case 'workspace_premium':
      case 'service':
        icon = Icons.work;
        break;
      case 'build':
        icon = Icons.build;
        break;
      case 'engineering':
        icon = Icons.engineering;
        break;
      case 'cleaning_services':
        icon = Icons.cleaning_services;
        break;
      case 'restaurant':
        icon = Icons.restaurant;
        break;
      case 'local_dining':
        icon = Icons.local_dining;
        break;
        
      // Icônes diverses utiles
      case 'info':
        icon = Icons.info;
        break;
      case 'help':
        icon = Icons.help;
        break;
      case 'support':
        icon = Icons.support;
        break;
      case 'star':
        icon = Icons.star;
        break;
      case 'diamond':
        icon = Icons.diamond;
        break;
      case 'emoji_events':
        icon = Icons.emoji_events;
        break;
      case 'card_membership':
        icon = Icons.card_membership;
        break;
      case 'badge':
        icon = Icons.badge;
        break;
        
      // Icône par défaut
      case 'help_outline':
      default:
        icon = Icons.help_outline;
    }
    
    return _buildQuickActionCard(title, description, icon, backgroundColor, iconColor, textColor, backgroundImageUrl, showIcon, () => _handleQuickAction(title));
  }

  // Méthode utilitaire pour calculer la couleur du texte selon le contraste
  Color _getTextColorForBackground(Color backgroundColor) {
    // Calculer la luminance de la couleur de fond
    final luminance = backgroundColor.computeLuminance();
    // Si la couleur est claire (luminance > 0.5), utiliser du texte noir
    // Sinon, utiliser du texte blanc
    return luminance > 0.5 ? AppTheme.black100 : AppTheme.white100;
  }

  ImageProvider _getImageProvider(String imageUrl) {
    if (imageUrl.startsWith('file://')) {
      final filePath = imageUrl.substring(7); // Enlever 'file://'
      return FileImage(File(filePath));
    } else {
      return NetworkImage(imageUrl);
    }
  }

  Widget _buildQuickActionCard(String title, String description, IconData icon, Color backgroundColor, Color iconColor, Color textColor, String? backgroundImageUrl, bool showIcon, VoidCallback onTap) {
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Material(
        elevation: 0,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          // Effets d'interaction améliorés
          splashColor: AppTheme.white100.withOpacity(0.3),
          highlightColor: AppTheme.white100.withOpacity(0.1),
        child: Container(
          decoration: BoxDecoration(
            gradient: backgroundImageUrl == null ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                backgroundColor,
                backgroundColor.withOpacity(0.8),
              ],
            ) : null,
            image: backgroundImageUrl != null ? DecorationImage(
              image: _getImageProvider(backgroundImageUrl),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                backgroundColor.withOpacity(0.3),
                BlendMode.overlay,
              ),
            ) : null,
            borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
            boxShadow: [
              BoxShadow(
                color: backgroundColor.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: backgroundColor.withOpacity(0.1),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Motifs décoratifs de fond
              Positioned(
                top: -10,
                right: -10,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.white100.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
              Positioned(
                bottom: -15,
                left: -15,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.white100.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              // Contenu principal
              Padding(
            padding: const EdgeInsets.all(AppTheme.spaceMedium), // Réduit de 20 à 16
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icône centrale proeminente - Affichage conditionnel
                if (showIcon)
                  Flexible(
                    child: Container(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight * 0.4,
                        maxHeight: constraints.maxHeight * 0.6,
                      ),
                      child: Center(
                        child: Container(
                          width: constraints.maxWidth * 0.4,
                          height: constraints.maxWidth * 0.4,
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                            maxWidth: 72,
                            maxHeight: 72,
                          ),
                          decoration: BoxDecoration(
                            color: textColor == AppTheme.black100 
                              ? AppTheme.black100.withOpacity(0.15)
                              : AppTheme.white100.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: textColor == AppTheme.black100 
                                  ? AppTheme.black100.withOpacity(0.1)
                                  : AppTheme.black100.withOpacity(0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            icon,
                            color: iconColor,
                            size: (constraints.maxWidth * 0.2).clamp(24.0, 36.0), // Taille adaptative
                          ),
                        ),
                      ),
                    ),
                  ),
                
                if (showIcon)
                  const SizedBox(height: AppTheme.spaceSmall),
                
                // Texte compact avec contraintes strictes
                Flexible(
                  child: Container(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight * 0.25,
                      maxHeight: constraints.maxHeight * 0.4,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: AppTheme.fontBold,
                              fontSize: (constraints.maxWidth * 0.08).clamp(12.0, 16.0), // Taille adaptative
                            ),
                            textAlign: TextAlign.center,
                            maxLines: constraints.maxHeight > 140 ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Flexible(
                          child: Text(
                            description,
                            style: TextStyle(
                              color: textColor == AppTheme.black100 
                                ? textColor.withOpacity(0.7) 
                                : textColor.withOpacity(0.85),
                              fontSize: (constraints.maxWidth * 0.06).clamp(10.0, 13.0), // Taille adaptative
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: constraints.maxHeight > 140 ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
            ],
          ),
        ),
      ),
    );
      },
    );
  }

  Widget _buildUpcomingEventsSection(HomeConfigModel config) {
    return StreamBuilder<List<EventModel>>(
      stream: EventsFirebaseService.getUpcomingEventsStream(limit: 3),
      builder: (context, snapshot) {
        final events = snapshot.data ?? [];
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec bouton "Voir plus" - Style moderne amélioré
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  // Icône avec dégradé
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.passageColor4,
                          AppTheme.orangeStandard,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.orangeStandard.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.event_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Événements à venir',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : const Color(0xFF1A1A1A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Ne manquez aucun moment important',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFFB0BEC5)
                                : const Color(0xFF546E7A),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Bouton "Voir plus" simple
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MemberEventsPage(),
                        ),
                      );
                    },
                    child: Text(
                      'Voir plus',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: AppTheme.fontSemiBold,
                        fontSize: AppTheme.isApplePlatform ? 14 : 13,
                        height: 1.2,
                        letterSpacing: AppTheme.isApplePlatform ? -0.1 : -0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            
            // Contenu des événements
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(
                child: CircularProgressIndicator(color: AppTheme.orangeStandard),
              )
            else if (snapshot.hasError)
              Container(
                padding: const EdgeInsets.all(AppTheme.space20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                  border: Border.all(
                    color: AppTheme.redStandard.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Erreur lors du chargement des événements',
                  style: TextStyle(color: AppTheme.redStandard.withOpacity(0.8)),
                ),
              )
            else if (events.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.orangeStandard.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.orangeStandard.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.event_busy_rounded,
                        color: AppTheme.orangeStandard,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun événement à venir',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : const Color(0xFF1A1A1A),
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Revenez bientôt pour découvrir nos prochains événements',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFFB0BEC5)
                            : const Color(0xFF546E7A),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else
              // Liste des événements
              ...events.map((event) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () {
                    // Navigation vers la vue membre de détail de l'événement
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MemberEventDetailPage(event: event),
                      ),
                    );
                  },
                  child: _buildEventCardFromEventModel(event),
                ),
              )).toList(),
          ],
        );
      },
    );
  }

  Widget _buildEventCardFromEventModel(EventModel event) {
    // Formatage de la date
    final startDate = event.startDate;
    final day = startDate.day.toString();
    final monthNames = [
      '', 'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
      'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    final month = monthNames[startDate.month];
    
    // Formatage de l'heure
    final timeFormat = '${startDate.hour.toString().padLeft(2, '0')}:${startDate.minute.toString().padLeft(2, '0')}';
    
    // Limitation de la description
    final description = event.description.length > 80 
        ? '${event.description.substring(0, 80)}...' 
        : event.description;
    
    return _buildEventCard(day, month, event.title, description, timeFormat);
  }

  Widget _buildEventCard(String day, String month, String title, String description, String time) {
    return Container(
      decoration: BoxDecoration(
        // Fond dégradé subtil pour plus de profondeur
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.orangeStandard.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.orangeStandard.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppTheme.black100.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Accent de gauche coloré
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 6,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.passageColor4,
                      AppTheme.orangeStandard,
                    ],
                  ),
                ),
              ),
            ),
            
            // Contenu principal
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Date bloc - Design amélioré avec ombre portée
                  Container(
                    width: 75,
                    height: 85,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.passageColor4,
                          AppTheme.orangeStandard,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.orangeStandard.withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 1,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          day,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            fontSize: 28,
                            height: 1.0,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                offset: Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            month.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 18),
                  
                  // Contenu textuel amélioré
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Titre avec meilleur contraste
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : const Color(0xFF1A1A1A),
                            fontSize: 17,
                            height: 1.3,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        
                        // Description avec meilleur contraste
                        Text(
                          description,
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFFB0BEC5)
                                : const Color(0xFF546E7A),
                            fontSize: 14,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        
                        // Badge horaire avec design amélioré
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.orangeStandard.withOpacity(0.15),
                                AppTheme.passageColor4.withOpacity(0.15),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppTheme.orangeStandard.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 16,
                                color: AppTheme.orangeStandard,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                time,
                                style: TextStyle(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? AppTheme.orangeStandard
                                      : const Color(0xFFE65100),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Icône de navigation améliorée
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.orangeStandard.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppTheme.orangeStandard,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactUsSection(HomeConfigModel config) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface, // MD3: Surface blanc/gris clair
        borderRadius: BorderRadius.circular(
          AppTheme.isApplePlatform ? 20 : 28, // 20dp iOS, 28dp Android
        ),
        border: Border.all(
          color: AppTheme.grey300.withOpacity(
            AppTheme.isApplePlatform ? 1.0 : 0.5, // Bordure visible iOS
          ),
          width: AppTheme.isApplePlatform ? 0.5 : 1.0,
        ),
        boxShadow: AppTheme.isApplePlatform
            ? [] // iOS: Flat design, pas d'ombre
            : [
                // Android: Élévation MD3
                BoxShadow(
                  color: AppTheme.black100.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                  spreadRadius: -4,
                ),
                BoxShadow(
                  color: AppTheme.black100.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec gradient rouge élégant (bandeau du haut uniquement)
          Container(
            padding: EdgeInsets.all(AppTheme.adaptivePadding),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withOpacity(0.9),
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(
                  AppTheme.isApplePlatform ? 19.5 : 27,
                ),
                topRight: Radius.circular(
                  AppTheme.isApplePlatform ? 19.5 : 27,
                ),
              ),
            ),
            child: Row(
              children: [
                // Icône professionnelle
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.white100.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(
                      AppTheme.isApplePlatform ? 12 : 18,
                    ),
                    border: Border.all(
                      color: AppTheme.white100.withOpacity(
                        AppTheme.isApplePlatform ? 0.5 : 0.35,
                      ),
                      width: AppTheme.isApplePlatform ? 0.5 : 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.headset_mic_rounded,
                    color: AppTheme.white100,
                    size: AppTheme.isApplePlatform ? 26 : 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nous contacter',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.white100,
                          fontSize: AppTheme.isApplePlatform ? 20 : 22,
                          letterSpacing: AppTheme.isApplePlatform ? 0 : -0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Nous sommes à votre écoute',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.white100.withOpacity(0.92),
                          fontSize: AppTheme.adaptiveBodyMedium,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Corps blanc avec les méthodes de contact
          Padding(
            padding: EdgeInsets.all(AppTheme.adaptivePadding),
            child: Column(
              children: [
                // Email
                if (config.contactEmail?.isNotEmpty == true)
                  _buildContactMethod(
                    Icons.email_rounded,
                    'Email',
                    config.contactEmail!,
                    () => _sendEmail(),
                  ),
                
                if (config.contactEmail?.isNotEmpty == true)
                  const SizedBox(height: 12),
                
                // Adresse
                if (config.contactAddress?.isNotEmpty == true)
                  _buildContactMethod(
                    Icons.location_on_rounded,
                    'Adresse',
                    config.contactAddress!,
                    () => _openMaps(),
                  ),
                
                if (config.contactAddress?.isNotEmpty == true)
                  const SizedBox(height: 12),
                
                // Téléphone
                if (config.contactPhone?.isNotEmpty == true)
                  _buildContactMethod(
                    Icons.phone_rounded,
                    'Téléphone',
                    config.contactPhone!,
                    () => _callChurch(),
                  ),
                
                if (config.contactPhone?.isNotEmpty == true)
                  const SizedBox(height: 12),
                
                // WhatsApp
                if (config.contactWhatsApp?.isNotEmpty == true)
                  _buildContactMethod(
                    Icons.chat_rounded,
                    'WhatsApp',
                    'Messagerie instantanée',
                    () => _openWhatsApp(),
                  ),
                
                if (config.contactWhatsApp?.isNotEmpty == true)
                  const SizedBox(height: 12),
                
                // Message depuis l'application (même design que les autres)
                _buildContactMethod(
                  Icons.message_rounded,
                  'Message depuis l\'application',
                  'Contactez-nous directement',
                  () => _showContactForm(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactMethod(IconData icon, String title, String subtitle, VoidCallback onTap) {
    // Version iOS/macOS
    if (AppTheme.isApplePlatform) {
      return CupertinoButton(
        onPressed: () {
          HapticFeedback.lightImpact(); // Feedback tactile iOS
          onTap();
        },
        padding: EdgeInsets.zero,
        child: Container(
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6.resolveFrom(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: CupertinoColors.separator.resolveFrom(context),
              width: 0.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Icône iOS
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                // Texte
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: CupertinoColors.label.resolveFrom(context),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: CupertinoColors.secondaryLabel.resolveFrom(context),
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Chevron iOS
                Icon(
                  CupertinoIcons.chevron_forward,
                  color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Version Android/Web (Material)
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: AppTheme.primaryColor.withOpacity(0.1), // Splash rouge subtil
        highlightColor: AppTheme.primaryColor.withOpacity(0.05),
        child: Ink(
          decoration: BoxDecoration(
            color: AppTheme.grey100, // Gris très clair, professionnel
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.grey300.withOpacity(0.6),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Icône avec accent rouge
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1), // Fond rouge clair
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: AppTheme.primaryColor, // Icône rouge
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                // Texte
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.onSurface, // Texte foncé
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.grey600, // Gris moyen
                          fontSize: 13,
                          letterSpacing: 0.25,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Icône de navigation
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.grey200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppTheme.grey700,
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Méthodes d'action
  void _showVisitUs() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const VisitUsPage()),
    );
  }

  void _handleQuickAction(String actionTitle) {
    final normalized = actionTitle
      .toLowerCase()
      .replaceAll(RegExp(r'[éèêë]'), 'e')
      .replaceAll(RegExp(r'[àâä]'), 'a')
      .replaceAll(RegExp(r'[îï]'), 'i')
      .replaceAll(RegExp(r'[ôö]'), 'o')
      .replaceAll(RegExp(r'[ùûü]'), 'u')
      .replaceAll(RegExp(r'[^a-z0-9 ]'), '')
      .trim();

    if (normalized == 'nous visiter') {
      _showVisitUs();
      return;
    }
    switch (actionTitle) {
      case 'Étudier la Parole':
        _showBibleStudy();
        break;
      case 'Requêtes de prière':
        _openPrayerWall();
        break;
      case 'Faire un don':
        _showDonations();
        break;
      case "Calendrier de l'église":
        _openChurchCalendar();
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$actionTitle - Fonctionnalité bientôt disponible')),
        );
    }
  }

  void _showChurchInfo() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Informations sur l\'église - Fonctionnalité bientôt disponible')),
    );
  }

  void _openLiveStream([String? liveUrl]) {
    if (liveUrl?.isNotEmpty == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ouverture du live stream: $liveUrl')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ouverture du live stream...')),
      );
    }
  }

  void _addLiveToCalendar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rappel ajouté au calendrier')),
    );
  }


  void _showBibleStudy() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Étude biblique - Fonctionnalité bientôt disponible')),
    );
  }


  void _openPrayerWall() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MemberPrayerWallPage(),
      ),
    );
  }

  void _showDonations() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DonationsPage(),
      ),
    );
  }

  void _sendEmail() async {
    try {
      // Récupérer la configuration
      final config = await HomeConfigService.getHomeConfig();
      final email = config.contactEmail;
      
      if (email?.isNotEmpty == true) {
        final Uri emailUri = Uri(
          scheme: 'mailto',
          path: email,
          query: 'subject=${Uri.encodeComponent('Contact depuis l\'application')}&body=${Uri.encodeComponent('Bonjour,\n\nJe vous contacte depuis l\'application mobile.\n\n')}'
        );
        
        if (await canLaunchUrl(emailUri)) {
          await launchUrl(emailUri);
        } else {
          // Fallback : copier l'email dans le presse-papier
          await Clipboard.setData(ClipboardData(text: email!));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Email copié dans le presse-papier : $email'),
                backgroundColor: AppTheme.greenStandard,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucun email de contact configuré'),
              backgroundColor: AppTheme.orangeStandard,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ouverture de l\'email : $e'),
            backgroundColor: AppTheme.redStandard,
          ),
        );
      }
    }
  }

  void _openMaps() async {
    try {
      // Récupérer la configuration
      final config = await HomeConfigService.getHomeConfig();
      final address = config.contactAddress;
      
      if (address?.isNotEmpty == true) {
        // Encoder l'adresse pour l'URL
        final encodedAddress = Uri.encodeComponent(address!);
        
        // Essayer d'ouvrir Google Maps d'abord
        final googleMapsUri = Uri.parse('google.navigation:q=$encodedAddress');
        final appleMapsUri = Uri.parse('maps:q=$encodedAddress');
        final webMapsUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedAddress');
        
        bool launched = false;
        
        // Essayer Google Maps
        if (await canLaunchUrl(googleMapsUri)) {
          await launchUrl(googleMapsUri);
          launched = true;
        }
        // Essayer Apple Maps
        else if (await canLaunchUrl(appleMapsUri)) {
          await launchUrl(appleMapsUri);
          launched = true;
        }
        // Fallback vers le web
        else if (await canLaunchUrl(webMapsUri)) {
          await launchUrl(webMapsUri, mode: LaunchMode.externalApplication);
          launched = true;
        }
        
        if (!launched) {
          // Copier l'adresse dans le presse-papier comme fallback
          await Clipboard.setData(ClipboardData(text: address));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Adresse copiée dans le presse-papier : $address'),
                backgroundColor: AppTheme.greenStandard,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucune adresse configurée'),
              backgroundColor: AppTheme.orangeStandard,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ouverture de la carte : $e'),
            backgroundColor: AppTheme.redStandard,
          ),
        );
      }
    }
  }

  void _callChurch() async {
    try {
      // Récupérer la configuration
      final config = await HomeConfigService.getHomeConfig();
      final phone = config.contactPhone;
      
      if (phone?.isNotEmpty == true) {
        // Nettoyer le numéro de téléphone (enlever les espaces, tirets, etc.)
        final cleanPhone = phone!.replaceAll(RegExp(r'[^\d+]'), '');
        final Uri telUri = Uri(scheme: 'tel', path: cleanPhone);
        
        if (await canLaunchUrl(telUri)) {
          await launchUrl(telUri);
        } else {
          // Fallback : copier le numéro dans le presse-papier
          await Clipboard.setData(ClipboardData(text: phone));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Numéro copié dans le presse-papier : $phone'),
                backgroundColor: AppTheme.greenStandard,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucun numéro de téléphone configuré'),
              backgroundColor: AppTheme.orangeStandard,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'appel : $e'),
            backgroundColor: AppTheme.redStandard,
          ),
        );
      }
    }
  }

  void _openWhatsApp() async {
    try {
      // Récupérer la configuration
      final config = await HomeConfigService.getHomeConfig();
      final whatsappNumber = config.contactWhatsApp;
      
      if (whatsappNumber?.isNotEmpty == true) {
        // Nettoyer le numéro WhatsApp
        final cleanNumber = whatsappNumber!.replaceAll(RegExp(r'[^\d+]'), '');
        
        // Message prédéfini
        const message = 'Bonjour, je vous contacte depuis l\'application mobile.';
        final encodedMessage = Uri.encodeComponent(message);
        
        // URLs WhatsApp
        final whatsappUri = Uri.parse('whatsapp://send?phone=$cleanNumber&text=$encodedMessage');
        final whatsappWebUri = Uri.parse('https://wa.me/$cleanNumber?text=$encodedMessage');
        
        bool launched = false;
        
        // Essayer l'application WhatsApp d'abord
        if (await canLaunchUrl(whatsappUri)) {
          await launchUrl(whatsappUri);
          launched = true;
        }
        // Fallback vers WhatsApp Web
        else if (await canLaunchUrl(whatsappWebUri)) {
          await launchUrl(whatsappWebUri, mode: LaunchMode.externalApplication);
          launched = true;
        }
        
        if (!launched) {
          // Copier le numéro dans le presse-papier comme fallback
          await Clipboard.setData(ClipboardData(text: whatsappNumber));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Numéro WhatsApp copié : $whatsappNumber'),
                backgroundColor: AppTheme.greenStandard,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucun numéro WhatsApp configuré'),
              backgroundColor: AppTheme.orangeStandard,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ouverture de WhatsApp : $e'),
            backgroundColor: AppTheme.redStandard,
          ),
        );
      }
    }
  }

  void _showContactForm() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ContactFormDialog();
      },
    );
  }
}

class ContactFormDialog extends StatefulWidget {
  @override
  _ContactFormDialogState createState() => _ContactFormDialogState();
}

class _ContactFormDialogState extends State<ContactFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Envoyer le message directement via Firebase
      await ContactService.sendMessage(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        subject: _subjectController.text.trim(),
        message: _messageController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Message envoyé avec succès !'),
            backgroundColor: AppTheme.greenStandard,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur lors de l\'envoi: $e'),
            backgroundColor: AppTheme.redStandard,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(AppTheme.spaceLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // En-tête
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.space12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: const Icon(
                    Icons.message_rounded,
                    color: AppTheme.white100,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nous contacter',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: AppTheme.fontBold,
                        ),
                      ),
                      Text(
                        'Envoyez-nous votre message',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.spaceLarge),
            
            // Formulaire
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Nom
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Votre nom *',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Veuillez entrer votre nom';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: AppTheme.spaceMedium),
                      
                      // Email
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Votre email *',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Veuillez entrer votre email';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Veuillez entrer un email valide';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: AppTheme.spaceMedium),
                      
                      // Sujet
                      TextFormField(
                        controller: _subjectController,
                        decoration: const InputDecoration(
                          labelText: 'Sujet *',
                          prefixIcon: Icon(Icons.subject),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Veuillez entrer un sujet';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: AppTheme.spaceMedium),
                      
                      // Message
                      TextFormField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          labelText: 'Votre message *',
                          prefixIcon: Icon(Icons.message_outlined),
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Veuillez entrer votre message';
                          }
                          if (value.trim().length < 10) {
                            return 'Le message doit contenir au moins 10 caractères';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: AppTheme.spaceLarge),
            
            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMedium),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      foregroundColor: AppTheme.white100,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white100),
                            ),
                          )
                        : const Text('Envoyer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget personnalisé pour lecteur vidéo avec autoplay et boucle
class AutoplayVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const AutoplayVideoPlayer({
    super.key,
    required this.videoUrl,
  });

  @override
  State<AutoplayVideoPlayer> createState() => _AutoplayVideoPlayerState();
}

class _AutoplayVideoPlayerState extends State<AutoplayVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _controller!.initialize();
      
      if (mounted) {
        setState(() => _isInitialized = true);
        
        // Configuration pour autoplay et boucle
        _controller!.setLooping(true);
        _controller!.setVolume(0.0); // Son coupé pour éviter le bruit automatique
        _controller!.play();
        
        // Listener pour relancer la vidéo si elle s'arrête
        _controller!.addListener(() {
          if (_controller!.value.hasError) {
            setState(() => _hasError = true);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorWidget();
    }
    
    if (!_isInitialized || _controller == null) {
      return _buildLoadingWidget();
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Lecteur vidéo
            VideoPlayer(_controller!),
            
            // Badge "LIVE" en haut à droite pour indiquer l'autoplay
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.grey900,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppTheme.primaryColor,
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'Chargement de la vidéo...',
              style: TextStyle(
                color: AppTheme.white100,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.grey900,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppTheme.redStandard,
            ),
            const SizedBox(height: 16),
            Text(
              'Impossible de charger la vidéo',
              style: TextStyle(
                color: AppTheme.white100,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vérifiez l\'URL de la vidéo',
              style: TextStyle(
                color: AppTheme.grey500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


