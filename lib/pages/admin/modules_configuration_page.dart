import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/app_config_model.dart';
import '../../services/app_config_firebase_service.dart';
import '../../services/pages_firebase_service.dart';
import '../../theme.dart';
import '../../widgets/icon_selector.dart';

class ModulesConfigurationPage extends StatefulWidget {
  const ModulesConfigurationPage({super.key});

  @override
  State<ModulesConfigurationPage> createState() => _ModulesConfigurationPageState();
}

class _ModulesConfigurationPageState extends State<ModulesConfigurationPage> {
  AppConfigModel? _appConfig;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isResetting = false;
  List<ModuleConfig> _modules = [];
  List<PageConfig> _customPages = [];

  @override
  void initState() {
    super.initState();
    _loadConfiguration();
  }

  Future<void> _loadConfiguration() async {
    try {
      // Sync custom pages first to get latest pages
      await AppConfigFirebaseService.syncCustomPages();
      
      final config = await AppConfigFirebaseService.getAppConfig();
      setState(() {
        _appConfig = config;
        _modules = List.from(config.modules);
        _customPages = List.from(config.customPages);
        _isLoading = false;
      });
      
      // Debug: Afficher le nombre de pages trouvées
    } catch (e) {
      print('Erreur lors du chargement de la configuration: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveConfiguration() async {
    setState(() {
      _isSaving = true;
    });
    
    try {
      final updatedConfig = AppConfigModel(
        id: _appConfig!.id,
        modules: _modules,
        customPages: _customPages,
        generalSettings: _appConfig!.generalSettings,
        lastUpdated: DateTime.now(),
        lastUpdatedBy: _appConfig!.lastUpdatedBy,
      );
      
      await AppConfigFirebaseService.updateAppConfig(updatedConfig);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuration sauvegardée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _toggleModuleForMembers(int index) {
    setState(() {
      _modules[index] = _modules[index].copyWith(
        isEnabledForMembers: !_modules[index].isEnabledForMembers,
      );
    });
  }

  void _togglePrimaryInBottomNav(int index) {
    setState(() {
      final wasPrimary = _modules[index].isPrimaryInBottomNav;
      if (!wasPrimary) {
        // On coche : attribuer le prochain ordre disponible
        final usedOrders = _modules.where((m) => m.isPrimaryInBottomNav).map((m) => m.order).toList()
          ..addAll(_customPages.where((p) => p.isPrimaryInBottomNav).map((p) => p.order));
        int nextOrder = 1;
        while (usedOrders.contains(nextOrder)) {
          nextOrder++;
        }
        _modules[index] = _modules[index].copyWith(
          isPrimaryInBottomNav: true,
          order: nextOrder,
        );
      } else {
        // On décoche : retirer et réordonner les autres
        _modules[index] = _modules[index].copyWith(isPrimaryInBottomNav: false, order: 1);
        // Réordonner les modules/pages restants
        final List<ModuleConfig> primaryModules = _modules.where((m) => m.isPrimaryInBottomNav).toList();
        final List<PageConfig> primaryPages = _customPages.where((p) => p.isPrimaryInBottomNav).toList();
        int order = 1;
        for (int i = 0; i < primaryModules.length; i++) {
          final idx = _modules.indexWhere((m) => m.id == primaryModules[i].id);
          if (idx != -1) {
            _modules[idx] = _modules[idx].copyWith(order: order);
            order++;
          }
        }
        for (int i = 0; i < primaryPages.length; i++) {
          final idx = _customPages.indexWhere((p) => p.id == primaryPages[i].id);
          if (idx != -1) {
            _customPages[idx] = _customPages[idx].copyWith(order: order);
            order++;
          }
        }
      }
    });
  }

  void _updateModuleOrder(int index, int newOrder) {
    setState(() {
      _modules[index] = _modules[index].copyWith(order: newOrder);
    });
  }

  void _togglePageForMembers(int index) {
    setState(() {
      _customPages[index] = _customPages[index].copyWith(
        isEnabledForMembers: !_customPages[index].isEnabledForMembers,
      );
    });
  }

  void _togglePagePrimaryInBottomNav(int index) {
    setState(() {
      final wasPrimary = _customPages[index].isPrimaryInBottomNav;
      if (!wasPrimary) {
        // On coche : attribuer le prochain ordre disponible
        final usedOrders = _customPages.where((p) => p.isPrimaryInBottomNav).map((p) => p.order).toList()
          ..addAll(_modules.where((m) => m.isPrimaryInBottomNav).map((m) => m.order));
        int nextOrder = 1;
        while (usedOrders.contains(nextOrder)) {
          nextOrder++;
        }
        _customPages[index] = _customPages[index].copyWith(
          isPrimaryInBottomNav: true,
          order: nextOrder,
        );
      } else {
        // On décoche : retirer et réordonner les autres
        _customPages[index] = _customPages[index].copyWith(isPrimaryInBottomNav: false, order: 1);
        // Réordonner les modules/pages restants
        final List<ModuleConfig> primaryModules = _modules.where((m) => m.isPrimaryInBottomNav).toList();
        final List<PageConfig> primaryPages = _customPages.where((p) => p.isPrimaryInBottomNav).toList();
        int order = 1;
        for (int i = 0; i < primaryModules.length; i++) {
          final idx = _modules.indexWhere((m) => m.id == primaryModules[i].id);
          if (idx != -1) {
            _modules[idx] = _modules[idx].copyWith(order: order);
            order++;
          }
        }
        for (int i = 0; i < primaryPages.length; i++) {
          final idx = _customPages.indexWhere((p) => p.id == primaryPages[i].id);
          if (idx != -1) {
            _customPages[idx] = _customPages[idx].copyWith(order: order);
            order++;
          }
        }
      }
    });
  }

  void _updatePageOrder(int index, int newOrder) {
    setState(() {
      _customPages[index] = _customPages[index].copyWith(order: newOrder);
    });
  }

  Future<void> _resetConfiguration() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la réinitialisation'),
        content: const Text(
          'Êtes-vous sûr de vouloir réinitialiser la configuration aux valeurs par défaut ?\n\n'
          'Cette action va :\n'
          '• Remettre les modules avec leur configuration par défaut\n'
          '• Synchroniser les nouvelles pages du Constructeur de Pages\n'
          '• Cette action est irréversible',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isResetting = true;
      });

      try {
        await AppConfigFirebaseService.resetToDefault();
        await _loadConfiguration(); // Recharger la configuration
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Configuration réinitialisée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la réinitialisation: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isResetting = false;
          });
        }
      }
    }
  }

  Future<void> _syncCustomPages() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      print('🔄 Début synchronisation pages personnalisées...');
      
      // Récupérer toutes les pages disponibles
      final allPages = await PagesFirebaseService.getAllPages();
      
      // Synchroniser
      await AppConfigFirebaseService.syncCustomPages();
      
      // Recharger la configuration
      final config = await AppConfigFirebaseService.getAppConfig();
      setState(() {
        _appConfig = config;
        _modules = List.from(config.modules);
        _customPages = List.from(config.customPages);
      });
      
      print('✅ Pages personnalisées synchronisées: ${_customPages.length}');
      for (var page in _customPages) {
        print('  - Config: "${page.title}" (ID: ${page.id}, Slug: ${page.slug})');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_customPages.length} pages synchronisées avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur synchronisation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la synchronisation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Obtenir l'IconData pour un module à partir de son nom d'icône
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

      // Finance et dons
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

  /// Changer l'icône d'un module
  void _changeModuleIcon(int moduleIndex) {
    final module = _modules[moduleIndex];
    
    showDialog(
      context: context,
      builder: (context) => IconSelector(
        currentIcon: module.iconName,
        onIconSelected: (selectedIcon) {
          setState(() {
            _modules[moduleIndex] = ModuleConfig(
              id: module.id,
              name: module.name,
              description: module.description,
              iconName: selectedIcon,
              route: module.route,
              category: module.category,
              isEnabledForMembers: module.isEnabledForMembers,
              isPrimaryInBottomNav: module.isPrimaryInBottomNav,
              order: module.order,
              isBuiltIn: module.isBuiltIn,
            );
          });
        },
      ),
    );
  }

  /// Changer l'icône d'une page personnalisée
  void _changePageIcon(int pageIndex) {
    final page = _customPages[pageIndex];
    
    showDialog(
      context: context,
      builder: (context) => IconSelector(
        currentIcon: page.iconName,
        onIconSelected: (selectedIcon) {
          setState(() {
            _customPages[pageIndex] = PageConfig(
              id: page.id,
              title: page.title,
              description: page.description,
              iconName: selectedIcon,
              route: page.route,
              isEnabledForMembers: page.isEnabledForMembers,
              isPrimaryInBottomNav: page.isPrimaryInBottomNav,
              order: page.order,
              slug: page.slug,
              visibility: page.visibility,
              visibilityTargets: page.visibilityTargets,
            );
          });
        },
      ),
    );
  }

  Future<void> _updateModules() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Forcer la mise à jour de la configuration avec les nouveaux modules
      await AppConfigFirebaseService.initializeDefaultConfig();
      
      // Recharger la configuration
      await _loadConfiguration();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Modules mis à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Erreur lors de la mise à jour des modules: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à jour: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration des Modules'),
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_isResetting)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            IconButton(
              onPressed: _resetConfiguration,
              icon: const Icon(Icons.refresh),
              tooltip: 'Réinitialiser Config',
            ),
          IconButton(
            onPressed: _isLoading ? null : _syncCustomPages,
            icon: const Icon(Icons.sync),
            tooltip: 'Synchroniser Pages',
          ),
          IconButton(
            onPressed: _isLoading ? null : _updateModules,
            icon: const Icon(Icons.update),
            tooltip: 'Mettre à jour modules',
          ),
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            IconButton(
              onPressed: _saveConfiguration,
              icon: const Icon(Icons.save),
              tooltip: 'Sauvegarder',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: 24),
                  _buildModulesList(),
                  const SizedBox(height: 24),
                  _buildCustomPagesList(),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Information',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '• Cochez "Activé pour les membres" pour rendre un module/page accessible dans la vue membre',
              style: TextStyle(color: AppTheme.textSecondaryColor),
            ),
            const SizedBox(height: 4),
            Text(
              '• Cochez "Navigation principale" pour afficher le module/page dans la barre de navigation (maximum 5 éléments)',
              style: TextStyle(color: AppTheme.textSecondaryColor),
            ),
            const SizedBox(height: 4),
            Text(
              '• Les modules et pages non en navigation principale apparaîtront dans le menu "Plus"',
              style: TextStyle(color: AppTheme.textSecondaryColor),
            ),
            const SizedBox(height: 4),
            Text(
              '• Les pages personnalisées proviennent du module Constructeur de Pages',
              style: TextStyle(color: AppTheme.textSecondaryColor),
            ),
            const SizedBox(height: 4),
            Text(
              '• Cliquez sur l\'icône d\'un module ou d\'une page pour la changer parmi plus de 100 icônes disponibles',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModulesList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Modules disponibles',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            ..._modules.asMap().entries.map((entry) {
              final index = entry.key;
              final module = entry.value;
              return _buildModuleItem(module, index);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleItem(ModuleConfig module, int index) {
    final allPrimaryCount = _modules.where((m) => m.isPrimaryInBottomNav).length +
        _customPages.where((p) => p.isPrimaryInBottomNav).length;
    final canMakePrimary = !module.isPrimaryInBottomNav && allPrimaryCount < 5;
    final canRemoveFromPrimary = module.isPrimaryInBottomNav;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: module.isEnabledForMembers
            ? AppTheme.primaryColor.withOpacity(0.05)
            : Colors.grey[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icône cliquable pour changer
              InkWell(
                onTap: () => _changeModuleIcon(index),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getIconForModule(module.iconName),
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.edit,
                        color: AppTheme.primaryColor,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      module.name,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    Text(
                      module.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    // Afficher le nom de l'icône actuelle
                    Text(
                      'Icône: ${module.iconName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              if (module.isPrimaryInBottomNav)
                Chip(
                  label: Text(
                    'Menu principal',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: AppTheme.primaryColor,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Checkbox(
                      value: module.isEnabledForMembers,
                      onChanged: (value) => _toggleModuleForMembers(index),
                      activeColor: AppTheme.primaryColor,
                    ),
                    const Text('Membres'),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Checkbox(
                      value: module.isPrimaryInBottomNav,
                      onChanged: (canMakePrimary || canRemoveFromPrimary)
                          ? (value) => _togglePrimaryInBottomNav(index)
                          : null,
                      activeColor: AppTheme.primaryColor,
                    ),
                    Text(
                      'Menu principal',
                      style: TextStyle(
                        color: (canMakePrimary || canRemoveFromPrimary)
                            ? AppTheme.textPrimaryColor
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (module.isPrimaryInBottomNav) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Ordre: '),
                Expanded(
                  child: DropdownButton<int>(
                    value: module.order,
                    onChanged: (newOrder) {
                      if (newOrder != null) {
                        _updateModuleOrder(index, newOrder);
                      }
                    },
                    isExpanded: true,
                    items: List.generate(
                            (_modules.map((m) => m.order).fold<int>(0, (prev, e) => e > prev ? e : prev) + 1),
                            (i) => i)
                        .map((i) => DropdownMenuItem(
                              value: i,
                              child: Text('${i + 1}'),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomPagesList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.web, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Pages personnalisées',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Pages créées avec le Constructeur de Pages',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 16),
            if (_customPages.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[50],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.grey[600]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Aucune page personnalisée trouvée',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pour voir vos pages ici :',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '1. Allez dans le module Constructeur de Pages\n2. Créez ou modifiez une page\n3. Sauvegardez la page (même en brouillon)\n4. Revenez ici et actualisez',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        setState(() {
                          _isLoading = true;
                        });
                        await _loadConfiguration();
                      },
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Synchroniser les pages'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._customPages.asMap().entries.map((entry) {
                final index = entry.key;
                final page = entry.value;
                return _buildPageItem(page, index);
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPageItem(PageConfig page, int index) {
    final allPrimaryCount = _modules.where((m) => m.isPrimaryInBottomNav).length +
        _customPages.where((p) => p.isPrimaryInBottomNav).length;
    final canMakePrimary = !page.isPrimaryInBottomNav && allPrimaryCount < 4;
    final canRemoveFromPrimary = page.isPrimaryInBottomNav;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: page.isEnabledForMembers
            ? AppTheme.primaryColor.withOpacity(0.05)
            : Colors.grey[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icône cliquable pour changer
              InkWell(
                onTap: () => _changePageIcon(index),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getIconForModule(page.iconName),
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.edit,
                        color: AppTheme.primaryColor,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      page.title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    Text(
                      page.description.isNotEmpty ? page.description : 'Page personnalisée',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    // Afficher l'icône actuelle et la visibilité
                    Text(
                      'Icône: ${page.iconName} • Visibilité: ${_getVisibilityLabel(page.visibility)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              if (page.isPrimaryInBottomNav)
                Chip(
                  label: Text(
                    'Menu principal',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: AppTheme.primaryColor,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Checkbox(
                      value: page.isEnabledForMembers,
                      onChanged: (value) => _togglePageForMembers(index),
                      activeColor: AppTheme.primaryColor,
                    ),
                    const Text('Membres'),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Checkbox(
                      value: page.isPrimaryInBottomNav,
                      onChanged: (canMakePrimary || canRemoveFromPrimary)
                          ? (value) => _togglePagePrimaryInBottomNav(index)
                          : null,
                      activeColor: AppTheme.primaryColor,
                    ),
                    Text(
                      'Menu principal',
                      style: TextStyle(
                        color: (canMakePrimary || canRemoveFromPrimary)
                            ? AppTheme.textPrimaryColor
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (page.isPrimaryInBottomNav) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Ordre: '),
                Expanded(
                  child: DropdownButton<int>(
                    value: page.order,
                    onChanged: (newOrder) {
                      if (newOrder != null) {
                        _updatePageOrder(index, newOrder);
                      }
                    },
                    isExpanded: true,
                    items: List.generate(
                            (_customPages.map((p) => p.order).fold<int>(0, (prev, e) => e > prev ? e : prev) + 1),
                            (i) => i)
                        .map((i) => DropdownMenuItem(
                              value: i,
                              child: Text('${i + 1}'),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _getVisibilityLabel(String visibility) {
    switch (visibility) {
      case 'public':
        return 'Public';
      case 'members':
        return 'Membres connectés';
      case 'groups':
        return 'Groupes spécifiques';
      case 'roles':
        return 'Rôles spécifiques';
      default:
        return visibility;
    }
  }
}