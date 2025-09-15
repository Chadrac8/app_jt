import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_config_model.dart';
import '../widgets/user_avatar.dart';
import '../pages/initial_profile_setup_page.dart';

import '../models/person_model.dart';
import '../services/app_config_firebase_service.dart';

import '../auth/auth_service.dart';
import '../theme.dart';

import '../pages/member_dashboard_page.dart';
import '../modules/bible/bible_module_page.dart';

import '../pages/member_groups_page.dart';
import '../pages/member_events_page.dart';
import '../modules/services/views/member_services_page.dart';
import '../pages/member_forms_page.dart';
import '../pages/member_tasks_page.dart';

import '../pages/member_calendar_page.dart';
import '../pages/member_settings_page.dart';
import '../pages/member_pages_view.dart';
import '../pages/member_appointments_page.dart';
import '../pages/member_profile_page.dart';
import '../pages/member_prayer_wall_page.dart';
import '../modules/songs/views/member_songs_page.dart';
import '../pages/blog_home_page.dart';



import '../pages/member_dynamic_lists_page.dart';
import '../pages/message_page.dart';
import '../modules/vie_eglise/vie_eglise_module.dart';
import '../models/page_model.dart';
import '../services/pages_firebase_service.dart';

class BottomNavigationWrapper extends StatefulWidget {
  final String initialRoute;

  const BottomNavigationWrapper({
    super.key,
    this.initialRoute = 'dashboard',
  });

  @override
  State<BottomNavigationWrapper> createState() => _BottomNavigationWrapperState();
}

class _BottomNavigationWrapperState extends State<BottomNavigationWrapper> {
  String _currentRoute = 'dashboard';
  AppConfigModel? _appConfig;
  List<dynamic> _overflowPrimaryItems = []; // Modules primaires qui ne peuvent pas être affichés
  int? _lastDebugLog; // Pour limiter les logs de debug

  // Méthode publique pour permettre la navigation depuis les modules enfants
  void navigateToRoute(String route) {
    setState(() {
      _currentRoute = route;
    });
  }

  PersonModel? _currentUser;
  bool _isLoading = true;
  int _unreadNotificationsCount = 0;

