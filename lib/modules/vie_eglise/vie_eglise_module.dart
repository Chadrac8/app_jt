import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme.dart';
import 'widgets/pour_vous_tab.dart' as pour_vous;
import 'widgets/prayer_wall_tab.dart';
import 'widgets/sermons_tab.dart';
import 'widgets/offrandes_tab.dart';

class VieEgliseModule extends StatefulWidget {
  final int initialTabIndex;
  
  const VieEgliseModule({Key? key, this.initialTabIndex = 0}) : super(key: key);

  @override
  State<VieEgliseModule> createState() => _VieEgliseModuleState();
}

class _VieEgliseModuleState extends State<VieEgliseModule> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4, 
      vsync: this,
      initialIndex: widget.initialTabIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                const pour_vous.PourVousTab(),
                SermonsTab(),
                const OffrandesTab(),
                PrayerWallTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Column(
      children: [
        // TabBar - Style MD3 moderne avec couleur bottomNavigationBar
        Material(
          color: AppTheme.surface, // Même couleur que la bottomNavigationBar
          elevation: 0,
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryColor, // Texte rouge sur fond clair
            unselectedLabelColor: AppTheme.onSurfaceVariant, // Texte gris sur fond clair
            indicatorColor: AppTheme.primaryColor, // Indicateur rouge sur fond clair
            indicatorSize: TabBarIndicatorSize.label,
            indicatorWeight: 3.0,
            labelStyle: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: AppTheme.fontSemiBold,
              letterSpacing: 0.1,
            ),
            unselectedLabelStyle: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: AppTheme.fontMedium,
              letterSpacing: 0.1,
            ),
            splashFactory: InkRipple.splashFactory,
            overlayColor: WidgetStateProperty.resolveWith<Color?>(
              (Set<WidgetState> states) {
                if (states.contains(WidgetState.pressed)) {
                  return AppTheme.primaryColor.withValues(alpha: 0.12); // Overlay rouge sur fond clair
                }
                if (states.contains(WidgetState.hovered)) {
                  return AppTheme.primaryColor.withValues(alpha: 0.08); // Hover rouge sur fond clair
                }
                return null;
              },
            ),
            tabs: const [
              Tab(
                icon: Icon(Icons.auto_awesome_rounded),
                text: 'Pour vous',
              ),
              Tab(
                icon: Icon(Icons.video_library_rounded),
                text: 'Sermons',
              ),
              Tab(
                icon: Icon(Icons.volunteer_activism_rounded),
                text: 'Offrandes',
              ),
              Tab(
                icon: Icon(Icons.favorite_rounded),
                text: 'Prières',
              ),
            ],
          ),
        ),
        
        // Divider subtil MD3
        Divider(
          height: 1,
          thickness: 1,
          color: Theme.of(context).colorScheme.outlineVariant,
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
      padding: const EdgeInsets.all(24), // 8px grid compliant
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
          const SizedBox(height: 16), // 8px grid
          Text(
            'Vie de l\'Église',
            style: GoogleFonts.inter( // Material Design 3 typography
              fontSize: 16, // titleMedium
              fontWeight: AppTheme.fontSemiBold,
              color: AppTheme.textPrimaryColor)),
          const SizedBox(height: 8), // 8px grid
          Text(
            'Actions personnalisées, sermons, bénévolat et prières',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter( // Material Design 3 typography
              fontSize: 14, // bodyMedium
              fontWeight: AppTheme.fontRegular,
              color: AppTheme.textSecondaryColor)),
          const SizedBox(height: 16), // 8px grid
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFeatureIcon(Icons.person, 'Pour vous'),
              const SizedBox(width: 16),
              _buildFeatureIcon(Icons.play_circle, 'Sermons'),
              const SizedBox(width: 16),
              _buildFeatureIcon(Icons.volunteer_activism, 'Bénévolat'),
              const SizedBox(width: 16),
              _buildFeatureIcon(Icons.pan_tool, 'Prières'),
            ]),
        ]));
  }

  Widget _buildFeatureIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
          child: Icon(
            icon,
            size: 20,
            color: AppTheme.primaryColor)),
        const SizedBox(height: 8), // 8px grid compliant
        Text(
          label,
          style: GoogleFonts.inter( // Material Design 3 typography
            fontSize: 12, // labelSmall
            fontWeight: AppTheme.fontMedium,
            color: AppTheme.textSecondaryColor)),
      ]);
  }
}
