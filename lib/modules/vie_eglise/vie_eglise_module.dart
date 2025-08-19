import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';
import 'widgets/church_resources_tab.dart';
import 'widgets/pour_vous_tab.dart';
import 'widgets/prayer_wall_tab.dart';
import 'widgets/benevolat_tab.dart';
import 'widgets/sermons_tab.dart';

class VieEgliseModule extends StatefulWidget {
  const VieEgliseModule({Key? key}) : super(key: key);

  @override
  State<VieEgliseModule> createState() => _VieEgliseModuleState();
}

class _VieEgliseModuleState extends State<VieEgliseModule> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
              children: const [
                PourVousTab(),
                SermonsTab(),
                ChurchResourcesTab(),
                BenevolatTab(),
                PrayerWallTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppTheme.primaryColor,
        indicatorWeight: 3,
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(
            icon: Icon(Icons.person, size: 20),
            text: 'Pour vous',
          ),
          Tab(
            icon: Icon(Icons.play_circle, size: 20),
            text: 'Sermons',
          ),
          Tab(
            icon: Icon(Icons.library_books, size: 20),
            text: 'Ressources',
          ),
          Tab(
            icon: Icon(Icons.volunteer_activism, size: 20),
            text: 'Bénévolat',
          ),
          Tab(
            icon: Icon(Icons.pan_tool, size: 20),
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
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.backgroundColor,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.church,
            size: 60,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Vie de l\'Église',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Actualités, ressources et services',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFeatureIcon(Icons.campaign, 'Actualités'),
              const SizedBox(width: 20),
              _buildFeatureIcon(Icons.library_books, 'Ressources'),
              const SizedBox(width: 20),
              _buildFeatureIcon(Icons.event, 'Services'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }
}