  /// Check if user profile is complete with all required fields
  bool _isProfileComplete(PersonModel? profile) {
    if (profile == null) return false;
    
    try {
      // Required fields for profile completion (synchronized with AuthWrapper)
      final hasFirstName = profile.firstName.isNotEmpty;
      final hasLastName = profile.lastName.isNotEmpty;
      final hasPhone = profile.phone != null && profile.phone!.isNotEmpty;
      final hasAddress = profile.address != null && profile.address!.isNotEmpty;
      final hasBirthDate = profile.birthDate != null;
      final hasGender = profile.gender != null && profile.gender!.isNotEmpty;
      
      final isComplete = hasFirstName && hasLastName && hasPhone && hasAddress && hasBirthDate && hasGender;
      
      if (!isComplete) {
        print('🔄 BottomNavigationWrapper: Profil incomplet détecté');
        print('  - Prénom: ${hasFirstName ? "✅" : "❌"}');
        print('  - Nom: ${hasLastName ? "✅" : "❌"}');
        print('  - Téléphone: ${hasPhone ? "✅" : "❌"}');
        print('  - Adresse: ${hasAddress ? "✅" : "❌"}');
        print('  - Date de naissance: ${hasBirthDate ? "✅" : "❌"}');
        print('  - Genre: ${hasGender ? "✅" : "❌"}');
      }
      
      return isComplete;
    } catch (e) {
      print('❌ Error checking profile completion in BottomNavigationWrapper: $e');
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _currentRoute = widget.initialRoute;
    _loadConfiguration();
    _loadUnreadNotificationsCount();
  }

  Future<void> _loadConfiguration() async {
    try {
      // Charger la configuration de l'app
      final config = await AppConfigFirebaseService.getAppConfig();
      
      // Charger l'utilisateur actuel et ses rôles/groupes
      await _loadUserData();
      
      setState(() {
        _appConfig = config;
        _isLoading = false;
      });
      

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserData() async {
    final user = AuthService.currentUser;
    if (user != null) {
      try {
        // Charger les données de la personne
        final person = await AuthService.getCurrentUserProfile();
        if (person != null) {
          _currentUser = person;
          
          // TODO: Charger les groupes de l'utilisateur
          // Implémenter la logique pour récupérer les groupes
        }
      } catch (e) {
        print('Erreur lors du chargement des données utilisateur: $e');
      }
    }
  }

  Future<void> _loadUnreadNotificationsCount() async {
    try {
      // Notifications module removed - set count to 0
      if (mounted) {
        setState(() {
          _unreadNotificationsCount = 0;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement du nombre de notifications: $e');
    }
  }



  Widget _getPageForRoute(String route) {
    // Routes par défaut
    switch (route) {
      case 'dashboard':
        return const MemberDashboardPage();

      case 'bible':
        return const BibleModulePage();

      case 'groups':
        return const MemberGroupsPage();
      case 'events':
        return const MemberEventsPage();
      case 'services':
        return const MemberServicesPage();
      case 'forms':
        return const MemberFormsPage();
      case 'tasks':
        return const MemberTasksPage();


      // case 'automation':
      //   return const MemberAutomationPage();
      case 'reports':
        return Scaffold(
          appBar: AppBar(title: const Text('Rapports')),
          body: const Center(child: Text('Module Rapports - En cours de développement')),
        );
      case 'appointments':
        return const MemberAppointmentsPage();
      case 'prayers':
        return const MemberPrayerWallPage();
      case 'songs':
        return const MemberSongsPage();
      case 'blog':
        return const BlogHomePage();
      case 'calendar':
        return const MemberCalendarPage();
      case 'notifications':
        // Notifications module removed - redirect to dashboard
        return const MemberDashboardPage();
      case 'settings':
        return const MemberSettingsPage();
      case 'pages':
        return const MemberPagesView();
      case 'dynamic_lists':
        return const MemberDynamicListsPage();
      case 'message':
        return const MessagePage();
      case 'vie-eglise':
        return const VieEgliseModule();
      default:
        // Check if it's a custom page route
        if (route.startsWith('custom_page/')) {
          final slug = route.substring('custom_page/'.length);
          return CustomPageDirectView(
            key: ValueKey('custom_page_$slug'),
            pageSlug: slug,
          );
        }
        return const MemberDashboardPage();
    }
  }

  IconData _getIconForModule(String iconName) {
    switch (iconName) {
      // Personnes et groupes
      case 'people':
        return Icons.people;
      case 'person':
        return Icons.person;
      case 'groups':
        return Icons.groups;
      case 'group_add':
        return Icons.group_add;
      case 'person_add':
        return Icons.person_add;
      case 'family_restroom':
        return Icons.family_restroom;
      case 'diversity_1':
        return Icons.diversity_1;
      case 'supervisor_account':
        return Icons.supervisor_account;
      case 'account_circle':
        return Icons.account_circle;
      case 'face':
        return Icons.face;

      // Événements et calendrier
      case 'event':
        return Icons.event;
      case 'calendar_today':
        return Icons.calendar_today;
      case 'calendar_month':
        return Icons.calendar_month;
      case 'event_available':
        return Icons.event_available;
      case 'event_busy':
        return Icons.event_busy;
      case 'schedule':
        return Icons.schedule;
      case 'today':
        return Icons.today;
      case 'date_range':
        return Icons.date_range;
      case 'access_time':
        return Icons.access_time;
      case 'timer':
        return Icons.timer;

      // Religion et spiritualité
      case 'church':
        return Icons.church;
      case 'menu_book':
      case 'bible':
        return Icons.menu_book;
      case 'book':
        return Icons.book;
      case 'library_books':
        return Icons.library_books;
      case 'auto_stories':
        return Icons.auto_stories;
      case 'favorite':
      case 'prayer_hands':
        return Icons.favorite;
      case 'volunteer_activism':
        return Icons.volunteer_activism;
      case 'handshake':
        return Icons.handshake;
      case 'emoji_people':
        return Icons.emoji_people;
      case 'celebration':
        return Icons.celebration;
      case 'self_improvement':
        return Icons.self_improvement;
      case 'psychology':
        return Icons.psychology;
      case 'healing':
        return Icons.healing;
      case 'diversity_3':
        return Icons.diversity_3;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'water_drop':
        return Icons.water_drop;
      case 'sentiment_very_satisfied':
        return Icons.sentiment_very_satisfied;
      case 'eco':
        return Icons.eco;
      case 'local_florist':
        return Icons.local_florist;
      case 'nights_stay':
        return Icons.nights_stay;
      case 'campaign':
        return Icons.campaign;
      case 'grade':
        return Icons.grade;
      case 'brightness_7':
        return Icons.brightness_7;
      case 'spa':
        return Icons.spa;
      case 'child_care':
        return Icons.child_care;
      case 'forum':
        return Icons.forum;
      case 'record_voice_over':
        return Icons.record_voice_over;
      case 'sentiment_satisfied_alt':
        return Icons.sentiment_satisfied_alt;
      case 'auto_awesome':
        return Icons.auto_awesome;
      case 'wb_sunny':
        return Icons.wb_sunny;
      case 'light_mode':
        return Icons.light_mode;
      case 'favorite_border':
        return Icons.favorite_border;
      case 'emoji_emotions':
        return Icons.emoji_emotions;
      case 'groups_2':
        return Icons.groups_2;
      case 'support':
        return Icons.support;
      case 'hub':
        return Icons.hub;
      case 'landscape':
        return Icons.landscape;
      case 'emoji_nature':
        return Icons.emoji_nature;
      case 'psychology_alt':
        return Icons.psychology_alt;
      case 'connect_without_contact':
        return Icons.connect_without_contact;
      case 'coronavirus':
        return Icons.coronavirus;
      case 'clean_hands':
        return Icons.clean_hands;
      case 'health_and_safety':
        return Icons.health_and_safety;

      // Musique et worship
      case 'library_music':
        return Icons.library_music;
      case 'music_note':
        return Icons.music_note;
      case 'queue_music':
        return Icons.queue_music;
      case 'piano':
        return Icons.piano;
      case 'mic':
        return Icons.mic;
      case 'volume_up':
        return Icons.volume_up;
      case 'headphones':
        return Icons.headphones;
      case 'radio':
        return Icons.radio;
      case 'surround_sound':
        return Icons.surround_sound;
      case 'graphic_eq':
        return Icons.graphic_eq;

      // Tâches et gestion
      case 'task_alt':
        return Icons.task_alt;
      case 'assignment':
        return Icons.assignment;
      case 'checklist':
        return Icons.checklist;
      case 'check_circle':
        return Icons.check_circle;
      case 'pending_actions':
        return Icons.pending_actions;
      case 'work':
        return Icons.work;
      case 'business_center':
        return Icons.business_center;
      case 'folder_open':
        return Icons.folder_open;
      case 'description':
        return Icons.description;
      case 'list_alt':
        return Icons.list_alt;

      // Communication et notifications
      case 'notifications':
        return Icons.notifications;
      case 'message':
        return Icons.message;
      case 'chat':
        return Icons.chat;
      case 'email':
        return Icons.email;
      case 'phone':
        return Icons.phone;
      case 'announcement':
        return Icons.announcement;
      case 'speaker_notes':
        return Icons.speaker_notes;

      // Navigation et interface
      case 'dashboard':
        return Icons.dashboard;
      case 'home':
        return Icons.home;
      case 'menu':
        return Icons.menu;
      case 'apps':
        return Icons.apps;
      case 'widgets':
        return Icons.widgets;
      case 'view_module':
        return Icons.view_module;
      case 'grid_view':
        return Icons.grid_view;
      case 'list':
        return Icons.list;
      case 'view_list':
        return Icons.view_list;
      case 'table_view':
        return Icons.table_view;

      // Paramètres et configuration
      case 'settings':
        return Icons.settings;
      case 'tune':
        return Icons.tune;
      case 'build':
        return Icons.build;
      case 'engineering':
        return Icons.engineering;
      case 'admin_panel_settings':
        return Icons.admin_panel_settings;
      case 'security':
        return Icons.security;
      case 'lock':
        return Icons.lock;
      case 'key':
        return Icons.key;
      case 'vpn_key':
        return Icons.vpn_key;
      case 'password':
        return Icons.password;

      // Médias et contenu
      case 'photo_library':
        return Icons.photo_library;
      case 'video_library':
        return Icons.video_library;
      case 'play_circle':
        return Icons.play_circle;
      case 'pause_circle':
        return Icons.pause_circle;
      case 'stop_circle':
        return Icons.stop_circle;
      case 'movie':
        return Icons.movie;
      case 'camera_alt':
        return Icons.camera_alt;
      case 'videocam':
        return Icons.videocam;
      case 'photo_camera':
        return Icons.photo_camera;
      case 'perm_media':
        return Icons.perm_media;

      // Finance
      case 'attach_money':
        return Icons.attach_money;
      case 'payment':
        return Icons.payment;
      case 'account_balance':
        return Icons.account_balance;
      case 'savings':
        return Icons.savings;
      case 'monetization_on':
        return Icons.monetization_on;
      case 'card_giftcard':
        return Icons.card_giftcard;
      case 'redeem':
        return Icons.redeem;
      case 'receipt':
        return Icons.receipt;
      case 'request_quote':
        return Icons.request_quote;

      // Transport et localisation
      case 'location_on':
        return Icons.location_on;
      case 'map':
        return Icons.map;
      case 'directions':
        return Icons.directions;
      case 'place':
        return Icons.place;
      case 'room':
        return Icons.room;
      case 'business':
        return Icons.business;
      case 'store':
        return Icons.store;
      case 'local_shipping':
        return Icons.local_shipping;
      case 'flight':
        return Icons.flight;
      case 'directions_car':
        return Icons.directions_car;

      // Éducation et formation
      case 'school':
        return Icons.school;
      case 'classroom':
        return Icons.school;
      case 'quiz':
        return Icons.quiz;
      case 'science':
        return Icons.science;
      case 'lightbulb':
        return Icons.lightbulb;
      case 'tips_and_updates':
        return Icons.tips_and_updates;
      case 'help':
        return Icons.help;
      case 'info':
        return Icons.info;

      // Technologie et digital
      case 'computer':
        return Icons.computer;
      case 'smartphone':
        return Icons.smartphone;
      case 'tablet':
        return Icons.tablet;
      case 'web':
        return Icons.web;
      case 'wifi':
        return Icons.wifi;
      case 'cloud':
        return Icons.cloud;
      case 'backup':
        return Icons.backup;
      case 'download':
        return Icons.download;
      case 'upload':
        return Icons.upload;
      case 'sync':
        return Icons.sync;

      // Divers et utilitaires
      case 'star':
        return Icons.star;
      case 'bookmark':
        return Icons.bookmark;
      case 'flag':
        return Icons.flag;
      case 'label':
        return Icons.label;
      case 'new_releases':
        return Icons.new_releases;
      case 'trending_up':
        return Icons.trending_up;
      case 'trending_down':
        return Icons.trending_down;
      case 'insights':
        return Icons.insights;
      case 'analytics':
        return Icons.analytics;
      case 'assessment':
        return Icons.assessment;
      case 'bar_chart':
        return Icons.bar_chart;
      case 'article':
        return Icons.article;

      default:
        return Icons.apps;
    }
  }



  void _showMoreMenu() {
    final secondaryModules = _appConfig?.secondaryModules ?? [];
    final secondaryPages = _appConfig?.secondaryPages ?? [];
    
    // Combiner les modules primaires qui ont débordé avec les modules secondaires
    final allSecondaryItems = <dynamic>[
      ..._overflowPrimaryItems, // Modules primaires qui n'ont pas pu être affichés
      ...secondaryModules,
      ...secondaryPages
    ];
    
    // DÉDUPLICATION: Supprimer les doublons basés sur l'ID
    final seen = <String>{};
    final deduplicatedItems = <dynamic>[];
    
    for (final item in allSecondaryItems) {
      String itemId;
      if (item is ModuleConfig) {
        itemId = item.id;
      } else if (item is PageConfig) {
        itemId = item.id;
      } else {
        continue; // Skip items that are neither ModuleConfig nor PageConfig
      }
      
      if (!seen.contains(itemId)) {
        seen.add(itemId);
        deduplicatedItems.add(item);
      }
    }
    
    // Trier par ordre (modules débordés d'abord, puis secondaires)
    deduplicatedItems.sort((a, b) {
      final isAOverflow = _overflowPrimaryItems.contains(a);
      final isBOverflow = _overflowPrimaryItems.contains(b);
      
      // Si un des deux est un module débordé, il passe en premier
      if (isAOverflow && !isBOverflow) return -1;
      if (!isAOverflow && isBOverflow) return 1;
      
      // Sinon, tri par ordre normal
      final orderA = a is ModuleConfig ? a.order : (a as PageConfig).order;
      final orderB = b is ModuleConfig ? b.order : (b as PageConfig).order;
      return orderA.compareTo(orderB);
    });
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: EdgeInsets.symmetric(vertical: 8),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.more_horiz, color: AppTheme.primaryColor),
                    SizedBox(width: 8),
                    Text(
                      'Plus de modules',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (deduplicatedItems.isEmpty)
                Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.apps, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Aucun module ou page secondaire configuré',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              else
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      controller: scrollController,
                      physics: AlwaysScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1.2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: deduplicatedItems.length,
                      itemBuilder: (context, index) {
                        final item = deduplicatedItems[index];
                        if (item is ModuleConfig) {
                          return _buildModuleCard(item);
                        } else if (item is PageConfig) {
                          return _buildPageCard(item);
                        }
                        return Container();
                      },
                    ),
                  ),
                ),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModuleCard(ModuleConfig module) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        setState(() {
          _currentRoute = module.route;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconForModule(module.iconName),
              size: 32,
              color: AppTheme.primaryColor,
            ),
            SizedBox(height: 8),
            Text(
              module.name,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryColor,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageCard(PageConfig page) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        setState(() {
          _currentRoute = page.route;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconForModule(page.iconName),
              size: 32,
              color: AppTheme.primaryColor,
            ),
            SizedBox(height: 8),
            Text(
              page.title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryColor,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    // Check if profile is complete before showing main interface
    if (!_isLoading && !_isProfileComplete(_currentUser)) {
      print('🔄 BottomNavigationWrapper: Profil incomplet, redirection vers configuration');
      return const InitialProfileSetupPage();
    }
    
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_appConfig == null) {
      return const Scaffold(
        body: Center(
          child: Text('Erreur de configuration'),
        ),
      );
    }

    final primaryModules = _appConfig!.primaryBottomNavModules;

    return Scaffold(
      appBar: _buildAppBar(),
      body: _getPageForRoute(_currentRoute),
      bottomNavigationBar: _buildBottomNavigationBar(primaryModules),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF860505), // Rouge bordeaux #860505
      elevation: 0,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // Icônes claires pour fond rouge
        statusBarBrightness: Brightness.dark, // Pour iOS
      ),
      leading: Padding(
        padding: const EdgeInsets.only(left: 12, right: 4),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(4),
          child: Image.asset(
            'assets/logo_jt.png',
            height: 32,
            width: 32,
            fit: BoxFit.contain,
          ),
        ),
      ),
      centerTitle: true,
      title: Text(
        _getPageTitle(),
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white, // Texte blanc sur fond rouge
        ),
      ),
      actions: [
        // Notifications avec badge
        _buildNotificationButton(),
        // Icône Mon profil
        IconButton(
          onPressed: _showProfileMenu,
          icon: NavigationUserAvatar(
            person: _currentUser,
            onTap: _showProfileMenu,
          ),
        ),
      ],
    );
  }

  String _getPageTitle() {
    // Check if it's a custom page route
    if (_currentRoute.startsWith('custom_page/')) {
      final slug = _currentRoute.substring('custom_page/'.length);
      final page = _appConfig?.customPages.firstWhere(
        (p) => p.slug == slug,
        orElse: () => PageConfig(id: '', title: 'Page personnalisée', description: '', iconName: 'web', route: '', slug: slug),
      );
      return page?.title ?? 'Page personnalisée';
    }
    
    switch (_currentRoute) {
      case 'dashboard':
        return 'Accueil';
      case 'groups':
        return 'Mes Groupes';
      case 'events':
        return 'Mes Événements';
      case 'services':
        return 'Mes Services';
      case 'forms':
        return 'Formulaires';
      case 'tasks':
        return 'Mes Tâches';

      case 'automation':
        return 'Automatisations';

      case 'calendar':
        return 'Calendrier';
      case 'appointments':
        return 'Mes Rendez-vous';
      case 'pages':
        return 'Pages';
      case 'prayers':
        return 'Mur de Prière';
      case 'songs':
        return 'Cantiques';
      case 'blog':
        return 'Blog';
      case 'notifications':
        return 'Notifications';
      case 'settings':
        return 'Paramètres';
      case 'dynamic_lists':
        return 'Listes Dynamiques';
      case 'bible':
        return 'La Bible';
      case 'message':
        return 'Le Message';
      case 'vie-eglise':
        return 'Vie de l\'Église';
      default:
        return 'ChurchFlow';
    }
  }

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProfileMenuSheet(
        currentUser: _currentUser,
        onNavigate: (route) {
          Navigator.pop(context);
          setState(() {
            _currentRoute = route;
          });
        },
        onEditProfile: () {
          Navigator.pop(context);
          _navigateToEditProfile();
        },
      ),
    );
  }

