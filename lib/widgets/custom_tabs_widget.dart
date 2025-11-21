import 'package:flutter/material.dart';
import '../models/page_model.dart';
import 'page_components/component_renderer.dart';
import '../../theme.dart';

/// Widget pour afficher des onglets avec sous-pages
class CustomTabsWidget extends StatefulWidget {
  final PageComponent component;
  final bool isPreview;

  const CustomTabsWidget({
    super.key,
    required this.component,
    this.isPreview = false,
  });

  @override
  State<CustomTabsWidget> createState() => _CustomTabsWidgetState();
}

class _CustomTabsWidgetState extends State<CustomTabsWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late List<TabData> _tabs;

  @override
  void initState() {
    super.initState();
    _initializeTabs();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeTabs() {
    final tabsData = widget.component.data['tabs'] as List<dynamic>? ?? [];
    _tabs = tabsData.map((tab) {
      final tabMap = tab as Map<String, dynamic>;
      return TabData.fromMap(tabMap);
    }).toList();

    // Si aucun onglet n'est défini, créer un onglet par défaut
    if (_tabs.isEmpty) {
      _tabs = [
        TabData(
          id: 'tab_1',
          title: 'Onglet 1',
          icon: Icons.tab,
          components: [],
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_tabs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.grey500),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: const Text(
          'Aucun onglet configuré',
          style: TextStyle(
            color: AppTheme.grey500,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    final tabPosition = widget.component.data['tabPosition'] ?? 'top';
    final showIcons = widget.component.data['showIcons'] ?? true;
    final tabStyle = widget.component.data['tabStyle'] ?? 'material';
    final backgroundColor = Color(int.parse(
      widget.component.styling['backgroundColor']?.replaceAll('#', '0xFF') ?? '0xFFFFFFFF'
    ));
    final indicatorColor = Color(int.parse(
      widget.component.styling['indicatorColor']?.replaceAll('#', '0xFF') ?? '0xFF1976D2'
    ));

    return Container(
      height: widget.component.data['height']?.toDouble() ?? 400.0, // Hauteur par défaut
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: _buildTabsInterface(
        tabPosition: tabPosition,
        showIcons: showIcons,
        tabStyle: tabStyle,
        indicatorColor: indicatorColor,
      ),
    );
  }

  Widget _buildTabsInterface({
    required String tabPosition,
    required bool showIcons,
    required String tabStyle,
    required Color indicatorColor,
  }) {
    final tabBar = Container(
      color: AppTheme.primaryColor, // Couleur d'arrière-plan identique à l'AppBar
      child: TabBar(
        controller: _tabController,
        isScrollable: _tabs.length > 3,
        indicatorColor: AppTheme.onPrimaryColor, // Indicateur blanc sur fond primaire
        labelColor: AppTheme.onPrimaryColor, // Texte blanc pour onglet sélectionné
        unselectedLabelColor: AppTheme.onPrimaryColor.withOpacity(0.7), // Texte blanc semi-transparent
        tabs: _tabs.map((tab) => Tab(
          icon: showIcons ? Icon(tab.icon) : null,
          text: tab.title,
        )).toList(),
      ),
    );

    final tabBarView = TabBarView(
      controller: _tabController,
      children: _tabs.map((tab) => _buildTabContent(tab)).toList(),
    );

    switch (tabPosition) {
      case 'bottom':
        return Column(
          children: [
            Expanded(child: tabBarView),
            tabBar,
          ],
        );
      case 'left':
      case 'right':
        return Row(
          children: [
            if (tabPosition == 'left') ...[
              RotatedBox(
                quarterTurns: -1,
                child: SizedBox(
                  width: 200,
                  child: tabBar,
                ),
              ),
              Expanded(child: tabBarView),
            ] else ...[
              Expanded(child: tabBarView),
              RotatedBox(
                quarterTurns: 1,
                child: SizedBox(
                  width: 200,
                  child: tabBar,
                ),
              ),
            ],
          ],
        );
      default: // 'top'
        return Column(
          children: [
            tabBar,
            Expanded(child: tabBarView),
          ],
        );
    }
  }

  Widget _buildTabContent(TabData tab) {
    if (tab.components.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.spaceXLarge),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.dashboard_customize_outlined,
                size: 48,
                color: AppTheme.grey500,
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              Text(
                'Onglet "${tab.title}" vide',
                style: TextStyle(
                  fontSize: AppTheme.fontSize16,
                  color: AppTheme.grey500,
                  fontWeight: AppTheme.fontMedium,
                ),
              ),
              const SizedBox(height: AppTheme.spaceSmall),
              Text(
                'Ajoutez des composants pour créer le contenu',
                style: TextStyle(
                  fontSize: AppTheme.fontSize14,
                  color: AppTheme.grey500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      child: Column(
        children: tab.components.map((component) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ComponentRenderer(
              component: component,
              isPreview: widget.isPreview,
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Modèle de données pour un onglet
class TabData {
  final String id;
  final String title;
  final IconData icon;
  final List<PageComponent> components;
  final bool isVisible;
  final Map<String, dynamic> settings;

  TabData({
    required this.id,
    required this.title,
    this.icon = Icons.tab,
    this.components = const [],
    this.isVisible = true,
    this.settings = const {},
  });

  factory TabData.fromMap(Map<String, dynamic> map) {
    // Conversion des composants depuis la map
    final componentsData = map['components'] as List<dynamic>? ?? [];
    final components = componentsData
        .map((comp) => PageComponent.fromMap(comp as Map<String, dynamic>))
        .toList();

    return TabData(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      icon: _getIconFromString(map['icon'] ?? 'tab'),
      components: components,
      isVisible: map['isVisible'] ?? true,
      settings: Map<String, dynamic>.from(map['settings'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'icon': _getStringFromIcon(icon),
      'components': components.map((comp) => comp.toMap()).toList(),
      'isVisible': isVisible,
      'settings': settings,
    };
  }

  TabData copyWith({
    String? id,
    String? title,
    IconData? icon,
    List<PageComponent>? components,
    bool? isVisible,
    Map<String, dynamic>? settings,
  }) {
    return TabData(
      id: id ?? this.id,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      components: components ?? this.components,
      isVisible: isVisible ?? this.isVisible,
      settings: settings ?? this.settings,
    );
  }

  static IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'home': return Icons.home;
      case 'person': return Icons.person;
      case 'settings': return Icons.settings;
      case 'info': return Icons.info;
      case 'help': return Icons.help;
      case 'star': return Icons.star;
      case 'favorite': return Icons.favorite;
      case 'bookmark': return Icons.bookmark;
      case 'calendar': return Icons.calendar_today;
      case 'phone': return Icons.phone;
      case 'mail': return Icons.mail;
      case 'location': return Icons.location_on;
      case 'photo': return Icons.photo;
      case 'video': return Icons.video_library;
      case 'music': return Icons.music_note;
      case 'document': return Icons.description;
      case 'folder': return Icons.folder;
      case 'cloud': return Icons.cloud;
      case 'download': return Icons.download;
      case 'upload': return Icons.upload;
      case 'share': return Icons.share;
      case 'edit': return Icons.edit;
      case 'delete': return Icons.delete;
      case 'add': return Icons.add;
      case 'remove': return Icons.remove;
      case 'check': return Icons.check;
      case 'close': return Icons.close;
      case 'arrow_forward': return Icons.arrow_forward;
      case 'arrow_back': return Icons.arrow_back;
      case 'arrow_up': return Icons.arrow_upward;
      case 'arrow_down': return Icons.arrow_downward;
      case 'menu': return Icons.menu;
      case 'search': return Icons.search;
      case 'filter': return Icons.filter_list;
      case 'sort': return Icons.sort;
      case 'refresh': return Icons.refresh;
      case 'notifications': return Icons.notifications;
      case 'visibility': return Icons.visibility;
      case 'visibility_off': return Icons.visibility_off;
      case 'lock': return Icons.lock;
      case 'unlock': return Icons.lock_open;
      case 'security': return Icons.security;
      case 'key': return Icons.vpn_key;
      case 'thumb_up': return Icons.thumb_up;
      case 'thumb_down': return Icons.thumb_down;
      case 'comment': return Icons.comment;
      case 'chat': return Icons.chat;
      case 'message': return Icons.message;
      case 'send': return Icons.send;
      case 'attach': return Icons.attach_file;
      case 'link': return Icons.link;
      case 'public': return Icons.public;
      case 'language': return Icons.language;
      case 'translate': return Icons.translate;
      case 'accessibility': return Icons.accessibility;
      case 'build': return Icons.build;
      case 'bug_report': return Icons.bug_report;
      case 'code': return Icons.code;
      case 'developer_mode': return Icons.developer_mode;
      case 'extension': return Icons.extension;
      case 'integration': return Icons.integration_instructions;
      case 'api': return Icons.api;
      case 'storage': return Icons.storage;
      case 'database': return Icons.dns;
      case 'server': return Icons.computer;
      case 'network': return Icons.wifi;
      case 'bluetooth': return Icons.bluetooth;
      case 'gps': return Icons.gps_fixed;
      case 'battery': return Icons.battery_full;
      case 'signal': return Icons.signal_cellular_4_bar;
      case 'data_usage': return Icons.data_usage;
      case 'timeline': return Icons.timeline;
      case 'trending_up': return Icons.trending_up;
      case 'trending_down': return Icons.trending_down;
      case 'analytics': return Icons.analytics;
      case 'insights': return Icons.insights;
      case 'dashboard': return Icons.dashboard;
      case 'widgets': return Icons.widgets;
      case 'apps': return Icons.apps;
      case 'grid': return Icons.grid_view;
      case 'list': return Icons.list;
      case 'view_list': return Icons.view_list;
      case 'view_module': return Icons.view_module;
      case 'view_carousel': return Icons.view_carousel;
      case 'tab': return Icons.tab;
      default: return Icons.tab;
    }
  }

  static String _getStringFromIcon(IconData icon) {
    // Mapping inverse des icônes vers leurs noms
    if (icon == Icons.home) return 'home';
    if (icon == Icons.person) return 'person';
    if (icon == Icons.settings) return 'settings';
    if (icon == Icons.info) return 'info';
    if (icon == Icons.help) return 'help';
    if (icon == Icons.star) return 'star';
    if (icon == Icons.favorite) return 'favorite';
    if (icon == Icons.bookmark) return 'bookmark';
    if (icon == Icons.calendar_today) return 'calendar';
    if (icon == Icons.phone) return 'phone';
    if (icon == Icons.mail) return 'mail';
    if (icon == Icons.location_on) return 'location';
    if (icon == Icons.photo) return 'photo';
    if (icon == Icons.video_library) return 'video';
    if (icon == Icons.music_note) return 'music';
    if (icon == Icons.description) return 'document';
    if (icon == Icons.folder) return 'folder';
    if (icon == Icons.cloud) return 'cloud';
    if (icon == Icons.download) return 'download';
    if (icon == Icons.upload) return 'upload';
    if (icon == Icons.share) return 'share';
    if (icon == Icons.edit) return 'edit';
    if (icon == Icons.delete) return 'delete';
    if (icon == Icons.add) return 'add';
    if (icon == Icons.remove) return 'remove';
    if (icon == Icons.check) return 'check';
    if (icon == Icons.close) return 'close';
    if (icon == Icons.arrow_forward) return 'arrow_forward';
    if (icon == Icons.arrow_back) return 'arrow_back';
    if (icon == Icons.arrow_upward) return 'arrow_up';
    if (icon == Icons.arrow_downward) return 'arrow_down';
    if (icon == Icons.menu) return 'menu';
    if (icon == Icons.search) return 'search';
    if (icon == Icons.filter_list) return 'filter';
    if (icon == Icons.sort) return 'sort';
    if (icon == Icons.refresh) return 'refresh';
    if (icon == Icons.notifications) return 'notifications';
    if (icon == Icons.visibility) return 'visibility';
    if (icon == Icons.visibility_off) return 'visibility_off';
    if (icon == Icons.lock) return 'lock';
    if (icon == Icons.lock_open) return 'unlock';
    if (icon == Icons.security) return 'security';
    if (icon == Icons.vpn_key) return 'key';
    if (icon == Icons.thumb_up) return 'thumb_up';
    if (icon == Icons.thumb_down) return 'thumb_down';
    if (icon == Icons.comment) return 'comment';
    if (icon == Icons.chat) return 'chat';
    if (icon == Icons.message) return 'message';
    if (icon == Icons.send) return 'send';
    if (icon == Icons.attach_file) return 'attach';
    if (icon == Icons.link) return 'link';
    if (icon == Icons.public) return 'public';
    if (icon == Icons.language) return 'language';
    if (icon == Icons.translate) return 'translate';
    if (icon == Icons.accessibility) return 'accessibility';
    if (icon == Icons.build) return 'build';
    if (icon == Icons.bug_report) return 'bug_report';
    if (icon == Icons.code) return 'code';
    if (icon == Icons.developer_mode) return 'developer_mode';
    if (icon == Icons.extension) return 'extension';
    if (icon == Icons.integration_instructions) return 'integration';
    if (icon == Icons.api) return 'api';
    if (icon == Icons.storage) return 'storage';
    if (icon == Icons.dns) return 'database';
    if (icon == Icons.computer) return 'server';
    if (icon == Icons.wifi) return 'network';
    if (icon == Icons.bluetooth) return 'bluetooth';
    if (icon == Icons.gps_fixed) return 'gps';
    if (icon == Icons.battery_full) return 'battery';
    if (icon == Icons.signal_cellular_4_bar) return 'signal';
    if (icon == Icons.data_usage) return 'data_usage';
    if (icon == Icons.timeline) return 'timeline';
    if (icon == Icons.trending_up) return 'trending_up';
    if (icon == Icons.trending_down) return 'trending_down';
    if (icon == Icons.analytics) return 'analytics';
    if (icon == Icons.insights) return 'insights';
    if (icon == Icons.dashboard) return 'dashboard';
    if (icon == Icons.widgets) return 'widgets';
    if (icon == Icons.apps) return 'apps';
    if (icon == Icons.grid_view) return 'grid';
    if (icon == Icons.list) return 'list';
    if (icon == Icons.view_list) return 'view_list';
    if (icon == Icons.view_module) return 'view_module';
    if (icon == Icons.view_carousel) return 'view_carousel';
    if (icon == Icons.tab) return 'tab';
    return 'tab'; // Valeur par défaut
  }
}
