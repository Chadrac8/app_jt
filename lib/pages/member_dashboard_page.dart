import 'package:flutter/material.dart';
import 'dart:async';
import '../theme.dart';
import '../models/home_widget_model.dart';
import '../models/home_config_model.dart';
import '../services/home_widget_service.dart';
import '../services/home_config_service.dart';
import '../widgets/latest_sermon_widget.dart';
import '../modules/offrandes/widgets/offrandes_widget.dart';
import '../widgets/home_widget_renderer.dart';
import '../modules/pain_quotidien/widgets/daily_bread_preview_widget.dart';
import '../pages/church_info_page.dart';
import '../pages/prayer_wall_page.dart';
import '../pages/new_member_form_page.dart';
import '../pages/give_life_to_jesus_page.dart';
import '../services/live_reminder_service.dart';
import '../services/home_cover_config_service.dart';
import '../models/home_cover_config_model.dart';
import '../models/event_model.dart';
import '../services/events_firebase_service.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class MemberDashboardPage extends StatefulWidget {
  const MemberDashboardPage({super.key});

  @override
  State<MemberDashboardPage> createState() => _MemberDashboardPageState();
}

class _MemberDashboardPageState extends State<MemberDashboardPage>
    with TickerProviderStateMixin {
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
                  const SizedBox(height: 16),
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

          return CustomScrollView(
            slivers: [
              // AppBar avec image de couverture
              _buildSliverAppBar(config),

              // Pain quotidien (si activé)
              if (config.isDailyBreadActive)
                SliverToBoxAdapter(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 32, bottom: 32),
                      child: const DailyBreadPreviewWidget(),
                    ),
                  ),
                ),

              // Contenu principal
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 0.0, left: 20.0, right: 20.0, bottom: 20.0),
                    child: Column(
                      children: [
                        // Section Live (si activée)
                        if (config.isLiveActive)
                          _buildNextLiveSection(config),
                        if (config.isLiveActive)
                          const SizedBox(height: 32),
                        
                        // Actions rapides (si activées)
                        if (config.areQuickActionsActive)
                          _buildQuickActionsSection(config),
                        if (config.areQuickActionsActive)
                          const SizedBox(height: 32),
                        
                        // Dernières prédications (si activées)
                        if (config.isLastSermonActive)
                          const LatestSermonWidget(),
                        if (config.isLastSermonActive)
                          const SizedBox(height: 32),
                        
                        // Événements à venir (si activés)
                        if (config.areEventsActive)
                          _buildUpcomingEventsSection(config),
                        if (config.areEventsActive)
                          const SizedBox(height: 32),
                        
                        // Nous contacter (si activé)
                        if (config.isContactActive)
                          _buildContactUsSection(config),
                        if (config.isContactActive)
                          const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(HomeConfigModel config) {
    return SliverAppBar(
      expandedHeight: 280,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.surface,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
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
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverMedia(HomeConfigModel config) {
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
                return Image.network(
                  config.coverImageUrls[index],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildDefaultCoverBackground();
                  },
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
                              ? Colors.white
                              : Colors.white.withOpacity(0.4),
                          border: currentIndex == index
                              ? Border.all(color: Colors.white, width: 1)
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
      return Image.network(
        config.coverImageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultCoverBackground();
        },
      );
    }
    
    // Background par défaut
    return _buildDefaultCoverBackground();
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
            color: (isLive ? Colors.deepOrange : isUpcoming ? Colors.blue : Colors.blueGrey)
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
          const SizedBox(height: 16),
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
                      color: Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(_liveAnimation.value * 0.8),
                          blurRadius: 8,
                          spreadRadius: _liveAnimation.value * 3,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
            ],
            Flexible(
              child: Text(
                statusText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        
        if (isUpcoming) ...[
          const SizedBox(height: 16),
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
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              letterSpacing: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          unit,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 11,
            fontWeight: FontWeight.w600,
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
          color: Colors.white.withOpacity(0.7),
          fontSize: 20,
          fontWeight: FontWeight.bold,
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
              backgroundColor: Colors.white,
              foregroundColor: isLive 
                  ? const Color(0xFFFF5722)
                  : isUpcoming 
                      ? const Color(0xFF2196F3)
                      : const Color(0xFF607D8B),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isLive 
                ? () => _openLiveStream(config.liveUrl)
                : () => _addLiveToCalendar(),
            icon: Icon(isLive ? Icons.play_circle_filled : Icons.notifications_outlined),
            label: Text(isLive ? 'Rejoindre' : 'Rappel'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.white, width: 1.5),
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.flash_on_rounded,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Actions rapides',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Accès direct aux fonctionnalités importantes',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.9,
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
    final color = Color(colorValue);
    
    // Mapper les noms d'icônes aux IconData
    IconData icon;
    switch (iconName) {
      case 'favorite_rounded':
        icon = Icons.favorite_rounded;
        break;
      case 'menu_book_rounded':
        icon = Icons.menu_book_rounded;
        break;
      case 'volunteer_activism_rounded':
        icon = Icons.volunteer_activism_rounded;
        break;
      case 'card_giftcard_rounded':
        icon = Icons.card_giftcard_rounded;
        break;
      default:
        icon = Icons.help_outline;
    }
    
    return _buildQuickActionCard(title, description, icon, color, () => _handleQuickAction(title));
  }

  Widget _buildQuickActionCard(String title, String description, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      elevation: 0,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color,
                color.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background Pattern
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Text
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
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
  }

  Widget _buildUpcomingEventsSection(HomeConfigModel config) {
    return StreamBuilder<List<EventModel>>(
      stream: EventsFirebaseService.getUpcomingEventsStream(limit: 3),
      builder: (context, snapshot) {
        final events = snapshot.data ?? [];
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec bouton "Voir plus" - Style moderne
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.event_rounded,
                      color: Theme.of(context).colorScheme.onTertiaryContainer,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Événements à venir',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Ne manquez aucun événement',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // Navigation vers la page complète des événements
                      Navigator.pushNamed(context, '/events');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Voir plus',
                            style: TextStyle(
                              color: Colors.orange.shade300,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.orange.shade300,
                            size: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Contenu des événements
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(
                child: CircularProgressIndicator(color: Colors.orange),
              )
            else if (snapshot.hasError)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Erreur lors du chargement des événements',
                  style: TextStyle(color: Colors.red.withOpacity(0.8)),
                ),
              )
            else if (events.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.event,
                      color: Colors.orange.withOpacity(0.6),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Aucun événement à venir',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            else
              // Liste des événements
              ...events.map((event) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildEventCardFromEventModel(event),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.orange.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFB74D),
                  Color(0xFFFF9800),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  day,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
                Text(
                  month,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFFB0BEC5),
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: Color(0xFFFFB74D),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: const TextStyle(
                        color: Color(0xFFFFB74D),
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Icon(
            Icons.chevron_right_rounded,
            color: Colors.white.withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildContactUsSection(HomeConfigModel config) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1565C0),
            Color(0xFF1976D2),
            Color(0xFF42A5F5),
          ],
          stops: [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1976D2).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nous contacter',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 26,
                        shadows: [
                          const Shadow(
                            blurRadius: 8,
                            color: Colors.black26,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Une question ? Nous sommes là pour vous',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                if (config.contactEmail?.isNotEmpty == true)
                  _buildContactMethod(
                    Icons.email_rounded,
                    'Email',
                    config.contactEmail!,
                    () => _sendEmail(),
                  ),
                
                if (config.contactEmail?.isNotEmpty == true)
                  const SizedBox(height: 16),
                
                if (config.contactAddress?.isNotEmpty == true)
                  _buildContactMethod(
                    Icons.location_on_rounded,
                    'Adresse',
                    config.contactAddress!,
                    () => _openMaps(),
                  ),
                
                if (config.contactAddress?.isNotEmpty == true)
                  const SizedBox(height: 16),
                
                if (config.contactPhone?.isNotEmpty == true)
                  _buildContactMethod(
                    Icons.phone_rounded,
                    'Téléphone',
                    config.contactPhone!,
                    () => _callChurch(),
                  ),
                
                if (config.contactPhone?.isNotEmpty == true)
                  const SizedBox(height: 16),
                
                if (config.contactWhatsApp?.isNotEmpty == true)
                  _buildContactMethod(
                    Icons.chat_rounded,
                    'WhatsApp',
                    'Messagerie instantanée',
                    () => _openWhatsApp(),
                  ),
                
                if (config.contactWhatsApp?.isNotEmpty == true)
                  const SizedBox(height: 20),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showContactForm(),
                    icon: const Icon(Icons.message_rounded),
                    label: const Text('Envoyer un message'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1976D2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactMethod(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withOpacity(0.7),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // Méthodes d'action
  void _handleQuickAction(String actionTitle) {
    switch (actionTitle) {
      case 'Donner sa vie à Jésus':
        _showGiveLifeToJesus();
        break;
      case 'Étudier la Parole':
        _showBibleStudy();
        break;
      case 'Requêtes de prière':
        _showPrayerRequests();
        break;
      case 'Faire un don':
        _showDonations();
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

  void _showGiveLifeToJesus() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Donner sa vie à Jésus - Fonctionnalité bientôt disponible')),
    );
  }

  void _showBibleStudy() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Étude biblique - Fonctionnalité bientôt disponible')),
    );
  }

  void _showPrayerRequests() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Requêtes de prière - Fonctionnalité bientôt disponible')),
    );
  }

  void _showDonations() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dons - Fonctionnalité bientôt disponible')),
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
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucun email de contact configuré'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ouverture de l\'email : $e'),
            backgroundColor: Colors.red,
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
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucune adresse configurée'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ouverture de la carte : $e'),
            backgroundColor: Colors.red,
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
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucun numéro de téléphone configuré'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'appel : $e'),
            backgroundColor: Colors.red,
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
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucun numéro WhatsApp configuré'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ouverture de WhatsApp : $e'),
            backgroundColor: Colors.red,
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
      // Récupérer la configuration pour l'email de destination
      final config = await HomeConfigService.getHomeConfig();
      final contactEmail = config.contactEmail;

      if (contactEmail?.isNotEmpty == true) {
        // Créer le contenu de l'email
        final subject = 'Contact App Mobile: ${_subjectController.text}';
        final body = '''
Nouveau message depuis l'application mobile

Nom: ${_nameController.text}
Email: ${_emailController.text}
Sujet: ${_subjectController.text}

Message:
${_messageController.text}

---
Envoyé depuis l'application mobile Jubilé Tabernacle
        ''';

        final Uri emailUri = Uri(
          scheme: 'mailto',
          path: contactEmail,
          query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}'
        );

        if (await canLaunchUrl(emailUri)) {
          await launchUrl(emailUri);
          
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Application email ouverte avec votre message'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          // Fallback : copier le message dans le presse-papier
          await Clipboard.setData(ClipboardData(text: body));
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Message copié dans le presse-papier'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucun email de contact configuré'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: Colors.red,
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
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // En-tête
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.message_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nous contacter',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Envoyez-nous votre message',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
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
            
            const SizedBox(height: 24),
            
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
                      
                      const SizedBox(height: 16),
                      
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
                      
                      const SizedBox(height: 16),
                      
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
                      
                      const SizedBox(height: 16),
                      
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
            
            const SizedBox(height: 24),
            
            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      foregroundColor: Colors.white,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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


