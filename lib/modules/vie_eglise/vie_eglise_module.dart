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
              ])),
        ]));
  }

  Widget _buildTabBar() {
    return Container(
      height: 50, // Hauteur Material Design standard
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor, // Harmonisé avec AppBar transparente membre
        boxShadow: [
          BoxShadow(
            color: AppTheme.black100.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: AppTheme.textSecondaryColor,
        indicatorColor: AppTheme.primaryColor,
        indicatorWeight: 3.0, // Poids standard Material Design
        padding: const EdgeInsets.symmetric(horizontal: 16),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: AppTheme.fontSemiBold,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: AppTheme.fontMedium,
        ),
        tabs: const [
          Tab(
            text: 'Pour vous',
            iconMargin: EdgeInsets.only(bottom: 4),
          ),
          Tab(
            text: 'Sermons',
            iconMargin: EdgeInsets.only(bottom: 4),
          ),
          Tab(
            text: 'Offrandes',
            iconMargin: EdgeInsets.only(bottom: 4),
          ),
          Tab(
            text: 'Prières & Témoignages',
            iconMargin: EdgeInsets.only(bottom: 4),
          ),
        ],
      ),
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
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.primaryColor.withOpacity(0.05),
          ]),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
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
            color: AppTheme.primaryColor.withOpacity(0.1),
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