  void _navigateToEditProfile() {
    if (_currentUser != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MemberProfilePage(person: _currentUser),
        ),
      );
    }
  }

  Widget _buildNotificationButton() {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications, color: Colors.white),
          tooltip: 'Notifications',
          onPressed: () {
            setState(() {
              _currentRoute = 'notifications';
            });
            // Réinitialiser le count quand on clique
            _loadUnreadNotificationsCount();
          },
        ),
        if (_unreadNotificationsCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                _unreadNotificationsCount > 99 ? '99+' : _unreadNotificationsCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomNavigationBar(List<ModuleConfig> primaryModules) {
    final primaryPages = _appConfig?.primaryBottomNavPages ?? [];
    final allPrimaryItems = <dynamic>[...primaryModules, ...primaryPages];
    
    // Sort by order
    allPrimaryItems.sort((a, b) {
      final orderA = a is ModuleConfig ? a.order : (a as PageConfig).order;
      final orderB = b is ModuleConfig ? b.order : (b as PageConfig).order;
      return orderA.compareTo(orderB);
    });
    
    // Déterminer combien d'éléments primaires on peut afficher
    final secondaryModules = _appConfig?.secondaryModules ?? [];
    final secondaryPages = _appConfig?.secondaryPages ?? [];
    final hasMoreItems = secondaryModules.isNotEmpty || secondaryPages.isNotEmpty;
    
    // Calculer le nombre max d'éléments selon la contrainte de Flutter
    // BottomNavigationBar peut afficher jusqu'à 5 éléments total
    final maxTotalItems = 5;
    final maxPrimaryItems = hasMoreItems ? (maxTotalItems - 1) : maxTotalItems; // -1 pour le bouton "Plus" si nécessaire
    
    final finalItems = allPrimaryItems.take(maxPrimaryItems).toList();
    
    // Si on a plus d'éléments primaires que l'espace disponible, on doit en déplacer vers secondaire
    final remainingPrimaryItems = allPrimaryItems.skip(maxPrimaryItems).toList();
    final hasMorePrimaryItems = remainingPrimaryItems.isNotEmpty;
    final shouldShowMoreButton = hasMoreItems || hasMorePrimaryItems;
    
    // Stocker les modules qui débordent pour le menu "Plus"
    _overflowPrimaryItems = remainingPrimaryItems;
    final allRoutes = <String>[];
    
    // Debug info (reduced logging to prevent console spam)
    if (kDebugMode) {
      // Only log once every 30 seconds to prevent spam
      final now = DateTime.now().millisecondsSinceEpoch;
      if (_lastDebugLog == null || (now - _lastDebugLog!) > 30000) {
        _lastDebugLog = now;
        print('=== DEBUG BOTTOM NAV ===');
        print('Primary modules: ${primaryModules.length}, Pages: ${primaryPages.length}');
        print('Should show More button: $shouldShowMoreButton');
        print('Final items count: ${finalItems.length}');
        print('=======================');
      }
    }
    
    // Removed excessive debug logs for custom pages to prevent console spam
    
    if (finalItems.isEmpty) {
      return BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
        ],
      );
    }
    
    // Construire les BottomNavigationBarItem
    final navItems = <BottomNavigationBarItem>[];
    
    for (final item in finalItems) {
      if (item is ModuleConfig) {
        navItems.add(BottomNavigationBarItem(
          icon: Icon(_getIconForModule(item.iconName)),
          label: item.name,
        ));
        allRoutes.add(item.route);
      } else if (item is PageConfig) {
        navItems.add(BottomNavigationBarItem(
          icon: Icon(_getIconForModule(item.iconName)),
          label: item.title,
        ));
        allRoutes.add(item.route);
      }
    }
    
    // Ajouter "Plus" si nécessaire
    if (shouldShowMoreButton) {
      navItems.add(BottomNavigationBarItem(
        icon: Icon(Icons.more_horiz),
        label: 'Plus',
      ));
      allRoutes.add('more');
    }
    
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _getCurrentIndex(allRoutes),
      onTap: (index) {
        if (allRoutes[index] == 'more') {
          _showMoreMenu();
        } else {
          setState(() {
            _currentRoute = allRoutes[index];
          });
        }
      },
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: AppTheme.textSecondaryColor,
      items: navItems,
    );
  }

  int _getCurrentIndex(List<String> routes) {
    final index = routes.indexWhere((route) => route == _currentRoute);
    return index != -1 ? index : 0;
  }
}

