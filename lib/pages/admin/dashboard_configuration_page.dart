import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/dashboard_widget_model.dart';
import '../../services/dashboard_firebase_service.dart';
import '../../services/app_config_firebase_service.dart';
import '../../../theme.dart';

class DashboardConfigurationPage extends StatefulWidget {
  const DashboardConfigurationPage({Key? key}) : super(key: key);

  @override
  State<DashboardConfigurationPage> createState() => _DashboardConfigurationPageState();
}

class _DashboardConfigurationPageState extends State<DashboardConfigurationPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _isSaving = false;
  List<DashboardWidgetModel> _allWidgets = [];
  Map<String, dynamic> _preferences = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadConfiguration();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadConfiguration() async {
    try {
      setState(() => _isLoading = true);

      final futures = await Future.wait([
        DashboardFirebaseService.getAllDashboardWidgetsStream().first,
        DashboardFirebaseService.getDashboardPreferences(),
      ]);

      _allWidgets = futures[0] as List<DashboardWidgetModel>;
      _preferences = futures[1] as Map<String, dynamic>;

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Erreur lors du chargement de la configuration: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: AppTheme.redStandard,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isApple = AppTheme.isApplePlatform;
    
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: _buildModernAppBar(isApple),
      body: _isLoading
          ? _buildLoadingState(isApple)
          : _buildModernTabBarView(isApple),
    );
  }

  PreferredSizeWidget _buildModernAppBar(bool isApple) {
    return AppBar(
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: AppTheme.onPrimaryColor,
      elevation: 0,
      title: Text(
        'Configuration Dashboard',
        style: GoogleFonts.inter(
          fontSize: AppTheme.fontSize18,
          fontWeight: AppTheme.fontSemiBold,
          color: AppTheme.onPrimaryColor,
        ),
      ),
      leading: IconButton(
        icon: Icon(
          isApple ? CupertinoIcons.back : Icons.arrow_back_rounded,
          color: AppTheme.onPrimaryColor,
        ),
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
        },
      ),
      actions: [
        IconButton(
          icon: Icon(
            isApple ? CupertinoIcons.refresh : Icons.refresh_rounded,
            color: AppTheme.onPrimaryColor,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            _loadConfiguration();
          },
          tooltip: 'Actualiser',
        ),
        IconButton(
          icon: Icon(
            isApple ? CupertinoIcons.restart : Icons.restore_rounded,
            color: AppTheme.onPrimaryColor,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            _resetToDefault();
          },
          tooltip: 'Réinitialiser',
        ),
      ],
      bottom: _buildModernTabBar(isApple),
    );
  }

  PreferredSize _buildModernTabBar(bool isApple) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(48.0),
      child: Container(
        color: AppTheme.primaryColor,
        child: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.onPrimaryColor,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: AppTheme.onPrimaryColor,
          unselectedLabelColor: AppTheme.onPrimaryColor.withOpacity(0.7),
          labelStyle: GoogleFonts.inter(
            fontSize: AppTheme.fontSize14,
            fontWeight: AppTheme.fontSemiBold,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontSize: AppTheme.fontSize14,
            fontWeight: AppTheme.fontMedium,
          ),
          tabs: [
            Tab(
              icon: Icon(
                isApple ? CupertinoIcons.square_grid_2x2 : Icons.widgets_rounded,
                size: 20,
              ),
              text: 'Widgets',
            ),
            Tab(
              icon: Icon(
                isApple ? CupertinoIcons.settings : Icons.tune_rounded,
                size: 20,
              ),
              text: 'Préférences',
            ),
            Tab(
              icon: Icon(
                isApple ? CupertinoIcons.wrench : Icons.build_rounded,
                size: 20,
              ),
              text: 'Maintenance',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isApple) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceLarge),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: AppTheme.borderRadiusLarge,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              strokeWidth: 3,
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            Text(
              'Chargement de la configuration...',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize16,
                fontWeight: AppTheme.fontMedium,
                color: AppTheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTabBarView(bool isApple) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildModernWidgetsTab(isApple),
        _buildModernPreferencesTab(isApple),
        _buildModernMaintenanceTab(isApple),
      ],
    );
  }

  Widget _buildModernWidgetsTab(bool isApple) {
    final categories = _groupWidgetsByCategory();
    
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildWidgetsHeader(isApple),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final entry = categories.entries.elementAt(index);
                return _buildModernCategorySection(entry.key, entry.value, isApple);
              },
              childCount: categories.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: AppTheme.spaceLarge),
        ),
      ],
    );
  }

  Widget _buildWidgetsHeader(bool isApple) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spaceMedium),
      padding: const EdgeInsets.all(AppTheme.spaceLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryContainer,
            AppTheme.primaryContainer.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppTheme.borderRadiusMedium,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceSmall),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: AppTheme.borderRadiusSmall,
                ),
                child: Icon(
                  isApple ? CupertinoIcons.square_grid_2x2 : Icons.widgets_rounded,
                  color: AppTheme.onPrimaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spaceSmall),
              Expanded(
                child: Text(
                  'Gestion des Widgets',
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize20,
                    fontWeight: AppTheme.fontBold,
                    color: AppTheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Text(
            'Personnalisez votre dashboard en sélectionnant et réorganisant les widgets. '
            'Glissez-déposez pour modifier l\'ordre d\'affichage.',
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize14,
              fontWeight: AppTheme.fontMedium,
              color: AppTheme.onPrimaryContainer.withOpacity(0.8),
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _selectAllWidgets();
                  },
                  icon: Icon(
                    isApple ? CupertinoIcons.checkmark_alt : Icons.check_box_rounded,
                    size: 18,
                  ),
                  label: const Text('Tout sélectionner'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceSmall),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spaceSmall),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _deselectAllWidgets();
                  },
                  icon: Icon(
                    isApple ? CupertinoIcons.clear : Icons.check_box_outline_blank_rounded,
                    size: 18,
                  ),
                  label: const Text('Tout désélectionner'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceSmall),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernCategorySection(String category, List<DashboardWidgetModel> widgets, bool isApple) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.borderRadiusMedium,
        border: Border.all(
          color: AppTheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          expansionTileTheme: ExpansionTileThemeData(
            backgroundColor: AppTheme.surface,
            collapsedBackgroundColor: AppTheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: AppTheme.borderRadiusMedium,
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: AppTheme.borderRadiusMedium,
            ),
          ),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceMedium,
            vertical: AppTheme.spaceSmall,
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceXSmall),
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer,
                  borderRadius: AppTheme.borderRadiusSmall,
                ),
                child: Icon(
                  _getCategoryIcon(category),
                  color: AppTheme.onPrimaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.spaceSmall),
              Text(
                _getCategoryDisplayName(category),
                style: GoogleFonts.inter(
                  fontSize: AppTheme.fontSize16,
                  fontWeight: AppTheme.fontSemiBold,
                  color: AppTheme.onSurface,
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: AppTheme.spaceXSmall),
            child: Text(
              '${widgets.length} widget${widgets.length > 1 ? 's' : ''} disponible${widgets.length > 1 ? 's' : ''}',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize12,
                fontWeight: AppTheme.fontMedium,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ),
          trailing: Icon(
            isApple ? CupertinoIcons.chevron_down : Icons.expand_more_rounded,
            color: AppTheme.onSurface,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: AppTheme.spaceMedium,
                right: AppTheme.spaceMedium,
                bottom: AppTheme.spaceMedium,
              ),
              child: Column(
                children: widgets.map((widget) => _buildModernWidgetTile(widget, isApple)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernWidgetTile(DashboardWidgetModel widget, bool isApple) {
    final widgetColor = _parseColor(widget.config['color']);
    
    return Container(
      key: ValueKey(widget.id),
      margin: const EdgeInsets.only(bottom: AppTheme.spaceSmall),
      decoration: BoxDecoration(
        color: widget.isVisible 
            ? AppTheme.primaryContainer.withOpacity(0.3)
            : AppTheme.surfaceVariant,
        borderRadius: AppTheme.borderRadiusMedium,
        border: Border.all(
          color: widget.isVisible 
              ? AppTheme.primaryColor.withOpacity(0.3)
              : AppTheme.outline.withOpacity(0.2),
          width: widget.isVisible ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppTheme.borderRadiusMedium,
          onTap: () {
            HapticFeedback.lightImpact();
            _showWidgetDetails(widget);
          },
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spaceSmall),
                  decoration: BoxDecoration(
                    color: widgetColor.withOpacity(0.15),
                    borderRadius: AppTheme.borderRadiusSmall,
                  ),
                  child: Icon(
                    _getWidgetIcon(widget),
                    color: widgetColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppTheme.spaceSmall),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: GoogleFonts.inter(
                          fontSize: AppTheme.fontSize14,
                          fontWeight: AppTheme.fontSemiBold,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getWidgetTypeDisplayName(widget.type),
                        style: GoogleFonts.inter(
                          fontSize: AppTheme.fontSize12,
                          fontWeight: AppTheme.fontMedium,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch.adaptive(
                      value: widget.isVisible,
                      onChanged: (value) {
                        HapticFeedback.lightImpact();
                        _toggleWidgetVisibility(widget, value);
                      },
                      activeColor: AppTheme.primaryColor,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    const SizedBox(width: AppTheme.spaceXSmall),
                    Icon(
                      isApple ? CupertinoIcons.line_horizontal_3 : Icons.drag_handle_rounded,
                      color: AppTheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernPreferencesTab(bool isApple) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildPreferencesHeader(isApple),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                _buildDisplayPreferencesSection(isApple),
                const SizedBox(height: AppTheme.spaceMedium),
                _buildAdvancedPreferencesSection(isApple),
                const SizedBox(height: AppTheme.spaceLarge),
                _buildSaveButton(isApple),
                const SizedBox(height: AppTheme.spaceLarge),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreferencesHeader(bool isApple) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spaceMedium),
      padding: const EdgeInsets.all(AppTheme.spaceLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.secondaryContainer,
            AppTheme.secondaryContainer.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppTheme.borderRadiusMedium,
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondaryColor.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceSmall),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor,
                  borderRadius: AppTheme.borderRadiusSmall,
                ),
                child: Icon(
                  isApple ? CupertinoIcons.settings : Icons.tune_rounded,
                  color: AppTheme.onSecondaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spaceSmall),
              Expanded(
                child: Text(
                  'Préférences Dashboard',
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize20,
                    fontWeight: AppTheme.fontBold,
                    color: AppTheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Text(
            'Personnalisez l\'affichage et le comportement de votre dashboard '
            'selon vos préférences.',
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize14,
              fontWeight: AppTheme.fontMedium,
              color: AppTheme.onSecondaryContainer.withOpacity(0.8),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisplayPreferencesSection(bool isApple) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.borderRadiusMedium,
        border: Border.all(
          color: AppTheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            child: Row(
              children: [
                Icon(
                  isApple ? CupertinoIcons.eye : Icons.visibility_rounded,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.spaceSmall),
                Text(
                  'Préférences d\'Affichage',
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize16,
                    fontWeight: AppTheme.fontSemiBold,
                    color: AppTheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          _buildModernSwitchTile(
            'Vue compacte',
            'Affichage plus dense des widgets',
            _preferences['compactView'] ?? false,
            isApple ? CupertinoIcons.rectangle_compress_vertical : Icons.compress_rounded,
            (value) => _updatePreference('compactView', value),
            isApple,
          ),
          _buildModernSwitchTile(
            'Afficher les tendances',
            'Indicateurs d\'évolution des statistiques',
            _preferences['showTrends'] ?? true,
            isApple ? CupertinoIcons.chart_bar : Icons.trending_up_rounded,
            (value) => _updatePreference('showTrends', value),
            isApple,
          ),
          _buildModernSwitchTile(
            'Actualisation automatique',
            'Mise à jour périodique des données',
            _preferences['autoRefresh'] ?? true,
            isApple ? CupertinoIcons.refresh : Icons.refresh_rounded,
            (value) => _updatePreference('autoRefresh', value),
            isApple,
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedPreferencesSection(bool isApple) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.borderRadiusMedium,
        border: Border.all(
          color: AppTheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            child: Row(
              children: [
                Icon(
                  isApple ? CupertinoIcons.gear_alt : Icons.settings_rounded,
                  color: AppTheme.tertiaryColor,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.spaceSmall),
                Text(
                  'Paramètres Avancés',
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize16,
                    fontWeight: AppTheme.fontSemiBold,
                    color: AppTheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.only(
                bottomLeft: AppTheme.borderRadiusMedium.bottomLeft,
                bottomRight: AppTheme.borderRadiusMedium.bottomRight,
              ),
              onTap: () {
                HapticFeedback.lightImpact();
                _showRefreshIntervalDialog();
              },
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceMedium),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spaceXSmall),
                      decoration: BoxDecoration(
                        color: AppTheme.tertiaryContainer,
                        borderRadius: AppTheme.borderRadiusSmall,
                      ),
                      child: Icon(
                        isApple ? CupertinoIcons.time : Icons.schedule_rounded,
                        color: AppTheme.onTertiaryContainer,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceSmall),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Intervalle d\'actualisation',
                            style: GoogleFonts.inter(
                              fontSize: AppTheme.fontSize14,
                              fontWeight: AppTheme.fontSemiBold,
                              color: AppTheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${(_preferences['refreshInterval'] ?? 300) ~/ 60} minutes',
                            style: GoogleFonts.inter(
                              fontSize: AppTheme.fontSize12,
                              fontWeight: AppTheme.fontMedium,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isApple ? CupertinoIcons.chevron_right : Icons.chevron_right_rounded,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSwitchTile(
    String title,
    String subtitle,
    bool value,
    IconData icon,
    ValueChanged<bool> onChanged,
    bool isApple,
  ) {
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceMedium,
          vertical: AppTheme.spaceSmall,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceXSmall),
              decoration: BoxDecoration(
                color: value 
                    ? AppTheme.primaryContainer 
                    : AppTheme.surfaceVariant,
                borderRadius: AppTheme.borderRadiusSmall,
              ),
              child: Icon(
                icon,
                color: value 
                    ? AppTheme.onPrimaryContainer 
                    : AppTheme.onSurfaceVariant,
                size: 20,
              ),
            ),
            const SizedBox(width: AppTheme.spaceSmall),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize14,
                      fontWeight: AppTheme.fontSemiBold,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize12,
                      fontWeight: AppTheme.fontMedium,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: (newValue) {
                HapticFeedback.lightImpact();
                onChanged(newValue);
              },
              activeColor: AppTheme.primaryColor,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(bool isApple) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
      child: FilledButton.icon(
        onPressed: _isSaving ? null : () {
          HapticFeedback.lightImpact();
          _savePreferences();
        },
        icon: _isSaving
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.onPrimaryColor),
                ),
              )
            : Icon(
                isApple ? CupertinoIcons.checkmark_alt : Icons.save_rounded,
                size: 18,
              ),
        label: Text(
          _isSaving ? 'Sauvegarde...' : 'Sauvegarder les Préférences',
          style: GoogleFonts.inter(
            fontWeight: AppTheme.fontSemiBold,
          ),
        ),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMedium),
          shape: RoundedRectangleBorder(
            borderRadius: AppTheme.borderRadiusMedium,
          ),
        ),
      ),
    );
  }

  // MÉTHODES UTILITAIRES

  Map<String, List<DashboardWidgetModel>> _groupWidgetsByCategory() {
    final Map<String, List<DashboardWidgetModel>> categories = {};
    
    for (final widget in _allWidgets) {
      if (!categories.containsKey(widget.category)) {
        categories[widget.category] = [];
      }
      categories[widget.category]!.add(widget);
    }
    
    // Trier chaque catégorie par ordre
    for (final widgets in categories.values) {
      widgets.sort((a, b) => a.order.compareTo(b.order));
    }
    
    return categories;
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'persons': return 'Membres';
      case 'groups': return 'Groupes';
      case 'events': return 'Événements';
      case 'services': return 'Services';
      case 'tasks': return 'Tâches';
      case 'appointments': return 'Rendez-vous';
      default: return category.toUpperCase();
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'persons': return Icons.people;
      case 'groups': return Icons.groups;
      case 'events': return Icons.event;
      case 'services': return Icons.church;
      case 'tasks': return Icons.task;
      case 'appointments': return Icons.schedule;
      default: return Icons.category;
    }
  }

  String _getWidgetTypeDisplayName(String type) {
    switch (type) {
      case 'stat': return 'Statistique';
      case 'chart': return 'Graphique';
      case 'list': return 'Liste';
      case 'card': return 'Carte';
      default: return type.toUpperCase();
    }
  }

  IconData _getWidgetIcon(DashboardWidgetModel widget) {
    final iconName = widget.config['icon'] as String?;
    if (iconName != null) {
      switch (iconName) {
        case 'people': return Icons.people;
        case 'person_check': return Icons.person_add_alt_1;
        case 'person_add': return Icons.person_add;
        case 'groups': return Icons.groups;
        case 'group_work': return Icons.group_work;
        case 'event': return Icons.event;
        case 'event_available': return Icons.event_available;
        case 'church': return Icons.church;
        case 'task': return Icons.task;
        case 'schedule': return Icons.schedule;
      }
    }
    
    switch (widget.type) {
      case 'stat': return Icons.analytics;
      case 'chart': return Icons.bar_chart;
      case 'list': return Icons.list;
      default: return Icons.widgets;
    }
  }

  Color _parseColor(String? colorString) {
    if (colorString == null) return AppTheme.blueStandard;
    try {
      if (colorString.startsWith('#')) {
        colorString = colorString.substring(1);
      }
      if (colorString.length == 6) {
        colorString = 'FF' + colorString;
      }
      return Color(int.parse(colorString, radix: 16));
    } catch (e) {
      return AppTheme.blueStandard;
    }
  }

  // ACTIONS

  Future<void> _toggleWidgetVisibility(DashboardWidgetModel widget, bool isVisible) async {
    try {
      await DashboardFirebaseService.updateWidgetVisibility(widget.id, isVisible);
      
      // Mettre à jour localement
      setState(() {
        final index = _allWidgets.indexWhere((w) => w.id == widget.id);
        if (index != -1) {
          _allWidgets[index] = widget.copyWith(isVisible: isVisible);
        }
      });
    } catch (e) {
      print('Erreur lors de la mise à jour de la visibilité: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: AppTheme.redStandard,
        ),
      );
    }
  }



  void _selectAllWidgets() {
    for (int i = 0; i < _allWidgets.length; i++) {
      if (!_allWidgets[i].isVisible) {
        DashboardFirebaseService.updateWidgetVisibility(_allWidgets[i].id, true);
        _allWidgets[i] = _allWidgets[i].copyWith(isVisible: true);
      }
    }
    setState(() {});
  }

  void _deselectAllWidgets() {
    for (int i = 0; i < _allWidgets.length; i++) {
      if (_allWidgets[i].isVisible) {
        DashboardFirebaseService.updateWidgetVisibility(_allWidgets[i].id, false);
        _allWidgets[i] = _allWidgets[i].copyWith(isVisible: false);
      }
    }
    setState(() {});
  }

  void _updatePreference(String key, dynamic value) {
    setState(() {
      _preferences[key] = value;
    });
  }

  Future<void> _savePreferences() async {
    try {
      setState(() => _isSaving = true);
      
      await DashboardFirebaseService.saveDashboardPreferences(_preferences);
      
      setState(() => _isSaving = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Préférences sauvegardées'),
          backgroundColor: AppTheme.greenStandard,
        ),
      );
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sauvegarde: $e'),
          backgroundColor: AppTheme.redStandard,
        ),
      );
    }
  }

  Future<void> _resetToDefault() async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialiser le Dashboard'),
        content: const Text(
          'Voulez-vous vraiment réinitialiser le dashboard aux paramètres par défaut ? '
          'Cette action ne peut pas être annulée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.redStandard),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );

    if (shouldReset == true) {
      try {
        await DashboardFirebaseService.resetToDefaultWidgets();
        await _loadConfiguration();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dashboard réinitialisé'),
            backgroundColor: AppTheme.greenStandard,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la réinitialisation: $e'),
            backgroundColor: AppTheme.redStandard,
          ),
        );
      }
    }
  }

  void _showWidgetDetails(DashboardWidgetModel widget) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${_getWidgetTypeDisplayName(widget.type)}'),
            Text('Catégorie: ${_getCategoryDisplayName(widget.category)}'),
            Text('Visible: ${widget.isVisible ? "Oui" : "Non"}'),
            Text('Ordre: ${widget.order}'),
            if (widget.config.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spaceSmall),
              const Text('Configuration:', style: TextStyle(fontWeight: AppTheme.fontBold)),
              ...widget.config.entries.map((entry) => 
                Text('${entry.key}: ${entry.value}'),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showRefreshIntervalDialog() {
    final currentInterval = (_preferences['refreshInterval'] ?? 300) ~/ 60;
    int selectedInterval = currentInterval;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Intervalle d\'actualisation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Sélectionnez l\'intervalle d\'actualisation automatique:'),
              const SizedBox(height: AppTheme.spaceMedium),
              DropdownButton<int>(
                value: selectedInterval,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('1 minute')),
                  DropdownMenuItem(value: 5, child: Text('5 minutes')),
                  DropdownMenuItem(value: 10, child: Text('10 minutes')),
                  DropdownMenuItem(value: 15, child: Text('15 minutes')),
                  DropdownMenuItem(value: 30, child: Text('30 minutes')),
                  DropdownMenuItem(value: 60, child: Text('1 heure')),
                ],
                onChanged: (value) => setState(() => selectedInterval = value ?? 5),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                _updatePreference('refreshInterval', selectedInterval * 60);
                Navigator.of(context).pop();
              },
              child: const Text('Confirmer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernMaintenanceTab(bool isApple) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildMaintenanceHeader(isApple),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                _buildCleanupSection(isApple),
                const SizedBox(height: AppTheme.spaceMedium),
                _buildSystemInfoSection(isApple),
                const SizedBox(height: AppTheme.spaceLarge),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMaintenanceHeader(bool isApple) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spaceMedium),
      padding: const EdgeInsets.all(AppTheme.spaceLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.warningContainer,
            AppTheme.warningContainer.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppTheme.borderRadiusMedium,
        boxShadow: [
          BoxShadow(
            color: AppTheme.warning.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceSmall),
                decoration: BoxDecoration(
                  color: AppTheme.warning,
                  borderRadius: AppTheme.borderRadiusSmall,
                ),
                child: Icon(
                  isApple ? CupertinoIcons.wrench : Icons.build_rounded,
                  color: AppTheme.onWarning,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spaceSmall),
              Expanded(
                child: Text(
                  'Maintenance Système',
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize20,
                    fontWeight: AppTheme.fontBold,
                    color: AppTheme.onWarningContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Text(
            'Outils de maintenance et d\'administration avancée pour le dashboard. '
            'Utilisez ces fonctions avec précaution.',
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize14,
              fontWeight: AppTheme.fontMedium,
              color: AppTheme.onWarningContainer.withOpacity(0.8),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanupSection(bool isApple) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.borderRadiusMedium,
        border: Border.all(
          color: AppTheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            child: Row(
              children: [
                Icon(
                  isApple ? CupertinoIcons.clear : Icons.cleaning_services_rounded,
                  color: AppTheme.warning,
                  size: 24,
                ),
                const SizedBox(width: AppTheme.spaceSmall),
                Text(
                  'Nettoyage des Modules',
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize16,
                    fontWeight: AppTheme.fontSemiBold,
                    color: AppTheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
            child: Text(
              'Supprime les modules orphelins qui n\'existent plus dans le code '
              'mais qui sont encore présents dans la configuration Firebase.',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize14,
                fontWeight: AppTheme.fontMedium,
                color: AppTheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
            padding: const EdgeInsets.all(AppTheme.spaceSmall),
            decoration: BoxDecoration(
              color: AppTheme.errorContainer,
              borderRadius: AppTheme.borderRadiusSmall,
            ),
            child: Row(
              children: [
                Icon(
                  isApple ? CupertinoIcons.exclamationmark_triangle : Icons.warning_rounded,
                  color: AppTheme.onErrorContainer,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.spaceSmall),
                Expanded(
                  child: Text(
                    'Cette action supprimera définitivement les modules '
                    '"Pour vous", "Ressources" et "Dons" du menu "Plus".',
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize12,
                      fontWeight: AppTheme.fontMedium,
                      color: AppTheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _cleanupOrphanModules();
                },
                icon: Icon(
                  isApple ? CupertinoIcons.delete : Icons.delete_sweep_rounded,
                  size: 18,
                ),
                label: const Text('Nettoyer les modules orphelins'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.warning,
                  foregroundColor: AppTheme.onWarning,
                  padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceSmall),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemInfoSection(bool isApple) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.borderRadiusMedium,
        border: Border.all(
          color: AppTheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            child: Row(
              children: [
                Icon(
                  isApple ? CupertinoIcons.info : Icons.info_rounded,
                  color: AppTheme.info,
                  size: 24,
                ),
                const SizedBox(width: AppTheme.spaceSmall),
                Text(
                  'Informations Système',
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize16,
                    fontWeight: AppTheme.fontSemiBold,
                    color: AppTheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          _buildModernInfoRow('Version de l\'application', '1.0.0', isApple),
          _buildModernInfoRow('Configuration Firebase', 'Connectée', isApple),
          _buildModernInfoRow('Modules actifs', '${_allWidgets.length}', isApple),
          Padding(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spaceSmall),
              decoration: BoxDecoration(
                color: AppTheme.infoContainer,
                borderRadius: AppTheme.borderRadiusSmall,
              ),
              child: Row(
                children: [
                  Icon(
                    isApple ? CupertinoIcons.lightbulb : Icons.lightbulb_rounded,
                    color: AppTheme.onInfoContainer,
                    size: 16,
                  ),
                  const SizedBox(width: AppTheme.spaceSmall),
                  Expanded(
                    child: Text(
                      'Pour plus d\'informations de maintenance, consultez la console Firebase.',
                      style: GoogleFonts.inter(
                        fontSize: AppTheme.fontSize12,
                        fontWeight: AppTheme.fontMedium,
                        color: AppTheme.onInfoContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernInfoRow(String label, String value, bool isApple) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceMedium,
        vertical: AppTheme.spaceXSmall,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize14,
                fontWeight: AppTheme.fontMedium,
                color: AppTheme.onSurface,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize14,
              fontWeight: AppTheme.fontSemiBold,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }



  Future<void> _cleanupOrphanModules() async {
    // Afficher un dialogue de confirmation
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmer le nettoyage'),
          content: const Text(
            'Cette action va supprimer définitivement les modules orphelins '
            '(Pour vous, Ressources, Dons) de la configuration Firebase.\n\n'
            'Ces modules n\'apparaîtront plus dans le menu "Plus" de l\'application.\n\n'
            'Voulez-vous continuer ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.orangeStandard,
                foregroundColor: AppTheme.white100,
              ),
              child: const Text('Nettoyer'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: AppTheme.spaceMedium),
                Text('Nettoyage en cours...'),
              ],
            ),
          );
        },
      );

      // Exécuter le nettoyage
      await AppConfigFirebaseService.cleanupOrphanModules();

      // Fermer le dialogue de chargement
      Navigator.of(context).pop();

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '✅ Nettoyage terminé avec succès! '
            'Les modules orphelins ont été supprimés.',
          ),
          backgroundColor: AppTheme.greenStandard,
          duration: Duration(seconds: 4),
        ),
      );

    } catch (e) {
      // Fermer le dialogue de chargement en cas d'erreur
      Navigator.of(context).pop();

      // Afficher un message d'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '❌ Erreur lors du nettoyage: $e\n'
            'Veuillez essayer via Firebase Console.',
          ),
          backgroundColor: AppTheme.redStandard,
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }
}