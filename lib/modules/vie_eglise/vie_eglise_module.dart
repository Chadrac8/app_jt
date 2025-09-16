import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';
import 'widgets/pour_vous_tab.dart' as pour_vous;
import 'widgets/prayer_wall_tab.dart';
import 'widgets/benevolat_tab.dart' as benevolat;
import 'widgets/sermons_tab.dart';

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
                const benevolat.BenevolatTab(),
                PrayerWallTab(),
              ])),
        ]));
  }

  Widget _buildTabBar() {
    return Container(
      height: 42, // Hauteur réduite de la TabBar
      decoration: BoxDecoration(
        color: const Color(0xFF860505), // Rouge bordeaux comme l'AppBar
        boxShadow: [
          BoxShadow(
            color: AppTheme.textTertiaryColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white, // Texte blanc pour onglet sélectionné
        unselectedLabelColor: Colors.white.withOpacity(0.7), // Texte blanc semi-transparent pour onglets non sélectionnés
        indicatorColor: Colors.white, // Indicateur blanc
        indicatorWeight: 3,
        labelStyle: GoogleFonts.poppins(
          fontSize: 13, // Taille de police légèrement réduite
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 13, // Taille de police légèrement réduite
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(
            text: 'Pour vous',
          ),
          Tab(
            text: 'Sermons',
          ),
          Tab(
            text: 'Bénévolat',
          ),
          Tab(
            text: 'Prières & Témoignages',
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.primaryColor.withOpacity(0.05),
          ]),
        borderRadius: BorderRadius.circular(16),
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
          const SizedBox(height: 12),
          Text(
            'Vie de l\'Église',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor)),
          const SizedBox(height: 8),
          Text(
            'Actions personnalisées, sermons, bénévolat et prières',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textSecondaryColor)),
          const SizedBox(height: 16),
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
            borderRadius: BorderRadius.circular(8)),
          child: Icon(
            icon,
            size: 20,
            color: AppTheme.primaryColor)),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: AppTheme.textSecondaryColor)),
      ]);
  }
}