class _ProfileMenuSheet extends StatelessWidget {
  final PersonModel? currentUser;
  final Function(String) onNavigate;
  final VoidCallback onEditProfile;

  const _ProfileMenuSheet({
    required this.currentUser,
    required this.onNavigate,
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              height: 4,
              width: 48,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header avec profil
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Photo de profil
                  UserAvatar(
                    person: currentUser,
                    radius: 30,
                    showBorder: true,
                    borderColor: AppTheme.primaryColor.withOpacity(0.2),
                  ),
                  const SizedBox(width: 16),
                  
                  // Informations utilisateur
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentUser?.fullName ?? 'Utilisateur',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentUser?.email ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                        if (currentUser?.roles.isNotEmpty == true) ...[
                          const SizedBox(height: 4),
                          Text(
                            currentUser!.roles.join(' • '),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Bouton éditer
                  IconButton(
                    onPressed: onEditProfile,
                    icon: const Icon(
                      Icons.edit,
                      color: AppTheme.primaryColor,
                    ),
                    tooltip: 'Éditer mon profil',
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1),
            
            // Menu items relatifs au profil
            ..._buildProfileMenuItems(context),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildProfileMenuItems(BuildContext context) {
    final profileModules = [
      {
        'title': 'Mes Informations',
        'subtitle': 'Voir et modifier mes informations personnelles',
        'icon': Icons.person_outline,
        'action': () => onEditProfile(),
      },
      {
        'title': 'Mes Groupes',
        'subtitle': 'Groupes auxquels je participe',
        'icon': Icons.groups_outlined,
        'action': () => onNavigate('groups'),
      },
      {
        'title': 'Mes Services',
        'subtitle': 'Services et affectations',
        'icon': Icons.church_outlined,
        'action': () => onNavigate('services'),
      },
      {
        'title': 'Mes Événements',
        'subtitle': 'Événements auxquels je participe',
        'icon': Icons.event_outlined,
        'action': () => onNavigate('events'),
      },
      {
        'title': 'Mes Tâches',
        'subtitle': 'Tâches qui me sont assignées',
        'icon': Icons.task_alt_outlined,
        'action': () => onNavigate('tasks'),
      },
      {
        'title': 'Mes Rendez-vous',
        'subtitle': 'Gérer mes rendez-vous',
        'icon': Icons.event_available_outlined,
        'action': () => onNavigate('appointments'),
      },
      {
        'title': 'Mon Calendrier',
        'subtitle': 'Vue d\'ensemble de mes activités',
        'icon': Icons.calendar_today_outlined,
        'action': () => onNavigate('calendar'),
      },
      {
        'title': 'Paramètres',
        'subtitle': 'Configuration de l\'application',
        'icon': Icons.settings_outlined,
        'action': () => onNavigate('settings'),
      },
    ];

    return profileModules.map((module) => _buildMenuItem(
      title: module['title'] as String,
      subtitle: module['subtitle'] as String,
      icon: module['icon'] as IconData,
      onTap: module['action'] as VoidCallback,
    )).toList();
  }

  Widget _buildMenuItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
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
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimaryColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 13,
          color: AppTheme.textSecondaryColor,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppTheme.textTertiaryColor,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}

// Widget pour afficher directement une page personnalisée
class CustomPageDirectView extends StatefulWidget {
  final String pageSlug;
  
  const CustomPageDirectView({
    super.key,
    required this.pageSlug,
  });

  @override
  @override
  State<CustomPageDirectView> createState() => _CustomPageDirectViewState();
}

class _CustomPageDirectViewState extends State<CustomPageDirectView> {
  CustomPageModel? _page;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPage();
  }

  Future<void> _loadPage() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final page = await PagesFirebaseService.getPageBySlug(widget.pageSlug);
      
      if (page != null && page.isVisible) {
        setState(() {
          _page = page;
          _isLoading = false;
        });
        
        // Enregistrer la vue de la page
        try {
          await PagesFirebaseService.recordPageView(page.id, null);
        } catch (e) {
          // Erreur silencieuse pour les statistiques
        }
      } else {
        setState(() {
          _errorMessage = 'Page non trouvée ou non disponible';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadPage,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_page == null) {
      return const Scaffold(
        body: Center(
          child: Text('Page non trouvée'),
        ),
      );
    }

    // Retourner directement le contenu de la page sans navigation wrapper
    return MemberPageDetailView(page: _page!);
  }
}