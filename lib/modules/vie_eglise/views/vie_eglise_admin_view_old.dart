import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme.dart';
import '../widgets/admin_pour_vous_tab.dart';
import '../widgets/admin_sermons_tab.dart';

class VieEgliseAdminView extends StatefulWidget {
  const VieEgliseAdminView({Key? key}) : super(key: key);

  @override
  State<VieEgliseAdminView> createState() => _VieEgliseAdminViewState();
}

class _VieEgliseAdminViewState extends State<VieEgliseAdminView> with TickerProviderStateMixin {
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
      appBar: AppBar(
        title: Text(
          'Administration - Vie de l\'Église',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor)),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 1,
        iconTheme: IconThemeData(color: AppTheme.textPrimaryColor),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textTertiaryColor,
          indicatorColor: AppTheme.primaryColor,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500),
          tabs: const [
            Tab(
              icon: Icon(Icons.person, size: 20),
              text: 'Pour vous'),
            Tab(
              icon: Icon(Icons.play_circle, size: 20),
              text: 'Sermons'),
            Tab(
              icon: Icon(Icons.church, size: 20),
              text: 'Vie de l\'Église'),
            Tab(
              icon: Icon(Icons.library_books, size: 20),
              text: 'Ressources'),
            Tab(
              icon: Icon(Icons.event, size: 20),
              text: 'Services'),
          ])),
      backgroundColor: AppTheme.backgroundColor,
      body: TabBarView(
        controller: _tabController,
        children: [
          const AdminPourVousTab(),
          const AdminSermonsTab(),
          _buildComingSoonTab('Vie de l\'Église'),
          _buildComingSoonTab('Ressources'),
          _buildComingSoonTab('Services'),
        ]));
  }

  Widget _buildComingSoonTab(String tabName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 80,
            color: AppTheme.textTertiaryColor),
          const SizedBox(height: 20),
          Text(
            'Administration $tabName',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor)),
          const SizedBox(height: 10),
          Text(
            'Cette section sera bientôt disponible',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppTheme.textSecondaryColor)),
        ]));
  }
}
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
              icon: Icon(Icons.church, size: 20),
              text: 'Vie de l\'Église',
            ),
            Tab(
              icon: Icon(Icons.library_books, size: 20),
              text: 'Ressources',
            ),
            Tab(
              icon: Icon(Icons.event, size: 20),
              text: 'Services',
            ),
          ],
        ),
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: TabBarView(
        controller: _tabController,
        children: [
          const AdminPourVousTab(),
          const AdminSermonsTab(),
          _buildComingSoonTab('Vie de l\'Église'),
          _buildComingSoonTab('Ressources'),
          _buildComingSoonTab('Services'),
        ],
      ),
    );
  }

  Widget _buildComingSoonTab(String tabName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
          Text(
            'Administration $tabName',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Cette section sera bientôt disponible',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
