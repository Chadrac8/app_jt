import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';
import 'widgets/pour_vous_tab_dynamic.dart' as pour_vous;
import 'widgets/sermons_tab.dart';
import 'widgets/offrandes_tab.dart';
import 'views/prayer_wall_view.dart';

class VieEgliseModule extends StatefulWidget {
  final int initialTabIndex;
  final TabController? tabController; // MD3: TabController fourni par le wrapper
  
  const VieEgliseModule({
    Key? key, 
    this.initialTabIndex = 0,
    this.tabController, // MD3: Optionnel pour rétrocompatibilité
  }) : super(key: key);

  @override
  State<VieEgliseModule> createState() => _VieEgliseModuleState();
}

class _VieEgliseModuleState extends State<VieEgliseModule> with TickerProviderStateMixin {
  TabController? _internalTabController; // TabController interne (si non fourni)
  
  // MD3: Getter pour obtenir le TabController (externe ou interne)
  TabController get _tabController => 
      widget.tabController ?? _internalTabController!;

  @override
  void initState() {
    super.initState();
    // MD3: Créer un TabController interne seulement si non fourni par le wrapper
    if (widget.tabController == null) {
      _internalTabController = TabController(
        length: 4, 
        vsync: this,
        initialIndex: widget.initialTabIndex,
      );
    }
  }

  @override
  void dispose() {
    // MD3: Disposer uniquement le TabController interne (pas celui du wrapper)
    _internalTabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // MD3: Si TabController fourni par wrapper, pas besoin de Scaffold
    final body = Column(
      children: [
        // MD3: Afficher le TabBar seulement si non fourni par le wrapper
        if (widget.tabController == null) _buildTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              const pour_vous.PourVousTabDynamic(),
              SermonsTab(),
              const OffrandesTab(),
              const PrayerWallView(),
            ],
          ),
        ),
      ],
    );
    
    // MD3: Scaffold seulement si utilisé standalone (sans wrapper)
    if (widget.tabController == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: body,
      );
    }
    
    // MD3: Si dans le wrapper, retourner directement le body
    return body;
  }

  Widget _buildTabBar() {
    return Column(
      children: [
        // TabBar intégrée - Style MD3 avec fond Surface (clair)
        Container(
          color: AppTheme.surface, // MD3: Fond clair comme l'AppBar
          child: TabBar(
            controller: _tabController,
            // Les couleurs sont héritées du TabBarTheme (primaryColor pour actif, gris pour inactif)
            tabs: [
              Tab(
                icon: const Icon(Icons.auto_awesome_rounded),
                child: Text(
                  'Pour vous',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(fontSize: AppTheme.isApplePlatform ? 14 : 12),
                ),
              ),
              Tab(
                icon: const Icon(Icons.mic_rounded),
                child: Text(
                  'Sermons',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(fontSize: AppTheme.isApplePlatform ? 14 : 12),
                ),
              ),
              Tab(
                icon: const Icon(Icons.volunteer_activism_rounded),
                child: Text(
                  'Offrandes',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(fontSize: AppTheme.isApplePlatform ? 14 : 12),
                ),
              ),
              Tab(
                icon: const Icon(Icons.diversity_3_rounded),
                child: Text(
                  'Prières',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(fontSize: AppTheme.isApplePlatform ? 14 : 12),
                ),
              ),
            ],
          ),
        ),
        
        // Divider subtil MD3
        Divider(
          height: 1,
          thickness: 1,
          color: AppTheme.grey300.withOpacity(0.5),
        ),
      ],
    );
  }
}

/// Widget d'aperçu pour la navigation
class VieEgliseModulePreview extends StatelessWidget {
  const VieEgliseModulePreview({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLarge), // 8px grid compliant
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.1),
            AppTheme.primaryColor.withValues(alpha: 0.05),
          ]),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
          width: 1)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.church,
            size: 48,
            color: AppTheme.primaryColor),
          const SizedBox(height: AppTheme.spaceMedium), // 8px grid
          Text(
            'Vie de l\'Église',
            style: GoogleFonts.inter( // Material Design 3 typography
              fontSize: AppTheme.fontSize16, // titleMedium
              fontWeight: AppTheme.fontSemiBold,
              color: AppTheme.textPrimaryColor)),
          const SizedBox(height: AppTheme.spaceSmall), // 8px grid
          Text(
            'Actions personnalisées, sermons, bénévolat et prières',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter( // Material Design 3 typography
              fontSize: AppTheme.fontSize14, // bodyMedium
              fontWeight: AppTheme.fontRegular,
              color: AppTheme.textSecondaryColor)),
          const SizedBox(height: AppTheme.spaceMedium), // 8px grid
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFeatureIcon(Icons.person, 'Pour vous'),
              const SizedBox(width: AppTheme.spaceMedium),
              _buildFeatureIcon(Icons.play_circle, 'Sermons'),
              const SizedBox(width: AppTheme.spaceMedium),
              _buildFeatureIcon(Icons.volunteer_activism, 'Bénévolat'),
              const SizedBox(width: AppTheme.spaceMedium),
              _buildFeatureIcon(Icons.pan_tool, 'Prières'),
            ]),
        ]));
  }

  Widget _buildFeatureIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spaceSmall),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
          child: Icon(
            icon,
            size: 20,
            color: AppTheme.primaryColor)),
        const SizedBox(height: AppTheme.spaceSmall), // 8px grid compliant
        Text(
          label,
          style: GoogleFonts.inter( // Material Design 3 typography
            fontSize: AppTheme.fontSize12, // labelSmall
            fontWeight: AppTheme.fontMedium,
            color: AppTheme.textSecondaryColor)),
      ]);
  }
}
